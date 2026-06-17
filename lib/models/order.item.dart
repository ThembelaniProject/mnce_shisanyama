class Order {
  final String orderId;
  final String status;
  final double totalAmount;
  final String driverName;
  final String driverPhone;
  final String itemsSummary;
  final int timestamp;
  double progress;

  Order({
    required this.orderId,
    required this.status,
    required this.totalAmount,
    required this.driverName,
    required this.driverPhone,
    required this.itemsSummary,
    required this.timestamp,
    this.progress = 0.0,
  });
}