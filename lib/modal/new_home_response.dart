class NewHomeResponse {
  final bool isSuccess;
  final NewHomeData data;

  NewHomeResponse({
    required this.isSuccess,
    required this.data,
  });

  factory NewHomeResponse.fromJson(Map<String, dynamic> json) {
    return NewHomeResponse(
      isSuccess: json['isSuccess'] ?? false,
      data: NewHomeData.fromJson(json['data'] ?? {}),
    );
  }
}

class NewHomeData {
  final List<NewNavigationPill> navigationPills;
  final List<FilterGroup> filterArray;
  final InitialData initialData;

  NewHomeData({
    required this.navigationPills,
    required this.filterArray,
    required this.initialData,
  });

  factory NewHomeData.fromJson(Map<String, dynamic> json) {
    return NewHomeData(
      navigationPills: (json['navigation_pills'] as List<dynamic>?)
              ?.map((e) => NewNavigationPill.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      filterArray: (json['filter_array'] as List<dynamic>?)
              ?.map((e) => FilterGroup.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      initialData: InitialData.fromJson(json['initial_data'] ?? {}),
    );
  }
}

class NewNavigationPill {
  final int id;
  final String name;
  final String activeColor;
  final String uiStyle;

  NewNavigationPill({
    required this.id,
    required this.name,
    required this.activeColor,
    required this.uiStyle,
  });

  factory NewNavigationPill.fromJson(Map<String, dynamic> json) {
    return NewNavigationPill(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      activeColor: json['active_color'] ?? '#FFFFFF',
      uiStyle: json['ui_style'] ?? 'list',
    );
  }
}

class FilterGroup {
  final int id;
  final String name;
  final List<FilterCategory> categories;

  FilterGroup({
    required this.id,
    required this.name,
    required this.categories,
  });

  factory FilterGroup.fromJson(Map<String, dynamic> json) {
    return FilterGroup(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => FilterCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class FilterCategory {
  final int id;
  final String name;

  FilterCategory({
    required this.id,
    required this.name,
  });

  factory FilterCategory.fromJson(Map<String, dynamic> json) {
    return FilterCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class InitialData {
  final int navPillId;
  final List<NewHomeSection> sections;
  final dynamic nextCursor;
  final bool hasMore;

  InitialData({
    required this.navPillId,
    required this.sections,
    this.nextCursor,
    required this.hasMore,
  });

  factory InitialData.fromJson(Map<String, dynamic> json) {
    return InitialData(
      navPillId: json['nav_pill_id'] ?? 0,
      sections: (json['sections'] as List<dynamic>?)
              ?.map((e) => NewHomeSection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nextCursor: json['nextCursor'],
      hasMore: json['hasMore'] ?? false,
    );
  }
}

class NewHomeSection {
  final int id;
  final String name;
  final String layoutType;
  final String aspectRatio;
  final int position;
  final List<NewHomeModule> modules;
  final dynamic nextCursor;
  final bool hasMore;

  NewHomeSection({
    required this.id,
    required this.name,
    required this.layoutType,
    required this.aspectRatio,
    required this.position,
    required this.modules,
    this.nextCursor,
    required this.hasMore,
  });

  factory NewHomeSection.fromJson(Map<String, dynamic> json) {
    return NewHomeSection(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      layoutType: json['layout_type'] ?? 'horizontal_scroll',
      aspectRatio: json['aspect_ratio'] ?? '16:9',
      position: json['position'] ?? 0,
      modules: (json['modules'] as List<dynamic>?)
              ?.map((e) => NewHomeModule.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      nextCursor: json['nextCursor'],
      hasMore: json['hasMore'] ?? false,
    );
  }
}

class NewHomeModule {
  final int id;
  final String title;
  final String thumbnailUrl;
  final int isFree;
  final int collectionId;
  final int position;
  final int rankCount;

  NewHomeModule({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.isFree,
    required this.collectionId,
    required this.position,
    required this.rankCount,
  });

  factory NewHomeModule.fromJson(Map<String, dynamic> json) {
    return NewHomeModule(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      isFree: json['is_free'] ?? 0,
      collectionId: json['collection_id'] ?? 0,
      position: json['position'] ?? 0,
      rankCount: json['rank_count'] ?? 0,
    );
  }

  static const String imgBaseUrl = 'https://admin.edugarciamovimiento.com/fitness/uploads';

  String get fullThumbnailUrl {
    if (thumbnailUrl.startsWith('http')) return thumbnailUrl;
    return '$imgBaseUrl/$thumbnailUrl';
  }
}
