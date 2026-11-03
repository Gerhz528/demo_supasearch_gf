// lib/models/usuario.dart
class Usuario {
  final String id;
  final String email;
  final String nombre;
  final String? apellido; // El '?' significa que puede ser nulo (null)
  final String rol; // 'usuario' o 'emprendedor'

  // Constructor
  Usuario({
    required this.id,
    required this.email,
    required this.nombre,
    this.apellido,
    required this.rol,
  });

  // 1. Convierte los datos de Supabase (Mapa) a un objeto Usuario
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      apellido: json['apellido'] as String?,
      rol: json['rol'] as String,
    );
  }

  // 2. Convierte el objeto Usuario a un Mapa para enviarlo a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'rol': rol,
    };
  }
}