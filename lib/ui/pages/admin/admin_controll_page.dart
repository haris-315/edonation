// ignore_for_file: use_build_context_synchronously

import 'package:edonation/firebase/auth/admin_svc.dart';
import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminSvc _adminSvc = AdminSvc();
  Future<List<Map<String, dynamic>>>? _donorsFuture;
  Future<List<Map<String, dynamic>>>? _charitiesFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Method to fetch both donors and charities data
  void _fetchData() {
    setState(() {
      _donorsFuture = _adminSvc.viewDonors();
      _charitiesFuture = _adminSvc.viewCharities();
    });
  }

  // Method to handle user verification
  Future<void> _verifyUser(String userId, String accountType) async {
    try {
      await _adminSvc.verifyUser(userId: userId, accountType: accountType);
      _fetchData(); // Refresh data after a successful operation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User $userId verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to verify user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to handle user deletion
  Future<void> _deleteUser(String userId, String accountType) async {
    try {
      await _adminSvc.deleteUser(userId: userId, accountType: accountType);
      _fetchData(); // Refresh data after a successful operation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User $userId deleted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Widget to build the list of users
  Widget _buildUserList(
    Future<List<Map<String, dynamic>>>? future,
    String accountType,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        _fetchData();
        await future;
      },
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!;
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userId = user['userId'] as String;
              final isApproved = user['isApproved'] as bool? ?? false;
              final email = user['email'] as String? ?? 'No email';
              final name =
                  user['accountType'] == UserType.charity.name
                      ? user['charityName'] as String? ?? 'No charity name'
                      : user['firstName'] as String? ?? 'No name';

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
                  ),
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isApproved)
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _verifyUser(userId, accountType),
                          tooltip: 'Verify User',
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteUser(userId, accountType),
                        tooltip: 'Delete User',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [Tab(text: 'Donors'), Tab(text: 'Charities')],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserList(_donorsFuture, UserType.donor.name),
            _buildUserList(_charitiesFuture, UserType.charity.name),
          ],
        ),
      ),
    );
  }
}
