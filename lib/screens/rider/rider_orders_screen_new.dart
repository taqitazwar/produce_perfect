import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants/app_constants.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../models/order_model.dart';
import '../../models/product_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/maps_navigation.dart';

class RiderOrdersScreen extends StatefulWidget {
  const RiderOrdersScreen({super.key});

  @override
  State<RiderOrdersScreen> createState() => _RiderOrdersScreenState();
}

class _RiderOrdersScreenState extends State<RiderOrdersScreen> {
  final _orderService = OrderService();
  final _authService = AuthService();
  final _productService = ProductService();
  List<OrderModel> _availableOrders = [];
  List<ProductModel> _availableProducts = [];
  bool _isLoading = true;
  
  // Stream subscription for real-time updates
  Stream<List<OrderModel>>? _ordersStream;
  
  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  // Default location (you can change this to your city center)
  static const LatLng _defaultLocation = LatLng(40.7128, -74.0060); // NYC

  @override
  void initState() {
    super.initState();
    _setupRealTimeOrders();
    _loadFarmLocations();
  }

  void _setupRealTimeOrders() {
    setState(() => _isLoading = true);
    
    // Set up real-time stream for available orders
    _ordersStream = _orderService.streamAvailableOrdersForRiders();
    
    _ordersStream!.listen(
      (orders) {
        if (mounted) {
          setState(() {
            _availableOrders = orders;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading orders: $error'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
      },
    );
  }
  
  Future<void> _loadFarmLocations() async {
    try {
      final products = await _productService.getAllProducts();
      setState(() {
        _availableProducts = products;
      });
      _createFarmMarkers();
    } catch (e) {
      print('Failed to load farm locations: $e');
    }
  }
  
  void _createFarmMarkers() {
    final markers = <Marker>{};
    final addedFarms = <String>{};
    
    for (final product in _availableProducts) {
      final farmKey = '${product.farmerId}_${product.farmLocation}';
      if (!addedFarms.contains(farmKey)) {
        // Create marker for farm (using mock coordinates for demo)
        final farmLatLng = _getMockFarmLocation(product.farmerId);
        markers.add(
          Marker(
            markerId: MarkerId(product.farmerId),
            position: farmLatLng,
            infoWindow: InfoWindow(
              title: product.farmerName,
              snippet: '${product.title} - \$${product.price.toStringAsFixed(2)}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
        addedFarms.add(farmKey);
      }
    }
    
    setState(() {
      _markers = markers;
    });
  }
  
  LatLng _getMockFarmLocation(String farmerId) {
    // Generate mock coordinates around the default location
    final hash = farmerId.hashCode;
    final latOffset = (hash % 100 - 50) / 1000.0;
    final lngOffset = ((hash ~/ 100) % 100 - 50) / 1000.0;
    
    return LatLng(
      _defaultLocation.latitude + latOffset,
      _defaultLocation.longitude + lngOffset,
    );
  }

  Future<void> _acceptOrder(OrderModel order) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      await _orderService.acceptOrder(order.id, user.uid);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order accepted! Navigate to ${order.farmerName}'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept order: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _markAsPickedUp(OrderModel order) async {
    try {
      await _orderService.updateOrderStatus(order.id, OrderStatus.pickedUp);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order picked up! Navigate to customer'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _markAsDelivered(OrderModel order) async {
    try {
      await _orderService.updateOrderStatus(order.id, OrderStatus.delivered);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order delivered! You earned \$${order.deliveryFee.toStringAsFixed(2)}'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update order: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Available Orders',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Map section showing farm locations
          Container(
            height: 300,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                },
                initialCameraPosition: const CameraPosition(
                  target: _defaultLocation,
                  zoom: 12.0,
                ),
                markers: _markers,
                mapType: MapType.normal,
                zoomControlsEnabled: true,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
              ),
            ),
          ),
          
          // Orders list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.list_alt,
                  color: AppConstants.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Available Orders',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_availableOrders.length} orders',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Orders list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _availableOrders.isEmpty
                    ? _buildEmptyState()
                    : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delivery_dining,
            size: 80,
            color: AppConstants.textSecondary,
          ).animate().scale(duration: 600.ms),
          const SizedBox(height: 20),
          Text(
            'No Available Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppConstants.textPrimary,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Orders will appear here when customers place them',
            style: TextStyle(
              fontSize: 16,
              color: AppConstants.textSecondary,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _availableOrders.length,
      itemBuilder: (context, index) {
        final order = _availableOrders[index];
        return _buildOrderCard(order).animate().slideX(
          delay: Duration(milliseconds: index * 100),
          duration: 500.ms,
        );
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.farmerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${order.deliveryFee.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Distance and delivery info
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppConstants.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${order.distanceKm?.toStringAsFixed(1) ?? 'N/A'} km',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: AppConstants.textSecondary),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(order.orderDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppConstants.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Items summary
            Text(
              '${order.items.length} items • \$${order.total.toStringAsFixed(2)} total',
              style: TextStyle(
                fontSize: 14,
                color: AppConstants.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Action buttons based on order status
            if (order.status == OrderStatus.pending) ...[
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Accept Order',
                      onPressed: () => _acceptOrder(order),
                      backgroundColor: AppConstants.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MapsNavigation(
                      destinationLat: order.farmLatitude ?? _defaultLocation.latitude,
                      destinationLng: order.farmLongitude ?? _defaultLocation.longitude,
                      destinationName: order.farmerName,
                      buttonText: 'Get Directions',
                    ),
                  ),
                ],
              ),
            ] else if (order.status == OrderStatus.confirmed) ...[
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Picked Up',
                          onPressed: () => _markAsPickedUp(order),
                          backgroundColor: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MapsNavigation(
                          destinationLat: order.farmLatitude ?? _defaultLocation.latitude,
                          destinationLng: order.farmLongitude ?? _defaultLocation.longitude,
                          destinationName: order.farmerName,
                          buttonText: 'To Farm',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ] else if (order.status == OrderStatus.pickedUp) ...[
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Delivered',
                          onPressed: () => _markAsDelivered(order),
                          backgroundColor: AppConstants.successColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MapsNavigation(
                          destinationLat: order.deliveryLatitude ?? _defaultLocation.latitude,
                          destinationLng: order.deliveryLongitude ?? _defaultLocation.longitude,
                          destinationName: 'Customer',
                          buttonText: 'To Customer',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
