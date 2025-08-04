import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uploadcare_flutter/uploadcare_flutter.dart';
import 'package:uuid/uuid.dart';

class CharitySvc {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Retrieves a stream of all campaigns created by a specific charity.
  Stream<List<Map<String, dynamic>>> getCharityCampaignsStream({
    required String charityId,
  }) {
    return _firestore
        .collection('campaigns')
        .where('charityId', isEqualTo: charityId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Creates a new donation campaign for a charity.
  /// This method also uploads the campaign image to Uploadcare.
  Future<void> createCampaign({
    required String charityId,
    required String charityName,
    required String name,
    required String description,
    required double targetAmount,
    required File campaignImage,
  }) async {
    try {
      final client = UploadcareClient.withSimpleAuth(
        publicKey: '96fc61676173876589b0',
        apiVersion: 'v0.7',
      );

      // Upload image to Uploadcare
      final imageFileId = await client.upload.auto(UCFile(campaignImage));
      final imageUrl = 'https://ucarecdn.com/$imageFileId/';

      final campaignId = const Uuid().v4();
      final campaignData = {
        'campaignId': campaignId,
        'charityId': charityId,
        'charityName': charityName,
        'name': name,
        'description': description,
        'targetAmount': targetAmount,
        'amountRaised': 0.0,
        'imageUrl': imageUrl,
        'isApproved': false, // Campaigns need admin approval
        'status': 'pending', // Can be 'pending', 'in_progress', 'completed'
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('campaigns')
          .doc(campaignId)
          .set(campaignData);
    } catch (e) {
      throw Exception('Failed to create campaign: $e');
    }
  }

  /// Fetches the details of a single campaign.
  Future<Map<String, dynamic>?> getCampaignDetails({
    required String campaignId,
  }) async {
    try {
      final doc =
          await _firestore.collection('campaigns').doc(campaignId).get();
      return doc.data();
    } catch (e) {
      throw Exception('Failed to fetch campaign details: $e');
    }
  }

  /// Updates a campaign's details.
  Future<void> updateCampaign({
    required String campaignId,
    required String name,
    required String description,
    required double targetAmount,
    File? campaignImage,
  }) async {
    try {
      final updateData = {
        'name': name,
        'description': description,
        'targetAmount': targetAmount,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (campaignImage != null) {
        final client = UploadcareClient.withSimpleAuth(
          publicKey: '96fc61676173876589b0',
          apiVersion: 'v0.7',
        );
        final imageFileId = await client.upload.auto(UCFile(campaignImage));
        updateData['imageUrl'] = 'https://ucarecdn.com/$imageFileId/';
      }

      await _firestore
          .collection('campaigns')
          .doc(campaignId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update campaign: $e');
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
}
