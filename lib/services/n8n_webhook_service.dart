import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/receipt_store.dart';

class N8nWebhookService {
  N8nWebhookService._();

  static final N8nWebhookService instance = N8nWebhookService._();

  String? receiveOrderWebhookUrl;
  String? sendInvoiceWebhookUrl;
  Map<String, String> headers = const <String, String>{'Content-Type': 'application/json'};

  Future<void> sendInvoice(ReceiptRecord receipt) async {
    final url = sendInvoiceWebhookUrl;
    if (url == null || url.isEmpty) {
      return;
    }

    final payload = <String, dynamic>{
      'type': 'invoice',
      'source': 'flutter_app',
      'receipt': receipt.toJson(),
      'summary': <String, dynamic>{
        'id': receipt.id,
        'customerName': receipt.customerName,
        'invoiceId': receipt.invoiceId,
        'date': receipt.date.toIso8601String(),
        'createdAt': receipt.createdAt.toIso8601String(),
        'subtotal': receipt.subtotal,
        'tax': receipt.tax,
        'total': receipt.total,
      },
    };

    await _postJson(url, payload);
  }

  Future<Map<String, dynamic>?> receiveOrder() async {
    final url = receiveOrderWebhookUrl;
    if (url == null || url.isEmpty) {
      return null;
    }

    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Failed to receive order: ${response.statusCode}');
    }

    if (response.body.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return <String, dynamic>{'data': decoded};
  }

  Future<void> _postJson(String url, Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException('Webhook request failed: ${response.statusCode}');
    }
  }
}

class HttpException implements Exception {
  final String message;

  const HttpException(this.message);

  @override
  String toString() => message;
}