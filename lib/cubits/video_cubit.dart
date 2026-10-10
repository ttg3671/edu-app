
import 'package:edu_gym/api/token_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';


class VideoCubit extends Cubit<VideoState>{

  VideoCubit(this.episodeId): super(VideoInitial());

  VideoPlayerController? _controller;
  bool _showControls=false;
  bool _isControlChecking=false;
  final String? episodeId;
  int? lastWatchedPosition;
  // VideoData? videoData;
  String? currentQuality;

  Future<void> loadVideo({String? link,String? trailerId, required bool? isTrailer,}) async {
    WakelockPlus.enable();
    emit(VideoLoading());

    // 1. Check if user is logged in
    if (!TokenApi.isUserLoggedIn()) {
      emit(AuthRequired());
      return;
    }

    // Access control is handled by the caller (e.g., ModuleDetails)
    // which has full context on module pricing and user subscription.

    initVideoPlayer(link: link??'');
  }

  Future<void> initVideoPlayer({required String link,String? quality,}) async {
    // print(link);
    emit(VideoLoading());
    // print(quality);
    try {
      _controller?.dispose();
    } catch (e) {
      // print('null');
    }
    // link="https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4";

    _controller = VideoPlayerController.networkUrl(Uri.parse(
        link))
      ..initialize().then((_) {

        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        if(!isClosed) {
          if(lastWatchedPosition!=null){
            _controller!.seekTo(Duration(seconds: lastWatchedPosition??0));
          }
          _controller!.play();
          _showControls=false;
          // emit(VideoInitialized(videoPlayerController: _controller!,
          //     showControls: _showControls,videoQualities: videoData?.qualities,currentQuality: quality));
          emit(VideoInitialized(videoPlayerController: _controller!,
              showControls: _showControls,currentQuality: quality));
        }
      },onError: (_){
        if(!isClosed){
          emit(VideoError(link));
        }
      });
    _controller!.addListener(() async {
      if(_controller!.value.isPlaying && _showControls && !_isControlChecking){
        _isControlChecking=true;
        await Future.delayed(const Duration(seconds: 3));
        _isControlChecking=false;
        if(_controller!.value.isPlaying && _showControls && !isClosed){
          // print("showC $_showControls");
          _showControls=!_showControls;
          // emit(VideoInitialized(videoPlayerController: _controller!,
          //     showControls: _showControls,videoQualities: videoData?.qualities,currentQuality: quality));
          emit(VideoInitialized(videoPlayerController: _controller!,
              showControls: _showControls,currentQuality: quality));

        }
      }
    });
  }

  void changeSpeed(double speed){
    if(speed==_controller!.value.playbackSpeed) return;
    _controller!.setPlaybackSpeed(speed);
    // emit(VideoInitialized(videoPlayerController: _controller!,
    //     showControls: _showControls,videoQualities: videoData?.qualities));
    emit(VideoInitialized(videoPlayerController: _controller!,
        showControls: _showControls,));
  }

  // Future<void> changeQuality(String quality) async {
  //   if(quality==currentQuality) return;
  //   // emit(VideoLoading());
  //   String? link;
  //   List<VideoVersion>? list;
  //   if(quality.toLowerCase()=='adaptive'){
  //     list=videoData?.hlsVersions;
  //   }
  //   else if(int.parse(quality)>=720){ //hd versions
  //     list=videoData?.hdVersions;
  //   }
  //   else{
  //     list=videoData?.sdVersions;
  //   }
  //   for(VideoVersion videoVersion in list??[]){
  //     if(videoVersion.rendition.contains(quality)){
  //       link=videoVersion.link;
  //       break;
  //     }
  //   }
  //   // print(link);
  //   if(link!=null){
  //     currentQuality=quality;
  //     lastWatchedPosition=(await _controller?.position)?.inSeconds;
  //     initVideoPlayer(link: link,quality: quality,);
  //   }
  // }

  void toggleControls(){
    _showControls=!_showControls;
    emit(VideoInitialized(videoPlayerController: _controller!,
        showControls: _showControls,));
  }

  void toggleVideoPlay(){
    _controller!.value.isPlaying?
    _controller!.pause(): _controller!.play();

    emit(VideoInitialized(videoPlayerController: _controller!,
        showControls: _showControls,));
  }

  void forwardVideo(){
    final currentPosition = _controller!.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    _controller!.seekTo(newPosition);
  }

  void disposePlayer(){
    if(_controller!=null) {
      _controller!.dispose();
    }
  }

  void backwardVideo(){
    final currentPosition = _controller!.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    _controller!.seekTo(newPosition);
  }

  /// Called when a Cast session starts/ends. While casting, the TV is the
  /// one playing the video, so the local (invisible) player is paused and
  /// muted instead of fighting the receiver for audio output. Playback
  /// itself while casting is driven entirely by GoogleCastRemoteMediaClient
  /// from the UI layer, not by this cubit.
  void setCastingActive(bool active){
    if(_controller==null) return;
    if(active){
      _controller!.pause();
      _controller!.setVolume(0);
    } else {
      _controller!.setVolume(1);
    }
  }

  void pauseVideo(){
    if(_controller!=null){
      _controller!.pause();
    }
  }

  void playVideo(){
    if(_controller!=null){
      _controller!.play();
    }
  }



  @override
  Future<void> close() {
    WakelockPlus.disable();
    if(_controller!=null) {
      _controller!.dispose();
    }
    return super.close();
  }

}

class VideoOrientationCubit extends Cubit<Orientation>{
  VideoOrientationCubit():super(Orientation.portrait);

  void landscape(){
    emit(Orientation.landscape);
  }

  void portrait(){
    emit(Orientation.portrait);
  }
}

abstract class VideoEvent{}


abstract class VideoState{}

class VideoInitial extends VideoState{}

class VideoLoading extends VideoState{}

class VideoInitialized extends VideoState{
  final VideoPlayerController videoPlayerController;
  final bool showControls;
  final List<String>? videoQualities;
  final String? currentQuality;
  VideoInitialized({required this.videoPlayerController, required this.showControls,
    this.videoQualities,this.currentQuality, });
}
class VideoError extends VideoState{
  final String videoLink;

  VideoError(this.videoLink);
}
class VideoPaused extends VideoState{}

class SubNotActive extends VideoState{}

class AuthRequired extends VideoState{}
