import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_feedback.dart';
import 'ad_service.dart';
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

class GameController extends ChangeNotifier {
  GameController() {
    _load();
  }

  final _random = Random();
  AppPage page = AppPage.welcome;
  bool ready = false;
  bool consentAccepted = false;
  List<String> players = ['Alex', 'Sam'];
  Set<String> inactivePlayers = {};
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
  String currentPlayer = '';
  GameCard? currentCard;
  GameCard? previousCard;
  bool paused = false;
  bool adBreakVisible = false;
  int turn = 0;
  int truthsCompleted = 0;
  int daresCompleted = 0;
  int skippedCards = 0;
  int _lastPlayerIndex = -1;
  List<GameCard> _deck = [];
  Set<String> _history = {};
  AppPage _pageBeforeSettings = AppPage.welcome;
  bool _advancingTurn = false;
  String _languageCode = 'es';

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

  void startGame() {
    AdService.instance.startGameSession();
    paused = false;
    adBreakVisible = false;
    _deck = _buildFilteredDeck();
    turn = 0;
    truthsCompleted = 0;
    daresCompleted = 0;
    skippedCards = 0;
    _lastPlayerIndex = -1;
    currentCard = null;
    previousCard = null;
    page = AppPage.playing;
    nextTurn();
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
    final cards = intensities
        .expand(
          (value) => buildDeck(mode, value, english: _languageCode == 'en'),
        )
        .where((card) => allowsCardText(card.text))
        .toList();
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

  void anotherCard() {
    final type = currentCard?.type;
    if (type == null) return;
    skippedCards++;
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

  Future<void> nextTurn({bool completed = true}) async {
    if (_advancingTurn) return;
    _advancingTurn = true;
    try {
      if (completed) {
        if (currentCard?.type == CardType.verdad) truthsCompleted++;
        if (currentCard?.type == CardType.reto) daresCompleted++;
        if (reachedRoundLimit && turn > 0) {
          finishGame();
          return;
        }
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
    _setPage(AppPage.summary);
  }

  void playAgain() => startGame();
  void goHome() => _setPage(AppPage.welcome);

  void _setPage(AppPage value) {
    page = value;
    notifyListeners();
  }
}
