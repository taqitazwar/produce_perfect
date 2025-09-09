import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../constants/app_constants.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
// Removed product service import - now using order-based real locations
import '../../models/order_model.dart';
// Removed product model import - now using order-based real locations
import '../../widgets/custom_button.dart';
// Removed maps_navigation import - using in-app navigation now
import 'active_delivery_screen.dart';

class RiderOrdersScreen extends StatefulWidget {
  const RiderOrdersScreen({super.key});

  @override
  State<RiderOrdersScreen> createState() => _RiderOrdersScreenState();
}

class _RiderOrdersScreenState extends State<RiderOrdersScreen> {
  final _orderService = OrderService();
  final _authService = AuthService();
  // Removed product service and product list - now using order-based real locations
  List<OrderModel> _availableOrders = [];
  bool _isLoading = true;
  
  // Stream subscription for real-time updates
  Stream<List<OrderModel>>? _ordersStream;
  
  // Google Maps
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  // Location
  LatLng _currentLocation = const LatLng(47.5615, -52.7126); // Default to St. John's, NL
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  // Safe initialization method
  Future<void> _initializeScreen() async {
    try {
      // Initialize real-time orders first (doesn't require location)
      _setupRealTimeOrders();
      
      // Then request location permission (this might take time or fail)
      await _requestLocationPermission();
    } catch (e) {
      print('Error initializing rider screen: $e');
      // Even if location fails, the screen should still work
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setupRealTimeOrders() {
    setState(() => _isLoading = true);
    
    // Debug: Check all orders in database
    _orderService.debugAllOrders();
    
    // Set up real-time stream for available orders
    _ordersStream = _orderService.streamAvailableOrdersForRiders();
    
    _ordersStream!.listen(
      (orders) {
        print('Rider received ${orders.length} orders');
        for (var order in orders) {
          print('Order ${order.id}: status=${order.status}, riderId=${order.riderId}');
        }
        if (mounted) {
          setState(() {
            _availableOrders = orders;
            _isLoading = false;
          });
          // Update map markers asynchronously to avoid blocking UI
          Future.microtask(() => _updateMapMarkers());
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
  
  // Build Google Map widget with error handling
  Widget _buildMapWidget() {
    try {
      return GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          try {
            _mapController = controller;
          } catch (e) {
            print('Error setting map controller: $e');
          }
        },
        initialCameraPosition: CameraPosition(
          target: _currentLocation,
          zoom: 12.0,
        ),
        markers: _markers,
        mapType: MapType.normal,
        zoomControlsEnabled: true,
        myLocationButtonEnabled: _locationPermissionGranted,
        myLocationEnabled: _locationPermissionGranted,
      );
    } catch (e) {
      print('Error building map widget: $e');
      // Return a fallback widget if map fails to load
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Map unavailable',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  // Removed old product-based farm location methods - now using real farmer profiles from orders
  
  // Removed mock farm location generation - now using real farmer profiles

  Future<void> _acceptOrder(OrderModel order) async {
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      await _orderService.acceptOrder(order.id, user.uid);
      
      if (mounted) {
        // Navigate to active delivery screen (use push so rider can go back to see other orders)
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ActiveDeliveryScreen(
              order: order.copyWith(
                riderId: user.uid,
                status: OrderStatus.confirmed,
              ),
            ),
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

  // Update map markers with real farmer locations
  Future<void> _updateMapMarkers() async {
    if (!mounted) return;
    
    Set<Marker> markers = {};
    
    // Process orders in batches to avoid overwhelming the system
    for (var order in _availableOrders) {
      try {
        LatLng? farmerLocation;
        
        // First try to use order data if available (faster)
        if (order.farmLatitude != null && order.farmLongitude != null) {
          farmerLocation = LatLng(order.farmLatitude!, order.farmLongitude!);
        } else {
          // Only fetch profile if order doesn't have location data
          try {
            final farmerProfile = await _authService.getUserProfile(order.farmerId);
            
            if (farmerProfile != null) {
              // Try farm-specific location first
              if (farmerProfile.farmLatitude != null && farmerProfile.farmLongitude != null) {
                farmerLocation = LatLng(farmerProfile.farmLatitude!, farmerProfile.farmLongitude!);
              }
              // Fallback to general location
              else if (farmerProfile.latitude != null && farmerProfile.longitude != null) {
                farmerLocation = LatLng(farmerProfile.latitude!, farmerProfile.longitude!);
              }
            }
          } catch (profileError) {
            print('Error fetching farmer profile for ${order.farmerName}: $profileError');
            // Continue with other orders even if this one fails
          }
        }
        
        if (farmerLocation != null) {
          markers.add(
            Marker(
              markerId: MarkerId('farm_${order.id}'),
              position: farmerLocation,
              infoWindow: InfoWindow(
                title: order.farmerName,
                snippet: '\$${order.total.toStringAsFixed(2)} • ${order.items.length} items',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          );
        }
      } catch (e) {
        print('Error processing order ${order.id}: $e');
        // Continue with other orders
      }
    }
    
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  // Request location permission and get current location
  Future<void> _requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them in settings.'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied. Cannot show nearby orders.'),
                backgroundColor: AppConstants.errorColor,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied. Please enable them in app settings.'),
              backgroundColor: AppConstants.errorColor,
            ),
          );
        }
        return;
      }

      // Get current location
      setState(() => _locationPermissionGranted = true);
      await _getCurrentLocation();
    } catch (e) {
      print('Error requesting location permission: $e');
    }
  }

  // Get rider's current location
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        
        // Update rider's current location in their profile
        final user = _authService.currentUser;
        if (user != null) {
          await _authService.updateUserProfile(
            uid: user.uid,
            data: {
              'currentLatitude': position.latitude,
              'currentLongitude': position.longitude,
              'lastLocationUpdate': DateTime.now().millisecondsSinceEpoch,
            },
          );
        }
        
        // Update map camera to rider's location
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentLocation),
        );
      }
    } catch (e) {
      print('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
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
              child: _buildMapWidget(),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.farmerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${order.items.length} items • ${order.distanceKm?.toStringAsFixed(1) ?? 'N/A'} km',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Earn \$${(order.deliveryFee * 0.7).toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Order items preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items to deliver:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...order.items.take(2).map((item) => Text(
                    '• ${item.productTitle} (${item.quantity}${item.unit})',
                    style: const TextStyle(fontSize: 14),
                  )),
                  if (order.items.length > 2)
                    Text(
                      '• +${order.items.length - 2} more items',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppConstants.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Status-based actions
            _buildOrderActions(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderActions(OrderModel order) {
    final user = _authService.currentUser;
    
    // Available order (no rider assigned)
    if (order.riderId == null || order.riderId!.isEmpty) {
      return CustomButton(
        text: 'Accept Order',
        onPressed: () => _acceptOrder(order),
      );
    }
    
    // Order assigned to current rider
    if (order.riderId == user?.uid) {
      if (order.status == OrderStatus.confirmed) {
        // Accepted but not picked up
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.successColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppConstants.successColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your Order - Navigate to farm for pickup',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.successColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Go to Active Delivery',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ActiveDeliveryScreen(order: order),
                  ),
                );
              },
            ),
          ],
        );
      } else if (order.status == OrderStatus.pickedUp || order.status == OrderStatus.inTransit) {
        // Picked up, ready for delivery
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_shipping, color: AppConstants.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your Order - Navigate to customer for delivery',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Go to Active Delivery',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ActiveDeliveryScreen(order: order),
                  ),
                );
              },
            ),
          ],
        );
      }
    }
    
    // Order assigned to another rider - show as informational
    if (order.riderId != null && order.riderId!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.person, color: Colors.grey[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Assigned to another rider',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Fallback - shouldn't normally reach here
    return const SizedBox.shrink();
  }
}
