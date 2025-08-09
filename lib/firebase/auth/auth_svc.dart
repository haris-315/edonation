// ignore_for_file: unused_local_variable
// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:edonation/core/constants.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:uploadcare_flutter/uploadcare_flutter.dart';
import 'package:uuid/uuid.dart';

enum UserType { admin, charity, donor }

/// ================================================================
/// 1.  UPDATED  SERVICE
/// ================================================================
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _generateHash(String input) =>
      sha256.convert(utf8.encode(input)).toString();

  /* ---------- OTP ---------- */
  Future<String> sendOtpEmail(String email) async {
    final otp =
        (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    final smtpServer = gmail(
      'remotehms112233@gmail.com',
      'zwgr gfbb xqij bfmo',
    );
    final message =
        Message()
          ..from = const Address('your-email@gmail.com', 'eDonation')
          ..recipients.add(email)
          ..subject = 'Your eDonation OTP'
          ..html = Constants.emailTemplate(otp);

    try {
      await send(message, smtpServer);
      print(otp);
      return otp;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /* ---------- SIGN-UP ---------- */
  Future<String> signupUser({
    required String accountType,
    required String email,
    required String phone,
    required String password,
  }) async {
    final emailCheck =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: email.trim())
            .get();
    if (emailCheck.docs.isNotEmpty) {
      throw Exception('Email already in use.');
    }

    final uuid = const Uuid().v4();
    final userId =
        accountType == UserType.donor.name ? 'dono_$uuid' : 'charown_$uuid';
    final user = AppUser(
      userId: userId,
      accountType: UserType.values.byName(accountType),
      email: email.trim(),
      phone: phone.trim(),
      passwordHash: _generateHash(password),
      isApproved: false,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('users').doc(userId).set(user.toSignupMap());

    final pending = PendingApprovalUser(
      userId: userId,
      accountType: user.accountType,
      email: user.email,
      phone: user.phone,
      timestamp: user.timestamp,
    );

    final adminDoc = _firestore.collection('admins').doc('admin_data');
    if (!(await adminDoc.get()).exists) {
      await adminDoc.set({'usersToApprove': []});
    }
    await adminDoc.update({
      'usersToApprove': FieldValue.arrayUnion([pending.toMap()]),
    });

    return userId;
  }

  /* ---------- LOGIN ---------- */
  Future<AppUser?> loginUser({
    required String email,
    required String password,
  }) async {
    final snap =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: email.trim())
            .where('password', isEqualTo: _generateHash(password))
            .where('isApproved', isEqualTo: true)
            .limit(1)
            .get();
    return snap.docs.isEmpty ? null : AppUser.fromFirestore(snap.docs.first);
  }

  Future<AppUser?> getUser({required String id}) async {
    final snap =
        await _firestore
            .collection('users')
            .where('userId', isEqualTo: id)
            .where('isApproved', isEqualTo: true)
            .limit(1)
            .get();
    return snap.docs.isEmpty ? null : AppUser.fromFirestore(snap.docs.first);
  }

  /* ---------- DONOR IDENTITY ---------- */
  Future<void> saveDonorIdentity({
    required String userId,
    required String firstName,
    required String lastName,
    required String docType,
    required String docNumber,
    required File? frontImage,
    required File? backImage,
  }) async {
    final identity = DonorIdentity(
      firstName: firstName,
      lastName: lastName,
      docType: docType,
      docNumber: docNumber,
      updatedAt: DateTime.now(),
    );

    final client = UploadcareClient.withSimpleAuth(
      publicKey: '96fc61676173876589b0',
      apiVersion: 'v0.7',
    );

    Map<String, dynamic> data = identity.toMap();
    if (frontImage != null) {
      final id = await client.upload.auto(UCFile(frontImage));
      data['frontImageUrl'] = 'https://ucarecdn.com/$id/';
    }
    if (backImage != null) {
      final id = await client.upload.auto(UCFile(backImage));
      data['backImageUrl'] = 'https://ucarecdn.com/$id/';
    }
    await _firestore.collection('users').doc(userId).update(data);
  }

  /* ---------- CHARITY IDENTITY ---------- */
  Future<void> saveCharityIdentity({
    required String userId,
    required String charityName,
    required String ownerName,
    required String contactNumber,
    required String cnicNumber,
    required File? verificationDocument,
    required File? charityLogo,
  }) async {
    final charity = CharityIdentity(
      charityName: charityName,
      ownerName: ownerName,
      contactNumber: contactNumber,
      cnicNumber: cnicNumber,
      updatedAt: DateTime.now(),
    );

    final client = UploadcareClient.withSimpleAuth(
      publicKey: '96fc61676173876589b0',
      apiVersion: 'v0.7',
    );

    Map<String, dynamic> data = charity.toMap();
    if (verificationDocument != null) {
      final id = await client.upload.auto(UCFile(verificationDocument));
      data['verificationDocumentUrl'] = 'https://ucarecdn.com/$id/';
    }
    if (charityLogo != null) {
      final id = await client.upload.auto(UCFile(charityLogo));
      data['charityLogoUrl'] = 'https://ucarecdn.com/$id/';
    }
    await _firestore.collection('users').doc(userId).update(data);
  }

  /* ---------- STREAMS ---------- */
  Stream<List<PendingApprovalUser>> getUnapprovedUsersStream() => _firestore
      .collection('admins')
      .doc('admin_data')
      .snapshots()
      .map(
        (snap) =>
            (snap.data()?['usersToApprove'] as List<dynamic>? ?? [])
                .map((e) => PendingApprovalUser.fromMap(e))
                .toList(),
      );

  Stream<List<AppUser>> getApprovedMembersStream() => _firestore
      .collection('users')
      .where('isApproved', isEqualTo: true)
      .snapshots()
      .map((qs) => qs.docs.map(AppUser.fromFirestore).toList());
}

/// ================================================================
/// 2.  MODEL  CLASSES
/// ================================================================

class AppUser {
  final String userId;
  final UserType accountType;
  final String email;
  final String phone;
  final String passwordHash;
  final bool isApproved;
  final DateTime timestamp;
  final DonorIdentity? donor;
  final CharityIdentity? charity;

  AppUser({
    required this.userId,
    required this.accountType,
    required this.email,
    required this.phone,
    required this.passwordHash,
    required this.isApproved,
    required this.timestamp,
    this.donor,
    this.charity,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final t = d['timestamp'] as Timestamp;
    return AppUser(
      userId: d['userId'],
      accountType: UserType.values.byName(d['accountType']),
      email: d['email'],
      phone: d['phone'],
      passwordHash: d['password'],
      isApproved: d['isApproved'],
      timestamp: t.toDate(),
      donor: (d['firstName'] != null) ? DonorIdentity.fromMap(d) : null,
      charity: (d['charityName'] != null) ? CharityIdentity.fromMap(d) : null,
    );
  }

  Map<String, dynamic> toSignupMap() => {
    'userId': userId,
    'accountType': accountType.name,
    'email': email,
    'phone': phone,
    'password': passwordHash,
    'isApproved': isApproved,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}

class DonorIdentity {
  final String firstName;
  final String lastName;
  final String docType;
  final String docNumber;
  final String? frontImageUrl;
  final String? backImageUrl;
  final DateTime updatedAt;

  DonorIdentity({
    required this.firstName,
    required this.lastName,
    required this.docType,
    required this.docNumber,
    this.frontImageUrl,
    this.backImageUrl,
    required this.updatedAt,
  });

  factory DonorIdentity.fromMap(Map<String, dynamic> d) => DonorIdentity(
    firstName: d['firstName'],
    lastName: d['lastName'],
    docType: d['docType'],
    docNumber: d['docNumber'],
    frontImageUrl: d['frontImageUrl'],
    backImageUrl: d['backImageUrl'],
    updatedAt: (d['updatedAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'firstName': firstName,
    'lastName': lastName,
    'docType': docType,
    'docNumber': docNumber,
    if (frontImageUrl != null) 'frontImageUrl': frontImageUrl,
    if (backImageUrl != null) 'backImageUrl': backImageUrl,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}

class CharityIdentity {
  final String charityName;
  final String ownerName;
  final String contactNumber;
  final String cnicNumber;
  final String? verificationDocumentUrl;
  final String? charityLogoUrl;
  final DateTime updatedAt;

  CharityIdentity({
    required this.charityName,
    required this.ownerName,
    required this.contactNumber,
    required this.cnicNumber,
    this.verificationDocumentUrl,
    this.charityLogoUrl,
    required this.updatedAt,
  });

  factory CharityIdentity.fromMap(Map<String, dynamic> d) => CharityIdentity(
    charityName: d['charityName'],
    ownerName: d['ownerName'],
    contactNumber: d['contactNumber'],
    cnicNumber: d['cnicNumber'],
    verificationDocumentUrl: d['verificationDocumentUrl'],
    charityLogoUrl: d['charityLogoUrl'],
    updatedAt: (d['updatedAt'] as Timestamp).toDate(),
  );

  Map<String, dynamic> toMap() => {
    'charityName': charityName,
    'ownerName': ownerName,
    'contactNumber': contactNumber,
    'cnicNumber': cnicNumber,
    if (verificationDocumentUrl != null)
      'verificationDocumentUrl': verificationDocumentUrl,
    if (charityLogoUrl != null) 'charityLogoUrl': charityLogoUrl,
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}

class PendingApprovalUser {
  final String userId;
  final UserType accountType;
  final String email;
  final String phone;
  final DateTime timestamp;

  PendingApprovalUser({
    required this.userId,
    required this.accountType,
    required this.email,
    required this.phone,
    required this.timestamp,
  });

  factory PendingApprovalUser.fromMap(Map<String, dynamic> d) =>
      PendingApprovalUser(
        userId: d['userId'],
        accountType: UserType.values.byName(d['accountType']),
        email: d['email'],
        phone: d['phone'],
        timestamp: (d['timestamp'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'accountType': accountType.name,
    'email': email,
    'phone': phone,
    'timestamp': Timestamp.fromDate(timestamp),
  };
}
