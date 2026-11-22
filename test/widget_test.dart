import 'dart:ui' show Locale, Offset, Size;

import 'package:flutter/material.dart' show AlertDialog, Icons, TextField;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verdad_o_reto/game_controller.dart';
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

  test('todas las barajas en español e inglés tienen 100 tarjetas únicas y limpias', () {
    for (final english in [false, true]) {
      for (final mode in GameMode.values) {
        final intensities = mode == GameMode.familia
            ? const [Intensity.suave]
            : Intensity.values;
        for (final intensity in intensities) {
          for (final type in CardType.values) {
            final cards = contentFor(
              mode,
              intensity,
              type,
              english: english,
            );
            expect(
              cards,
              hasLength(cardsPerType),
              reason: 'Falta contenido en $mode/$intensity/$type (en=$english)',
            );
            expect(
              cards.toSet(),
              hasLength(cardsPerType),
              reason: 'Hay duplicados en $mode/$intensity/$type (en=$english)',
            );
            for (final text in cards) {
              expect(text.trim(), isNotEmpty);
              expect(text.contains('{topic}'), isFalse);
              expect(text.contains('penetro/a'), isFalse);
              expect(text.contains('lamedido'), isFalse);
              expect(RegExp(r'\bde el\b').hasMatch(text), isFalse);
              if (english) {
                expect(text.contains('¿'), isFalse);
                expect(text.contains('¡'), isFalse);
              }
            }
          }
        }
      }
    }
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

  test('GameController evita duplicados al truncar nombres a 18 caracteres', () async {
    SharedPreferences.setMockInitialValues({'consent': true});
    final controller = GameController();
    await Future<void>.delayed(Duration.zero);

    expect(controller.addPlayer('NombreMuyLargo1234A'), isTrue);
    expect(controller.addPlayer('NombreMuyLargo1234B'), isFalse);
    expect(controller.players.toSet().length, controller.players.length);
  });

  test('skipPlayer no cuenta tarjetas incompletas y pausa se reinicia al empezar', () async {
    SharedPreferences.setMockInitialValues({'consent': true});
    final controller = GameController();
    await Future<void>.delayed(Duration.zero);

    controller.startGame();
    controller.chooseCard(CardType.verdad);
    await controller.skipPlayer();
    expect(controller.truthsCompleted, 0);
    expect(controller.daresCompleted, 0);

    controller.togglePause();
    expect(controller.paused, isTrue);
    controller.startGame();
    expect(controller.paused, isFalse);
  });

  test('los filtros de contenido usan límites de palabra y no falsos positivos', () async {
    SharedPreferences.setMockInitialValues({'consent': true});
    final controller = GameController();
    await Future<void>.delayed(Duration.zero);

    controller.setContentFilter('public', false);
    controller.setContentFilter('personal', false);
    controller.setContentFilter('alcohol', false);

    // Words containing "bar", "car", "lie", "shot" as substrings must NOT be blocked
    expect(
      controller.allowsCardText('¿Qué comida te gustaría probar hoy?'),
      isTrue,
    );
    expect(
      controller.allowsCardText('What is your most embarrassing memory?'),
      isTrue,
    );
    expect(
      controller.allowsCardText('Pick a favorite character and act it out.'),
      isTrue,
    );
    expect(
      controller.allowsCardText('What childhood myth did you believe?'),
      isTrue,
    );
    // Actual matching words MUST be blocked
    expect(
      controller.allowsCardText('¿Has ligado alguna vez en un bar?'),
      isFalse,
    );
    expect(
      controller.allowsCardText('¿Alguna vez tomaste un chupito?'),
      isFalse,
    );
  });

  test('el mazo se repone si se agotan todas las tarjetas de un tipo', () async {
    SharedPreferences.setMockInitialValues({'consent': true});
    final controller = GameController();
    await Future<void>.delayed(Duration.zero);

    controller.startGame();
    for (var i = 0; i < 105; i++) {
      controller.chooseCard(CardType.verdad);
      expect(controller.currentCard, isNotNull);
      expect(controller.currentCard!.type, CardType.verdad);
    }
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

  testWidgets('traduce correctamente el resumen final en inglés', (tester) async {
    SharedPreferences.setMockInitialValues({
      'consent': true,
      'language': 'en',
      'maxRounds': 1,
      'notification_permission_prompted': true,
    });
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const TruthOrDareApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('START PLAYING'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Family'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('LET THE GAME BEGIN!'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('TRUTH'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VIEW SUMMARY'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PLAY AGAIN'), findsOneWidget);
    expect(find.text('BACK TO HOME'), findsOneWidget);
  });

  testWidgets('pluraliza bien el aviso cuando faltan 2 jugadores activos', (
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

    await tester.tap(find.byTooltip('Eliminar Alex'));
    await tester.pumpAndSettle();
    expect(find.text('Necesitas 1 jugador activo más'), findsOneWidget);

    await tester.tap(find.byTooltip('Eliminar Sam'));
    await tester.pumpAndSettle();
    expect(find.text('Necesitas 2 jugadores activos más'), findsOneWidget);
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
