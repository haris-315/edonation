// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edonation/core/funcs/push_func.dart';
import 'package:edonation/firebase/auth/auth_svc.dart';
import 'package:edonation/services.dart';
import 'package:edonation/ui/pages/auth/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ================================================================
/// 1.  SERVICE  CLASS
/// ================================================================

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Streams for donor page
  Stream<List<Campaign>> getActiveCampaignsStream() => _firestore
      .collection('campaigns')
      .snapshots()
      .map((qs) => qs.docs.map((doc) => Campaign.fromFirestore(doc)).toList());

  Stream<List<Fundraiser>> getActiveFundraisersStream() => _firestore
      .collection('adminFundraisers')
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map(
        (qs) => qs.docs.map((doc) => Fundraiser.fromFirestore(doc)).toList(),
      );

  Stream<List<Donation>> getDonationHistoryStream({required String donorId}) =>
      _firestore
          .collection('donationHistory')
          .where('donorId', isEqualTo: donorId)
          .snapshots()
          .map(
            (qs) => qs.docs.map((doc) => Donation.fromFirestore(doc)).toList(),
          );

  // Stream for admin notifications
  Stream<List<NotificationItem>> getNotificationsStream() => _firestore
      .collection('notifications')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map(
        (qs) =>
            qs.docs.map((doc) => NotificationItem.fromFirestore(doc)).toList(),
      );

  // User methods
  Future<Map<String, dynamic>> getOrCreateUser({
    required String donorId,
  }) async {
    final userRef = _firestore.collection('users').doc(donorId);
    final userDoc = await userRef.get();
    if (userDoc.exists) {
      return userDoc.data()!;
    } else {
      final newUser = {
        'name': 'Anonymous Donor',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await userRef.set(newUser);
      return newUser;
    }
  }

  // New contribution and transaction methods
  Future<void> contributeToCampaign({
    required String campaignId,
    required double amount,
    required String donorId,
  }) async {
    final campaignRef = _firestore.collection('campaigns').doc(campaignId);
    await _firestore.runTransaction((transaction) async {
      final campaignSnap = await transaction.get(campaignRef);
      if (!campaignSnap.exists) {
        throw Exception("Campaign does not exist!");
      }
      final campaign = Campaign.fromFirestore(campaignSnap);
      final newAmount = campaign.currentAmount + amount;
      final newDonations = campaign.currentDonations + 1;
      transaction.update(campaignRef, {
        'currentAmount': newAmount,
        'currentDonations': newDonations,
      });
      await recordDonation(
        donorId: donorId,
        itemId: campaignId,
        amount: amount,
        type: 'Campaign',
        itemName: campaign.name,
      );
      await sendNotification(
        donorId: donorId,
        amount: amount,
        itemName: campaign.name,
        itemType: 'Campaign',
      );
    });
  }

  Future<void> contributeToFundraiser({
    required String fundraiserId,
    required double amount,
    required String donorId,
  }) async {
    final fundraiserRef = _firestore
        .collection('fundraisers')
        .doc(fundraiserId);
    await _firestore.runTransaction((transaction) async {
      final fundraiserSnap = await transaction.get(fundraiserRef);
      if (!fundraiserSnap.exists) {
        throw Exception("Fundraiser does not exist!");
      }
      final fundraiser = Fundraiser.fromFirestore(fundraiserSnap);
      final newAmount = fundraiser.currentAmount + amount;
      final newDonations = fundraiser.currentDonations + 1;
      transaction.update(fundraiserRef, {
        'currentAmount': newAmount,
        'currentDonations': newDonations,
      });
      await recordDonation(
        donorId: donorId,
        itemId: fundraiserId,
        amount: amount,
        type: 'Fundraiser',
        itemName: fundraiser.name,
      );
      await sendNotification(
        donorId: donorId,
        amount: amount,
        itemName: fundraiser.name,
        itemType: 'Fundraiser',
      );
    });
  }

  Future<void> recordDonation({
    required String donorId,
    required String itemId,
    required double amount,
    required String type,
    required String itemName,
  }) async {
    await _firestore.collection('donationHistory').add({
      'donorId': donorId,
      'itemId': itemId,
      'itemName': itemName,
      'amount': amount,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendNotification({
    required String donorId,
    required double amount,
    required String itemName,
    required String itemType,
  }) async {
    final userDoc = await _firestore.collection('users').doc(donorId).get();
    final donorName = userDoc.data()?['name'] ?? 'Anonymous Donor';

    await _firestore.collection('notifications').add({
      'title': 'New Donation!',
      'message':
          'New donation from $donorName of amount \$${amount.toStringAsFixed(2)} to $itemName.',
      'donorId': donorId,
      'amount': amount,
      'itemType': itemType,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Payment method saving logic
  Future<void> savePaymentMethod({
    required Map<String, dynamic> cardDetails,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('paymentMethod', cardDetails['cardNumber'] as String);
  }

  Future<String?> getPaymentMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('paymentMethod');
  }

  Future<String> getDonorId() async {
    final prefs = await SharedPreferences.getInstance();
    var donorId = prefs.getString('donorId');
    if (donorId == null) {
      donorId = 'donor_${Random().nextInt(999999)}';
      await prefs.setString('donorId', donorId);
      // Ensure user document is created for new donor
      await getOrCreateUser(donorId: donorId);
    }
    return donorId;
  }
}

/// ================================================================
/// 2.  MODEL  CLASSES
/// ================================================================

class Campaign {
  final String campaignId;
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final int currentDonations;
  final String charityName;
  final String status;

  Campaign({
    required this.campaignId,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.currentDonations,
    required this.charityName,
    required this.status,
  });

  factory Campaign.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Campaign(
      campaignId: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      targetAmount: (d['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (d['currentAmount'] as num?)?.toDouble() ?? 0.0,
      currentDonations: d['currentDonations'] as int? ?? 0,
      charityName: d['charityName'] ?? 'Unknown Charity',
      status: d['status'] ?? 'inactive',
    );
  }
}

class Fundraiser {
  final String fundraiserId;
  final String name;
  final String description;
  final double targetAmount;
  final double currentAmount;
  final int currentDonations;
  final String status;

  Fundraiser({
    required this.fundraiserId,
    required this.name,
    required this.description,
    required this.targetAmount,
    required this.currentAmount,
    required this.currentDonations,
    required this.status,
  });

  factory Fundraiser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Fundraiser(
      fundraiserId: doc.id,
      name: d['name'] ?? '',
      description: d['description'] ?? '',
      targetAmount: (d['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (d['currentAmount'] as num?)?.toDouble() ?? 0.0,
      currentDonations: d['currentDonations'] as int? ?? 0,
      status: d['status'] ?? 'inactive',
    );
  }
}

class Donation {
  final String donationId;
  final String donorId;
  final String itemId;
  final String itemName;
  final double amount;
  final String type;
  final Timestamp timestamp;

  Donation({
    required this.donationId,
    required this.donorId,
    required this.itemId,
    required this.itemName,
    required this.amount,
    required this.type,
    required this.timestamp,
  });

  factory Donation.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Donation(
      donationId: doc.id,
      donorId: d['donorId'] ?? '',
      itemId: d['itemId'] ?? '',
      itemName: d['itemName'] ?? '',
      amount: (d['amount'] as num?)?.toDouble() ?? 0.0,
      type: d['type'] ?? '',
      timestamp: d['timestamp'] ?? Timestamp.now(),
    );
  }
}

class NotificationItem {
  final String notificationId;
  final String title;
  final String message;
  final Timestamp timestamp;

  NotificationItem({
    required this.notificationId,
    required this.title,
    required this.message,
    required this.timestamp,
  });

  factory NotificationItem.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return NotificationItem(
      notificationId: doc.id,
      title: d['title'] ?? '',
      message: d['message'] ?? '',
      timestamp: d['timestamp'] ?? Timestamp.now(),
    );
  }
}

/// ================================================================
/// 3.  WIDGETS  AND  SCREENS
/// ================================================================

class DonorApp extends StatelessWidget {
  const DonorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF1976D2),
        scaffoldBackgroundColor: const Color(0xFFF0F2F5),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF1976D2),
          unselectedItemColor: Colors.black54,
          elevation: 8,
        ),
      ),
      home: const DonorMainScreen(),
    );
  }
}

