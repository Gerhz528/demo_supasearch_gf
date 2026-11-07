// lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario.dart';
import 'dart:io';

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

      // 2. Si enviaron nombre de negocio, actualizarlo en emprendedores Y en lugares
      if (nombreNegocio != null) {
        // Actualizamos el nombre del negocio
        await _client.from('emprendedores').update({'nombre_negocio': nombreNegocio}).eq('usuario_id', usuarioId);

        // 👇 Buscamos el ID del emprendedor para actualizar sus lugares
        final emp = await _client.from('emprendedores').select('id').eq('usuario_id', usuarioId).single();

        // Actualizamos el nombre en la tabla 'lugares' para que el mapa lo refleje
        await _client.from('lugares').update({'nombre': nombreNegocio}).eq('emprendedor_id', emp['id']);
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

  //Subir imagen al bucket de imagenes
  Future<String?> subirImagen(File imagen) async {
    try {
      // Generamos un nombre único usando la fecha actual
      final fileName = 'producto_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Subimos el archivo
      await _client.storage.from('Images').upload(fileName, imagen);

      // Obtenemos la URL pública
      return _client.storage.from('Images').getPublicUrl(fileName);
    } catch (e) {
      print('Error subiendo imagen: $e');
      return null;
    }
  }

  // Crear un producto para el emprendedor logueado
  Future<void> crearProducto({
    required String emprendedorId,
    required String nombre,
    required double precio,
    String? descripcion,
    String? imagenUrl,
  }) async {
    await _client.from('productos').insert({
      'emprendedor_id': emprendedorId,
      'nombre': nombre,
      'precio': precio,
      'descripcion': descripcion,
      'imagen_url': imagenUrl,
    });
  }

  Future<List<Map<String, dynamic>>> obtenerProductos(String emprendedorId) async {
    final response = await _client
        .from('productos')
        .select()
        .eq('emprendedor_id', emprendedorId);
    return List<Map<String, dynamic>>.from(response);
  }

  // Borrar un producto
  Future<void> borrarProducto(String productoId) async {
    await _client.from('productos').delete().eq('id', productoId);
  }

}

