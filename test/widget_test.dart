import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:verdad_o_reto/game_data.dart';
import 'package:verdad_o_reto/game_models.dart';
import 'package:verdad_o_reto/main.dart';

void main() {
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

  testWidgets('muestra la pantalla inicial de Verdad o Reto', (tester) async {
    SharedPreferences.setMockInitialValues({
      'consent': true,
      'notification_permission_prompted': true,
    });

    await tester.pumpWidget(const TruthOrDareApp());
    await tester.pump();

    expect(find.text('EMPEZAR A JUGAR'), findsOneWidget);
  });

  testWidgets('el flujo completo es legible en modo claro', (tester) async {
    SharedPreferences.setMockInitialValues({
      'consent': true,
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
    await tester.pumpAndSettle();

    expect(find.text('JUGAR OTRA VEZ'), findsOneWidget);
    expect(find.text('VOLVER AL INICIO'), findsOneWidget);
  });

  testWidgets('Familia omite la intensidad y comienza directamente', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'consent': true,
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
}
