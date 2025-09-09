import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../models/order_model.dart';

class RiderEarningsScreen extends StatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  State<RiderEarningsScreen> createState() => _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends State<RiderEarningsScreen> {
  final _orderService = OrderService();
  final _authService = AuthService();
  List<OrderModel> _completedOrders = [];
  Map<String, dynamic> _earningsData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEarningsData();
  }

  Future<void> _loadEarningsData() async {
    try {
      setState(() => _isLoading = true);
      final user = _authService.currentUser;
      if (user != null) {
        final orders = await _orderService.getOrdersByRider(user.uid);
        final completedOrders = orders.where((order) => 
            order.status == OrderStatus.delivered).toList();
        final earnings = await _orderService.getRiderEarnings(user.uid);
        
        setState(() {
          _completedOrders = completedOrders;
          _earningsData = earnings;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load earnings: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Impact'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEarningsData,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppConstants.backgroundGradient,
        ),
        child: RefreshIndicator(
          onRefresh: _loadEarningsData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              children: [
                // Earnings Overview
                Container(
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
                        Icons.account_balance_wallet,
                        size: 50,
                        color: Colors.white,
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      const Text(
                        'Total Earnings',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${(_earningsData['totalEarnings'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildEarningsStat(
                            '${_earningsData['totalDeliveries'] ?? 0}',
                            'Deliveries',
                          ),
                          _buildEarningsStat(
                            '\$${(_earningsData['avgEarningsPerDelivery'] ?? 0.0).toStringAsFixed(2)}',
                            'Per Delivery',
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().scale(delay: 100.ms, duration: 600.ms),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Environmental Impact
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
                      const Row(
                        children: [
                          Icon(
                            Icons.eco,
                            color: AppConstants.primaryColor,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Your Environmental Impact',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Impact Stats Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        childAspectRatio: 1.3,
                        crossAxisSpacing: AppConstants.paddingMedium,
                        mainAxisSpacing: AppConstants.paddingMedium,
                        children: [
                          _buildImpactCard(
                            '🌍',
                            'Carbon Saved',
                            '${(_earningsData['carbonSaved'] ?? 0.0).toStringAsFixed(1)} kg CO₂',
                            Colors.blue,
                          ),
                          _buildImpactCard(
                            '🥬',
                            'Food Saved',
                            '${(_earningsData['vegetablesSaved'] ?? 0.0).toStringAsFixed(1)} kg',
                            Colors.green,
                          ),
                          _buildImpactCard(
                            '',
                            'Deliveries',
                            '${_earningsData['totalDeliveries'] ?? 0}',
                            AppConstants.primaryColor,
                          ),
                          _buildImpactCard(
                            '⭐',
                            'Impact Score',
                            '${((_earningsData['carbonSaved'] ?? 0.0) + (_earningsData['vegetablesSaved'] ?? 0.0)).toStringAsFixed(0)}',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().slideY(delay: 200.ms, duration: 500.ms),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Recent Deliveries
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
                      const Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: AppConstants.primaryColor,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Recent Deliveries',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      if (_completedOrders.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppConstants.paddingLarge),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.delivery_dining,
                                  size: 60,
                                  color: AppConstants.textSecondary,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No deliveries completed yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppConstants.textSecondary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Start accepting orders to see your delivery history!',
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
                          itemCount: _completedOrders.take(5).length,
                          itemBuilder: (context, index) {
                            final order = _completedOrders[index];
                            return _buildDeliveryItem(order, index);
                          },
                        ),
                      
                      if (_completedOrders.length > 5)
                        Padding(
                          padding: const EdgeInsets.only(top: AppConstants.paddingMedium),
                          child: Center(
                            child: TextButton(
                              onPressed: () {
                                // Navigate to full delivery history
                              },
                              child: Text(
                                'View All ${_completedOrders.length} Deliveries',
                                style: const TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate().slideY(delay: 300.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEarningsStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildImpactCard(String emoji, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryItem(OrderModel order, int index) {
    final dateFormat = DateFormat('MMM dd, h:mm a');
    final earnings = order.deliveryFee * 0.7; // 70% goes to rider
    
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
              color: AppConstants.successColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check,
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
                  'Delivered to ${order.customerName}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  order.actualDelivery != null 
                      ? dateFormat.format(order.actualDelivery!)
                      : 'Recently completed',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          // Earnings
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${earnings.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              const Text(
                'earned',
                style: TextStyle(
                  fontSize: 10,
                  color: AppConstants.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 50))
     .slideX(duration: 300.ms);
  }
}
