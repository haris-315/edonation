// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edonation/core/funcs/push_func.dart';
import 'package:edonation/firebase/auth/admin_svc.dart';
import 'package:edonation/ui/pages/auth/welcome_screen.dart';
import 'package:flutter/material.dart';

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  int _selectedIndex = 0;
  final AdminSvc _adminSvc = AdminSvc(); // Assuming AdminSvc exists

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      ProductsPage(adminSvc: _adminSvc),
      RequestsPage(adminSvc: _adminSvc),
      MembersPage(adminSvc: _adminSvc),
      MenuPage(adminSvc: _adminSvc),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: Colors.blue[800],
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: Colors.blueAccent,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          elevation: 0,
          backgroundColor: Colors.blue[800],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _widgetOptions.elementAt(_selectedIndex),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue[800],
          unselectedItemColor: Colors.grey[600],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 8,
          backgroundColor: Colors.white,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.apps), label: 'Products'),
            BottomNavigationBarItem(
              icon: Icon(Icons.handshake),
              label: 'Requests',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Members'),
            BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
          ],
        ),
      ),
    );
  }
}

class RequestsPage extends StatelessWidget {
  final AdminSvc adminSvc;
  const RequestsPage({super.key, required this.adminSvc});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Requests',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[300], thickness: 1),

          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: adminSvc.getPendingCampaignsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No new campaign requests.'));
                }

                final campaigns = snapshot.data!;
                return ListView.builder(
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = campaigns[index];
                    final campaignId =
                        campaign['campaignId'] as String? ?? 'N/A';
                    final charityName =
                        campaign['charityName'] as String? ?? 'N/A';
                    final campaignName =
                        campaign['name'] as String? ?? 'No Title';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Icon(Icons.campaign, color: Colors.blue[800]),
                        ),
                        title: Text(
                          campaignName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text('Charity: $charityName'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              onPressed:
                                  () => adminSvc.approveCampaign(
                                    campaignId: campaignId,
                                  ),
                              tooltip: 'Approve',
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed:
                                  () => adminSvc.deleteCampaign(
                                    campaignId: campaignId,
                                  ),
                              tooltip: 'Reject',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> user;
  final AdminSvc adminSvc;
  final bool isPendingRequest;

  const UserDetailScreen({
    super.key,
    required this.user,
    required this.adminSvc,
    this.isPendingRequest = false,
  });

  @override
  Widget build(BuildContext context) {
    final accountType = user['accountType'] as String? ?? 'N/A';
    final isCharity = accountType == UserType.charity.name;
    final name =
        isCharity
            ? user['charityName'] as String? ?? 'Unnamed Charity'
            : '${user['firstName'] as String? ?? ''} ${user['lastName'] as String? ?? ''}'
                .trim();
    final email = user['email'] as String? ?? 'N/A';
    final userId = user['userId'] as String? ?? 'N/A';
    final charityLogoUrl = user['charityLogoUrl'] as String?;
    final frontImageUrl = user['frontImageUrl'] as String?;
    final backImageUrl = user['backImageUrl'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCharity ? 'Charity Details' : 'Donor Details',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue[100],
                backgroundImage:
                    isCharity && charityLogoUrl != null
                        ? NetworkImage(charityLogoUrl)
                        : null,
                child:
                    isCharity && charityLogoUrl == null
                        ? Icon(
                          Icons.corporate_fare,
                          size: 60,
                          color: Colors.blue[800],
                        )
                        : !isCharity
                        ? Icon(Icons.person, size: 60, color: Colors.blue[800])
                        : null,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildDetailRow(
                      context,
                      'Name:',
                      name,
                      Icons.person_outline,
                    ),
                    _buildDetailRow(
                      context,
                      'Account Type:',
                      accountType,
                      Icons.people_outline,
                    ),
                    _buildDetailRow(
                      context,
                      'Email:',
                      email,
                      Icons.email_outlined,
                    ),
                    _buildDetailRow(
                      context,
                      'User ID:',
                      userId,
                      Icons.fingerprint,
                    ),
                  ],
                ),
              ),
            ),
            if (isCharity) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Charity Details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      _buildDetailRow(
                        context,
                        'Registration Number:',
                        user['registrationNumber'] as String? ?? 'N/A',
                        Icons.insert_drive_file_outlined,
                      ),
                      _buildDetailRow(
                        context,
                        'Address:',
                        user['address'] as String? ?? 'N/A',
                        Icons.location_on_outlined,
                      ),
                      _buildDetailRow(
                        context,
                        'Phone:',
                        user['phone'] as String? ?? 'N/A',
                        Icons.phone_outlined,
                      ),
                      if (charityLogoUrl != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Charity Logo',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            charityLogoUrl,
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                            errorBuilder:
                                (context, error, stackTrace) => const Center(
                                  child: Text('Failed to load logo'),
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ] else if (!isCharity &&
                (frontImageUrl != null || backImageUrl != null)) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Donor Identity Documents',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      if (frontImageUrl != null) ...[
                        Text(
                          'Front of Card',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            frontImageUrl,
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                            errorBuilder:
                                (context, error, stackTrace) => const Center(
                                  child: Text('Failed to load front image'),
                                ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (backImageUrl != null) ...[
                        Text(
                          'Back of Card',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Image.network(
                            backImageUrl,
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                            errorBuilder:
                                (context, error, stackTrace) => const Center(
                                  child: Text('Failed to load back image'),
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (isPendingRequest) ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        adminSvc.verifyUser(
                          userId: userId,
                          accountType: accountType,
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.check_circle, color: Colors.white),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        adminSvc.deleteUser(
                          userId: userId,
                          accountType: accountType,
                        );
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue[800], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MembersPage extends StatefulWidget {
  final AdminSvc adminSvc;
  const MembersPage({super.key, required this.adminSvc});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  bool _showApproved = true;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Members',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[300], thickness: 1),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.black87,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: [
                Container(padding: EdgeInsets.all(14), child: Text("Donors")),
                Container(
                  padding: EdgeInsets.all(14),
                  child: Text("Charities"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(
                label: const Text('Approved'),
                selected: _showApproved,
                selectedColor: Colors.blue[100],
                checkmarkColor: Colors.blue[800],
                onSelected: (bool selected) {
                  setState(() {
                    _showApproved = selected;
                  });
                },
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Unapproved'),
                selected: !_showApproved,
                selectedColor: Colors.blue[100],
                checkmarkColor: Colors.blue[800],
                onSelected: (bool selected) {
                  setState(() {
                    _showApproved = !selected;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: widget.adminSvc.getDonorsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final allDonors = snapshot.data ?? [];
                    final filteredDonors =
                        allDonors.where((donor) {
                          final isApproved =
                              donor['isApproved'] as bool? ?? false;
                          return isApproved == _showApproved;
                        }).toList();

                    if (filteredDonors.isEmpty) {
                      return Center(
                        child: Text(
                          'No ${_showApproved ? 'approved' : 'unapproved'} donors found.',
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filteredDonors.length,
                      itemBuilder: (context, index) {
                        final donor = filteredDonors[index];
                        final name =
                            '${donor['firstName'] ?? ''} ${donor['lastName'] ?? ''}'
                                .trim();
                        final isApproved =
                            donor['isApproved'] as bool? ?? false;
                        final frontImageUrl = donor['frontImageUrl'] as String?;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => UserDetailScreen(
                                        user: donor,
                                        adminSvc: widget.adminSvc,
                                        isPendingRequest: !isApproved,
                                      ),
                                ),
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              backgroundImage:
                                  frontImageUrl != null
                                      ? NetworkImage(frontImageUrl)
                                          as ImageProvider<Object>?
                                      : null,
                              child:
                                  frontImageUrl == null
                                      ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                        ),
                                      )
                                      : null,
                            ),
                            title: Text(
                              name.isNotEmpty ? name : 'Unnamed Donor',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Email: ${donor['email'] as String? ?? 'N/A'}\nStatus: ${isApproved ? 'Approved' : 'Unapproved'}',
                            ),
                            isThreeLine: true,
                            trailing:
                                isApproved
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                    : const Icon(
                                      Icons.pending,
                                      color: Colors.amber,
                                    ),
                          ),
                        );
                      },
                    );
                  },
                ),
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: widget.adminSvc.getCharitiesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    final allCharities = snapshot.data ?? [];
                    final filteredCharities =
                        allCharities.where((charity) {
                          final isApproved =
                              charity['isApproved'] as bool? ?? false;
                          return isApproved == _showApproved;
                        }).toList();

                    if (filteredCharities.isEmpty) {
                      return Center(
                        child: Text(
                          'No ${_showApproved ? 'approved' : 'unapproved'} charities found.',
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: filteredCharities.length,
                      itemBuilder: (context, index) {
                        final charity = filteredCharities[index];
                        final name = charity['charityName'] as String? ?? 'N/A';
                        final isApproved =
                            charity['isApproved'] as bool? ?? false;
                        final charityLogoUrl =
                            charity['charityLogoUrl'] as String?;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => UserDetailScreen(
                                        user: charity,
                                        adminSvc: widget.adminSvc,
                                        isPendingRequest: !isApproved,
                                      ),
                                ),
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              backgroundImage:
                                  charityLogoUrl != null
                                      ? NetworkImage(charityLogoUrl)
                                          as ImageProvider<Object>?
                                      : null,
                              child:
                                  charityLogoUrl == null
                                      ? Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                        ),
                                      )
                                      : null,
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Email: ${charity['email'] as String? ?? 'N/A'}\nStatus: ${isApproved ? 'Approved' : 'Unapproved'}',
                            ),
                            isThreeLine: true,
                            trailing:
                                isApproved
                                    ? const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    )
                                    : const Icon(
                                      Icons.pending,
                                      color: Colors.amber,
                                    ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductsPage extends StatelessWidget {
  final AdminSvc adminSvc;
  const ProductsPage({super.key, required this.adminSvc});

  void _showAddFundraiserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddFundraiserDialog(adminSvc: adminSvc);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Products',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Divider(color: Colors.grey[300], thickness: 1),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.black87,
                  unselectedLabelColor: Colors.grey[600],
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: [
                    Container(
                      padding: EdgeInsets.all(14),
                      child: Text("Campaigns"),
                    ),
                    Container(
                      padding: EdgeInsets.all(14),
                      child: Text("Funds"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: adminSvc.viewCampaignsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        final campaigns = snapshot.data ?? [];
                        if (campaigns.isEmpty) {
                          return const Center(
                            child: Text('No active campaigns found.'),
                          );
                        }
                        return ListView.builder(
                          itemCount: campaigns.length,
                          itemBuilder: (context, index) {
                            final campaign = campaigns[index];
                            final campaignId =
                                campaign['campaignId'] as String? ?? 'N/A';
                            final status =
                                campaign['status'] as String? ?? 'N/A';
                            final targetAmount =
                                campaign['targetAmount'] as double? ?? 0.0;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  campaign['name'] as String? ?? 'No Title',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Charity: ${campaign['charityName'] as String? ?? 'N/A'}\nTarget: \$${targetAmount.toStringAsFixed(2)}\nStatus: $status',
                                ),
                                isThreeLine: true,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (status != 'completed')
                                      IconButton(
                                        icon: const Icon(
                                          Icons.done_all,
                                          color: Colors.blue,
                                        ),
                                        onPressed:
                                            () => adminSvc.completeCampaign(
                                              campaignId: campaignId,
                                            ),
                                        tooltip: 'Mark as Complete',
                                      ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => adminSvc.deleteCampaign(
                                            campaignId: campaignId,
                                          ),
                                      tooltip: 'Delete Campaign',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: adminSvc.viewAdminFundraisersStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        final fundraisers = snapshot.data ?? [];
                        if (fundraisers.isEmpty) {
                          return const Center(
                            child: Text('No admin fundraisers found.'),
                          );
                        }
                        return ListView.builder(
                          itemCount: fundraisers.length,
                          itemBuilder: (context, index) {
                            final fundraiser = fundraisers[index];
                            final fundraiserId =
                                fundraiser['fundraiserId'] as String? ?? 'N/A';
                            final status =
                                fundraiser['status'] as String? ?? 'N/A';
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  fundraiser['name'] as String? ?? 'No Title',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Target: \$${(fundraiser['targetAmount'] as num? ?? 0.0).toStringAsFixed(2)}\nStatus: $status',
                                ),
                                isThreeLine: true,
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () => adminSvc.deleteAdminFundraiser(
                                        fundraiserId: fundraiserId,
                                      ),
                                  tooltip: 'Delete Fundraiser',
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _showAddFundraiserDialog(context),
              backgroundColor: Colors.blue[800],
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class AddFundraiserDialog extends StatefulWidget {
  final AdminSvc adminSvc;
  const AddFundraiserDialog({super.key, required this.adminSvc});

  @override
  State<AddFundraiserDialog> createState() => _AddFundraiserDialogState();
}

class _AddFundraiserDialogState extends State<AddFundraiserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetAmountController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  Future<void> _createFundraiser() async {
    if (_formKey.currentState!.validate()) {
      try {
        await widget.adminSvc.createAdminFundraiser(
          name: _nameController.text,
          description: _descriptionController.text,
          targetAmount: double.parse(_targetAmountController.text),
        );
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fundraiser created successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create fundraiser: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Create New Fundraiser',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Fundraiser Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetAmountController,
                decoration: InputDecoration(
                  labelText: 'Target Amount (\$)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a target amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createFundraiser,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

class MenuPage extends StatefulWidget {
  final AdminSvc adminSvc;
  const MenuPage({super.key, required this.adminSvc});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final TextEditingController _phoneController = TextEditingController();
  final String adminDocId = 'admin_data';
  String _currentPhone = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchAdminPhone();
  }

  Future<void> _fetchAdminPhone() async {
    try {
      final docSnapshot =
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(adminDocId)
              .get();
      if (docSnapshot.exists) {
        setState(() {
          _currentPhone =
              docSnapshot.data()?['phone'] as String? ?? 'Phone number not set';
        });
      }
    } catch (e) {
      setState(() {
        _currentPhone = 'Error loading phone';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load admin phone: $e')));
    }
  }

  Future<void> _updatePhone() async {
    if (_phoneController.text.isNotEmpty) {
      try {
        await widget.adminSvc.updateAdminPhone(_phoneController.text);
        _fetchAdminPhone();
        _phoneController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone number updated successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update phone: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[300], thickness: 1),
          const SizedBox(height: 16),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              title: const Text(
                'Admin Phone Number',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_currentPhone),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Update Phone Number',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'New Phone Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _updatePhone,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Update'),
            ),
          ),

          SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, mprChange(WelcomeScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[500],
                foregroundColor: const Color.fromARGB(255, 253, 240, 240),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }
}
