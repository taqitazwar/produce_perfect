import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/app_constants.dart';
import '../../services/payment_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String customerName;
  final String customerEmail;
  final Function(bool success, String? paymentIntentId) onPaymentComplete;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    required this.onPaymentComplete,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isProcessing = false;
  String _cardType = '';

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.customerName;
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onCardNumberChanged(String value) {
    setState(() {
      _cardType = PaymentService.getCardType(value);
    });
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final result = await PaymentService.processPayment(
        amount: widget.amount,
        currency: 'USD',
        customerName: widget.customerName,
        customerEmail: widget.customerEmail,
        paymentMethod: 'card',
      );

      if (mounted) {
        if (result.success) {
          // Show success animation
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: AppConstants.successColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ).animate()
                   .scale(duration: 600.ms, curve: Curves.elasticOut),
                  
                  const SizedBox(height: 24),
                  
                  const Text(
                    'Payment Complete!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  const Text(
                    'Your order will be delivered within 24 hours',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppConstants.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  CustomButton(
                    text: 'Continue',
                    onPressed: () async {
                      Navigator.of(context).pop(); // Close dialog
                      
                      // Call the callback to process the order
                      await widget.onPaymentComplete(true, result.paymentIntentId);
                      
                      // Navigate back to home after order is processed
                      if (mounted) {
                        Navigator.of(context).pop(); // Close payment screen
                        Navigator.of(context).pop(); // Go back to home
                        
                        // Show success message on the home screen
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order placed successfully!'),
                            backgroundColor: AppConstants.successColor,
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: AppConstants.errorColor,
            ),
          );
          await widget.onPaymentComplete(false, null);
          
          // Navigate back on failure
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment failed: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
        await widget.onPaymentComplete(false, null);
        Navigator.of(context).pop();
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.backgroundGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Payment Amount Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    gradient: AppConstants.primaryGradient,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                    boxShadow: [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.payment,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(delay: 100.ms, duration: 600.ms),

                const SizedBox(height: AppConstants.paddingLarge),

                // Card Details Section
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
                      Row(
                        children: [
                          const Icon(
                            Icons.credit_card,
                            color: AppConstants.primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Card Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                          const Spacer(),
                          if (_cardType.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _cardType,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppConstants.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Card Number
                      TextFormField(
                        controller: _cardNumberController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(19),
                          _CardNumberInputFormatter(),
                        ],
                        onChanged: _onCardNumberChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter card number';
                          }
                          if (!PaymentService.validateCardNumber(value)) {
                            return 'Please enter a valid card number';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Card Number',
                          hintText: '1234 5678 9012 3456',
                          prefixIcon: const Icon(Icons.credit_card, color: AppConstants.primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                            borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      // Expiry and CVV Row
                      Row(
                        children: [
                          // Expiry Date
                          Expanded(
                            child: TextFormField(
                              controller: _expiryController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                                _ExpiryInputFormatter(),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter expiry date';
                                }
                                if (!PaymentService.validateExpiry(value)) {
                                  return 'Invalid expiry date';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Expiry Date',
                                hintText: 'MM/YY',
                                prefixIcon: const Icon(Icons.calendar_today, color: AppConstants.primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                  borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: AppConstants.paddingMedium),
                          
                          // CVV
                          Expanded(
                            child: TextFormField(
                              controller: _cvvController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter CVV';
                                }
                                if (!PaymentService.validateCVV(value, _cardNumberController.text)) {
                                  return 'Invalid CVV';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'CVV',
                                hintText: '123',
                                prefixIcon: const Icon(Icons.lock, color: AppConstants.primaryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                  borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      // Cardholder Name
                      TextFormField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter cardholder name';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Cardholder Name',
                          prefixIcon: const Icon(Icons.person, color: AppConstants.primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                            borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(delay: 200.ms, duration: 500.ms),

                const SizedBox(height: AppConstants.paddingLarge),

                // Demo Notice
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demo Mode: Use any card starting with 4, 5, or 3. No real payment will be processed.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: AppConstants.paddingLarge),

                // Pay Button
                CustomButton(
                  text: 'Pay with Card',
                  onPressed: _processPayment,
                  isLoading: _isProcessing,
                ).animate().slideY(delay: 400.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Custom input formatter for card numbers
class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < newText.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(newText[i]);
    }
    
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Custom input formatter for expiry date
class _ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    if (newText.length >= 2) {
      final month = newText.substring(0, 2);
      final year = newText.length > 2 ? newText.substring(2) : '';
      final formatted = year.isEmpty ? month : '$month/$year';
      
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
