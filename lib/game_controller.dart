import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_service.dart';
import 'audio_feedback.dart';
import 'content/bonus_packs_content.dart';
import 'game_data.dart';
import 'game_models.dart';

enum AppPage {
  consent,
  welcome,
  players,
  modeSetup,
  intensitySetup,
  playing,
  summary,
  settings,
}

class PlayerAward {
  const PlayerAward({
    required this.emoji,
    required this.title,
    required this.player,
    required this.detail,
  });

  final String emoji;
  final String title;
  final String player;
  final String detail;
}

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.rewardSparks,
  });

  final String id;
  final String emoji;
  final String title;
  final String description;
  final int rewardSparks;
}

const appAchievements = <AchievementDef>[
  AchievementDef(
    id: 'first_game',
    emoji: '🎉',
    title: 'Primera noche',
    description: 'Completa tu primera partida',
    rewardSparks: 40,
  ),
  AchievementDef(
    id: 'fearless_5',
    emoji: '🔥',
    title: 'Sin miedo',
    description: 'Completa 5 retos seguidos sin cambiar tarjeta',
    rewardSparks: 50,
  ),
  AchievementDef(
    id: 'all_modes',
    emoji: '🧭',
    title: 'Todo terreno',
    description: 'Juega en los 4 modos disponibles',
    rewardSparks: 60,
  ),
  AchievementDef(
    id: 'crowd_6',
    emoji: '👥',
    title: 'Multitud',
    description: 'Juega una partida con 6 o más personas',
    rewardSparks: 45,
  ),
  AchievementDef(
    id: 'marathon_30',
    emoji: '🏅',
    title: 'Maratón',
    description: 'Acumula 30 turnos completados',
    rewardSparks: 60,
  ),
  AchievementDef(
    id: 'custom_creator',
    emoji: '✍️',
    title: 'Guionista',
    description: 'Crea tu primera tarjeta personalizada',
    rewardSparks: 35,
  ),
];

int? detectCardTimerSeconds(String text) {
  final lower = text.toLowerCase();
  final secMatch = RegExp(
    r'\b(\d{1,2})\s*(segundos?|seconds?|s)\b',
  ).firstMatch(lower);
  if (secMatch != null) {
    final value = int.tryParse(secMatch.group(1)!);
    if (value != null && value >= 5 && value <= 90) return value;
  }
  if (RegExp(r'\b(1\s*minuto|un\s*minuto|1\s*minute|one\s*minute)\b')
      .hasMatch(lower)) {
    return 60;
  }
  return null;
}

class GameController extends ChangeNotifier {
  GameController() {
    _load();
  }

  static const freeCustomCardsLimit = 3;
  static const customCardCost = 30;
  static const rewardedAdSparks = 60;

  final _random = Random();
  AppPage page = AppPage.welcome;
  bool ready = false;
  bool consentAccepted = false;
  List<String> players = ['Alex', 'Sam'];
  Set<String> inactivePlayers = {};
  Map<String, List<String>> playerPresets = {};
  GameMode mode = GameMode.amigos;
  Intensity intensity = Intensity.suave;
  bool randomizeTurns = false;
  bool mixIntensities = false;
  bool contactAllowed = true;
  bool adultAllowed = true;
  bool alcoholAllowed = false;
  bool socialAllowed = false;
  bool personalAllowed = true;
  bool publicAllowed = false;
  bool soundEnabled = false;
  bool hapticsEnabled = true;
  bool animationsEnabled = true;
  double textScale = 1;
  int maxRounds = 20;
  bool hasSavedSession = false;

  // Match state
  String currentPlayer = '';
  GameCard? currentCard;
  GameCard? previousCard;
  bool paused = false;
  bool adBreakVisible = false;
  int turn = 0;
  int truthsCompleted = 0;
  int daresCompleted = 0;
  int skippedCards = 0;
  int sessionSparksEarned = 0;
  int _consecutiveDares = 0;
  final Map<String, int> _playerTruths = {};
  final Map<String, int> _playerDares = {};
  final Map<String, int> _playerSkips = {};
  int _lastPlayerIndex = -1;
  List<GameCard> _deck = [];
  Set<String> _history = {};
  AppPage _pageBeforeSettings = AppPage.welcome;
  bool _advancingTurn = false;
  String _languageCode = 'es';

