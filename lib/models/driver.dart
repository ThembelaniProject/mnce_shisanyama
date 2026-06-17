class Driver {
  final String id;
  final String name;
  final String phone;
  final String vehicle;
  final String status; // Active, On Break, Offline
  final int deliveries;
  final double rating;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    this.status = 'Offline',
    this.deliveries = 0,
    this.rating = 5.0,
  });
}