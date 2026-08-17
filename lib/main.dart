import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'audio_feedback.dart';
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

const ink = Color(0xFF190B2C);
const plum = Color(0xFF32134F);
const purple = Color(0xFF7547E8);
const coral = Color(0xFFFF5449);
const gold = Color(0xFFFFBE42);
const mist = Color(0xFFF8F5FF);
const snappy = Cubic(0.23, 1, 0.32, 1);

class TruthOrDareApp extends StatefulWidget {
  const TruthOrDareApp({super.key});

  @override
  State<TruthOrDareApp> createState() => _TruthOrDareAppState();
}

class _TruthOrDareAppState extends State<TruthOrDareApp> {
  final controller = GameController();
  bool lightMode = false;
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
    setState(() => lightMode = preferences.getBool('light_mode') ?? false);
    _applySystemBars();
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
    await NotificationService.instance.scheduleReminders();
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
    debugPaintBaselinesEnabled = false;
    debugPaintSizeEnabled = false;
    debugPaintLayerBordersEnabled = false;
    debugPaintPointersEnabled = false;
    debugRepaintRainbowEnabled = false;
    debugRepaintTextRainbowEnabled = false;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Verdad o Reto',
      themeMode: lightMode ? ThemeMode.light : ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: ink,
        colorScheme: const ColorScheme.dark(
          primary: purple,
          onPrimary: Colors.white,
          secondary: coral,
          onSecondary: ink,
          tertiary: gold,
          onTertiary: ink,
          surface: plum,
          onSurface: mist,
          onSurfaceVariant: Color(0xFFD5C8E2),
          outline: Color(0xFF665277),
        ),
        fontFamily: 'sans',
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF8F3FB),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6940D8),
          onPrimary: Colors.white,
          secondary: Color(0xFFE6453E),
          onSecondary: Color(0xFF190B2C),
          tertiary: Color(0xFF8B5A00),
          onTertiary: Colors.white,
          surface: Color(0xFFFFFBFF),
          onSurface: Color(0xFF21142B),
          onSurfaceVariant: Color(0xFF65566E),
          outline: Color(0xFFCEC0D7),
        ),
        fontFamily: 'sans',
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
      home: PopScope(
        canPop: controller.page == AppPage.welcome,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.back();
        },
        child: AppBackground(
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
              ),
            },
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
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: light
              ? const [Color(0xFFFFFBFF), Color(0xFFF8F3FB), Color(0xFFF1E9F6)]
              : const [Color(0xFF2B1045), ink, Color(0xFF10071C)],
        ),
      ),
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

Color _softSurface(BuildContext context, {double darkAlpha = .06}) =>
    _isLight(context)
    ? Colors.white.withValues(alpha: .82)
    : Colors.white.withValues(alpha: darkAlpha);

Color _softOutline(BuildContext context, {double darkAlpha = .12}) =>
    _isLight(context)
    ? Theme.of(context).colorScheme.outline.withValues(alpha: .72)
    : Colors.white.withValues(alpha: darkAlpha);

Color _accentColor(BuildContext context, Color color) {
  if (!_isLight(context)) return color;
  final scheme = Theme.of(context).colorScheme;
  if (color == coral) return scheme.secondary;
  if (color == purple) return scheme.primary;
  if (color == gold) return scheme.tertiary;
  if (color == mist) return scheme.primary;
  return color;
}

