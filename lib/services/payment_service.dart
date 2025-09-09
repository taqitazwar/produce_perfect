import 'dart:math';
import 'package:uuid/uuid.dart';

class PaymentService {
  static const _uuid = Uuid();

  // Demo payment processing
  static Future<PaymentResult> processPayment({
    required double amount,
    required String currency,
    required String customerName,
    required String customerEmail,
    String paymentMethod = 'card',
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // For demo purposes, randomly succeed or fail (95% success rate)
    final random = Random();
    final success = random.nextDouble() > 0.05; // 95% success rate

    if (success) {
      final paymentIntentId = 'pi_demo_${_uuid.v4().substring(0, 8)}';
      final transactionId = 'txn_${_uuid.v4().substring(0, 12)}';
      
      return PaymentResult(
        success: true,
        paymentIntentId: paymentIntentId,
        transactionId: transactionId,
        amount: amount,
        currency: currency,
        paymentMethod: paymentMethod,
        paidAt: DateTime.now(),
        message: 'Payment completed successfully!',
      );
    } else {
      return PaymentResult(
        success: false,
        message: 'Payment failed. Please try again.',
        errorCode: 'card_declined',
      );
    }
  }

  // Demo card validation
  static bool validateCardNumber(String cardNumber) {
    // Remove spaces and non-digits
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    // Check length (13-19 digits for most cards)
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      return false;
    }
    
    // Demo validation - accept any card starting with 4, 5, or 3
    return cleanNumber.startsWith('4') || // Visa
           cleanNumber.startsWith('5') || // Mastercard
           cleanNumber.startsWith('3');   // American Express
  }

  // Demo CVV validation
  static bool validateCVV(String cvv, String cardNumber) {
    final cleanCvv = cvv.replaceAll(RegExp(r'\D'), '');
    final cleanCardNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    // American Express uses 4-digit CVV
    if (cleanCardNumber.startsWith('3')) {
      return cleanCvv.length == 4;
    }
    
    // Most other cards use 3-digit CVV
    return cleanCvv.length == 3;
  }

  // Demo expiry validation
  static bool validateExpiry(String expiry) {
    final cleanExpiry = expiry.replaceAll(RegExp(r'\D'), '');
    
    if (cleanExpiry.length != 4) return false;
    
    final month = int.tryParse(cleanExpiry.substring(0, 2));
    final year = int.tryParse(cleanExpiry.substring(2, 4));
    
    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    
    // Check if card is not expired
    final now = DateTime.now();
    final currentYear = now.year % 100; // Get last 2 digits
    final currentMonth = now.month;
    
    if (year < currentYear) return false;
    if (year == currentYear && month < currentMonth) return false;
    
    return true;
  }

  // Format card number for display
  static String formatCardNumber(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    
    for (int i = 0; i < cleanNumber.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(cleanNumber[i]);
    }
    
    return buffer.toString();
  }

  // Format expiry date
  static String formatExpiry(String expiry) {
    final cleanExpiry = expiry.replaceAll(RegExp(r'\D'), '');
    
    if (cleanExpiry.length >= 2) {
      final month = cleanExpiry.substring(0, 2);
      final year = cleanExpiry.length > 2 ? cleanExpiry.substring(2) : '';
      return year.isEmpty ? month : '$month/$year';
    }
    
    return cleanExpiry;
  }

  // Get card type from number
  static String getCardType(String cardNumber) {
    final cleanNumber = cardNumber.replaceAll(RegExp(r'\D'), '');
    
    if (cleanNumber.startsWith('4')) return 'Visa';
    if (cleanNumber.startsWith('5')) return 'Mastercard';
    if (cleanNumber.startsWith('3')) return 'American Express';
    if (cleanNumber.startsWith('6')) return 'Discover';
    
    return 'Unknown';
  }
}

class PaymentResult {
  final bool success;
  final String? paymentIntentId;
  final String? transactionId;
  final double? amount;
  final String? currency;
  final String? paymentMethod;
  final DateTime? paidAt;
  final String message;
  final String? errorCode;

  PaymentResult({
    required this.success,
    this.paymentIntentId,
    this.transactionId,
    this.amount,
    this.currency,
    this.paymentMethod,
    this.paidAt,
    required this.message,
    this.errorCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'paymentIntentId': paymentIntentId,
      'transactionId': transactionId,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'paidAt': paidAt?.millisecondsSinceEpoch,
      'message': message,
      'errorCode': errorCode,
    };
  }

  factory PaymentResult.fromMap(Map<String, dynamic> map) {
    return PaymentResult(
      success: map['success'] ?? false,
      paymentIntentId: map['paymentIntentId'],
      transactionId: map['transactionId'],
      amount: map['amount']?.toDouble(),
      currency: map['currency'],
      paymentMethod: map['paymentMethod'],
      paidAt: map['paidAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['paidAt'])
          : null,
      message: map['message'] ?? '',
      errorCode: map['errorCode'],
    );
  }
}
