import 'package:cloud_firestore/cloud_firestore.dart';

// Assuming UserType enum is defined elsewhere or will be included in the same file.
enum UserType { admin, charity, donor }

class AdminSvc {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retrieves a stream of pending user approval requests from the admin document.
  /// This is suitable for real-time updates on the Requests page.
  Stream<List<Map<String, dynamic>>> getUnapprovedUsersStream() {
    return _firestore.collection('admin').doc('admin_data').snapshots().map((snapshot) {
      if (!snapshot.exists) return [];
      final data = snapshot.data();
      final usersToApprove = List<Map<String, dynamic>>.from(data?['usersToApprove'] ?? []);
      return usersToApprove;
    });
  }

  /// Retrieves a stream of all approved members (donors and charities) from the 'users' collection.
  /// This is for the Members page.
  Stream<List<Map<String, dynamic>>> getApprovedMembersStream() {
    return _firestore
        .collection('users')
        .where('isApproved', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Approves a user (donor or charity) by setting their 'isApproved' status to true
  /// and removes them from the admin's approval queue.
  Future<void> verifyUser({required String userId, required String accountType}) async {
    try {
      // 1. Update the user's document to set isApproved to true
      await _firestore.collection('users').doc(userId).update({
        'isApproved': true,
      });

      // 2. Remove the user from the admin's approval queue
      final adminDocRef = _firestore.collection('admin').doc('admin_data');
      final userToRemove = {
        'userId': userId,
        'accountType': accountType,
      };

      // Fetch the admin document to get the complete user data to remove from the array
      final adminDoc = await adminDocRef.get();
      if (adminDoc.exists) {
        final usersToApprove = List<Map<String, dynamic>>.from(adminDoc.data()?['usersToApprove'] ?? []);
        final userEntryToRemove = usersToApprove.firstWhere(
          (user) => user['userId'] == userId && user['accountType'] == accountType,
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
  Future<void> deleteUser({required String userId, required String accountType}) async {
    try {
      await _firestore.collection('users').doc(userId).delete();

      // Also remove from the admin's approval queue in case they were pending
      final adminDocRef = _firestore.collection('admin').doc('admin_data');
      final adminDoc = await adminDocRef.get();
      if (adminDoc.exists) {
        final usersToApprove = List<Map<String, dynamic>>.from(adminDoc.data()?['usersToApprove'] ?? []);
        final userEntryToRemove = usersToApprove.firstWhere(
          (user) => user['userId'] == userId && user['accountType'] == accountType,
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

  /// Retrieves a stream of all campaigns for the Products page.
  Stream<List<Map<String, dynamic>>> viewCampaignsStream() {
    return _firestore.collection('campaigns').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
  
  /// Retrieves a stream of all admin-raised fundraisers for the Products page.
  Stream<List<Map<String, dynamic>>> viewAdminFundraisersStream() {
    return _firestore.collection('adminFundraisers').snapshots().map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Updates the admin's phone number in the 'admin' document.
  Future<void> updateAdminPhone(String newPhone) async {
    try {
      await _firestore.collection('admin').doc('admin_data').update({
        'phone': newPhone,
      });
    } catch (e) {
      throw Exception('Failed to update admin phone: $e');
    }
  }
}