TextStyle _sectionStyle(BuildContext context) => TextStyle(
  color: _secondaryText(context),
  fontSize: 12,
  fontWeight: FontWeight.w800,
  letterSpacing: 1.5,
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
      Icon(Icons.shield_outlined, color: _accentColor(context, gold), size: 58),
      const SizedBox(height: 20),
      const Text(
        'Antes de jugar',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 10),
      Text(
        'La diversión siempre termina donde empieza un límite.',
        textAlign: TextAlign.center,
        style: TextStyle(color: _secondaryText(context), fontSize: 16),
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
      CheckboxListTile(
        value: adult,
        onChanged: (value) => setState(() => adult = value ?? false),
        title: const Text('Todas las personas tienen 18 años o más'),
        controlAffinity: ListTileControlAffinity.leading,
      ),
      CheckboxListTile(
        value: consent,
        onChanged: (value) => setState(() => consent = value ?? false),
        title: const Text('Entendemos que el consentimiento puede retirarse'),
        controlAffinity: ListTileControlAffinity.leading,
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
        Icon(icon, color: _accentColor(context, purple)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(
                subtitle,
                style: TextStyle(color: _secondaryText(context), fontSize: 13),
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
    final controlBackground = _isLight(context)
        ? scheme.primary.withValues(alpha: .12)
        : coral;
    final controlForeground = _isLight(context) ? scheme.primary : ink;
    final controlStyle = IconButton.styleFrom(
      backgroundColor: controlBackground,
      foregroundColor: controlForeground,
      minimumSize: const Size(48, 48),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton.filled(
                style: controlStyle,
                onPressed: () {
                  AppAudio.play(AppSound.toggle);
                  onToggleTheme();
                },
                tooltip: lightMode
                    ? 'Activar modo oscuro'
                    : 'Activar modo claro',
                icon: Icon(
                  lightMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: controlStyle,
                onPressed: () {
                  AppAudio.play(AppSound.tap);
                  controller.showSettings();
                },
                tooltip: 'Configuración',
                icon: const Icon(Icons.settings_rounded, size: 20),
              ),
            ],
          ),
          const Spacer(flex: 2),
          Center(
            child: SizedBox(
              width: 196,
              height: 196,
              child: Image.asset(
                'assets/branding/verdad-o-reto-logo-transparent.png',
                key: const ValueKey('brand-logo'),
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Verdad o Reto',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 34,
              height: 1.05,
              fontWeight: FontWeight.w900,
              letterSpacing: .4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Las mejores historias empiezan\ncon una pregunta.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _secondaryText(context),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const Spacer(flex: 3),
          PrimaryButton(
            label: 'EMPEZAR A JUGAR',
            icon: Icons.play_arrow_rounded,
            onTap: controller.showPlayers,
          ),
          const SizedBox(height: 14),
          Text(
            '2–12 jugadores  ·  Sin conexión',
            style: TextStyle(color: _secondaryText(context), fontSize: 13),
          ),
        ],
      ),
    );
  }
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
    final editor = TextEditingController(text: player);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar jugador'),
        content: TextField(controller: editor, autofocus: true, maxLength: 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, editor.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    editor.dispose();
    if (value != null) widget.controller.editPlayer(player, value);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppHeader(
          title: '¿Quién juega?',
          subtitle: 'Añade al menos 2 personas',
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
                  hintText: 'Nombre del jugador',
                  filled: true,
                  fillColor: _softSurface(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: _softOutline(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: _softOutline(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Pressable(
              onTap: addPlayer,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          'JUGADORES  ${widget.controller.players.length}/12',
          style: _sectionStyle(context),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ReorderableListView.builder(
            itemCount: widget.controller.players.length,
            onReorderItem: widget.controller.reorderPlayer,
            itemBuilder: (_, index) {
              final player = widget.controller.players[index];
              final active = !widget.controller.inactivePlayers.contains(
                player,
              );
              return Container(
                key: ValueKey(player),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                decoration: BoxDecoration(
                  color: _softSurface(context, darkAlpha: active ? .08 : .035),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _softOutline(context)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _accentColor(
                        context,
                        purple,
                      ).withValues(alpha: .18),
                      child: Text(
                        player[0].toUpperCase(),
                        style: TextStyle(
                          color: _isLight(context)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        player,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
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
                      tooltip: 'Editar $player',
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
                      tooltip: 'Eliminar $player',
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
              );
            },
          ),
        ),
        if (widget.controller.activePlayers.length < 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Necesitas ${2 - widget.controller.activePlayers.length} jugador más activo',
              style: TextStyle(color: _accentColor(context, gold)),
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
        title: 'Modo de juego',
        subtitle: 'Elige el ambiente de la partida',
        onBack: controller.back,
      ),
      Text('MODO DE JUEGO', style: _sectionStyle(context)),
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
              title: 'Intensidad',
              subtitle: 'Modo ${controller.mode.title}',
              onBack: controller.back,
            ),
            const SizedBox(height: 16),
            Text('INTENSIDAD', style: _sectionStyle(context)),
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
                title: const Text(
                  'Turnos aleatorios',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  controller.randomizeTurns
                      ? 'El siguiente jugador se elegirá al azar'
                      : 'Los jugadores participarán en orden',
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
            const SizedBox(height: 14),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Límites de contenido',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                'Desactiva lo que el grupo prefiera evitar',
                style: TextStyle(color: _secondaryText(context), fontSize: 13),
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
    padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
    decoration: BoxDecoration(
      color: _isLight(context)
          ? Theme.of(context).colorScheme.surface.withValues(alpha: .97)
          : ink.withValues(alpha: .96),
      border: Border(top: BorderSide(color: _softOutline(context))),
      boxShadow: _isLight(context)
          ? [
              BoxShadow(
                color: ink.withValues(alpha: .08),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ]
          : null,
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          subtitle,
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
    title: Text(label),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? activeColor.withValues(alpha: _isLight(context) ? .11 : .18)
                : _softSurface(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? activeColor : _softOutline(context),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 27)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _secondaryText(context),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: _duration(context, 160),
                width: 20,
                height: 20,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? activeColor : _secondaryText(context),
                    width: 2,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? activeColor : Colors.transparent,
                  ),
                ),
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
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 14, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'RONDA ${controller.turn}${controller.maxRounds > 0 ? ' / ${controller.maxRounds}' : ''}',
                        style: _sectionStyle(context),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        AppAudio.play(AppSound.toggle);
                        controller.togglePause();
                      },
                      tooltip: 'Pausar',
                      icon: Icon(
                        Icons.pause_rounded,
                        color: _secondaryText(context),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        AppAudio.play(AppSound.back);
                        controller.finishGame();
                      },
                      child: Text(
                        'Terminar',
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
                        Text(
                          'ES EL TURNO DE',
                          textAlign: TextAlign.center,
                          style: _sectionStyle(context),
                        ),
                        Text(
                          controller.currentPlayer,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _accentColor(context, gold),
                            fontSize: 38,
                            height: 1.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (card == null)
                          ChooseCardType(
                            onTruth: () =>
                                controller.chooseCard(CardType.verdad),
                            onDare: () => controller.chooseCard(CardType.reto),
                          )
                        else
                          ChallengeCard(card: card),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 124,
                          child: card == null
                              ? Align(
                                  alignment: Alignment.topCenter,
                                  child: SecondaryButton(
                                    label: 'SALTAR JUGADOR',
                                    color: _secondaryText(context),
                                    icon: Icons.skip_next_rounded,
                                    onTap: controller.skipPlayer,
                                  ),
                                )
                              : Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SecondaryButton(
                                            label: 'OTRA',
                                            color: gold,
                                            icon: Icons.refresh_rounded,
                                            onTap: controller.anotherCard,
                                          ),
                                        ),
                                        if (controller.previousCard !=
                                            null) ...[
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: SecondaryButton(
                                              label: 'ANTERIOR',
                                              color: _secondaryText(context),
                                              icon: Icons.undo_rounded,
                                              onTap: controller
                                                  .restorePreviousCard,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    PrimaryButton(
                                      label: controller.reachedRoundLimit
                                          ? 'VER RESUMEN'
                                          : 'SIGUIENTE TURNO',
                                      icon: Icons.arrow_forward_rounded,
                                      onTap: controller.nextTurn,
                                    ),
                                  ],
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
                color: ink.withValues(alpha: .96),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pause_circle_outline_rounded,
                          size: 64,
                          color: gold,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Partida en pausa',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
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
        ],
      ),
    );
  }
}

class ChooseCardType extends StatelessWidget {
  const ChooseCardType({
    required this.onTruth,
    required this.onDare,
    super.key,
  });
  final VoidCallback onTruth;
  final VoidCallback onDare;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 220),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: _softSurface(context),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: _softOutline(context)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '¿Qué eliges?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'VERDAD',
                color: coral,
                icon: Icons.chat_bubble_outline_rounded,
                onTap: onTruth,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecondaryButton(
                label: 'RETO',
                color: purple,
                icon: Icons.bolt_rounded,
                onTap: onDare,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({required this.card, super.key});
  final GameCard card;

  @override
  Widget build(BuildContext context) {
    final color = card.type == CardType.verdad ? coral : purple;
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(card.type.emoji, style: const TextStyle(fontSize: 38)),
          const SizedBox(height: 10),
          Text(
            card.type.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: ink.withValues(alpha: .64),
            ),
          ),
          const SizedBox(height: 17),
          Text(
            card.text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: ink,
              fontSize: 22,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({required this.controller, super.key});
  final GameController controller;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🏆', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 18),
        const Text(
          '¡Qué partida!',
          style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900),
        ),
        Text(
          'Habéis completado ${controller.truthsCompleted + controller.daresCompleted} turnos',
          style: TextStyle(color: _secondaryText(context), fontSize: 17),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: StatCard(
                value: '${controller.truthsCompleted}',
                label: 'Verdades',
                color: coral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: '${controller.daresCompleted}',
                label: 'Retos',
                color: purple,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatCard(
                value: '${controller.skippedCards}',
                label: 'Cambios',
                color: gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 34),
        PrimaryButton(
          label: 'JUGAR OTRA VEZ',
          icon: Icons.refresh_rounded,
          onTap: controller.playAgain,
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: 'VOLVER AL INICIO',
          color: Theme.of(context).colorScheme.primary,
          icon: Icons.home_rounded,
          onTap: controller.goHome,
        ),
      ],
    ),
  );
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
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: _isLight(context) ? .10 : .14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: effectiveColor.withValues(alpha: _isLight(context) ? .18 : 0),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: effectiveColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: _secondaryText(context), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.controller, super.key});
  final GameController controller;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
    children: [
      AppHeader(
        title: 'Configuración',
        subtitle: 'Adapta el juego a tu grupo',
        onBack: controller.closeSettings,
      ),
      Text('EXPERIENCIA', style: _sectionStyle(context)),
      const SizedBox(height: 8),
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(
          Icons.notification_add_outlined,
          color: _accentColor(context, gold),
        ),
        title: const Text('Probar notificación'),
        subtitle: Text(
          'Envía una notificación local ahora',
          style: TextStyle(color: _secondaryText(context)),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: _secondaryText(context),
        ),
        onTap: () async {
          final messenger = ScaffoldMessenger.of(context);
          final sent = await NotificationService.instance
              .showTestNotification();
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                sent
                    ? 'Notificación de prueba enviada'
                    : 'Activa el permiso de notificaciones para probarla',
              ),
            ),
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
      Text('TAMAÑO DEL TEXTO', style: _sectionStyle(context)),
      Slider(
        value: controller.textScale,
        min: .9,
        max: 1.25,
        divisions: 7,
        label: '${(controller.textScale * 100).round()} %',
        onChanged: controller.setTextScale,
      ),
      const SizedBox(height: 12),
      Text('DURACIÓN DE LA PARTIDA', style: _sectionStyle(context)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final rounds in [10, 20, 30, 0])
            ChoiceChip(
              selected: controller.maxRounds == rounds,
              label: Text(rounds == 0 ? 'Sin límite' : '$rounds turnos'),
              onSelected: (_) {
                AppAudio.play(AppSound.select);
                controller.setMaxRounds(rounds);
              },
            ),
        ],
      ),
      const SizedBox(height: 24),
      Text('PRIVACIDAD E HISTORIAL', style: _sectionStyle(context)),
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
        title: Text('${controller.historyCount} tarjetas vistas'),
        subtitle: Text(
          'Se priorizan tarjetas que aún no han aparecido',
          style: TextStyle(color: _secondaryText(context)),
        ),
        trailing: TextButton(
          onPressed: controller.historyCount == 0
              ? null
              : () {
                  AppAudio.play(AppSound.back);
                  controller.resetHistory();
                },
          child: const Text('Reiniciar'),
        ),
      ),
    ],
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
          onPressed: () {
            AppAudio.play(AppSound.back);
            onBack();
          },
          tooltip: 'Volver',
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: _secondaryText(context), fontSize: 14),
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
    super.key,
  });
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final AppSound sound;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    sound: sound,
    child: AnimatedOpacity(
      duration: _duration(context, 160),
      opacity: onTap == null ? .35 : 1,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          color: coral,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ink),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .6,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
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
    final effectiveColor = _accentColor(context, color);
    return Pressable(
      onTap: onTap,
      sound: sound,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: effectiveColor.withValues(alpha: _isLight(context) ? .035 : 0),
          border: Border.all(color: effectiveColor.withValues(alpha: .72)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: effectiveColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontWeight: FontWeight.w900,
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
