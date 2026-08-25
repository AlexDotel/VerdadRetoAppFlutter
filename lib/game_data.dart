import 'game_models.dart';
import 'imported_adult_content.dart';

const cardsPerType = 100;

List<GameCard> buildDeck(
  GameMode mode,
  Intensity intensity, {
  bool english = false,
}) => [
  ...contentFor(
    mode,
    intensity,
    CardType.verdad,
    english: english,
  ).map((text) => GameCard(CardType.verdad, text)),
  ...contentFor(
    mode,
    intensity,
    CardType.reto,
    english: english,
  ).map((text) => GameCard(CardType.reto, text)),
]..shuffle();

List<String> contentFor(
  GameMode mode,
  Intensity intensity,
  CardType type, {
  bool english = false,
}) {
  if (english) return _englishContentFor(mode, intensity, type);
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

List<String> _englishContentFor(
  GameMode mode,
  Intensity intensity,
  CardType type,
) {
  if (mode == GameMode.familia) {
    return type == CardType.verdad
        ? _familyTruthsEnglish()
        : _familyDaresEnglish();
  }
  return type == CardType.verdad
      ? _generatedTruthsEnglish(mode, intensity)
      : _generatedDaresEnglish(mode, intensity);
}

String _settingEnglish(GameMode mode) => switch (mode) {
  GameMode.amigos => 'with friends',
  GameMode.pareja => 'as a couple',
  GameMode.fiesta => 'at a party',
  GameMode.familia => 'with family',
};

String _toneEnglish(Intensity intensity) => switch (intensity) {
  Intensity.suave => 'in a fun way without making anyone uncomfortable',
  Intensity.atrevido => 'honestly and with a bold twist',
  Intensity.extremo => 'with complete honesty while respecting every boundary',
};

List<String> _generatedTruthsEnglish(GameMode mode, Intensity intensity) {
  final setting = _settingEnglish(mode);
  final tone = _toneEnglish(intensity);
  const openings = [
    'What has been',
    'What do you remember as',
    'How would you describe',
    'Who would you tell about',
    'What would you change about',
    'What did you learn from',
    'What would you like to repeat about',
    'What have you never shared about',
    'What surprised you most about',
    'What is your honest opinion about',
  ];
  const topics = [
    'your most embarrassing moment',
    'a first impression you got wrong',
    'your perfect plan',
    'an impulsive decision',
    'the compliment you remember most',
    'a harmless white lie',
    'your biggest quirk',
    'a conversation you still need to have',
    'the most fun risk you have taken',
    'something that makes you feel vulnerable',
  ];
  return [
    for (final opening in openings)
      for (final topic in topics) '$opening $topic $setting, $tone?',
  ];
}

List<String> _generatedDaresEnglish(GameMode mode, Intensity intensity) {
  final setting = _settingEnglish(mode);
  final seconds = switch (intensity) {
    Intensity.suave => 15,
    Intensity.atrevido => 25,
    Intensity.extremo => 40,
  };
  const actions = [
    'Improvise a story',
    'Do an impression',
    'Act out a scene',
    'Make up a dance',
    'Give someone a compliment',
    'Sing a made-up chorus',
    'Defend a ridiculous opinion',
    'Tell a story using gestures',
    'Make a dramatic declaration',
    'Play a character chosen by the group',
  ];
  const twists = [
    'without using the letter A',
    'with a TV host voice',
    'without laughing',
    'including three words chosen by the others',
    'as if it were the end of a movie',
    'while maintaining eye contact with someone',
    'using questions only',
    'using a nearby object as a prop',
    'in slow motion',
    'letting the group choose the subject',
  ];
  return [
    for (final action in actions)
      for (final twist in twists)
        '$action $setting for $seconds seconds, $twist.',
  ];
}

List<String> _familyTruthsEnglish() {
  const topics = [
    'a holiday',
    'a birthday',
    'a special meal',
    'a day at school',
    'an afternoon of games',
    'a celebration',
    'an unexpected visit',
    'a family tradition',
    'a day trip',
    'a moment at home',
  ];
  const questions = [
    'What is your funniest memory connected to {topic}?',
    'What did you enjoy most about {topic}?',
    'Who made you laugh most during {topic}, and why?',
    'What would you repeat exactly the same from {topic}?',
    'What small detail do you remember best from {topic}?',
    'What did you learn thanks to {topic}?',
    'How would you improve {topic} if it happened tomorrow?',
    'Who would you invite to share {topic}?',
    'Which song would you choose to remember {topic}?',
    'What movie title would you give to {topic}?',
  ];
  return [
    for (final question in questions)
      for (final topic in topics) question.replaceFirst('{topic}', topic),
  ];
}

List<String> _familyDaresEnglish() {
  const actions = [
    'Imitate an animal',
    'Make up a dance',
    'Tell a three-sentence story',
    'Hum a well-known song',
    'Act out a profession',
    'Draw something in the air with your finger',
    'Strike a superhero pose',
    'Act out an emotion without speaking',
    'Say a made-up tongue twister',
    'Create a funny advert for a nearby object',
  ];
  const twists = [
    'while the group tries to guess it',
    'using a robot voice',
    'as if you were moving in slow motion',
    'without using the letter A',
    'including another player’s name',
    'with your hands behind your back',
    'as if you were a TV host',
    'without laughing for 20 seconds',
    'letting the group choose the subject',
    'and finish with a bow',
  ];
  return [
    for (final action in actions)
      for (final twist in twists) '$action $twist.',
  ];
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
