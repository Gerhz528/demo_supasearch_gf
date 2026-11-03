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
}