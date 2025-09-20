import 'package:flutter/material.dart';
import 'package:chewie_flower/src/chewie_controller_provider.dart';

typedef ChewieRoutePageBuilder =
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      ChewieControllerProvider controllerProvider,
    );

/// How to present the fullscreen route
enum FullScreenRouteType {
  /// Use Navigator.push to present fullscreen
  push,

  /// Use Navigator.pushReplacement to present fullscreen
  /// Suitable for declarative routing stacks where replacing the page is preferred
  replace,
}

/// Callback to let the host app decide whether entering fullscreen is allowed
/// and optionally handle the routing itself.
///
/// The [defaultFullScreenContentBuilder] builds Chewie's default fullscreen
/// content using the current Chewie instance's state (including its notifier),
/// and the [defaultFullScreenRouteBuilder] builds a default route that presents
/// that content. You can reuse either in your routing implementation.
typedef OnEnterFullScreenRequested =
    Future<bool> Function(
      BuildContext context,
      WidgetBuilder defaultFullScreenContentBuilder,
      Route<void> Function() defaultFullScreenRouteBuilder,
    );

/// Callback to let the host app decide whether exiting fullscreen is allowed
/// and optionally handle the pop/routing itself.
typedef OnExitFullScreenRequested = Future<bool> Function(BuildContext context);

/// Generic event types to observe important Chewie lifecycle changes.
enum ChewieEventType {
  fullscreenEnterRequested,
  fullscreenEnterApproved,
  fullscreenEnterDenied,
  fullscreenPolicyDenied,
  fullscreenEnterApplied,
  fullscreenExitRequested,
  fullscreenExitApproved,
  fullscreenExitDenied,
  fullscreenExitApplied,
}

/// Generic event payload for Chewie lifecycle changes.
class ChewieEvent {
  ChewieEvent({
    required this.type,
    required this.controller,
    DateTime? timestamp,
    this.metadata,
  }) : timestamp = timestamp ?? DateTime.now();

  final ChewieEventType type;
  final dynamic
  controller; // ChewieController, kept dynamic to avoid cycle here
  final DateTime timestamp;
  final Map<String, Object?>? metadata;
}

/// Callback to observe ChewieEvents
typedef ChewieEventCallback = void Function(ChewieEvent event);
