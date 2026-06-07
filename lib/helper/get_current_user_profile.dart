import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invoice_ai/models/user_profile_model.dart';

Future<UserProfile?> getCurrentUserProfile() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) return null;

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  if (!userDoc.exists) return null;

  final userData = userDoc.data()!;
  final organizationId = userData['organization_id'];
  Map<String, dynamic>? organizationData;

  if (organizationId is String && organizationId.trim().isNotEmpty) {
    final organizationDoc = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId.trim())
        .get();
    organizationData = organizationDoc.data();
  }

  return UserProfile.fromFirestore(
    userData: userData,
    organizationData: organizationData,
  );
}
