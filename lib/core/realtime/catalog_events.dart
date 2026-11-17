import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'sse_decoder.dart';

enum LiveStatus { connecting, live, reconnecting, paused }

class CatalogEvents extends ChangeNotifier {
  CatalogEvents(this.config, {http.Client Function()? clientFactory})
    : _clientFactory = clientFactory ?? http.Client.new;
  final AppConfig config;
  final http.Client Function() _clientFactory;
  final _changes = StreamController<void>.broadcast();
  final _random = Random();
  Stream<void> get changes => _changes.stream;
  LiveStatus _status = LiveStatus.paused;
  LiveStatus get status => _status;
  bool _active = false, _disposed = false;
  int _generation = 0;
  String? _lastId;
  http.Client? _client;
  Timer? _timer;
  Completer<void>? _waiting;

  void start() {
    if (_active || _disposed) return;
    _active = true;
    final generation = ++_generation;
    unawaited(_run(generation));
  }

  void stop() {
    _active = false;
    _generation++;
    _client?.close();
    _client = null;
    _timer?.cancel();
    if (_waiting != null && !_waiting!.isCompleted) _waiting!.complete();
    _setStatus(LiveStatus.paused);
  }

  bool _current(int generation) =>
      !_disposed && _active && generation == _generation;

  Future<void> _run(int generation) async {
    var seconds = 3;
    while (_current(generation)) {
      final client = _clientFactory();
      _client = client;
      _setStatus(
        _status == LiveStatus.paused
            ? LiveStatus.connecting
            : LiveStatus.reconnecting,
      );
      try {
        final request = http.Request(
          'GET',
          config.endpoint('/api/catalogo/eventos'),
        );
        request.headers['Accept'] = 'text/event-stream';
        if (_lastId != null) request.headers['Last-Event-ID'] = _lastId!;
        final response = await client
            .send(request)
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200 ||
            !(response.headers['content-type'] ?? '').startsWith(
              'text/event-stream',
            )) {
          throw const FormatException('Canal SSE no disponible');
        }
        final lines = response.stream
            .timeout(const Duration(seconds: 40))
            .transform(utf8.decoder)
            .transform(const LineSplitter());
        await for (final event in lines.transform(const SseDecoder())) {
          if (!_current(generation)) break;
          _lastId = event.id;
          seconds = 3;
          _setStatus(LiveStatus.live);
          if (event.name == 'sincronizar' ||
              event.name == 'catalogo-actualizado') {
            _changes.add(null);
          }
        }
      } catch (_) {
        // El catálogo REST sigue disponible; el canal reintenta sin mostrar errores técnicos.
      } finally {
        client.close();
        if (identical(_client, client)) _client = null;
      }
      if (!_current(generation)) break;
      _setStatus(LiveStatus.reconnecting);
      final waiting = Completer<void>();
      _waiting = waiting;
      _timer = Timer(
        Duration(milliseconds: seconds * 1000 + _random.nextInt(700)),
        waiting.complete,
      );
      await waiting.future;
      seconds = min(30, seconds * 2);
    }
  }

  void _setStatus(LiveStatus value) {
    if (_disposed || _status == value) return;
    _status = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stop();
    unawaited(_changes.close());
    super.dispose();
  }
}
