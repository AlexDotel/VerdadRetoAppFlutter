import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:stack_appodeal_flutter/stack_appodeal_flutter.dart';

class AdService {
  AdService._();
  static final instance = AdService._();

  static const appKey = 'd8b53d4823a08ea01337203a26f7dd20d1c10030855b4bcc';
  static const placement = 'round_complete';
  static const testing = true;
  static const minimumInterval = Duration(minutes: 2);

  bool _initializing = false;
  bool _initialized = false;
  bool _showing = false;
  DateTime? _sessionStartedAt;
  DateTime? _lastShownAt;
  Completer<void>? _closedCompleter;

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
        },
        onInterstitialShowFailed: _finishShowing,
        onInterstitialClosed: _finishShowing,
        onInterstitialExpired: _finishShowing,
      );

      final initialized = Completer<void>();
      Appodeal.initialize(
        appKey: appKey,
        adTypes: const [AppodealAdType.Interstitial],
        onInitializationFinished: (errors) {
          _initialized = true;
          if (errors != null && errors.isNotEmpty) {
            debugPrint('Appodeal initialization: $errors');
          }
          if (!initialized.isCompleted) initialized.complete();
        },
      );
      await initialized.future.timeout(const Duration(seconds: 20));
    } catch (error) {
      debugPrint('Appodeal unavailable: $error');
    } finally {
      _initializing = false;
    }
  }

  Future<bool> canShowAfterRound(int completedRound) async {
    if (!_initialized || _showing || completedRound <= 1) return false;
    final anchor = _lastShownAt ?? _sessionStartedAt;
    if (anchor == null || DateTime.now().difference(anchor) < minimumInterval) {
      return false;
    }
    try {
      return await Appodeal.canShow(AppodealAdType.Interstitial, placement);
    } catch (_) {
      return false;
    }
  }

  Future<bool> showRoundBreak() async {
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
        return showRoundBreak();
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
