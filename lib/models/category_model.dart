class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final String color;
  final bool isActive;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isActive = true,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? '',
      color: map['color'] ?? '',
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'isActive': isActive,
    };
  }
}

// Predefined categories for demo
class DemoCategories {
  static List<CategoryModel> getCategories() {
    return [
      // Vegetables
      CategoryModel(
        id: 'tomatoes',
        name: 'Tomatoes',
        icon: '🍅',
        color: '#FF6B6B',
      ),
      CategoryModel(
        id: 'carrots',
        name: 'Carrots',
        icon: '🥕',
        color: '#FF8C42',
      ),
      CategoryModel(
        id: 'potatoes',
        name: 'Potatoes',
        icon: '🥔',
        color: '#8B4513',
      ),
      CategoryModel(
        id: 'leafy_greens',
        name: 'Leafy Greens',
        icon: '🥬',
        color: '#4ECDC4',
      ),
      // Fruits
      CategoryModel(
        id: 'apples',
        name: 'Apples',
        icon: '🍎',
        color: '#FF4757',
      ),
      CategoryModel(
        id: 'bananas',
        name: 'Bananas',
        icon: '🍌',
        color: '#FFC048',
      ),
    ];
  }
}
