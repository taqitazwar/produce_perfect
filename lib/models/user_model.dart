class UserModel {
  final String uid;
  final String email;
  final String name;
  final String userType; // farmer, rider, customer
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  
  // Location fields (for all user types)
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? placeId; // Google Places API ID
  
  // Farmer specific fields
  final String? farmName;
  final String? farmAddress; // Deprecated - use address instead
  final String? farmDescription;
  final double? farmLatitude;
  final double? farmLongitude;
  final String? farmPlaceId;
  
  // Rider specific fields
  final String? vehicleType;
  final String? licenseNumber;
  final bool? isAvailable;
  final double? currentLatitude;
  final double? currentLongitude;
  
  // Customer specific fields
  final String? deliveryAddress; // Deprecated - use address instead
  final List<String>? preferredCategories;
  final List<Map<String, dynamic>>? savedAddresses; // Multiple delivery addresses

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.userType,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    // Location fields
    this.address,
    this.latitude,
    this.longitude,
    this.placeId,
    // Farmer fields
    this.farmName,
    this.farmAddress,
    this.farmDescription,
    this.farmLatitude,
    this.farmLongitude,
    this.farmPlaceId,
    // Rider fields
    this.vehicleType,
    this.licenseNumber,
    this.isAvailable,
    this.currentLatitude,
    this.currentLongitude,
    // Customer fields
    this.deliveryAddress,
    this.preferredCategories,
    this.savedAddresses,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      userType: map['userType'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
      isActive: map['isActive'] ?? true,
      // Location fields
      address: map['address'],
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      placeId: map['placeId'],
      // Farmer fields
      farmName: map['farmName'],
      farmAddress: map['farmAddress'],
      farmDescription: map['farmDescription'],
      farmLatitude: map['farmLatitude']?.toDouble(),
      farmLongitude: map['farmLongitude']?.toDouble(),
      farmPlaceId: map['farmPlaceId'],
      // Rider fields
      vehicleType: map['vehicleType'],
      licenseNumber: map['licenseNumber'],
      isAvailable: map['isAvailable'],
      currentLatitude: map['currentLatitude']?.toDouble(),
      currentLongitude: map['currentLongitude']?.toDouble(),
      // Customer fields
      deliveryAddress: map['deliveryAddress'],
      preferredCategories: map['preferredCategories'] != null
          ? List<String>.from(map['preferredCategories'])
          : null,
      savedAddresses: map['savedAddresses'] != null
          ? List<Map<String, dynamic>>.from(map['savedAddresses'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'userType': userType,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'isActive': isActive,
      // Location fields
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
      // Farmer fields
      'farmName': farmName,
      'farmAddress': farmAddress,
      'farmDescription': farmDescription,
      'farmLatitude': farmLatitude,
      'farmLongitude': farmLongitude,
      'farmPlaceId': farmPlaceId,
      // Rider fields
      'vehicleType': vehicleType,
      'licenseNumber': licenseNumber,
      'isAvailable': isAvailable,
      'currentLatitude': currentLatitude,
      'currentLongitude': currentLongitude,
      // Customer fields
      'deliveryAddress': deliveryAddress,
      'preferredCategories': preferredCategories,
      'savedAddresses': savedAddresses,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? userType,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    // Location fields
    String? address,
    double? latitude,
    double? longitude,
    String? placeId,
    // Farmer fields
    String? farmName,
    String? farmAddress,
    String? farmDescription,
    double? farmLatitude,
    double? farmLongitude,
    String? farmPlaceId,
    // Rider fields
    String? vehicleType,
    String? licenseNumber,
    bool? isAvailable,
    double? currentLatitude,
    double? currentLongitude,
    // Customer fields
    String? deliveryAddress,
    List<String>? preferredCategories,
    List<Map<String, dynamic>>? savedAddresses,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      // Location fields
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      // Farmer fields
      farmName: farmName ?? this.farmName,
      farmAddress: farmAddress ?? this.farmAddress,
      farmDescription: farmDescription ?? this.farmDescription,
      farmLatitude: farmLatitude ?? this.farmLatitude,
      farmLongitude: farmLongitude ?? this.farmLongitude,
      farmPlaceId: farmPlaceId ?? this.farmPlaceId,
      // Rider fields
      vehicleType: vehicleType ?? this.vehicleType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isAvailable: isAvailable ?? this.isAvailable,
      currentLatitude: currentLatitude ?? this.currentLatitude,
      currentLongitude: currentLongitude ?? this.currentLongitude,
      // Customer fields
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      preferredCategories: preferredCategories ?? this.preferredCategories,
      savedAddresses: savedAddresses ?? this.savedAddresses,
    );
  }
}
