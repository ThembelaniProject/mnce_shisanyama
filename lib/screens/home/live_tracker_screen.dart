import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order.item.dart';

class LiveTrackerScreen extends StatefulWidget {
  final Order order;
  const LiveTrackerScreen({super.key, required this.order});

  @override
  State<LiveTrackerScreen> createState() => _LiveTrackerScreenState();
}

class _LiveTrackerScreenState extends State<LiveTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      appBar: AppBar(title: const Text("Live Tracking")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Order #${widget.order.orderId}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.order.status, style: TextStyle(color: AppTheme.braaiFireOrange, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text("Live Map", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Custom Canvas Map
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppTheme.braaiCoalSurface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: CustomPaint(
                size: const Size(double.infinity, 220),
                painter: DeliveryMapPainter(progress: widget.order.progress),
              ),
            ),

            const SizedBox(height: 24),

            // Progress Steps
            ..._buildTrackingSteps(),

            const SizedBox(height: 24),

            // Driver Info
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.motorcycle)),
                title: Text(widget.order.driverName),
                subtitle: Text(widget.order.driverPhone),
                trailing: IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () {}),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTrackingSteps() {
    return [
      _buildStep("Order Received", true),
      _buildStep("Grilling on Coals", true),
      _buildStep("Packed & Ready", false),
      _buildStep("On the Way", false),
      _buildStep("Delivered", false),
    ];
  }

  Widget _buildStep(String title, bool completed) {
    return ListTile(
      leading: Icon(completed ? Icons.check_circle : Icons.circle_outlined, color: completed ? Colors.green : AppTheme.braaiFireOrange),
      title: Text(title),
    );
  }
}

class DeliveryMapPainter extends CustomPainter {
  final double progress;
  DeliveryMapPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    // Simple animated delivery path (you can make it more complex)
    final paint = Paint()
      ..color = AppTheme.braaiFireOrange
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.6, size.width * 0.6, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.4, size.width * 0.9, size.height * 0.2);

    canvas.drawPath(path, paint);

    // Driver position
    final driverPos = Offset(
      size.width * (0.1 + progress * 0.8),
      size.height * (0.8 - progress * 0.6),
    );
    canvas.drawCircle(driverPos, 12, Paint()..color = Colors.white);
    canvas.drawCircle(driverPos, 8, Paint()..color = AppTheme.braaiFireOrange);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}