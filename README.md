# Qúbico Transportes - App Móvil

Qúbico Transportes es una aplicación móvil desarrollada en Flutter diseñada para gestionar la logística, el agendamiento de entregas, y el enrutamiento de la flota de vehículos de la empresa.

## Características Principales

### Panel de Administración
- **Gestión de Flota:** Registro y edición de vehículos, conductores, patentes y control de capacidades de carga máxima (Kg).
- **Asignación Dinámica:** Creación de pedidos asociándolos a un vehículo específico, validando en tiempo real que el peso de la carga no exceda la capacidad del vehículo.
- **Geocodificación Inteligente:** Integración con la API de Nominatim (OpenStreetMap) con autocompletado y _debounce_ para prevenir saturación de red.
- **Gestión de Pedidos:** Los administradores pueden anular pedidos, editarlos o eliminarlos de la base de datos (según reglas de negocio) y revisar la evidencia de entregas o incidencias en tiempo real.
- **Dashboard Estadístico:** Indicadores de puntualidad (En tiempo vs Atrasado) y estados generales.

### Hoja de Ruta del Conductor
- **Enrutamiento Diario:** Visualización exclusiva de los despachos programados para la fecha actual (Filtro por día).
- **Integración de Mapas:** Soporte nativo para abrir rutas en Google Maps o visualizarlas en el mapa interno (OpenStreetMap con control de zoom para prevención de crashes).
- **Control de Recepción:** Captura obligatoria de firmas digitales y evidencia fotográfica mediante la cámara al marcar entregas o incidencias.
- **Operación Offline:** Almacenamiento local mediante SQLite, diseñado para operar en zonas de baja conectividad.

## Tecnologías Utilizadas
- **Framework:** Flutter / Dart
- **Gestión de Estado:** Provider
- **Almacenamiento Local:** SQFlite (Base de datos versión 3 con tablas relacionales de Flota y Pedidos)
- **Mapas y Geocodificación:** Flutter Map, Nominatim, OSRM.
- **Hardware Integrado:** Image Picker (Cámara), Signature (Firmas digitales táctiles), URL Launcher.

## Instrucciones de Ejecución

1. Clona el repositorio:
   ```bash
   git clone https://github.com/luisbustamanteuautonoma/qubico-transportes.git
   ```
2. Instala las dependencias:
   ```bash
   flutter pub get
   ```
3. (Opcional) Si hubo cambios en la base de datos, ejecuta un clean:
   ```bash
   flutter clean
   ```
4. Ejecuta la aplicación:
   ```bash
   flutter run
   ```

## Notas de Desarrollo
- La aplicación incluye validaciones estrictas de RUT chileno.
- El esquema de base de datos se maneja mediante migraciones (`onUpgrade`) para evitar pérdida de datos en despliegues.
