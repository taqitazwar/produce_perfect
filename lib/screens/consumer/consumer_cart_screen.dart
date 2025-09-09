import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_constants.dart';
import '../../services/cart_service.dart';
import '../../services/product_service.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../services/maps_service.dart';
import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/address_picker.dart';
import 'payment_screen.dart';

class ConsumerCartScreen extends StatefulWidget {
  const ConsumerCartScreen({super.key});

  @override
  State<ConsumerCartScreen> createState() => _ConsumerCartScreenState();
}

class _ConsumerCartScreenState extends State<ConsumerCartScreen> {
  final _cartService = CartService();
  final _productService = ProductService();
  final _orderService = OrderService();
  final _authService = AuthService();
  final _instructionsController = TextEditingController();
  
  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  bool _isCheckingOut = false;
  double _subtotal = 0.0;
  double _deliveryFee = 0.0;
  double _total = 0.0;
  
  // Address selection
  AddressResult? _selectedAddress;
  bool _isCalculatingDistance = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _loadCart() async {
    try {
      setState(() => _isLoading = true);
      final user = _authService.currentUser;
      if (user != null) {
        final cartItems = await _cartService.getCart(user.uid);
        _calculateTotals(cartItems);
        setState(() => _cartItems = cartItems);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load cart: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotals(List<CartItem> items) {
    _subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    // Delivery fee will be calculated based on distance when address is selected
    _total = _subtotal + _deliveryFee;
  }

  Future<void> _onAddressSelected(AddressResult address) async {
    setState(() {
      _selectedAddress = address;
      _isCalculatingDistance = true;
    });

    try {
      // Calculate distance to all farmers and get average delivery fee
      double totalDeliveryFee = 0.0;
      int farmerCount = 0;
      
      // Group items by farmer to calculate individual distances
      final Map<String, List<CartItem>> itemsByFarmer = {};
      for (final item in _cartItems) {
        if (!itemsByFarmer.containsKey(item.farmerId)) {
          itemsByFarmer[item.farmerId] = [];
        }
        itemsByFarmer[item.farmerId]!.add(item);
      }

      for (final farmerId in itemsByFarmer.keys) {
        // Get farmer's real address for distance calculation
        UserModel? farmerProfile;
        double farmLat = 0.0;
        double farmLng = 0.0;
        
        try {
          farmerProfile = await _authService.getUserProfile(farmerId);
          if (farmerProfile != null && 
              farmerProfile.farmLatitude != null && 
              farmerProfile.farmLongitude != null) {
            farmLat = farmerProfile.farmLatitude!;
            farmLng = farmerProfile.farmLongitude!;
          } else if (farmerProfile != null && 
                     farmerProfile.latitude != null && 
                     farmerProfile.longitude != null) {
            // Fallback to general address if farm-specific address not available
            farmLat = farmerProfile.latitude!;
            farmLng = farmerProfile.longitude!;
          } else {
            // Last resort: use mock coordinates near St. John's, NL
            farmLat = 47.5615 + (farmerId.hashCode % 10) * 0.001;
            farmLng = -52.7126 + (farmerId.hashCode % 10) * 0.001;
          }
        } catch (e) {
          // Error fetching farmer profile, use mock coordinates near St. John's, NL
          farmLat = 47.5615 + (farmerId.hashCode % 10) * 0.001;
          farmLng = -52.7126 + (farmerId.hashCode % 10) * 0.001;
        }
        
        final distanceResult = await MapsService.calculateDistance(
          fromLat: farmLat,
          fromLng: farmLng,
          toLat: address.latitude,
          toLng: address.longitude,
        );

        if (distanceResult.success) {
          final farmerDeliveryFee = MapsService.calculateDeliveryFee(distanceResult.distanceKm);
          totalDeliveryFee += farmerDeliveryFee;
          farmerCount++;
        }
      }

      setState(() {
        _deliveryFee = farmerCount > 0 ? totalDeliveryFee / farmerCount : 5.99;
        _total = _subtotal + _deliveryFee;
        _isCalculatingDistance = false;
      });
    } catch (e) {
      setState(() {
        _deliveryFee = 5.99; // Fallback fee
        _total = _subtotal + _deliveryFee;
        _isCalculatingDistance = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not calculate delivery fee: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      if (newQuantity <= 0) {
        await _cartService.removeFromCart(user.uid, item.productId);
      } else {
        // Check product availability and stock
        final product = await _productService.getProduct(item.productId);
        if (product == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product no longer available'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
          return;
        }
        
        // Check if requested quantity exceeds available stock
        if (newQuantity > product.quantity) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only ${product.quantity} ${product.unit} available'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
          return;
        }
        
        await _cartService.updateCartItem(user.uid, item.productId, newQuantity);
      }
      await _loadCart();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update cart: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _removeItem(CartItem item) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove ${item.productTitle} from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppConstants.errorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _cartService.removeFromCart(user.uid, item.productId);
        await _loadCart();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.productTitle} removed from cart'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _checkout() async {
    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    final user = _authService.currentUser;
    if (user == null || _cartItems.isEmpty) return;

    final userProfile = await _authService.getUserProfile(user.uid);
    if (userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User profile not found'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    // Navigate to payment screen
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: _total,
          customerName: userProfile.name,
          customerEmail: userProfile.email,
          onPaymentComplete: (success, paymentIntentId) async {
            // The payment screen handles its own dialog and navigation
            // We just need to process the order if successful
            if (success) {
              await _processOrder();
            }
          },
        ),
      ),
    );
  }

  Future<void> _processOrder() async {
    final user = _authService.currentUser;
    if (user == null || _cartItems.isEmpty || _selectedAddress == null) return;

    setState(() => _isCheckingOut = true);

    try {
      final userProfile = await _authService.getUserProfile(user.uid);
      if (userProfile == null) {
        throw 'User profile not found';
      }

      // Group items by farmer
      final Map<String, List<CartItem>> itemsByFarmer = {};
      for (final item in _cartItems) {
        if (!itemsByFarmer.containsKey(item.farmerId)) {
          itemsByFarmer[item.farmerId] = [];
        }
        itemsByFarmer[item.farmerId]!.add(item);
      }

      // Create separate orders for each farmer
      for (final entry in itemsByFarmer.entries) {
        final farmerId = entry.key;
        final farmerItems = entry.value;
        final farmerName = farmerItems.first.farmerName;

        // Convert cart items to order items
        final orderItems = farmerItems.map((cartItem) => OrderItem(
          productId: cartItem.productId,
          productTitle: cartItem.productTitle,
          productImage: cartItem.productImage,
          price: cartItem.unitPrice,
          quantity: cartItem.quantity,
          unit: cartItem.unit,
        )).toList();

        // Get farmer's real address for distance calculation
        UserModel? farmerProfile;
        double farmLat = 0.0;
        double farmLng = 0.0;
        
        try {
          farmerProfile = await _authService.getUserProfile(farmerId);
          if (farmerProfile != null && 
              farmerProfile.farmLatitude != null && 
              farmerProfile.farmLongitude != null) {
            farmLat = farmerProfile.farmLatitude!;
            farmLng = farmerProfile.farmLongitude!;
          } else if (farmerProfile != null && 
                     farmerProfile.latitude != null && 
                     farmerProfile.longitude != null) {
            // Fallback to general address if farm-specific address not available
            farmLat = farmerProfile.latitude!;
            farmLng = farmerProfile.longitude!;
          } else {
            // Last resort: use mock coordinates near St. John's, NL
            farmLat = 47.5615 + (farmerId.hashCode % 10) * 0.001;
            farmLng = -52.7126 + (farmerId.hashCode % 10) * 0.001;
          }
        } catch (e) {
          // Error fetching farmer profile, use mock coordinates near St. John's, NL
          farmLat = 47.5615 + (farmerId.hashCode % 10) * 0.001;
          farmLng = -52.7126 + (farmerId.hashCode % 10) * 0.001;
        }
        
        final distanceResult = await MapsService.calculateDistance(
          fromLat: farmLat,
          fromLng: farmLng,
          toLat: _selectedAddress!.latitude,
          toLng: _selectedAddress!.longitude,
        );

        await _orderService.createOrderWithLocation(
          customerId: user.uid,
          customerName: userProfile.name,
          customerPhone: userProfile.phoneNumber ?? 'Not provided',
          farmerId: farmerId,
          farmerName: farmerName,
          items: orderItems,
          deliveryAddress: _selectedAddress!.address,
          deliveryLatitude: _selectedAddress!.latitude,
          deliveryLongitude: _selectedAddress!.longitude,
          deliveryPlaceId: _selectedAddress!.placeId,
          farmLocation: farmerProfile?.farmAddress ?? farmerProfile?.address ?? 'Farm Location',
          farmLatitude: farmLat,
          farmLongitude: farmLng,
          farmPlaceId: farmerProfile?.farmPlaceId ?? farmerProfile?.placeId ?? 'farm_place_id',
          distanceKm: distanceResult.success ? distanceResult.distanceKm : 10.0,
          specialInstructions: _instructionsController.text.trim().isEmpty 
              ? null 
              : _instructionsController.text.trim(),
        );
      }

      // Clear cart after successful order
      await _cartService.clearCart(user.uid);
      
      // Update UI state to reflect empty cart
      if (mounted) {
        setState(() {
          _cartItems.clear();
          _subtotal = 0.0;
          _deliveryFee = 0.0;
          _total = 0.0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );

        // Navigate back to home or order confirmation
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isCheckingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shopping Cart',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.backgroundGradient,
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _cartItems.isEmpty
                ? _buildEmptyCart()
                : Column(
                    children: [
                      // Cart Items
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppConstants.paddingLarge),
                          itemCount: _cartItems.length,
                          itemBuilder: (context, index) {
                            final item = _cartItems[index];
                            return _buildCartItem(item, index);
                          },
                        ),
                      ),
                      
                      // Checkout Section
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppConstants.borderRadiusLarge),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Delivery Address
                            AddressPicker(
                              label: 'Delivery Address',
                              initialValue: _selectedAddress?.address,
                              onAddressSelected: _onAddressSelected,
                              isRequired: true,
                            ),
                            
                            if (_isCalculatingDistance)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Calculating delivery fee...',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppConstants.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            const SizedBox(height: AppConstants.paddingMedium),
                            
                            // Special Instructions
                            CustomTextField(
                              label: 'Special Instructions (optional)',
                              controller: _instructionsController,
                              maxLines: 2,
                              prefixIcon: const Icon(Icons.note, color: AppConstants.primaryColor),
                            ),
                            
                            const SizedBox(height: AppConstants.paddingLarge),
                            
                            // Order Summary
                            Container(
                              padding: const EdgeInsets.all(AppConstants.paddingMedium),
                              decoration: BoxDecoration(
                                color: AppConstants.backgroundColor,
                                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                              ),
                              child: Column(
                                children: [
                                  _buildSummaryRow('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
                                  _buildSummaryRow(
                                    'Delivery Fee', 
                                    _selectedAddress == null 
                                        ? 'Select address first'
                                        : '\$${_deliveryFee.toStringAsFixed(2)}',
                                  ),
                                  if (_selectedAddress != null)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Based on distance: km x 2 x \$2',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppConstants.textSecondary,
                                        ),
                                      ),
                                    ),
                                  const Divider(),
                                  _buildSummaryRow(
                                    'Total', 
                                    '\$${_total.toStringAsFixed(2)}',
                                    isTotal: true,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: AppConstants.paddingLarge),
                            
                            // Checkout Button
                            CustomButton(
                              text: 'Place Order',
                              onPressed: _checkout,
                              isLoading: _isCheckingOut,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add some fresh produce to get started!',
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Product Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              image: item.productImage.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(item.productImage),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: item.productImage.isEmpty ? AppConstants.backgroundColor : null,
            ),
            child: item.productImage.isEmpty
                ? const Icon(
                    Icons.image,
                    size: 30,
                    color: AppConstants.textSecondary,
                  )
                : null,
          ),
          
          const SizedBox(width: AppConstants.paddingMedium),
          
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'by ${item.farmerName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.unitPrice.toStringAsFixed(2)} per ${item.unit}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          // Quantity Controls and Price
          Column(
            children: [
              // Remove button
              GestureDetector(
                onTap: () => _removeItem(item),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: AppConstants.errorColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Quantity controls
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _updateQuantity(item, item.quantity - 1),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppConstants.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.remove,
                        size: 16,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ),
                  
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                  ),
                  
                  GestureDetector(
                    onTap: () => _updateQuantity(item, item.quantity + 1),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Total price for this item
              Text(
                '\$${item.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
     .slideX(duration: 400.ms)
     .fadeIn();
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: AppConstants.textPrimary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: isTotal ? AppConstants.primaryColor : AppConstants.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
