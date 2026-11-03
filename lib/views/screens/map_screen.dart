// lib/views/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../../viewModel/auth_viewmodel.dart';
//import '../../viewmodel/auth_viewmodel.dart' hide authViewModelProvider; // Para el botón de cerrar sesión

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapboxMap? mapboxMap;

  _onMapCreated(MapboxMap mapboxMap) {
    this.mapboxMap = mapboxMap;

    // Centrado en San Salvador
    mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(-89.2182, 13.6929)),
        zoom: 12.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Mapa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Cerrar sesión
              ref.read(authViewModelProvider.notifier).logout();
            },
          )
        ],
      ),
      // Usamos un Column para dividir la pantalla verticalmente
      body: Column(
        children: [
          // 1. El mapa ocupa todo el espacio disponible (Expanded)
          Expanded(
            child: MapWidget(
              key: const ValueKey("mapWidget"),
              styleUri: MapboxStyles.MAPBOX_STREETS,
              onMapCreated: _onMapCreated,
            ),
          ),

          // 2. El espacio de abajo (Altura fija de 200 píxeles)
          Container(
            height: 200, // Aquí puedes ajustar el alto que quieras
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: const Center(
              child: Text(
                'Espacio reservado para la lista de productos o botones',
                style: TextStyle(color: Colors.grey, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}