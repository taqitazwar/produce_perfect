import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/product_model.dart';
import '../models/user_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Upload product images to Firebase Storage
  Future<List<String>> uploadProductImages(List<File> images) async {
    try {
      List<String> imageUrls = [];
      
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final ref = _storage.ref().child('products').child(fileName);
        
        final uploadTask = ref.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        imageUrls.add(downloadUrl);
      }
      
      return imageUrls;
    } catch (e) {
      throw 'Failed to upload images: ${e.toString()}';
    }
  }

  // Create a new product
  Future<String> createProduct({
    required String farmerId,
    required String farmerName,
    required String title,
    required String description,
    required String category,
    required double originalPrice,
    required double discountedPrice,
    required int quantity,
    required String unit,
    required List<XFile> images,
    required String farmLocation,
    required DateTime harvestDate,
    required DateTime expiryDate,
    required String condition,
    List<String> tags = const [],
    Map<String, dynamic>? nutritionInfo,
  }) async {
    try {
      // Upload images first
      List<String> imageUrls = [];
      for (int i = 0; i < images.length; i++) {
        final imageUrl = await _uploadImage(images[i], farmerId, i);
        imageUrls.add(imageUrl);
      }

      // Create product document
      final productRef = _firestore.collection('products').doc();
      final product = ProductModel(
        id: productRef.id,
        farmerId: farmerId,
        farmerName: farmerName,
        title: title,
        description: description,
        category: category,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        quantity: quantity,
        unit: unit,
        imageUrls: imageUrls,
        farmLocation: farmLocation,
        harvestDate: harvestDate,
        expiryDate: expiryDate,
        condition: condition,
        isAvailable: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        tags: tags,
        nutritionInfo: nutritionInfo,
      );

      await productRef.set(product.toMap());
      return productRef.id;
    } catch (e) {
      throw 'Failed to create product: ${e.toString()}';
    }
  }

  // Upload image to Firebase Storage
  Future<String> _uploadImage(XFile imageFile, String farmerId, int index) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${farmerId}_${timestamp}_$index.jpg';
      final ref = _storage.ref().child('products').child(fileName);
      
      final uploadTask = ref.putFile(File(imageFile.path));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload image: ${e.toString()}';
    }
  }

  // Get products by farmer
  Future<List<ProductModel>> getProductsByFarmer(String farmerId) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('farmerId', isEqualTo: farmerId)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      // Fallback: get all farmer products without isAvailable filter
      try {
        final querySnapshot = await _firestore
            .collection('products')
            .where('farmerId', isEqualTo: farmerId)
            .get();

        return querySnapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data()))
            .toList();
      } catch (fallbackError) {
        throw 'Failed to get products: ${e.toString()}';
      }
    }
  }

  // Get all available products
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw 'Failed to get products: ${e.toString()}';
    }
  }

  // Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .where('isAvailable', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw 'Failed to get products by category: ${e.toString()}';
    }
  }

  // Update product with map
  Future<void> updateProduct(String productId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
      await _firestore.collection('products').doc(productId).update(updates);
    } catch (e) {
      throw 'Failed to update product: ${e.toString()}';
    }
  }

  // Update product with ProductModel
  Future<void> updateProductModel(ProductModel product) async {
    try {
      await _firestore.collection('products').doc(product.id).update(product.toMap());
    } catch (e) {
      throw 'Failed to update product: ${e.toString()}';
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      // Get product to delete images
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        final product = ProductModel.fromMap(doc.data()!);
        
        // Delete images from storage
        for (String imageUrl in product.imageUrls) {
          try {
            await _storage.refFromURL(imageUrl).delete();
          } catch (e) {
            print('Failed to delete image: $e');
          }
        }
      }

      // Delete product document
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw 'Failed to delete product: ${e.toString()}';
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .where('isAvailable', isEqualTo: true)
          .get();

      final products = querySnapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data()))
          .where((product) =>
              product.title.toLowerCase().contains(query.toLowerCase()) ||
              product.description.toLowerCase().contains(query.toLowerCase()) ||
              product.category.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return products;
    } catch (e) {
      throw 'Failed to search products: ${e.toString()}';
    }
  }

  // Get product by ID
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw 'Failed to get product: ${e.toString()}';
    }
  }

  // Decrease product quantity when order is placed
  Future<void> decreaseProductQuantity(String productId, int quantityToDecrease) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) {
        throw 'Product not found';
      }

      final product = ProductModel.fromMap(doc.data()!);
      final newQuantity = product.quantity - quantityToDecrease;

      if (newQuantity <= 0) {
        // Remove product from farmer's posts when quantity reaches 0
        await _firestore.collection('products').doc(productId).update({
          'isAvailable': false,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        print('Product $productId marked as unavailable (quantity reached 0)');
      } else {
        // Update quantity
        await _firestore.collection('products').doc(productId).update({
          'quantity': newQuantity,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        print('Product $productId quantity decreased to $newQuantity');
      }
    } catch (e) {
      throw 'Failed to decrease product quantity: ${e.toString()}';
    }
  }

  // Decrease quantities for multiple products (for order processing)
  Future<void> decreaseProductQuantities(List<Map<String, int>> productQuantities) async {
    try {
      // Process all quantity decreases in a batch
      final batch = _firestore.batch();
      
      for (final item in productQuantities) {
        final productId = item.keys.first;
        final quantityToDecrease = item.values.first;
        
        final doc = await _firestore.collection('products').doc(productId).get();
        if (!doc.exists) {
          print('Product $productId not found, skipping...');
          continue;
        }

        final product = ProductModel.fromMap(doc.data()!);
        final newQuantity = product.quantity - quantityToDecrease;

        if (newQuantity <= 0) {
          // Mark as unavailable
          batch.update(_firestore.collection('products').doc(productId), {
            'isAvailable': false,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
          print('Product $productId will be marked as unavailable (quantity reached 0)');
        } else {
          // Update quantity
          batch.update(_firestore.collection('products').doc(productId), {
            'quantity': newQuantity,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
          print('Product $productId quantity will be decreased to $newQuantity');
        }
      }
      
      await batch.commit();
      print('All product quantities updated successfully');
    } catch (e) {
      throw 'Failed to decrease product quantities: ${e.toString()}';
    }
  }
}
