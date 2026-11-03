// lib/views/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewModel/auth_viewmodel.dart';


class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _negocioController = TextEditingController();
  String _rolSeleccionado = 'usuario';

  bool _esLogin = true; // Variable para alternar entre Login y Registro

  @override
  Widget build(BuildContext context) {
    // ESCUCHAMOS EL VIEWMODEL (Aquí ocurre la magia de MVVM)
    final authState = ref.watch(authViewModelProvider);

    // Escuchamos si hay errores o éxitos para mostrar alertas
    ref.listen<AsyncValue<void>>(authViewModelProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${next.error}'), backgroundColor: Colors.red),
        );
      } else if (next is AsyncData && previous is AsyncLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Operación exitosa!'), backgroundColor: Colors.green),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(_esLogin ? 'Iniciar Sesión' : 'Registrarse')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            if (!_esLogin) ...[
              TextField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            // Selector de Rol (Solo visible en modo Registro)
            if (!_esLogin) ...[
              DropdownButtonFormField<String>(
                value: _rolSeleccionado,
                decoration: const InputDecoration(labelText: '¿Qué tipo de cuenta eres?'),
                items: const [
                  DropdownMenuItem(value: 'usuario', child: Text('Cliente')),
                  DropdownMenuItem(value: 'emprendedor', child: Text('Emprendedor')),
                ],
                onChanged: (value) {
                  setState(() {
                    _rolSeleccionado = value!;
                  });
                },
              ),
              const SizedBox(height: 12),

              // Campo condicional: Solo si es emprendedor
              if (_rolSeleccionado == 'emprendedor')
                TextField(
                  controller: _negocioController,
                  decoration: const InputDecoration(labelText: 'Nombre de tu negocio'),
                ),
              const SizedBox(height: 12),
            ],

            // BOTÓN PRINCIPAL
            authState.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: () {
                final email = _emailController.text.trim();
                final password = _passwordController.text.trim();

                if (_esLogin) {
                  // Llamamos al ViewModel
                  ref.read(authViewModelProvider.notifier).login(
                    email: email,
                    password: password,
                  );
                } else {
                  // Llamamos al ViewModel
                  ref.read(authViewModelProvider.notifier).registrar(
                    email: email,
                    password: password,
                    nombre: _nombreController.text.trim(),
                    apellido: _apellidoController.text.trim(),
                    rol: _rolSeleccionado,
                    nombreNegocio: _rolSeleccionado == 'emprendedor' ? _negocioController.text.trim() : null,
                  );
                }
              },
              child: Text(_esLogin ? 'Entrar' : 'Registrarse'),
            ),

            TextButton(
              onPressed: () {
                setState(() {
                  _esLogin = !_esLogin;
                });
              },
              child: Text(_esLogin
                  ? '¿No tienes cuenta? Regístrate'
                  : '¿Ya tienes cuenta? Inicia sesión'),
            ),
          ],
        ),
      ),
    );
  }
}