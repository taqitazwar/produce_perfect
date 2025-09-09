import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants/app_constants.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../models/category_model.dart';

class FarmerCreatePostScreen extends StatefulWidget {
  const FarmerCreatePostScreen({super.key});

  @override
  State<FarmerCreatePostScreen> createState() => _FarmerCreatePostScreenState();
}

class _FarmerCreatePostScreenState extends State<FarmerCreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _conditionController = TextEditingController();
  final _productService = ProductService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  List<XFile> _selectedImages = [];
  String _selectedCategory = '';
  String _selectedUnit = 'kg';
  DateTime? _harvestDate;
  DateTime? _expiryDate;
  bool _isLoading = false;

  final List<String> _units = ['kg', 'lbs', 'pieces', 'bunches', 'boxes'];
  final List<CategoryModel> _categories = DemoCategories.getCategories();

  @override
  void initState() {
    super.initState();
    if (_categories.isNotEmpty) {
      _selectedCategory = _categories.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountedPriceController.dispose();
    _quantityController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.take(5).toList(); // Max 5 images
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: $e'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isHarvestDate) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day); // Remove time component
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: isHarvestDate 
          ? DateTime.now().subtract(const Duration(days: 30)) // Allow past harvest dates
          : today, // Expiry date starts from today
      lastDate: isHarvestDate 
          ? today // Harvest date cannot be in the future
          : DateTime.now().add(const Duration(days: 365)), // Expiry can be up to 1 year
    );
    
    if (picked != null) {
      setState(() {
        if (isHarvestDate) {
          _harvestDate = picked;
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  Future<void> _createPost() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    if (_harvestDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select harvest and expiry dates'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      final userProfile = await _authService.getUserProfile(user!.uid);
      
      if (userProfile == null) {
        throw 'User profile not found';
      }

      await _productService.createProduct(
        farmerId: user.uid,
        farmerName: userProfile.name,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        originalPrice: _originalPriceController.text.isNotEmpty 
            ? double.parse(_originalPriceController.text) 
            : double.parse(_discountedPriceController.text), // Use sale price as original if not provided
        discountedPrice: double.parse(_discountedPriceController.text),
        quantity: int.parse(_quantityController.text),
        unit: _selectedUnit,
        images: _selectedImages,
        farmLocation: userProfile.farmAddress ?? 'Unknown Location',
        harvestDate: _harvestDate!,
        expiryDate: _expiryDate!,
        condition: _conditionController.text.trim(),
        tags: ['imperfect', 'fresh', 'local'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product posted successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        
        // Clear form
        _formKey.currentState!.reset();
        _titleController.clear();
        _descriptionController.clear();
        _originalPriceController.clear();
        _discountedPriceController.clear();
        _quantityController.clear();
        _conditionController.clear();
        setState(() {
          _selectedImages.clear();
          _harvestDate = null;
          _expiryDate = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
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
      appBar: AppBar(
        title: const Text('Create Post'),
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image Selection Section
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
                      const Text(
                        'Product Images',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      if (_selectedImages.isEmpty)
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppConstants.primaryColor,
                                style: BorderStyle.solid,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_a_photo,
                                    size: 50,
                                    color: AppConstants.primaryColor,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap to add photos',
                                    style: TextStyle(
                                      color: AppConstants.primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Add up to 5 images',
                                    style: TextStyle(
                                      color: AppConstants.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.file(
                                            File(_selectedImages[index].path),
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedImages.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _selectedImages.length < 5 ? _pickImages : null,
                              icon: const Icon(Icons.add_photo_alternate),
                              label: Text('Add More Images (${_selectedImages.length}/5)'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ).animate().slideY(delay: 100.ms, duration: 500.ms),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Product Details Section
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
                      const Text(
                        'Product Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Title
                      CustomTextField(
                        label: 'Product Name',
                        controller: _titleController,
                        isRequired: true,
                        prefixIcon: const Icon(Icons.shopping_basket),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter product name';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category),
                          border: OutlineInputBorder(),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Text('${category.icon} ${category.name}'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Description
                      CustomTextField(
                        label: 'Description',
                        controller: _descriptionController,
                        isRequired: true,
                        maxLines: 3,
                        prefixIcon: const Icon(Icons.description),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter description';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Condition
                      CustomTextField(
                        label: 'Condition',
                        hint: 'e.g., slightly overripe, small dents',
                        controller: _conditionController,
                        isRequired: true,
                        prefixIcon: const Icon(Icons.info_outline),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please describe the condition';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ).animate().slideY(delay: 200.ms, duration: 500.ms),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Pricing & Quantity Section
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
                      const Text(
                        'Pricing & Quantity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Price Row
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Original Price (\$)',
                              hint: 'Enter original price',
                              controller: _originalPriceController,
                              keyboardType: TextInputType.number,
                              isRequired: false, // Made optional
                              prefixIcon: const Icon(Icons.attach_money),
                              validator: (value) {
                                // Only validate if value is provided
                                if (value != null && value.isNotEmpty) {
                                  if (double.tryParse(value) == null) {
                                    return 'Invalid price';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingMedium),
                          Expanded(
                            child: CustomTextField(
                              label: 'Sale Price (\$)',
                              hint: 'Enter sale price',
                              controller: _discountedPriceController,
                              keyboardType: TextInputType.number,
                              isRequired: true,
                              prefixIcon: const Icon(Icons.local_offer),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                final price = double.tryParse(value);
                                if (price == null) {
                                  return 'Invalid price';
                                }
                                final originalPrice = double.tryParse(_originalPriceController.text);
                                if (originalPrice != null && price >= originalPrice) {
                                  return 'Must be less than original';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Quantity Row
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: CustomTextField(
                              label: 'Quantity',
                              hint: 'Enter quantity',
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              isRequired: true,
                              prefixIcon: const Icon(Icons.inventory),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid quantity';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingMedium),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: _selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(),
                              ),
                              items: _units.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().slideY(delay: 300.ms, duration: 500.ms),
                
                const SizedBox(height: AppConstants.paddingLarge),
                
                // Dates Section
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
                      const Text(
                        'Dates',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      
                      // Harvest Date
                      ListTile(
                        leading: const Icon(Icons.agriculture, color: AppConstants.primaryColor),
                        title: const Text('Harvest Date'),
                        subtitle: Text(_harvestDate != null 
                            ? '${_harvestDate!.day}/${_harvestDate!.month}/${_harvestDate!.year}'
                            : 'Select harvest date'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context, true),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      // Expiry Date
                      ListTile(
                        leading: const Icon(Icons.schedule, color: AppConstants.errorColor),
                        title: const Text('Best Before Date'),
                        subtitle: Text(_expiryDate != null 
                            ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                            : 'Select expiry date'),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () => _selectDate(context, false),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                    ],
                  ),
                ).animate().slideY(delay: 400.ms, duration: 500.ms),
                
                const SizedBox(height: AppConstants.paddingXLarge),
                
                // Create Post Button
                CustomButton(
                  text: 'Create Post',
                  onPressed: _isLoading ? null : _createPost,
                  isLoading: _isLoading,
                ).animate().slideY(delay: 500.ms, duration: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
