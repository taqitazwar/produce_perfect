import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_logo.dart';
import '../../services/auth_service.dart';
import 'farmer_signup_screen.dart';
import 'consumer_signup_screen.dart';
import 'rider_signup_screen.dart';

class UserTypeSelectionScreen extends StatefulWidget {
  const UserTypeSelectionScreen({super.key});

  @override
  State<UserTypeSelectionScreen> createState() => _UserTypeSelectionScreenState();
}

class _UserTypeSelectionScreenState extends State<UserTypeSelectionScreen> {
  String? _selectedUserType;

  final List<UserTypeOption> _userTypes = [
    UserTypeOption(
      type: AppConstants.userTypeFarmer,
      title: 'I own a farm',
      description: 'I grow produce and want to sell my imperfect items',
      icon: Icons.agriculture,
      color: Colors.green,
      benefits: [
        'List your imperfect produce',
        'Reduce food waste',
        'Earn extra income',
        'Connect with local customers',
      ],
    ),
    UserTypeOption(
      type: AppConstants.userTypeRider,
      title: 'I want to deliver',
      description: 'I want to deliver produce and earn money',
      icon: Icons.delivery_dining,
      color: Colors.blue,
      benefits: [
        'Flexible delivery schedules',
        'Earn money helping farmers',
        'Support sustainable food system',
        'Work in your local area',
      ],
    ),
    UserTypeOption(
      type: AppConstants.userTypeCustomer,
      title: 'I want to buy fresh produce',
      description: 'I want to buy fresh, imperfect produce at great prices',
      icon: Icons.shopping_basket,
      color: Colors.orange,
      benefits: [
        'Save money on fresh produce',
        'Support local farmers',
        'Reduce food waste',
        'Get unique, imperfect items',
      ],
    ),
  ];

  void _navigateToSignUp() {
    if (_selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user type'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    Widget nextScreen;
    switch (_selectedUserType) {
      case AppConstants.userTypeFarmer:
        nextScreen = const FarmerSignUpScreen();
        break;
      case AppConstants.userTypeCustomer:
        nextScreen = const ConsumerSignUpScreen();
        break;
      case AppConstants.userTypeRider:
        nextScreen = const RiderSignUpScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Header
                Column(
                  children: [
                    const AppLogo(
                      size: 100,
                      iconSize: 50,
                    ).animate().scale(delay: 200.ms, duration: 600.ms),
                    
                    const SizedBox(height: AppConstants.paddingLarge),
                    
                    Text(
                      'Choose Your Role',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().slideX(delay: 400.ms, duration: 500.ms),
                    
                    const SizedBox(height: AppConstants.paddingSmall),
                    
                    Text(
                      'How would you like to use ProducePerfect?',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppConstants.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().slideX(delay: 500.ms, duration: 500.ms),
                  ],
                ),
                
                const SizedBox(height: AppConstants.paddingXLarge),
                
                // User Type Options
                Expanded(
                  child: ListView.builder(
                    itemCount: _userTypes.length,
                    itemBuilder: (context, index) {
                      final userType = _userTypes[index];
                      final isSelected = _selectedUserType == userType.type;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                        child: _buildUserTypeCard(userType, isSelected),
                      ).animate(delay: Duration(milliseconds: 600 + (index * 100)))
                       .slideX(duration: 500.ms)
                       .fadeIn();
                    },
                  ),
                ),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Continue Button
                CustomButton(
                  text: 'Continue',
                  onPressed: _navigateToSignUp,
                ).animate().slideY(delay: 1000.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeCard(UserTypeOption userType, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = userType.type;
        });
      },
      child: AnimatedContainer(
        duration: AppConstants.animationNormal,
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppConstants.primaryColor.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 15 : 5,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: userType.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                  child: Icon(
                    userType.icon,
                    size: 30,
                    color: userType.color,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userType.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingSmall / 2),
                      Text(
                        userType.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: AppConstants.animationFast,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppConstants.primaryColor : Colors.grey[400]!,
                      width: 2,
                    ),
                    color: isSelected ? AppConstants.primaryColor : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Benefits:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            ...userType.benefits.map((benefit) => Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall / 2),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: userType.color,
                  ),
                  const SizedBox(width: AppConstants.paddingSmall),
                  Expanded(
                    child: Text(
                      benefit,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}

class UserTypeOption {
  final String type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> benefits;

  UserTypeOption({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.benefits,
  });
}
