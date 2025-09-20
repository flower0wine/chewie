import 'package:chewie_flower/src/notifiers/player_notifier.dart';
import 'package:chewie_flower/src/chewie_controller.dart';
import 'package:chewie_flower/src/chewie_controller_provider.dart';
import 'package:chewie_flower/src/player_with_controls.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DefaultChewieFullScreen extends StatelessWidget {
  const DefaultChewieFullScreen({
    super.key,
    required this.controller,
  });

  final ChewieController controller;

  @override
  Widget build(BuildContext context) {
    final controllerProvider = ChewieControllerProvider(
      controller: controller,
      child: ChangeNotifierProvider<PlayerNotifier>.value(
        value: controller.playerNotifier,
        builder: (context, w) => const PlayerWithControls(),
      ),
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        alignment: Alignment.center,
        color: Colors.black,
        child: controllerProvider,
      ),
    );
  }
}
