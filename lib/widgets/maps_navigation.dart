import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_constants.dart';
import '../services/maps_service.dart';
import '../widgets/custom_button.dart';

class MapsNavigation extends StatelessWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationName;
  final String? destinationAddress;
  final String? buttonText;
  final VoidCallback? onNavigationStarted;

  const MapsNavigation({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
    this.destinationAddress,
    this.buttonText,
    this.onNavigationStarted,
  });

  Future<void> _startNavigation(BuildContext context) async {
    try {
      final url = MapsService.generateNavigationUrl(
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        destinationName: destinationName,
      );

      final uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        onNavigationStarted?.call();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open Google Maps'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation error: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.navigation,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Navigate to Destination',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Destination details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destinationName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      destinationAddress ?? destinationName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Navigation button
          CustomButton(
            text: buttonText ?? 'Start Navigation',
            onPressed: () => _startNavigation(context),
          ),
        ],
      ),
    );
  }
}

class RiderNavigationScreen extends StatefulWidget {
  final String orderId;
  final String currentDestination; // 'farm' or 'customer'
  final double farmLat;
  final double farmLng;
  final String farmName;
  final String farmAddress;
  final double customerLat;
  final double customerLng;
  final String customerName;
  final String customerAddress;

  const RiderNavigationScreen({
    super.key,
    required this.orderId,
    required this.currentDestination,
    required this.farmLat,
    required this.farmLng,
    required this.farmName,
    required this.farmAddress,
    required this.customerLat,
    required this.customerLng,
    required this.customerName,
    required this.customerAddress,
  });

  @override
  State<RiderNavigationScreen> createState() => _RiderNavigationScreenState();
}

class _RiderNavigationScreenState extends State<RiderNavigationScreen> {
  late String _currentDestination;

  @override
  void initState() {
    super.initState();
    _currentDestination = widget.currentDestination;
  }

  Future<void> _markAsPickedUp() async {
    try {
      // Update order status to picked up
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'pickedUp',
        'pickedUpAt': DateTime.now().millisecondsSinceEpoch,
      });

      setState(() {
        _currentDestination = 'customer';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as picked up! Navigate to customer.'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _markAsDelivered() async {
    try {
      // Update order status to delivered
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update({
        'status': 'delivered',
        'deliveredAt': DateTime.now().millisecondsSinceEpoch,
        'actualDelivery': DateTime.now().millisecondsSinceEpoch,
      });

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order delivered successfully!'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update order: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGoingToFarm = _currentDestination == 'farm';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isGoingToFarm ? 'Pickup Order' : 'Deliver Order'),
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
          child: Column(
            children: [
              // Current step indicator
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                decoration: BoxDecoration(
                  color: isGoingToFarm ? Colors.orange : AppConstants.primaryColor,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                ),
                child: Column(
                  children: [
                    Icon(
                      isGoingToFarm ? Icons.agriculture : Icons.home,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isGoingToFarm ? 'Step 1: Pickup from Farm' : 'Step 2: Deliver to Customer',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isGoingToFarm ? 'Go to farmer location' : 'Deliver to customer',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Navigation widget
              MapsNavigation(
                destinationLat: isGoingToFarm ? widget.farmLat : widget.customerLat,
                destinationLng: isGoingToFarm ? widget.farmLng : widget.customerLng,
                destinationName: isGoingToFarm ? widget.farmName : widget.customerName,
                destinationAddress: isGoingToFarm ? widget.farmAddress : widget.customerAddress,
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Action button
              if (isGoingToFarm)
                CustomButton(
                  text: 'Mark as Picked Up',
                  onPressed: _markAsPickedUp,
                  backgroundColor: Colors.orange,
                )
              else
                CustomButton(
                  text: 'Mark as Delivered',
                  onPressed: _markAsDelivered,
                  backgroundColor: AppConstants.successColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
