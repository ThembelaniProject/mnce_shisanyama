import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;

  // ADD THIS - sums all quantities
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0, (sum, item) => sum + item.total);
  double get serviceFee => subtotal * 0.05;
  double deliveryFee = 35.0;
  double driverTip = 0.0;
  double get total => subtotal + deliveryFee + serviceFee + driverTip;

  void addItem(MenuItem menuItem, {int quantity = 1, String spicePreference = 'Mild', String notes = ''}) {
    final index = _items.indexWhere((item) =>
        item.menuItem.id == menuItem.id && item.spicePreference == spicePreference && item.notes == notes);

    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(
        menuItem: menuItem,
        quantity: quantity,
        spicePreference: spicePreference,
        notes: notes,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(CartItem item, int newQty) {
    if (newQty <= 0) {
      _items.remove(item);
    } else {
      item.quantity = newQty;
    }
    notifyListeners();
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}