class DonorMainScreen extends StatefulWidget {
  const DonorMainScreen({super.key});

  @override
  State<DonorMainScreen> createState() => _DonorMainScreenState();
}

class _DonorMainScreenState extends State<DonorMainScreen> {
  int _selectedIndex = 0; // Default to 'Home' screen
  final FirebaseService _service = FirebaseService();
  String? _donorId;

  late List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _loadDonorId();
  }

  void _loadDonorId() async {
    final id = await _service.getDonorId();
    setState(() {
      _donorId = id;
      _widgetOptions = <Widget>[
        HomePage(service: _service, donorId: _donorId!),
        DonatePage(service: _service, donorId: _donorId!),
        ProfilePage(service: _service, donorId: _donorId!),
      ];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_donorId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Charity App',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Donate'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final FirebaseService service;
  final String donorId;

  const HomePage({super.key, required this.service, required this.donorId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDonationHistorySection(context),
            const SizedBox(height: 24),
            // _buildNotificationsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDonationHistorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Donation History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<Donation>>(
          stream: service.getDonationHistoryStream(donorId: donorId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final donations = snapshot.data ?? [];
            if (donations.isEmpty) {
              return const Center(
                child: Text('You have not made any donations yet.'),
              );
            }
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: donations.length,
              itemBuilder: (context, index) {
                final donation = donations[index];
                return DonationHistoryCard(donation: donation);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<NotificationItem>>(
          stream: service.getNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final notifications = snapshot.data ?? [];
            if (notifications.isEmpty) {
              return const Center(child: Text('No new notifications.'));
            }
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationCard(notification: notification);
              },
            );
          },
        ),
      ],
    );
  }
}

