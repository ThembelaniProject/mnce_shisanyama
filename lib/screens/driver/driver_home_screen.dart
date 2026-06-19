// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rxdart/rxdart.dart';
import '../../core/theme/app_theme.dart';
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

  // SPLIT QUERY TO AVOID PERMISSION DENIED
  Stream<List<QueryDocumentSnapshot>> _ordersStream() {
    if (uid == null) return Stream.value([]);

    // Stream 1: Unassigned orders all drivers can see
    final availableStream = FirebaseFirestore.instance
       .collection('orders')
       .where('status', whereIn: ['packing_up', 'ready_for_driver'])
       .orderBy('createdAt', descending: true)
       .snapshots();

    // Stream 2: Orders assigned to this driver only
    final myStream = FirebaseFirestore.instance
       .collection('orders')
       .where('assignedDriver', isEqualTo: uid)
       .where('status', whereIn: ['awaiting_final_dispatch', 'on_the_way'])
       .orderBy('createdAt', descending: true)
       .snapshots();

    return Rx.combineLatest2(
      availableStream,
      myStream,
      (QuerySnapshot available, QuerySnapshot mine) {
        final allDocs = [...available.docs,...mine.docs];
        allDocs.sort((a, b) {
          final aTime = (a.data() as Map)['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map)['createdAt'] as Timestamp?;
          return (bTime?? Timestamp(0, 0)).compareTo(aTime?? Timestamp(0, 0));
        });
        return allDocs;
      },
    );
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
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'awaiting_final_dispatch',
        'assignedDriver': uid,
        'assignedDriverName': userDoc.data()?['fullName']?? user?.displayName?? 'Driver',
        'driverPhone': user?.phoneNumber?? '',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order accepted! Waiting for staff handover'), backgroundColor: Colors.orange),
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

  Future<void> _scanQRAndDeliver(String orderId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QRScannerScreen(expectedOrderId: orderId)),
    );

    if (result == true && mounted) {
      try {
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
          const SnackBar(content: Text('QR verified! Order delivered'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
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

  void _goToDeliveryHistory() {
    if (uid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DriverDeliveryHistoryScreen(driverId: uid!)),
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
                GestureDetector(
                  onTap: _goToProfile,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.braaiCoalSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isOnline? Colors.green : AppTheme.softAshGray, width: 2),
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
                                Text('Hi, $fullName', style: const TextStyle(color: AppTheme.whitePure, fontSize: 22, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(isOnline? 'You are Online' : 'You are Offline', style: TextStyle(color: isOnline? Colors.green : AppTheme.softAshGray, fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                        Switch(value: isOnline, activeColor: Colors.green, onChanged: _toggleOnlineStatus),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard('Deliveries', deliveries.toString(), Icons.local_shipping, _goToDeliveryHistory),
                    const SizedBox(width: 12),
                    _buildStatCard('Rating', rating.toStringAsFixed(1), Icons.star, null),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Active Orders', style: TextStyle(color: AppTheme.whitePure, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                StreamBuilder<List<QueryDocumentSnapshot>>(
                  stream: _ordersStream(),
                  builder: (context, orderSnap) {
                    if (!isOnline) {
                      return _buildEmptyState(Icons.power_settings_new, 'Go online to receive orders');
                    }

                    if (orderSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppTheme.braaiFireOrange)));
                    }

                    if (orderSnap.hasError) {
                      return _buildEmptyState(Icons.error_outline, 'Error: ${orderSnap.error}');
                    }

                    if (!orderSnap.hasData || orderSnap.data!.isEmpty) {
                      return _buildEmptyState(Icons.inbox_outlined, 'No active orders');
                    }

                    final orders = orderSnap.data!;

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
      decoration: BoxDecoration(color: AppTheme.braaiCoalSurface, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppTheme.softAshGray),
          const SizedBox(height: 12),
          Text(text, style: const TextStyle(color: AppTheme.softAshGray, fontSize: 16), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, VoidCallback? onTap) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.braaiCoalSurface,
        borderRadius: BorderRadius.circular(12),
        border: onTap!= null? Border.all(color: AppTheme.braaiFireOrange.withOpacity(0.3)) : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.braaiFireOrange, size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: AppTheme.whitePure, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppTheme.softAshGray, fontSize: 12)),
        ],
      ),
    );

    return Expanded(
      child: onTap!= null
         ? InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: card)
          : card,
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> order) {
    final status = order['status']?? 'packing_up';
    final customerName = order['customerName']?? 'Customer';
    final address = order['deliveryAddress']?? 'No address';
    final total = order['total']?.toDouble()?? 0.0;
    final assignedDriver = order['assignedDriver'];
    final isAssignedToMe = assignedDriver == uid;

    String buttonText = 'Accept Order';
    Color statusColor = Colors.blue;
    VoidCallback? onPressed;
    bool showMapButton = false;

    if (status == 'packing_up') {
      buttonText = 'Accept Order';
      statusColor = Colors.blue;
      onPressed = () => _acceptOrder(orderId);
    } else if (status == 'ready_for_driver') {
      buttonText = 'Accept Order';
      statusColor = Colors.orange;
      onPressed = () => _acceptOrder(orderId);
    } else if (status == 'awaiting_final_dispatch' && isAssignedToMe) {
      buttonText = 'Waiting for Staff Handover';
      statusColor = Colors.amber;
      onPressed = null;
    } else if (status == 'on_the_way' && isAssignedToMe) {
      buttonText = 'Scan Customer QR to Deliver';
      statusColor = Colors.green;
      showMapButton = true;
      onPressed = () => _scanQRAndDeliver(orderId);
    }

    String statusText = status.toUpperCase().replaceAll('_', ' ');
    if (status == 'packing_up') statusText = 'PACKING';
    if (status == 'ready_for_driver') statusText = 'READY FOR PICKUP';
    if (status == 'awaiting_final_dispatch') statusText = 'WAITING STAFF';
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
                Text('Order #${orderId.substring(0, 6)}', style: const TextStyle(color: AppTheme.whitePure, fontSize: 16, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
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
                Expanded(child: Text(address, style: const TextStyle(color: AppTheme.softAshGray, fontSize: 13))),
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
                Text('R${total.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.braaiFireOrange, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
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
      appBar: AppBar(title: const Text('Scan Customer QR'), backgroundColor: AppTheme.braaiCoalSurface),
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
                const SnackBar(content: Text('Wrong QR code. Scan customer order QR'), backgroundColor: Colors.red),
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

class DriverDeliveryHistoryScreen extends StatelessWidget {
  final String driverId;
  const DriverDeliveryHistoryScreen({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      appBar: AppBar(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: const Text('Delivery History', style: TextStyle(color: AppTheme.whitePure)),
        iconTheme: const IconThemeData(color: AppTheme.whitePure),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
           .collection('orders')
           .where('assignedDriver', isEqualTo: driverId)
           .where('status', isEqualTo: 'delivered')
           .orderBy('deliveredAt', descending: true)
           .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.braaiFireOrange));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: AppTheme.softAshGray),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppTheme.softAshGray),
                  SizedBox(height: 16),
                  Text('No deliveries yet', style: TextStyle(color: AppTheme.softAshGray, fontSize: 16)),
                ],
              ),
            );
          }

          final deliveries = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: deliveries.length,
            itemBuilder: (context, index) {
              final data = deliveries[index].data() as Map<String, dynamic>;
              final orderId = deliveries[index].id;
              final customerName = data['customerName']?? 'Customer';
              final address = data['deliveryAddress']?? 'No address';
              final total = data['total']?.toDouble()?? 0.0;
              final deliveredAt = (data['deliveredAt'] as Timestamp?)?.toDate();

              return Card(
                color: AppTheme.braaiCoalSurface,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.check, color: Colors.white),
                  ),
                  title: Text(
                    'Order #${orderId.substring(0, 6)}',
                    style: const TextStyle(color: AppTheme.whitePure, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(customerName, style: const TextStyle(color: AppTheme.softAshGray)),
                      Text(
                        address,
                        style: const TextStyle(color: AppTheme.softAshGray, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (deliveredAt!= null)
                        Text(
                          '${deliveredAt.day}/${deliveredAt.month}/${deliveredAt.year} ${deliveredAt.hour}:${deliveredAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: AppTheme.softAshGray, fontSize: 11),
                        ),
                    ],
                  ),
                  trailing: Text(
                    'R${total.toStringAsFixed(2)}',
                    style: const TextStyle(color: AppTheme.braaiFireOrange, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}