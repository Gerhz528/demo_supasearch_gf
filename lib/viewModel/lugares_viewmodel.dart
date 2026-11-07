// lib/viewmodels/lugares_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lugar.dart'; // Asegúrate de que este modelo exista
import '../repositories/lugares_repository.dart';

// 1. Inyectamos el Repository
final lugaresRepositoryProvider = Provider<LugaresRepository>((ref) {
  return LugaresRepository();
});

// 2. El ViewModel usa el Repository
final lugaresProvider = FutureProvider<List<Lugar>>((ref) async {
  final repository = ref.watch(lugaresRepositoryProvider);
  return await repository.obtenerLugares();
});