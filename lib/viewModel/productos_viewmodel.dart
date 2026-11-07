// lib/viewmodels/productos_viewmodel.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/productos_repository.dart';

final productosRepositoryProvider = Provider<ProductosRepository>((ref) {
  return ProductosRepository();
});

final productosEmprendedorProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, emprendedorId) async {
  final repository = ref.watch(productosRepositoryProvider);
  return await repository.obtenerProductosEmprendedor(emprendedorId);
});