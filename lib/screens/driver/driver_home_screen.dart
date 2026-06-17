// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Add this
import '../../../core/theme/app_theme.dart';
import 'driver_profile_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  bool? _localOnlineState;

  Stream<DocumentSnapshot> _userStream() {
    return FirebaseFirestore.instance.collection('users').doc(uid).snapshots();
  }

  Stream<QuerySnapshot> _ordersStream() {
    return FirebaseFirestore.instance
   .collection('orders')
   .where('status', whereIn: ['ready_for_pickup', 'packing_up', 'on_the_way'])
   .orderBy('createdAt', descending: true)
   .snapshots();
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    if (uid == null) return;
    
    setState(() {
      _localOnlineState = value;
    });

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'status': value? 'Online' : 'Offline',
        'lastActive': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('driver_locations').doc(uid).set({
        'isOnline': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (mounted) {
        setState(() {
          _localOnlineState =!value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    if (uid == null) return;
    final user = FirebaseAuth.instance.currentUser;
    
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'status': 'packing_up',
      'driverId': uid,
      'driverName': user?.displayName?? 'Driver',
      'driverPhone': user?.phoneNumber?? '',
      'acceptedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order accepted! Waiting for staff to dispatch'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // New: Scan QR to confirm delivery
  Future<void> _scanQRAndDeliver(String orderId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QRScannerScreen(expectedOrderId: orderId)),
    );

    if (result == true && mounted) {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'delivered',
        'deliveredAt': FieldValue.serverTimestamp(),
      });

      if (uid!= null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'deliveries': FieldValue.increment(1),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR verified! Order delivered'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _openMap(String address) async {
    final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    }
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return const Scaffold(
        backgroundColor: AppTheme.braaiCharcoalDark,
        body: Center(child: Text('Not logged in', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      appBar: AppBar(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: const Text('Driver Dashboard', style: TextStyle(color: AppTheme.whitePure)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: AppTheme.braaiFireOrange),
            onPressed: _goToProfile,
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream(),
        builder: (context, userSnap) {
          if (!userSnap.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.braaiFireOrange));
          }

          final userData = userSnap.data!.data() as Map<String, dynamic>;
          final isOnline = _localOnlineState?? (userData['status'] == 'Online');
          final fullName = userData['fullName']?? 'Driver';
          final deliveries = userData['deliveries']?? 0;
          final rating = userData['rating']?.toDouble()?? 5.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                GestureDetector(
                  onTap: _goToProfile,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.braaiCoalSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isOnline? Colors.green : AppTheme.softAshGray,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.braaiFireOrange.withOpacity(0.2),
                              child: Text(
                                fullName.isNotEmpty? fullName[0].toUpperCase() : 'D',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.braaiFireOrange),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Hi, $fullName',
                                    style: const TextStyle(
                                      color: AppTheme.whitePure,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    )),
                                const SizedBox(height: 4),
                                Text(isOnline? 'You are Online' : 'You are Offline',
                                    style: TextStyle(
                                      color: isOnline? Colors.green : AppTheme.softAshGray,
                                      fontSize: 14,
                                    )),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: isOnline,
                          activeColor: Colors.green,
                          onChanged: _toggleOnlineStatus,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Row
                Row(
                  children: [
                    _buildStatCard('Deliveries', deliveries.toString(), Icons.local_shipping),
                    const SizedBox(width: 12),
                    _buildStatCard('Rating', rating.toStringAsFixed(1), Icons.star),
                  ],
                ),
                const SizedBox(height: 24),

                // Active Orders
                const Text('Active Orders',
                    style: TextStyle(
                      color: AppTheme.whitePure,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
                const SizedBox(height: 12),

                StreamBuilder<QuerySnapshot>(
                  stream: _ordersStream(),
                  builder: (context, orderSnap) {
                    if (!isOnline) {
                      return _buildEmptyState(Icons.power_settings_new, 'Go online to receive orders');
                    }

                    if (orderSnap.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(color: AppTheme.braaiFireOrange),
                        ),
                      );
                    }

                    if (orderSnap.hasError) {
                      return _buildEmptyState(Icons.error_outline, 'Error: ${orderSnap.error}');
                    }

                    if (!orderSnap.hasData || orderSnap.data!.docs.isEmpty) {
                      return _buildEmptyState(Icons.inbox_outlined, 'No active orders');
                    }

                    final orders = orderSnap.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final driverId = data['driverId'];
                      final status = data['status'];
                      
                      if (status == 'ready_for_pickup') {
                        return driverId == null;
                      } else {
                        return driverId == uid;
                      }
                    }).toList();

                    if (orders.isEmpty) {
                      return _buildEmptyState(Icons.inbox_outlined, 'No orders available');
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final order = orders[index].data() as Map<String, dynamic>;
                        final orderId = orders[index].id;
                        return _buildOrderCard(orderId, order);
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.braaiCoalSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.softAshGray),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(color: AppTheme.softAshGray, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.braaiCoalSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.braaiFireOrange, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                  color: AppTheme.whitePure,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                )),
            Text(label, style: const TextStyle(color: AppTheme.softAshGray, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> order) {
    final status = order['status']?? 'ready_for_pickup';
    final customerName = order['customerName']?? 'Customer';
    final address = order['deliveryAddress']?? order['address']?? 'No address';
    final total = order['total']?.toDouble()?? 0.0;
    final driverId = order['driverId'];
    final isAssignedToMe = driverId == uid;

    String buttonText = 'Accept Order';
    Color statusColor = Colors.orange;
    VoidCallback? onPressed;
    bool showMapButton = false;

    if (status == 'ready_for_pickup') {
      buttonText = 'Accept Order';
      statusColor = Colors.orange;
      onPressed = () => _acceptOrder(orderId);
    } else if (status == 'packing_up' && isAssignedToMe) {
      buttonText = 'Packing Up - Wait for Dispatch';
      statusColor = Colors.amber;
      onPressed = null;
    } else if (status == 'on_the_way' && isAssignedToMe) {
      buttonText = 'Scan Customer QR to Deliver';
      statusColor = Colors.green;
      showMapButton = true;
      onPressed = () => _scanQRAndDeliver(orderId);
    }

    String statusText = status.toUpperCase().replaceAll('_', ' ');
    if (status == 'ready_for_pickup') statusText = 'READY FOR PICKUP';
    if (status == 'packing_up') statusText = 'PACKING UP';
    if (status == 'on_the_way') statusText = 'ON THE WAY';

    return Card(
      color: AppTheme.braaiCoalSurface,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${orderId.substring(0, 6)}',
                    style: const TextStyle(
                      color: AppTheme.whitePure,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    )),
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
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, color: AppTheme.softAshGray, size: 16),
                const SizedBox(width: 8),
                Text(customerName, style: const TextStyle(color: AppTheme.whitePure)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.softAshGray, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(address,
                      style: const TextStyle(color: AppTheme.softAshGray, fontSize: 13)),
                ),
                if (showMapButton)
                  IconButton(
                    icon: const Icon(Icons.navigation, color: AppTheme.braaiFireOrange),
                    onPressed: () => _openMap(address),
                    tooltip: 'Navigate',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, color: AppTheme.softAshGray, size: 16),
                const SizedBox(width: 8),
                Text('R${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.braaiFireOrange,
                      fontWeight: FontWeight.bold,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == 'packing_up' 
                    ? Colors.amber 
                      : status == 'ready_for_pickup' 
                        ? Colors.orange 
                          : AppTheme.braaiFireOrange,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey.shade700,
                  disabledForegroundColor: Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// QR Scanner Screen
class QRScannerScreen extends StatefulWidget {
  final String expectedOrderId;
  const QRScannerScreen({super.key, required this.expectedOrderId});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Customer QR'),
        backgroundColor: AppTheme.braaiCoalSurface,
      ),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          if (_isScanned) return;
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code == widget.expectedOrderId) {
              setState(() => _isScanned = true);
              Navigator.pop(context, true);
              break;
            } else if (code!= null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Wrong QR code. Scan customer order QR'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}