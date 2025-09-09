enum OrderStatus {
  pending,
  confirmed,
  preparing,
  readyForPickup,
  pickedUp,
  inTransit,
  delivered,
  cancelled,
}

class OrderItem {
  final String productId;
  final String productTitle;
  final String productImage;
  final double price;
  final int quantity;
  final String unit;

  OrderItem({
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.price,
    required this.quantity,
    required this.unit,
  });

  double get totalPrice => price * quantity;

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImage: map['productImage'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String farmerId;
  final String farmerName;
  final String? riderId;
  final String? riderName;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final OrderStatus status;
  // Location details
  final String deliveryAddress;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final String? deliveryPlaceId;
  final String farmLocation;
  final double? farmLatitude;
  final double? farmLongitude;
  final String? farmPlaceId;
  final double? distanceKm; // Distance between farm and customer
  
  // Timing
  final DateTime orderDate;
  final DateTime? estimatedDelivery;
  final DateTime? actualDelivery;
  final DateTime? pickedUpAt;
  final DateTime? deliveredAt;
  
  // Payment details
  final String paymentMethod; // 'card', 'cash', etc.
  final String? paymentIntentId; // For demo payment tracking
  final bool isPaid;
  final DateTime? paidAt;
  
  final String? specialInstructions;
  final String? cancellationReason;
  final Map<String, dynamic>? paymentInfo;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.farmerId,
    required this.farmerName,
    this.riderId,
    this.riderName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    // Location details
    required this.deliveryAddress,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.deliveryPlaceId,
    required this.farmLocation,
    this.farmLatitude,
    this.farmLongitude,
    this.farmPlaceId,
    this.distanceKm,
    // Timing
    required this.orderDate,
    this.estimatedDelivery,
    this.actualDelivery,
    this.pickedUpAt,
    this.deliveredAt,
    // Payment
    this.paymentMethod = 'card',
    this.paymentIntentId,
    this.isPaid = false,
    this.paidAt,
    this.specialInstructions,
    this.cancellationReason,
    this.paymentInfo,
  });

  bool get isActive {
    return status != OrderStatus.delivered && 
           status != OrderStatus.cancelled;
  }

  bool get canBeCancelled {
    return status == OrderStatus.pending || 
           status == OrderStatus.confirmed;
  }

  String get statusDisplayName {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      case OrderStatus.inTransit:
        return 'In Transit';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      riderId: map['riderId'],
      riderName: map['riderName'],
      items: (map['items'] as List<dynamic>?)
          ?.map((item) => OrderItem.fromMap(item))
          .toList() ?? [],
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${map['status']}',
        orElse: () => OrderStatus.pending,
      ),
      deliveryAddress: map['deliveryAddress'] ?? '',
      farmLocation: map['farmLocation'] ?? '',
      orderDate: DateTime.fromMillisecondsSinceEpoch(map['orderDate'] ?? 0),
      estimatedDelivery: map['estimatedDelivery'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['estimatedDelivery'])
          : null,
      actualDelivery: map['actualDelivery'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['actualDelivery'])
          : null,
      specialInstructions: map['specialInstructions'],
      cancellationReason: map['cancellationReason'],
      paymentInfo: map['paymentInfo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'riderId': riderId,
      'riderName': riderName,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'status': status.toString().split('.').last,
      'deliveryAddress': deliveryAddress,
      'farmLocation': farmLocation,
      'orderDate': orderDate.millisecondsSinceEpoch,
      'estimatedDelivery': estimatedDelivery?.millisecondsSinceEpoch,
      'actualDelivery': actualDelivery?.millisecondsSinceEpoch,
      'specialInstructions': specialInstructions,
      'cancellationReason': cancellationReason,
      'paymentInfo': paymentInfo,
    };
  }

  OrderModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? farmerId,
    String? farmerName,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? total,
    OrderStatus? status,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? deliveryPlaceId,
    String? farmLocation,
    double? farmLatitude,
    double? farmLongitude,
    String? farmPlaceId,
    double? distanceKm,
    String? riderId,
    DateTime? orderDate,
    DateTime? estimatedDelivery,
    DateTime? actualDelivery,
    String? specialInstructions,
    String? cancellationReason,
    Map<String, dynamic>? paymentInfo,
    String? paymentMethod,
    String? paymentIntentId,
    bool? isPaid,
    DateTime? paidAt,
    DateTime? pickedUpAt,
    DateTime? deliveredAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      farmerId: farmerId ?? this.farmerId,
      farmerName: farmerName ?? this.farmerName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      status: status ?? this.status,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      deliveryLatitude: deliveryLatitude ?? this.deliveryLatitude,
      deliveryLongitude: deliveryLongitude ?? this.deliveryLongitude,
      deliveryPlaceId: deliveryPlaceId ?? this.deliveryPlaceId,
      farmLocation: farmLocation ?? this.farmLocation,
      farmLatitude: farmLatitude ?? this.farmLatitude,
      farmLongitude: farmLongitude ?? this.farmLongitude,
      farmPlaceId: farmPlaceId ?? this.farmPlaceId,
      distanceKm: distanceKm ?? this.distanceKm,
      riderId: riderId ?? this.riderId,
      orderDate: orderDate ?? this.orderDate,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      actualDelivery: actualDelivery ?? this.actualDelivery,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      paymentInfo: paymentInfo ?? this.paymentInfo,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      isPaid: isPaid ?? this.isPaid,
      paidAt: paidAt ?? this.paidAt,
      pickedUpAt: pickedUpAt ?? this.pickedUpAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
