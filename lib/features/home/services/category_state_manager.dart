/// Singleton manager for persisting category and subcategory selections
/// Maintains user's last selected subcategory for each main category
class CategoryStateManager {
  static final CategoryStateManager _instance = CategoryStateManager._internal();
  factory CategoryStateManager() => _instance;
  CategoryStateManager._internal();

  // Store selected subcategory ID for each main category
  final Map<String, String?> _selectedSubcategories = {};
  
  // Cache subcategories to avoid repeated queries
  final Map<String, List<CategoryItem>> _subcategoriesCache = {};
  
  // Get selected subcategory for a main category
  String? getSelectedSubcategory(String mainCategoryId) {
    return _selectedSubcategories[mainCategoryId];
  }
  
  // Set selected subcategory for a main category
  void setSelectedSubcategory(String mainCategoryId, String? subcategoryId) {
    _selectedSubcategories[mainCategoryId] = subcategoryId;
  }
  
  // Get cached subcategories
  List<CategoryItem>? getCachedSubcategories(String mainCategoryId) {
    return _subcategoriesCache[mainCategoryId];
  }
  
  // Cache subcategories for faster access
  void cacheSubcategories(String mainCategoryId, List<CategoryItem> subcategories) {
    _subcategoriesCache[mainCategoryId] = subcategories;
  }
  
  // Clear all selections (useful for logout)
  void clear() {
    _selectedSubcategories.clear();
    _subcategoriesCache.clear();
  }
}

/// Model for category items
class CategoryItem {
  final String id;
  final String name;
  final String slug;
  final String? iconUrl;
  final String? parentId;
  final int displayOrder;

  CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    this.parentId,
    this.displayOrder = 0,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      iconUrl: json['icon_url'],
      parentId: json['parent_id'],
      displayOrder: json['display_order'] ?? 0,
    );
  }
}