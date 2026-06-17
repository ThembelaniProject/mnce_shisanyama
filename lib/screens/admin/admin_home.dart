// ignore_for_file: duplicate_ignore, undefined_hidden_name, undefined_hidden_name, invalid_use_of_protected_member, unused_import, unused_element, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../admin/forms/add_driver_form.dart';
import '../admin/admin_profile_screen.dart';
import '../admin/tabs/stock_tab_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardTab(),
    const UserManagementTab(),
    const StockTabScreen(), // Only once, not duplicated
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.braaiCharcoalDark,
      appBar: AppBar(
        backgroundColor: AppTheme.braaiCoalSurface,
        elevation: 0,
        title: const Text(
          'Braai Admin',
          style: TextStyle(color: AppTheme.whitePure, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppTheme.braaiFireOrange),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminProfileScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        backgroundColor: AppTheme.braaiCoalSurface,
        selectedItemColor: AppTheme.braaiFireOrange,
        unselectedItemColor: AppTheme.softAshGray,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Stock'),
        ],
      ),
    );
  }
}

// DASHBOARD TAB - Firebase - Fixed to use menu_items
class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, orderSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'driver').snapshots(),
          builder: (context, driverSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              // Changed from 'stock' to 'menu_items' and check quantity <= 5
              stream: FirebaseFirestore.instance
                  .collection('menu_items')
                  .where('quantity', isLessThanOrEqualTo: 5)
                  .snapshots(),
              builder: (context, stockSnapshot) {
                final totalOrders = orderSnapshot.data?.docs.length ?? 0;
                final activeDrivers = driverSnapshot.data?.docs.length ?? 0;
                final pendingStock = stockSnapshot.data?.docs.length ?? 0;

                double revenue = 0;
                if (orderSnapshot.hasData) {
                  for (var doc in orderSnapshot.data!.docs) {
                    revenue += (doc.data() as Map<String, dynamic>)['total'] ?? 0;
                  }
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Today Overview',
                      style: TextStyle(color: AppTheme.whitePure, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _buildStatCard('Total Orders', totalOrders.toString(), Icons.receipt_long, AppTheme.braaiFireOrange),
                        _buildStatCard('Revenue', 'R${revenue.toInt()}', Icons.payments, AppTheme.braaiBasteGold),
                        _buildStatCard('Total Drivers', activeDrivers.toString(), Icons.delivery_dining, Colors.green),
                        _buildStatCard('Low Stock', pendingStock.toString(), Icons.inventory, Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(color: AppTheme.whitePure, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildActionTile('Add New User', Icons.person_add, () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddDriverForm()));
                    }),
                    _buildActionTile('Update Menu Items', Icons.restaurant_menu, () {
                      // Switch to Stock tab instead of opening AddStockScreen directly
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const StockTabScreen()));
                    }),
                    _buildActionTile('View Sales Report', Icons.bar_chart, () {}),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.braaiCoalSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(color: AppTheme.whitePure, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(title, style: const TextStyle(color: AppTheme.softAshGray, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return Card(
      color: AppTheme.braaiCoalSurface,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.braaiFireOrange),
        title: Text(title, style: const TextStyle(color: AppTheme.whitePure)),
        trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.softAshGray, size: 16),
        onTap: onTap,
      ),
    );
  }
}

// USER TAB - Shows all users from Firestore
class UserManagementTab extends StatelessWidget {
  const UserManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading users: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.braaiFireOrange));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No users found', style: TextStyle(color: AppTheme.softAshGray)),
          );
        }

        final users = snapshot.data!.docs;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Users (${users.length})',
                    style: const TextStyle(color: AppTheme.whitePure, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddDriverForm()),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.braaiFireOrange,
                      foregroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final data = users[index].data() as Map<String, dynamic>;
                  
                  final role = data['role']?.toString() ?? 'customer';
                  final name = data['name']?.toString() ?? 'No Name';
                  final email = data['email']?.toString() ?? '';
                  final photoUrl = data['photoUrl']?.toString();

                  Color roleColor = AppTheme.softAshGray;
                  if (role == 'admin') roleColor = AppTheme.braaiFireOrange;
                  if (role == 'driver') roleColor = Colors.green;
                  if (role == 'customer') roleColor = AppTheme.braaiBasteGold;

                  return Card(
                    color: AppTheme.braaiCoalSurface,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.braaiCharcoalDark,
                        backgroundImage: photoUrl != null && photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl == null || photoUrl.isEmpty
                           ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppTheme.braaiFireOrange, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text(name, style: const TextStyle(color: AppTheme.whitePure, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (email.isNotEmpty) Text(email, style: const TextStyle(color: AppTheme.softAshGray, fontSize: 12)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              role.toUpperCase(),
                              style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppTheme.softAshGray),
                        color: AppTheme.braaiCoalSurface,
                        onSelected: (value) => _handleUserAction(context, value, users[index].id, data),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: AppTheme.braaiFireOrange, size: 20),
                                SizedBox(width: 8),
                                Text('Edit Role', style: TextStyle(color: AppTheme.whitePure)),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleUserAction(BuildContext context, String action, String docId, Map<String, dynamic> data) {
    final name = data['name']?.toString() ?? 'User';
    final role = data['role']?.toString() ?? 'customer';
    
    if (action == 'edit') {
      _showEditRoleDialog(context, docId, role, name);
    } else if (action == 'delete') {
      _showDeleteUserDialog(context, docId, name);
    }
  }

  void _showEditRoleDialog(BuildContext context, String docId, String currentRole, String name) {
    String selectedRole = currentRole;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.braaiCoalSurface,
          title: Text('Edit Role: $name', style: const TextStyle(color: AppTheme.whitePure)),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            dropdownColor: AppTheme.braaiCharcoalDark,
            style: const TextStyle(color: AppTheme.whitePure),
            decoration: InputDecoration(
              labelText: 'Role',
              labelStyle: const TextStyle(color: AppTheme.softAshGray),
              filled: true,
              fillColor: AppTheme.braaiCharcoalDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
            items: ['customer', 'driver', 'admin']
               .map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase())))
               .toList(),
            onChanged: (val) => setDialogState(() => selectedRole = val!),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.softAshGray)),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('users').doc(docId).update({'role': selectedRole});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Role updated'), backgroundColor: Colors.green),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.braaiFireOrange),
              child: const Text('Save', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteUserDialog(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: const Text('Delete User', style: TextStyle(color: AppTheme.whitePure)),
        content: Text(
          'Delete $name? This only removes Firestore data, not the Auth account.',
          style: const TextStyle(color: AppTheme.softAshGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.softAshGray)),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('users').doc(docId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User deleted'), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Delete the old MerchandiserTab - you're using StockTabScreen now