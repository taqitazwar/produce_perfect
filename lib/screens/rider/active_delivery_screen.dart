import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';
import '../../constants/app_constants.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../services/maps_service.dart';
import '../../widgets/custom_button.dart';

class ActiveDeliveryScreen extends StatefulWidget {
  final OrderModel order;
  
  const ActiveDeliveryScreen({
    super.key,
    required this.order,
  });

  @override
  State<ActiveDeliveryScreen> createState() => _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends State<ActiveDeliveryScreen> {
  final _orderService = OrderService();
  final _authService = AuthService();
  
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  LatLng? _currentLocation;
  LatLng? _destination;
  String _destinationName = '';
  String _destinationAddress = '';
  
  bool _isNavigating = false;
  String _deliveryPhase = 'pickup'; // 'pickup' or 'delivery'
  
  String _estimatedTime = 'Calculating...';
  String _distance = 'Calculating...';
  
  Timer? _locationTimer;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initializeDelivery();
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  void _initializeDelivery() async {
    // Determine current phase and get real locations
    if (widget.order.status == OrderStatus.confirmed) {
      _deliveryPhase = 'pickup';
      await _getFarmerLocation();
    } else if (widget.order.status == OrderStatus.pickedUp) {
      _deliveryPhase = 'delivery';
      await _getCustomerLocation();
    }
    
    _updateMapMarkers();
  }

  Future<void> _getFarmerLocation() async {
    try {
      final farmerProfile = await _authService.getUserProfile(widget.order.farmerId);
      
      if (farmerProfile != null) {
        print('Farmer profile found: ${farmerProfile.name}');
        print('Farm lat/lng: ${farmerProfile.farmLatitude}/${farmerProfile.farmLongitude}');
        print('General lat/lng: ${farmerProfile.latitude}/${farmerProfile.longitude}');
        print('Farm address: ${farmerProfile.farmAddress}');
        print('General address: ${farmerProfile.address}');
        
        // Try farm-specific location first
        if (farmerProfile.farmLatitude != null && farmerProfile.farmLongitude != null) {
          _destination = LatLng(farmerProfile.farmLatitude!, farmerProfile.farmLongitude!);
          _destinationAddress = farmerProfile.farmAddress ?? 'Farm Location';
          print('Using farm-specific location');
        }
        // Fallback to general location
        else if (farmerProfile.latitude != null && farmerProfile.longitude != null) {
          _destination = LatLng(farmerProfile.latitude!, farmerProfile.longitude!);
          _destinationAddress = farmerProfile.address ?? 'Farm Location';
          print('Using general location');
        }
        // Last resort: use order data
        else {
          if (widget.order.farmLatitude != null && widget.order.farmLongitude != null) {
            _destination = LatLng(widget.order.farmLatitude!, widget.order.farmLongitude!);
            _destinationAddress = widget.order.farmLocation ?? 'Farm Location';
            print('Using order farm coordinates');
          } else {
            // If no coordinates available, show error instead of defaulting to St. John's
            print('No farm coordinates available in order data');
            _destination = null;
            _destinationAddress = 'Location not available';
          }
        }
      } else {
        // Farmer profile not found, use order data
        if (widget.order.farmLatitude != null && widget.order.farmLongitude != null) {
          _destination = LatLng(widget.order.farmLatitude!, widget.order.farmLongitude!);
          _destinationAddress = widget.order.farmLocation ?? 'Farm Location';
          print('Using order farm coordinates (profile not found)');
        } else {
          print('No farm coordinates available in order data');
          _destination = null;
          _destinationAddress = 'Location not available';
        }
      }
      
      _destinationName = widget.order.farmerName;
      print('Farmer location: ${_destination?.latitude}, ${_destination?.longitude}');
      print('Farmer address: $_destinationAddress');
      
      // Update UI after getting farmer location
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {
      print('Error fetching farmer location: $e');
      // Fallback to order data
      _destination = LatLng(
        widget.order.farmLatitude ?? 47.5615,
        widget.order.farmLongitude ?? -52.7126,
      );
      _destinationName = widget.order.farmerName;
      _destinationAddress = widget.order.farmLocation ?? 'Farm Location';
      
      // Update UI after fallback
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _getCustomerLocation() async {
    try {
      final customerProfile = await _authService.getUserProfile(widget.order.customerId);
      
      if (customerProfile != null) {
        print('Customer profile found: ${customerProfile.name}');
        print('Customer lat/lng: ${customerProfile.latitude}/${customerProfile.longitude}');
        print('Customer address: ${customerProfile.address}');
        
        if (customerProfile.latitude != null && customerProfile.longitude != null) {
          _destination = LatLng(customerProfile.latitude!, customerProfile.longitude!);
          _destinationAddress = customerProfile.address ?? widget.order.deliveryAddress;
          print('Using customer profile location');
        } else {
          // Use order delivery data
          if (widget.order.deliveryLatitude != null && widget.order.deliveryLongitude != null) {
            _destination = LatLng(widget.order.deliveryLatitude!, widget.order.deliveryLongitude!);
            _destinationAddress = widget.order.deliveryAddress;
            print('Using order delivery coordinates');
          } else {
            print('No delivery coordinates available in order data');
            _destination = null;
            _destinationAddress = 'Location not available';
          }
        }
      } else {
        // Use order delivery data
        if (widget.order.deliveryLatitude != null && widget.order.deliveryLongitude != null) {
          _destination = LatLng(widget.order.deliveryLatitude!, widget.order.deliveryLongitude!);
          _destinationAddress = widget.order.deliveryAddress;
          print('Using order delivery coordinates (profile not found)');
        } else {
          print('No delivery coordinates available in order data');
          _destination = null;
          _destinationAddress = 'Location not available';
        }
      }
      
      _destinationName = widget.order.customerName;
      print('Customer location: ${_destination?.latitude}, ${_destination?.longitude}');
      print('Customer address: $_destinationAddress');
      
      // Update UI after getting customer location
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {
      print('Error fetching customer location: $e');
      // Fallback to order data
      if (widget.order.deliveryLatitude != null && widget.order.deliveryLongitude != null) {
        _destination = LatLng(widget.order.deliveryLatitude!, widget.order.deliveryLongitude!);
        _destinationName = widget.order.customerName;
        _destinationAddress = widget.order.deliveryAddress;
        print('Using order delivery coordinates (error fallback)');
      } else {
        print('No delivery coordinates available in order data');
        _destination = null;
        _destinationName = widget.order.customerName;
        _destinationAddress = 'Location not available';
      }
      
      // Update UI after fallback
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _startLocationTracking() {
    // Get current location every 10 seconds
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _getCurrentLocation();
    });
    
    // Get initial location
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
        
        _updateMapMarkers();
        _calculateRouteInfo();
        
        // Update rider location in Firebase
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
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _updateMapMarkers() {
    Set<Marker> markers = {};
    
    // Current location marker (rider)
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }
    
    // Destination marker
    if (_destination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _deliveryPhase == 'pickup' 
              ? BitmapDescriptor.hueGreen 
              : BitmapDescriptor.hueRed
          ),
          infoWindow: InfoWindow(
            title: _destinationName,
            snippet: _destinationAddress,
          ),
        ),
      );
    }
    
    setState(() {
      _markers = markers;
    });
  }

  void _calculateRouteInfo() async {
    if (_currentLocation != null && _destination != null) {
      print('Calculating route from: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}');
      print('To destination: ${_destination!.latitude}, ${_destination!.longitude}');
      
      try {
        // Use Google Maps Directions API for accurate routing
        final directions = await MapsService.getDirections(
          fromLat: _currentLocation!.latitude,
          fromLng: _currentLocation!.longitude,
          toLat: _destination!.latitude,
          toLng: _destination!.longitude,
        );
        
        if (directions != null && directions.success) {
          print('Got directions from Google Maps API');
          print('Distance: ${directions.distanceText}');
          print('Duration: ${directions.durationText}');
          
          setState(() {
            _distance = directions.distanceText;
            _estimatedTime = directions.durationText;
          });
          
          // Update polylines with actual route
          _updatePolylines(directions.polylinePoints);
        } else {
          // Fallback to straight-line distance if API fails
          print('Directions API failed, using fallback calculation');
          _calculateFallbackRoute();
        }
      } catch (e) {
        print('Error getting directions: $e');
        _calculateFallbackRoute();
      }
      
      // Update map camera to show both locations
      _updateMapCamera();
    } else if (_destination == null) {
      // Handle case where destination is not available
      setState(() {
        _distance = 'Location not available';
        _estimatedTime = 'N/A';
      });
      print('Cannot calculate route: destination not available');
    }
  }

  void _calculateFallbackRoute() {
    // Simple distance calculation (straight line distance) as fallback
    double distanceInMeters = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      _destination!.latitude,
      _destination!.longitude,
    );
    
    double distanceInKm = distanceInMeters / 1000;
    // More realistic ETA: 2 minutes per km for city driving
    int estimatedMinutes = (distanceInKm * 2).round();
    
    print('Fallback Distance: ${distanceInKm.toStringAsFixed(1)} km');
    print('Fallback ETA: ${estimatedMinutes} min');
    
    setState(() {
      _distance = '${distanceInKm.toStringAsFixed(1)} km';
      _estimatedTime = '${estimatedMinutes} min';
    });
  }

  void _updatePolylines(List<LatLng> polylinePoints) {
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylinePoints,
          color: AppConstants.primaryColor,
          width: 4,
          patterns: [],
        ),
      };
    });
  }

  void _updateMapCamera() {
    if (_mapController != null && _currentLocation != null && _destination != null) {
      // Calculate bounds to include both locations
      double minLat = _currentLocation!.latitude < _destination!.latitude 
          ? _currentLocation!.latitude 
          : _destination!.latitude;
      double maxLat = _currentLocation!.latitude > _destination!.latitude 
          ? _currentLocation!.latitude 
          : _destination!.latitude;
      double minLng = _currentLocation!.longitude < _destination!.longitude 
          ? _currentLocation!.longitude 
          : _destination!.longitude;
      double maxLng = _currentLocation!.longitude > _destination!.longitude 
          ? _currentLocation!.longitude 
          : _destination!.longitude;
      
      // Add padding
      double latPadding = (maxLat - minLat) * 0.1;
      double lngPadding = (maxLng - minLng) * 0.1;
      
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat - latPadding, minLng - lngPadding),
        northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
      );
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
      
      print('Map camera updated to show both locations');
    }
  }

  Future<void> _markAsPickedUp() async {
    try {
      setState(() => _isNavigating = true);
      
      await _orderService.updateOrderStatus(widget.order.id, OrderStatus.pickedUp);
      
      // Switch to delivery phase
      setState(() {
        _deliveryPhase = 'delivery';
        _isNavigating = false;
      });
      
      // Get real customer location
      await _getCustomerLocation();
      
      _updateMapMarkers();
      _calculateRouteInfo();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order picked up! Navigate to customer'),
            backgroundColor: AppConstants.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isNavigating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _markAsDelivered() async {
    try {
      setState(() => _isNavigating = true);
      
      await _orderService.updateOrderStatus(widget.order.id, OrderStatus.delivered);
      
      if (mounted) {
        // Show success dialog
        showDialog(
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
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Delivery Complete!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'You earned \$${(widget.order.deliveryFee * 0.7).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                CustomButton(
                  text: 'Back to Orders',
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to orders
                  },
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isNavigating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _deliveryPhase == 'pickup' ? 'Pickup Order' : 'Deliver Order',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppConstants.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Map section
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: GoogleMap(
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: _destination ?? const LatLng(47.5615, -52.7126),
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
              ),
            ),
          ),
          
          // Route info section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoCard(
                  icon: Icons.access_time,
                  label: 'ETA',
                  value: _estimatedTime,
                  color: AppConstants.primaryColor,
                ),
                _buildInfoCard(
                  icon: Icons.straighten,
                  label: 'Distance',
                  value: _distance,
                  color: AppConstants.successColor,
                ),
                _buildInfoCard(
                  icon: Icons.local_shipping,
                  label: 'Phase',
                  value: _deliveryPhase == 'pickup' ? 'Pickup' : 'Delivery',
                  color: AppConstants.warningColor,
                ),
              ],
            ),
          ),
          
          // Destination info and action section
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: AppConstants.backgroundGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Destination info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: (_deliveryPhase == 'pickup' 
                              ? AppConstants.successColor 
                              : AppConstants.primaryColor).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _deliveryPhase == 'pickup' 
                              ? Icons.store 
                              : Icons.home,
                            color: _deliveryPhase == 'pickup' 
                              ? AppConstants.successColor 
                              : AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _deliveryPhase == 'pickup' 
                                  ? 'Pick up from:' 
                                  : 'Deliver to:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppConstants.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _destinationName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _destinationAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppConstants.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(duration: 500.ms),
                  
                  const SizedBox(height: 20),
                  
                  // Action button
                  CustomButton(
                    text: _deliveryPhase == 'pickup' 
                      ? 'Items Picked Up' 
                      : 'Order Delivered',
                    onPressed: _deliveryPhase == 'pickup' 
                      ? _markAsPickedUp 
                      : _markAsDelivered,
                    isLoading: _isNavigating,
                    backgroundColor: _deliveryPhase == 'pickup' 
                      ? AppConstants.primaryColor 
                      : AppConstants.successColor,
                  ).animate().slideY(delay: 200.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
