import 'package:edu_gym/cubits/show_hide_video_cubit.dart';
import 'package:edu_gym/cubits/video_cubit.dart';
import 'package:edu_gym/features/module/presentation/cubit/lesson_cubit.dart';
import 'package:edu_gym/features/module/presentation/widget/lesson_details_shimmer.dart';
import 'package:edu_gym/modal/lesson.dart';
import 'package:edu_gym/screens/video/portrait_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/common/widgets/loader.dart';
import '../../../../core/cubit_states/data_state.dart';
import '../../../../screens/video/landscape_video.dart';
import '../widget/module_description.dart';
import '../widget/module_lesson.dart';
import '../../../../l10n/app_localizations.dart';

class LessonDetails extends StatelessWidget {
  final int lessonId;
  const LessonDetails({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return MultiBlocProvider(
        providers: [
          BlocProvider(create: (create)=>LessonCubit()..loadData(lessonId)),
          BlocProvider(create: (create)=>VideoCubit('')),
          BlocProvider(create: (create)=>ShowHideWidgetCubit()),
          BlocProvider(create: (create)=>VideoOrientationCubit()),
        ],
        child: BlocBuilder<VideoOrientationCubit,Orientation>(
          builder: (BuildContext context, Orientation state) {
            if(state== Orientation.landscape){
              return const LandscapeVideo(isTrailer: false,);
            }
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
            SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
            return Scaffold(
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    const PortraitPlayer(),
                    Expanded(
                      child: BlocConsumer<LessonCubit,DataState>(
                        builder: (BuildContext context, DataState state) {
                          // return LessonDetailsShimmer();
                          if(state is DataLoaded<Lesson>){
                            return CustomScrollView(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10.h,horizontal: 10.w),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(state.data.lessonTitle??'',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontSize: 20.sp
                                          ),
                                        ),
                                        SizedBox(height: 15.h,),

                                        ModuleDescription(description: state.data.lessonDes??''),

                                        SizedBox(height: 10.h,),
                                        const Divider(),
                                        SizedBox(height: 10.h,),
                                        Text(localizations?.translate('up_next') ?? "Up next",
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                              fontSize: 16.sp,
                                              color: Colors.brown,
                                              fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                        (context, index){
                                      return ModuleLesson(
                                        index: index,
                                        onTap: (){
                                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (builder)=>
                                              LessonDetails(lessonId: state.data.upNext![index].lessonId))
                                          );
                                        },
                                        padding: EdgeInsets.symmetric(vertical:10.h, horizontal: 10.w),
                                        lesson: state.data.upNext![index],
                                      );
                                    },
                                    childCount: state.data.upNext?.length??0,
                                  ),
                                ),
                              ],
                            );
                          }
                          else if(state is DataLoading){
                            return const LessonDetailsShimmer();
                          }
                          return const SizedBox();
                        },
                        listener: (BuildContext context, DataState state) {
                          if(state is DataLoaded<Lesson>){
                            context.read<VideoCubit>().loadVideo(link: state.data.lessonVideo
                                ,isTrailer: false);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },)
    );
  }
}
