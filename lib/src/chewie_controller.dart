import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie_flower/src/chewie_types.dart';
import 'package:chewie_flower/src/chewie_progress_colors.dart';
import 'package:chewie_flower/src/chewie_controller_provider.dart';
import 'package:chewie_flower/src/models/option_item.dart';
import 'package:chewie_flower/src/models/options_translation.dart';
import 'package:chewie_flower/src/models/subtitle_model.dart';
import 'package:chewie_flower/src/notifiers/player_notifier.dart';

class ChewieController extends ChangeNotifier {
  ChewieController({
    required VideoPlayerController videoPlayerController,
    this.optionsTranslation,
    this.aspectRatio,
    this.autoInitialize = false,
    this.autoPlay = false,
    this.draggableProgressBar = true,
    this.startAt,
    this.looping = false,
    this.fullScreenByDefault = false,
    this.cupertinoProgressColors,
    this.materialProgressColors,
    this.materialSeekButtonFadeDuration = const Duration(milliseconds: 300),
    this.materialSeekButtonSize = 26,
    this.placeholder,
    this.overlay,
    this.showControlsOnInitialize = true,
    this.showOptions = true,
    this.optionsBuilder,
    this.additionalOptions,
    this.showControls = true,
    this.transformationController,
    this.zoomAndPan = false,
    this.maxScale = 2.5,
    this.subtitle,
    this.showSubtitles = false,
    this.subtitleBuilder,
    this.customControls,
    this.errorBuilder,
    this.bufferingBuilder,
    this.allowedScreenSleep = true,
    this.isLive = false,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.allowPlaybackSpeedChanging = true,
    this.useRootNavigator = true,
    this.playbackSpeeds = const [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2],
    this.systemOverlaysOnEnterFullScreen,
    this.deviceOrientationsOnEnterFullScreen,
    this.systemOverlaysAfterFullScreen = SystemUiOverlay.values,
    this.deviceOrientationsAfterFullScreen = DeviceOrientation.values,
    this.routePageBuilder,
    this.progressIndicatorDelay,
    this.hideControlsTimer = defaultHideControlsTimer,
    this.controlsSafeAreaMinimum = EdgeInsets.zero,
    this.pauseOnBackgroundTap = false,
    this.onEnterFullScreenRequested,
    this.onExitFullScreenRequested,
    this.onEvent,
  }) : assert(
         playbackSpeeds.every((speed) => speed > 0),
         'The playbackSpeeds values must all be greater than 0',
       ),
       _activeVideoPlayerController = videoPlayerController {
    initialize();
  }

  @override
  void dispose() {
    playerNotifier.dispose();
    super.dispose();
  }

