// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import '../../../core/theme/app_theme.dart';

class AddStockScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? existingData;

  const AddStockScreen({
    super.key,
    this.docId,
    this.existingData,
  });

  @override
  State<AddStockScreen> createState() => _AddStockScreenState();
}

class _AddStockScreenState extends State<AddStockScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = "Meats";
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _imageUrl;

  final ImagePicker _picker = ImagePicker();
  final cloudinary = CloudinaryPublic(
    'dgg3eg14n',
    'mnce_stock_uploads', // Change to your unsigned preset name
    cache: false,
  );

  final List<String> _categories = [
    "Meats",
    "Platters", 
    "Sides",
    "Drinks",
    "Spices",
    "Other"
  ];

  bool get isEditing => widget.docId!= null;

  @override
  void initState() {
    super.initState();
    if (widget.existingData!= null) {
      _nameController.text = widget.existingData!['name']?? '';
      _priceController.text = (widget.existingData!['price']?? 0).toString();
      _quantityController.text = (widget.existingData!['quantity']?? 0).toString();
      _descriptionController.text = widget.existingData!['description']?? '';
      _imageUrl = widget.existingData!['imageUrl'];
      
      final cat = widget.existingData!['category'];
      if (cat!= null && _categories.contains(cat)) {
        _selectedCategory = cat;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
  try {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      maxHeight: 1080,
      imageQuality: 80, // Compress more
    );

    if (image == null) return;

    final file = File(image.path);
    final bytes = await file.length();
    
    // Fixed: 10MB = 10 * 1024 * 1024
    if (bytes > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image too large. Max 10MB'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isUploadingImage = true);

    CloudinaryResponse response = await cloudinary.uploadFile(
      CloudinaryFile.fromFile(
        image.path,
        resourceType: CloudinaryResourceType.Image,
        folder: 'stock_items',
      ),
    );

    setState(() {
      _imageUrl = response.secureUrl;
      _isUploadingImage = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded'), backgroundColor: Colors.green),
      );
    }
  } on CloudinaryException catch (e) {
    print('Cloudinary error: ${e.message}');
    setState(() => _isUploadingImage = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.message}'), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    print('Upload error: $e');
    setState(() => _isUploadingImage = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

  Future<void> _saveStock() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'category': _selectedCategory,
        'imageUrl': _imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await FirebaseFirestore.instance
           .collection('menu_items')
           .doc(widget.docId)
           .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('menu_items').add(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing? 'Stock updated successfully' : 'Stock added successfully'),
            backgroundColor: AppTheme.braaiFireOrange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.softAshGray),
      prefixIcon: Icon(icon, color: AppTheme.braaiFireOrange),
      filled: true,
      fillColor: AppTheme.braaiCoalSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.braaiFireOrange, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      appBar: AppBar(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: Text(
          isEditing? 'Edit Stock' : 'Add Stock',
          style: const TextStyle(color: AppTheme.whitePure, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: AppTheme.braaiFireOrange),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _isUploadingImage? null : _pickAndUploadImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.braaiCoalSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.braaiFireOrange.withOpacity(0.4),
                    width: 2,
                  ),
                  image: _imageUrl!= null && _imageUrl!.isNotEmpty
                     ? DecorationImage(
                          image: NetworkImage(_imageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _isUploadingImage
                   ? const Center(
                        child: CircularProgressIndicator(color: AppTheme.braaiFireOrange),
                      )
                    : _imageUrl == null || _imageUrl!.isEmpty
                       ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 50, color: AppTheme.softAshGray),
                              SizedBox(height: 8),
                              Text('Tap to add image', style: TextStyle(color: AppTheme.softAshGray)),
                            ],
                          )
                        : Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: AppTheme.braaiFireOrange,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, size: 18, color: Colors.black),
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              style: const TextStyle(color: AppTheme.whitePure),
              decoration: _inputDecoration('Item Name', Icons.restaurant_menu),
              validator: (value) => value == null || value.trim().isEmpty? 'Enter item name' : null,
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: AppTheme.braaiCoalSurface,
              style: const TextStyle(color: AppTheme.whitePure),
              decoration: _inputDecoration('Category', Icons.category),
              items: _categories.map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (value) => setState(() => _selectedCategory = value!),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    style: const TextStyle(color: AppTheme.whitePure),
                    decoration: _inputDecoration('Price (R)', Icons.payments),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter price';
                      if (double.tryParse(value) == null) return 'Invalid price';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _quantityController,
                    style: const TextStyle(color: AppTheme.whitePure),
                    decoration: _inputDecoration('Quantity', Icons.inventory),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter qty';
                      if (int.tryParse(value) == null) return 'Invalid qty';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              style: const TextStyle(color: AppTheme.whitePure),
              decoration: _inputDecoration('Description', Icons.description),
              maxLines: 3,
              validator: (value) => value == null || value.trim().isEmpty? 'Enter description' : null,
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading? null : _saveStock,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.braaiFireOrange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                 ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : Text(
                      isEditing? 'Update Stock' : 'Add to Stock',
                      style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}