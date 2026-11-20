// lib/viewmodels/chat_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/chat_repository.dart';
import 'auth_viewmodel.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());

// Provider que nos da el stream de mensajes entre dos usuarios
final mensajesStreamProvider = StreamProvider.family<List<Map<String, dynamic>>, ({String usuarioA, String usuarioB})>((ref, params) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.obtenerMensajesStream(usuarioA: params.usuarioA, usuarioB: params.usuarioB);
});

// Provider para la bandeja de entrada
final bandejaEntradaProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final miId = Supabase.instance.client.auth.currentUser!.id;
  final repository = ref.watch(chatRepositoryProvider);
  return await repository.obtenerBandejaDeEntrada(miId);
});