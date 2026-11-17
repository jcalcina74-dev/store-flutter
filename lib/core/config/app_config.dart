import 'package:flutter/foundation.dart';

class AppConfig {
  AppConfig({required Uri baseUrl}) : baseUrl = _validate(baseUrl);

  factory AppConfig.fromEnvironment() {
    const configured = String.fromEnvironment('API_BASE_URL');
    final value = configured.trim();
    if (value.isEmpty && !kDebugMode) {
      throw StateError(
        'Configura API_BASE_URL con --dart-define-from-file antes de compilar.',
      );
    }

    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    final url = Uri.parse(value.isEmpty ? 'http://$host:8080' : value);
    if (!kDebugMode && url.scheme != 'https') {
      throw ArgumentError('API_BASE_URL debe usar HTTPS fuera de debug.');
    }
    return AppConfig(baseUrl: url);
  }
  final Uri baseUrl;
  static const storeName = 'NOVA';

  static Uri _validate(Uri url) {
    if (!url.hasAuthority ||
        !{'http', 'https'}.contains(url.scheme) ||
        url.userInfo.isNotEmpty ||
        url.hasQuery ||
        url.hasFragment) {
      throw ArgumentError(
        'API_BASE_URL debe ser una URL HTTP(S) sin credenciales.',
      );
    }
    return url;
  }

  Uri endpoint(String path, [Map<String, String>? query]) {
    final root = baseUrl.toString().replaceFirst(RegExp(r'/+$'), '');
    final relative = path.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$root/$relative').replace(queryParameters: query);
  }

  String imageUrl(String path) {
    if (!path.startsWith('/api/media/')) {
      throw const FormatException('Referencia de imagen no válida');
    }
    return endpoint(path).toString();
  }
}
