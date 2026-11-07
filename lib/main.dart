// lib/main.dart
import 'package:demo_supasearch_gf/viewModel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/SupaBaseConfig.dart';
import 'views/screens/auth_screen.dart';
import 'views/screens/map_screen.dart'; // <-- Importamos el mapa
//import 'viewModel/auth_viewmodel.dart'; // <-- Para escuchar la sesión
import 'views/screens/main_screen.dart'; // <-- Importamos el mapa'

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // 2. Inicializar Mapbox
  // Recuerda ejecutar con --dart-define=ACCESS_TOKEN=pk...
  MapboxOptions.setAccessToken('pk.eyJ1IjoiZHJpdmVydmFuIiwiYSI6ImNtdnkzMXQ1NzAybWgyenExMzJwdGt5b24ifQ.NuSOApFFI5z3hPYkoj4GpA');

  // 3. Arrancar la app
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Emprendedores',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AuthGate(), // El portero decide qué mostrar
    );
  }
}

// EL PORTERO
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (state) {
        if (state.session != null) {
          // Si hay sesión, va a la pantalla con el mapa y los 3 botones
          return const MainScreen();
        } else {
          // Si no hay sesión, va al login
          return const AuthScreen();
        }
      },
    );
  }
}