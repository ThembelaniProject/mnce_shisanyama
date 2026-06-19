// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';

class OrderTrackerScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackerScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.braaiCharcoalDark,
            body: const Center(
              child: CircularProgressIndicator(color: AppTheme.braaiFireOrange),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.braaiCharcoalDark,
            appBar: AppBar(
              backgroundColor: AppTheme.braaiCoalSurface,
              title: const Text('Order Error', style: TextStyle(color: AppTheme.whitePure)),
            ),
            body: Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: AppTheme.braaiCharcoalDark,
            appBar: AppBar(
              backgroundColor: AppTheme.braaiCoalSurface,
              title: const Text('Order Not Found', style: TextStyle(color: AppTheme.whitePure)),
            ),
            body: const Center(
              child: Text(
                'This order no longer exists',
                style: TextStyle(color: AppTheme.softAshGray),
              ),
            ),
          );
        }
        
        final order = snapshot.data!.data() as Map<String, dynamic>;
        final status = order['status'] as String;
        final driverName = order['assignedDriverName'] as String?;
        
        return Scaffold(
          backgroundColor: AppTheme.braaiCharcoalDark,
          appBar: AppBar(
            backgroundColor: AppTheme.braaiCoalSurface,
            title: Text(
              'Order #${orderId.substring(0, 6).toUpperCase()}',
              style: const TextStyle(color: AppTheme.whitePure),
            ),
            automaticallyImplyLeading: false,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildStatusAnimation(status),
                  const SizedBox(height: 32),
                  _buildStatusText(status, driverName),
                  const SizedBox(height: 40),
                  if (status == 'on_the_way') ...[
                    _buildQRSection(),
                    const SizedBox(height: 32),
                  ],
                  _buildOrderDetails(order),
                  const SizedBox(height: 40),
                  if (status == 'delivered')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.braaiFireOrange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusAnimation(String status) {
    String? lottiePath;
    switch (status) {
      case 'pending':
      case 'packing_up':
        lottiePath = 'assets/lotties/packing.json';
        break;
      case 'on_the_way':
        lottiePath = 'assets/lotties/delivery.json';
        break;
      case 'delivered':
        lottiePath = 'assets/lotties/success.json';
        break;
    }

    if (lottiePath == null) {
      return const Icon(Icons.local_fire_department, size: 120, color: AppTheme.braaiFireOrange);
    }

    return Lottie.asset(
      lottiePath,
      width: 200,
      height: 200,
      repeat: status != 'delivered',
      errorBuilder: (context, error, stackTrace) {
        return const Icon(Icons.local_fire_department, size: 120, color: AppTheme.braaiFireOrange);
      },
    );
  }

  Widget _buildStatusText(String status, String? driverName) {
    String title, subtitle;
    switch (status) {
      case 'pending':
        title = 'Order Confirmed';
        subtitle = 'Waiting for kitchen to start';
        break;
      case 'packing_up':
        title = 'Packing Your Order';
        subtitle = 'Our team is preparing your braai';
        break;
      case 'on_the_way':
        title = 'On The Way';
        subtitle = driverName != null ? 'Driver $driverName is coming' : 'Driver is on the way';
        break;
      case 'delivered':
        title = 'Delivered';
        subtitle = 'Enjoy your meal!';
        break;
      default:
        title = status.toUpperCase();
        subtitle = 'Processing...';
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.whitePure,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.softAshGray,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQRSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.braaiCoalSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.braaiFireOrange, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            'Show this QR to driver',
            style: TextStyle(
              color: AppTheme.whitePure,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: orderId,
              size: 180,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Driver will scan this on delivery',
            style: TextStyle(color: AppTheme.softAshGray, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(Map<String, dynamic> order) {
    final items = order['items'] as List<dynamic>? ?? [];
    final total = (order['total'] as num?)?.toDouble() ?? 0.0;
    final address = order['deliveryAddress'] as String? ?? 'No address';

    return Card(
      color: AppTheme.braaiCoalSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(
                color: AppTheme.whitePure,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final itemMap = item as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${itemMap['quantity']}x ${itemMap['name']}',
                        style: const TextStyle(color: AppTheme.softAshGray),
                      ),
                    ),
                    Text(
                      'R${((itemMap['price'] as num) * (itemMap['quantity'] as num)).toStringAsFixed(0)}',
                      style: const TextStyle(color: AppTheme.softAshGray),
                    ),
                  ],
                ),
              );
            }),
            const Divider(color: AppTheme.softAshGray),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(color: AppTheme.whitePure, fontWeight: FontWeight.bold)),
                Text(
                  'R${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.braaiBasteGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: AppTheme.braaiFireOrange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: const TextStyle(color: AppTheme.softAshGray, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}