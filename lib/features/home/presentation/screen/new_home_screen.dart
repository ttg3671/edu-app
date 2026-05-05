import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_gym/core/common/widgets/custom_shimmer.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/cubits/navigation_cubit.dart';
import 'package:edu_gym/features/auth/presentation/pages/starting_screen.dart';
import 'package:edu_gym/features/home/presentation/cubit/new_home_cubit.dart';
import 'package:edu_gym/features/home/presentation/widget/home_shimmer_loading.dart';
import 'package:edu_gym/features/module/presentation/screens/module_details.dart';
import 'package:edu_gym/modal/new_home_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class NewHomeScreen extends StatefulWidget {
  const NewHomeScreen({super.key});

  @override
  State<NewHomeScreen> createState() => _NewHomeScreenState();
}

class _NewHomeScreenState extends State<NewHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  // Track selected filters: {groupId: {categoryId}}
  final Map<int, Set<int>> _selectedFilters = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  String _capitalizeFirstWord(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll <= 200) {
      context.read<NewHomeCubit>().loadMoreSections();
    }
  }

  void _showFilterBottomSheet(List<FilterGroup> filterArray) {
    final cubit = context.read<NewHomeCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocProvider.value(
          value: cubit,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
              height: MediaQuery.of(context).size.height * 0.6,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.r),
                  topRight: Radius.circular(20.r),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              _selectedFilters.clear();
                              context.read<NewHomeCubit>().filterByCategory(null);
                            });
                          },
                          child: Text(
                            'Reset All',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade300),
                  
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      itemCount: filterArray.length,
                      itemBuilder: (context, index) {
                        final group = filterArray[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Text(
                                _capitalizeFirstWord(group.name),
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 15.h),
                            
                            // Horizontal Categories Row
                            SizedBox(
                              height: 45.h,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: EdgeInsets.symmetric(horizontal: 15.w),
                                itemCount: group.categories.length + 1, // +1 for "Show All"
                                itemBuilder: (context, catIndex) {
                                  final isShowAll = catIndex == 0;
                                  final cat = isShowAll ? null : group.categories[catIndex - 1];
                                  
                                  // "Show All" is selected if no categories in this group are selected
                                  final isGroupEmpty = _selectedFilters[group.id] == null || _selectedFilters[group.id]!.isEmpty;
                                  final isSelected = isShowAll ? isGroupEmpty : (_selectedFilters[group.id]?.contains(cat!.id) ?? false);
                                  
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {
                                      // print('👆 Category clicked: ${isShowAll ? "Show All" : cat?.name} (id: ${cat?.id})');
                                      setModalState(() {
                                        if (isShowAll) {
                                          _selectedFilters[group.id]?.clear();
                                          context.read<NewHomeCubit>().filterByCategory(null);
                                        } else {
                                          // SINGLE SELECTION LOGIC: Clear other selections in this group first
                                          if (_selectedFilters[group.id] == null) {
                                            _selectedFilters[group.id] = {};
                                          }
                                          
                                          if (isSelected) {
                                            _selectedFilters[group.id]!.remove(cat!.id);
                                            context.read<NewHomeCubit>().filterByCategory(null);
                                          } else {
                                            // Clear everything else in the group to allow only ONE selection
                                            _selectedFilters[group.id]!.clear();
                                            _selectedFilters[group.id]!.add(cat!.id);
                                            context.read<NewHomeCubit>().filterByCategory(cat.id);
                                          }
                                        }
                                      });
                                    },
                                    child: Container(
                                      margin: EdgeInsets.symmetric(horizontal: 5.w),
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 20.w,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.black : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(10.r),
                                        border: Border.all(
                                          color: isSelected ? Colors.black : Colors.grey.shade300,
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        isShowAll ? 'Show All' : _capitalizeFirstWord(cat!.name),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black,
                                          fontSize: 16.sp,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 30.h),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NewHomeCubit, DataState>(
      builder: (context, state) {
        if (state is DataLoading) {
          return const HomeShimmerLoading();
        } else if (state is DataLoaded<NewHomeResponse>) {
          final homeData = state.data.data;
          final pills = homeData.navigationPills;
          final sections = homeData.initialData.sections;

          return RefreshIndicator(
            onRefresh: () => context.read<NewHomeCubit>().loadHome(),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Custom Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 10.h, left: 10.w, right: 10.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black),
                          onPressed: () {
                            // Navigate back to starting screen
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => StartingScreen()),
                              (route) => false,
                            );
                          },
                        ),
                        Text(
                          'EXPLORE',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.black),
                          onPressed: () {
                            // Navigate to search
                            context.read<NavigationCubit>().changeIndex(1);
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Navigation Pills & Filter Button
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Row(
                      children: [
                        // Filter Button
                        IconButton(
                          padding: EdgeInsets.only(left: 20.w),
                          icon: const Icon(Icons.tune),
                          onPressed: () => _showFilterBottomSheet(homeData.filterArray),
                        ),
                        
                        // Pills
                        Expanded(
                          child: SizedBox(
                            height: 40.h,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              itemCount: pills.length,
                              itemBuilder: (context, index) {
                                final pill = pills[index];
                                final isSelected = homeData.initialData.navPillId == pill.id;
                                return GestureDetector(
                                  onTap: () {
                                    context.read<NewHomeCubit>().selectPill(pill.id);
                                  },
                                  child: Container(
                                    margin: EdgeInsets.only(right: 10.w),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 15.w,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.black : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      pill.name.toUpperCase(),
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.sp,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sections
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final section = sections[index];
                      return _buildSection(section);
                    },
                    childCount: sections.length,
                  ),
                ),

                // Bottom padding / loading more
                if (homeData.initialData.hasMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Center(child: CircularProgressIndicator(color: Colors.black)),
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: SizedBox(height: 30.h),
                  ),
              ],
            ),
          );
        } else if (state is DataLoadFailed) {
          return Center(child: Text(state.error?.toString() ?? 'Error'));
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSection(NewHomeSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
          child: Text(
            section.name.toUpperCase(),
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        HorizontalSectionList(section: section),
        SizedBox(height: 10.h),
      ],
    );
  }
}

class HorizontalSectionList extends StatefulWidget {
  final NewHomeSection section;
  const HorizontalSectionList({super.key, required this.section});

  @override
  State<HorizontalSectionList> createState() => _HorizontalSectionListState();
}

class _HorizontalSectionListState extends State<HorizontalSectionList> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    _horizontalController.addListener(_onHorizontalScroll);
  }

  @override
  void dispose() {
    _horizontalController.removeListener(_onHorizontalScroll);
    _horizontalController.dispose();
    super.dispose();
  }

  void _onHorizontalScroll() {
    if (!mounted) return;
    final maxScroll = _horizontalController.position.maxScrollExtent;
    final currentScroll = _horizontalController.position.pixels;
    
    // Increased threshold to 500 for better detection on wide items
    if (maxScroll - currentScroll <= 500 && widget.section.hasMore) {
      // print('📡 Triggering horizontal load for section ${widget.section.id}');
      context.read<NewHomeCubit>().loadMoreModulesForSection(widget.section.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modules = widget.section.modules;
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        controller: _horizontalController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 15.w),
        itemCount: modules.length + (widget.section.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == modules.length) {
            return Container(
              width: 100.w,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Colors.black),
            );
          }
          final module = modules[index];
          return _buildModuleCard(context, module);
        },
      ),
    );
  }

  Widget _buildModuleCard(BuildContext context, NewHomeModule module) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ModuleDetails(
              moduleId: module.id,
              moduleTitle: module.title,
            ),
          ),
        );
      },
      child: Container(
        width: 280.w,
        margin: EdgeInsets.symmetric(horizontal: 5.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.r),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: module.fullThumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => const CustomShimmer(),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image),
                  ),
                ),
                
                // Gradient Overlay
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // Title Overlay (bottom left)
                Positioned(
                  bottom: 12.h,
                  left: 12.w,
                  right: 40.w,
                  child: Text(
                    module.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Lock Icon (top right) if is_free is 0
                if (module.isFree == 0)
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
