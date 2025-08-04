import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

// Assuming UserType enum is defined elsewhere or will be included in the same file.
enum UserType { admin, charity, donor }

class AdminSvc {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _adminDocId = 'admin_data';

  /// Retrieves a stream of pending user approval requests from the admin document.
  Stream<List<Map<String, dynamic>>> getUnapprovedUsersStream() {
    return _firestore.collection('admins').doc(_adminDocId).snapshots().map((
      snapshot,
    ) {
      if (!snapshot.exists) return [];
      final data = snapshot.data();
      final usersToApprove = List<Map<String, dynamic>>.from(
        data?['usersToApprove'] ?? [],
      );
      return usersToApprove;
    });
  }

  /// Retrieves a stream of all donors.
  Stream<List<Map<String, dynamic>>> getDonorsStream() {
    return _firestore
        .collection('users')
        .where('accountType', isEqualTo: UserType.donor.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Retrieves a stream of all charities.
  Stream<List<Map<String, dynamic>>> getCharitiesStream() {
    return _firestore
        .collection('users')
        .where('accountType', isEqualTo: UserType.charity.name)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Approves a user (donor or charity) by setting their 'isApproved' status to true
  /// and removes them from the admin's approval queue.
  Future<void> verifyUser({
    required String userId,
    required String accountType,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isApproved': true,
      });

      final adminDocRef = _firestore.collection('admins').doc(_adminDocId);
      final adminDoc = await adminDocRef.get();
      if (adminDoc.exists) {
        final usersToApprove = List<Map<String, dynamic>>.from(
          adminDoc.data()?['usersToApprove'] ?? [],
        );
        final userEntryToRemove = usersToApprove.firstWhere(
          (user) =>
              user['userId'] == userId && user['accountType'] == accountType,
          orElse: () => {},
        );
        if (userEntryToRemove.isNotEmpty) {
          await adminDocRef.update({
            'usersToApprove': FieldValue.arrayRemove([userEntryToRemove]),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to verify user: $e');
    }
  }

  /// Deletes a user from the 'users' collection and from the approval queue if pending.
  Future<void> deleteUser({
    required String userId,
    required String accountType,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).delete();

      final adminDocRef = _firestore.collection('admins').doc(_adminDocId);
      final adminDoc = await adminDocRef.get();
      if (adminDoc.exists) {
        final usersToApprove = List<Map<String, dynamic>>.from(
          adminDoc.data()?['usersToApprove'] ?? [],
        );
        final userEntryToRemove = usersToApprove.firstWhere(
          (user) =>
              user['userId'] == userId && user['accountType'] == accountType,
          orElse: () => {},
        );
        if (userEntryToRemove.isNotEmpty) {
          await adminDocRef.update({
            'usersToApprove': FieldValue.arrayRemove([userEntryToRemove]),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Retrieves a stream of all APPROVED campaigns for the Products page.
  Stream<List<Map<String, dynamic>>> viewCampaignsStream() {
    return _firestore
        .collection('campaigns')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Retrieves a stream of PENDING campaigns for the Requests page.
  Stream<List<Map<String, dynamic>>> getPendingCampaignsStream() {
    return _firestore
        .collection('campaigns')
        .where('isApproved', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Retrieves a stream of all admin-raised fundraisers for the Products page.
  Stream<List<Map<String, dynamic>>> viewAdminFundraisersStream() {
    return _firestore
        .collection('adminFundraisers')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Updates the admin's phone number in the 'admin' document.
  Future<void> updateAdminPhone(String newPhone) async {
    try {
      final adminDocRef = _firestore.collection('admins').doc(_adminDocId);
      final adminDoc = await adminDocRef.get();
      if (!adminDoc.exists) {
        await adminDocRef.set({'phone': newPhone});
      } else {
        await adminDocRef.update({'phone': newPhone});
      }
    } catch (e) {
      throw Exception('Failed to update admin phone: $e');
    }
  }

  /// Approves a campaign by setting its 'isApproved' status to true.
  Future<void> approveCampaign({required String campaignId}) async {
    try {
      await _firestore.collection('campaigns').doc(campaignId).update({
        'isApproved': true,
      });
    } catch (e) {
      throw Exception('Failed to approve campaign: $e');
    }
  }

  /// Deletes a campaign.
  Future<void> deleteCampaign({required String campaignId}) async {
    try {
      await _firestore.collection('campaigns').doc(campaignId).delete();
    } catch (e) {
      throw Exception('Failed to delete campaign: $e');
    }
  }

  /// Deletes an admin fundraiser.
  Future<void> deleteAdminFundraiser({required String fundraiserId}) async {
    try {
      await _firestore
          .collection('adminFundraisers')
          .doc(fundraiserId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete fundraiser: $e');
    }
  }

  /// Marks a campaign as completed.
  Future<void> completeCampaign({required String campaignId}) async {
    try {
      await _firestore.collection('campaigns').doc(campaignId).update({
        'status': 'completed',
      });
    } catch (e) {
      throw Exception('Failed to complete campaign: $e');
    }
  }

  /// Creates a new admin-raised fundraiser.
  Future<void> createAdminFundraiser({
    required String name,
    required String description,
    required double targetAmount,
  }) async {
    try {
      final docId = const Uuid().v4();
      await _firestore.collection('adminFundraisers').doc(docId).set({
        'fundraiserId': docId,
        'name': name,
        'description': description,
        'targetAmount': targetAmount,
        'currentAmount': 0.0,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create admin fundraiser: $e');
    }
  }
}
