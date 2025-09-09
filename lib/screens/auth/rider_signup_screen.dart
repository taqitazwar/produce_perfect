import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:email_validator/email_validator.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_logo.dart';
import '../../services/auth_service.dart';
import '../rider/rider_main_screen.dart';

class RiderSignUpScreen extends StatefulWidget {
  const RiderSignUpScreen({super.key});

  @override
  State<RiderSignUpScreen> createState() => _RiderSignUpScreenState();
}

class _RiderSignUpScreenState extends State<RiderSignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (userCredential?.user != null && mounted) {
        try {
          // Create rider profile
          await _authService.createUserProfile(
            uid: userCredential!.user!.uid,
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
            userType: AppConstants.userTypeRider,
            phoneNumber: _phoneController.text.trim().isEmpty 
                ? null 
                : _phoneController.text.trim(),
            additionalData: {
              'isAvailable': true,
              'totalDeliveries': 0,
              'totalEarnings': 0.0,
              'carbonSaved': 0.0,
              'vegetablesSaved': 0,
            },
          );

          // Navigate to rider main screen
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RiderMainScreen(),
              ),
            );
          }
        } catch (profileError) {
          // Profile creation failed, but user account was created
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RiderMainScreen(),
              ),
            );
          }
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Back Button and Logo
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios),
                        color: AppConstants.textPrimary,
                      ),
                      Expanded(
                        child: Center(
                          child: const AppLogo(
                            size: 80,
                            iconSize: 40,
                          ).animate().scale(delay: 200.ms, duration: 600.ms),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Title
                  Text(
                    'Join as a Rider',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().slideX(delay: 400.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  Text(
                    'Deliver produce and earn money while helping the environment',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().slideX(delay: 500.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingXLarge),
                  
                  // Name Field
                  CustomTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    isRequired: true,
                    prefixIcon: const Icon(Icons.person_outlined),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ).animate().slideX(delay: 600.ms, duration: 500.ms),
                  
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
                  ).animate().slideX(delay: 700.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Phone Field
                  CustomTextField(
                    label: 'Phone Number',
                    hint: 'Optional',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    validator: (value) {
                      if (value != null && value.isNotEmpty && value.length < 10) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ).animate().slideX(delay: 800.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Password Field
                  CustomTextField(
                    label: 'Password',
                    controller: _passwordController,
                    isPassword: true,
                    isRequired: true,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < AppConstants.minPasswordLength) {
                        return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                      }
                      return null;
                    },
                  ).animate().slideX(delay: 900.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Confirm Password Field
                  CustomTextField(
                    label: 'Confirm Password',
                    controller: _confirmPasswordController,
                    isPassword: true,
                    isRequired: true,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ).animate().slideX(delay: 1000.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                  
                  // Terms and Conditions Checkbox
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (value) {
                          setState(() {
                            _agreeToTerms = value ?? false;
                          });
                        },
                        activeColor: AppConstants.primaryColor,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: RichText(
                            text: TextSpan(
                              text: 'I agree to the ',
                              style: TextStyle(
                                color: AppConstants.textSecondary,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: const TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(
                                  text: ' and ',
                                  style: TextStyle(
                                    color: AppConstants.textSecondary,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 1100.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingXLarge),
                  
                  // Sign Up Button
                  CustomButton(
                    text: 'Create Rider Account',
                    onPressed: _isLoading ? null : _signUp,
                    isLoading: _isLoading,
                  ).animate().slideY(delay: 1200.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
