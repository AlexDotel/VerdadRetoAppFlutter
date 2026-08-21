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

  bool addPlayer(String value) {
    final name = value.trim();
    if (name.isEmpty ||
        players.length >= 12 ||
        players.any((p) => p.toLowerCase() == name.toLowerCase())) {
      return false;
    }
    players = [...players, name.substring(0, min(name.length, 18))];
    _save();
    notifyListeners();
    return true;
  }

  void editPlayer(String oldName, String value) {
    final name = value.trim();
    if (name.isEmpty ||
        players.any(
          (p) => p != oldName && p.toLowerCase() == name.toLowerCase(),
        )) {
      return;
    }
    final index = players.indexOf(oldName);
    if (index < 0) return;
    players = [...players]..[index] = name.substring(0, min(name.length, 18));
    if (inactivePlayers.remove(oldName)) inactivePlayers.add(players[index]);
    _save();
    notifyListeners();
  }

  void reorderPlayer(int oldIndex, int newIndex) {
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
    _deck = _buildFilteredDeck();
    turn = 0;
    truthsCompleted = 0;
    daresCompleted = 0;
    skippedCards = 0;
    _lastPlayerIndex = -1;
    previousCard = null;
    page = AppPage.playing;
    nextTurn();
  }

  List<GameCard> _buildFilteredDeck() {
    final intensities = mode == GameMode.familia
        ? const [Intensity.suave]
        : mixIntensities
        ? Intensity.values
        : [intensity];
    final cards = intensities.expand((value) => buildDeck(mode, value)).where((
      card,
    ) {
      final text = card.text.toLowerCase();
      if (!contactAllowed && _has(text, ['besa', 'toca', 'abrazo', 'masaje'])) {
        return false;
      }
      if (!adultAllowed &&
          _has(text, [
            'sexo',
            'sexual',
            'desnud',
            'folla',
            'orgasmo',
            'íntim',
          ])) {
        return false;
      }
      if (!alcoholAllowed &&
          _has(text, ['alcohol', 'bebid', 'borrach', 'chupito'])) {
        return false;
      }
      if (!socialAllowed &&
          _has(text, [
            'mensaje',
            'chat',
            'estado',
            'publica',
            'foto de perfil',
          ])) {
        return false;
      }
      if (!personalAllowed &&
          _has(text, ['secreto', 'vulnerable', 'mentira', 'confiesa'])) {
        return false;
      }
      if (!publicAllowed &&
          _has(text, ['en público', 'bar', 'baño', 'coche'])) {
        return false;
      }
      return true;
    }).toList();
    return cards..shuffle(_random);
  }

  bool _has(String text, List<String> terms) => terms.any(text.contains);

  void chooseCard(CardType type) => _draw(type, skipped: false);

  void anotherCard() {
    final type = currentCard?.type;
    if (type == null) return;
    skippedCards++;
    _draw(type, skipped: true);
  }

  void _draw(CardType type, {required bool skipped}) {
    if (_deck.isEmpty) _deck = _buildFilteredDeck();
    var candidates = _deck
        .where((card) => card.type == type && !_history.contains(card.text))
        .toList();
    candidates = candidates.isEmpty
        ? _deck.where((card) => card.type == type).toList()
        : candidates;
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

  Future<void> nextTurn() async {
    if (_advancingTurn) return;
    _advancingTurn = true;
    try {
      if (currentCard?.type == CardType.verdad) truthsCompleted++;
      if (currentCard?.type == CardType.reto) daresCompleted++;
      if (reachedRoundLimit && turn > 0) {
        finishGame();
        return;
      }
      currentCard = null;
      previousCard = null;
      final available = activePlayers;
      if (available.length < 2) return;
      if (await AdService.instance.canShowAfterTurn(turn, available.length)) {
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
      turn++;
      notifyListeners();
    } finally {
      adBreakVisible = false;
      _advancingTurn = false;
    }
  }

  Future<void> skipPlayer() => nextTurn();
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
    if (key == 'haptics') hapticsEnabled = value;
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

  void finishGame() => _setPage(AppPage.summary);
  void playAgain() => startGame();
  void goHome() => _setPage(AppPage.welcome);

  void _setPage(AppPage value) {
    page = value;
    notifyListeners();
  }
}
