// ignore_for_file: unused_import, deprecated_member_use

import 'package:flutter/material.dart';
import 'menu_screen.dart';
import '../../core/theme/app_theme.dart';
import '../cart/cart_screen.dart';
import '../orders/order_history_screen.dart';

class ShisanyamaMainScreen extends StatefulWidget {
  const ShisanyamaMainScreen({super.key});

  @override
  State<ShisanyamaMainScreen> createState() => _ShisanyamaMainScreenState();
}

class _ShisanyamaMainScreenState extends State<ShisanyamaMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MenuScreen(),
    const OrderHistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: Colors.orange.withOpacity(0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Braai Menu',
          ),
         
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Orders',
          ),
        ],
      ),
    );
  }
}