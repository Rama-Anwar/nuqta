import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

Future<void> sendSupportEmail({
  required String issueType,
  required String message,
}) async {
  const serviceId = "service_0iioitb";
  const templateId = "template_z8qtd9s";
  const publicKey = "EPKNOE5QuWG1lonIt";

  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception("User not logged in");
  }

  // 👇 Fetch name from Firestore
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final userName = doc.data()?['name'] ?? 'Unknown User';
  final userEmail = user.email ?? 'No Email';

  final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "service_id": serviceId,
      "template_id": templateId,
      "user_id": publicKey,
      "template_params": {
        "title": "Support Request - $issueType",
        "issue": issueType,
        "name": userName,
        "email": userEmail,
        "message": message,
      },
    }),
  );

  print("RESPONSE CODE: ${response.statusCode}");
  print("RESPONSE BODY: ${response.body}");

  if (response.statusCode != 200) {
    throw Exception("Failed to send email");
  }
}
