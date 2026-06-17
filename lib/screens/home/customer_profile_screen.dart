// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String _email = '';
  int _totalOrders = 0;
  double _totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final ordersSnap = await FirebaseFirestore.instance
         .collection('orders')
         .where('userId', isEqualTo: uid)
         .get();

      double spent = 0;
      for (var doc in ordersSnap.docs) {
        spent += (doc.data()['total']?? 0).toDouble();
      }

      final data = userDoc.data();
      if (data!= null && mounted) {
        setState(() {
          _nameController.text = data['fullName']?? data['name']?? '';
          _phoneController.text = data['phone']?? '';
          _addressController.text = data['address']?? '';
          _email = data['email']?? '';
          _totalOrders = ordersSnap.docs.length;
          _totalSpent = spent;
          _isLoading = false;
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
        'address': _addressController.text.trim(),
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
        title: const Text('My Profile', style: TextStyle(color: AppTheme.whitePure)),
        iconTheme: const IconThemeData(color: AppTheme.braaiFireOrange),
        actions: [
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing? Icons.close : Icons.edit, color: AppTheme.braaiFireOrange),
              onPressed: () => setState(() => _isEditing =!_isEditing),
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
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: AppTheme.braaiFireOrange.withOpacity(0.2),
                            child: Text(
                              _nameController.text.isNotEmpty? _nameController.text[0].toUpperCase() : 'C',
                              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.braaiFireOrange),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(_nameController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.whitePure)),
                          const SizedBox(height: 4),
                          Text(_email, style: const TextStyle(color: AppTheme.softAshGray)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.braaiBasteGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'CUSTOMER',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.braaiBasteGold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats
                    Row(
                      children: [
                        Expanded(child: _statCard('Orders', '$_totalOrders', Icons.receipt_long)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard('Total Spent', 'R${_totalSpent.toInt()}', Icons.payments)),
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
                          _buildField('Delivery Address', _addressController, Icons.location_on, _isEditing),
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
                          onPressed: _isSaving? null : _saveProfile,
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
      maxLines: label == 'Delivery Address'? 2 : 1,
      style: TextStyle(color: enabled? AppTheme.whitePure : AppTheme.softAshGray),
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
    _addressController.dispose();
    super.dispose();
  }
}