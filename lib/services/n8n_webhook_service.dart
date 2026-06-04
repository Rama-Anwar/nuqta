import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class N8nWebhookService {
  N8nWebhookService._();

  static final N8nWebhookService instance = N8nWebhookService._();

  // ── Environment toggle ──────────────────────────────────────────────────
  //
  // Set to [true]  → requests go to the n8n TEST webhook (safe to experiment).
  // Set to [false] → requests go to the PRODUCTION webhook (live traffic).
  //
  // Flip this flag before a release build.
  /// Finalizes an invoice using the organization's configured webhook URL.
  ///
  /// Payload fields:
  ///  • `docId`         — Firestore document ID
  ///  • `invoice_id`    — human-readable invoice number
  ///  • `customer_name` — customer / supplier name
  ///  • `items`         — list of `{item, qty, price, cost}` objects
  ///
  /// Must only be called **after** the Firestore document has been
  /// successfully updated to "completed".
  Future<void> pingDocId({
    required String organizationId,
    required String docId,
    required String invoiceId,
    required String customerName,
    required List<Map<String, dynamic>> items,
  }) async {
    final organization = await FirebaseFirestore.instance
        .collection('organizations')
        .doc(organizationId)
        .get();
    final url = organization.data()?['finalize_webhook_url'] as String?;

    if (url == null || url.isEmpty) {
      throw const HttpException(
        'Organization finalize_webhook_url is missing or empty',
      );
    }

    final body = jsonEncode(<String, dynamic>{
      'docId': docId,
      'invoice_id': invoiceId,
      'customer_name': customerName,
      'items': items,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: const <String, String>{'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Finalize-invoice webhook failed '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }
  }
}

class HttpException implements Exception {
  final String message;

  const HttpException(this.message);

  @override
  String toString() => message;
}