  // Loyalty, rewards, custom cards & favorites
  int sparks = 0;
  int totalTurnsPlayed = 0;
  int totalGamesPlayed = 0;
  Set<String> modesPlayed = {};
  Set<String> unlockedPacks = {};
  Set<String> activeBonusPacks = {};
  Set<String> unlockedAchievements = {};
  List<String> newlyUnlockedAchievements = [];
  List<GameCard> customCards = [];
  bool includeCustomCards = true;
  List<GameCard> favoriteCards = [];

  String get languageCode => _languageCode;
  set languageCode(String value) {
    if (_languageCode == value) return;
    _languageCode = value;
    _deck = [];
  }

  static final _contactPattern = RegExp(
    r'\b(besa\w*|beso\w*|toca\w*|toque\w*|abrazo\w*|abraz\w*|masaje\w*|acarici\w*|lame\w*|chupa\w*|mord\w*|azot\w*|kiss\w*|touch\w*|hug\w*|massage\w*|cuddle\w*|lick\w*)\b',
    caseSensitive: false,
  );
  static final _adultPattern = RegExp(
    r'\b(sexo|sexual\w*|desnud\w*|foll\w*|orgasm\w*|íntim\w*|erótic\w*|erógen\w*|masturb\w*|porno\w*|fetiche\w*|striptease|oral\w*|penetr\w*|corrert\w*|corrido\w*|trío\w*|nudes|sex|sexual\w*|naked|orgasm\w*|intimate|erotic\w*|strip\w*|foreplay|lingerie|kink\w*)\b',
    caseSensitive: false,
  );
  static final _alcoholPattern = RegExp(
    r'\b(alcohol\w*|bebid\w*|borrach\w*|chupito\w*|copa\w*|cerveza\w*|vino|tequila|drink\w*|drunk|shots?|alcohol\w*|tipsy|booze)\b',
    caseSensitive: false,
  );
  static final _socialPattern = RegExp(
    r'\b(mensaje\w*|whatsapp|instagram|tiktok|chat|chatear|estado|publica\w*|foto de perfil|historia de|redes sociales|dm|text\w*|message\w*|post\w*|profile picture|social media|story)\b',
    caseSensitive: false,
  );
  static final _personalPattern = RegExp(
    r'\b(secreto\w*|vulnerable\w*|mentira\w*|confiesa\w*|inseguridad\w*|arrepent\w*|secret\w*|vulnerable|lies?|lied|lying|confess\w*|insecurity|regret\w*)\b',
    caseSensitive: false,
  );
  static final _publicPattern = RegExp(
    r'\b(en público|en la calle|bar|bares|baño público|discoteca|local|coche|vecino\w*|in public|public place|street|nightclub|restroom|bathroom|car|stranger\w*)\b',
    caseSensitive: false,
  );

  List<String> get activePlayers =>
      players.where((name) => !inactivePlayers.contains(name)).toList();
  int get historyCount => _history.length;
  bool get reachedRoundLimit => maxRounds > 0 && turn >= maxRounds;
  bool get nextCustomCardIsFree => customCards.length < freeCustomCardsLimit;
  int get freeCustomCardsRemaining =>
      max(0, freeCustomCardsLimit - customCards.length);
  bool get canAffordCustomCard =>
      nextCustomCardIsFree || sparks >= customCardCost;

  String get rankTitle {
    if (totalTurnsPlayed >= 150) return 'Leyenda Nocturna';
    if (totalTurnsPlayed >= 60) return 'Sin Filtros';
    if (totalTurnsPlayed >= 20) return 'Alma de la Fiesta';
    return 'Rompehielos';
  }

