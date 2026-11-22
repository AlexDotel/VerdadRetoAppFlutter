import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_feedback.dart';
import 'app_language.dart';
import 'feature_sheets.dart';
import 'game_controller.dart';
import 'game_models.dart';
import 'notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  debugPaintBaselinesEnabled = false;
  debugPaintSizeEnabled = false;
  debugPaintLayerBordersEnabled = false;
  debugPaintPointersEnabled = false;
  debugRepaintRainbowEnabled = false;
  debugRepaintTextRainbowEnabled = false;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: ink,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const TruthOrDareApp());
}

const ink = Color(0xFF1C102B);
const plum = Color(0xFF2F1A42);
const purple = Color(0xFF7659E6);
const coral = Color(0xFFFF6B67);
const gold = Color(0xFFF2B85B);
const mist = Color(0xFFFBF8FF);
const snappy = Cubic(0.23, 1, 0.32, 1);
const truthCardColors = [Color(0xFFD94F55), Color(0xFFEE6B70)];
const dareCardColors = [Color(0xFF6750C8), Color(0xFF826CE0)];

class TruthOrDareApp extends StatefulWidget {
  const TruthOrDareApp({super.key});

  @override
  State<TruthOrDareApp> createState() => _TruthOrDareAppState();
}

class _TruthOrDareAppState extends State<TruthOrDareApp> {
  final controller = GameController();
  bool lightMode = false;
  String language = 'system';
  static const _platform = MethodChannel('verdadoreto/ui_audio');
  static const _sendTestNotification = bool.fromEnvironment(
    'SEND_TEST_NOTIFICATION',
  );

