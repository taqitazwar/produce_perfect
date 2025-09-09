import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class CartItem {
  final String productId;
  final String productTitle;
  final String productImage;
  final double unitPrice;
  final String unit;
  final String farmerId;
  final String farmerName;
  int quantity;

  CartItem({
    required this.productId,
    required this.productTitle,
    required this.productImage,
    required this.unitPrice,
    required this.unit,
    required this.farmerId,
    required this.farmerName,
    required this.quantity,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productTitle': productTitle,
      'productImage': productImage,
      'unitPrice': unitPrice,
      'unit': unit,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      productTitle: map['productTitle'] ?? '',
      productImage: map['productImage'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      unit: map['unit'] ?? 'kg',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      quantity: (map['quantity'] ?? 1).toInt(),
    );
  }
}

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get user's cart
  Future<List<CartItem>> getCart(String userId) async {
    try {
      final doc = await _firestore.collection('carts').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        return items.map((item) => CartItem.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      throw 'Failed to get cart: ${e.toString()}';
    }
  }

  // Add item to cart
  Future<void> addToCart(String userId, ProductModel product, int quantity) async {
    try {
      final cartItems = await getCart(userId);
      
      // Check if item already exists in cart
      final existingItemIndex = cartItems.indexWhere(
        (item) => item.productId == product.id,
      );

      if (existingItemIndex >= 0) {
        // Update quantity if item exists
        cartItems[existingItemIndex].quantity += quantity;
      } else {
        // Add new item
        cartItems.add(CartItem(
          productId: product.id,
          productTitle: product.title,
          productImage: product.imageUrl,
          unitPrice: product.price,
          unit: product.unit,
          farmerId: product.farmerId,
          farmerName: product.farmerName,
          quantity: quantity,
        ));
      }

      await _saveCart(userId, cartItems);
    } catch (e) {
      throw 'Failed to add to cart: ${e.toString()}';
    }
  }

  // Update item quantity in cart
  Future<void> updateCartItem(String userId, String productId, int quantity) async {
    try {
      final cartItems = await getCart(userId);
      final itemIndex = cartItems.indexWhere((item) => item.productId == productId);
      
      if (itemIndex >= 0) {
        if (quantity <= 0) {
          cartItems.removeAt(itemIndex);
        } else {
          cartItems[itemIndex].quantity = quantity;
        }
        await _saveCart(userId, cartItems);
      }
    } catch (e) {
      throw 'Failed to update cart: ${e.toString()}';
    }
  }

  // Remove item from cart
  Future<void> removeFromCart(String userId, String productId) async {
    try {
      final cartItems = await getCart(userId);
      cartItems.removeWhere((item) => item.productId == productId);
      await _saveCart(userId, cartItems);
    } catch (e) {
      throw 'Failed to remove from cart: ${e.toString()}';
    }
  }

  // Clear entire cart
  Future<void> clearCart(String userId) async {
    try {
      await _firestore.collection('carts').doc(userId).delete();
    } catch (e) {
      throw 'Failed to clear cart: ${e.toString()}';
    }
  }

  // Get cart item count
  Future<int> getCartItemCount(String userId) async {
    try {
      final cartItems = await getCart(userId);
      return cartItems.fold<int>(0, (total, item) => total + item.quantity);
    } catch (e) {
      return 0;
    }
  }

  // Get cart total
  Future<double> getCartTotal(String userId) async {
    try {
      final cartItems = await getCart(userId);
      return cartItems.fold<double>(0.0, (total, item) => total + item.totalPrice);
    } catch (e) {
      return 0.0;
    }
  }

  // Private method to save cart
  Future<void> _saveCart(String userId, List<CartItem> cartItems) async {
    await _firestore.collection('carts').doc(userId).set({
      'items': cartItems.map((item) => item.toMap()).toList(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Stream cart changes
  Stream<List<CartItem>> streamCart(String userId) {
    return _firestore
        .collection('carts')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        return items.map((item) => CartItem.fromMap(item)).toList();
      }
      return <CartItem>[];
    });
  }
}
