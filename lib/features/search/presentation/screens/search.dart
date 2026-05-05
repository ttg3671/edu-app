import 'package:edu_gym/features/module/presentation/screens/module_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../cubit/search_cubit.dart';
import '../widgets/module_search_card.dart';
import '../../../../l10n/app_localizations.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

class _SearchState extends State<Search> {
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h,horizontal: 10.w),
      child: Column(
        children: [

          Container(
            padding: EdgeInsets.symmetric(vertical: 5.h,horizontal: 5.w),
            decoration: BoxDecoration(
              color: Theme.of(context).textTheme.titleSmall?.color?.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: localizations?.translate('search_hint') ?? 'Search..',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
                    ),
                    style: Theme.of(context).textTheme.titleSmall,
                    onChanged: (s){
                      context.read<SearchCubit>().search(s);
                    },
                  ),
                ),
                SizedBox(width: 10.w,),
                InkWell(
                    onTap: (){
                      FocusManager.instance.primaryFocus?.unfocus();
                      context.read<SearchCubit>().search(searchController.text);
                    },
                    child: Icon(Icons.search,color: Colors.blue,size: 25.sp,)),
                SizedBox(width: 10.w,),
              ],
            ),
          ),
          SizedBox(height: 20.h,),
          BlocConsumer<SearchCubit,SearchState>(
              builder: (context,state){
                if(state is RecentLoaded){
                  return Expanded(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(localizations?.translate('recent_searches') ?? "Recent Searches",style: Theme.of(context).textTheme.titleSmall,),
                            InkWell(
                              onTap: () {
                                context.read<SearchCubit>().clearPrefs();
                              },
                              child: Text(localizations?.translate('clear') ?? "Clear",style: GoogleFonts.poppins(color: Colors.red,fontWeight: FontWeight.bold),),
                            )
                          ],
                        ),
                        SizedBox(height: 10.h,),
                        BlocBuilder<SearchCubit,SearchState>(
                          builder: (BuildContext context, SearchState state) {

                            if(state is RecentLoaded){
                              // print('$state ${state.list.length}');
                              return Expanded(
                                  child: ListView.separated(
                                    itemCount: state.list.length,
                                    itemBuilder: (context,index){
                                      return InkWell(
                                        onTap: (){
                                          searchController.text=state.list[index];
                                          // FocusManager.instance.primaryFocus?.unfocus();
                                        },
                                        child: Text(state.list[index],
                                          style: Theme.of(context).textTheme.bodyMedium,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    },
                                    separatorBuilder: (context,index){
                                      return SizedBox(height: 20.h,);
                                    },
                                  )
                              );
                            }
                            return Container();
                          },

                        ),
                      ],
                    ),
                  );
                }
                else if(state is SearchLoading){
                  return const Expanded(child: Center(child: CircularProgressIndicator()));
                }
                else if(state is SearchLoaded){
                  return Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: 10.h,),
                        Expanded(
                          child: GridView.builder(
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 1.4,
                              crossAxisSpacing: 10.w,
                              mainAxisSpacing: 15.h,
                            ),
                            itemCount: state.searchModal.modules.length,
                            itemBuilder: (context,index){
                              final module = state.searchModal.modules[index];
                              return InkWell(
                                onTap: (){
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  context.read<SearchCubit>().saveToPrefs();
                                  Navigator.push(context, MaterialPageRoute(builder:
                                      (context)=>ModuleDetails(
                                          moduleId: module.moduleId,
                                          moduleTitle: module.moduleTitle
                                      )
                                  ));
                                },
                                child: ModuleSearchCard(module: module),
                              );
                            },
                          ),
                        )
                      ],
                    ),
                  );
                }
                return Container();
              },
            listener: (context,state){},
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
