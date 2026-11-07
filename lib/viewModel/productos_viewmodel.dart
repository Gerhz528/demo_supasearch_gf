// lib/viewmodels/productos_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Usamos un 'family' provider porque necesitamos pasarle el ID del emprendedor
// para saber de quién son los productos que queremos buscar.
final productosEmprendedorProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, emprendedorId) async {
  final response = await Supabase.instance.client
      .from('productos')
      .select()
      .eq('emprendedor_id', emprendedorId)
      .order('created_at', ascending: false); // Los más nuevos primero

  return List<Map<String, dynamic>>.from(response);
});