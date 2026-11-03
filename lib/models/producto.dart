// lib/models/producto.dart
class Producto {
  final String id;
  final String emprendedorId;
  final String nombre;
  final double precio;
  final String? descripcion;
  final String? imagenUrl;

  Producto({
    required this.id,
    required this.emprendedorId,
    required this.nombre,
    required this.precio,
    this.descripcion,
    this.imagenUrl,
  });

  // 1. Convierte los datos de Supabase (Mapa) a un objeto Producto
  factory Producto.fromJson(Map<String, dynamic> json) {
    return Producto(
      id: json['id'] as String,
      emprendedorId: json['emprendedor_id'] as String,
      nombre: json['nombre'] as String,
      precio: (json['precio'] as num).toDouble(),
      descripcion: json['descripcion'] as String?,
      imagenUrl: json['imagen_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emprendedor_id': emprendedorId,
      'nombre': nombre,
      'precio': precio,
      'descripcion': descripcion,
      'imagen_url': imagenUrl,
    };
  }
}