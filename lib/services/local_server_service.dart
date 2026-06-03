import 'dart:async';
import 'dart:convert';
import 'dart:io';

class LocalServerService {
  LocalServerService._();

  static final LocalServerService instance = LocalServerService._();

  static const int _port = 8080;
  // تم تعديل المسار هنا ليتطابق مع رابط n8n
  static const String _receiveOrderPath = '/items';

  final StreamController<dynamic> _incomingOrderController =
      StreamController<dynamic>.broadcast();

  HttpServer? _server;

  Stream<dynamic> get incomingOrderStream => _incomingOrderController.stream;

  Future<void> start() async {
    if (_server != null) {
      return;
    }

    final server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
    _server = server;

    server.listen(
      _handleRequest,
      onError: (Object error, StackTrace stackTrace) {
        stderr.writeln('LocalServerService error: $error');
      },
      onDone: () {
        _server = null;
      },
      cancelOnError: false,
    );

    stdout.writeln(
      'LocalServerService listening on http://${server.address.address}:$_port$_receiveOrderPath',
    );
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      if (request.uri.path != _receiveOrderPath) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write('Not found');
        await request.response.close();
        return;
      }

      if (request.method.toUpperCase() != 'POST') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        request.response.headers.set(HttpHeaders.allowHeader, 'POST');
        request.response.write('Only POST is supported');
        await request.response.close();
        return;
      }

      final body = await utf8.decoder.bind(request).join();
      if (body.trim().isEmpty) {
        request.response.statusCode = HttpStatus.badRequest;
        request.response.write('Empty JSON body');
        await request.response.close();
        return;
      }

      final decoded = jsonDecode(body);
      _incomingOrderController.add(decoded);

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode(<String, dynamic>{
          'success': true,
          'message': 'Order received',
        }),
      );
      await request.response.close();
    } catch (error) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('Invalid request: $error');
        await request.response.close();
      } catch (_) {
        // The response may already be closed if the client disconnected early.
      }
    }
  }
}
