import 'dart:async';

class SseEvent {
  const SseEvent({required this.name, required this.data, this.id});
  final String name, data;
  final String? id;
}

/// Recibe líneas decodificadas en UTF-8. No presupone que un chunk HTTP sea un evento.
class SseDecoder extends StreamTransformerBase<String, SseEvent> {
  const SseDecoder();
  @override
  Stream<SseEvent> bind(Stream<String> stream) async* {
    var name = 'message';
    String? id;
    final data = <String>[];
    var first = true;
    await for (var line in stream) {
      if (first) {
        line = line.replaceFirst(RegExp('^\uFEFF'), '');
        first = false;
      }
      if (line.isEmpty) {
        if (data.isNotEmpty) {
          yield SseEvent(name: name, data: data.join('\n'), id: id);
        }
        data.clear();
        name = 'message';
        continue;
      }
      if (line.startsWith(':')) continue;
      final colon = line.indexOf(':');
      final field = colon < 0 ? line : line.substring(0, colon);
      var value = colon < 0 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      switch (field) {
        case 'event':
          name = value;
        case 'data':
          data.add(value);
        case 'id':
          if (!value.contains('\u0000')) id = value;
      }
    }
    // Un bloque incompleto al desconectar no es un evento SSE.
  }
}
