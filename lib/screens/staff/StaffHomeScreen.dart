// ignore_for_file: dead_code, dead_null_aware_expression, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  // TAB 1: New pending orders - staff must approve to start packing
  Stream<QuerySnapshot> _pendingOrdersStream() {
    return FirebaseFirestore.instance
      .collection('orders')
      .where('status', isEqualTo: 'pending')
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  // TAB 2: Orders being packed
  Stream<QuerySnapshot> _packingOrdersStream() {
    return FirebaseFirestore.instance
      .collection('orders')
      .where('status', isEqualTo: 'packing_up')
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  // TAB 3: Waiting for driver pickup
  Stream<QuerySnapshot> _awaitingDispatchStream() {
    return FirebaseFirestore.instance
      .collection('orders')
      .where('status', isEqualTo: 'awaiting_final_dispatch')
      .orderBy('createdAt', descending: true)
      .snapshots();
  }

  // Staff approves pending order -> starts packing
  Future<void> _startPacking(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'packing_up',
        'acceptedAt': FieldValue.serverTimestamp(),
        'approvedBy': uid,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order moved to Packing'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _approveToDrivers(String orderId) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'ready_for_driver',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': uid,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order sent to drivers'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _finalDispatch(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: const Text('Final Dispatch', style: TextStyle(color: AppTheme.whitePure)),
        content: const Text('Confirm driver has collected the order?', style: TextStyle(color: AppTheme.softAshGray)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppTheme.softAshGray))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.braaiFireOrange),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirmed!= true) return;

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'on_the_way',
        'dispatchedAt': FieldValue.serverTimestamp(),
        'dispatchedBy': uid,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order dispatched!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // Changed to 3
      child: Scaffold(
        backgroundColor: AppTheme.braaiCharcoalDark,
        appBar: AppBar(
          backgroundColor: AppTheme.braaiCoalSurface,
          title: const Text('Staff Dashboard', style: TextStyle(color: AppTheme.whitePure)),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'New Orders'), // New tab
              Tab(text: 'Pack Orders'),
              Tab(text: 'Driver Pickup'),
            ],
            labelColor: AppTheme.braaiFireOrange,
            unselectedLabelColor: AppTheme.softAshGray,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.softAshGray),
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // Tab 1: Pending orders - staff views receipt and approves
            _buildOrdersList(
              stream: _pendingOrdersStream(),
              emptyText: 'No new orders',
              emptySubtext: 'New customer orders appear here instantly',
              buttonText: 'Start Packing',
              buttonColor: Colors.red,
              onPressed: _startPacking,
              statusLabel: 'NEW',
              statusColor: Colors.red,
            ),
            // Tab 2: Packing orders
            _buildOrdersList(
              stream: _packingOrdersStream(),
              emptyText: 'No orders packing',
              emptySubtext: 'Approved orders appear here',
              buttonText: 'Approve to Drivers',
              buttonColor: AppTheme.braaiFireOrange,
              onPressed: _approveToDrivers,
              statusLabel: 'PACKING',
              statusColor: Colors.amber,
            ),
            // Tab 3: Driver pickup
            _buildOrdersList(
              stream: _awaitingDispatchStream(),
              emptyText: 'No drivers waiting',
              emptySubtext: 'Drivers appear after accepting',
              buttonText: 'Confirm & Dispatch',
              buttonColor: Colors.green,
              onPressed: _finalDispatch,
              statusLabel: 'DRIVER WAITING',
              statusColor: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList({
    required Stream<QuerySnapshot> stream,
    required String emptyText,
    required String emptySubtext,
    required String buttonText,
    required Color buttonColor,
    required Function(String) onPressed,
    required String statusLabel,
    required Color statusColor,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.braaiFireOrange));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Query Error', style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', style: const TextStyle(color: AppTheme.softAshGray, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.softAshGray),
                const SizedBox(height: 16),
                Text(emptyText, style: const TextStyle(color: AppTheme.softAshGray, fontSize: 16)),
                const SizedBox(height: 8),
                Text(emptySubtext, style: const TextStyle(color: AppTheme.mutedSlate, fontSize: 12)),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final data = order.data() as Map<String, dynamic>;
            return _buildOrderCard(order.id, data, buttonText, buttonColor, onPressed, statusLabel, statusColor);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(
    String orderId,
    Map<String, dynamic> order,
    String buttonText,
    Color buttonColor,
    Function(String) onPressed,
    String statusLabel,
    Color statusColor,
  ) {
    final customerName = order['customerName']?? 'Customer';
    final driverName = order['assignedDriverName']?? 'No driver assigned';
    final total = order['total']?.toDouble()?? 0.0;
    final items = order['items'] as List<dynamic>?? [];
    final createdAt = order['createdAt'] as Timestamp?;
    final address = order['deliveryAddress'] as String?? 'No address';

    return Card(
      color: AppTheme.braaiCoalSurface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Order #${orderId.substring(0, 6).toUpperCase()}", style: const TextStyle(color: AppTheme.whitePure, fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Customer', customerName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, 'Address', address),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.attach_money, 'Total', 'R${total.toStringAsFixed(0)}', valueColor: AppTheme.braaiBasteGold),
            if (order['status'] == 'awaiting_final_dispatch')...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.delivery_dining, 'Driver', driverName),
            ],
            if (createdAt!= null)...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.access_time, 'Placed', _formatTime(createdAt)),
            ],
            const SizedBox(height: 16),
            const Divider(color: AppTheme.softAshGray),
            const SizedBox(height: 12),
            const Text('Receipt:', style: TextStyle(color: AppTheme.whitePure, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
          ...items.map((item) {
              final itemMap = item as Map<String, dynamic>;
              final notes = itemMap['notes'] as String?? '';
              final spice = itemMap['spice'] as String?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: AppTheme.braaiFireOrange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: Text('${itemMap['quantity']}x', style: const TextStyle(color: AppTheme.braaiFireOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(itemMap['name']?? 'Item', style: const TextStyle(color: AppTheme.softAshGray))),
                        Text('R${((itemMap['price'] as num) * (itemMap['quantity'] as num)).toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.softAshGray, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    if (spice.isNotEmpty || notes.isNotEmpty)...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 36),
                        child: Text(
                          [if (spice.isNotEmpty) 'Spice: $spice', if (notes.isNotEmpty) 'Note: $notes'].join(' • '),
                          style: const TextStyle(color: AppTheme.mutedSlate, fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onPressed(orderId),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.check),
                label: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.softAshGray, size: 16),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: AppTheme.softAshGray, fontSize: 14)),
        Expanded(child: Text(value, style: TextStyle(color: valueColor?? AppTheme.whitePure, fontSize: 14, fontWeight: FontWeight.w500))),
      ],
    );
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}