  ChewieController copyWith({
    VideoPlayerController? videoPlayerController,
    OptionsTranslation? optionsTranslation,
    double? aspectRatio,
    bool? autoInitialize,
    bool? autoPlay,
    bool? draggableProgressBar,
    Duration? startAt,
    bool? looping,
    bool? fullScreenByDefault,
    ChewieProgressColors? cupertinoProgressColors,
    ChewieProgressColors? materialProgressColors,
    Duration? materialSeekButtonFadeDuration,
    double? materialSeekButtonSize,
    Widget? placeholder,
    Widget? overlay,
    bool? showControlsOnInitialize,
    bool? showOptions,
    Future<void> Function(BuildContext, List<OptionItem>)? optionsBuilder,
    List<OptionItem> Function(BuildContext)? additionalOptions,
    bool? showControls,
    TransformationController? transformationController,
    bool? zoomAndPan,
    double? maxScale,
    Subtitles? subtitle,
    bool? showSubtitles,
    Widget Function(BuildContext, dynamic)? subtitleBuilder,
    Widget? customControls,
    WidgetBuilder? bufferingBuilder,
    Widget Function(BuildContext, String)? errorBuilder,
    bool? allowedScreenSleep,
    bool? isLive,
    bool? allowFullScreen,
    bool? allowMuting,
    bool? allowPlaybackSpeedChanging,
    bool? useRootNavigator,
    Duration? hideControlsTimer,
    EdgeInsets? controlsSafeAreaMinimum,
    List<double>? playbackSpeeds,
    List<SystemUiOverlay>? systemOverlaysOnEnterFullScreen,
    List<DeviceOrientation>? deviceOrientationsOnEnterFullScreen,
    List<SystemUiOverlay>? systemOverlaysAfterFullScreen,
    List<DeviceOrientation>? deviceOrientationsAfterFullScreen,
    Duration? progressIndicatorDelay,
    Widget Function(
      BuildContext,
      Animation<double>,
      Animation<double>,
      ChewieControllerProvider,
    )?
    routePageBuilder,
    bool? pauseOnBackgroundTap,
    OnEnterFullScreenRequested? onEnterFullScreenRequested,
    OnExitFullScreenRequested? onExitFullScreenRequested,
  }) {
    return ChewieController(
      draggableProgressBar: draggableProgressBar ?? this.draggableProgressBar,
      videoPlayerController:
          videoPlayerController ?? this.videoPlayerController,
      optionsTranslation: optionsTranslation ?? this.optionsTranslation,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      autoInitialize: autoInitialize ?? this.autoInitialize,
      autoPlay: autoPlay ?? this.autoPlay,
      startAt: startAt ?? this.startAt,
      looping: looping ?? this.looping,
      fullScreenByDefault: fullScreenByDefault ?? this.fullScreenByDefault,
      cupertinoProgressColors:
          cupertinoProgressColors ?? this.cupertinoProgressColors,
      materialProgressColors:
          materialProgressColors ?? this.materialProgressColors,
      zoomAndPan: zoomAndPan ?? this.zoomAndPan,
      maxScale: maxScale ?? this.maxScale,
      controlsSafeAreaMinimum:
          controlsSafeAreaMinimum ?? this.controlsSafeAreaMinimum,
      transformationController:
          transformationController ?? this.transformationController,
      materialSeekButtonFadeDuration:
          materialSeekButtonFadeDuration ?? this.materialSeekButtonFadeDuration,
      materialSeekButtonSize:
          materialSeekButtonSize ?? this.materialSeekButtonSize,
      placeholder: placeholder ?? this.placeholder,
      overlay: overlay ?? this.overlay,
      showControlsOnInitialize:
          showControlsOnInitialize ?? this.showControlsOnInitialize,
      showOptions: showOptions ?? this.showOptions,
      optionsBuilder: optionsBuilder ?? this.optionsBuilder,
      additionalOptions: additionalOptions ?? this.additionalOptions,
      showControls: showControls ?? this.showControls,
      showSubtitles: showSubtitles ?? this.showSubtitles,
      subtitle: subtitle ?? this.subtitle,
      subtitleBuilder: subtitleBuilder ?? this.subtitleBuilder,
      customControls: customControls ?? this.customControls,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      bufferingBuilder: bufferingBuilder ?? this.bufferingBuilder,
      allowedScreenSleep: allowedScreenSleep ?? this.allowedScreenSleep,
      isLive: isLive ?? this.isLive,
      allowFullScreen: allowFullScreen ?? this.allowFullScreen,
      allowMuting: allowMuting ?? this.allowMuting,
      allowPlaybackSpeedChanging:
          allowPlaybackSpeedChanging ?? this.allowPlaybackSpeedChanging,
      useRootNavigator: useRootNavigator ?? this.useRootNavigator,
      playbackSpeeds: playbackSpeeds ?? this.playbackSpeeds,
      systemOverlaysOnEnterFullScreen:
          systemOverlaysOnEnterFullScreen ??
          this.systemOverlaysOnEnterFullScreen,
      deviceOrientationsOnEnterFullScreen:
          deviceOrientationsOnEnterFullScreen ??
          this.deviceOrientationsOnEnterFullScreen,
      systemOverlaysAfterFullScreen:
          systemOverlaysAfterFullScreen ?? this.systemOverlaysAfterFullScreen,
      deviceOrientationsAfterFullScreen:
          deviceOrientationsAfterFullScreen ??
          this.deviceOrientationsAfterFullScreen,
      routePageBuilder: routePageBuilder ?? this.routePageBuilder,
      hideControlsTimer: hideControlsTimer ?? this.hideControlsTimer,
      progressIndicatorDelay:
          progressIndicatorDelay ?? this.progressIndicatorDelay,
      pauseOnBackgroundTap: pauseOnBackgroundTap ?? this.pauseOnBackgroundTap,
      onEnterFullScreenRequested:
          onEnterFullScreenRequested ?? this.onEnterFullScreenRequested,
      onExitFullScreenRequested:
          onExitFullScreenRequested ?? this.onExitFullScreenRequested,
    );
  }

