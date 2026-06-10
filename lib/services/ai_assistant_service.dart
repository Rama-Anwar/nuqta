import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AiAssistantService {
  AiAssistantService._();

  static final AiAssistantService instance = AiAssistantService._();

  // Keep this isolated from the invoice-finalization webhook.
  static const String _webhookUrl =
      'https://n8n-production-9b11.up.railway.app/webhook/chat-assistant';

  Future<String> sendMessage({
    required String uid,
    required String language,
    required String message,
    List<Map<String, String>> history = const [],
  }) async {
    final body = jsonEncode(<String, Object>{
      'uid': uid,
      'language': language,
      'message': message,
      'history': history,
    });

    late final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_webhookUrl),
            headers: const <String, String>{'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const AiAssistantConnectionException();
    }

    final responseBody = utf8.decode(response.bodyBytes);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = _errorFromResponse(responseBody);
      throw AiAssistantException(
        error == null
            ? 'Maven request failed (HTTP ${response.statusCode}).'
            : 'Maven request failed (HTTP ${response.statusCode}): $error',
      );
    }

    final decoded = _decodeResponse(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw const AiAssistantMalformedResponseException();
    }

    final success = decoded['success'];
    if (success == true) {
      final answer = decoded['answer'];
      if (answer is String) return answer;
      throw const AiAssistantMalformedResponseException();
    }

    if (success == false) {
      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        throw AiAssistantException(error.trim());
      }
      throw const AiAssistantMalformedResponseException();
    }

    throw const AiAssistantMalformedResponseException();
  }

  Object? _decodeResponse(String responseBody) {
    try {
      return jsonDecode(responseBody);
    } on FormatException {
      throw const AiAssistantMalformedResponseException();
    }
  }

  String? _errorFromResponse(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is String && error.trim().isNotEmpty) return error.trim();
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

class AiAssistantException implements Exception {
  final String message;

  const AiAssistantException(this.message);

  @override
  String toString() => message;
}

class AiAssistantConnectionException implements Exception {
  const AiAssistantConnectionException();

  @override
  String toString() => 'Maven request timed out.';
}

class AiAssistantMalformedResponseException implements Exception {
  const AiAssistantMalformedResponseException();

  @override
  String toString() => 'Maven returned a malformed response.';
}
