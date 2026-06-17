// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import '../admin/admin_home.dart';
import '../driver/driver_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!mounted) return;

      final role = userDoc.data()?['role'] ?? 'customer';

      Widget nextScreen;
      if (role == 'admin') {
        nextScreen = const AdminHomeScreen();
      } else if (role == 'driver') {
        nextScreen = const DriverHomeScreen();
      } else {
        nextScreen = const ShisanyamaMainScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextScreen),
      );
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'user-not-found') {
        message = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided.";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address.";
      } else if (e.code == 'invalid-credential') {
        message = "Invalid email or password.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final emailController = TextEditingController(text: _emailController.text.trim());
    
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.braaiCoalSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password', style: TextStyle(color: AppTheme.whitePure)),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: AppTheme.whitePure),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: const TextStyle(color: AppTheme.mutedSlate),
            prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.braaiFireOrange),
            filled: true,
            fillColor: AppTheme.braaiCharcoalDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.softAshGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.braaiFireOrange,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, emailController.text.trim()),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;
    if (!email.contains('@')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid email'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to $email'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Failed to send reset email';
      if (e.code == 'user-not-found') msg = 'No account found for this email';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.braaiFireOrange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/images/mnce_logo.png',
                            height: 100,
                            width: 100,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.local_fire_department_rounded,
                              size: 80,
                              color: AppTheme.braaiFireOrange,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Mnce Shisanyama",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.whitePure,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Text(
                          "Durban Mai Mai",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.braaiBasteGold,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50),
                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.whitePure,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Sign in to continue ordering your favourite braai",
                    style: TextStyle(fontSize: 16, color: AppTheme.softAshGray),
                  ),
                  const SizedBox(height: 40),
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
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword, // <-- Now works
                      child: const Text("Forgot Password?", style: TextStyle(color: AppTheme.braaiBasteGold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.braaiFireOrange,
                        foregroundColor: AppTheme.whitePure,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                      ),
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? ", style: TextStyle(color: AppTheme.softAshGray)),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text("Create Account", style: TextStyle(color: AppTheme.braaiFireOrange, fontWeight: FontWeight.bold)),
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
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}