import 'game_models.dart';
import 'imported_adult_content.dart';

const cardsPerType = 100;

List<GameCard> buildDeck(GameMode mode, Intensity intensity) => [
  ...contentFor(
    mode,
    intensity,
    CardType.verdad,
  ).map((text) => GameCard(CardType.verdad, text)),
  ...contentFor(
    mode,
    intensity,
    CardType.reto,
  ).map((text) => GameCard(CardType.reto, text)),
]..shuffle();

List<String> contentFor(GameMode mode, Intensity intensity, CardType type) {
  if (mode == GameMode.familia) {
    return type == CardType.verdad ? _familyTruths() : _familyDares();
  }
  final imported =
      importedAdultContent[_categoryKey(
        mode,
        intensity,
      )]?[type == CardType.verdad ? 'verdad' : 'reto'] ??
      const <String>[];
  final generated = type == CardType.verdad
      ? _generatedTruths(mode, intensity)
      : _generatedDares(mode, intensity);
  return <String>{...imported, ...generated}.take(cardsPerType).toList();
}

String _categoryKey(GameMode mode, Intensity intensity) =>
    '${mode.name}_${intensity.name}';

String _setting(GameMode mode) => switch (mode) {
  GameMode.amigos => 'entre amigos',
  GameMode.pareja => 'en pareja',
  GameMode.fiesta => 'en una fiesta',
  GameMode.familia => 'en familia',
};

String _tone(Intensity intensity) => switch (intensity) {
  Intensity.suave => 'de forma divertida y sin incomodar a nadie',
  Intensity.atrevido => 'con sinceridad y un punto atrevido',
  Intensity.extremo => 'con total honestidad, respetando todos los límites',
};

List<String> _generatedTruths(GameMode mode, Intensity intensity) {
  final setting = _setting(mode);
  final tone = _tone(intensity);
  const openings = [
    '¿Cuál ha sido',
    '¿Qué recuerdas como',
    '¿Cómo describirías',
    '¿A quién contarías',
    '¿Qué cambiarías de',
    '¿Qué aprendiste de',
    '¿Qué te gustaría repetir de',
    '¿Qué nunca has contado sobre',
    '¿Qué te sorprendió más de',
    '¿Qué opinión sincera tienes sobre',
  ];
  const topics = [
    'tu momento más vergonzoso',
    'una primera impresión equivocada',
    'tu plan perfecto',
    'una decisión impulsiva',
    'el cumplido que más recuerdas',
    'una pequeña mentira piadosa',
    'tu mayor manía',
    'una conversación pendiente',
    'el riesgo más divertido que tomaste',
    'algo que te hace sentir vulnerable',
  ];
  return [
    for (final opening in openings)
      for (final topic in topics) '$opening $topic $setting, $tone?',
  ];
}

List<String> _generatedDares(GameMode mode, Intensity intensity) {
  final setting = _setting(mode);
  final seconds = switch (intensity) {
    Intensity.suave => 15,
    Intensity.atrevido => 25,
    Intensity.extremo => 40,
  };
  const actions = [
    'Improvisa una historia',
    'Haz una imitación',
    'Representa una escena',
    'Inventa un baile',
    'Dedica un cumplido',
    'Canta un estribillo inventado',
    'Defiende una opinión absurda',
    'Cuenta una anécdota usando gestos',
    'Haz una declaración dramática',
    'Interpreta un personaje elegido por el grupo',
  ];
  const twists = [
    'sin usar la letra A',
    'con voz de presentador de televisión',
    'sin poder reírte',
    'incluyendo tres palabras elegidas por los demás',
    'como si fuera el final de una película',
    'manteniendo contacto visual con alguien',
    'usando únicamente preguntas',
    'con un objeto cercano como accesorio',
    'a cámara lenta',
    'dejando que el grupo elija el tema',
  ];
  return [
    for (final action in actions)
      for (final twist in twists)
        '$action $setting durante $seconds segundos, $twist.',
  ];
}

List<String> _familyTruths() {
  const topics = [
    'unas vacaciones',
    'un cumpleaños',
    'una comida especial',
    'un día de colegio',
    'una tarde de juegos',
    'una celebración',
    'una visita inesperada',
    'una tradición familiar',
    'una excursión',
    'un momento en casa',
  ];
  const questions = [
    '¿Cuál es tu recuerdo más divertido relacionado con {topic}?',
    '¿Qué fue lo que más te gustó de {topic}?',
    '¿Quién te hizo reír más durante {topic} y por qué?',
    '¿Qué repetirías exactamente igual de {topic}?',
    '¿Qué pequeño detalle recuerdas mejor de {topic}?',
    '¿Qué aprendiste gracias a {topic}?',
    '¿Cómo mejorarías {topic} si ocurriera mañana?',
    '¿A qué persona invitarías a compartir {topic}?',
    '¿Qué canción elegirías para recordar {topic}?',
    '¿Qué título de película le pondrías a {topic}?',
  ];
  return [
    for (final question in questions)
      for (final topic in topics) question.replaceFirst('{topic}', topic),
  ];
}

List<String> _familyDares() {
  const actions = [
    'Imita a un animal',
    'Inventa un baile',
    'Cuenta una historia de tres frases',
    'Tararea una canción conocida',
    'Representa una profesión',
    'Dibuja algo en el aire con el dedo',
    'Haz una pose de superhéroe',
    'Interpreta una emoción sin hablar',
    'Di un trabalenguas inventado',
    'Crea un anuncio divertido sobre un objeto cercano',
  ];
  const twists = [
    'mientras el grupo intenta adivinarlo',
    'usando una voz de robot',
    'como si estuvieras a cámara lenta',
    'sin poder usar la letra A',
    'incluyendo el nombre de otro jugador',
    'con las manos detrás de la espalda',
    'como si fueras presentador de televisión',
    'sin reírte durante 20 segundos',
    'dejando que el grupo elija el tema',
    'y termina haciendo una reverencia',
  ];
  return [
    for (final action in actions)
      for (final twist in twists) '$action $twist.',
  ];
}
