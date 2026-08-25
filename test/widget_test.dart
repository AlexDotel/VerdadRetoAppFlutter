import 'dart:ui' show Locale, Offset, Size;

import 'package:flutter/material.dart' show AlertDialog, Icons, TextField;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verdad_o_reto/game_data.dart';
import 'package:verdad_o_reto/game_models.dart';
import 'package:verdad_o_reto/main.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .localeTestValue = const Locale(
      'es',
    );
  });

  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearLocaleTestValue();
  });

  test('el modo Familia contiene 100 verdades y 100 retos únicos', () {
    final truths = contentFor(
      GameMode.familia,
      Intensity.suave,
      CardType.verdad,
    );
    final dares = contentFor(GameMode.familia, Intensity.suave, CardType.reto);

    expect(truths, hasLength(cardsPerType));
    expect(dares, hasLength(cardsPerType));
    expect(truths.toSet(), hasLength(cardsPerType));
    expect(dares.toSet(), hasLength(cardsPerType));
  });

  test('la baraja inglesa contiene 100 textos únicos por tipo', () {
    final truths = contentFor(
      GameMode.amigos,
      Intensity.suave,
      CardType.verdad,
      english: true,
    );
    final dares = contentFor(
      GameMode.amigos,
      Intensity.suave,
      CardType.reto,
      english: true,
    );

    expect(truths, hasLength(cardsPerType));
    expect(dares, hasLength(cardsPerType));
    expect(truths.toSet(), hasLength(cardsPerType));
    expect(dares.toSet(), hasLength(cardsPerType));
    expect(truths.any((text) => text.contains('¿')), isFalse);
  });

  testWidgets('muestra la pantalla inicial de Verdad o Reto', (tester) async {
    SharedPreferences.setMockInitialValues({
      'consent': true,
      'language': 'es',
      'notification_permission_prompted': true,
    });

    await tester.pumpWidget(const TruthOrDareApp());
    await tester.pumpAndSettle();

    expect(find.text('EMPEZAR A JUGAR'), findsOneWidget);
  });

  testWidgets('muestra interfaz y ajustes en inglés', (tester) async {
    SharedPreferences.setMockInitialValues({
      'consent': true,
      'language': 'en',
      'notification_permission_prompted': true,
    });

    await tester.pumpWidget(const TruthOrDareApp());
    await tester.pumpAndSettle();

    expect(find.text('START PLAYING'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Rate the app'), 300);
    expect(find.text('Rate the app'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Play The Bomb'), 300);
    expect(find.text('Play The Bomb'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Play Impostor'), 300);
    expect(find.text('Play Impostor'), findsOneWidget);
  });

  testWidgets(
    'permite editar un jugador sin destruir el campo antes de tiempo',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'consent': true,
        'language': 'es',
        'notification_permission_prompted': true,
      });

      await tester.pumpWidget(const TruthOrDareApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text('EMPEZAR A JUGAR'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Editar jugador: Alex'));
      await tester.pumpAndSettle();
      final editor = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(editor, 'Andrea');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Andrea'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('permite reordenar jugadores sin errores en el overlay', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'consent': true,
      'language': 'es',
      'notification_permission_prompted': true,
    });

    await tester.pumpWidget(const TruthOrDareApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('EMPEZAR A JUGAR'));
    await tester.pumpAndSettle();

    final handles = find.byIcon(Icons.drag_handle_rounded);
    await tester.drag(handles.first, const Offset(0, 140));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('el flujo completo es legible en modo claro', (tester) async {
    SharedPreferences.setMockInitialValues({
      'consent': true,
      'language': 'es',
      'light_mode': true,
      'maxRounds': 1,
      'notification_permission_prompted': true,
    });
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TruthOrDareApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('EMPEZAR A JUGAR'));
    await tester.pumpAndSettle();
    expect(find.text('¿Quién juega?'), findsOneWidget);

    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(find.text('Modo de juego'), findsOneWidget);

    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    expect(find.text('¡QUE EMPIECE EL JUEGO!'), findsOneWidget);

    await tester.tap(find.text('¡QUE EMPIECE EL JUEGO!'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VERDAD'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VER RESUMEN'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('JUGAR OTRA VEZ'), findsOneWidget);
    expect(find.text('VOLVER AL INICIO'), findsOneWidget);
  });

  testWidgets('Familia omite la intensidad y comienza directamente', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'consent': true,
      'language': 'es',
      'notification_permission_prompted': true,
    });
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TruthOrDareApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('EMPEZAR A JUGAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Familia'));
    await tester.pumpAndSettle();
    expect(find.text('¡QUE EMPIECE EL JUEGO!'), findsOneWidget);

    await tester.tap(find.text('¡QUE EMPIECE EL JUEGO!'));
    await tester.pumpAndSettle();
    expect(find.text('Intensidad'), findsNothing);
    expect(find.text('VERDAD'), findsOneWidget);
    expect(find.text('RETO'), findsOneWidget);
  });

  testWidgets('confirma antes de abandonar una partida activa', (tester) async {
    SharedPreferences.setMockInitialValues({
      'consent': true,
      'language': 'es',
      'notification_permission_prompted': true,
    });
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TruthOrDareApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('EMPEZAR A JUGAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUAR'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Familia'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('¡QUE EMPIECE EL JUEGO!'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿Salir de la partida?'), findsOneWidget);

    await tester.tap(find.text('SEGUIR JUGANDO'));
    await tester.pumpAndSettle();
    expect(find.text('VERDAD'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('SALIR'));
    await tester.pumpAndSettle();
    expect(find.text('Modo de juego'), findsOneWidget);
  });
}
