import 'dart:async';

import 'package:chewie_flower/src/chewie_controller.dart';
import 'package:chewie_flower/src/chewie_controller_provider.dart';
import 'package:chewie_flower/src/chewie_types.dart';
import 'package:chewie_flower/src/notifiers/player_notifier.dart';
import 'package:chewie_flower/src/player_with_controls.dart';
import 'package:chewie_flower/src/default_chewie_full_screen.dart';
import 'package:chewie_flower/src/fullscreen_coordinator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A Video Player with Material and Cupertino skins.
///
/// `video_player` is pretty low level. Chewie wraps it in a friendly skin to
/// make it easy to use!
class Chewie extends StatefulWidget {
  const Chewie({super.key, required this.controller});

  /// The [ChewieController]
  final ChewieController controller;

  @override
  ChewieState createState() {
    return ChewieState();
  }
}

class ChewieState extends State<Chewie> {
  bool _isFullScreen = false;
  bool _wasPlayingBeforeFullScreen = false;
  bool _resumeAppliedInFullScreen = false;

  bool get isControllerFullScreen => widget.controller.isFullScreen;
  late PlayerNotifier notifier;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(listener);
    notifier = widget.controller.playerNotifier;
  }

  @override
  void dispose() {
    widget.controller.removeListener(listener);
    super.dispose();
  }

  @override
  void didUpdateWidget(Chewie oldWidget) {
    if (oldWidget.controller != widget.controller) {
      widget.controller.addListener(listener);
    }
    super.didUpdateWidget(oldWidget);
  }

  Future<void> listener() async {
    final wantsFullScreen = isControllerFullScreen;
    final isFullScreenNow = _isFullScreen;

    // Case 1: Enter requested and not currently fullscreen -> enter
    if (wantsFullScreen && !isFullScreenNow) {
      _wasPlayingBeforeFullScreen =
          widget.controller.videoPlayerController.value.isPlaying;
      _resumeAppliedInFullScreen = false;
      _isFullScreen = true;
      await _pushFullScreenWidget(context);
      return;
    }

    // Case 2: Exit requested and currently fullscreen -> exit
    if (!wantsFullScreen && isFullScreenNow) {
      final onExit = widget.controller.onExitFullScreenRequested;
      if (onExit != null) {
        final allow = await onExit(context);
        if (allow) {
          // Host app handles pop; we just perform teardown.
          await _teardownAfterFullScreen();
        }
        // If not allowed, do nothing and keep fullscreen flag as is
        return;
      }
    }

    // Case 3: Enter requested but already fullscreen -> ignore (no-op)
    // Case 4: Exit requested but already normal -> ignore (no-op)
  }

  @override
  Widget build(BuildContext context) {
    return ChewieControllerProvider(
      controller: widget.controller,
      child: ChangeNotifierProvider<PlayerNotifier>.value(
        value: widget.controller.playerNotifier,
        builder: (context, w) => const PlayerWithControls(),
      ),
    );
  }

  Widget _buildFullScreenVideo(
    BuildContext context,
    Animation<double> animation,
    ChewieControllerProvider controllerProvider,
  ) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: controllerProvider,
      ),
    );
  }

  AnimatedWidget _defaultRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    ChewieControllerProvider controllerProvider,
  ) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        return _buildFullScreenVideo(context, animation, controllerProvider);
      },
    );
  }

  Widget _fullScreenRoutePageBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final controllerProvider = ChewieControllerProvider(
      controller: widget.controller,
      child: ChangeNotifierProvider<PlayerNotifier>.value(
        value: notifier,
        builder: (context, w) => const PlayerWithControls(),
      ),
    );

    if (kIsWeb && !_resumeAppliedInFullScreen) {
      _resumeAppliedInFullScreen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final vpc = widget.controller.videoPlayerController;
        await vpc.pause();
        await Future<void>.delayed(const Duration(milliseconds: 10));
        if (_wasPlayingBeforeFullScreen) {
          await vpc.play();
        } else {
          await vpc.play();
          await vpc.pause();
        }
      });
    }

    if (widget.controller.routePageBuilder == null) {
      return _defaultRoutePageBuilder(
        context,
        animation,
        secondaryAnimation,
        controllerProvider,
      );
    }
    return widget.controller.routePageBuilder!(
      context,
      animation,
      secondaryAnimation,
      controllerProvider,
    );
  }

  Future<dynamic> _pushFullScreenWidget(BuildContext context) async {
    Route<void> defaultRouteBuilder() => PageRouteBuilder<void>(
      pageBuilder: (ctx, a, sa) => _fullScreenRoutePageBuilder(ctx, a, sa),
    );

    // If host app wants to handle routing, ask permission and delegate
    final onEnter = widget.controller.onEnterFullScreenRequested;
    if (onEnter != null) {
      widget.controller.emitEvent(ChewieEventType.fullscreenEnterRequested);
      final allow = await onEnter(
        context,
        (ctx) => DefaultChewieFullScreen(controller: widget.controller),
        defaultRouteBuilder,
      );
      if (allow) {
        widget.controller.emitEvent(ChewieEventType.fullscreenEnterApproved);
        // Host app presents the route; we only perform global side-effects via coordinator.
        final ok = FullscreenCoordinator.instance.requestEnter(
          widget.controller,
        );
        if (ok) {
          await FullscreenCoordinator.instance.applyEnterSideEffects(
            widget.controller,
          );
        } else {
          // Denied by policy; revert flag
          _isFullScreen = false;
          widget.controller.exitFullScreen();
          widget.controller.emitEvent(ChewieEventType.fullscreenPolicyDenied);
        }
        return; // Do not push our own route
      } else {
        // Not allowed -> revert the flag and return
        _isFullScreen = false;
        widget.controller.exitFullScreen();
        widget.controller.emitEvent(ChewieEventType.fullscreenEnterDenied);
        return;
      }
    }

    final decision = FullscreenCoordinator.instance.requestEnterDecision(widget.controller);
    if (decision.allowed) {
      if (decision.needsSideEffects) {
        await FullscreenCoordinator.instance.applyEnterSideEffects(
          widget.controller,
        );
      }
    } else {
      _isFullScreen = false;
      widget.controller.exitFullScreen();
      widget.controller.emitEvent(ChewieEventType.fullscreenPolicyDenied);
      return;
    }

    await _teardownAfterFullScreen();
  }

  Future<void> _teardownAfterFullScreen() async {
    widget.controller.emitEvent(ChewieEventType.fullscreenExitRequested);
    final wasPlaying = widget.controller.videoPlayerController.value.isPlaying;

    if (kIsWeb) {
      await _reInitializeControllers(wasPlaying);
    }

    _isFullScreen = false;
    widget.controller.exitFullScreen();
    await FullscreenCoordinator.instance.applyExitSideEffects(
      widget.controller,
    );
  }

  /// When viewing full screen on web, returning from full screen could cause
  /// the original video element to lose the picture. We re-initialize the
  /// controllers for web only when returning from full screen and preserve
  /// the previous play/pause state.
  Future<void> _reInitializeControllers(bool wasPlaying) async {
    final prevPosition = widget.controller.videoPlayerController.value.position;

    await widget.controller.videoPlayerController.initialize();
    widget.controller.initialize();
    await widget.controller.videoPlayerController.seekTo(prevPosition);

    if (wasPlaying) {
      await widget.controller.videoPlayerController.play();
    } else {
      await widget.controller.videoPlayerController.play();
      await widget.controller.videoPlayerController.pause();
    }
  }
}
