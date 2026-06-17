// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../forms/add_stock_screen.dart';
import '../../../core/theme/app_theme.dart';

class StockTabScreen extends StatefulWidget {
  const StockTabScreen({super.key});

  @override
  State<StockTabScreen> createState() => _StockTabScreenState();
}

class _StockTabScreenState extends State<StockTabScreen> {
  String searchQuery = '';
  String selectedCategory = "All";
  final int lowStockThreshold = 5;

  final List<String> _categories = ["All", "Platters", "Meats", "Sides", "Drinks", "Spices", "Other"];

  Future<void> _deleteItem(String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: const Text('Delete Item', style: TextStyle(color: AppTheme.whitePure)),
        content: Text('Remove "$name" from stock?', style: const TextStyle(color: AppTheme.softAshGray)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.softAshGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('menu_items').doc(id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item deleted'), backgroundColor: AppTheme.braaiFireOrange),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _openAddStock() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddStockScreen()),
    );
  }

  void _openEditStock(String docId, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddStockScreen(
          docId: docId,
          existingData: data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      appBar: AppBar(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: const Text(
          'Stock Management',
          style: TextStyle(color: AppTheme.whitePure, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _openAddStock,
            icon: const Icon(Icons.add, color: AppTheme.braaiFireOrange, size: 28),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              style: const TextStyle(color: AppTheme.whitePure),
              decoration: InputDecoration(
                hintText: "Search stock items...",
                hintStyle: const TextStyle(color: AppTheme.softAshGray),
                prefixIcon: const Icon(Icons.search, color: AppTheme.braaiFireOrange),
                filled: true,
                fillColor: AppTheme.braaiCoalSurface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Categories
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _categories.map((cat) {
                final isSelected = cat == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat),
                    onSelected: (selected) => setState(() => selectedCategory = cat),
                    backgroundColor: AppTheme.braaiCoalSurface,
                    selectedColor: AppTheme.braaiFireOrange,
                    checkmarkColor: Colors.black,
                    labelStyle: TextStyle(color: isSelected ? Colors.black : AppTheme.whitePure),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: isSelected ? Colors.transparent : AppTheme.softAshGray),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Firebase Stock List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('menu_items')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.braaiFireOrange),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, color: AppTheme.softAshGray, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'No stock items yet',
                          style: TextStyle(color: AppTheme.softAshGray, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final category = (data['category'] ?? '').toString();

                  final matchesSearch = name.contains(searchQuery.toLowerCase());
                  final matchesCategory = selectedCategory == "All" || category == selectedCategory;

                  return matchesSearch && matchesCategory;
                }).toList();

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, color: AppTheme.softAshGray, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty && selectedCategory == "All"
                              ? 'No stock items yet'
                              : 'No items match your filters',
                          style: const TextStyle(color: AppTheme.softAshGray, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final qty = (data['quantity'] ?? 0).toInt();
                    final price = (data['price'] ?? 0).toDouble();
                    final name = (data['name'] ?? 'No name').toString();
                    final category = (data['category'] ?? 'Other').toString();
                    final imageUrl = data['imageUrl']?.toString();
                    final isLowStock = qty <= lowStockThreshold && qty > 0;
                    final isOutOfStock = qty == 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: AppTheme.braaiCoalSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            // Image
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOutOfStock
                                      ? Colors.red
                                      : isLowStock
                                          ? AppTheme.braaiBasteGold
                                          : AppTheme.braaiFireOrange,
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: imageUrl,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: AppTheme.braaiCharcoalDark,
                                          child: const Icon(Icons.image, color: AppTheme.softAshGray),
                                        ),
                                        errorWidget: (context, url, error) => Container(
                                          color: AppTheme.braaiCharcoalDark,
                                          child: const Icon(Icons.broken_image, color: AppTheme.softAshGray),
                                        ),
                                      )
                                    : Container(
                                        color: AppTheme.braaiCharcoalDark,
                                        child: const Icon(Icons.outdoor_grill, color: AppTheme.softAshGray, size: 30),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.whitePure,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.braaiCharcoalDark,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          category,
                                          style: const TextStyle(
                                            color: AppTheme.softAshGray,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'R${price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: AppTheme.braaiBasteGold,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Quantity + Actions
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isOutOfStock
                                        ? Colors.red.withOpacity(0.2)
                                        : isLowStock
                                            ? AppTheme.braaiBasteGold.withOpacity(0.2)
                                            : AppTheme.braaiFireOrange.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Qty: $qty',
                                    style: TextStyle(
                                      color: isOutOfStock
                                          ? Colors.red
                                          : isLowStock
                                              ? AppTheme.braaiBasteGold
                                              : AppTheme.braaiFireOrange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () => _openEditStock(doc.id, data),
                                      child: const Icon(Icons.edit, color: AppTheme.softAshGray, size: 20),
                                    ),
                                    const SizedBox(width: 12),
                                    InkWell(
                                      onTap: () => _deleteItem(doc.id, name),
                                      child: const Icon(Icons.delete, color: Colors.red, size: 20),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddStock,
        backgroundColor: AppTheme.braaiFireOrange,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}