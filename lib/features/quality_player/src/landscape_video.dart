import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/player_cubit.dart';

class LandscapeVideo extends StatefulWidget {
  final bool alwaysLandscape;
  final Widget player;
  const LandscapeVideo({super.key, this.alwaysLandscape=false, required this.player});

  @override
  State<LandscapeVideo> createState() => _LandscapeVideoState();
}

class _LandscapeVideoState extends State<LandscapeVideo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setLandscapeOrientation();
    });
  }

  void _setLandscapeOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.alwaysLandscape,
      onPopInvokedWithResult: (didPop, result){
        if(widget.alwaysLandscape){
          if(didPop) {
            // Reset orientation to portrait after successful pop
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
          }
        }
        else {
          if(!didPop) {
            context.read<VideoOrientationCubit>().portrait();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
            child: widget.player
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Reset orientation when widget is disposed
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
