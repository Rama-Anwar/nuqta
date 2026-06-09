import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String userName;
  final String email;
  final String name;
  final String address;
  final String priceSheetUrl;
  final String finalizeWebhookUrl;
  final String organizationId;
  final String role;
  final DateTime? billingDate;

  UserProfile({
    required this.userName,
    required this.email,
    required this.name,
    required this.address,
    required this.priceSheetUrl,
    required this.finalizeWebhookUrl,
    required this.organizationId,
    required this.role,
    required this.billingDate,
  });

  bool get isOwner => role == 'owner';
  bool get isEmployee => !isOwner;

  factory UserProfile.fromFirestore({
    required Map<String, dynamic> userData,
    required Map<String, dynamic>? organizationData,
  }) {
    final rawRole = userData['role'];
    final role = rawRole is String && rawRole.trim().toLowerCase() == 'owner'
        ? 'owner'
        : 'employee';

    return UserProfile(
      userName: userData['name'] is String
          ? (userData['name'] as String).trim()
          : '',
      email: userData['email'] is String
          ? (userData['email'] as String).trim()
          : '',
      name: organizationData?['name'] is String
          ? (organizationData!['name'] as String).trim()
          : '',
      address: organizationData?['address'] is String
          ? (organizationData!['address'] as String).trim()
          : '',
      priceSheetUrl: organizationData?['price_sheet_url'] is String
          ? (organizationData!['price_sheet_url'] as String).trim()
          : '',
      finalizeWebhookUrl: organizationData?['finalize_webhook_url'] is String
          ? (organizationData!['finalize_webhook_url'] as String).trim()
          : '',
      organizationId: userData['organization_id'] is String
          ? (userData['organization_id'] as String).trim()
          : '',
      role: role,
      billingDate: _parseDate(organizationData?['billing_date']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
