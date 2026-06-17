import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';

class OrderTrackerScreen extends StatelessWidget {
  final String orderId;
  const OrderTrackerScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').doc(orderId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final order = snapshot.data!.data() as Map<String, dynamic>;
        final status = order['status'];
        
        return Scaffold(
          appBar: AppBar(title: Text('Order #${orderId.substring(0, 6)}')),
          body: Column(
            children: [
              if (status == 'packing_up')
                Lottie.asset('assets/lotties/packing.json'),
              if (status == 'on_the_way') ...[
                Lottie.asset('assets/lotties/delivery.json'),
                const SizedBox(height: 20),
                const Text('Show this QR to driver'),
                QrImageView(data: orderId, size: 200),
              ],
              Text('Status: ${status.toUpperCase()}'),
            ],
          ),
        );
      },
    );
  }
}