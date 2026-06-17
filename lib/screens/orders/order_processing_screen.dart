import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../driver/driver_home_screen.dart'; //
import 'package:firebase_auth/firebase_auth.dart'; 

class OrderProcessingScreen extends StatefulWidget {
  final double orderTotal;
  final String deliveryAddress;
  final List<CartItem> cartItems;

  const OrderProcessingScreen({
    super.key,
    required this.orderTotal,
    required this.deliveryAddress,
    required this.cartItems,
  });

  @override
  State<OrderProcessingScreen> createState() => _OrderProcessingScreenState();
}

class _OrderProcessingScreenState extends State<OrderProcessingScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _secondsLeft = 120; // 2 minutes
  String _statusText = "We're preparing your order";
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _processOrder();
  }

  Future<void> _processOrder() async {
  // 1. Save order to Firebase first
  final orderRef = await FirebaseFirestore.instance.collection('orders').add({
    'status': 'packing',
    'total': widget.orderTotal,
    'deliveryAddress': widget.deliveryAddress,
    'customerName': FirebaseAuth.instance.currentUser?.displayName?? 'Customer',
    'items': widget.cartItems.map((e) => {
      'name': e.menuItem.name,
      'quantity': e.quantity,
      'spice': e.spicePreference,
      'notes': e.notes,
      'price': e.menuItem.price,
    }).toList(),
    'createdAt': FieldValue.serverTimestamp(),
    'packedAt': null,
    'assignedDriver': null,
  });

  // 2. Clear cart immediately
  CartService().clear();
  
  // 3. 2-minute countdown
  for (int i = 120; i > 0; i--) {
    if (!mounted) return;
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _secondsLeft = i - 1;
      if (i <= 60) _statusText = "Almost ready...";
      if (i <= 30) _statusText = "Packing complete soon";
    });
  }

  // 4. Mark as ready for pickup
  await orderRef.update({
    'status': 'ready_for_pickup',
    'packedAt': FieldValue.serverTimestamp(),
  });
  
  if (mounted) {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (_) => const DriverHomeScreen())
    );
  }
}

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RotationTransition(
                  turns: _controller,
                  child: FaIcon(
                    FontAwesomeIcons.fire,
                    size: 80,
                    color: AppTheme.braaiFireOrange,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  "Firing up the grill!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.whitePure,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _statusText,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.softAshGray,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _formatTime(_secondsLeft),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.braaiBasteGold,
                  ),
                ),
                const SizedBox(height: 40),
                Card(
                  color: AppTheme.braaiCoalSurface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total", style: TextStyle(color: AppTheme.softAshGray)),
                            Text(
                              "R${widget.orderTotal.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: AppTheme.braaiBasteGold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FaIcon(FontAwesomeIcons.locationDot, 
                              color: AppTheme.braaiFireOrange, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.deliveryAddress,
                                style: const TextStyle(color: AppTheme.softAshGray),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            FaIcon(FontAwesomeIcons.basketShopping, 
                              color: AppTheme.braaiFireOrange, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              "${widget.cartItems.length} items",
                              style: const TextStyle(color: AppTheme.softAshGray),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}