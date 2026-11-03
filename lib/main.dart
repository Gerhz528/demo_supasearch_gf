// lib/main.dart
import 'package:demo_supasearch_gf/viewModel/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'core/SupaBaseConfig.dart';
import 'views/screens/auth_screen.dart';
import 'views/screens/map_screen.dart'; // <-- Importamos el mapa
import 'viewModel/auth_viewmodel.dart'; // <-- Para escuchar la sesión

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Recuerda que debes ejecutar con --dart-define=ACCESS_TOKEN=pk...
  // o si lo hardcodeaste, déjalo aquí.
  MapboxOptions.setAccessToken(
    const String.fromEnvironment('ACCESS_TOKEN'),
  );

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
      home: const AuthGate(), // <--- Volvemos a usar el portero
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
          return const MapScreen(); // Si hay sesión, va al mapa
        } else {
          return const AuthScreen(); // Si no, va al login
        }
      },
    );
  }
}