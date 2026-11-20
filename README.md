
# App Emprendedores Ambulantes (Prototipo)

Aplicación móvil desarrollada en Flutter que conecta a **clientes** con **vendedores ambulantes** en tiempo real. Permite a los vendedores actualizar su ubicación GPS, mostrar un catálogo de productos con fotografías y comunicarse con los clientes mediante un chat en vivo.

## Características Principales

*   **Autenticación con Roles:** Registro e inicio de sesión diferenciado para Clientes y Vendedores (Emprendedores) utilizando Supabase Auth.
*   **Geolocalización en Tiempo Real (Mapbox):**
    *   Los clientes ven pines rojos con la ubicación exacta de los vendedores ambulantes.
    *   Los vendedores pueden actualizar su ubicación con un solo toque usando el GPS del dispositivo.
*   **Catálogo de Productos:** Los vendedores pueden tomar fotos a sus productos, asignarles un precio y descripción, y publicarlos. Las imágenes se almacenan en Supabase Storage.
*   **Interacción y Chat en Tiempo Real:** Los clientes pueden tocar el pin del vendedor para ver sus productos y abrir un chat directo. La mensajería utiliza WebSockets a través de Supabase Realtime para actualizaciones instantáneas.

##  Tecnologías y Arquitectura

*   **Frontend:** Flutter (Dart) + Material Design 3.
*   **Gestión de Estado e Inyección de Dependencias:** Riverpod.
*   **Backend as a Service (BaaS):** Supabase (PostgreSQL, Auth, Storage, Realtime).
*   **Mapas:** Mapbox Maps SDK.
*   **Patrón de Arquitectura:** **MVVM (Model-View-ViewModel)** con capa de Repository.
    *   La interfaz de usuario (View) reacciona al estado del ViewModel.
    *   El ViewModel no conoce a Supabase directamente; delega al Repository.
    *   El Repository abstrae el acceso a los datos y utiliza los Services (Supabase, Mapbox, GPS).

## Estructura del Proyecto

El código está modularizado siguiendo los principios de Clean Architecture y responsabilidad única (SRP):

```text
lib/
 └── core/           # Configuraciones globales (SupabaseConfig)
 └── models/         # Entidades de dominio (Usuario, Lugar, Producto, etc.)
 └── repositories/   # Abstracción de datos (LugaresRepository, ChatRepository)
 └── services/       # Conexiones directas a APIs externas (Supabase, Location)
 └── viewmodels/     # Estados de la UI y lógica de negocio (Riverpod Notifiers)
 └── views/          # Interfaz de usuario
      ├── screens/   # Pantallas principales (Auth, Main, Chat, CrearProducto)
      └── tabs/      # Componentes de las pestañas inferiores (Mapa, Productos, Chat, Ajustes)
 └── main.dart       # Punto de entrada de la aplicación
```

##  Requisitos Previos y Configuración

Para ejecutar este proyecto localmente, necesitas configurar las siguientes variables:

### 1. Supabase
1. Crea un proyecto en [Supabase](https://supabase.com/).
2. Ejecuta los scripts SQL para crear las tablas (`perfiles`, `emprendedores`, `lugares`, `productos`, `mensajes`), los Triggers y las Políticas de Seguridad (RLS). *(Revisar la carpeta `/docs` o el documento de entrega para el script SQL completo)*.
3. Crea un Bucket público en Storage llamado `Images`.
4. Crea el archivo `lib/core/supabase_config.dart` con tus credenciales:
   ```dart
   class SupabaseConfig {
     static const String url = 'TU_SUPABASE_URL';
     static const String anonKey = 'TU_SUPABASE_ANON_KEY';
   }
   ```

### 2. Mapbox
Necesitas un token público de [Mapbox](https://www.mapbox.com/). Este token se pasa a la aplicación en tiempo de compilación, no se escribe en el código.

## Instalación y Ejecución

1. Clona este repositorio e ingresa a la carpeta:
   ```bash
   git clone <tu-repositorio>
   cd nombre_del_proyecto
   ```

2. Descarga las dependencias de Flutter:
   ```bash
   flutter pub get
   ```

3. Ejecuta la aplicación pasando tu token público de Mapbox (necesario para que el mapa se renderice):
   ```bash
   flutter run --dart-define=ACCESS_TOKEN=pk.tu_token_publico_aqui
   ```

### Generar APK (Android)
Si deseas instalar la app directamente en un dispositivo físico, genera el APK en modo Release:

```bash
flutter build apk --release --dart-define=ACCESS_TOKEN=pk.tu_token_publico_aqui
```
El archivo se encontrará en `build/app/outputs/flutter-apk/app-release.apk`.

##  Licencia
Este proyecto es de uso académico y fue desarrollado como un prototipo evolutivo.
