enum GameMode {
  amigos('Amigos', 'Risas y buenas historias', '🎉'),
  pareja('Pareja', 'Conexión y complicidad', '💞'),
  fiesta('Fiesta', 'Más energía, más caos', '🪩'),
  familia('Familia', 'Para todas las edades', '🏡');

  const GameMode(this.title, this.subtitle, this.emoji);
  final String title;
  final String subtitle;
  final String emoji;
}

enum Intensity {
  suave('Suave', 'Para romper el hielo', '🌿'),
  atrevido('Atrevido', 'Sube la temperatura', '🔥'),
  extremo('Extremo', 'Sin miedo y con confianza', '💥');

  const Intensity(this.title, this.subtitle, this.emoji);
  final String title;
  final String subtitle;
  final String emoji;
}

enum CardType {
  verdad('VERDAD', '💬'),
  reto('RETO', '⚡');

  const CardType(this.title, this.emoji);
  final String title;
  final String emoji;
}

class GameCard {
  const GameCard(this.type, this.text);
  final CardType type;
  final String text;
}