  static const defaultHideControlsTimer = Duration(seconds: 3);

  /// Exposed player UI notifier for sharing between in-page and fullscreen
  /// This replaces previous widget-local notifier usage.
  final PlayerNotifier playerNotifier = PlayerNotifier.init();

  /// Optional generic event callback for lifecycle notifications.
  final ChewieEventCallback? onEvent;

  void emitEvent(ChewieEventType type, {Map<String, Object?>? metadata}) {
    final cb = onEvent;
    if (cb != null) {
      cb(ChewieEvent(type: type, controller: this, metadata: metadata));
    }
  }

  final bool showOptions;
  final OptionsTranslation? optionsTranslation;
  final Future<void> Function(
    BuildContext context,
    List<OptionItem> chewieOptions,
  )?
  optionsBuilder;
  final List<OptionItem> Function(BuildContext context)? additionalOptions;
  Widget Function(BuildContext context, dynamic subtitle)? subtitleBuilder;
  Subtitles? subtitle;
  bool showSubtitles;

  VideoPlayerController get videoPlayerController =>
      _activeVideoPlayerController;
  late VideoPlayerController _activeVideoPlayerController;
  VideoPlayerController? _preparingVideoPlayerController;

  bool _isSwitching = false;
  bool get isSwitching => _isSwitching;

  final bool autoInitialize;
  final bool autoPlay;
  final bool draggableProgressBar;
  final Duration? startAt;
  final bool looping;
  final bool showControlsOnInitialize;
  final bool showControls;
  final TransformationController? transformationController;
  final bool zoomAndPan;
  final double maxScale;
  final Widget? customControls;
  final Widget Function(BuildContext context, String errorMessage)?
  errorBuilder;
  final WidgetBuilder? bufferingBuilder;
  final double? aspectRatio;
  final ChewieProgressColors? cupertinoProgressColors;
  final ChewieProgressColors? materialProgressColors;
  final Duration materialSeekButtonFadeDuration;
  final double materialSeekButtonSize;
  final Widget? placeholder;
  final Widget? overlay;
  final bool fullScreenByDefault;
  final bool allowedScreenSleep;
  final bool isLive;
  final bool allowFullScreen;
  final bool allowMuting;
  final bool allowPlaybackSpeedChanging;
  final bool useRootNavigator;
  final Duration hideControlsTimer;
  final List<double> playbackSpeeds;
  final List<SystemUiOverlay>? systemOverlaysOnEnterFullScreen;
  final List<DeviceOrientation>? deviceOrientationsOnEnterFullScreen;
  final List<SystemUiOverlay> systemOverlaysAfterFullScreen;
  final List<DeviceOrientation> deviceOrientationsAfterFullScreen;
  final ChewieRoutePageBuilder? routePageBuilder;
  final Duration? progressIndicatorDelay;
  final EdgeInsets controlsSafeAreaMinimum;
  final bool pauseOnBackgroundTap;
  final OnEnterFullScreenRequested? onEnterFullScreenRequested;
  final OnExitFullScreenRequested? onExitFullScreenRequested;

  static ChewieController of(BuildContext context) {
    final chewieControllerProvider = context
        .dependOnInheritedWidgetOfExactType<ChewieControllerProvider>()!;
    return chewieControllerProvider.controller;
  }

  bool _isFullScreen = false;
  bool get isFullScreen => _isFullScreen;
  bool get isPlaying => videoPlayerController.value.isPlaying;

  Future<dynamic> initialize() async {
    await videoPlayerController.setLooping(looping);

    if ((autoInitialize || autoPlay) &&
        !videoPlayerController.value.isInitialized) {
      await videoPlayerController.initialize();
    }

    if (autoPlay) {
      if (fullScreenByDefault) {
        enterFullScreen();
      }
      await videoPlayerController.play();
    }

    if (startAt != null) {
      await videoPlayerController.seekTo(startAt!);
    }

    if (fullScreenByDefault) {
      videoPlayerController.addListener(_fullScreenListener);
    }
  }

  Future<void> prepareNext(
    VideoPlayerController next, {
    Duration? startAt,
    bool warmUp = false,
  }) async {
    _preparingVideoPlayerController = next;
    if (!next.value.isInitialized) {
      await next.initialize();
    }
    if (startAt != null && !isLive) {
      await next.seekTo(startAt);
    }
    if (warmUp) {
      await next.play();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await next.pause();
    }
  }

