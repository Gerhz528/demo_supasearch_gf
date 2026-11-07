// lib/views/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/lugar.dart';
import '../../services/location_service.dart';
import '../../viewModel/auth_viewmodel.dart';
import '../../viewModel/perfil_viewmodel.dart';
import '../../viewModel/lugares_viewmodel.dart';
import '../../viewModel/productos_viewmodel.dart';
import 'crear_producto_screen.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import '../../services/location_service.dart';
import 'crear_producto_screen.dart';


class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  MapboxMap? mapboxMap;

  // Usamos CircleAnnotationManager para los pines rojos
  CircleAnnotationManager? _circleAnnotationManager;

  void _pintarLugares() async {
    if (_circleAnnotationManager == null) return;

    final lugaresAsync = ref.read(lugaresProvider);

    lugaresAsync.whenData((lugares) async {
      print("📍 Lugares encontrados para pintar: ${lugares.length}");

      await _circleAnnotationManager?.deleteAll();

      for (var lugar in lugares) {
        await _circleAnnotationManager?.create(
          CircleAnnotationOptions(
            geometry: Point(coordinates: Position(lugar.longitud, lugar.latitud)),
            circleColor: Colors.red.value,
            circleRadius: 10.0,
            circleStrokeColor: Colors.white.value,
            circleStrokeWidth: 2.0,
            customData: {'lugarId': lugar.id},
          ),
        );
      }
    });
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    this.mapboxMap = mapboxMap;

    // 1. Primero pedimos la ubicación (esto fuerza a que salte la ventana de permisos si no se ha dado)
    final position = await LocationService().obtenerUbicacionActual();

    // 2. Esperamos a que el perfil cargue por completo usando '.future'
    final perfilData = await ref.read(perfilProvider.future);
    final esEmprendedor = perfilData?['negocio'] != null;

    // 3. Encendemos el punto azul con la seguridad de que ya sabemos el rol
    await mapboxMap.location.updateSettings(
      LocationComponentSettings(
        enabled: esEmprendedor, // Solo el emprendedor lo verá
        pulsingEnabled: true,
      ),
    );

    // 4. Centramos la cámara en la ubicación obtenida
    mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(position?.longitude ?? -89.2182, position?.latitude ?? 13.6929)),
        zoom: 15.0,
      ),
    );

    _circleAnnotationManager = await mapboxMap.annotations.createCircleAnnotationManager();

    _circleAnnotationManager?.tapEvents(
      onTap: (CircleAnnotation annotation) {
        final lugarId = annotation.customData?['lugarId'] as String?;
        if (lugarId != null) {
          final lugares = ref.read(lugaresProvider).value ?? [];
          final lugarSeleccionado = lugares.firstWhere((l) => l.id == lugarId);
          _mostrarInfoLugar(lugarSeleccionado);
        }
      },
    );

    _pintarLugares();
  }

  void _mostrarInfoLugar(Lugar lugar) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 👈 Permite que la ventana crezca si hay muchos productos
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        // 👇 Envolvemos todo en SafeArea
        return SafeArea(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: ref.read(supabaseServiceProvider).obtenerProductos(lugar.emprendedorId),
            builder: (context, snapshot) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Un pequeño indicador visual de que se puede arrastrar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(lugar.nombre, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(lugar.direccion ?? 'Ubicación actual', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Divider(height: 30),
                    const Text('Productos que ofrece:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    // Hacemos que la lista de productos sea scrolleable si hay muchos
                    Flexible(
                      child: snapshot.connectionState == ConnectionState.waiting
                          ? const Center(child: CircularProgressIndicator())
                          : (!snapshot.hasData || snapshot.data!.isEmpty)
                          ? const Text('No hay productos aún.')
                          : ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final prod = snapshot.data![index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: prod['imagen_url'] != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                prod['imagen_url'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            )
                                : const Icon(Icons.shopping_bag, color: Colors.blue),
                            title: Text(prod['nombre']),
                            subtitle: Text(prod['descripcion'] ?? ''),
                            trailing: Text('\$${prod['precio']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final perfilAsync = ref.watch(perfilProvider);
    final bool esEmprendedor = perfilAsync.value?['negocio'] != null;
    final String? emprendedorId = esEmprendedor ? perfilAsync.value!['negocio']['id'] : null;

    // Escuchamos cambios en la base de datos
    ref.listen(lugaresProvider, (previous, next) {
      if (next.hasValue) {
        _pintarLugares();
      }
    });

    final List<Widget> pantallas = [
      MapWidget(key: const ValueKey("mapWidget"), styleUri: MapboxStyles.MAPBOX_STREETS, onMapCreated: _onMapCreated),
      if (esEmprendedor) _ProductosTab(emprendedorId: emprendedorId!),
      const Center(child: Text('Chat en construcción...')),
      _ConfiguracionTab(perfilAsync: perfilAsync),
    ];

    final List<NavigationDestination> destinos = [
      const NavigationDestination(icon: Icon(Icons.map), label: 'Mapa'),
      if (esEmprendedor) const NavigationDestination(icon: Icon(Icons.store), label: 'Productos'),
      const NavigationDestination(icon: Icon(Icons.chat), label: 'Chat'),
      const NavigationDestination(icon: Icon(Icons.settings), label: 'Ajustes'),
    ];

    if (_selectedIndex >= pantallas.length) _selectedIndex = 0;

    return Scaffold(
      appBar: AppBar(
        title: perfilAsync.when(
          loading: () => const Text('Cargando...'),
          error: (err, stack) => const Text('Error'),
          data: (data) {
            if (data == null || data['perfil'] == null) return const Text('App');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['perfil']['nombre'] ?? 'Usuario', style: const TextStyle(fontSize: 18)),
                if (data['negocio'] != null)
                  Text(data['negocio']['nombre_negocio'] ?? 'Emprendedor', style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            );
          },
        ),
      ),

      body: IndexedStack(index: _selectedIndex, children: pantallas),

      floatingActionButton: (_selectedIndex == 0 && esEmprendedor)
          ? FloatingActionButton.extended(
        onPressed: () async {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Obteniendo tu ubicación GPS...')),
          );

          final position = await LocationService().obtenerUbicacionActual();

          if (position != null) {
            final negocioNombre = perfilAsync.value!['negocio']['nombre_negocio'] ?? 'Mi Puesto';
            final user = Supabase.instance.client.auth.currentUser;

            await ref.read(supabaseServiceProvider).actualizarUbicacionEmprendedor(
              usuarioId: user!.id,
              nombreNegocio: negocioNombre,
              latitud: position.latitude,
              longitud: position.longitude,
            );

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
        label: const Text('Actualizar ubicación'),
      )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: destinos,
      ),
    );
  }
}

// ==========================================
// PESTAÑA DE PRODUCTOS (Solo Emprendedores)
// ==========================================
class _ProductosTab extends ConsumerWidget {
  final String emprendedorId;
  const _ProductosTab({required this.emprendedorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productosAsync = ref.watch(productosEmprendedorProvider(emprendedorId));

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Tomar foto y agregar producto'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CrearProductoScreen(emprendedorId: emprendedorId)),
                );
                if (result == true) {
                  ref.invalidate(productosEmprendedorProvider(emprendedorId));
                }
              },
            ),
            const SizedBox(height: 20),
            const Text('Mis Productos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Expanded(
              child: productosAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (productos) {
                  if (productos.isEmpty) return const Center(child: Text('Aún no tienes productos.'));
                  return ListView.builder(
                    itemCount: productos.length,
                    itemBuilder: (context, index) {
                      final prod = productos[index];
                      return Card(
                        child: ListTile(
                          leading: prod['imagen_url'] != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(prod['imagen_url'], width: 50, height: 50, fit: BoxFit.cover))
                              : const Icon(Icons.image_not_supported),
                          title: Text(prod['nombre']),
                          subtitle: Text('\$${prod['precio']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await ref.read(supabaseServiceProvider).borrarProducto(prod['id']);
                              ref.invalidate(productosEmprendedorProvider(emprendedorId));
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PESTAÑA DE CONFIGURACIÓN (Ajustes)
// ==========================================
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
    if (widget.perfilAsync.isLoading) return const Center(child: CircularProgressIndicator());
    final data = widget.perfilAsync.value;
    if (data == null || data['perfil'] == null) return const Center(child: Text('Sin datos'));

    final perfil = data['perfil'];
    final bool esEmprendedor = data['negocio'] != null;
    final user = Supabase.instance.client.auth.currentUser;

    if (_nombreController.text.isEmpty) _nombreController.text = perfil['nombre'] ?? '';
    if (esEmprendedor && _negocioController.text.isEmpty) _negocioController.text = data['negocio']['nombre_negocio'] ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Editar Información', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _nombreController, decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          if (esEmprendedor) ...[
            TextField(controller: _negocioController, decoration: const InputDecoration(labelText: 'Nombre del Negocio (Opcional)', border: OutlineInputBorder())),
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
                ref.invalidate(lugaresProvider);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              } finally {
                setState(() => _isLoading = false);
              }
            },
            child: _isLoading ? const CircularProgressIndicator() : const Text('Guardar Cambios'),
          ),
          const SizedBox(height: 40),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await ref.read(authViewModelProvider.notifier).logout();
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