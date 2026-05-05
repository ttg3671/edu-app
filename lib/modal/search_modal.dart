import 'package:edu_gym/modal/module.dart';

class SearchModal {
  final List<Module> modules;
  final dynamic nextCursor;
  final bool hasMore;

  SearchModal({
    required this.modules,
    this.nextCursor,
    required this.hasMore,
  });

  factory SearchModal.fromJson(Map<String, dynamic> json) {
    // New structure has data list directly
    List moduleJson = json['data'] ?? [];

    return SearchModal(
      modules: moduleJson.map((e) => Module.fromJson(e)).toList(),
      nextCursor: json['nextCursor'],
      hasMore: json['hasMore'] ?? false,
    );
  }
}
