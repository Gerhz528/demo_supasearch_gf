// lib/models/emprendedor.dart
class Emprendedor {
  final String id;
  final String usuarioId; // La llave foránea
  final String nombreNegocio;
  final String? descripcion;

  Emprendedor({
    required this.id,
    required this.usuarioId,
    required this.nombreNegocio,
    this.descripcion,
  });

  // 1. Convierte los datos de Supabase (Mapa) a un objeto Lugar
  factory Emprendedor.fromJson(Map<String, dynamic> json) {
    return Emprendedor(
      id: json['id'] as String,
      // Ojo: en Supabase la columna se llama 'usuario_id' (con guion bajo)
      usuarioId: json['usuario_id'] as String,
      nombreNegocio: json['nombre_negocio'] as String,
      descripcion: json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // No enviamos el 'id' porque Supabase lo genera solo (gen_random_uuid)
      'usuario_id': usuarioId,
      'nombre_negocio': nombreNegocio,
      'descripcion': descripcion,
    };
  }
}