class ProductModel {
  final String id;
  final String farmerId;
  final String farmerName;
  final String title;
  final String description;
  final String category;
  final double originalPrice;
  final double discountedPrice;
  final int quantity;
  final String unit; // kg, pieces, etc.
  final List<String> imageUrls;
  final String farmLocation;
  final DateTime harvestDate;
  final DateTime expiryDate;
  final String condition; // slightly damaged, overripe, etc.
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? nutritionInfo;
  final List<String> tags; // organic, local, etc.

  ProductModel({
    required this.id,
    required this.farmerId,
    required this.farmerName,
    required this.title,
    required this.description,
    required this.category,
    required this.originalPrice,
    required this.discountedPrice,
    required this.quantity,
    required this.unit,
    required this.imageUrls,
    required this.farmLocation,
    required this.harvestDate,
    required this.expiryDate,
    required this.condition,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
    this.nutritionInfo,
    this.tags = const [],
  });

  // Convenience getters for backward compatibility
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  double get price => discountedPrice;

  double get savingsPercentage {
    if (originalPrice == 0) return 0;
    return ((originalPrice - discountedPrice) / originalPrice) * 100;
  }

  bool get isExpiringSoon {
    final now = DateTime.now();
    final daysUntilExpiry = expiryDate.difference(now).inDays;
    return daysUntilExpiry <= 3;
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      originalPrice: (map['originalPrice'] ?? 0).toDouble(),
      discountedPrice: (map['discountedPrice'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      farmLocation: map['farmLocation'] ?? '',
      harvestDate: DateTime.fromMillisecondsSinceEpoch(map['harvestDate'] ?? 0),
      expiryDate: DateTime.fromMillisecondsSinceEpoch(map['expiryDate'] ?? 0),
      condition: map['condition'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      nutritionInfo: map['nutritionInfo'],
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'title': title,
      'description': description,
      'category': category,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'unit': unit,
      'imageUrls': imageUrls,
      'farmLocation': farmLocation,
      'harvestDate': harvestDate.millisecondsSinceEpoch,
      'expiryDate': expiryDate.millisecondsSinceEpoch,
      'condition': condition,
      'isAvailable': isAvailable,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'nutritionInfo': nutritionInfo,
      'tags': tags,
    };
  }

  ProductModel copyWith({
    String? id,
    String? farmerId,
    String? farmerName,
    String? title,
    String? description,
    String? category,
    double? originalPrice,
    double? discountedPrice,
    int? quantity,
    String? unit,
    List<String>? imageUrls,
    String? farmLocation,
    DateTime? harvestDate,
    DateTime? expiryDate,
    String? condition,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? nutritionInfo,
    List<String>? tags,
  }) {
    return ProductModel(
      id: id ?? this.id,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      imageUrls: imageUrls ?? this.imageUrls,
      farmLocation: farmLocation ?? this.farmLocation,
      harvestDate: harvestDate ?? this.harvestDate,
      expiryDate: expiryDate ?? this.expiryDate,
      condition: condition ?? this.condition,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      tags: tags ?? this.tags,
    );
  }
}
