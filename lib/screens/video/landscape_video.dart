import 'package:edu_gym/screens/video/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/video_cubit.dart';

class LandscapeVideo extends StatelessWidget {
  final bool isTrailer;
  const LandscapeVideo({super.key, required this.isTrailer});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    _hideStatusBar();
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_,x){
        context.read<VideoOrientationCubit>().portrait();
        if(isTrailer){
          context.read<VideoCubit>().disposePlayer();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Player(isTrailer: isTrailer,isLandscape: true,),
        ),
      ),
    );
  }

  void _hideStatusBar(){
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: [
      SystemUiOverlay.bottom
    ]);
  }
}
