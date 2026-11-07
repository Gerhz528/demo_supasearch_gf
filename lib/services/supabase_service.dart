// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';

class SupabaseService {
  // Instancia del cliente de Supabase
  final SupabaseClient _client = Supabase.instance.client;

  // 1. REGISTRAR USUARIO
  Future<AuthResponse> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String rol, // <-- Nuevo
    String? nombreNegocio, // <-- Nuevo (solo para emprendedores)
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nombre': nombre,
          'apellido': apellido,
          'rol': rol, // <-- Se envía al Trigger
          'nombre_negocio': nombreNegocio, // <-- Se envía al Trigger
        },
      );
      return response;
    } catch (e) {
      throw Exception('Error al registrar: $e');
    }
  }

  // 2. INICIAR SESIÓN
  Future<AuthResponse> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Error al iniciar sesión: $e');
    }
  }

  // 3. CERRAR SESIÓN
  Future<void> cerrarSesion() async {
    await _client.auth.signOut();
  }

  // 4. OBTENER EL USUARIO ACTUAL
  User? get usuarioActual => _client.auth.currentUser;

  // Actualizar datos del perfil (para la pantalla de configuración)
  Future<void> actualizarPerfil({
    required String usuarioId,
    required String nombre,
    String? nombreNegocio,
  }) async {
    try {
      // 1. Actualizar el nombre en la tabla perfiles
      await _client.from('perfiles').update({'nombre': nombre}).eq('id', usuarioId);

      // 2. Si enviaron nombre de negocio, actualizarlo en la tabla emprendedores
      if (nombreNegocio != null) {
        await _client.from('emprendedores').update({'nombre_negocio': nombreNegocio}).eq('usuario_id', usuarioId);
      }
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  Future<void> actualizarUbicacionEmprendedor({
    required String usuarioId,
    required String nombreNegocio,
    required double latitud,
    required double longitud,
  }) async {
    // 1. Buscamos el ID del emprendedor usando el usuario logueado
    final emprendedor = await _client
        .from('emprendedores')
        .select('id')
        .eq('usuario_id', usuarioId)
        .single();

    final emprendedorId = emprendedor['id'];

    // 2. Buscamos si ya tiene un "lugar" (puesto ambulante) registrado
    final lugares = await _client
        .from('lugares')
        .select('id')
        .eq('emprendedor_id', emprendedorId);

    if (lugares.isEmpty) {
      // Si no tiene, lo creamos
      await _client.from('lugares').insert({
        'emprendedor_id': emprendedorId,
        'nombre': nombreNegocio,
        'latitud': latitud,
        'longitud': longitud,
        'direccion': 'Ubicación actual del vendedor',
      });
    } else {
      // Si ya tiene uno, actualizamos sus coordenadas
      await _client.from('lugares').update({
        'latitud': latitud,
        'longitud': longitud,
      }).eq('id', lugares[0]['id']);
    }
  }

}

