import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_constants.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../widgets/custom_text_field.dart';
import 'consumer_cart_screen.dart';
import 'consumer_profile_screen.dart';
import 'product_details_screen.dart';
import 'consumer_main_screen.dart';

// Helper function to convert hex color strings to Color objects
Color hexToColor(String hexString) {
  final buffer = StringBuffer();
  if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
  buffer.write(hexString.replaceFirst('#', ''));
  return Color(int.parse(buffer.toString(), radix: 16));
}

class ConsumerHomeScreen extends StatefulWidget {
  const ConsumerHomeScreen({super.key});

  @override
  State<ConsumerHomeScreen> createState() => _ConsumerHomeScreenState();
}

class _ConsumerHomeScreenState extends State<ConsumerHomeScreen> {
  final _productService = ProductService();
  final _cartService = CartService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<CategoryModel> _categories = [];
  String _selectedCategory = 'all';
  bool _isLoading = true;
  int _cartItemCount = 0;

  // Get predefined categories from model
  final List<CategoryModel> _demoCategories = DemoCategories.getCategories();

  @override
  void initState() {
    super.initState();
    _categories = _demoCategories;
    _loadData();
    _loadCartCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final products = await _productService.getAllProducts();
      
      // Always show all predefined categories regardless of available products
      final allCategories = <CategoryModel>[
        // Always include "All" category first
        CategoryModel(id: 'all', name: 'All', icon: '', color: '#D84315'),
        // Add all predefined categories
        ..._demoCategories,
      ];
      
      setState(() {
        _products = products;
        _categories = allCategories;
      });
      
      // Apply initial filtering
      _filterProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCartCount() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final count = await _cartService.getCartItemCount(user.uid);
        setState(() => _cartItemCount = count);
      } catch (e) {
        // Ignore cart count errors
      }
    }
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = _searchController.text.isEmpty ||
            product.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchesCategory = _selectedCategory == 'all' ||
            product.category == _selectedCategory;
        
        final isAvailable = product.isAvailable;
        
        return matchesSearch && matchesCategory && isAvailable;
      }).toList();
    });
  }

  Future<void> _addToCart(ProductModel product) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _cartService.addToCart(user.uid, product, 1);
      await _loadCartCount();
      
      // Also refresh cart count in the main screen
      final mainScreen = context.findAncestorStateOfType<ConsumerMainScreenState>();
      if (mainScreen != null) {
        mainScreen.refreshCartCount();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.title} added to cart!'),
          backgroundColor: AppConstants.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to cart: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
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
              // Header with Search and Profile
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
                child: Column(
                  children: [
                    // Top row with greeting and profile
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Good day!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Find fresh produce',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Cart Icon with Badge
                        GestureDetector(
                          onTap: () {
                            // Navigate to cart screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ConsumerCartScreen()),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.shopping_cart,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            if (_cartItemCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppConstants.accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    '$_cartItemCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: AppConstants.paddingMedium),
                        
                        // Profile Icon
                        GestureDetector(
                          onTap: () {
                            // Navigate to profile screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ConsumerProfileScreen()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    // Search Bar
                    CustomTextField(
                      label: 'Search for fresh produce...',
                      controller: _searchController,
                      prefixIcon: const Icon(Icons.search, color: AppConstants.primaryColor),
                      onChanged: (_) => _filterProducts(),
                    ),
                  ],
                ),
              ).animate().slideY(duration: 500.ms),
              
              // Categories
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = _selectedCategory == category.id;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedCategory = category.id);
                        _filterProducts();
                      },
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: AppConstants.paddingMedium),
                        decoration: BoxDecoration(
                          color: isSelected ? hexToColor(category.color) : Colors.white,
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              category.icon,
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppConstants.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ).animate(delay: Duration(milliseconds: index * 100))
                     .scale(duration: 300.ms);
                  },
                ),
              ),
              
              // Products Grid
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredProducts.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(AppConstants.paddingLarge),
                              itemCount: _filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = _filteredProducts[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                                  child: _buildProductCard(product, index),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 80,
            color: AppConstants.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty 
                ? 'No products found'
                : 'No products available',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty 
                ? 'Try a different search term'
                : 'Check back later for fresh produce!',
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        height: 280, // Fixed height for ListView
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
          // Product Image
          Container(
            height: 160, // Fixed height instead of Expanded
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppConstants.borderRadiusLarge),
                ),
                image: product.imageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(product.imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: product.imageUrl.isEmpty ? AppConstants.backgroundColor : null,
              ),
              child: product.imageUrl.isEmpty
                  ? const Center(
                      child: Icon(
                        Icons.image,
                        size: 40,
                        color: AppConstants.textSecondary,
                      ),
                    )
                  : null,
            ),
          ),
          
          // Product Info
          Expanded( // This is now safe with fixed container height
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Farmer name
                  Text(
                    'by ${product.farmerName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppConstants.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const Spacer(),
                  
                  // Price and Add to Cart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price display with strikethrough for original price
                            Row(
                              children: [
                                Text(
                                  '\$${product.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                                if (product.originalPrice != null && product.originalPrice! > product.price) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '\$${product.originalPrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppConstants.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Quantity and unit info
                            Row(
                              children: [
                                Text(
                                  '${product.quantity} ${product.unit} available',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppConstants.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // Add to Cart Button
                      GestureDetector(
                        onTap: () => _addToCart(product),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 100))
     .scale(duration: 400.ms)
     .fadeIn(),
    );
  }
}
