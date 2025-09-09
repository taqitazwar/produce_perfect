import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../models/user_model.dart';
import '../../models/order_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/address_picker.dart';

class ConsumerProfileScreen extends StatefulWidget {
  const ConsumerProfileScreen({super.key});

  @override
  State<ConsumerProfileScreen> createState() => _ConsumerProfileScreenState();
}

class _ConsumerProfileScreenState extends State<ConsumerProfileScreen> {
  final _authService = AuthService();
  final _orderService = OrderService();
  UserModel? _userProfile;
  List<OrderModel> _recentOrders = [];
  bool _isLoading = true;
  bool _isEditing = false;

  // Edit controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  AddressResult? _selectedAddress;

  // Stats
  int _totalOrders = 0;
  double _totalSpent = 0.0;
  double _carbonSaved = 0.0;
  double _foodSaved = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      final user = _authService.currentUser;
      if (user != null) {
        // Load profile first
        final profile = await _authService.getUserProfile(user.uid);
        
        // Load orders with fallback
        List<OrderModel> orders = [];
        try {
          orders = await _orderService.getOrdersByCustomer(user.uid);
        } catch (e) {
          print('Failed to load orders: $e');
          // Continue with empty orders list
        }
        
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _recentOrders = orders.take(5).toList();
          });
        }

        if (profile != null) {
          _nameController.text = profile.name;
          _phoneController.text = profile.phoneNumber ?? '';
        }

        // Calculate stats
        _calculateStats(orders);
      }
    } catch (e) {
      print('Consumer profile loading error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile. Please check your connection.'),
            backgroundColor: AppConstants.errorColor,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadProfile,
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateStats(List<OrderModel> orders) {
    _totalOrders = orders.length;
    _totalSpent = orders
        .where((order) => order.status == OrderStatus.delivered)
        .fold(0.0, (sum, order) => sum + order.total);
    
    // Calculate environmental impact
    for (final order in orders) {
      if (order.status == OrderStatus.delivered) {
        for (final item in order.items) {
          _foodSaved += item.quantity;
          _carbonSaved += item.quantity * 2.1; // ~2.1 kg CO2 per kg food waste prevented
        }
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_userProfile == null) return;

    try {
      setState(() => _isLoading = true);

      await _authService.updateUserProfile(
        uid: _userProfile!.uid,
        data: {
          'name': _nameController.text.trim(),
          'address': _selectedAddress?.address ?? _userProfile!.address ?? '',
          'latitude': _selectedAddress?.latitude ?? _userProfile!.latitude,
          'longitude': _selectedAddress?.longitude ?? _userProfile!.longitude,
          'placeId': _selectedAddress?.placeId ?? _userProfile!.placeId,
          'phoneNumber': _phoneController.text.trim().isEmpty 
              ? null 
              : _phoneController.text.trim(),
        },
      );

      setState(() => _isEditing = false);
      await _loadProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppConstants.errorColor),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Failed to load profile'),
        ),
      );
    }

    final dateFormat = DateFormat('MMMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: () => setState(() => _isEditing = false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            children: [
              // Profile Header
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
                  children: [
                    // Profile Picture
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: AppConstants.primaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.paddingMedium),
                    
                    // Name
                    if (_isEditing) ...[
                      CustomTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        isRequired: true,
                      ),
                    ] else ...[
                      Text(
                        _userProfile!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Produce Perfect Customer',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Member since ${dateFormat.format(_userProfile!.createdAt)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(delay: 100.ms, duration: 500.ms),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Shopping Stats
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
                      'Your Shopping Stats',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    // Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: AppConstants.paddingMedium,
                      mainAxisSpacing: AppConstants.paddingMedium,
                      children: [
                        _buildStatCard(
                          'Orders',
                          '$_totalOrders',
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Spent',
                          '\$${_totalSpent.toStringAsFixed(0)}',
                          AppConstants.primaryColor,
                        ),
                        _buildStatCard(
                          'Food Saved',
                          '${_foodSaved.toStringAsFixed(1)} kg',
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Carbon Saved',
                          '${_carbonSaved.toStringAsFixed(1)} kg CO₂',
                          Colors.teal,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().slideY(delay: 200.ms, duration: 500.ms),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Contact Information
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
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    if (_isEditing) ...[
                      AddressPicker(
                        label: 'Delivery Address',
                        onAddressSelected: (address) {
                          setState(() {
                            _selectedAddress = address;
                          });
                        },
                        isRequired: true,
                        initialValue: _userProfile?.address,
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      CustomTextField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Save Changes',
                              onPressed: _updateProfile,
                              isLoading: _isLoading,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildInfoRow(
                        Icons.email,
                        'Email',
                        _userProfile!.email,
                      ),
                      _buildInfoRow(
                        Icons.phone,
                        'Phone',
                        _userProfile!.phoneNumber ?? 'Not provided',
                      ),
                    ],
                  ],
                ),
              ).animate().slideY(delay: 300.ms, duration: 500.ms),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Recent Orders
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
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    if (_recentOrders.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppConstants.paddingLarge),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 60,
                                color: AppConstants.textSecondary,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No orders yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppConstants.textSecondary,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start shopping for fresh produce!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppConstants.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentOrders.length,
                        itemBuilder: (context, index) {
                          final order = _recentOrders[index];
                          return _buildOrderItem(order, index);
                        },
                      ),
                  ],
                ),
              ).animate().slideY(delay: 400.ms, duration: 500.ms),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Sign Out Button
              if (!_isEditing)
                CustomButton(
                  text: 'Sign Out',
                  onPressed: _signOut,
                  isOutlined: true,
                  textColor: AppConstants.errorColor,
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderModel order, int index) {
    final dateFormat = DateFormat('MMM dd, h:mm a');
    
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppConstants.backgroundColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: Row(
        children: [
          // Status Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(order.status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getStatusIcon(order.status),
              color: Colors.white,
              size: 20,
            ),
          ),
          
          const SizedBox(width: AppConstants.paddingMedium),
          
          // Order Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.items.length} items from ${order.farmerName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(order.orderDate),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Price and Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              Text(
                order.statusDisplayName,
                style: TextStyle(
                  fontSize: 10,
                  color: _getStatusColor(order.status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 50))
     .slideX(duration: 300.ms);
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.readyForPickup:
        return AppConstants.primaryColor;
      case OrderStatus.pickedUp:
        return Colors.indigo;
      case OrderStatus.inTransit:
        return Colors.teal;
      case OrderStatus.delivered:
        return AppConstants.successColor;
      case OrderStatus.cancelled:
        return AppConstants.errorColor;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.schedule;
      case OrderStatus.confirmed:
        return Icons.check_circle_outline;
      case OrderStatus.preparing:
        return Icons.kitchen;
      case OrderStatus.readyForPickup:
        return Icons.inventory;
      case OrderStatus.pickedUp:
        return Icons.local_shipping;
      case OrderStatus.inTransit:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }
}