  @override
  void initState() {
    super.initState();
    controller.addListener(_refresh);
    _loadTheme();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _requestNotificationPermissionOnce();
      if (_sendTestNotification) {
        NotificationService.instance.showTestNotification();
      }
    });
  }

  Future<void> _loadTheme() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      lightMode = preferences.getBool('light_mode') ?? false;
      language = preferences.getString('language') ?? 'system';
    });
    _applySystemBars();
  }

  Future<void> _setLanguage(String value) async {
    setState(() => language = value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('language', value);
    final resolved =
        value == 'es' || value == 'en' ? value : deviceLanguageCode();
    unawaited(
      NotificationService.instance.scheduleReminders(languageCode: resolved),
    );
  }

  Future<void> _openStore(
    String packageName, {
    bool launchFirst = false,
  }) async {
    await _platform.invokeMethod<void>(
      launchFirst ? 'openAppOrStore' : 'openStore',
      {'package': packageName},
    );
  }

  Future<void> _toggleTheme() async {
    setState(() => lightMode = !lightMode);
    _applySystemBars();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('light_mode', lightMode);
  }

  void _applySystemBars() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: lightMode ? const Color(0xFFF8F3FB) : ink,
        statusBarIconBrightness: lightMode ? Brightness.dark : Brightness.light,
        systemNavigationBarIconBrightness: lightMode
            ? Brightness.dark
            : Brightness.light,
      ),
    );
  }

  Future<void> _requestNotificationPermissionOnce() async {
    const preferenceKey = 'notification_permission_prompted';
    final preferences = await SharedPreferences.getInstance();
    if (!(preferences.getBool(preferenceKey) ?? false)) {
      await NotificationService.instance.requestPermission();
      await preferences.setBool(preferenceKey, true);
    }
    await NotificationService.instance.scheduleReminders(
      languageCode: controller.languageCode,
    );
  }

  Future<void> _handleBack(BuildContext dialogContext) async {
    if (controller.page != AppPage.playing) {
      controller.back();
      return;
    }
    final leaveGame = await showDialog<bool>(
      context: dialogContext,
      builder: (alertContext) => AlertDialog(
        backgroundColor: Theme.of(alertContext).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(alertContext).colorScheme.secondary,
          size: 34,
        ),
        title: Text(
          dialogContext.tr('¿Salir de la partida?'),
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Text(
          dialogContext.tr('Perderás el progreso de la partida actual.'),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(alertContext).colorScheme.onSurfaceVariant,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(alertContext, false),
            child: Text(dialogContext.tr('SEGUIR JUGANDO')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(alertContext, true),
            child: Text(dialogContext.tr('SALIR')),
          ),
        ],
      ),
    );
    if (leaveGame == true && mounted) controller.back();
  }

  @override
  void dispose() {
    controller.removeListener(_refresh);
    controller.dispose();
    AppAudio.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final selectedLocale = switch (language) {
      'es' => const Locale('es'),
      'en' => const Locale('en'),
      _ => null,
    };
    controller.languageCode =
        selectedLocale?.languageCode ?? deviceLanguageCode();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => context.tr('Verdad o Reto'),
      locale: selectedLocale,
      supportedLocales: supportedAppLocales,
      localeResolutionCallback: (deviceLocale, _) =>
          resolveAppLocale(deviceLocale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: lightMode ? ThemeMode.light : ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF9B87F5),
          onPrimary: Colors.white,
          secondary: Color(0xFFE45B60),
          onSecondary: Colors.white,
          tertiary: gold,
          onTertiary: ink,
          surface: Color(0xFF211A27),
          onSurface: Color(0xFFF7F2F8),
          onSurfaceVariant: Color(0xFFBDB4C1),
          outline: Color(0xFF443B49),
        ),
        fontFamily: 'DMSans',
        dividerColor: Colors.white.withValues(alpha: .08),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.white.withValues(alpha: .10)),
        ),
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9F6FC),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6750C8),
          onPrimary: Colors.white,
          secondary: Color(0xFFD94F55),
          onSecondary: Colors.white,
          tertiary: Color(0xFF946200),
          onTertiary: Colors.white,
          surface: Color(0xFFFFFBFF),
          onSurface: Color(0xFF24182D),
          onSurfaceVariant: Color(0xFF685C70),
          outline: Color(0xFFD4CADB),
        ),
        fontFamily: 'DMSans',
        dividerColor: const Color(0xFFD4CADB).withValues(alpha: .55),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(
            color: const Color(0xFFD4CADB).withValues(alpha: .65),
          ),
        ),
      ),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(controller.textScale),
            disableAnimations:
                media.disableAnimations || !controller.animationsEnabled,
          ),
          child: child!,
        );
      },
      home: Builder(
        builder: (homeContext) => PopScope(
          canPop: controller.page == AppPage.welcome,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _handleBack(homeContext);
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: AppBackground(
              child: AnimatedSwitcher(
              duration: _duration(context, 180),
              reverseDuration: _duration(context, 100),
              switchInCurve: snappy,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween(begin: .97, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
              child: switch (controller.page) {
                AppPage.consent => ConsentScreen(
                  key: const ValueKey('consent'),
                  controller: controller,
                ),
                AppPage.welcome => WelcomeScreen(
                  key: const ValueKey('welcome'),
                  controller: controller,
                  lightMode: lightMode,
                  onToggleTheme: _toggleTheme,
                ),
                AppPage.players => PlayersScreen(
                  key: const ValueKey('players'),
                  controller: controller,
                ),
                AppPage.modeSetup => ModeSetupScreen(
                  key: const ValueKey('modeSetup'),
                  controller: controller,
                ),
                AppPage.intensitySetup => IntensitySetupScreen(
                  key: const ValueKey('intensitySetup'),
                  controller: controller,
                ),
                AppPage.playing => GameScreen(
                  key: const ValueKey('playing'),
                  controller: controller,
                ),
                AppPage.summary => SummaryScreen(
                  key: const ValueKey('summary'),
                  controller: controller,
                ),
                AppPage.settings => SettingsScreen(
                  key: const ValueKey('settings'),
                  controller: controller,
                  language: language,
                  onLanguageChanged: _setLanguage,
                  onRateApp: () => _openStore('nuviapps.co.verdadoreto'),
                  onOpenBomb: () =>
                      _openStore('nuviapps.co.labomba', launchFirst: true),
                  onOpenImpostor: () =>
                      _openStore('nuviapptest.co.impostor', launchFirst: true),
                ),
              },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Duration _duration(BuildContext context, int milliseconds) =>
    MediaQuery.disableAnimationsOf(context)
    ? Duration.zero
    : Duration(milliseconds: milliseconds);

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    return ColoredBox(
      color: light ? const Color(0xFFFAF8FC) : const Color(0xFF110D16),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(child: child),
      ),
    );
  }
}

bool _isLight(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light;

Color _secondaryText(BuildContext context) =>
    Theme.of(context).colorScheme.onSurfaceVariant;

Color _softSurface(BuildContext context, {double darkAlpha = .04}) =>
    _isLight(context)
    ? Colors.white
    : Colors.white.withValues(alpha: darkAlpha);

Color _softOutline(BuildContext context, {double darkAlpha = .10}) =>
    _isLight(context)
    ? Theme.of(context).colorScheme.outline.withValues(alpha: .42)
    : Colors.white.withValues(alpha: darkAlpha);

Color _accentColor(BuildContext context, Color color) {
  final scheme = Theme.of(context).colorScheme;
  if (!_isLight(context)) {
    if (color == coral) return scheme.secondary;
    if (color == purple) return scheme.primary;
    if (color == gold) return scheme.onSurfaceVariant;
    if (color == mist) return scheme.onSurface;
    return color;
  }
  if (color == coral) return scheme.secondary;
  if (color == purple) return scheme.primary;
  if (color == gold) return scheme.tertiary;
  if (color == mist) return scheme.primary;
  return color;
}

TextStyle _sectionStyle(BuildContext context) => TextStyle(
  color: _secondaryText(context),
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.7,
);

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({required this.controller, super.key});
  final GameController controller;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool adult = false;
  bool consent = false;

  @override
  Widget build(BuildContext context) => FixedBottomActionLayout(
    contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
    action: PrimaryButton(
      label: 'ACEPTAR Y CONTINUAR',
      icon: Icons.check_rounded,
      onTap: adult && consent ? widget.controller.acceptConsent : null,
    ),
    children: [
      Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _accentColor(context, gold).withValues(alpha: .12),
            shape: BoxShape.circle,
            border: Border.all(
              color: _accentColor(context, gold).withValues(alpha: .22),
            ),
          ),
          child: Icon(
            Icons.shield_outlined,
            color: _accentColor(context, gold),
            size: 30,
          ),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        context.tr('Antes de jugar'),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: -.8,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        context.tr('La diversión siempre termina donde empieza un límite.'),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _secondaryText(context),
          fontSize: 15,
          height: 1.45,
        ),
      ),
      const SizedBox(height: 28),
      const InfoCard(
        icon: Icons.pan_tool_alt_outlined,
        title: 'Cualquiera puede decir que no',
        subtitle: 'Se puede cambiar cualquier tarjeta sin penalización.',
      ),
      const InfoCard(
        icon: Icons.lock_outline_rounded,
        title: 'Privado y sin conexión',
        subtitle: 'No grabamos respuestas ni enviamos datos personales.',
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: _softSurface(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _softOutline(context)),
        ),
        child: Column(
          children: [
            CheckboxListTile(
              value: adult,
              onChanged: (value) => setState(() => adult = value ?? false),
              title: Text(
                context.tr('Todas las personas tienen 18 años o más'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            Divider(height: 1, color: _softOutline(context)),
            CheckboxListTile(
              value: consent,
              onChanged: (value) => setState(() => consent = value ?? false),
              title: Text(
                context.tr('Entendemos que el consentimiento puede retirarse'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    ],
  );
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _softSurface(context),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _softOutline(context)),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _accentColor(context, purple).withValues(alpha: .11),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _accentColor(context, purple), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(title),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr(subtitle),
                style: TextStyle(
                  color: _secondaryText(context),
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    required this.controller,
    required this.lightMode,
    required this.onToggleTheme,
    super.key,
  });
  final GameController controller;
  final bool lightMode;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controlStyle = IconButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      minimumSize: const Size(42, 42),
      shape: CircleBorder(side: BorderSide(color: _softOutline(context))),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 16, 26, 28),
      child: Column(
        children: [
          Row(
            children: [
              Pressable(
                onTap: () => showRewardsAndPacksSheet(context, controller),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: _softOutline(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '⚡ ${controller.sparks}',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: _secondaryText(context),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        context.tr(controller.rankTitle),
                        style: TextStyle(
                          color: _secondaryText(context),
                          fontWeight: FontWeight.w500,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                style: controlStyle,
                onPressed: () {
                  AppAudio.play(AppSound.toggle);
                  onToggleTheme();
                },
                tooltip: lightMode
                    ? context.tr('Activar modo oscuro')
                    : context.tr('Activar modo claro'),
                icon: Icon(
                  lightMode
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  size: 19,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: controlStyle,
                onPressed: () {
                  AppAudio.play(AppSound.tap);
                  controller.showSettings();
                },
                tooltip: context.tr('Configuración'),
                icon: const Icon(Icons.tune_rounded, size: 19),
              ),
            ],
          ),
          const Spacer(flex: 2),
          _welcomeEntrance(
            context,
            delay: 20,
            child: Center(
              child: SizedBox(
                width: 128,
                height: 128,
                child: Image.asset(
                  'assets/branding/verdad-o-reto-logo-transparent.png',
                  key: const ValueKey('brand-logo'),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _welcomeEntrance(
            context,
            delay: 70,
            child: Column(
              children: [
                Text(
                  context.tr('Verdad o Reto'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 40,
                    height: 1.0,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: coral,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 22,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: purple,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr(
                    'Las mejores historias empiezan\ncon una pregunta.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 3),
          _welcomeEntrance(
            context,
            delay: 120,
            child: Column(
              children: [
                PrimaryButton(
                  label: 'EMPEZAR A JUGAR',
                  icon: Icons.play_arrow_rounded,
                  onTap: controller.showPlayers,
                ),
                if (controller.hasSavedSession &&
                    controller.activePlayers.length >= 2) ...[
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'PARTIDA RÁPIDA',
                    color: Theme.of(context).colorScheme.primary,
                    icon: Icons.bolt_rounded,
                    onTap: controller.startQuickGame,
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  context.tr('2–12 jugadores  ·  Sin conexión'),
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _welcomeEntrance(
  BuildContext context, {
  required Widget child,
  required int delay,
}) {
  if (MediaQuery.disableAnimationsOf(context)) return child;
  return Animate(
    delay: Duration(milliseconds: delay),
    effects: const [
      FadeEffect(duration: Duration(milliseconds: 220)),
      ScaleEffect(
        begin: Offset(.97, .97),
        end: Offset(1, 1),
        duration: Duration(milliseconds: 220),
        curve: snappy,
      ),
    ],
    child: child,
  );
}

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({required this.controller, super.key});
  final GameController controller;

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  final textController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void dispose() {
    textController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  void addPlayer() {
    if (widget.controller.addPlayer(textController.text)) {
      textController.clear();
      focusNode.requestFocus();
    }
  }

  Future<void> editPlayer(String player) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _EditPlayerDialog(initialValue: player),
    );
    if (value != null) widget.controller.editPlayer(player, value);
  }

  Future<void> savePreset() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => const _EditPlayerDialog(
        initialValue: '',
        titleKey: 'Guardar grupo',
        hintKey: 'Nombre del grupo',
      ),
    );
    if (value != null) widget.controller.savePlayerPreset(value);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppHeader(
          title: context.tr('¿Quién juega?'),
          subtitle: context.tr('Añade al menos 2 personas'),
          onBack: widget.controller.back,
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
                maxLength: 18,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => addPlayer(),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: context.tr('Nombre del jugador'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: _softSurface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: _softOutline(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(color: _softOutline(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.onSurface,
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Pressable(
              onTap: addPlayer,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 24,
                  color: Theme.of(context).colorScheme.surface,
                ),
              ),
            ),
          ],
        ),
        if (widget.controller.activePlayers.length >= 2 ||
            widget.controller.playerPresets.isNotEmpty) ...[
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (widget.controller.activePlayers.length >= 2)
                  ActionChip(
                    avatar: const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: Text(context.tr('Guardar grupo')),
                    onPressed: savePreset,
                  ),
                for (final name in widget.controller.playerPresets.keys) ...[
                  const SizedBox(width: 8),
                  InputChip(
                    label: Text(name),
                    onPressed: () {
                      AppAudio.play(AppSound.select);
                      widget.controller.applyPlayerPreset(name);
                    },
                    onDeleted: () => widget.controller.deletePlayerPreset(name),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          '${context.tr('JUGADORES')}  ${widget.controller.players.length}/12',
          style: _sectionStyle(context),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: widget.controller.players.length,
            onReorderItem: widget.controller.reorderPlayer,
            proxyDecorator: (child, index, animation) {
              final lift = CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              );
              return AnimatedBuilder(
                animation: lift,
                child: child,
                builder: (_, child) => Transform.scale(
                  scale: MediaQuery.disableAnimationsOf(context)
                      ? 1
                      : 1 + (.018 * lift.value),
                  child: Material(
                    type: MaterialType.transparency,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: ink.withValues(alpha: .18),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  ),
                ),
              );
            },
            itemBuilder: (_, index) {
              final player = widget.controller.players[index];
              final active = !widget.controller.inactivePlayers.contains(
                player,
              );
              return AnimatedOpacity(
                key: ValueKey(player),
                duration: _duration(context, 160),
                opacity: active ? 1 : .52,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                  decoration: BoxDecoration(
                    color: _softSurface(context, darkAlpha: active ? .055 : .025),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _softOutline(context)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _accentColor(
                            context,
                            purple,
                          ).withValues(alpha: .14),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          player[0].toUpperCase(),
                          style: TextStyle(
                            color: _accentColor(context, purple),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.2,
                          ),
                        ),
                      ),
                    Switch.adaptive(
                      value: active,
                      activeTrackColor: _accentColor(context, purple),
                      activeThumbColor: Colors.white,
                      onChanged: (value) {
                        AppAudio.play(AppSound.toggle);
                        widget.controller.togglePlayer(player, value);
                      },
                    ),
                    IconButton(
                      onPressed: () {
                        AppAudio.play(AppSound.tap);
                        editPlayer(player);
                      },
                      tooltip: '${context.tr('Editar jugador')}: $player',
                      icon: Icon(
                        Icons.edit_outlined,
                        color: _secondaryText(context),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        AppAudio.play(AppSound.back);
                        widget.controller.removePlayer(player);
                      },
                      tooltip:
                          '${context.isEnglish ? 'Remove' : 'Eliminar'} $player',
                      icon: Icon(
                        Icons.close_rounded,
                        color: _secondaryText(context),
                      ),
                    ),
                      ReorderableDragStartListener(
                        index: index,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: _secondaryText(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.controller.activePlayers.length < 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Builder(
              builder: (context) {
                final missing = 2 - widget.controller.activePlayers.length;
                final message = context.isEnglish
                    ? (missing == 1
                        ? 'You need 1 more active player'
                        : 'You need $missing more active players')
                    : (missing == 1
                        ? 'Necesitas 1 jugador activo más'
                        : 'Necesitas $missing jugadores activos más');
                return Text(
                  message,
                  style: TextStyle(color: _accentColor(context, gold)),
                );
              },
            ),
          ),
        PrimaryButton(
          label: 'CONTINUAR',
          icon: Icons.arrow_forward_rounded,
          onTap: widget.controller.activePlayers.length >= 2
              ? () {
                  FocusScope.of(context).unfocus();
                  widget.controller.showSetup();
                }
              : null,
        ),
        const SizedBox(height: 18),
      ],
    ),
  );
}

class _EditPlayerDialog extends StatefulWidget {
  const _EditPlayerDialog({
    required this.initialValue,
    this.titleKey = 'Editar jugador',
    this.hintKey,
  });

  final String initialValue;
  final String titleKey;
  final String? hintKey;

  @override
  State<_EditPlayerDialog> createState() => _EditPlayerDialogState();
}

class _EditPlayerDialogState extends State<_EditPlayerDialog> {
  late final TextEditingController editor;

  @override
  void initState() {
    super.initState();
    editor = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    editor.dispose();
    super.dispose();
  }

  void save() => Navigator.pop(context, editor.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr(widget.titleKey)),
    content: TextField(
      controller: editor,
      autofocus: true,
      maxLength: 18,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => save(),
      decoration: widget.hintKey == null
          ? null
          : InputDecoration(hintText: context.tr(widget.hintKey!)),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Cancelar')),
      ),
      FilledButton(onPressed: save, child: Text(context.tr('Guardar'))),
    ],
  );
}

class ModeSetupScreen extends StatelessWidget {
  const ModeSetupScreen({required this.controller, super.key});
  final GameController controller;

  @override
  Widget build(BuildContext context) => FixedBottomActionLayout(
    contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
    action: PrimaryButton(
      label: controller.mode == GameMode.familia
          ? '¡QUE EMPIECE EL JUEGO!'
          : 'CONTINUAR',
      icon: controller.mode == GameMode.familia
          ? Icons.play_arrow_rounded
          : Icons.arrow_forward_rounded,
      onTap: controller.mode == GameMode.familia
          ? controller.startGame
          : controller.showIntensitySetup,
    ),
    children: [
      AppHeader(
        title: context.tr('Modo de juego'),
        subtitle: context.tr('Elige el ambiente de la partida'),
        onBack: controller.back,
      ),
      Text(context.tr('MODO DE JUEGO'), style: _sectionStyle(context)),
      const SizedBox(height: 6),
      ...GameMode.values.map(
        (mode) => SelectCard(
          emoji: mode.emoji,
          title: mode.title,
          subtitle: mode.subtitle,
          selected: controller.mode == mode,
          onTap: () => controller.selectMode(mode),
        ),
      ),
    ],
  );
}

class IntensitySetupScreen extends StatelessWidget {
  const IntensitySetupScreen({required this.controller, super.key});
  final GameController controller;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          children: [
            AppHeader(
              title: context.tr('Intensidad'),
              subtitle:
                  '${context.isEnglish ? 'Mode' : 'Modo'} ${context.tr(controller.mode.title)}',
              onBack: controller.back,
            ),
            const SizedBox(height: 16),
            Text(context.tr('INTENSIDAD'), style: _sectionStyle(context)),
            const SizedBox(height: 6),
            ...Intensity.values.map(
              (intensity) => SelectCard(
                emoji: intensity.emoji,
                title: intensity.title,
                subtitle: intensity.subtitle,
                selected: controller.intensity == intensity,
                onTap: () => controller.selectIntensity(intensity),
              ),
            ),
            const SizedBox(height: 16),
            SettingSwitch(
              icon: Icons.layers_outlined,
              title: 'Mezclar intensidades',
              subtitle: 'Combina contenido suave, atrevido y extremo',
              value: controller.mixIntensities,
              onChanged: controller.setMixIntensities,
            ),
            const SizedBox(height: 10),
            Material(
              color: _softSurface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: _softOutline(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SwitchListTile.adaptive(
                value: controller.randomizeTurns,
                onChanged: (value) {
                  AppAudio.play(AppSound.toggle);
                  controller.setRandomizeTurns(value);
                },
                activeTrackColor: _accentColor(context, purple),
                activeThumbColor: Colors.white,
                title: Text(
                  context.tr('Turnos aleatorios'),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  controller.randomizeTurns
                      ? context.tr('El siguiente jugador se elegirá al azar')
                      : context.tr('Los jugadores participarán en orden'),
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 13,
                  ),
                ),
                secondary: Icon(
                  controller.randomizeTurns
                      ? Icons.shuffle_rounded
                      : Icons.format_list_numbered_rounded,
                  color: controller.randomizeTurns
                      ? _accentColor(context, purple)
                      : _secondaryText(context),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Pressable(
                    onTap: () => showRewardsAndPacksSheet(context, controller),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _softSurface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _softOutline(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_outlined,
                            size: 18,
                            color: _accentColor(context, purple),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${context.tr('Mazos y logros')} (${controller.activeBonusPacks.length})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Pressable(
                    onTap: () => showCustomCardsSheet(context, controller),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: _softSurface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _softOutline(context)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 19,
                            color: _accentColor(context, coral),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${context.tr('Mis tarjetas')} (${controller.customCards.length})',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                color: _softSurface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: _softOutline(context)),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: Text(
                  context.tr('Límites de contenido'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  context.tr('Desactiva lo que el grupo prefiera evitar'),
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 13,
                  ),
                ),
              children: [
                ContentFilterTile(
                  label: 'Contacto físico',
                  value: controller.contactAllowed,
                  onChanged: (v) => controller.setContentFilter('contact', v),
                ),
                ContentFilterTile(
                  label: 'Contenido sexual 18+',
                  value: controller.adultAllowed,
                  onChanged: (v) => controller.setContentFilter('adult', v),
                ),
                ContentFilterTile(
                  label: 'Alcohol',
                  value: controller.alcoholAllowed,
                  onChanged: (v) => controller.setContentFilter('alcohol', v),
                ),
                ContentFilterTile(
                  label: 'Mensajes y redes sociales',
                  value: controller.socialAllowed,
                  onChanged: (v) => controller.setContentFilter('social', v),
                ),
                ContentFilterTile(
                  label: 'Preguntas personales',
                  value: controller.personalAllowed,
                  onChanged: (v) => controller.setContentFilter('personal', v),
                ),
                ContentFilterTile(
                  label: 'Acciones en público',
                  value: controller.publicAllowed,
                  onChanged: (v) => controller.setContentFilter('public', v),
                ),
              ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      BottomActionBar(
        child: PrimaryButton(
          label: '¡QUE EMPIECE EL JUEGO!',
          icon: Icons.play_arrow_rounded,
          onTap: controller.startGame,
        ),
      ),
    ],
  );
}

class FixedBottomActionLayout extends StatelessWidget {
  const FixedBottomActionLayout({
    required this.children,
    required this.action,
    required this.contentPadding,
    super.key,
  });

  final List<Widget> children;
  final Widget action;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView(padding: contentPadding, children: children),
      ),
      BottomActionBar(child: action),
    ],
  );
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(
        alpha: _isLight(context) ? .92 : .85,
      ),
      border: Border(top: BorderSide(color: _softOutline(context), width: .8)),
    ),
    child: child,
  );
}

class SettingSwitch extends StatelessWidget {
  const SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final activeColor = _accentColor(context, purple);
    return Material(
      color: _softSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _softOutline(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SwitchListTile.adaptive(
        value: value,
        activeTrackColor: activeColor,
        activeThumbColor: Colors.white,
        onChanged: (newValue) {
          AppAudio.play(AppSound.toggle);
          onChanged(newValue);
        },
        secondary: Icon(
          icon,
          color: value ? activeColor : _secondaryText(context),
        ),
        title: Text(
          context.tr(title),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          context.tr(subtitle),
          style: TextStyle(color: _secondaryText(context), fontSize: 13),
        ),
      ),
    );
  }
}

class ContentFilterTile extends StatelessWidget {
  const ContentFilterTile({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile.adaptive(
    dense: true,
    value: value,
    activeTrackColor: _accentColor(context, purple),
    activeThumbColor: Colors.white,
    onChanged: (newValue) {
      AppAudio.play(AppSound.toggle);
      onChanged(newValue);
    },
    title: Text(context.tr(label)),
  );
}

class SelectCard extends StatelessWidget {
  const SelectCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeColor = _accentColor(context, purple);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Pressable(
        onTap: onTap,
        sound: AppSound.select,
        child: AnimatedContainer(
          duration: _duration(context, 180),
          curve: snappy,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: selected
                ? _softSurface(context, darkAlpha: .08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.onSurface.withValues(alpha: .42)
                  : _softOutline(context),
              width: selected ? 1.3 : .9,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: _duration(context, 160),
                width: 3.5,
                height: selected ? 26 : 12,
                decoration: BoxDecoration(
                  color: selected ? activeColor : _softOutline(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 14),
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(title),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(subtitle),
                      style: TextStyle(
                        color: _secondaryText(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: activeColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({required this.controller, super.key});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final card = controller.currentCard;
    return Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 14, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _softSurface(context),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: _softOutline(context)),
                          ),
                          child: Text(
                            '${context.isEnglish ? 'ROUND' : 'RONDA'} ${controller.turn}${controller.maxRounds > 0 ? ' / ${controller.maxRounds}' : ''}',
                            style: _sectionStyle(context),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        AppAudio.play(AppSound.toggle);
                        controller.togglePause();
                      },
                      tooltip: context.tr(
                        controller.paused ? 'Reanudar' : 'Pausar',
                      ),
                      icon: Icon(
                        controller.paused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: _secondaryText(context),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        AppAudio.play(AppSound.back);
                        controller.finishGame();
                      },
                      child: Text(
                        context.tr('Terminar'),
                        style: TextStyle(color: _secondaryText(context)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerTurnIdentity(
                          player: controller.currentPlayer,
                          turn: controller.turn,
                        ),
                        const SizedBox(height: 28),
                        if (card == null)
                          ChooseCardType(
                            onTruth: () =>
                                controller.chooseCard(CardType.verdad),
                            onDare: () => controller.chooseCard(CardType.reto),
                            onRandom: controller.chooseRandomCard,
                          )
                        else
                          ChallengeCard(
                            card: card,
                            isFavorite: controller.isFavorite(card),
                            onToggleFavorite: () =>
                                controller.toggleFavorite(card),
                          ),
                        const SizedBox(height: 18),
                        if (card != null)
                          SizedBox(
                            height: 60,
                            child: PrimaryButton(
                              label: controller.reachedRoundLimit
                                  ? 'VER RESUMEN'
                                  : 'SIGUIENTE TURNO',
                              icon: Icons.arrow_forward_rounded,
                              onTap: controller.nextTurn,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (controller.paused)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .96),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pause_circle_outline_rounded,
                          size: 64,
                          color: _accentColor(context, gold),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr('Partida en pausa'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            FilterChip(
                              selected: controller.soundEnabled,
                              avatar: Icon(
                                controller.soundEnabled
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                size: 17,
                              ),
                              label: Text(context.tr('Sonido')),
                              onSelected: (v) =>
                                  controller.setPreference('sound', v),
                            ),
                            FilterChip(
                              selected: controller.hapticsEnabled,
                              avatar: const Icon(
                                Icons.vibration_rounded,
                                size: 17,
                              ),
                              label: Text(context.tr('Vibración')),
                              onSelected: (v) =>
                                  controller.setPreference('haptics', v),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        PrimaryButton(
                          label: 'CONTINUAR',
                          icon: Icons.play_arrow_rounded,
                          onTap: controller.togglePause,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (controller.adBreakVisible)
            Positioned.fill(
              child: ColoredBox(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .96),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('PUBLICIDAD'),
                          style: _sectionStyle(context),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('La partida continúa en un momento'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!controller.paused && !controller.adBreakVisible)
            Positioned(
              right: 22,
              bottom: 18,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (card != null && controller.previousCard != null) ...[
                    FloatingGameAction(
                      tooltip: context.tr('Tarjeta anterior'),
                      icon: Icons.undo_rounded,
                      onTap: controller.restorePreviousCard,
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (card != null) ...[
                    FloatingGameAction(
                      tooltip: context.tr('Otra tarjeta'),
                      icon: Icons.refresh_rounded,
                      onTap: controller.anotherCard,
                    ),
                    const SizedBox(width: 10),
                  ],
                  FloatingGameAction(
                    tooltip: context.tr('Saltar jugador'),
                    icon: Icons.skip_next_rounded,
                    onTap: controller.skipPlayer,
                  ),
                ],
              ),
            ),
        ],
      );
  }
}

class ChooseCardType extends StatelessWidget {
  const ChooseCardType({
    required this.onTruth,
    required this.onDare,
    required this.onRandom,
    super.key,
  });
  final VoidCallback onTruth;
  final VoidCallback onDare;
  final VoidCallback onRandom;

  @override
  Widget build(BuildContext context) {
    Widget choices = Row(
      children: [
        Expanded(
          child: GameChoiceButton(
            label: context.tr('VERDAD'),
            subtitle: context.tr('Una pregunta'),
            icon: Icons.chat_bubble_rounded,
            colors: truthCardColors,
            onTap: onTruth,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GameChoiceButton(
            label: context.tr('RETO'),
            subtitle: context.tr('Atrévete'),
            icon: Icons.bolt_rounded,
            colors: dareCardColors,
            onTap: onDare,
          ),
        ),
      ],
    );
    if (!MediaQuery.disableAnimationsOf(context)) {
      choices = Animate(
        effects: const [
          FadeEffect(duration: Duration(milliseconds: 180)),
          ScaleEffect(
            begin: Offset(.97, .97),
            end: Offset(1, 1),
            duration: Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
          ),
        ],
        child: choices,
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          context.tr('ELIGE UNA OPCIÓN'),
          style: _sectionStyle(context),
        ),
        const SizedBox(height: 18),
        choices,
        const SizedBox(height: 18),
        Pressable(
          onTap: onRandom,
          sound: AppSound.select,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _softOutline(context)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎲', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  context.tr('Al azar'),
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    required this.card,
    required this.isFavorite,
    required this.onToggleFavorite,
    super.key,
  });
  final GameCard card;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final isTruth = card.type == CardType.verdad;
    final accent = isTruth ? coral : purple;
    final light = _isLight(context);
    final scheme = Theme.of(context).colorScheme;
    final timerSeconds = detectCardTimerSeconds(card.text);
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 28),
      decoration: BoxDecoration(
        color: light ? Colors.white : const Color(0xFF1A1422),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: accent.withValues(alpha: light ? .48 : .52),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                context.tr(card.type.title),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                  color: accent,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  AppAudio.play(AppSound.tap);
                  onToggleFavorite();
                },
                tooltip: context.tr(
                  isFavorite ? 'Quitar de favoritas' : 'Guardar en favoritas',
                ),
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? coral : _secondaryText(context),
                  size: 21,
                ),
              ),
            ],
          ),
          Divider(height: 1, color: _softOutline(context)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 26),
            child: Text(
              card.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 23.5,
                height: 1.4,
                fontWeight: FontWeight.w700,
                letterSpacing: -.45,
              ),
            ),
          ),
          if (timerSeconds != null)
            CardTimerPill(
              key: ValueKey('timer-${card.text}'),
              seconds: timerSeconds,
              accentColor: accent,
            )
          else
            const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class PlayerTurnIdentity extends StatelessWidget {
  const PlayerTurnIdentity({
    required this.player,
    required this.turn,
    super.key,
  });

  final String player;
  final int turn;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        _faceForTurn(player, turn),
        semanticsLabel: context.tr('Carita del jugador'),
        style: const TextStyle(fontSize: 30, height: 1),
      ),
      const SizedBox(width: 12),
      Flexible(
        child: Text(
          player,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 34,
            height: 1.05,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.1,
          ),
        ),
      ),
    ],
  );
}

class FloatingGameAction extends StatelessWidget {
  const FloatingGameAction({
    required this.tooltip,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.tr(tooltip),
    child: Pressable(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: _softOutline(context)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}

String _faceForTurn(String player, int turn) {
  const faces = ['😄', '😎', '🤩', '😂', '😜', '🥳', '🤓', '🤠', '🤪', '😊'];
  final seed = Object.hash(player, turn) & 0x7fffffff;
  return faces[seed % faces.length];
}

class GameChoiceButton extends StatelessWidget {
  const GameChoiceButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.onTap,
    super.key,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = colors.first;
    final light = _isLight(context);
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 158,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: light
              ? Colors.white
              : accent.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: accent.withValues(alpha: light ? .48 : .45),
            width: 1.4,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: light ? .12 : .22),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 19),
                ),
                Icon(
                  Icons.north_east_rounded,
                  size: 16,
                  color: accent.withValues(alpha: .65),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({required this.controller, super.key});
  final GameController controller;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late final ConfettiController confettiController;
  bool celebrationStarted = false;

  @override
  void initState() {
    super.initState();
    confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!celebrationStarted) {
      celebrationStarted = true;
      if (!MediaQuery.disableAnimationsOf(context)) confettiController.play();
    }
  }

  @override
  void dispose() {
    confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final awards = c.playerAwards;
    final newBadges = appAchievements
        .where((a) => c.newlyUnlockedAchievements.contains(a.id))
        .toList();
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: _accentColor(context, gold).withValues(alpha: .12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _accentColor(context, gold).withValues(alpha: .22),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text('🏆', style: TextStyle(fontSize: 40)),
                ),
                const SizedBox(height: 18),
                Text(
                  context.tr('¡Qué partida!'),
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -.9,
                  ),
                ),
                Text(
                  context.isEnglish
                      ? 'You completed ${c.truthsCompleted + c.daresCompleted} turns'
                      : 'Habéis completado ${c.truthsCompleted + c.daresCompleted} turnos',
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 16,
                  ),
                ),
                if (c.sessionSparksEarned > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _accentColor(context, purple).withValues(
                        alpha: .14,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '+${c.sessionSparksEarned} ⚡ ${context.tr('Chispas')}',
                      style: TextStyle(
                        color: _accentColor(context, purple),
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        value: '${c.truthsCompleted}',
                        label: 'Verdades',
                        color: coral,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        value: '${c.daresCompleted}',
                        label: 'Retos',
                        color: purple,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        value: '${c.skippedCards}',
                        label: 'Cambios',
                        color: gold,
                      ),
                    ),
                  ],
                ),
                if (awards.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    context.tr('PREMIOS DE LA PARTIDA'),
                    style: _sectionStyle(context),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      for (final award in awards)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _softSurface(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: _softOutline(context)),
                          ),
                          child: Text(
                            '${award.emoji} ${context.tr(award.title)}: ${award.player} (${award.detail})',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if (newBadges.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    context.tr('LOGROS DESBLOQUEADOS'),
                    style: _sectionStyle(context),
                  ),
                  const SizedBox(height: 8),
                  for (final badge in newBadges)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${badge.emoji} ${context.tr(badge.title)} (+${badge.rewardSparks} ⚡)',
                        style: TextStyle(
                          color: _accentColor(context, gold),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'JUGAR OTRA VEZ',
                  icon: Icons.refresh_rounded,
                  onTap: c.playAgain,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: 'VOLVER AL INICIO',
                  color: Theme.of(context).colorScheme.primary,
                  icon: Icons.home_rounded,
                  onTap: c.goHome,
                ),
              ],
            ),
          ),
        ),
      IgnorePointer(
        child: ConfettiWidget(
          confettiController: confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: .035,
          numberOfParticles: 16,
          minBlastForce: 7,
          maxBlastForce: 16,
          gravity: .22,
          minimumSize: const Size(5, 5),
          maximumSize: const Size(11, 11),
          colors: const [coral, purple, gold, Colors.white],
          pauseEmissionOnLowFrameRate: true,
        ),
      ),
    ],
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    required this.value,
    required this.label,
    required this.color,
    super.key,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _accentColor(context, color);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _softSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _softOutline(context)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -.8,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.tr(label),
            style: TextStyle(
              color: _secondaryText(context),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.controller,
    required this.language,
    required this.onLanguageChanged,
    required this.onRateApp,
    required this.onOpenBomb,
    required this.onOpenImpostor,
    super.key,
  });
  final GameController controller;
  final String language;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onRateApp;
  final VoidCallback onOpenBomb;
  final VoidCallback onOpenImpostor;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
    children: [
      AppHeader(
        title: context.tr('Configuración'),
        subtitle: context.tr('Adapta el juego a tu grupo'),
        onBack: controller.closeSettings,
      ),
      Text(context.tr('IDIOMA'), style: _sectionStyle(context)),
      const SizedBox(height: 8),
      Material(
        color: _softSurface(context),
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.language_rounded,
                  color: _accentColor(context, purple),
                ),
                title: Text(
                  context.tr('Idioma'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  context.tr('Idioma de los textos de la aplicación'),
                  style: TextStyle(color: _secondaryText(context)),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: language,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: _softSurface(context, darkAlpha: .08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'system',
                    child: Text(context.tr('Automático (dispositivo)')),
                  ),
                  DropdownMenuItem(
                    value: 'es',
                    child: Text(context.tr('Español')),
                  ),
                  DropdownMenuItem(
                    value: 'en',
                    child: Text(context.tr('Inglés')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) onLanguageChanged(value);
                },
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 24),
      Text(context.tr('PROGRESO Y CONTENIDO'), style: _sectionStyle(context)),
      const SizedBox(height: 8),
      StoreRecommendationTile(
        emoji: '⚡',
        title: '${context.tr('Mazos y logros')}  ·  ${controller.sparks} ⚡',
        subtitle: context.tr(
          'Desbloquea mazos con Chispas o vídeos bonificados',
        ),
        onTap: () => showRewardsAndPacksSheet(context, controller),
      ),
      const SizedBox(height: 10),
      StoreRecommendationTile(
        emoji: '✍️',
        title:
            '${context.tr('Mis tarjetas')} (${controller.customCards.length})',
        subtitle: context.tr('Crea verdades y retos propios para tu grupo'),
        onTap: () => showCustomCardsSheet(context, controller),
      ),
      const SizedBox(height: 10),
      StoreRecommendationTile(
        emoji: '❤️',
        title:
            '${context.tr('Favoritas')} (${controller.favoriteCards.length})',
        subtitle: context.tr('Tus preguntas y retos guardados'),
        onTap: () => showFavoritesSheet(context, controller),
      ),
      const SizedBox(height: 24),
      Text(context.tr('EXPERIENCIA'), style: _sectionStyle(context)),
      const SizedBox(height: 8),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(
          Icons.notification_add_outlined,
          color: _accentColor(context, gold),
        ),
        title: Text(context.tr('Probar notificación')),
        subtitle: Text(
          context.tr('Envía una notificación local ahora'),
          style: TextStyle(color: _secondaryText(context)),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: _secondaryText(context),
        ),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final sentMessage = context.tr('Notificación de prueba enviada');
          final permissionMessage = context.tr(
            'Activa el permiso de notificaciones para probarla',
          );
          final sent = await NotificationService.instance.showTestNotification(
            languageCode: controller.languageCode,
          );
          if (!context.mounted) return;
          messenger.showSnackBar(
            SnackBar(content: Text(sent ? sentMessage : permissionMessage)),
          );
        },
      ),
      const SizedBox(height: 10),
      SettingSwitch(
        icon: Icons.vibration_rounded,
        title: 'Vibración',
        subtitle: 'Respuesta suave al revelar tarjetas',
        value: controller.hapticsEnabled,
        onChanged: (v) => controller.setPreference('haptics', v),
      ),
      const SizedBox(height: 10),
      SettingSwitch(
        icon: Icons.volume_up_outlined,
        title: 'Sonido',
        subtitle: 'Sonido breve del sistema al revelar',
        value: controller.soundEnabled,
        onChanged: (v) => controller.setPreference('sound', v),
      ),
      const SizedBox(height: 10),
      SettingSwitch(
        icon: Icons.animation_rounded,
        title: 'Animaciones',
        subtitle: 'Transiciones breves y optimizadas',
        value: controller.animationsEnabled,
        onChanged: (v) => controller.setPreference('animations', v),
      ),
      const SizedBox(height: 22),
      Text(context.tr('TAMAÑO DEL TEXTO'), style: _sectionStyle(context)),
      Slider(
        value: controller.textScale,
        min: .9,
        max: 1.25,
        divisions: 7,
        label: '${(controller.textScale * 100).round()} %',
        onChanged: controller.setTextScale,
      ),
      const SizedBox(height: 12),
      Text(context.tr('DURACIÓN DE LA PARTIDA'), style: _sectionStyle(context)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final rounds in [10, 20, 30, 0])
            ChoiceChip(
              selected: controller.maxRounds == rounds,
              label: Text(
                rounds == 0
                    ? context.tr('Sin límite')
                    : context.isEnglish
                    ? '$rounds turns'
                    : '$rounds turnos',
              ),
              onSelected: (_) {
                AppAudio.play(AppSound.select);
                controller.setMaxRounds(rounds);
              },
            ),
        ],
      ),
      const SizedBox(height: 24),
      Text(context.tr('PRIVACIDAD E HISTORIAL'), style: _sectionStyle(context)),
      const SizedBox(height: 8),
      const InfoCard(
        icon: Icons.offline_bolt_outlined,
        title: 'Todo permanece en tu dispositivo',
        subtitle:
            'La app funciona sin conexión y no guarda respuestas, audio ni imágenes.',
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.history_rounded,
          color: _accentColor(context, purple),
        ),
        title: Text(
          context.isEnglish
              ? '${controller.historyCount} viewed cards'
              : '${controller.historyCount} tarjetas vistas',
        ),
        subtitle: Text(
          context.tr('Se priorizan tarjetas que aún no han aparecido'),
          style: TextStyle(color: _secondaryText(context)),
        ),
        trailing: TextButton(
          onPressed: controller.historyCount == 0
              ? null
              : () {
                  AppAudio.play(AppSound.back);
                  controller.resetHistory();
                },
          child: Text(context.tr('Reiniciar')),
        ),
      ),
      const SizedBox(height: 24),
      Text(context.tr('VALORACIÓN'), style: _sectionStyle(context)),
      const SizedBox(height: 8),
      StoreRecommendationTile(
        icon: Icons.star_rounded,
        title: context.tr('Valorar la aplicación'),
        subtitle: context.tr('Comparte tu opinión en Google Play'),
        onTap: onRateApp,
      ),
      const SizedBox(height: 24),
      Text(context.tr('MÁS JUEGOS'), style: _sectionStyle(context)),
      const SizedBox(height: 8),
      StoreRecommendationTile(
        emoji: '💣',
        title: context.tr('Jugar a La Bomba'),
        subtitle: context.tr('Responde antes de que explote'),
        onTap: onOpenBomb,
      ),
      const SizedBox(height: 10),
      StoreRecommendationTile(
        emoji: '🕵️',
        title: context.tr('Jugar a Impostor'),
        subtitle: context.tr('Descubre quién está fingiendo'),
        onTap: onOpenImpostor,
      ),
    ],
  );
}

class StoreRecommendationTile extends StatelessWidget {
  const StoreRecommendationTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.emoji,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData? icon;
  final String? emoji;

  @override
  Widget build(BuildContext context) => Material(
    color: _softSurface(context),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: _softOutline(context)),
    ),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      minTileHeight: 68,
      onTap: onTap,
      leading: SizedBox.square(
        dimension: 42,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _accentColor(context, purple).withValues(alpha: .13),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: emoji != null
                ? Text(emoji!, style: const TextStyle(fontSize: 23))
                : Icon(icon, color: _accentColor(context, gold)),
          ),
        ),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: _secondaryText(context)),
      ),
      trailing: Icon(Icons.open_in_new_rounded, color: _secondaryText(context)),
    ),
  );
}

class AppHeader extends StatelessWidget {
  const AppHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
    super.key,
  });
  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Row(
      children: [
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            minimumSize: const Size(42, 42),
            shape: CircleBorder(side: BorderSide(color: _softOutline(context))),
          ),
          onPressed: () {
            AppAudio.play(AppSound.back);
            onBack();
          },
          tooltip: context.tr('Volver'),
          icon: const Icon(Icons.arrow_back_rounded, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(title),
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.tr(subtitle),
                style: TextStyle(
                  color: _secondaryText(context),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.sound = AppSound.confirm,
    this.foregroundColor,
    super.key,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final AppSound sound;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final light = _isLight(context);
    final background = light ? ink : mist;
    final foreground = foregroundColor ?? (light ? Colors.white : ink);
    return Pressable(
      onTap: onTap,
      sound: sound,
      child: AnimatedOpacity(
        duration: _duration(context, 160),
        opacity: onTap == null ? .32 : 1,
        child: Container(
          height: 56,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  context.tr(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: foreground, size: 17),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.sound = AppSound.tap,
    super.key,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final AppSound sound;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      sound: sound,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.transparent,
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .22),
            width: 1.1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: Theme.of(context).colorScheme.onSurface,
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              context.tr(label),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                letterSpacing: .5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    required this.onTap,
    this.sound = AppSound.tap,
    super.key,
  });
  final Widget child;
  final VoidCallback? onTap;
  final AppSound sound;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool pressed = false;

  void setPressed(bool value) {
    if (widget.onTap != null && mounted) setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: widget.onTap != null,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap == null
          ? null
          : () {
              AppAudio.play(widget.sound);
              widget.onTap!();
            },
      onTapDown: (_) => setPressed(true),
      onTapUp: (_) => setPressed(false),
      onTapCancel: () => setPressed(false),
      child: AnimatedScale(
        scale: pressed ? .97 : 1,
        duration: _duration(context, pressed ? 100 : 140),
        curve: snappy,
        child: widget.child,
      ),
    ),
  );
}
