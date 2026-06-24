import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/user_profile.dart';

abstract class ProfileRemoteDatasource {
  Future<UserProfile?> getProfile(String userId);
  Future<void> saveProfile(UserProfile profile);
}

class ProfileRemoteDatasourceImpl implements ProfileRemoteDatasource {
  final FirebaseFirestore _firestore;

  ProfileRemoteDatasourceImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserProfile?> getProfile(String userId) async {
    final doc = await _firestore.collection('profiles').doc(userId).get();
    if (!doc.exists || doc.data() == null) return null;

    final data = Map<String, dynamic>.from(doc.data()!);
    data['uid'] = userId;

    // FieldValue.serverTimestamp() is stored as a Firestore Timestamp.
    // json_serializable expects ISO-8601 strings for DateTime, so convert here.
    for (final key in ['createdAt', 'updatedAt']) {
      final val = data[key];
      if (val is Timestamp) {
        data[key] = val.toDate().toIso8601String();
      }
    }

    return UserProfile.fromJson(data);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No autenticado: currentUser is null');

    final data = profile.toJson();
    data['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _firestore
          .collection('profiles')
          .doc(profile.uid)
          .set(data, SetOptions(merge: true));
    } catch (e, stack) {
      debugPrint('Firestore saveProfile error: $e\n$stack');
      rethrow;
    }
  }
}
