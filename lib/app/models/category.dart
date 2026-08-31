class Category {
  final String categoryId;
  final int categoryOrder;
  final int levels;
  final List<CategoryName> names;

  Category({
    required this.categoryId,
    required this.categoryOrder,
    required this.levels,
    required this.names,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    categoryId: json['categoryId'] as String,
    categoryOrder: json['categoryOrder'] as int,
    levels: json['levels'] as int,
    names: (json['names'] as List)
        .cast<Map<String, dynamic>>()
        .map(CategoryName.fromJson)
        .toList(),
  );

  /// [localeKey] is already normalized (e.g. "en-us") - see
  /// level_category_view's `_localeKey`. Falls back to the first entry
  /// (JSON authoring order) when there's no exact match.
  String nameFor(String localeKey) {
    final normalized = localeKey.toLowerCase();
    return names
        .firstWhere(
          (n) => n.locale.toLowerCase() == normalized,
          orElse: () => names.first,
        )
        .name;
  }
}

class CategoryName {
  final String locale;
  final String name;

  CategoryName({required this.locale, required this.name});

  factory CategoryName.fromJson(Map<String, dynamic> json) => CategoryName(
    locale: json['locale'] as String,
    name: json['name'] as String,
  );
}
