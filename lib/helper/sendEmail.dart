import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> sendEmail({
  required String name,
  required String email,
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
      "template_params": {"name": name, "email": email, "message": message},
    }),
  );

  if (response.statusCode == 200) {
    print("Email sent successfully");
  } else {
    print("Failed: ${response.body}");
  }
}
