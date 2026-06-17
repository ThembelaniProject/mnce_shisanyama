// ignore_for_file: unused_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.item.dart';
import '../orders/orderTrackerScreen.dart'; // Import your tracker screen

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> with SingleTickerProviderStateMixin {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Stream<QuerySnapshot> _activeOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: uid) // Change to 'userId' if that's your field
        .where('status', whereIn: ['packing_up', 'on_the_way'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _historyOrdersStream() {
    return FirebaseFirestore.instance
        .collection('orders')
        .where('customerId', isEqualTo: uid)
        .where('status', isEqualTo: 'delivered')
        .orderBy('deliveredAt', descending: true)
        .snapshots();
  }

  void _navigateToTracker(String orderId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackerScreen(orderId: orderId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return Scaffold(
        backgroundColor: AppTheme.braaiCharcoalDark,
        appBar: AppBar(title: const Text("My Orders")),
        body: const Center(child: Text('Not logged in', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      appBar: AppBar(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: const Text("My Orders", style: TextStyle(color: AppTheme.whitePure)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.braaiFireOrange,
          labelColor: AppTheme.braaiFireOrange,
          unselectedLabelColor: AppTheme.softAshGray,
          tabs: const [
            Tab(text: "Active"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrderList(_activeOrdersStream(), isActive: true),
          _buildOrderList(_historyOrdersStream(), isActive: false),
        ],
      ),
    );
  }

  Widget _buildOrderList(Stream<QuerySnapshot> stream, {required bool isActive}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.braaiFireOrange),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.softAshGray),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.receipt_long : Icons.history,
                  size: 64,
                  color: AppTheme.softAshGray,
                ),
                const SizedBox(height: 16),
                Text(
                  isActive ? 'No active orders' : 'No order history',
                  style: const TextStyle(color: AppTheme.softAshGray, fontSize: 16),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final data = orders[index].data() as Map<String, dynamic>;
            final orderId = orders[index].id;
            return _buildOrderCard(orderId, data, isActive);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> order, bool isActive) {
    final status = order['status'] ?? 'unknown';
    final total = order['total']?.toDouble() ?? 0.0;
    final driverName = order['driverName'] ?? 'Assigning driver...';
    final itemsSummary = order['itemsSummary'] ?? _buildItemsSummary(order['items']);
    final timestamp = order['createdAt'] as Timestamp?;
    final deliveredAt = order['deliveredAt'] as Timestamp?;

    Color statusColor = Colors.orange;
    String statusText = status.toUpperCase().replaceAll('_', ' ');
    
    if (status == 'packing_up') {
      statusColor = Colors.amber;
      statusText = 'PACKING UP';
    } else if (status == 'on_the_way') {
      statusColor = Colors.blue;
      statusText = 'ON THE WAY';
    } else if (status == 'delivered') {
      statusColor = Colors.green;
      statusText = 'DELIVERED';
    }

    return Card(
      color: AppTheme.braaiCoalSurface,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order #${orderId.substring(0, 6)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.whitePure,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              itemsSummary,
              style: const TextStyle(color: AppTheme.softAshGray),
            ),
            const SizedBox(height: 12),
            if (isActive && driverName != 'Assigning driver...') ...[
              Row(
                children: [
                  const Icon(Icons.person, color: AppTheme.softAshGray, size: 16),
                  const SizedBox(width: 8),
                  Text(driverName, style: const TextStyle(color: AppTheme.whitePure)),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "R${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.braaiBasteGold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(isActive ? timestamp : deliveredAt),
                      style: const TextStyle(color: AppTheme.softAshGray, fontSize: 12),
                    ),
                  ],
                ),
                if (isActive)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.braaiFireOrange,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => _navigateToTracker(orderId),
                    icon: const Icon(Icons.timeline, size: 18),
                    label: const Text("Track Progress"),
                  )
                else
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.braaiFireOrange,
                      side: const BorderSide(color: AppTheme.braaiFireOrange),
                    ),
                    onPressed: () {
                      // Reorder functionality
                    },
                    child: const Text("Reorder"),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _buildItemsSummary(dynamic items) {
    if (items == null || items is! List) return 'No items';
    return items.take(2).map((e) => '${e['name']} x${e['quantity']}').join(', ');
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}