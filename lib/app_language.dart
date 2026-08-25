import 'dart:ui';

import 'package:flutter/material.dart';

const supportedAppLocales = <Locale>[Locale('es'), Locale('en')];

Locale resolveAppLocale(Locale? deviceLocale) =>
    deviceLocale?.languageCode == 'es'
    ? const Locale('es')
    : const Locale('en');

String deviceLanguageCode() =>
    PlatformDispatcher.instance.locale.languageCode == 'es' ? 'es' : 'en';

extension AppTranslation on BuildContext {
  bool get isEnglish => Localizations.localeOf(this).languageCode == 'en';

  String tr(String spanish) =>
      isEnglish ? (_english[spanish] ?? spanish) : spanish;
}

const _english = <String, String>{
  'Verdad o Reto': 'Truth or Dare',
  'ACEPTAR Y CONTINUAR': 'ACCEPT AND CONTINUE',
  'Antes de jugar': 'Before you play',
  'La diversión siempre termina donde empieza un límite.':
      'Fun always ends where a boundary begins.',
  'Cualquiera puede decir que no': 'Anyone can say no',
  'Se puede cambiar cualquier tarjeta sin penalización.':
      'Any card can be changed without a penalty.',
  'Privado y sin conexión': 'Private and offline',
  'No grabamos respuestas ni enviamos datos personales.':
      'We do not record answers or send personal data.',
  'Todas las personas tienen 18 años o más': 'Everyone playing is 18 or older',
  'Entendemos que el consentimiento puede retirarse':
      'We understand that consent can be withdrawn',
  'Activar modo oscuro': 'Enable dark mode',
  'Activar modo claro': 'Enable light mode',
  'Configuración': 'Settings',
  'Las mejores historias empiezan\ncon una pregunta.':
      'The best stories begin\nwith a question.',
  'EMPEZAR A JUGAR': 'START PLAYING',
  '2–12 jugadores  ·  Sin conexión': '2–12 players  ·  Offline',
  '¿Quién juega?': 'Who is playing?',
  'Añade al menos 2 personas': 'Add at least 2 people',
  'Nombre del jugador': 'Player name',
  'JUGADORES': 'PLAYERS',
  'CONTINUAR': 'CONTINUE',
  'Editar jugador': 'Edit player',
  'Cancelar': 'Cancel',
  'Guardar': 'Save',
  '¡QUE EMPIECE EL JUEGO!': 'LET THE GAME BEGIN!',
  'Modo de juego': 'Game mode',
  'Elige el ambiente de la partida': 'Choose the mood of the game',
  'MODO DE JUEGO': 'GAME MODE',
  'Amigos': 'Friends',
  'Risas y buenas historias': 'Laughs and great stories',
  'Pareja': 'Couple',
  'Conexión y complicidad': 'Connection and chemistry',
  'Fiesta': 'Party',
  'Más energía, más caos': 'More energy, more chaos',
  'Familia': 'Family',
  'Para todas las edades': 'For all ages',
  'Intensidad': 'Intensity',
  'INTENSIDAD': 'INTENSITY',
  'Suave': 'Mild',
  'Para romper el hielo': 'To break the ice',
  'Atrevido': 'Bold',
  'Sube la temperatura': 'Turn up the heat',
  'Extremo': 'Extreme',
  'Sin miedo y con confianza': 'Fearless and confident',
  'Mezclar intensidades': 'Mix intensities',
  'Combina contenido suave, atrevido y extremo':
      'Combine mild, bold and extreme content',
  'Turnos aleatorios': 'Random turns',
  'El siguiente jugador se elegirá al azar':
      'The next player will be chosen at random',
  'Los jugadores participarán en orden': 'Players will take turns in order',
  'Límites de contenido': 'Content boundaries',
  'Desactiva lo que el grupo prefiera evitar':
      'Turn off anything the group would rather avoid',
  'Contacto físico': 'Physical contact',
  'Contenido sexual 18+': 'Sexual content 18+',
  'Alcohol': 'Alcohol',
  'Mensajes y redes sociales': 'Messages and social media',
  'Preguntas personales': 'Personal questions',
  'Acciones en público': 'Actions in public',
  'VERDAD': 'TRUTH',
  'RETO': 'DARE',
  'Una pregunta': 'A question',
  'Atrévete': 'Go for it',
  'ELIGE UNA OPCIÓN': 'CHOOSE AN OPTION',
  'Pausar': 'Pause',
  'Reanudar': 'Resume',
  'Terminar': 'Finish',
  'Partida en pausa': 'Game paused',
  'Otra tarjeta': 'Another card',
  'Saltar jugador': 'Skip player',
  'Carita del jugador': 'Player face',
  'SIGUIENTE TURNO': 'NEXT TURN',
  'VER RESUMEN': 'VIEW SUMMARY',
  'CONTINUAR PARTIDA': 'CONTINUE GAME',
  'PUBLICIDAD': 'ADVERTISEMENT',
  'La partida continúa en un momento': 'The game will continue shortly',
  '¡Qué partida!': 'What a game!',
  'Verdades': 'Truths',
  'Retos': 'Dares',
  'Cambios': 'Changes',
  'JUGAR OTRA VEZ': 'PLAY AGAIN',
  'VOLVER AL INICIO': 'BACK TO HOME',
  'Adapta el juego a tu grupo': 'Adapt the game to your group',
  'EXPERIENCIA': 'EXPERIENCE',
  'Probar notificación': 'Test notification',
  'Envía una notificación local ahora': 'Send a local notification now',
  'Notificación de prueba enviada': 'Test notification sent',
  'Activa el permiso de notificaciones para probarla':
      'Enable notification permission to test it',
  'Vibración': 'Vibration',
  'Respuesta suave al revelar tarjetas': 'Gentle feedback when revealing cards',
  'Sonido': 'Sound',
  'Sonido breve del sistema al revelar': 'Short system sound when revealing',
  'Animaciones': 'Animations',
  'Transiciones breves y optimizadas': 'Short, optimized transitions',
  'TAMAÑO DEL TEXTO': 'TEXT SIZE',
  'DURACIÓN DE LA PARTIDA': 'GAME LENGTH',
  'Sin límite': 'No limit',
  'PRIVACIDAD E HISTORIAL': 'PRIVACY AND HISTORY',
  'Todo permanece en tu dispositivo': 'Everything stays on your device',
  'La app funciona sin conexión y no guarda respuestas, audio ni imágenes.':
      'The app works offline and does not store answers, audio or images.',
  'Se priorizan tarjetas que aún no han aparecido':
      'Cards that have not appeared yet are prioritized',
  'Reiniciar': 'Reset',
  'Volver': 'Back',
  'IDIOMA': 'LANGUAGE',
  'Idioma': 'Language',
  'Idioma de los textos de la aplicación': 'Language used by the application',
  'Automático (dispositivo)': 'Automatic (device)',
  'Español': 'Spanish',
  'Inglés': 'English',
  'VALORACIÓN': 'RATING',
  'Valorar la aplicación': 'Rate the app',
  'Comparte tu opinión en Google Play': 'Share your opinion on Google Play',
  'MÁS JUEGOS': 'MORE GAMES',
  'Jugar a La Bomba': 'Play The Bomb',
  'Responde antes de que explote': 'Answer before it explodes',
  'Jugar a Impostor': 'Play Impostor',
  'Descubre quién está fingiendo': 'Find out who is pretending',
  'Abrir en Google Play': 'Open in Google Play',
  '¿Salir de la partida?': 'Leave the game?',
  'Perderás el progreso de la partida actual.':
      'You will lose the progress of the current game.',
  'SEGUIR JUGANDO': 'KEEP PLAYING',
  'SALIR': 'LEAVE',
};
