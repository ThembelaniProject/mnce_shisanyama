// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/cart_item.dart';
import '../../services/cart_service.dart';
import '../orders/order_processing_screen.dart';

class CartScreen extends StatefulWidget {
  final String deliveryAddress;
  
  const CartScreen({
    super.key,
    required this.deliveryAddress,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService cart = CartService();

  @override
  void initState() {
    super.initState();
    cart.addListener(_onCartUpdate);
  }

  void _onCartUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    cart.removeListener(_onCartUpdate);
    super.dispose();
  }

  void _placeOrder() {
  if (cart.isEmpty) return;
  
  
  Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => OrderProcessingScreen(
      orderTotal: cart.total,
      deliveryAddress: widget.deliveryAddress,
      cartItems: cart.items, // now defined
    ),
  ),
);
}
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      appBar: AppBar(
        title: const Text("My Basket", style: TextStyle(color: AppTheme.whitePure)),
        backgroundColor: AppTheme.braaiCoalSurface,
        iconTheme: const IconThemeData(color: AppTheme.braaiFireOrange),
      ),
      body: cart.isEmpty
         ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.basketShopping, size: 80, color: AppTheme.mutedSlate),
                  const SizedBox(height: 16),
                  const Text("Your basket is empty", 
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.whitePure)),
                  const SizedBox(height: 8),
                  const Text("Add some flame-grilled goodness!", 
                    style: TextStyle(color: AppTheme.softAshGray)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Delivery Address Card
                // Delivery Address Card
Card(
  color: AppTheme.braaiCoalSurface,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(FontAwesomeIcons.locationDot, 
              color: AppTheme.braaiFireOrange, size: 16),
            const SizedBox(width: 8),
            const Text("Delivery Address", 
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.whitePure)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.deliveryAddress.trim().isEmpty 
            ? "Workshop Durban" 
            : widget.deliveryAddress, 
          style: const TextStyle(color: AppTheme.softAshGray)
        ),
      ],
    ),
  ),
),
                const SizedBox(height: 16),

                const Text("Your Order", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.whitePure)),
                const SizedBox(height: 12),
                
               ...cart.items.map((item) => CartItemRow(
                  item: item, 
                  onUpdate: () => setState(() {}),
                  cart: cart,
                )),

                const SizedBox(height: 24),

                // Summary Card
                Card(
                  color: AppTheme.braaiCoalSurface,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildRow("Subtotal", "R${cart.subtotal.toStringAsFixed(2)}"),
                        _buildRow("Delivery Fee", "R${cart.deliveryFee.toStringAsFixed(2)}"),
                        _buildRow("Service Fee", "R${cart.serviceFee.toStringAsFixed(2)}"),
                        _buildRow("Driver Tip", "R${cart.driverTip.toStringAsFixed(2)}"),
                        const Divider(color: AppTheme.softAshGray),
                        _buildRow("Total", "R${cart.total.toStringAsFixed(2)}", isTotal: true),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.braaiFireOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: cart.isEmpty ? null : _placeOrder,
                  child: Text(
                    "PLACE ORDER • R${cart.total.toStringAsFixed(0)}",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isTotal? AppTheme.whitePure : AppTheme.softAshGray)),
          Text(value, style: TextStyle(
            fontWeight: isTotal? FontWeight.bold : FontWeight.normal, 
            fontSize: isTotal? 18 : 14, 
            color: isTotal? AppTheme.braaiBasteGold : AppTheme.whitePure
          )),
        ],
      ),
    );
  }
}

class CartItemRow extends StatelessWidget {
  final CartItem item;
  final VoidCallback onUpdate;
  final CartService cart;

  const CartItemRow({
    super.key, 
    required this.item, 
    required this.onUpdate,
    required this.cart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.braaiCoalSurface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.braaiCharcoalDark,
                image: item.menuItem.imageUrl!= null && item.menuItem.imageUrl!.isNotEmpty
                   ? DecorationImage(
                        image: NetworkImage(item.menuItem.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item.menuItem.imageUrl == null || item.menuItem.imageUrl!.isEmpty
                 ? FaIcon(FontAwesomeIcons.fire, color: AppTheme.braaiFireOrange, size: 30)
                  : null,
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.menuItem.name, 
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.whitePure),
                  ),
                  if (item.spicePreference.isNotEmpty)
                    Text(
                      "Spice: ${item.spicePreference}", 
                      style: const TextStyle(color: AppTheme.braaiFireOrange, fontSize: 12),
                    ),
                  Text(
                    "R${(item.menuItem.price * item.quantity).toStringAsFixed(0)}", 
                    style: const TextStyle(color: AppTheme.braaiBasteGold, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            Container(
              decoration: BoxDecoration(
                color: AppTheme.braaiCharcoalDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: FaIcon(FontAwesomeIcons.minus, color: AppTheme.braaiFireOrange, size: 16),
                    onPressed: () {
                      cart.updateQuantity(item, item.quantity - 1);
                      onUpdate();
                    },
                  ),
                  Text(
                    item.quantity.toString(), 
                    style: const TextStyle(color: AppTheme.whitePure, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: FaIcon(FontAwesomeIcons.plus, color: AppTheme.braaiFireOrange, size: 16),
                    onPressed: () {
                      cart.updateQuantity(item, item.quantity + 1);
                      onUpdate();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}