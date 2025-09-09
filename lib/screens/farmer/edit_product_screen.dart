import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../constants/app_constants.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../models/product_model.dart';
import '../../models/category_model.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productService = ProductService();
  final _authService = AuthService();
  final _imagePicker = ImagePicker();

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _originalPriceController;
  late TextEditingController _discountedPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _conditionController;

  // Form state
  List<File> _selectedImages = [];
  List<String> _existingImageUrls = [];
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
    _initializeFromProduct();
  }

  void _initializeFromProduct() {
    final product = widget.product;
    
    _titleController = TextEditingController(text: product.title);
    _descriptionController = TextEditingController(text: product.description);
    _originalPriceController = TextEditingController(text: product.originalPrice.toString());
    _discountedPriceController = TextEditingController(text: product.discountedPrice.toString());
    _quantityController = TextEditingController(text: product.quantity.toString());
    _conditionController = TextEditingController(text: product.condition);
    
    _selectedCategory = product.category;
    _selectedUnit = product.unit;
    _harvestDate = product.harvestDate;
    _expiryDate = product.expiryDate;
    _existingImageUrls = List<String>.from(product.imageUrls);
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
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick images: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isHarvestDate) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isHarvestDate ? (_harvestDate ?? today) : (_expiryDate ?? today),
      firstDate: isHarvestDate 
          ? DateTime.now().subtract(const Duration(days: 30))
          : today,
      lastDate: isHarvestDate 
          ? today
          : DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

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
      if (user == null) throw Exception('User not authenticated');

      // Upload new images if any were selected
      List<String> finalImageUrls = List<String>.from(_existingImageUrls);
      if (_selectedImages.isNotEmpty) {
        final newImageUrls = await _productService.uploadProductImages(_selectedImages);
        finalImageUrls.addAll(newImageUrls);
      }

      final updatedProduct = ProductModel(
        id: widget.product.id,
        farmerId: user.uid,
        farmerName: widget.product.farmerName,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        originalPrice: double.parse(_originalPriceController.text),
        discountedPrice: double.parse(_discountedPriceController.text),
        quantity: int.parse(_quantityController.text),
        unit: _selectedUnit,
        imageUrls: finalImageUrls,
        farmLocation: widget.product.farmLocation,
        harvestDate: _harvestDate!,
        expiryDate: _expiryDate!,
        condition: _conditionController.text.trim(),
        tags: widget.product.tags,
        isAvailable: widget.product.isAvailable,
        createdAt: widget.product.createdAt,
        updatedAt: DateTime.now(),
      );

      await _productService.updateProductModel(updatedProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
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
                // Product Images Section
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
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
                      const Text(
                        'Product Images',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      
                      // Existing images
                      if (_existingImageUrls.isNotEmpty) ...[
                        const Text(
                          'Current Images:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingImageUrls.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        _existingImageUrls[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.error),
                                          );
                                        },
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeExistingImage(index),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: AppConstants.errorColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
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
                        const SizedBox(height: AppConstants.paddingMedium),
                      ],

                      // New images
                      if (_selectedImages.isNotEmpty) ...[
                        const Text(
                          'New Images:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 100,
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
                                        _selectedImages[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeNewImage(index),
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: AppConstants.errorColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
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
                        const SizedBox(height: AppConstants.paddingMedium),
                      ],

                      // Add images button
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppConstants.primaryColor,
                              style: BorderStyle.solid,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo,
                                  color: AppConstants.primaryColor,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add More Images',
                                  style: TextStyle(
                                    color: AppConstants.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // Product Details Section
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
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
                      const Text(
                        'Product Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),

                      // Product Title
                      CustomTextField(
                        label: 'Product Title',
                        controller: _titleController,
                        isRequired: true,
                        prefixIcon: const Icon(Icons.title),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Product title is required';
                          }
                          return null;
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
                          if (value == null || value.isEmpty) {
                            return 'Description is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // Category Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedCategory.isEmpty ? null : _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category *',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                          ),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // Price Row
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              label: 'Original (\$)',
                              controller: _originalPriceController,
                              keyboardType: TextInputType.number,
                              isRequired: true,
                              prefixIcon: const Icon(Icons.attach_money),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid price';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: AppConstants.paddingMedium),
                          Expanded(
                            child: CustomTextField(
                              label: 'Sale (\$)',
                              controller: _discountedPriceController,
                              keyboardType: TextInputType.number,
                              isRequired: true,
                              prefixIcon: const Icon(Icons.local_offer),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Invalid price';
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
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              isRequired: true,
                              prefixIcon: const Icon(Icons.inventory),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Required';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Invalid';
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
                              decoration: InputDecoration(
                                labelText: 'Unit',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                                ),
                              ),
                              items: _units.map((unit) {
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value ?? 'kg';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.paddingLarge),

                      // Condition
                      CustomTextField(
                        label: 'Condition (e.g., slightly overripe, small dents)',
                        controller: _conditionController,
                        isRequired: true,
                        maxLines: 2,
                        prefixIcon: const Icon(Icons.info),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please describe the condition';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // Dates Section
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
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

                      // Best Before Date
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
                ),

                const SizedBox(height: AppConstants.paddingXLarge),

                // Update Button
                CustomButton(
                  text: 'Update Product',
                  onPressed: _updateProduct,
                  isLoading: _isLoading,
                ).animate().slideY(delay: 800.ms, duration: 500.ms),

                const SizedBox(height: AppConstants.paddingLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
