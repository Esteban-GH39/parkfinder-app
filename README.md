# parkfinder-app
ParkFinder mobile app developed with Flutter for searching, booking, and managing parking spaces.

# ParkFinder APP (Frontend)
Backend: https://github.com/Esteban-GH39/parkfinder-api
Documentación completa del proyecto (wiki): [https://github.com/Esteban-GH39/parkfinder-api/wiki](https://github.com/Esteban-GH39/parkfinder-api/wiki)

## Stack

- **Framework:** Flutter (Dart)
- **HTTP:** paquete `http`, hablando con la API REST de `parkfinder-api` (Quarkus)

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado (`flutter doctor` sin errores bloqueantes)

## Primeros pasos

Este repo ya trae `pubspec.yaml` y el código Dart en `lib/`, pero **todavía no tiene las
carpetas de plataforma** (`android/`, `ios/`, etc.) porque se generaron sin tener el SDK de
Flutter instalado en la máquina donde se creó la base. La primera vez que alguien del equipo
clone el repo con Flutter instalado, debe correr:

```shell script
flutter create --platforms=android,ios .
flutter pub get
```

Esto agrega las carpetas de plataforma sin tocar `lib/` ni `pubspec.yaml` (ya existentes).
Después, para correr la app en un emulador/dispositivo conectado:

```shell script
flutter run
```

## Estructura de carpetas

`lib/` está organizado por módulo (feature), en espejo con los módulos del backend:

- `features/users` — registro/login/perfil de **cliente** y **administrador**.
- `features/admin` — administración de parqueaderos (rol administrador).
- `features/reservations` — búsqueda y reserva de puestos (rol cliente).
- `features/payments` — cobro de reservas.
- `features/notifications` — avisos/confirmaciones.
- `common/` — tema visual, cliente HTTP compartido y utilidades.

Cada carpeta de `features/` tiene un `README.md` con su alcance; ahora mismo están vacías de
código real, se van llenando a medida que se implementen las historias de usuario.

## Estado

Proyecto en fase de scaffolding inicial (aún sin pantallas reales, solo un placeholder de bienvenida en `lib/app.dart`).