  List<PlayerAward> get playerAwards {
    final awards = <PlayerAward>[];
    String? topKey(Map<String, int> map) {
      String? best;
      var bestVal = 0;
      for (final entry in map.entries) {
        if (entry.value > bestVal) {
          bestVal = entry.value;
          best = entry.key;
        }
      }
      return best;
    }

    final bravest = topKey(_playerDares);
    if (bravest != null) {
      awards.add(
        PlayerAward(
          emoji: '🔥',
          title: 'Más valiente',
          player: bravest,
          detail: '${_playerDares[bravest]}',
        ),
      );
    }
    final mostHonest = topKey(_playerTruths);
    if (mostHonest != null) {
      awards.add(
        PlayerAward(
          emoji: '💬',
          title: 'Más sincero',
          player: mostHonest,
          detail: '${_playerTruths[mostHonest]}',
        ),
      );
    }
    final skipper = topKey(_playerSkips);
    if (skipper != null && (_playerSkips[skipper] ?? 0) >= 2) {
      awards.add(
        PlayerAward(
          emoji: '🔄',
          title: 'Rey del cambio',
          player: skipper,
          detail: '${_playerSkips[skipper]}',
        ),
      );
    }
    return awards;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    consentAccepted = prefs.getBool('consent') ?? false;
    if (consentAccepted) unawaited(AdService.instance.initialize());
    players = prefs.getStringList('players') ?? players;
    inactivePlayers = (prefs.getStringList('inactivePlayers') ?? []).toSet();
    _history = (prefs.getStringList('history') ?? []).toSet();
    soundEnabled = prefs.getBool('sound') ?? false;
    AppAudio.enabled = soundEnabled;
    hapticsEnabled = prefs.getBool('haptics') ?? true;
    AppAudio.hapticsEnabled = hapticsEnabled;
    animationsEnabled = prefs.getBool('animations') ?? true;
    textScale = prefs.getDouble('textScale') ?? 1;
    maxRounds = prefs.getInt('maxRounds') ?? 20;

    // Quick session restore
    hasSavedSession = prefs.getBool('hasSavedSession') ?? false;
    final savedMode = prefs.getString('lastMode');
    if (savedMode != null) {
      mode = GameMode.values.firstWhere(
        (m) => m.name == savedMode,
        orElse: () => GameMode.amigos,
      );
    }
    final savedIntensity = prefs.getString('lastIntensity');
    if (savedIntensity != null) {
      intensity = Intensity.values.firstWhere(
        (i) => i.name == savedIntensity,
        orElse: () => Intensity.suave,
      );
    }
    mixIntensities = prefs.getBool('lastMixIntensities') ?? false;
    randomizeTurns = prefs.getBool('lastRandomizeTurns') ?? false;

    // Loyalty & content state
    sparks = prefs.getInt('sparks') ?? 0;
    totalTurnsPlayed = prefs.getInt('totalTurnsPlayed') ?? 0;
    totalGamesPlayed = prefs.getInt('totalGamesPlayed') ?? 0;
    modesPlayed = (prefs.getStringList('modesPlayed') ?? []).toSet();
    unlockedPacks = (prefs.getStringList('unlockedPacks') ?? []).toSet();
    activeBonusPacks = (prefs.getStringList('activeBonusPacks') ?? [])
        .where(unlockedPacks.contains)
        .toSet();
    unlockedAchievements =
        (prefs.getStringList('unlockedAchievements') ?? []).toSet();
    includeCustomCards = prefs.getBool('includeCustomCards') ?? true;
    customCards = _decodeCards(prefs.getStringList('customCards') ?? []);
    favoriteCards = _decodeCards(prefs.getStringList('favoriteCards') ?? []);
    playerPresets = _decodePresets(prefs.getString('playerPresets'));

    page = consentAccepted ? AppPage.welcome : AppPage.consent;
    ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('consent', consentAccepted);
    await prefs.setStringList('players', players);
    await prefs.setStringList('inactivePlayers', inactivePlayers.toList());
    await prefs.setStringList('history', _history.toList());
    await prefs.setBool('sound', soundEnabled);
    await prefs.setBool('haptics', hapticsEnabled);
    await prefs.setBool('animations', animationsEnabled);
    await prefs.setDouble('textScale', textScale);
    await prefs.setInt('maxRounds', maxRounds);
    await prefs.setBool('hasSavedSession', hasSavedSession);
    await prefs.setString('lastMode', mode.name);
    await prefs.setString('lastIntensity', intensity.name);
    await prefs.setBool('lastMixIntensities', mixIntensities);
    await prefs.setBool('lastRandomizeTurns', randomizeTurns);
    await prefs.setInt('sparks', sparks);
    await prefs.setInt('totalTurnsPlayed', totalTurnsPlayed);
    await prefs.setInt('totalGamesPlayed', totalGamesPlayed);
    await prefs.setStringList('modesPlayed', modesPlayed.toList());
    await prefs.setStringList('unlockedPacks', unlockedPacks.toList());
    await prefs.setStringList('activeBonusPacks', activeBonusPacks.toList());
    await prefs.setStringList(
      'unlockedAchievements',
      unlockedAchievements.toList(),
    );
    await prefs.setBool('includeCustomCards', includeCustomCards);
    await prefs.setStringList('customCards', _encodeCards(customCards));
    await prefs.setStringList('favoriteCards', _encodeCards(favoriteCards));
    await prefs.setString('playerPresets', jsonEncode(playerPresets));
  }

