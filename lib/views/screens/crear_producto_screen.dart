// lib/views/screens/crear_producto_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewModel/auth_viewmodel.dart';
import '../../viewModel/perfil_viewmodel.dart';
import '../../viewModel/lugares_viewmodel.dart';
import '../../services/supabase_service.dart';

class CrearProductoScreen extends ConsumerStatefulWidget {
  final String emprendedorId;

  const CrearProductoScreen({super.key, required this.emprendedorId});

  @override
  ConsumerState<CrearProductoScreen> createState() => _CrearProductoScreenState();
}

class _CrearProductoScreenState extends ConsumerState<CrearProductoScreen> {
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _descripcionController = TextEditingController();
  File? _imagenSeleccionada;
  bool _isLoading = false;

  // Función para abrir la cámara o galería
  Future<void> _seleccionarImagen(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imagenSeleccionada = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar Producto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- SECCIÓN DE IMAGEN ---
            GestureDetector(
              onTap: () {
                // Muestra un menú para elegir cámara o galería
                showModalBottomSheet(
                  context: context,
                  builder: (context) => SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Tomar foto'),
                          onTap: () {
                            Navigator.pop(context);
                            _seleccionarImagen(ImageSource.camera);
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Elegir de la galería'),
                          onTap: () {
                            Navigator.pop(context);
                            _seleccionarImagen(ImageSource.gallery);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: _imagenSeleccionada != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imagenSeleccionada!, fit: BoxFit.cover),
                )
                    : const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Toca para tomar o subir una foto', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- CAMPOS DE TEXTO ---
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre del producto', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _precioController,
              decoration: const InputDecoration(labelText: 'Precio', border: OutlineInputBorder(), prefixText: '\$ '),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción breve (Opcional)', border: OutlineInputBorder()),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardarProducto,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Guardar Producto'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarProducto() async {
    final nombre = _nombreController.text.trim();
    final precioStr = _precioController.text.trim();
    final descripcion = _descripcionController.text.trim();

    if (nombre.isEmpty || precioStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre y el precio son obligatorios'), backgroundColor: Colors.orange));
      return;
    }

    final precio = double.tryParse(precioStr);
    if (precio == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El precio debe ser un número válido'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imagenUrl;

      // 1. Si hay imagen, la subimos a Supabase Storage primero
      if (_imagenSeleccionada != null) {
        imagenUrl = await ref.read(supabaseServiceProvider).subirImagen(_imagenSeleccionada!);
      }

      // 2. Guardamos el producto en la base de datos
      await ref.read(supabaseServiceProvider).crearProducto(
        emprendedorId: widget.emprendedorId,
        nombre: nombre,
        precio: precio,
        descripcion: descripcion.isEmpty ? null : descripcion,
        imagenUrl: imagenUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Producto agregado con éxito!'), backgroundColor: Colors.green));
        Navigator.pop(context, true); // Retorna 'true' para avisar que se guardó algo
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}