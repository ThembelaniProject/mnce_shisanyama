// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../orders/OrderTrackerScreen.dart';

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
  String _statusText = "Placing your order...";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _createOrder();
  }

  Future<void> _createOrder() async {
    try {
      final orderRef = await FirebaseFirestore.instance.collection('orders').add({
        'status': 'pending',
        'total': widget.orderTotal,
        'deliveryAddress': widget.deliveryAddress,
        'customerId': FirebaseAuth.instance.currentUser?.uid,
        'customerName': FirebaseAuth.instance.currentUser?.displayName ?? 'Customer',
        'items': widget.cartItems.map((e) => {
          'name': e.menuItem.name,
          'quantity': e.quantity,
          'spice': e.spicePreference,
          'notes': e.notes,
          'price': e.menuItem.price,
        }).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'approvedAt': null,
        'dispatchedAt': null,
        'deliveredAt': null,
        'assignedDriver': null,
        'assignedDriverName': null,
        'approvedBy': null,
        'dispatchedBy': null,
      });

      CartService().clear();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackerScreen(orderId: orderRef.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create order: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.softAshGray,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(color: AppTheme.braaiBasteGold),
                const SizedBox(height: 40),
                Card(
                  color: AppTheme.braaiCoalSurface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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