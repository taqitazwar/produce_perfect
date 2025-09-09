import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../constants/app_constants.dart';
import '../services/maps_service.dart';
import 'custom_text_field.dart';

class AddressPicker extends StatefulWidget {
  final String label;
  final String? initialValue;
  final Function(AddressResult) onAddressSelected;
  final bool isRequired;

  const AddressPicker({
    super.key,
    required this.label,
    this.initialValue,
    required this.onAddressSelected,
    this.isRequired = false,
  });

  @override
  State<AddressPicker> createState() => _AddressPickerState();
}

class _AddressPickerState extends State<AddressPicker> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onPlaceSelected(Prediction prediction) async {
    setState(() => _isLoading = true);
    
    try {
      final placeDetails = await MapsService.getPlaceDetails(prediction.placeId!);
      
      if (placeDetails != null) {
        // Preserve cursor position
        final cursorPosition = _controller.selection.baseOffset;
        _controller.text = placeDetails.address;
        
        // Restore cursor position at the end
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: placeDetails.address.length),
        );
        
        final addressResult = AddressResult(
          address: placeDetails.address,
          name: placeDetails.name,
          latitude: placeDetails.latitude,
          longitude: placeDetails.longitude,
          placeId: prediction.placeId!,
        );
        
        widget.onAddressSelected(addressResult);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get address details: $e'),
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
    return GooglePlaceAutoCompleteTextField(
      textEditingController: _controller,
      focusNode: _focusNode,
      googleAPIKey: "AIzaSyDW7fSRAERAoO91N3-nyeKrrBBWEwYkR4Q",
      inputDecoration: InputDecoration(
        labelText: widget.label + (widget.isRequired ? ' *' : ''),
        hintText: 'Enter ${widget.label.toLowerCase()}',
        hintStyle: TextStyle(
          color: AppConstants.textLight,
          fontSize: 16,
        ),
        prefixIcon: _isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(
                Icons.location_on,
                color: AppConstants.primaryColor,
              ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      debounceTime: 800,
      countries: const ["us", "ca"],
      isLatLngRequired: true,
      getPlaceDetailWithLatLng: _onPlaceSelected,
      itemClick: _onPlaceSelected,
      itemBuilder: (context, index, prediction) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prediction.structuredFormatting?.mainText ?? prediction.description ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.textPrimary,
                      ),
                    ),
                    if (prediction.structuredFormatting?.secondaryText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        prediction.structuredFormatting!.secondaryText!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppConstants.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class AddressResult {
  final String address;
  final String name;
  final double latitude;
  final double longitude;
  final String placeId;

  AddressResult({
    required this.address,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.placeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'placeId': placeId,
    };
  }

  factory AddressResult.fromMap(Map<String, dynamic> map) {
    return AddressResult(
      address: map['address'] ?? '',
      name: map['name'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      placeId: map['placeId'] ?? '',
    );
  }
}
