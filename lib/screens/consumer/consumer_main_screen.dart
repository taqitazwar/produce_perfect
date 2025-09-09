import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import 'consumer_home_screen.dart';
import 'consumer_cart_screen.dart';
import 'consumer_orders_screen.dart';
import 'consumer_profile_screen.dart';

class ConsumerMainScreen extends StatefulWidget {
  const ConsumerMainScreen({super.key});

  @override
  State<ConsumerMainScreen> createState() => ConsumerMainScreenState();
}

class ConsumerMainScreenState extends State<ConsumerMainScreen> {
  int _currentIndex = 0;
  int _cartItemCount = 0;
  final _cartService = CartService();
  final _authService = AuthService();
  
  void setCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCartCount();
  }

  Future<void> _loadCartCount() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final count = await _cartService.getCartItemCount(user.uid);
        if (mounted) {
          setState(() => _cartItemCount = count);
        }
      } catch (e) {
        // Ignore cart count errors
      }
    }
  }

  // Method to refresh cart count from other screens
  void refreshCartCount() {
    _loadCartCount();
  }

  final List<Widget> _screens = [
    const ConsumerHomeScreen(),
    const ConsumerCartScreen(),
    const ConsumerOrdersScreen(),
    const ConsumerProfileScreen(),
  ];

  Widget _buildCartIconWithBadge() {
    return Stack(
      children: [
        const Icon(Icons.shopping_cart),
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
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                '$_cartItemCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          // Refresh cart count when navigating to cart tab
          if (index == 1) {
            _loadCartCount();
          }
        },
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textSecondary,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildCartIconWithBadge(),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

