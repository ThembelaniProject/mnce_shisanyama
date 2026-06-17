// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../auth/login_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _licenseController = TextEditingController();

  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String _email = '';
  String _status = 'Offline';
  int _deliveries = 0;
  double _rating = 5.0;

  @override
  void initState() {
    super.initState();
    _loadDriverData();
  }

  Future<void> _loadDriverData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (data!= null && mounted) {
        setState(() {
          _nameController.text = data['fullName']?? '';
          _phoneController.text = data['phone']?? '';
          _vehicleController.text = data['vehicle']?? '';
          _licenseController.text = data['license']?? '';
          _email = data['email']?? '';
          _status = data['status']?? 'Offline';
          _deliveries = data['deliveries']?? 0;
          _rating = (data['rating']?? 5.0).toDouble();
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

  Future<void> _toggleStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final newStatus = _status == 'Online'? 'Offline' : 'Online';
    setState(() => _status = newStatus);

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': newStatus,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status: $newStatus'),
            backgroundColor: newStatus == 'Online'? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() => _status = _status == 'Online'? 'Offline' : 'Online'); // revert
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check name and phone'), backgroundColor: Colors.red),
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
        'vehicle': _vehicleController.text.trim(),
        'license': _licenseController.text.trim(),
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
        title: const Text('Driver Profile', style: TextStyle(color: AppTheme.whitePure)),
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
                    // Avatar + Status
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.braaiCoalSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: AppTheme.braaiFireOrange.withOpacity(0.2),
                                child: Text(
                                  _nameController.text.isNotEmpty? _nameController.text[0].toUpperCase() : 'D',
                                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.braaiFireOrange),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: _status == 'Online'? Colors.green : Colors.orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppTheme.braaiCoalSurface, width: 3),
                                ),
                                child: Icon(
                                  _status == 'Online'? Icons.circle : Icons.circle_outlined,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(_nameController.text, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.whitePure)),
                          const SizedBox(height: 4),
                          Text(_email, style: const TextStyle(color: AppTheme.softAshGray)),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _status == 'Online'? Colors.green : AppTheme.braaiFireOrange,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _toggleStatus,
                            icon: Icon(_status == 'Online'? Icons.toggle_on : Icons.toggle_off),
                            label: Text('Go ${_status == 'Online'? 'Offline' : 'Online'}'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Stats
                    Row(
                      children: [
                        Expanded(child: _statCard('Deliveries', '$_deliveries', Icons.local_shipping)),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard('Rating', _rating.toStringAsFixed(1), Icons.star)),
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
                          _buildField('Vehicle', _vehicleController, Icons.directions_car, _isEditing),
                          const SizedBox(height: 16),
                          _buildField('License Plate', _licenseController, Icons.credit_card, _isEditing),
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
    _vehicleController.dispose();
    _licenseController.dispose();
    super.dispose();
  }
}