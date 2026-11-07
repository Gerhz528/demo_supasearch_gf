// lib/viewmodels/lugares_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lugar.dart'; // Asegúrate de que este modelo exista

// Este Provider se encarga de buscar los lugares en Supabase
final lugaresProvider = StreamProvider<List<Lugar>>((ref) {
  // Escuchamos los cambios en la tabla 'lugares' en tiempo real
  final stream = Supabase.instance.client
      .from('lugares')
      .stream(primaryKey: ['id'])
      .order('created_at')
      .map((maps) => maps.map((map) => Lugar.fromJson(map)).toList());

  return stream;
});