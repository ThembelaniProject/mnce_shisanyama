import 'package:mnce_shisanyama/models/menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;
  final String spicePreference;
  final String notes;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.spicePreference = "Medium Basted",
    this.notes = "",
  });

  double get total => menuItem.price * quantity;
}