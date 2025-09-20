import 'package:chewie_flower/src/chewie_controller.dart';
import 'package:chewie_flower/src/chewie_types.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Policy when another controller is already fullscreen
enum FullscreenPolicy {
  /// Deny entering fullscreen if another controller is active
  deny,

  /// Replace the currently active controller. Global side effects (SystemChrome,
  /// Wakelock) will NOT be toggled; the ownership is handed off to the new
  /// controller to keep user experience smooth.
  replace,
}

class EnterDecision {
  const EnterDecision({
    required this.allowed,
    required this.needsSideEffects,
    this.replacedController,
  });

  final bool allowed;
  final bool needsSideEffects;
  final ChewieController? replacedController;
}

/// A singleton to coordinate global fullscreen side effects across multiple players.
/// - Ensures only one active fullscreen controller at a time
/// - Centralizes SystemChrome and Wakelock handling
/// - Prevents competing enter/exit operations from different controllers
class FullscreenCoordinator {
  FullscreenCoordinator._();
  static final FullscreenCoordinator instance = FullscreenCoordinator._();

  FullscreenPolicy policy = FullscreenPolicy.replace;

  ChewieController? _active;
  int _wakelockRefs = 0;
  final Set<ChewieController> _skipExitSideEffects = <ChewieController>{};

  // We keep last-applied settings minimal; restoring uses controller's
  // deviceOrientationsAfterFullScreen and systemOverlaysAfterFullScreen.

  bool get hasActive => _active != null;
  ChewieController? get activeController => _active;

  /// Try to mark [controller] as the active fullscreen owner.
  /// Returns false if another controller is already active (policy = deny).
  EnterDecision requestEnterDecision(ChewieController controller) {
    if (_active == null) {
      _active = controller;
      return const EnterDecision(allowed: true, needsSideEffects: true);
    }
    if (identical(_active, controller)) {
      return const EnterDecision(allowed: true, needsSideEffects: false);
    }

    switch (policy) {
      case FullscreenPolicy.deny:
        return const EnterDecision(allowed: false, needsSideEffects: false);
      case FullscreenPolicy.replace:
        final previous = _active!;
        // Mark previous so that its exit teardown will not revert side effects.
        _skipExitSideEffects.add(previous);
        // Hand off ownership to the new controller without toggling side effects.
        _active = controller;
        return EnterDecision(
          allowed: true,
          needsSideEffects: false,
          replacedController: previous,
        );
    }
  }

  // Backward-compat wrapper (default true means side effects expected)
  bool requestEnter(ChewieController controller) {
    final d = requestEnterDecision(controller);
    return d.allowed;
  }

  /// Apply global side effects for fullscreen enter for [controller].
  /// Caller should have verified requestEnter returned true.
  Future<void> applyEnterSideEffects(ChewieController controller) async {
    // System overlays on enter: if provided, use it; otherwise hide overlays.
    final overlaysOnEnter = controller.systemOverlaysOnEnterFullScreen;
    if (overlaysOnEnter != null) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: overlaysOnEnter,
      );
    } else {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: const <SystemUiOverlay>[],
      );
    }

    // Device orientations on enter: if provided, use it; otherwise infer
    // from video aspect ratio with the legacy logic.
    final orientationsOnEnter = controller.deviceOrientationsOnEnterFullScreen;
    if (orientationsOnEnter != null) {
      await SystemChrome.setPreferredOrientations(orientationsOnEnter);
    } else {
      final size = controller.videoPlayerController.value.size;
      final videoWidth = size.width;
      final videoHeight = size.height;
      final isLandscapeVideo = videoWidth > videoHeight;
      final isPortraitVideo = videoHeight > videoWidth;
      if (isLandscapeVideo) {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else if (isPortraitVideo) {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      }
    }

    // Wakelock: only enable if this controller disallows screen sleep.
    if (!controller.allowedScreenSleep) {
      _wakelockRefs++;
      await WakelockPlus.enable();
    }

    controller.emitEvent(ChewieEventType.fullscreenEnterApplied);
  }

  /// Apply global side effects for fullscreen exit for [controller].
  /// Only the active controller may finalize exit.
  Future<void> applyExitSideEffects(ChewieController controller) async {
    if (_skipExitSideEffects.remove(controller)) {
      // This controller was replaced; do not toggle global side effects.
      // Active ownership has already been handed to the new controller.
      return;
    }
    if (!identical(_active, controller)) {
      // Ignore stray exits from non-active controllers
      return;
    }

    // Wakelock disable when ref count reaches zero
    if (!controller.allowedScreenSleep) {
      _wakelockRefs = (_wakelockRefs - 1).clamp(0, 1 << 30);
      if (_wakelockRefs == 0) {
        await WakelockPlus.disable();
      }
    }

    // Restore overlays/orientations per controller's afterFullScreen prefs
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: controller.systemOverlaysAfterFullScreen,
    );
    await SystemChrome.setPreferredOrientations(
      controller.deviceOrientationsAfterFullScreen,
    );

    _active = null;
    controller.emitEvent(ChewieEventType.fullscreenExitApplied);
  }
}
