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

  // ── Environment toggle ──────────────────────────────────────────────────
  //
  // Set to [true]  → requests go to the n8n TEST webhook (safe to experiment).
  // Set to [false] → requests go to the PRODUCTION webhook (live traffic).
  //
  // Flip this flag before a release build.
  static bool isTestingMode = false;

  // Finalize-invoice endpoints.
  static const String _testUrl =
      'https://doxological-turner-insurmountably.ngrok-free.dev/webhook-test/finalize-invoice';
  static const String _prodUrl =
      'https://n8n-production-9b11.up.railway.app/webhook/finalize-invoice';

  /// Finalizes an invoice by posting its full data to [_testUrl] or [_prodUrl]
  /// depending on [isTestingMode].
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
    required String docId,
    required String invoiceId,
    required String customerName,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = isTestingMode ? _testUrl : _prodUrl;

    final body = jsonEncode(<String, dynamic>{
      'docId': docId,
      'invoice_id': invoiceId,
      'customer_name': customerName,
      'items': items,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: const <String, String>{
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Finalize-invoice webhook failed [${isTestingMode ? 'TEST' : 'PROD'}] '
        '(HTTP ${response.statusCode}): ${response.body}',
      );
    }
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