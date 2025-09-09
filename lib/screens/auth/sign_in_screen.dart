import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:email_validator/email_validator.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_logo.dart';
import '../../services/auth_service.dart';
import '../farmer/farmer_main_screen.dart';
import '../consumer/consumer_main_screen.dart';
import '../rider/rider_main_screen.dart';
import 'reset_password_screen.dart';
import 'user_type_selection_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToUserScreen(String userType) {
    Widget targetScreen;
    
    switch (userType) {
      case AppConstants.userTypeFarmer:
        targetScreen = const FarmerMainScreen();
        break;
      case AppConstants.userTypeCustomer:
        targetScreen = const ConsumerMainScreen();
        break;
      case AppConstants.userTypeRider:
        targetScreen = const RiderMainScreen();
        break;
      default:
        targetScreen = const UserTypeSelectionScreen();
    }
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (userCredential?.user != null && mounted) {
        // Get user profile to determine user type
        final userProfile = await _authService.getUserProfile(userCredential!.user!.uid);
        
        if (userProfile != null) {
          // Navigate to appropriate screen based on user type
          _navigateToUserScreen(userProfile.userType);
        } else {
          // User exists in Auth but not in Firestore - navigate to user type selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UserTypeSelectionScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential?.user != null && mounted) {
        final userProfile = await _authService.getUserProfile(userCredential!.user!.uid);
        
        if (userProfile == null) {
          // New user - navigate to user type selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const UserTypeSelectionScreen(),
            ),
          );
        } else {
          // Existing user - navigate to appropriate screen
          _navigateToUserScreen(userProfile.userType);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Logo and Welcome Text
                  const AppLogoWithText(
                    size: 100,
                    iconSize: 50,
                  ).animate().scale(delay: 200.ms, duration: 600.ms),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Welcome Text
                  Text(
                    'Sign in to Continue',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().slideX(delay: 800.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  Text(
                    'Sign in to continue your journey',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().slideX(delay: 900.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Email Field
                  CustomTextField(
                    label: 'Email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    isRequired: true,
                    prefixIcon: const Icon(Icons.email_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!EmailValidator.validate(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ).animate().slideX(delay: 1000.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  // Password Field
                  CustomTextField(
                    label: 'Password',
                    controller: _passwordController,
                    isPassword: true,
                    isRequired: true,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < AppConstants.minPasswordLength) {
                        return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                      }
                      return null;
                    },
                  ).animate().slideX(delay: 1100.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ResetPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 1200.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  // Sign In Button
                  CustomButton(
                    text: 'Sign In',
                    onPressed: _isLoading ? null : _signIn,
                    isLoading: _isLoading,
                  ).animate().slideY(delay: 1300.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                        child: Text(
                          'OR',
                          style: TextStyle(
                            color: AppConstants.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ).animate().fadeIn(delay: 1400.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  // Social Sign In Buttons
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildSocialButton(
                        icon: Icons.g_mobiledata,
                        label: 'Continue with Google',
                        onPressed: _isLoading ? null : _signInWithGoogle,
                      ),
                    ),
                  ).animate().slideY(delay: 1500.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingMedium),
                  
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppConstants.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserTypeSelectionScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1600.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return CustomButton(
      text: label,
      onPressed: onPressed,
      isOutlined: true,
      height: 50,
      icon: Icon(icon, color: AppConstants.primaryColor),
    );
  }
}
