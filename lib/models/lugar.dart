// lib/models/lugar.dart
class Lugar {
  final String id;
  final String emprendedorId;
  final String nombre;
  final double latitud;
  final double longitud;
  final String? direccion;

  Lugar({
    required this.id,
    required this.emprendedorId,
    required this.nombre,
    required this.latitud,
    required this.longitud,
    this.direccion,
  });

  // 1. Convierte los datos de Supabase (Mapa) a un objeto Lugar
  factory Lugar.fromJson(Map<String, dynamic> json) {
    return Lugar(
      id: json['id'] as String,
      emprendedorId: json['emprendedor_id'] as String,
      nombre: json['nombre'] as String,
      // Supabase a veces devuelve los decimales como int si no tienen punto,
      // por eso usamos (json['latitud'] as num).toDouble()
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      direccion: json['direccion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emprendedor_id': emprendedorId,
      'nombre': nombre,
      'latitud': latitud,
      'longitud': longitud,
      'direccion': direccion,
    };
  }
}