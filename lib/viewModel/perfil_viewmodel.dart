// lib/viewmodels/perfil_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_viewmodel.dart';

final perfilProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // 👇 LA MAGIA ESTÁ AQUÍ: Escuchamos el estado de autenticación
  // Si el usuario cambia, este provider se reinicia automáticamente.
  final authState = ref.watch(authStateProvider);

  // Obtenemos el usuario actual basado en el estado escuchado
  final user = authState.value?.session?.user;

  if (user == null) return null;

  try {
    final perfil = await Supabase.instance.client
        .from('perfiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (perfil == null) {
      print("⚠️ Perfil no encontrado en la BD para el ID: ${user.id}");
      return null;
    }

    Map<String, dynamic>? negocio;

    if (perfil['rol'] == 'emprendedor') {
      negocio = await Supabase.instance.client
          .from('emprendedores')
          .select()
          .eq('usuario_id', user.id)
          .maybeSingle();
    }

    return {
      'perfil': perfil,
      'negocio': negocio,
    };
  } catch (e) {
    print("❌ Error en perfilProvider: $e");
    rethrow;
  }
});