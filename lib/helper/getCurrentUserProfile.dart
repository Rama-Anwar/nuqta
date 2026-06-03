import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:invoice_ai/models/user_profile_model.dart';

Future<UserProfile?> getCurrentUserProfile() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) return null;

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  if (!doc.exists) return null;

  return UserProfile.fromFirestore(doc.data()!);
}
