// ignore_for_file: unused_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _register() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    // 1. Create auth user
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // 2. Add to Firestore 'users' collection with role: customer
    await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
      'uid': userCredential.user!.uid,
      'email': _emailController.text.trim(),
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'role': 'customer', // This is key
      'createdAt': FieldValue.serverTimestamp(),
      'fcmToken': '', // For push notifications later
    });

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ShisanyamaMainScreen()),
      );
    }
  } on FirebaseAuthException catch (e) {
    String message = "Registration failed";
    if (e.code == 'email-already-in-use') {
      message = "Email already registered.";
    } else if (e.code == 'weak-password') {
      message = "Password is too weak.";
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong.")),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.whitePure),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Header
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.braaiFireOrange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            size: 70,
                            color: AppTheme.braaiFireOrange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Join Mnce Shisanyama",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.whitePure,
                          ),
                        ),
                        const Text(
                          "Create your account",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.softAshGray,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Full Name
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppTheme.whitePure),
                    validator: (value) => value == null || value.isEmpty ? "Full name is required" : null,
                    decoration: InputDecoration(
                      hintText: "Full Name",
                      hintStyle: const TextStyle(color: AppTheme.mutedSlate),
                      prefixIcon: const Icon(Icons.person_outline, color: AppTheme.braaiFireOrange),
                      filled: true,
                      fillColor: AppTheme.braaiCoalSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.braaiFireOrange, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Phone Number
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: AppTheme.whitePure),
                    validator: (value) => value == null || value.isEmpty ? "Phone number is required" : null,
                    decoration: InputDecoration(
                      hintText: "Phone Number",
                      hintStyle: const TextStyle(color: AppTheme.mutedSlate),
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.braaiFireOrange),
                      filled: true,
                      fillColor: AppTheme.braaiCoalSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.braaiFireOrange, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppTheme.whitePure),
                    validator: (value) => value == null || !value.contains('@') ? "Enter valid email" : null,
                    decoration: InputDecoration(
                      hintText: "Email Address",
                      hintStyle: const TextStyle(color: AppTheme.mutedSlate),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.braaiFireOrange),
                      filled: true,
                      fillColor: AppTheme.braaiCoalSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.braaiFireOrange, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    style: const TextStyle(color: AppTheme.whitePure),
                    validator: (value) => value == null || value.length < 6 ? "Password must be at least 6 characters" : null,
                    decoration: InputDecoration(
                      hintText: "Password",
                      hintStyle: const TextStyle(color: AppTheme.mutedSlate),
                      prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.braaiFireOrange),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: AppTheme.softAshGray,
                        ),
                        onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                      ),
                      filled: true,
                      fillColor: AppTheme.braaiCoalSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.braaiFireOrange, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Register Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.braaiFireOrange,
                        foregroundColor: AppTheme.whitePure,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                      ),
                      onPressed: _isLoading ? null : _register,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Create Account",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? ", style: TextStyle(color: AppTheme.softAshGray)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Login", style: TextStyle(color: AppTheme.braaiFireOrange, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}