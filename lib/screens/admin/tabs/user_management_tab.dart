// ignore_for_file: unused_element, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../forms/add_driver_form.dart';

class UserManagementTab extends StatelessWidget {
  const UserManagementTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
        .collection('users')
        .snapshots(), // FIX: removed orderBy
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.braaiFireOrange));
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Error: ${snapshot.error}',
                style: const TextStyle(color: AppTheme.softAshGray),
                textAlign: TextAlign.center,
              ),
            ),
          );
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
                  final role = data['role']?.toString()?? 'customer';
                  final fullName = data['fullName']?.toString()?? 'Unknown';
                  final email = data['email']?.toString().trim()?? ''; // trim() removes that trailing space
                  final phone = data['phone']?.toString()?? '';
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
                        backgroundImage: photoUrl!= null && photoUrl.isNotEmpty? NetworkImage(photoUrl) : null,
                        child: photoUrl == null || photoUrl.isEmpty
                          ? Text(
                                fullName.isNotEmpty? fullName[0].toUpperCase() : '?',
                                style: const TextStyle(color: AppTheme.braaiFireOrange, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text(fullName, style: const TextStyle(color: AppTheme.whitePure, fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (email.isNotEmpty) Text(email, style: const TextStyle(color: AppTheme.softAshGray, fontSize: 12)),
                          if (phone.isNotEmpty)...[
                            const SizedBox(height: 2),
                            Text(phone, style: const TextStyle(color: AppTheme.softAshGray, fontSize: 12)),
                          ],
                          const SizedBox(height: 6),
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
    if (action == 'edit') {
      _showEditRoleDialog(context, docId, data['role']?? 'customer', data['fullName']?? 'User');
    } else if (action == 'delete') {
      _showDeleteUserDialog(context, docId, data['fullName']?? 'User');
    }
  }

  void _showEditRoleDialog(BuildContext context, String docId, String currentRole, String fullName) {
    String selectedRole = currentRole;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.braaiCoalSurface,
          title: Text('Edit Role: $fullName', style: const TextStyle(color: AppTheme.whitePure)),
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

  void _showDeleteUserDialog(BuildContext context, String docId, String fullName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.braaiCoalSurface,
        title: const Text('Delete User', style: TextStyle(color: AppTheme.whitePure)),
        content: Text(
          'Delete $fullName? This only removes Firestore data, not the Auth account.',
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