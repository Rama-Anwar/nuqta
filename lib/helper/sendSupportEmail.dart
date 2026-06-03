import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> sendSupportEmail({
  required String issueType,
  required String message,
}) async {
  const serviceId = "service_0iioitb";
  const templateId = "template_z8qtd9s";
  const publicKey = "EPKNOE5QuWG1lonIt";

  final url = Uri.parse("https://api.emailjs.com/api/v1.0/email/send");

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "service_id": serviceId,
      "template_id": templateId,
      "user_id": publicKey,
      "template_params": {
        "title": "Nuqta Support Request - $issueType",
        "message": message,
        "to_email": "rama2kalloub@gmail.com",
      },
    }),
  );

  if (response.statusCode != 200) {
    throw Exception("Failed to send email: ${response.body}");
  }
}
