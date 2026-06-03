import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String name;
  final String address;
  final String sheetUrl;
  final DateTime billingDate;

  UserProfile({
    required this.name,
    required this.address,
    required this.sheetUrl,
    required this.billingDate,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data) {
    return UserProfile(
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      sheetUrl: data['sheet url'] ?? '',
      billingDate: (data['billing date'] as Timestamp).toDate(),
    );
  }
}
