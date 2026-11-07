// lib/repositories/productos_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductosRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> obtenerProductosEmprendedor(String emprendedorId) async {
    final response = await _client
        .from('productos')
        .select()
        .eq('emprendedor_id', emprendedorId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}