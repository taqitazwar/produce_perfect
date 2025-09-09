import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:email_validator/email_validator.dart';
import '../../constants/app_constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/app_logo.dart';
import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(_emailController.text.trim());
      
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  void _resendEmail() {
    setState(() {
      _emailSent = false;
    });
    _resetPassword();
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
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
                
                const SizedBox(height: AppConstants.paddingXLarge),
                
                if (!_emailSent) ...[
                  // Reset Password Form
                  Text(
                    'Reset Password',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().slideX(delay: 400.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingSmall),
                  
                  Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().slideX(delay: 500.ms, duration: 500.ms),
                  
                  const SizedBox(height: AppConstants.paddingXLarge),
                  
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
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
                        ).animate().slideX(delay: 600.ms, duration: 500.ms),
                        
                        const SizedBox(height: AppConstants.paddingXLarge),
                        
                        CustomButton(
                          text: 'Send Reset Link',
                          onPressed: _isLoading ? null : _resetPassword,
                          isLoading: _isLoading,
                        ).animate().slideY(delay: 700.ms, duration: 500.ms),
                      ],
                    ),
                  ),
                ] else ...[
                  // Email Sent Confirmation
                  Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppConstants.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusXLarge),
                          border: Border.all(
                            color: AppConstants.successColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.mark_email_read,
                          size: 60,
                          color: AppConstants.successColor,
                        ),
                      ).animate().scale(delay: 200.ms, duration: 600.ms),
                      
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      Text(
                        'Check Your Email',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().slideX(delay: 400.ms, duration: 500.ms),
                      
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: 'We\'ve sent a password reset link to\n',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppConstants.textSecondary,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: _emailController.text.trim(),
                              style: const TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideX(delay: 500.ms, duration: 500.ms),
                      
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                          border: Border.all(
                            color: Colors.blue[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                                const SizedBox(width: AppConstants.paddingSmall),
                                Expanded(
                                  child: Text(
                                    'What to do next:',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            _buildInstructionStep(
                              '1',
                              'Check your email inbox (and spam folder)',
                            ),
                            _buildInstructionStep(
                              '2',
                              'Click the reset link in the email',
                            ),
                            _buildInstructionStep(
                              '3',
                              'Create a new password',
                            ),
                            _buildInstructionStep(
                              '4',
                              'Sign in with your new password',
                            ),
                          ],
                        ),
                      ).animate().slideY(delay: 600.ms, duration: 500.ms),
                      
                      const SizedBox(height: AppConstants.paddingXLarge),
                      
                      Text(
                        'Didn\'t receive the email?',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppConstants.textSecondary,
                        ),
                      ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
                      
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      CustomButton(
                        text: 'Resend Email',
                        onPressed: _resendEmail,
                        isOutlined: true,
                      ).animate().slideY(delay: 800.ms, duration: 500.ms),
                    ],
                  ),
                ],
                
                const SizedBox(height: AppConstants.paddingXLarge),
                
                // Back to Sign In
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Back to Sign In',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ).animate().fadeIn(delay: _emailSent ? 900.ms : 800.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