  List<String> _encodeCards(List<GameCard> cards) =>
      cards.map((c) => '${c.type.name}|${c.text}').toList();

  List<GameCard> _decodeCards(List<String> encoded) {
    final out = <GameCard>[];
    for (final raw in encoded) {
      final sep = raw.indexOf('|');
      if (sep <= 0) continue;
      final typeName = raw.substring(0, sep);
      final text = raw.substring(sep + 1).trim();
      if (text.isEmpty) continue;
      final type = typeName == CardType.reto.name
          ? CardType.reto
          : CardType.verdad;
      out.add(GameCard(type, text));
    }
    return out;
  }

  Map<String, List<String>> _decodePresets(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((e) => e.toString()).toList(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  void acceptConsent() {
    consentAccepted = true;
    page = AppPage.welcome;
    unawaited(AdService.instance.initialize());
    _save();
    notifyListeners();
  }

  void showPlayers() => _setPage(AppPage.players);
  void showSetup() {
    if (activePlayers.length >= 2) _setPage(AppPage.modeSetup);
  }

  void showIntensitySetup() => _setPage(AppPage.intensitySetup);

  void showSettings() {
    _pageBeforeSettings = page;
    _setPage(AppPage.settings);
  }

  void closeSettings() => _setPage(_pageBeforeSettings);

  void back() {
    if (page == AppPage.playing) paused = false;
    page = switch (page) {
      AppPage.players => AppPage.welcome,
      AppPage.modeSetup => AppPage.players,
      AppPage.intensitySetup => AppPage.modeSetup,
      AppPage.playing =>
        mode == GameMode.familia ? AppPage.modeSetup : AppPage.intensitySetup,
      AppPage.summary => AppPage.welcome,
      AppPage.settings => _pageBeforeSettings,
      AppPage.consent => AppPage.consent,
      AppPage.welcome => AppPage.welcome,
    };
    notifyListeners();
  }

  String _normalizePlayerName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.substring(0, min(trimmed.length, 18)).trim();
  }

  bool addPlayer(String value) {
    final name = _normalizePlayerName(value);
    if (name.isEmpty ||
        players.length >= 12 ||
        players.any((p) => p.toLowerCase() == name.toLowerCase())) {
      return false;
    }
    players = [...players, name];
    _save();
    notifyListeners();
    return true;
  }

  void editPlayer(String oldName, String value) {
    final name = _normalizePlayerName(value);
    if (name.isEmpty ||
        players.any(
          (p) => p != oldName && p.toLowerCase() == name.toLowerCase(),
        )) {
      return;
    }
    final index = players.indexOf(oldName);
    if (index < 0) return;
    players = [...players]..[index] = name;
    if (inactivePlayers.remove(oldName)) inactivePlayers.add(name);
    _save();
    notifyListeners();
  }

  void reorderPlayer(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= players.length ||
        newIndex < 0 ||
        newIndex >= players.length) {
      return;
    }
    final updated = [...players];
    final player = updated.removeAt(oldIndex);
    updated.insert(newIndex, player);
    players = updated;
    _save();
    notifyListeners();
  }

  void togglePlayer(String name, bool active) {
    active ? inactivePlayers.remove(name) : inactivePlayers.add(name);
    _save();
    notifyListeners();
  }

  void removePlayer(String name) {
    players = players.where((player) => player != name).toList();
    inactivePlayers.remove(name);
    _save();
    notifyListeners();
  }

  bool savePlayerPreset(String rawName) {
    final name = _normalizePlayerName(rawName);
    final current = activePlayers;
    if (name.isEmpty || current.length < 2) return false;
    playerPresets = {...playerPresets, name: current};
    _save();
    notifyListeners();
    return true;
  }

