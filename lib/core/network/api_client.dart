import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'request_session.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient(this.config, this.session, {http.Client? client})
    : _client = client ?? http.Client();
  final AppConfig config;
  final RequestSession session;
  final http.Client _client;

  Map<String, String> imageHeaders({bool admin = false}) =>
      admin && session.authorization != null
      ? {'Authorization': session.authorization!}
      : const {};

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    bool admin = false,
    String? authorization,
  }) async {
    final request = http.Request(method, config.endpoint(path, query));
    request.headers.addAll(_headers(admin, authorization));
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    return _send(request, authenticated: admin && authorization == null);
  }

  Future<dynamic> upload(
    String path,
    Uint8List bytes,
    String name,
    int order,
  ) async {
    if (bytes.length > 5 * 1024 * 1024) {
      throw const ApiException('La imagen no puede superar los 5 MB.');
    }
    final request = http.MultipartRequest('POST', config.endpoint(path));
    request.headers.addAll(_headers(true, null));
    request.fields['orden'] = '$order';
    request.files.add(
      http.MultipartFile.fromBytes('archivo', bytes, filename: name),
    );
    return _send(request, authenticated: true);
  }

  Map<String, String> _headers(bool admin, String? override) {
    final auth = override ?? (admin ? session.authorization : null);
    if (admin && auth == null) {
      throw const ApiException(
        'Inicia sesión para continuar.',
        statusCode: 401,
      );
    }
    return {
      'Accept': 'application/json',
      'Authorization': ?auth,
      if (admin) 'X-Admin-Request': 'true',
    };
  }

  Future<dynamic> _send(
    http.BaseRequest request, {
    required bool authenticated,
  }) async {
    try {
      final stream = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(stream)
          .timeout(const Duration(seconds: 30));
      dynamic decoded;
      if (response.bodyBytes.isNotEmpty) {
        try {
          decoded = jsonDecode(utf8.decode(response.bodyBytes));
        } on FormatException {
          if (response.statusCode < 400) {
            throw const ApiException(
              'El servidor devolvió una respuesta no válida.',
            );
          }
        }
      }
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return decoded;
      }
      if (response.statusCode == 401 && authenticated) session.signOut();
      final message = switch (response.statusCode) {
        401 => 'La sesión no es válida. Vuelve a ingresar.',
        413 => 'La imagen es demasiado grande. El máximo es 5 MB.',
        >= 500 =>
          'El servidor no pudo completar la operación. Inténtalo de nuevo.',
        _ =>
          decoded is Map && decoded['detail'] is String
              ? decoded['detail'] as String
              : 'No se pudo completar la operación.',
      };
      throw ApiException(message, statusCode: response.statusCode);
    } on TimeoutException {
      throw const ApiException(
        'El servidor tardó demasiado. Comprueba el catálogo antes de repetir la operación.',
      );
    } on http.ClientException {
      throw const ApiException(
        'No se pudo conectar. Revisa tu conexión e inténtalo de nuevo.',
      );
    }
  }

  void dispose() => _client.close();
}
