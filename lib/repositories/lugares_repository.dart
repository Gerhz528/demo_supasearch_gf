// lib/repositories/lugares_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lugar.dart';

class LugaresRepository {
  final SupabaseClient _client = Supabase.instance.client;

  // El Repository se encarga de traer los datos y convertirlos a Modelos
  Future<List<Lugar>> obtenerLugares() async {
    try {
      final response = await _client
          .from('lugares')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((json) => Lugar.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener lugares: $e');
    }
  }
}