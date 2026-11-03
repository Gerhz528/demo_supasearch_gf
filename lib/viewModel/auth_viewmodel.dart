// lib/viewmodels/auth_viewmodel.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. INYECCIÓN DE DEPENDENCIA: Creamos un Provider para el Service
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

// 2. EL VIEWMODEL: Maneja el estado de la UI usando AsyncValue
class AuthViewModel extends AsyncNotifier<void> {
  late SupabaseService _supabaseService;

  // build() se ejecuta automáticamente al iniciar
  @override
  FutureOr<void> build() {
    // Aquí inyectamos el Service usando Riverpod
    _supabaseService = ref.watch(supabaseServiceProvider);
    // El estado inicial es 'data' (sin cargar)
  }

  // Método para registrar
  Future<void> registrar({
    required String email,
    required String password,
    required String nombre,
    required String apellido,
    required String rol,
    String? nombreNegocio,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _supabaseService.registrarUsuario(
        email: email,
        password: password,
        nombre: nombre,
        apellido: apellido,
        rol: rol,
        nombreNegocio: nombreNegocio,
      );
    });
  }

  // Método para iniciar sesión
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await _supabaseService.iniciarSesion(
        email: email,
        password: password,
      );
    });
  }

  // Método para cerrar sesión
  Future<void> logout() async {
    await _supabaseService.cerrarSesion();
  }
}

// 3. EL PROVIDER DEL VIEWMODEL
final authViewModelProvider = AsyncNotifierProvider<AuthViewModel, void>(() {
  return AuthViewModel();
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});