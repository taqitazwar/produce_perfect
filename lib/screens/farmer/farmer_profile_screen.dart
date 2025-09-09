import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../models/user_model.dart';
import '../../models/product_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/address_picker.dart';

class FarmerProfileScreen extends StatefulWidget {
  const FarmerProfileScreen({super.key});

  @override
  State<FarmerProfileScreen> createState() => _FarmerProfileScreenState();
}

class _FarmerProfileScreenState extends State<FarmerProfileScreen> {
  final _authService = AuthService();
  final _productService = ProductService();
  UserModel? _userProfile;
  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isEditing = false;

  // Edit controllers
  final _nameController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _farmAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  AddressResult? _selectedFarmAddress;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _farmNameController.dispose();
    _farmAddressController.dispose();
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
        
        // Load products with fallback
        List<ProductModel> products = [];
        try {
          products = await _productService.getProductsByFarmer(user.uid);
        } catch (e) {
          print('Failed to load products: $e');
          // Continue with empty products list
        }
        
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _products = products;
          });
        }

        if (profile != null) {
          _nameController.text = profile.name;
          _farmNameController.text = profile.farmName ?? '';
          _farmAddressController.text = profile.farmAddress ?? '';
          _phoneController.text = profile.phoneNumber ?? '';
        }
      }
    } catch (e) {
      print('Profile loading error: $e');
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
      if (mounted) {
        setState(() => _isLoading = false);
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
          'farmName': _farmNameController.text.trim(),
          'farmAddress': _selectedFarmAddress?.address ?? _userProfile!.farmAddress ?? '',
          'farmLatitude': _selectedFarmAddress?.latitude ?? _userProfile!.farmLatitude,
          'farmLongitude': _selectedFarmAddress?.longitude ?? _userProfile!.farmLongitude,
          'farmPlaceId': _selectedFarmAddress?.placeId ?? _userProfile!.farmPlaceId,
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

  Map<String, dynamic> _calculateImpactStats() {
    if (_products.isEmpty) {
      return {
        'totalProducts': 0,
        'totalQuantity': 0.0,
        'estimatedWasteSaved': 0.0,
        'carbonFootprintSaved': 0.0,
        'totalEarnings': 0.0,
        'avgSavings': 0.0,
      };
    }

    double totalQuantity = 0;
    double totalEarnings = 0;
    double totalSavings = 0;

    for (var product in _products) {
      totalQuantity += product.quantity;
      // Estimate earnings from sold products (assuming 70% sell rate)
      totalEarnings += (product.discountedPrice * product.quantity * 0.7);
      totalSavings += ((product.originalPrice - product.discountedPrice) * product.quantity * 0.7);
    }

    // Rough estimates for environmental impact
    double estimatedWasteSaved = totalQuantity * 0.8; // 80% would have been wasted
    double carbonFootprintSaved = estimatedWasteSaved * 2.1; // ~2.1 kg CO2 per kg food waste

    return {
      'totalProducts': _products.length,
      'totalQuantity': totalQuantity,
      'estimatedWasteSaved': estimatedWasteSaved,
      'carbonFootprintSaved': carbonFootprintSaved,
      'totalEarnings': totalEarnings,
      'avgSavings': _products.isNotEmpty ? totalSavings / _products.length : 0.0,
    };
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

    final stats = _calculateImpactStats();
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
                        Icons.agriculture,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: AppConstants.paddingMedium),
                    
                    // Name and Farm
                    if (_isEditing) ...[
                      CustomTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        isRequired: true,
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      CustomTextField(
                        label: 'Farm Name',
                        controller: _farmNameController,
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
                      Text(
                        _userProfile!.farmName ?? 'Farm Name Not Set',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppConstants.primaryColor,
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
              
              // Impact Statistics
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
                      'Your Impact',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    // Impact Stats Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: AppConstants.paddingMedium,
                      mainAxisSpacing: AppConstants.paddingMedium,
                      children: [
                        _buildStatCard(
                          'Food Saved',
                          '${stats['estimatedWasteSaved'].toStringAsFixed(1)} kg',
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Carbon Saved',
                          '${stats['carbonFootprintSaved'].toStringAsFixed(1)} kg CO₂',
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Products Listed',
                          '${stats['totalProducts']}',
                          AppConstants.primaryColor,
                        ),
                        _buildStatCard(
                          '💰 Estimated Earnings',
                          '\$${stats['totalEarnings'].toStringAsFixed(0)}',
                          Colors.orange,
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
                        label: 'Farm Address',
                        onAddressSelected: (address) {
                          setState(() {
                            _selectedFarmAddress = address;
                          });
                        },
                        isRequired: true,
                        initialValue: _userProfile?.farmAddress,
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
                      _buildInfoRow(
                        Icons.location_on,
                        'Farm Address',
                        _userProfile!.farmAddress ?? 'Not provided',
                      ),
                    ],
                  ],
                ),
              ).animate().slideY(delay: 300.ms, duration: 500.ms),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Sign Out Button
              if (!_isEditing)
                CustomButton(
                  text: 'Sign Out',
                  onPressed: _signOut,
                  isOutlined: true,
                  textColor: AppConstants.errorColor,
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
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
}
