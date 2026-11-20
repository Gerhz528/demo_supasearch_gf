// lib/repositories/chat_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  final _client = Supabase.instance.client;

  // Enviar un mensaje
  Future<void> enviarMensaje({
    required String emisorId,
    required String receptorId,
    required String contenido,
  }) async {
    await _client.from('mensajes').insert({
      'emisor_id': emisorId,
      'receptor_id': receptorId,
      'contenido': contenido,
    });
  }

  // Obtener el historial y escuchar nuevos mensajes en tiempo real (WebSocket)
  Stream<List<Map<String, dynamic>>> obtenerMensajesStream({
    required String usuarioA,
    required String usuarioB,
  }) {
    final String conversacionId = usuarioA.compareTo(usuarioB) < 0
        ? '${usuarioA}_$usuarioB'
        : '${usuarioB}_$usuarioA';

    return _client
        .from('mensajes')
        .stream(primaryKey: ['id'])
        .eq('conversacion_id', conversacionId)
        .map((maps) {
      final list = List<Map<String, dynamic>>.from(maps);

      // 👇 FORZAMOS EL ORDEN: Del más antiguo al más nuevo
      list.sort((a, b) {
        final fechaA = a['created_at'] as String;
        final fechaB = b['created_at'] as String;
        return fechaA.compareTo(fechaB);
      });

      return list;
    });
  }

  // Obtener la lista de conversaciones (Bandeja de entrada)
  Future<List<Map<String, dynamic>>> obtenerBandejaDeEntrada(String miId) async {
    // 1. Traemos todos los mensajes donde participo, ordenados del más nuevo al más viejo
    final response = await _client
        .from('mensajes')
        .select()
        .or('emisor_id.eq.$miId,receptor_id.eq.$miId')
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> mensajes = List<Map<String, dynamic>>.from(response);

    // 2. Agrupamos por conversacion_id para quedarnos solo con el último mensaje de cada chat
    final Map<String, Map<String, dynamic>> chatsUnicos = {};
    final List<String> otrosUsuariosIds = [];

    for (var msg in mensajes) {
      final convId = msg['conversacion_id'];
      if (!chatsUnicos.containsKey(convId)) {
        chatsUnicos[convId] = msg;
        // Guardamos el ID de la otra persona
        final otroId = msg['emisor_id'] == miId ? msg['receptor_id'] : msg['emisor_id'];
        otrosUsuariosIds.add(otroId);
      }
    }

    if (chatsUnicos.isEmpty) return [];

    // 3. Buscamos los nombres de las otras personas en la tabla perfiles
    final perfilesResponse = await _client
        .from('perfiles')
        .select('id, nombre, apellido')
        .inFilter('id', otrosUsuariosIds);

    final List<Map<String, dynamic>> perfiles = List<Map<String, dynamic>>.from(perfilesResponse);

    // 4. Armamos la lista final combinando el último mensaje con el nombre del usuario
    final List<Map<String, dynamic>> bandeja = [];

    for (var chat in chatsUnicos.values) {
      final otroId = chat['emisor_id'] == miId ? chat['receptor_id'] : chat['emisor_id'];
      final perfil = perfiles.firstWhere((p) => p['id'] == otroId, orElse: () => {'nombre': 'Usuario', 'apellido': ''});

      bandeja.add({
        'otroId': otroId,
        'nombre': '${perfil['nombre']} ${perfil['apellido'] ?? ''}'.trim(),
        'ultimoMensaje': chat['contenido'],
        'fecha': chat['created_at'],
        'conversacion_id': chat['conversacion_id'],
      });
    }

    return bandeja;
  }
}