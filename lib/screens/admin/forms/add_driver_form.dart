// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Add this
import '../../../core/theme/app_theme.dart';

class AddDriverForm extends StatefulWidget {
  const AddDriverForm({super.key});

  @override
  State<AddDriverForm> createState() => _AddDriverFormState();
}

class _AddDriverFormState extends State<AddDriverForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _licenseController = TextEditingController();
  final _passwordController = TextEditingController(); // <-- Added
  String _selectedRole = 'driver';
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Create Firebase Auth account first
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = cred.user!.uid; // <-- This is the Auth UID

      // 2. Build user data
      final data = {
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole,
        'status': 'Offline',
        'deliveries': 0,
        'rating': 5.0,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Only add vehicle/license if role is driver
      if (_selectedRole == 'driver') {
        data['vehicle'] = _vehicleController.text.trim();
        data['license'] = _licenseController.text.trim();
      }

      // 3. Use UID as document ID instead of .add()
      await FirebaseFirestore.instance.collection('users').doc(uid).set(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User added successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Error creating user';
      if (e.code == 'email-already-in-use') msg = 'Email already registered';
      if (e.code == 'weak-password') msg = 'Password too weak. Use 6+ characters';
      if (e.code == 'invalid-email') msg = 'Invalid email address';
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      appBar: AppBar(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: const Text('Add New User', style: TextStyle(color: AppTheme.whitePure)),
        iconTheme: const IconThemeData(color: AppTheme.braaiFireOrange),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppTheme.whitePure),
                  decoration: _inputDecoration('Full Name', Icons.person),
                  validator: (v) => v!.isEmpty ? 'Enter name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppTheme.whitePure),
                  decoration: _inputDecoration('Email', Icons.email),
                  validator: (v) {
                    if (v!.isEmpty) return 'Enter email';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppTheme.whitePure),
                  decoration: _inputDecoration('Phone Number', Icons.phone),
                  validator: (v) => v!.length < 10 ? 'Enter valid phone' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController, // <-- Added password field
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.whitePure),
                  decoration: _inputDecoration('Temporary Password', Icons.lock),
                  validator: (v) => v!.length < 6 ? 'Password must be 6+ chars' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  dropdownColor: AppTheme.braaiCharcoalDark,
                  style: const TextStyle(color: AppTheme.whitePure),
                  decoration: _inputDecoration('Role', Icons.admin_panel_settings),
                  items: ['customer', 'driver', 'admin']
                      .map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase())))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),
                
                if (_selectedRole == 'driver') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _vehicleController,
                    style: const TextStyle(color: AppTheme.whitePure),
                    decoration: _inputDecoration('Vehicle Model', Icons.directions_car),
                    validator: (v) => v!.isEmpty ? 'Enter vehicle' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _licenseController,
                    style: const TextStyle(color: AppTheme.whitePure),
                    decoration: _inputDecoration('License Plate', Icons.credit_card),
                    validator: (v) => v!.isEmpty ? 'Enter license plate' : null,
                  ),
                ],
                
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.braaiFireOrange,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Text('Add User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.softAshGray),
      prefixIcon: Icon(icon, color: AppTheme.braaiFireOrange),
      filled: true,
      fillColor: AppTheme.braaiCoalSurface,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.braaiFireOrange, width: 1.5),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    _licenseController.dispose();
    _passwordController.dispose(); // <-- Added
    super.dispose();
  }
}