class DonationHistoryCard extends StatelessWidget {
  final Donation donation;
  const DonationHistoryCard({super.key, required this.donation});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: Icon(
          donation.type == 'Campaign' ? Icons.favorite : Icons.people,
          color: const Color(0xFF1976D2),
        ),
        title: Text(
          'Donated to: ${donation.itemName}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Amount: \$${donation.amount.toStringAsFixed(2)}\nDate: ${donation.timestamp.toDate().toLocal().toString().split(' ')[0]}',
        ),
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      color: Colors.lightBlue.shade50,
      child: ListTile(
        leading: const Icon(Icons.notifications_active, color: Colors.blue),
        title: Text(
          notification.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(notification.message),
        trailing: Text(
          notification.timestamp.toDate().toLocal().toString().split(' ')[0],
          style: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}

class DonatePage extends StatefulWidget {
  final FirebaseService service;
  final String donorId;
  const DonatePage({super.key, required this.service, required this.donorId});

  @override
  State<DonatePage> createState() => _DonatePageState();
}

class _DonatePageState extends State<DonatePage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 50,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: const Color(0xFF1976D2),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black87,
            tabs: [
              Container(padding: EdgeInsets.all(14), child: Text("Charities")),
              Container(
                padding: EdgeInsets.all(14),
                child: Text("Fund Raising"),
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCampaignsList(widget.service, widget.donorId),
              _buildFundraisersList(widget.service, widget.donorId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignsList(FirebaseService service, String donorId) {
    return StreamBuilder<List<Campaign>>(
      stream: service.getActiveCampaignsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final campaigns = snapshot.data ?? [];
        if (campaigns.isEmpty) {
          return const Center(child: Text('No active campaigns found.'));
        }
        return ListView.builder(
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            final campaign = campaigns[index];
            return DonationCard(
              itemId: campaign.campaignId,
              title: campaign.name,
              organizer: campaign.charityName,
              amountRequired: campaign.targetAmount,
              amountRaised: campaign.currentAmount,
              type: 'Campaign',
              service: service,
              donorId: donorId,
            );
          },
        );
      },
    );
  }

  Widget _buildFundraisersList(FirebaseService service, String donorId) {
    return StreamBuilder<List<Fundraiser>>(
      stream: service.getActiveFundraisersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final fundraisers = snapshot.data ?? [];
        if (fundraisers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No active fundraisers found.'),
                const SizedBox(height: 16),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: fundraisers.length,
          itemBuilder: (context, index) {
            final fundraiser = fundraisers[index];
            return DonationCard(
              itemId: fundraiser.fundraiserId,
              title: fundraiser.name,
              organizer: 'Admin',
              amountRequired: fundraiser.targetAmount,
              amountRaised: fundraiser.currentAmount,
              type: 'Fundraiser',
              service: service,
              donorId: donorId,
            );
          },
        );
      },
    );
  }
}

class DonationCard extends StatelessWidget {
  final String itemId;
  final String title;
  final String organizer;
  final double amountRequired;
  final double amountRaised;
  final String type;
  final FirebaseService service;
  final String donorId;

  const DonationCard({
    super.key,
    required this.itemId,
    required this.title,
    required this.organizer,
    required this.amountRequired,
    required this.amountRaised,
    required this.type,
    required this.service,
    required this.donorId,
  });

  @override
  Widget build(BuildContext context) {
    final progress = amountRaised / amountRequired;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              'by $organizer',
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${amountRaised.toStringAsFixed(2)} raised',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Goal: \$${amountRequired.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showContributeDialog(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Donate', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContributeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => ContributeDialog(
            itemId: itemId,
            itemName: title,
            remainingAmount: amountRequired - amountRaised,
            type: type,
            service: service,
            donorId: donorId,
          ),
    );
  }
}

class ContributeDialog extends StatefulWidget {
  final String itemId;
  final String itemName;
  final double remainingAmount;
  final String type;
  final FirebaseService service;
  final String donorId;

