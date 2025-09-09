import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import 'consumer_main_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final _cartService = CartService();
  final _authService = AuthService();
  int _selectedQuantity = 1;
  bool _isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    // Set max quantity to available stock
    _selectedQuantity = 1;
  }

  Future<void> _addToCart() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isAddingToCart = true);

    try {
      await _cartService.addToCart(user.uid, widget.product, _selectedQuantity);
      
      // Also refresh cart count in the main screen
      final mainScreen = context.findAncestorStateOfType<ConsumerMainScreenState>();
      if (mainScreen != null) {
        mainScreen.refreshCartCount();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product.title} added to cart!'),
            backgroundColor: AppConstants.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to cart: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingToCart = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    Expanded(
                      child: Text(
                        'Product Details',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(duration: 500.ms),

              // Product Image
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: widget.product.imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.product.imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: widget.product.imageUrl.isEmpty ? AppConstants.backgroundColor : null,
                ),
                child: widget.product.imageUrl.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.image,
                          size: 80,
                          color: AppConstants.textSecondary,
                        ),
                      )
                    : null,
              ).animate().fadeIn(duration: 600.ms),

              // Product Details
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title and Farmer
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.product.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppConstants.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'by ${widget.product.farmerName}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppConstants.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().slideX(delay: 100.ms, duration: 500.ms),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // Price and Quantity Section
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pricing & Availability',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Price Display
                            Row(
                              children: [
                                Text(
                                  '\$${widget.product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                if (widget.product.originalPrice != null && 
                                    widget.product.originalPrice! > widget.product.price) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    '\$${widget.product.originalPrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      color: AppConstants.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppConstants.successColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppConstants.successColor.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'per ${widget.product.unit}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppConstants.successColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppConstants.paddingLarge),

                            // Quantity Selector
                            Row(
                              children: [
                                const Text(
                                  'Quantity:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppConstants.textPrimary,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      // Decrease button
                                      GestureDetector(
                                        onTap: _selectedQuantity > 1
                                            ? () => setState(() => _selectedQuantity--)
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _selectedQuantity > 1
                                                ? AppConstants.primaryColor.withOpacity(0.1)
                                                : Colors.grey.withOpacity(0.1),
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(8),
                                              bottomLeft: Radius.circular(8),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            color: _selectedQuantity > 1
                                                ? AppConstants.primaryColor
                                                : Colors.grey,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                      // Quantity display
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          border: Border.symmetric(
                                            vertical: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        child: Text(
                                          '$_selectedQuantity',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppConstants.textPrimary,
                                          ),
                                        ),
                                      ),
                                      // Increase button
                                      GestureDetector(
                                        onTap: _selectedQuantity < widget.product.quantity
                                            ? () => setState(() => _selectedQuantity++)
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: _selectedQuantity < widget.product.quantity
                                                ? AppConstants.primaryColor.withOpacity(0.1)
                                                : Colors.grey.withOpacity(0.1),
                                            borderRadius: const BorderRadius.only(
                                              topRight: Radius.circular(8),
                                              bottomRight: Radius.circular(8),
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: _selectedQuantity < widget.product.quantity
                                                ? AppConstants.primaryColor
                                                : Colors.grey,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Stock info
                            Text(
                              '${widget.product.quantity} ${widget.product.unit} available',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppConstants.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideX(delay: 200.ms, duration: 500.ms),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // Description Section
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Text(
                              widget.product.description,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppConstants.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideX(delay: 300.ms, duration: 500.ms),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // Condition Section
                      if (widget.product.condition.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(AppConstants.paddingLarge),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Condition',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppConstants.paddingMedium),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppConstants.warningColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppConstants.warningColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: AppConstants.warningColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.product.condition,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppConstants.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().slideX(delay: 400.ms, duration: 500.ms),

                      if (widget.product.condition.isNotEmpty)
                        const SizedBox(height: AppConstants.paddingLarge),

                      // Dates Section
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Product Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingLarge),

                            // Harvest Date
                            _buildInfoRow(
                              icon: Icons.agriculture,
                              label: 'Harvest Date',
                              value: DateFormat('MMM dd, yyyy').format(widget.product.harvestDate),
                              color: AppConstants.successColor,
                            ),

                            const SizedBox(height: AppConstants.paddingMedium),

                            // Expiry Date
                            _buildInfoRow(
                              icon: Icons.schedule,
                              label: 'Best Before',
                              value: DateFormat('MMM dd, yyyy').format(widget.product.expiryDate),
                              color: AppConstants.errorColor,
                            ),

                            const SizedBox(height: AppConstants.paddingMedium),

                            // Farm Location
                            _buildInfoRow(
                              icon: Icons.location_on,
                              label: 'Farm Location',
                              value: widget.product.farmLocation,
                              color: AppConstants.primaryColor,
                            ),
                          ],
                        ),
                      ).animate().slideX(delay: 500.ms, duration: 500.ms),

                      const SizedBox(height: AppConstants.paddingXLarge),
                    ],
                  ),
                ),
              ),

              // Add to Cart Button
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: CustomButton(
                  text: 'Add to Cart - \$${(_selectedQuantity * widget.product.price).toStringAsFixed(2)}',
                  onPressed: _isAddingToCart ? null : _addToCart,
                  isLoading: _isAddingToCart,
                ),
              ).animate().slideY(delay: 600.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppConstants.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConstants.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