  Future<void> switchToPrepared({
    bool keepPosition = true,
    bool preservePlayState = true,
    bool preserveVolume = true,
    bool preserveLooping = true,
    bool preserveSpeed = true,
    bool crossfade = true,
    bool disposeOld = true,
  }) async {
    final next = _preparingVideoPlayerController;
    if (next == null) return;

    await _switchToInternal(
      next,
      keepPosition: keepPosition,
      preservePlayState: preservePlayState,
      preserveVolume: preserveVolume,
      preserveLooping: preserveLooping,
      preserveSpeed: preserveSpeed,
      crossfade: crossfade,
      disposeOld: disposeOld,
    );

    _preparingVideoPlayerController = null;
  }

  Future<void> switchTo(
    VideoPlayerController next, {
    Duration? startAt,
    bool keepPosition = true,
    bool preservePlayState = true,
    bool preserveVolume = true,
    bool preserveLooping = true,
    bool preserveSpeed = true,
    bool crossfade = true,
    bool disposeOld = true,
    bool warmUp = false,
  }) async {
    await prepareNext(next, startAt: startAt, warmUp: warmUp);
    await switchToPrepared(
      keepPosition: keepPosition,
      preservePlayState: preservePlayState,
      preserveVolume: preserveVolume,
      preserveLooping: preserveLooping,
      preserveSpeed: preserveSpeed,
      crossfade: crossfade,
      disposeOld: disposeOld,
    );
  }

  Future<void> _switchToInternal(
    VideoPlayerController next, {
    required bool keepPosition,
    required bool preservePlayState,
    required bool preserveVolume,
    required bool preserveLooping,
    required bool preserveSpeed,
    required bool crossfade,
    required bool disposeOld,
  }) async {
    final old = _activeVideoPlayerController;

    final wasInitialized = old.value.isInitialized;
    final wasPlaying = old.value.isPlaying;
    final oldPosition = wasInitialized && !isLive ? old.value.position : null;
    final oldVolume = old.value.volume;
    final oldLooping = old.value.isLooping;
    final oldSpeed = old.value.playbackSpeed;

    if (!next.value.isInitialized) {
      await next.initialize();
    }

    if (crossfade) {
      _isSwitching = true;
      notifyListeners();
    }

    if (wasPlaying) {
      await old.pause();
    }

    if (preserveLooping) {
      await next.setLooping(oldLooping);
    } else {
      await next.setLooping(looping);
    }
    if (preserveVolume) {
      await next.setVolume(oldVolume);
    }
    if (preserveSpeed) {
      try {
        await next.setPlaybackSpeed(oldSpeed);
      } catch (_) {}
    }

    if (keepPosition && oldPosition != null) {
      await next.seekTo(oldPosition);
    } else if (startAt != null) {
      await next.seekTo(startAt!);
    }

    _activeVideoPlayerController = next;
    notifyListeners();

    if (preservePlayState && wasPlaying) {
      await next.play();
    } else if (!preservePlayState && autoPlay) {
      await next.play();
    }

    if (crossfade) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      _isSwitching = false;
      notifyListeners();
    }

    if (disposeOld) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      await old.dispose();
    }
  }

  Future<void> _fullScreenListener() async {
    if (videoPlayerController.value.isPlaying && !_isFullScreen) {
      enterFullScreen();
      videoPlayerController.removeListener(_fullScreenListener);
    }
  }

  void enterFullScreen() {
    _isFullScreen = true;
    notifyListeners();
  }

  void exitFullScreen() {
    _isFullScreen = false;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  void togglePause() {
    isPlaying ? pause() : play();
  }

  Future<void> play() async {
    await videoPlayerController.play();
  }

  Future<void> setLooping(bool looping) async {
    await videoPlayerController.setLooping(looping);
  }

  Future<void> pause() async {
    await videoPlayerController.pause();
  }

  Future<void> seekTo(Duration moment) async {
    await videoPlayerController.seekTo(moment);
  }

  Future<void> setVolume(double volume) async {
    await videoPlayerController.setVolume(volume);
  }

  void setSubtitle(List<Subtitle> newSubtitle) {
    subtitle = Subtitles(newSubtitle);
  }
}
