import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class RiderProfileScreen extends StatefulWidget {
  const RiderProfileScreen({super.key});

  @override
  State<RiderProfileScreen> createState() => _RiderProfileScreenState();
}

class _RiderProfileScreenState extends State<RiderProfileScreen> {
  final _authService = AuthService();
  final _orderService = OrderService();
  UserModel? _userProfile;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  bool _isEditing = false;

  // Edit controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _licenseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleTypeController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      setState(() => _isLoading = true);
      final user = _authService.currentUser;
      if (user != null) {
        // Load profile first
        final profile = await _authService.getUserProfile(user.uid);
        
        // Load stats with fallback
        Map<String, dynamic> stats = {};
        try {
          stats = await _orderService.getRiderEarnings(user.uid);
        } catch (e) {
          print('Failed to load rider stats: $e');
          // Continue with empty stats
        }
        
        if (mounted) {
          setState(() {
            _userProfile = profile;
            _stats = stats;
          });
        }

        if (profile != null) {
          _nameController.text = profile.name;
          _phoneController.text = profile.phoneNumber ?? '';
          _vehicleTypeController.text = profile.vehicleType ?? '';
          _licenseController.text = profile.licenseNumber ?? '';
        }
      }
    } catch (e) {
      print('Rider profile loading error: $e');
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
          'phoneNumber': _phoneController.text.trim().isEmpty 
              ? null 
              : _phoneController.text.trim(),
          'vehicleType': _vehicleTypeController.text.trim().isEmpty
              ? null
              : _vehicleTypeController.text.trim(),
          'licenseNumber': _licenseController.text.trim().isEmpty
              ? null
              : _licenseController.text.trim(),
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
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppConstants.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.delivery_dining,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: _userProfile!.isAvailable == true 
                                  ? AppConstants.successColor 
                                  : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Icon(
                              _userProfile!.isAvailable == true 
                                  ? Icons.check 
                                  : Icons.pause,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
                      Text(
                        _userProfile!.isAvailable == true ? 'Available for Deliveries' : 'Currently Offline',
                        style: TextStyle(
                          fontSize: 14,
                          color: _userProfile!.isAvailable == true 
                              ? AppConstants.successColor 
                              : AppConstants.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Rider since ${dateFormat.format(_userProfile!.createdAt)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(delay: 100.ms, duration: 500.ms),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Performance Stats
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
                      'Your Performance',
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
                          'Deliveries',
                          '${_stats['totalDeliveries'] ?? 0}',
                          Colors.blue,
                        ),
                        _buildStatCard(
                          '💰 Earned',
                          '\$${(_stats['totalEarnings'] ?? 0.0).toStringAsFixed(0)}',
                          AppConstants.primaryColor,
                        ),
                        _buildStatCard(
                          '🌱 Food Saved',
                          '${(_stats['vegetablesSaved'] ?? 0.0).toStringAsFixed(1)} kg',
                          Colors.green,
                        ),
                        _buildStatCard(
                          '🌍 Carbon Saved',
                          '${(_stats['carbonSaved'] ?? 0.0).toStringAsFixed(1)} kg CO₂',
                          Colors.teal,
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().slideY(delay: 200.ms, duration: 500.ms),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Contact & Vehicle Information
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
                      'Contact & Vehicle Info',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    if (_isEditing) ...[
                      CustomTextField(
                        label: 'Phone Number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      CustomTextField(
                        label: 'Vehicle Type (e.g., Bicycle, Scooter, Car)',
                        controller: _vehicleTypeController,
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      CustomTextField(
                        label: 'License Number (optional)',
                        controller: _licenseController,
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
                        Icons.directions_car,
                        'Vehicle Type',
                        _userProfile!.vehicleType ?? 'Not specified',
                      ),
                      _buildInfoRow(
                        Icons.credit_card,
                        'License Number',
                        _userProfile!.licenseNumber ?? 'Not provided',
                      ),
                    ],
                  ],
                ),
              ).animate().slideY(delay: 300.ms, duration: 500.ms),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Achievement Badges
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
                      'Achievements',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    Wrap(
                      spacing: AppConstants.paddingMedium,
                      runSpacing: AppConstants.paddingMedium,
                      children: _buildAchievementBadges(),
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

  List<Widget> _buildAchievementBadges() {
    final deliveries = _stats['totalDeliveries'] ?? 0;
    final earnings = _stats['totalEarnings'] ?? 0.0;
    final carbonSaved = _stats['carbonSaved'] ?? 0.0;
    
    List<Widget> badges = [];
    
    // First Delivery Badge
    if (deliveries >= 1) {
      badges.add(_buildBadge('', 'First Delivery', 'Completed your first delivery!'));
    }
    
    // Delivery Milestones
    if (deliveries >= 10) {
      badges.add(_buildBadge('🏆', 'Delivery Pro', '10+ deliveries completed'));
    }
    if (deliveries >= 50) {
      badges.add(_buildBadge('⭐', 'Super Rider', '50+ deliveries completed'));
    }
    if (deliveries >= 100) {
      badges.add(_buildBadge('👑', 'Delivery King', '100+ deliveries completed'));
    }
    
    // Earnings Milestones
    if (earnings >= 100) {
      badges.add(_buildBadge('💰', 'Century Club', 'Earned \$100+'));
    }
    if (earnings >= 500) {
      badges.add(_buildBadge('💎', 'High Earner', 'Earned \$500+'));
    }
    
    // Environmental Impact
    if (carbonSaved >= 50) {
      badges.add(_buildBadge('🌍', 'Eco Warrior', 'Saved 50+ kg CO₂'));
    }
    if (carbonSaved >= 100) {
      badges.add(_buildBadge('🌳', 'Planet Saver', 'Saved 100+ kg CO₂'));
    }
    
    if (badges.isEmpty) {
      badges.add(
        Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: const Text(
            'Complete your first delivery to earn badges!',
            style: TextStyle(
              fontSize: 14,
              color: AppConstants.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    return badges;
  }

  Widget _buildBadge(String emoji, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.primaryColor.withOpacity(0.1),
            AppConstants.secondaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(
          color: AppConstants.primaryColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: const TextStyle(
              fontSize: 10,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
