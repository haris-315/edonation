// ignore_for_file: unused_local_variable

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:edonation/core/constants.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:uploadcare_flutter/uploadcare_flutter.dart';
import 'package:uuid/uuid.dart';

// Assuming UserType enum is defined elsewhere or will be included in the same file.
enum UserType { admin, charity, donor }

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateHash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<String> sendOtpEmail(String email) async {
    final otp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    final smtpServer = gmail(
      'remotehms112233@gmail.com',
      'zwgr gfbb xqij bfmo',
    ); // Replace with your SMTP credentials

    final message = Message()
      ..from = const Address('your-email@gmail.com', 'eDonation')
      ..recipients.add(email)
      ..subject = 'Your eDonation OTP'
      ..html = Constants.emailTemplate(otp);

    try {
      // await send(message, smtpServer);
      print(otp);
      return otp;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  Future<String> signupUser({
    required String accountType,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      // Check if email or phone number already exists in the unified 'users' collection
      final emailOrPhoneCheck = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .get();

      if (emailOrPhoneCheck.docs.isNotEmpty) {
        throw Exception('Email or phone number already in use.');
      }

      final uuid = const Uuid().v4();
      final userId =
          accountType == UserType.donor.name ? 'dono_$uuid' : 'charown_$uuid';

      final signupData = {
        'userId': userId,
        'accountType': accountType,
        'email': email.trim(),
        'phone': phone.trim(),
        'password': _generateHash(password),
        'timestamp': DateTime.now(),
        'isApproved': false, // All new signups require approval
      };

      // Add user to the unified 'users' collection
      await _firestore.collection('users').doc(userId).set(signupData);
      
      // Add user to the admin's approval queue
      final adminDocRef = _firestore.collection('admin').doc('admin_data');
      await adminDocRef.update({
        'usersToApprove': FieldValue.arrayUnion([
          {
            'userId': userId,
            'accountType': accountType,
            'email': email.trim(),
            'phone': phone.trim(),
            'timestamp': Timestamp.now(),
          }
        ]),
      });

      return userId;
    } catch (e) {
      throw Exception('Signup failed: $e');
    }
  }

  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.trim())
          .where('password', isEqualTo: _generateHash(password))
          .where('isApproved', isEqualTo: true) // Only approved users can log in
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  Future<void> saveDonorIdentity({
    required String userId,
    required String firstName,
    required String lastName,
    required String docType,
    required String docNumber,
    required File? frontImage,
    required File? backImage,
  }) async {
    try {
      final identityData = {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'docType': docType,
        'docNumber': docNumber.trim(),
        'updatedAt': DateTime.now(),
      };

      final client = UploadcareClient.withSimpleAuth(
        publicKey: '96fc61676173876589b0',
        apiVersion: 'v0.7',
      );

      if (frontImage != null) {
        final frontFileId = await client.upload.auto(UCFile(frontImage));
        identityData['frontImageUrl'] = 'https://ucarecdn.com/$frontFileId/';
      }

      if (backImage != null) {
        final backFileId = await client.upload.auto(UCFile(backImage));
        identityData['backImageUrl'] = 'https://ucarecdn.com/$backFileId/';
      }

      await _firestore.collection('users').doc(userId).update(identityData);
    } catch (e) {
      throw Exception('Failed to save donor identity: $e');
    }
  }

  Future<void> saveCharityIdentity({
    required String userId,
    required String charityName,
    required String ownerName,
    required String contactNumber,
    required String cnicNumber,
    required File? verificationDocument,
    required File? charityLogo,
  }) async {
    try {
      final charityData = {
        'charityName': charityName.trim(),
        'ownerName': ownerName.trim(),
        'contactNumber': contactNumber.trim(),
        'cnicNumber': cnicNumber.trim(),
        'updatedAt': DateTime.now(),
      };

      final client = UploadcareClient.withSimpleAuth(
        publicKey: '96fc61676173876589b0',
        apiVersion: 'v0.7',
      );

      if (verificationDocument != null) {
        final docFileId = await client.upload.auto(UCFile(verificationDocument));
        charityData['verificationDocumentUrl'] = 'https://ucarecdn.com/$docFileId/';
      }

      if (charityLogo != null) {
        final logoFileId = await client.upload.auto(UCFile(charityLogo));
        charityData['charityLogoUrl'] = 'https://ucarecdn.com/$logoFileId/';
      }

      await _firestore.collection('users').doc(userId).update(charityData);
    } catch (e) {
      throw Exception('Failed to save charity identity: $e');
    }
  }
}
