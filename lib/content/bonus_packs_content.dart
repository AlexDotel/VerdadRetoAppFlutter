import '../game_models.dart';

class BonusPack {
  const BonusPack({
    required this.id,
    required this.emoji,
    required this.titleEs,
    required this.titleEn,
    required this.subtitleEs,
    required this.subtitleEn,
    required this.costSparks,
    required this.truthsEs,
    required this.daresEs,
    required this.truthsEn,
    required this.daresEn,
  });

  final String id;
  final String emoji;
  final String titleEs;
  final String titleEn;
  final String subtitleEs;
  final String subtitleEn;
  final int costSparks;
  final List<String> truthsEs;
  final List<String> daresEs;
  final List<String> truthsEn;
  final List<String> daresEn;

  String title({required bool english}) => english ? titleEn : titleEs;
  String subtitle({required bool english}) => english ? subtitleEn : subtitleEs;

  List<GameCard> cards({required bool english}) => [
    ...(english ? truthsEn : truthsEs).map(
      (text) => GameCard(CardType.verdad, text),
    ),
    ...(english ? daresEn : daresEs).map(
      (text) => GameCard(CardType.reto, text),
    ),
  ];
}

const bonusPacks = <BonusPack>[
  BonusPack(
    id: 'midnight_confessions',
    emoji: '🌙',
    titleEs: 'Confesiones de Madrugada',
    titleEn: 'Midnight Confessions',
    subtitleEs: 'Preguntas profundas y sin filtros para largas noches',
    subtitleEn: 'Deep, unfiltered prompts for late-night talks',
    costSparks: 80,
    truthsEs: [
      '¿Qué decisión de hace dos años cambió por completo dónde estás hoy?',
      '¿Cuál es la verdad sobre ti que te costó más tiempo aceptar?',
      '¿A qué persona de tu vida le debes una conversación sincera todavía?',
      '¿Qué miedo silencioso te frena más de lo que dejas ver?',
      '¿Cuál ha sido el momento en el que te sentiste más orgulloso de ti mismo?',
      '¿Qué consejo le darías hoy a tu yo de hace cinco años en una sola frase?',
      '¿Qué parte de tu personalidad solo muestras cuando confías al 100% en alguien?',
      '¿Cuál es el sueño que dejaste aparcado y todavía te pica por dentro?',
      '¿Qué error del pasado hoy agradeces haber cometido?',
      '¿Cuál es la lección más dura que te enseñó alguien a quien querías mucho?',
      '¿En qué momento reciente fingiste estar bien cuando en realidad no lo estabas?',
      '¿Qué valor tuyo no negociarías nunca por dinero ni por nadie?',
    ],
    daresEs: [
      'Di en voz alta algo que admiras de verdad de la persona que tienes a tu izquierda.',
      'Mantén 20 segundos de silencio total mirando a los ojos a quien elijas sin reírte.',
      'Cuenta en 20 segundos un giro inesperado que te cambió la vida.',
      'Haz un brindis sincero por algo que quieras lograr antes de que acabe el año.',
      'Confiesa una pequeña manía nocturna que casi nadie conoce de ti.',
      'Di tres cosas por las que hoy te sientes afortunado en menos de 15 segundos.',
      'Elige a alguien del grupo y pregúntale algo profundo que nunca le hayas preguntado.',
      'Resume tu año hasta ahora con un título de película y explica por qué.',
      'Di en voz alta una promesa realista que quieras cumplir esta semana.',
      'Da un abrazo largo y sincero de 10 segundos a la persona que elijas (si acepta).',
      'Comparte la canción que te salva siempre que tienes un día difícil.',
      'Dedica 15 segundos a agradecer al grupo un momento concreto que hayáis vivido.',
    ],
    truthsEn: [
      'What decision from two years ago completely changed where you are today?',
      'What truth about yourself took you the longest to accept?',
      'Who in your life do you still owe an honest conversation to?',
      'What quiet fear holds you back more than you let anyone see?',
      'When did you feel the proudest of yourself in the last year?',
      'What one-sentence advice would you send to yourself five years ago?',
      'What side of your personality only comes out when you trust someone 100%?',
      'What dream did you put on hold that still tugs at you?',
      'What past mistake are you secretly grateful you made?',
      'What was the hardest lesson taught to you by someone you cared about?',
      'When did you recently pretend to be fine when you really were not?',
      'What personal value would you never trade for money or status?',
    ],
    daresEn: [
      'Tell the person on your left one thing you genuinely admire about them.',
      'Hold 20 seconds of silent eye contact with someone you choose without laughing.',
      'Share an unexpected plot twist from your life in 20 seconds.',
      'Make a sincere toast to one goal you want to hit before the year ends.',
      'Confess a harmless late-night habit almost nobody knows about you.',
      'Name three things you feel genuinely lucky for today in under 15 seconds.',
      'Ask someone in the group one meaningful question you have never asked before.',
      'Give your year so far a movie title and explain why in two sentences.',
      'Say out loud one realistic promise you intend to keep this week.',
      'Give a genuine 10-second hug to someone of your choice (if they are up for it).',
      'Share the song that always rescues your mood after a rough day.',
      'Take 15 seconds to thank the group for one specific memory you love.',
    ],
  ),
  BonusPack(
    id: 'group_chaos',
    emoji: '🌪️',
    titleEs: 'Caos en Grupo',
    titleEn: 'Group Chaos',
    subtitleEs: 'Risas rápidas, votaciones y retos colectivos',
    subtitleEn: 'Fast laughs, group votes, and chaotic challenges',
    costSparks: 120,
    truthsEs: [
      '¿Quién de esta sala sobreviviría peor si se apagara internet durante una semana?',
      '¿A quién de aquí le confiarías tu coche nuevo y a quién jamás?',
      '¿Quién de este grupo sería el primero en hacer amistad con unos extraterrestres?',
      '¿Cuál es la historia más caótica que hemos vivido juntos y todavía da risa?',
      '¿Quién de los presentes tardaría menos en meterse en un lío absurdo en otro país?',
      '¿Qué regla inventada impondrías al grupo durante los próximos diez minutos?',
      '¿Quién de esta sala tiene la mejor cara de póker cuando está mintiendo?',
      '¿A qué dos personas de aquí encerrarías juntas en un escape room para ver qué pasa?',
      '¿Quién de este grupo acabaría siendo el líder en un apocalipsis y quién el chef?',
      '¿Qué apodo colectivo le pondrías a esta pandilla?',
      '¿Quién de aquí se reiría primero en un juicio súper serio?',
      '¿Cuál es el plan más improvisado que aceptarías hacer ahora mismo con este grupo?',
    ],
    daresEs: [
      'Todo el grupo tiene 15 segundos para ponerse de acuerdo en una pose grupal dirigida por ti.',
      'Señala en menos de 10 segundos al más cabezota, al más puntual y al más dramático de la sala.',
      'Haz una ronda relámpago de 20 segundos imitando a dos personas del grupo sin decir nombres.',
      'Inventa una regla graciosa que todos deben cumplir durante 2 rondas (ej. hablar sin señalar).',
      'Consigue que todo el grupo aplauda un ritmo inventado por ti en menos de 15 segundos.',
      'Haz una entrevista exprés de 20 segundos a la persona que tengas más lejos.',
      'Defiende durante 20 segundos por qué tú deberías ser el presidente oficial de este grupo.',
      'Haz 15 segundos de baile libre mientras el grupo puntúa del 1 al 10 con los dedos.',
      'Organiza un piedra-papel-tijera rápido contra la persona de tu derecha; quien pierda hace 5 sentadillas.',
      'Nombra a tres jugadores y crea el título de la serie de comedia que protagonizarían.',
      'Habla como comentarista deportivo narrando los próximos 20 segundos de la sala.',
      'Haz un brindis caótico inventando un motivo totalmente absurdo para celebrar hoy.',
    ],
    truthsEn: [
      'Who in this room would handle a week without Wi-Fi the worst?',
      'Who here would you trust with a brand-new car, and who never?',
      'Who in this group would be the first to befriend aliens?',
      'What is the most chaotic group story we still laugh about?',
      'Who here would get into a ridiculous misunderstanding abroad the fastest?',
      'What silly house rule would you enforce on the group for the next ten minutes?',
      'Who in this room has the best poker face when bluffing?',
      'Which two people here would be hilarious locked together in an escape room?',
      'Who would lead the group in an apocalypse, and who would be stuck cooking?',
      'What should our official friend-group band name be?',
      'Who here would crack up first during a dead-serious courtroom trial?',
      'What spontaneous adventure would you say yes to with this group right now?',
    ],
    daresEn: [
      'You have 15 seconds to direct the whole room into an epic group photo pose.',
      'In under 10 seconds, point to the most stubborn, most punctual, and most dramatic player.',
      'Spend 20 seconds imitating two people in the room without naming them.',
      'Invent a harmless rule everyone must follow for 2 rounds (like no pointing).',
      'Get the entire group clapping a custom rhythm you lead within 15 seconds.',
      'Do a 20-second red-carpet interview with the player sitting farthest from you.',
      'Give a 20-second campaign speech on why you should be president of this group.',
      'Do a 15-second freestyle dance while everyone scores you 1 to 10 on their fingers.',
      'Challenge the person on your right to rock-paper-scissors; the loser does 5 squats.',
      'Pick three players and pitch the sitcom they would star in together.',
      'Commentate live like a sports announcer on whatever happens in the room for 20 seconds.',
      'Give a dramatic toast celebrating a completely ridiculous made-up holiday.',
    ],
  ),
  BonusPack(
    id: 'express_dares',
    emoji: '⏱️',
    titleEs: 'Retos Express',
    titleEn: 'Express Dares',
    subtitleEs: 'Desafíos contrarreloj de 10 a 20 segundos',
    subtitleEn: 'Fast-paced 10 to 20-second timed challenges',
    costSparks: 150,
    truthsEs: [
      'Tienes 10 segundos: di tres cosas que te sacan de quicio al instante.',
      'Tienes 10 segundos: nombra tus tres películas favoritas sin dudar.',
      'Tienes 10 segundos: di tres virtudes tuyas sin falsa modestia.',
      'Tienes 10 segundos: nombra tres destinos a los que viajarías mañana mismo.',
      'Tienes 10 segundos: confiesa tus tres comidas culpables favoritas.',
      'Tienes 10 segundos: di tres cosas que siempre llevas encima al salir.',
      'Tienes 10 segundos: nombra tres canciones que te ponen de buen humor.',
      'Tienes 10 segundos: di tres cosas que jamás volverías a hacer.',
      'Tienes 10 segundos: nombra tres famosos con los que cenarías hoy.',
      'Tienes 10 segundos: di tres manías tuyas que todo el mundo nota.',
      'Tienes 10 segundos: elige tus tres series imprescindibles.',
      'Tienes 10 segundos: di tres objetivos que quieras cumplir este año.',
    ],
    daresEs: [
      'Di cinco animales que empiecen por "P" en menos de 10 segundos.',
      'Mantén el equilibrio en un pie durante 15 segundos sin mover los brazos.',
      'Cuenta del 30 al 0 de tres en tres en menos de 15 segundos.',
      'Haz tu mejor imitación de tres emociones distintas en 10 segundos.',
      'Di seis objetos de esta habitación al revés (del último al primero) en 15 segundos.',
      'Aguanta sin parpadear ni reírte durante 15 segundos mirando a la persona de enfrente.',
      'Nombra cinco países europeos en menos de 10 segundos dando palmas.',
      'Haz 10 sentadillas limpias en menos de 15 segundos.',
      'Di el abecedario desde la A hasta la M al revés en 15 segundos.',
      'Tararea dos canciones seguidas en 15 segundos y logra que adivinen al menos una.',
      'Haz cinco poses de revista distintas en 10 segundos sin repetir.',
      'Inventa una excusa genial para llegar tarde en menos de 10 segundos.',
    ],
    truthsEn: [
      'You have 10 seconds: name three things that instantly annoy you.',
      'You have 10 seconds: list your top three favorite movies without hesitating.',
      'You have 10 seconds: say three things you genuinely like about yourself.',
      'You have 10 seconds: name three places you would fly to tomorrow.',
      'You have 10 seconds: confess your top three guilty-pleasure snacks.',
      'You have 10 seconds: list three things you never leave home without.',
      'You have 10 seconds: name three songs that always boost your mood.',
      'You have 10 seconds: name three things you would never do again.',
      'You have 10 seconds: name three celebrities you would invite to dinner tonight.',
      'You have 10 seconds: admit three quirks everyone notices about you.',
      'You have 10 seconds: pick your three must-watch TV shows.',
      'You have 10 seconds: share three goals you want to hit this year.',
    ],
    daresEn: [
      'Name five animals starting with "P" in under 10 seconds.',
      'Balance on one foot for 15 seconds without moving your arms.',
      'Count down from 30 to 0 by threes in under 15 seconds.',
      'Flash three totally different emotions on command in 10 seconds.',
      'Point to and name six objects in the room in 10 seconds flat.',
      'Hold a staring contest without blinking or laughing for 15 seconds.',
      'Name five European countries in under 10 seconds while clapping.',
      'Do 10 clean squats in under 15 seconds.',
      'Say the alphabet backwards from M to A in 15 seconds.',
      'Hum two songs back-to-back in 15 seconds and get at least one guessed.',
      'Strike five completely different magazine poses in 10 seconds.',
      'Invent a brilliant excuse for being late in under 10 seconds.',
    ],
  ),
];

BonusPack? bonusPackById(String id) {
  for (final pack in bonusPacks) {
    if (pack.id == id) return pack;
  }
  return null;
}
