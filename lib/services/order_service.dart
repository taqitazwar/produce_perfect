import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import 'product_service.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();
  final _productService = ProductService();

  // Create a new order with location details
  Future<String> createOrderWithLocation({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String farmerId,
    required String farmerName,
    required List<OrderItem> items,
    required String deliveryAddress,
    required double deliveryLatitude,
    required double deliveryLongitude,
    required String deliveryPlaceId,
    required String farmLocation,
    required double farmLatitude,
    required double farmLongitude,
    required String farmPlaceId,
    required double distanceKm,
    String? specialInstructions,
  }) async {
    try {
      final orderId = _uuid.v4();
      final subtotal = items.fold<double>(0, (sum, item) => sum + item.totalPrice);
      final deliveryFee = distanceKm * 2 * 1.5; // Formula: km × 2 × $1.5
      final total = subtotal + deliveryFee;

      final order = OrderModel(
        id: orderId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        farmerId: farmerId,
        farmerName: farmerName,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        status: OrderStatus.confirmed, // Changed to confirmed so riders can see it
        deliveryAddress: deliveryAddress,
        deliveryLatitude: deliveryLatitude,
        deliveryLongitude: deliveryLongitude,
        deliveryPlaceId: deliveryPlaceId,
        farmLocation: farmLocation,
        farmLatitude: farmLatitude,
        farmLongitude: farmLongitude,
        farmPlaceId: farmPlaceId,
        distanceKm: distanceKm,
        orderDate: DateTime.now(),
        estimatedDelivery: DateTime.now().add(const Duration(hours: 24)), // Tomorrow 2pm
        paymentMethod: 'card',
        isPaid: true,
        paidAt: DateTime.now(),
        specialInstructions: specialInstructions,
      );

      await _firestore.collection('orders').doc(orderId).set(order.toMap());
      
      // Decrease product quantities
      await _decreaseProductQuantities(items);
      
      return orderId;
    } catch (e) {
      throw 'Failed to create order: ${e.toString()}';
    }
  }

  // Helper method to decrease product quantities
  Future<void> _decreaseProductQuantities(List<OrderItem> items) async {
    try {
      // Prepare product quantities for batch update
      final productQuantities = <Map<String, int>>[];
      
      for (final item in items) {
        productQuantities.add({item.productId: item.quantity});
      }
      
      // Use ProductService to decrease quantities
      await _productService.decreaseProductQuantities(productQuantities);
    } catch (e) {
      print('Warning: Failed to decrease product quantities: $e');
      // Don't throw error here to avoid breaking order creation
      // The order is already created, just log the warning
    }
  }

  // Legacy method for backward compatibility
  Future<String> createOrder({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String farmerId,
    required String farmerName,
    required List<OrderItem> items,
    required String deliveryAddress,
    required String farmLocation,
    String? specialInstructions,
  }) async {
    try {
      final orderId = _uuid.v4();
      final subtotal = items.fold<double>(0, (sum, item) => sum + item.totalPrice);
      final deliveryFee = _calculateDeliveryFee(subtotal);
      final total = subtotal + deliveryFee;

      final order = OrderModel(
        id: orderId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        farmerId: farmerId,
        farmerName: farmerName,
        items: items,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        status: OrderStatus.pending,
        deliveryAddress: deliveryAddress,
        farmLocation: farmLocation,
        orderDate: DateTime.now(),
        estimatedDelivery: DateTime.now().add(const Duration(hours: 2)),
        specialInstructions: specialInstructions,
      );

      await _firestore.collection('orders').doc(orderId).set(order.toMap());
      
      // Decrease product quantities
      await _decreaseProductQuantities(items);
      
      return orderId;
    } catch (e) {
      throw 'Failed to create order: ${e.toString()}';
    }
  }

  // Calculate delivery fee based on subtotal
  double _calculateDeliveryFee(double subtotal) {
    if (subtotal >= 50) return 0; // Free delivery over $50
    return 5.99; // Standard delivery fee
  }

  // Get orders by customer
  Future<List<OrderModel>> getOrdersByCustomer(String customerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .orderBy('orderDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw 'Failed to get customer orders: ${e.toString()}';
    }
  }

  // Get orders by farmer
  Future<List<OrderModel>> getOrdersByFarmer(String farmerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('orderDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw 'Failed to get farmer orders: ${e.toString()}';
    }
  }

  // Get available orders for riders (orders that need pickup)
  Future<List<OrderModel>> getAvailableOrdersForRiders() async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('status', whereIn: [
            OrderStatus.confirmed.toString().split('.').last,
            OrderStatus.preparing.toString().split('.').last,
            OrderStatus.readyForPickup.toString().split('.').last,
          ])
          .where('riderId', isNull: true)
          .orderBy('orderDate', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw 'Failed to get available orders: ${e.toString()}';
    }
  }

  // Get orders assigned to a rider
  Future<List<OrderModel>> getOrdersByRider(String riderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('riderId', isEqualTo: riderId)
          .orderBy('orderDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw 'Failed to get rider orders: ${e.toString()}';
    }
  }

  // Assign order to rider
  Future<void> assignOrderToRider(String orderId, String riderId, String riderName) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'riderId': riderId,
        'riderName': riderName,
        'status': OrderStatus.pickedUp.toString().split('.').last,
      });
    } catch (e) {
      throw 'Failed to assign order to rider: ${e.toString()}';
    }
  }

  // Accept order by rider
  Future<void> acceptOrder(String orderId, String riderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'riderId': riderId,
        'status': OrderStatus.confirmed.toString().split('.').last,
      });
    } catch (e) {
      throw 'Failed to accept order: ${e.toString()}';
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      final updates = <String, dynamic>{
        'status': status.toString().split('.').last,
      };

      // Add timestamps for different statuses
      if (status == OrderStatus.pickedUp) {
        updates['pickedUpAt'] = DateTime.now().millisecondsSinceEpoch;
      } else if (status == OrderStatus.delivered) {
        updates['actualDelivery'] = DateTime.now().millisecondsSinceEpoch;
        updates['deliveredAt'] = DateTime.now().millisecondsSinceEpoch;
        
        // Update rider earnings and stats when order is delivered
        await _updateRiderStatsOnDelivery(orderId);
      }

      await _firestore.collection('orders').doc(orderId).update(updates);
    } catch (e) {
      throw 'Failed to update order status: ${e.toString()}';
    }
  }

  // Update rider stats when an order is delivered
  Future<void> _updateRiderStatsOnDelivery(String orderId) async {
    try {
      final order = await getOrder(orderId);
      if (order == null || order.riderId == null) return;

      final riderId = order.riderId!;
      final riderEarnings = order.deliveryFee * 0.7; // 70% of delivery fee goes to rider
      
      // Update rider profile with earnings and stats
      final riderDoc = _firestore.collection('users').doc(riderId);
      
      await _firestore.runTransaction((transaction) async {
        final riderSnapshot = await transaction.get(riderDoc);
        
        if (riderSnapshot.exists) {
          final data = riderSnapshot.data()!;
          final currentEarnings = (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
          final currentDeliveries = (data['totalDeliveries'] as int?) ?? 0;
          final currentFoodSaved = (data['foodSaved'] as num?)?.toDouble() ?? 0.0;
          final currentCarbonSaved = (data['carbonSaved'] as num?)?.toDouble() ?? 0.0;
          
          // Calculate food saved (sum of all item quantities in kg)
          final foodSavedThisOrder = order.items.fold<double>(
            0.0, 
            (sum, item) => sum + item.quantity
          );
          
          // Estimate carbon saved (rough calculation: 1kg food = 2kg CO2 saved)
          final carbonSavedThisOrder = foodSavedThisOrder * 2.0;
          
          transaction.update(riderDoc, {
            'totalEarnings': currentEarnings + riderEarnings,
            'totalDeliveries': currentDeliveries + 1,
            'foodSaved': currentFoodSaved + foodSavedThisOrder,
            'carbonSaved': currentCarbonSaved + carbonSavedThisOrder,
            'lastDeliveryDate': DateTime.now().millisecondsSinceEpoch,
          });
        }
      });
    } catch (e) {
      print('Error updating rider stats: $e');
      // Don't throw error to avoid breaking the main order update
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrder(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (doc.exists) {
        return OrderModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Failed to get order: ${e.toString()}';
    }
  }

  // Cancel order
  Future<void> cancelOrder(String orderId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.toString().split('.').last,
        'cancellationReason': reason,
      });
    } catch (e) {
      throw 'Failed to cancel order: ${e.toString()}';
    }
  }

  // Get rider earnings
  Future<Map<String, dynamic>> getRiderEarnings(String riderId) async {
    try {
      final querySnapshot = await _firestore
          .collection('orders')
          .where('riderId', isEqualTo: riderId)
          .where('status', isEqualTo: OrderStatus.delivered.toString().split('.').last)
          .get();

      double totalEarnings = 0;
      int totalDeliveries = querySnapshot.docs.length;
      double totalDistance = 0; // Placeholder - would calculate from actual routes
      double carbonSaved = 0;
      double vegetablesSaved = 0;

      for (var doc in querySnapshot.docs) {
        final order = OrderModel.fromMap(doc.data());
        // Base delivery fee for rider (assuming 70% goes to rider)
        totalEarnings += order.deliveryFee * 0.7;
        
        // Calculate environmental impact
        for (var item in order.items) {
          vegetablesSaved += item.quantity;
          carbonSaved += item.quantity * 2.1; // ~2.1 kg CO2 per kg food waste prevented
        }
      }

      return {
        'totalEarnings': totalEarnings,
        'totalDeliveries': totalDeliveries,
        'carbonSaved': carbonSaved,
        'vegetablesSaved': vegetablesSaved,
        'totalDistance': totalDistance,
        'avgEarningsPerDelivery': totalDeliveries > 0 ? totalEarnings / totalDeliveries : 0,
      };
    } catch (e) {
      throw 'Failed to get rider earnings: ${e.toString()}';
    }
  }

  // Stream orders for real-time updates
  Stream<List<OrderModel>> streamOrdersByCustomer(String customerId) {
    return _firestore
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<OrderModel>> streamAvailableOrdersForRiders() {
    return _firestore
        .collection('orders')
        .where('status', whereIn: [
          OrderStatus.confirmed.toString().split('.').last,
          OrderStatus.preparing.toString().split('.').last,
          OrderStatus.readyForPickup.toString().split('.').last,
          OrderStatus.pickedUp.toString().split('.').last,
          OrderStatus.inTransit.toString().split('.').last,
        ])
        .orderBy('orderDate', descending: false)
        .snapshots()
        .map((snapshot) {
          print('Raw query returned ${snapshot.docs.length} orders');
          
          final allOrders = snapshot.docs.map((doc) {
            final data = doc.data();
            print('Order ${doc.id}: status=${data['status']}, riderId=${data['riderId']}');
            return OrderModel.fromMap(data);
          }).toList();
          
          // Show both unassigned orders AND orders assigned to any rider (for multiple order support)
          final availableOrders = allOrders.toList();
              
          print('All active orders (available + in-progress): ${availableOrders.length}');
          return availableOrders;
        });
  }

  // Debug method to check all orders in database
  Future<void> debugAllOrders() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      print('Total orders in database: ${snapshot.docs.length}');
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        print('📄 Order ${doc.id}:');
        print('   - status: ${data['status']}');
        print('   - riderId: ${data['riderId']}');
        print('   - farmerId: ${data['farmerId']}');
        print('   - customerId: ${data['customerId']}');
        print('   - total: ${data['total']}');
        print('   - orderDate: ${data['orderDate']}');
        print('---');
      }
    } catch (e) {
      print('Error debugging orders: $e');
    }
  }
}