  void applyPlayerPreset(String name) {
    final list = playerPresets[name];
    if (list == null || list.length < 2) return;
    players = [...list];
    inactivePlayers.clear();
    _save();
    notifyListeners();
  }

  void deletePlayerPreset(String name) {
    if (!playerPresets.containsKey(name)) return;
    final updated = {...playerPresets}..remove(name);
    playerPresets = updated;
    _save();
    notifyListeners();
  }

  void selectMode(GameMode value) {
    mode = value;
    if (value == GameMode.familia) {
      mixIntensities = false;
      randomizeTurns = false;
    }
    notifyListeners();
  }

  void selectIntensity(Intensity value) {
    intensity = value;
    notifyListeners();
  }

  void setRandomizeTurns(bool value) {
    randomizeTurns = value;
    notifyListeners();
  }

  void setMixIntensities(bool value) {
    mixIntensities = value;
    notifyListeners();
  }

  void setContentFilter(String key, bool value) {
    switch (key) {
      case 'contact':
        contactAllowed = value;
      case 'adult':
        adultAllowed = value;
      case 'alcohol':
        alcoholAllowed = value;
      case 'social':
        socialAllowed = value;
      case 'personal':
        personalAllowed = value;
      case 'public':
        publicAllowed = value;
    }
    notifyListeners();
  }

  void toggleBonusPackActive(String packId) {
    if (!unlockedPacks.contains(packId)) return;
    if (activeBonusPacks.contains(packId)) {
      activeBonusPacks.remove(packId);
    } else {
      activeBonusPacks.add(packId);
    }
    _save();
    notifyListeners();
  }

  bool unlockPackWithSparks(String packId) {
    final pack = bonusPackById(packId);
    if (pack == null || unlockedPacks.contains(packId)) return false;
    if (sparks < pack.costSparks) return false;
    sparks -= pack.costSparks;
    unlockedPacks.add(packId);
    activeBonusPacks.add(packId);
    _save();
    notifyListeners();
    return true;
  }

  Future<bool> unlockPackWithRewardedAd(String packId) async {
    final pack = bonusPackById(packId);
    if (pack == null || unlockedPacks.contains(packId)) return false;
    final earned = await AdService.instance.showRewardedAd();
    if (!earned) return false;
    unlockedPacks.add(packId);
    activeBonusPacks.add(packId);
    _save();
    notifyListeners();
    return true;
  }

  Future<bool> earnSparksFromRewardedAd() async {
    final earned = await AdService.instance.showRewardedAd();
    if (!earned) return false;
    sparks += rewardedAdSparks;
    _save();
    notifyListeners();
    return true;
  }

  void setIncludeCustomCards(bool value) {
    includeCustomCards = value;
    _save();
    notifyListeners();
  }

  bool addCustomCard(
    CardType type,
    String rawText, {
    bool paidWithAd = false,
  }) {
    final text = rawText.trim();
    if (text.length < 4) return false;
    if (customCards.any((c) => c.text.toLowerCase() == text.toLowerCase())) {
      return false;
    }
    if (!nextCustomCardIsFree && !paidWithAd) {
      if (sparks < customCardCost) return false;
      sparks -= customCardCost;
    }
    customCards = [GameCard(type, text), ...customCards];
    _unlockAchievement('custom_creator');
    _save();
    notifyListeners();
    return true;
  }

  void removeCustomCard(GameCard card) {
    customCards = customCards
        .where((c) => !(c.type == card.type && c.text == card.text))
        .toList();
    _save();
    notifyListeners();
  }

  bool isFavorite(GameCard card) =>
      favoriteCards.any((c) => c.type == card.type && c.text == card.text);

  void toggleFavorite(GameCard card) {
    if (isFavorite(card)) {
      favoriteCards = favoriteCards
          .where((c) => !(c.type == card.type && c.text == card.text))
          .toList();
    } else {
      favoriteCards = [card, ...favoriteCards];
    }
    _save();
    notifyListeners();
  }

  void startQuickGame() {
    if (activePlayers.length < 2) {
      showPlayers();
      return;
    }
    startGame();
  }

