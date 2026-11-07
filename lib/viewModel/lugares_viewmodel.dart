// lib/viewmodels/lugares_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lugar.dart'; // Asegúrate de que este modelo exista

// Este Provider se encarga de buscar los lugares en Supabase
final lugaresProvider = FutureProvider<List<Lugar>>((ref) async {
  try {
    // Hacemos la consulta a la tabla 'lugares'
    final response = await Supabase.instance.client
        .from('lugares')
        .select()
        .order('created_at', ascending: false);

    // Convertimos la respuesta (que es un JSON) a una lista de objetos 'Lugar'
    return (response as List).map((json) => Lugar.fromJson(json)).toList();

  } catch (e) {
    print("❌ Error al cargar lugares: $e");
    throw Exception('Error al cargar lugares');
  }
});