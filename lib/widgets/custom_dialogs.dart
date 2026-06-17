import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/menu_item.dart';
import '../services/cart_service.dart';

Future<void> showSpiceCustomizerDialog(BuildContext context, MenuItem menuItem) async {
  int quantity = 1;
  String selectedSpice = "Medium Basted";
  String notes = "";
  final cart = CartService();

  await showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          backgroundColor: AppTheme.braaiCoalSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Customize Your Braai", style: TextStyle(color: AppTheme.braaiFireOrange)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(menuItem.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.whitePure)),
                const SizedBox(height: 16),

                const Text("Quantity", style: TextStyle(color: AppTheme.whitePure)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => setState(() => quantity = quantity > 1? quantity - 1 : 1),
                      icon: const Icon(Icons.remove, color: AppTheme.braaiFireOrange),
                    ),
                    Text(quantity.toString(), style: const TextStyle(fontSize: 24, color: AppTheme.whitePure)),
                    IconButton(
                      onPressed: () => setState(() => quantity++),
                      icon: const Icon(Icons.add, color: AppTheme.braaiFireOrange),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Text("Spice Level", style: TextStyle(color: AppTheme.whitePure)),
                DropdownButton<String>(
                  value: selectedSpice,
                  isExpanded: true,
                  dropdownColor: AppTheme.braaiCoalSurface,
                  style: const TextStyle(color: AppTheme.whitePure),
                  items: ["No Spice", "Lemon & Herb", "Medium Basted", "Hot Peri-Peri", "Soweto Town Fire"]
                     .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                     .toList(),
                  onChanged: (val) => setState(() => selectedSpice = val!),
                ),

                const SizedBox(height: 12),
                const Text("Special Instructions", style: TextStyle(color: AppTheme.whitePure)),
                TextField(
                  onChanged: (val) => notes = val,
                  style: const TextStyle(color: AppTheme.whitePure),
                  decoration: const InputDecoration(
                    hintText: "Extra onions, well done, etc...",
                    hintStyle: TextStyle(color: AppTheme.softAshGray),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: AppTheme.softAshGray)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.braaiFireOrange),
              onPressed: () {
                cart.addItem(
                  menuItem,
                  quantity: quantity,
                  spicePreference: selectedSpice,
                  notes: notes,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${menuItem.name} added to basket!"),
                    backgroundColor: AppTheme.braaiFireOrange,
                  ),
                );
              },
              child: Text(
                "Add R${(menuItem.price * quantity).toInt()}",
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ),
  );
}