  void startGame() {
    AdService.instance.startGameSession();
    hasSavedSession = true;
    paused = false;
    adBreakVisible = false;
    _deck = _buildFilteredDeck();
    turn = 0;
    truthsCompleted = 0;
    daresCompleted = 0;
    skippedCards = 0;
    sessionSparksEarned = 0;
    _consecutiveDares = 0;
    _playerTruths.clear();
    _playerDares.clear();
    _playerSkips.clear();
    newlyUnlockedAchievements = [];
    modesPlayed.add(mode.name);
    if (modesPlayed.length >= GameMode.values.length) {
      _unlockAchievement('all_modes');
    }
    if (activePlayers.length >= 6) {
      _unlockAchievement('crowd_6');
    }
    _lastPlayerIndex = -1;
    currentCard = null;
    previousCard = null;
    final available = activePlayers;
    if (available.length >= 2) {
      _lastPlayerIndex = 0;
      currentPlayer = available[0];
      turn = 1;
    }
    page = AppPage.playing;
    _save();
    notifyListeners();
  }

  @visibleForTesting
  bool allowsCardText(String text) {
    if (!contactAllowed && _contactPattern.hasMatch(text)) return false;
    if (!adultAllowed && _adultPattern.hasMatch(text)) return false;
    if (!alcoholAllowed && _alcoholPattern.hasMatch(text)) return false;
    if (!socialAllowed && _socialPattern.hasMatch(text)) return false;
    if (!personalAllowed && _personalPattern.hasMatch(text)) return false;
    if (!publicAllowed && _publicPattern.hasMatch(text)) return false;
    return true;
  }

  List<GameCard> _buildFilteredDeck() {
    final intensities = mode == GameMode.familia
        ? const [Intensity.suave]
        : mixIntensities
        ? Intensity.values
        : [intensity];
    final english = _languageCode == 'en';
    final baseCards = intensities
        .expand((value) => buildDeck(mode, value, english: english))
        .where((card) => allowsCardText(card.text));

    final bonusCards = activeBonusPacks
        .map(bonusPackById)
        .whereType<BonusPack>()
        .expand((pack) => pack.cards(english: english))
        .where((card) => allowsCardText(card.text));

    final extraCustom = includeCustomCards ? customCards : const <GameCard>[];

    final cards = <GameCard>[...baseCards, ...bonusCards, ...extraCustom];
    return cards..shuffle(_random);
  }

  List<GameCard> _fallbackCardsFor(CardType type) {
    final fallbackMode = mode == GameMode.familia ? GameMode.familia : mode;
    final mildDeck = buildDeck(
      fallbackMode,
      Intensity.suave,
      english: _languageCode == 'en',
    ).where((card) => card.type == type).toList();
    final filteredMild = mildDeck
        .where((card) => allowsCardText(card.text))
        .toList();
    if (filteredMild.isNotEmpty) return filteredMild..shuffle(_random);
    return mildDeck..shuffle(_random);
  }

  void chooseCard(CardType type) => _draw(type, skipped: false);

  void chooseRandomCard() {
    final type = _random.nextBool() ? CardType.verdad : CardType.reto;
    chooseCard(type);
  }

  void anotherCard() {
    final type = currentCard?.type;
    if (type == null) return;
    skippedCards++;
    _consecutiveDares = 0;
    if (currentPlayer.isNotEmpty) {
      _playerSkips[currentPlayer] = (_playerSkips[currentPlayer] ?? 0) + 1;
    }
    _draw(type, skipped: true);
  }

  void _draw(CardType type, {required bool skipped}) {
    if (!_deck.any((card) => card.type == type)) {
      final rebuilt = _buildFilteredDeck()
          .where((card) => card.type == type)
          .toList();
      _deck.addAll(rebuilt.isNotEmpty ? rebuilt : _fallbackCardsFor(type));
    }
    var candidates = _deck
        .where(
          (card) =>
              card.type == type &&
              !_history.contains(card.text) &&
              card.text != currentCard?.text,
        )
        .toList();
    if (candidates.isEmpty) {
      candidates = _deck
          .where((card) => card.type == type && card.text != currentCard?.text)
          .toList();
    }
    if (candidates.isEmpty) {
      candidates = _deck.where((card) => card.type == type).toList();
    }
    if (candidates.isEmpty) return;
    previousCard = skipped ? currentCard : null;
    currentCard = candidates[_random.nextInt(candidates.length)];
    _deck.remove(currentCard);
    _history.add(currentCard!.text);
    _save();
    _feedback();
    notifyListeners();
  }

