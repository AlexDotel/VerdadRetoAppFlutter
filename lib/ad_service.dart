import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

class AdService {
  AdService._();
  static final instance = AdService._();

  static const appKey = '0596564f2ebf4266d6944678836a0c5b24a7baa89909bd1b';
  static const placement = 'default';
  static const testing = true;
  static const minimumInterval = Duration(minutes: 2);

  bool _initializing = false;
  bool _initialized = false;
  bool _showing = false;
  DateTime? _sessionStartedAt;
  DateTime? _lastShownAt;
  bool _firstRoundAdShown = false;
  Completer<void>? _closedCompleter;

  void startGameSession() {
    _sessionStartedAt = DateTime.now();
    _firstRoundAdShown = false;
  }

  Future<void> initialize() async {
    if (_initialized || _initializing) return;
    _initializing = true;
    _sessionStartedAt = DateTime.now();
    try {
      Appodeal.setTesting(testing);
      Appodeal.setLogLevel(
        testing ? Appodeal.LogLevelVerbose : Appodeal.LogLevelNone,
      );
      Appodeal.setChildDirectedTreatment(false);
      Appodeal.setAutoCache(AppodealAdType.Interstitial, true);
      Appodeal.muteVideosIfCallsMuted(true);
      Appodeal.setInterstitialCallbacks(
        onInterstitialShown: () {
          _lastShownAt = DateTime.now();
          _firstRoundAdShown = true;
        },
        onInterstitialShowFailed: _finishShowing,
        onInterstitialClosed: _finishShowing,
        onInterstitialExpired: _finishShowing,
      );

      Appodeal.initialize(
        appKey: appKey,
        adTypes: const [AppodealAdType.Interstitial],
        onInitializationFinished: (errors) {
          _initialized = true;
          _initializing = false;
          if (errors != null && errors.isNotEmpty) {
            debugPrint('Appodeal initialization: $errors');
          }
        },
      );
    } catch (error) {
      debugPrint('Appodeal unavailable: $error');
      _initializing = false;
    }
  }

  Future<bool> canShowAfterTurn(
    int completedTurn,
    int activePlayerCount,
  ) async {
    if (!_initialized || _showing || completedTurn <= 0) {
      return false;
    }
    if (!_firstRoundAdShown) {
      if (activePlayerCount < 2 || completedTurn < activePlayerCount) {
        return false;
      }
    } else {
      final sessionStart = _sessionStartedAt;
      final lastShown = _lastShownAt;
      final anchor =
          lastShown != null &&
              (sessionStart == null || lastShown.isAfter(sessionStart))
          ? lastShown
          : sessionStart;
      if (anchor == null ||
          DateTime.now().difference(anchor) < minimumInterval) {
        return false;
      }
    }
    try {
      return await Appodeal.canShow(AppodealAdType.Interstitial, placement);
    } catch (_) {
      return false;
    }
  }

  Future<bool> showTurnBreak() async {
    if (!_initialized || _showing) return false;
    try {
      final available = await Appodeal.canShow(
        AppodealAdType.Interstitial,
        placement,
      );
      if (!available) return false;
      _showing = true;
      _closedCompleter = Completer<void>();
      final accepted = await Appodeal.show(
        AppodealAdType.Interstitial,
        placement,
      );
      if (!accepted) {
        _finishShowing();
        return false;
      }
      await _closedCompleter!.future.timeout(const Duration(minutes: 2));
      return true;
    } catch (error) {
      debugPrint('Interstitial unavailable: $error');
      _finishShowing();
      return false;
    }
  }

  Future<bool> showTestWhenReady() async {
    for (var attempt = 0; attempt < 30; attempt++) {
      if (_initialized &&
          await Appodeal.canShow(AppodealAdType.Interstitial, placement)) {
        return showTurnBreak();
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    return false;
  }

  void _finishShowing() {
    _showing = false;
    final completer = _closedCompleter;
    _closedCompleter = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }
}