  const ContributeDialog({
    super.key,
    required this.itemId,
    required this.itemName,
    required this.remainingAmount,
    required this.type,
    required this.service,
    required this.donorId,
  });

  @override
  State<ContributeDialog> createState() => _ContributeDialogState();
}

class _ContributeDialogState extends State<ContributeDialog> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _paymentMethod;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethod();
  }

  Future<void> _loadPaymentMethod() async {
    _paymentMethod = await widget.service.getPaymentMethod();
    setState(() {});
  }

  Future<void> _contribute() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);
      final amount = double.parse(_amountController.text);
      try {
        if (widget.type == 'Campaign') {
          await widget.service.contributeToCampaign(
            campaignId: widget.itemId,
            amount: amount,
            donorId: widget.donorId,
          );
        } else {
          await widget.service.contributeToFundraiser(
            fundraiserId: widget.itemId,
            amount: amount,
            donorId: widget.donorId,
          );
        }
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution successful!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to contribute: $e')));
      } finally {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showAddPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AddPaymentMethodDialog(
            onCardSaved: (cardDetails) {
              widget.service.savePaymentMethod(cardDetails: cardDetails);
              _loadPaymentMethod();
              Navigator.of(context).pop();
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Make a Contribution'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contributing to: ${widget.itemName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Remaining Goal: \$${widget.remainingAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Contribution Amount',
                  hintText: 'Enter amount in PKR',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  if (amount > widget.remainingAmount) {
                    return 'Amount cannot exceed remaining goal';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_paymentMethod != null) ...[
                const Text(
                  'Payment Method',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card),
                      const SizedBox(width: 12),
                      Text(
                        '**** **** **** ${_paymentMethod!.substring(_paymentMethod!.length - 4)}',
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _showAddPaymentDialog(context),
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                TextButton.icon(
                  onPressed: () => _showAddPaymentDialog(context),
                  icon: const Icon(Icons.add_card),
                  label: const Text('Add Payment Method'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (_paymentMethod != null && !_isProcessing)
                          ? _contribute
                          : null,
                  icon:
                      _isProcessing
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Icon(Icons.payment, color: Colors.white),
                  label: Text(_isProcessing ? 'Processing...' : 'Pay'),
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class AddPaymentMethodDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onCardSaved;
  const AddPaymentMethodDialog({super.key, required this.onCardSaved});

  @override
  State<AddPaymentMethodDialog> createState() => _AddPaymentMethodDialogState();
}

class _AddPaymentMethodDialogState extends State<AddPaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvcController = TextEditingController();
  final _postalCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add a New Card'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(labelText: 'Card number'),
                keyboardType: TextInputType.number,
                validator:
                    (value) =>
                        value!.length < 16 ? 'Invalid card number' : null,
              ),
              TextFormField(
                controller: _expiryDateController,
                decoration: const InputDecoration(
                  labelText: 'MM/YY',
                  hintText: 'MM/YY',
                ),
                keyboardType: TextInputType.text,
                validator:
                    (value) =>
                        value!.length != 5 ? 'Invalid expiry date' : null,
              ),
              TextFormField(
                controller: _cvcController,
                decoration: const InputDecoration(labelText: 'CVC'),
                keyboardType: TextInputType.number,
                obscureText: true,
                validator: (value) => value!.length < 3 ? 'Invalid CVC' : null,
              ),
              TextFormField(
                controller: _postalCodeController,
                decoration: const InputDecoration(labelText: 'Postal code'),
                keyboardType: TextInputType.number,
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
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onCardSaved({
                'cardNumber': _cardNumberController.text,
                'expiryDate': _expiryDateController.text,
                'cvc': _cvcController.text,
                'postalCode': _postalCodeController.text,
              });
            }
          },
          child: const Text('Save Card'),
        ),
      ],
    );
  }
}

class ProfilePage extends StatefulWidget {
  final FirebaseService service;
  final String donorId;

  const ProfilePage({super.key, required this.service, required this.donorId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late AppUser _userInfoFuture;
  final _nameController = TextEditingController();
  final bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _userInfoFuture = serviceLocator<AppUser>();
  }

  void _toggleEdit() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("userId");
    Navigator.pushReplacement(context, mprChange(WelcomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_circle, size: 100, color: Colors.blue),
            const SizedBox(height: 16),
            if (!_isEditing) ...[
              Text(
                "${_userInfoFuture.donor?.firstName ?? ""} ${_userInfoFuture.donor?.lastName ?? ""}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email: ${_userInfoFuture.email}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _toggleEdit,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ] else ...[
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'e.g., John Doe',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _toggleEdit,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