  void restorePreviousCard() {
    if (previousCard == null) return;
    final card = currentCard;
    currentCard = previousCard;
    previousCard = card;
    notifyListeners();
  }

  void _unlockAchievement(String id) {
    if (unlockedAchievements.contains(id)) return;
    final def = appAchievements.where((a) => a.id == id).firstOrNull;
    if (def == null) return;
    unlockedAchievements.add(id);
    newlyUnlockedAchievements = [...newlyUnlockedAchievements, id];
    sparks += def.rewardSparks;
    sessionSparksEarned += def.rewardSparks;
  }

  Future<void> nextTurn({bool completed = true}) async {
    if (_advancingTurn) return;
    _advancingTurn = true;
    try {
      if (completed) {
        if (currentCard?.type == CardType.verdad) {
          truthsCompleted++;
          totalTurnsPlayed++;
          sparks += 10;
          sessionSparksEarned += 10;
          _consecutiveDares = 0;
          if (currentPlayer.isNotEmpty) {
            _playerTruths[currentPlayer] =
                (_playerTruths[currentPlayer] ?? 0) + 1;
          }
        }
        if (currentCard?.type == CardType.reto) {
          daresCompleted++;
          totalTurnsPlayed++;
          sparks += 15;
          sessionSparksEarned += 15;
          _consecutiveDares++;
          if (currentPlayer.isNotEmpty) {
            _playerDares[currentPlayer] =
                (_playerDares[currentPlayer] ?? 0) + 1;
          }
          if (_consecutiveDares >= 5) _unlockAchievement('fearless_5');
        }
        if (totalTurnsPlayed >= 30) _unlockAchievement('marathon_30');
        if (reachedRoundLimit && turn > 0) {
          finishGame();
          return;
        }
      } else {
        _consecutiveDares = 0;
      }
      currentCard = null;
      previousCard = null;
      final available = activePlayers;
      if (available.length < 2) return;
      if (completed &&
          await AdService.instance.canShowAfterTurn(turn, available.length)) {
        adBreakVisible = true;
        notifyListeners();
        await Future<void>.delayed(const Duration(milliseconds: 700));
        await AdService.instance.showTurnBreak();
        adBreakVisible = false;
      }
      if (randomizeTurns && _lastPlayerIndex >= 0) {
        final indices = List.generate(
          available.length,
          (index) => index,
        ).where((index) => index != _lastPlayerIndex).toList();
        _lastPlayerIndex = indices[_random.nextInt(indices.length)];
      } else {
        _lastPlayerIndex = (_lastPlayerIndex + 1) % available.length;
      }
      currentPlayer = available[_lastPlayerIndex];
      if (completed || turn == 0) turn++;
      _save();
      notifyListeners();
    } finally {
      adBreakVisible = false;
      _advancingTurn = false;
    }
  }

  Future<void> skipPlayer() => nextTurn(completed: false);

  void togglePause() {
    paused = !paused;
    notifyListeners();
  }

  void _feedback() {
    if (hapticsEnabled) HapticFeedback.selectionClick();
    AppAudio.play(AppSound.reveal);
  }

  void setPreference(String key, bool value) {
    if (key == 'sound') {
      soundEnabled = value;
      AppAudio.enabled = value;
      if (value) AppAudio.play(AppSound.confirm);
    }
    if (key == 'haptics') {
      hapticsEnabled = value;
      AppAudio.hapticsEnabled = value;
    }
    if (key == 'animations') animationsEnabled = value;
    _save();
    notifyListeners();
  }

  void setTextScale(double value) {
    textScale = value;
    _save();
    notifyListeners();
  }

  void setMaxRounds(int value) {
    maxRounds = value;
    _save();
    notifyListeners();
  }

  void resetHistory() {
    _history.clear();
    _save();
    notifyListeners();
  }

  void finishGame() {
    paused = false;
    adBreakVisible = false;
    if (truthsCompleted + daresCompleted > 0) {
      totalGamesPlayed++;
      sparks += 20;
      sessionSparksEarned += 20;
      _unlockAchievement('first_game');
      _save();
    }
    _setPage(AppPage.summary);
  }

  void playAgain() => startGame();
  void goHome() => _setPage(AppPage.welcome);

  void _setPage(AppPage value) {
    page = value;
    notifyListeners();
  }
}
