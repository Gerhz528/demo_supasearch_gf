// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {

  // Método para obtener la ubicación actual
  Future<Position?> obtenerUbicacionActual() async {
    bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
    if (!servicioHabilitado) {
      // El GPS está apagado en el teléfono
      return null;
    }

    LocationPermission permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
      if (permiso == LocationPermission.denied) {
        // El usuario denegó el permiso
        return null;
      }
    }

    if (permiso == LocationPermission.deniedForever) {
      // El usuario denegó permanentemente (toca ir a ajustes)
      return null;
    }

    // Si llegamos aquí, tenemos permiso. Obtenemos las coordenadas.
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}