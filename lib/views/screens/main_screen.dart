// lib/views/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/location_service.dart';
import '../../viewModel/auth_viewmodel.dart';
import '../../viewModel/perfil_viewmodel.dart';
import '../../viewModel/lugares_viewmodel.dart';


class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  MapboxMap? mapboxMap;

  // 1. DECLARACIÓN DE LA VARIABLE (Faltaba esto)
  PointAnnotationManager? _annotationManager;

  // 2. MÉTODO PARA PINTAR LOS LUGARES (Faltaba esto)
  void _pintarLugares() async {
    if (_annotationManager == null) return;

    // Leemos los datos del provider
    final lugaresAsync = ref.read(lugaresProvider);

    lugaresAsync.whenData((lugares) async {
      // Borramos los pines anteriores
      await _annotationManager?.deleteAll();

      // Recorremos los lugares y creamos un pin por cada uno
      for (var lugar in lugares) {
        await _annotationManager?.create(
          PointAnnotationOptions(
            geometry: Point(
              coordinates: Position(lugar.longitud, lugar.latitud), // Longitud primero
            ),
          ),
        );
      }
      print("✅ Se pintaron ${lugares.length} lugares en el mapa.");
    });
  }

  // 3. CREACIÓN DEL MAPA Y GPS
  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    // Activar el "punto azul" de Mapbox
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: true,
        pulsingEnabled: true,
      ),
    );

    // Obtener ubicación del usuario
    final locationService = LocationService();
    final position = await locationService.obtenerUbicacionActual();

    if (position != null) {
      mapboxMap.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(position.longitude, position.latitude)),
          zoom: 15.0,
        ),
      );
    } else {
      // Si falla el GPS, centrar en San Salvador
      mapboxMap.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(-89.2182, 13.6929)),
          zoom: 12.0,
        ),
      );
    }

    // Inicializar el administrador de pines
    _annotationManager = await mapboxMap.annotations.createPointAnnotationManager();

    // Pintar los lugares
    _pintarLugares();
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    // Verificamos si es emprendedor (asumiendo que data['negocio'] no es nulo)
    final esEmprendedor = perfilAsync.value?['negocio'] != null;

    // Escuchamos si los lugares cambian en la BD para volver a pintarlos
    ref.listen(lugaresProvider, (previous, next) {
      if (next.hasValue) {
        _pintarLugares();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: perfilAsync.when(
          loading: () => const Text('Cargando...'),
          error: (err, stack) => Text('Error: $err', style: const TextStyle(fontSize: 12)),
          data: (data) {
            if (data == null || data['perfil'] == null) {
              return const Text('Usuario sin perfil');
            }
            final perfil = data['perfil'];
            final negocio = data['negocio'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(perfil['nombre'] ?? 'Usuario', style: const TextStyle(fontSize: 18)),
                if (negocio != null)
                  Text(
                    negocio['nombre_negocio'] ?? 'Mi Negocio',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            );
          },
        ),
      ),

      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // Pestaña 0: Mapa
          MapWidget(
            key: const ValueKey("mapWidget"),
            styleUri: MapboxStyles.MAPBOX_STREETS,
            onMapCreated: _onMapCreated,
          ),
          // Pestaña 1: Chat
          const Center(
            child: Text('El Chat estará aquí pronto', style: TextStyle(fontSize: 18)),
          ),
          // Pestaña 2: Ajustes
          _ConfiguracionTab(perfilAsync: perfilAsync),
        ],
      ),

      //PARA MOSTRAR EL BOTÓN DE ACTUALIZACIÓN DE UBICACIÓN
      floatingActionButton: (_selectedIndex == 0 && esEmprendedor)
          ? FloatingActionButton.extended(
        onPressed: () async {
          // 1. Mostramos un indicador de carga
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obteniendo tu ubicación GPS...')),
          );

          // 2. Obtenemos el GPS
          final locationService = LocationService();
          final position = await locationService.obtenerUbicacionActual();

          if (position != null) {
            // 3. Actualizamos en Supabase
            final negocioNombre = perfilAsync.value!['negocio']['nombre_negocio'] ?? 'Mi Puesto';
            final user = Supabase.instance.client.auth.currentUser;

            await ref.read(supabaseServiceProvider).actualizarUbicacionEmprendedor(
              usuarioId: user!.id,
              nombreNegocio: negocioNombre,
              latitud: position.latitude,
              longitud: position.longitude,
            );

            // 4. Refrescamos los datos del mapa (¡El pin se moverá!)
            ref.invalidate(lugaresProvider);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('¡Ubicación actualizada en el mapa!'), backgroundColor: Colors.green),
              );
            }
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No se pudo obtener el GPS. Revisa tus permisos.'), backgroundColor: Colors.red),
              );
            }
          }
        },
        icon: const Icon(Icons.my_location),
        label: const Text('Actualizar mi ubicación'),
      )
          : null, // Si no es emprendedor o no está en la pestaña del mapa, el botón se oculta


      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}

// --- WIDGET PARA LA PESTAÑA DE CONFIGURACIÓN ---
class _ConfiguracionTab extends ConsumerStatefulWidget {
  final AsyncValue<Map<String, dynamic>?> perfilAsync;
  const _ConfiguracionTab({required this.perfilAsync});

  @override
  ConsumerState<_ConfiguracionTab> createState() => _ConfiguracionTabState();
}

class _ConfiguracionTabState extends ConsumerState<_ConfiguracionTab> {
  late TextEditingController _nombreController;
  late TextEditingController _negocioController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController();
    _negocioController = TextEditingController();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _negocioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.perfilAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.perfilAsync.hasError) {
      return Center(child: Text('Error al cargar ajustes: ${widget.perfilAsync.error}'));
    }

    final data = widget.perfilAsync.value;

    if (data == null || data['perfil'] == null) {
      return const Center(child: Text('No se encontraron datos del perfil.'));
    }

    final perfil = data['perfil'];
    final bool esEmprendedor = data['negocio'] != null;
    final user = Supabase.instance.client.auth.currentUser;

    // Llenamos los controladores si están vacíos
    if (_nombreController.text.isEmpty) _nombreController.text = perfil['nombre'] ?? '';
    if (esEmprendedor && _negocioController.text.isEmpty) {
      _negocioController.text = data['negocio']['nombre_negocio'] ?? '';
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Editar Información', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          TextField(
            controller: _nombreController,
            decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),

          if (esEmprendedor) ...[
            TextField(
              controller: _negocioController,
              decoration: const InputDecoration(labelText: 'Nombre del Negocio', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
          ],

          ElevatedButton(
            onPressed: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              try {
                await ref.read(supabaseServiceProvider).actualizarPerfil(
                  usuarioId: user!.id,
                  nombre: _nombreController.text.trim(),
                  nombreNegocio: esEmprendedor ? _negocioController.text.trim() : null,
                );
                ref.invalidate(perfilProvider);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: _isLoading ? const CircularProgressIndicator() : const Text('Guardar Cambios'),
          ),

          const Spacer(),

          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              // 1. Cerramos sesión en Supabase
              await ref.read(authViewModelProvider.notifier).logout();
              // 2. Destruimos la caché de los datos para que el próximo usuario cargue los suyos
              ref.invalidate(perfilProvider);
              ref.invalidate(lugaresProvider);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}