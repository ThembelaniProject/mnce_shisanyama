// ignore_for_file: unused_field, deprecated_member_use

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  String _email = '';
  int _totalUsers = 0;
  int _totalDrivers = 0;
  String? _profileImageUrl;
  File? _selectedImage;

  final ImagePicker _picker = ImagePicker();

  // Use 'ml_default' if you don't have a custom unsigned preset
  final cloudinary = CloudinaryPublic(
    'dgg3eg14n',
    'ml_default', // Cloudinary's default unsigned preset. Change to 'dynamic_folders' after creating it
    cache: false,
  );

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final driversSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'driver').get();

      final data = userDoc.data();
      if (data != null && mounted) {
        print('Profile image from Firestore: ${data['profileImage']}');
        setState(() {
          _nameController.text = data['fullName'] ?? data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _email = data['email'] ?? '';
          _totalUsers = usersSnap.docs.length;
          _totalDrivers = driversSnap.docs.length;
          _isLoading = false;
          _profileImageUrl = data['profileImage'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      print('Starting image pick...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) {
        print('No image selected');
        return;
      }

      print('Image picked: ${image.path}');
      setState(() {
        _isUploadingImage = true;
        _selectedImage = File(image.path);
      });

      print('Uploading to Cloudinary...');
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'admin_profiles',
        ),
      );

      print('Upload success: ${response.secureUrl}');
      final imageUrl = response.secureUrl;
      final uid = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _profileImageUrl = imageUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile image updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on CloudinaryException catch (e) {
      print('Cloudinary error: ${e.message}');
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cloudinary error: ${e.message}. Check if preset is unsigned.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Upload error: $e');
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: const Text('Logout', style: TextStyle(color: AppTheme.whitePure)),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: AppTheme.softAshGray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.braaiFireOrange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      appBar: AppBar(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: const Text('Admin Profile', style: TextStyle(color: AppTheme.whitePure)),
        iconTheme: const IconThemeData(color: AppTheme.braaiFireOrange),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit, color: AppTheme.braaiFireOrange),
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.braaiFireOrange))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar + Info
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.braaiCoalSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Avatar with tap + camera icon
                              GestureDetector(
                                onTap: _isUploadingImage ? null : _pickAndUploadImage,
                                behavior: HitTestBehavior.opaque,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundColor: AppTheme.braaiFireOrange.withOpacity(0.2),
                                      backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                                          ? NetworkImage(_profileImageUrl!)
                                          : null,
                                      child: (_profileImageUrl == null || _profileImageUrl!.isEmpty)
                                          ? Text(
                                              _nameController.text.isNotEmpty
                                                  ? _nameController.text[0].toUpperCase()
                                                  : 'A',
                                              style: const TextStyle(
                                                fontSize: 40,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.braaiFireOrange,
                                              ),
                                            )
                                          : null,
                                    ),
                                    if (_isUploadingImage)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: AppTheme.braaiFireOrange,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (!_isUploadingImage)
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppTheme.braaiFireOrange,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: AppTheme.braaiCoalSurface,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // ADMIN badge - positioned so it doesn't cover avatar
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.braaiFireOrange,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.braaiCoalSurface, width: 2),
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(_nameController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.whitePure)),
                          const SizedBox(height: 4),
                          Text(_email, style: const TextStyle(color: AppTheme.softAshGray)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats
                    Row(
                      children: [
                        Expanded(child: _statCard('Total Users', '$_totalUsers', Icons.people)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard('Drivers', '$_totalDrivers', Icons.delivery_dining)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Details
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.braaiCoalSurface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildField('Full Name', _nameController, Icons.person, _isEditing),
                          const SizedBox(height: 16),
                          _buildField('Phone', _phoneController, Icons.phone, _isEditing, TextInputType.phone),
                          const SizedBox(height: 16),
                          _buildField('Email', TextEditingController(text: _email), Icons.email, false),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.braaiFireOrange,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isSaving ? null : _saveProfile,
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.black)
                              : const Text('Save Changes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.braaiCoalSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.braaiFireOrange, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.whitePure)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.softAshGray, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon, bool enabled, [TextInputType? keyboardType]) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(color: enabled ? AppTheme.whitePure : AppTheme.softAshGray),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.softAshGray),
        prefixIcon: Icon(icon, color: AppTheme.braaiFireOrange),
        filled: true,
        fillColor: AppTheme.braaiCharcoalDark,
        disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.braaiFireOrange, width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}