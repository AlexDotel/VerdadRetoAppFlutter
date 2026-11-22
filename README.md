# Verdad o Reto

Aplicación Android desarrollada con Flutter para jugar a Verdad o Reto en grupo.

## Funciones principales

- Modos Amigos, Pareja, Fiesta y Familia.
- Modo Familia con 100 preguntas y 100 retos aptos para todas las edades.
- Intensidades Suave, Atrevido y Extremo en los modos compatibles.
- Turnos ordenados o aleatorios para grupos de 2 a 12 jugadores.
- Más de 1.800 preguntas y retos.
- Límites de contenido configurables.
- Notificaciones locales y funcionamiento sin conexión para el contenido del juego.
- Publicidad intersticial mediante Appodeal.

## Ejecutar el proyecto

```bash
flutter pub get
flutter run
```

## Comprobaciones

```bash
flutter analyze
flutter test
```

## Firma de Android

Las claves privadas no forman parte del repositorio. Para una compilación destinada a Google Play, copia `android/key.properties.example` como `android/key.properties` y configura localmente la clave de subida.

Para compilar una versión firmada, configura `storeFile` como `../../private-signing/verdad-o-reto-upload.jks` en tu `android/key.properties` local y ejecuta:

```powershell
flutter clean
flutter pub get
flutter build appbundle --release
```

El AAB se genera en `build/app/outputs/bundle/release/app-release.aab`. Nunca publiques `android/key.properties`, archivos `.jks` ni sus contraseñas.

## Identificador Android

`nuviapps.co.verdadoreto`
