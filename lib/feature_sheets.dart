import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ad_service.dart';
import 'app_language.dart';
import 'audio_feedback.dart';
import 'content/bonus_packs_content.dart';
import 'game_controller.dart';
import 'game_models.dart';

Future<void> showRewardsAndPacksSheet(
  BuildContext context,
  GameController controller,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (sheetContext) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => _RewardsSheetContent(controller: controller),
  ),
);

Future<void> showCustomCardsSheet(
  BuildContext context,
  GameController controller,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (sheetContext) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => _CustomCardsSheetContent(controller: controller),
  ),
);

Future<void> showFavoritesSheet(
  BuildContext context,
  GameController controller,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  backgroundColor: Theme.of(context).colorScheme.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
  ),
  builder: (sheetContext) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => _FavoritesSheetContent(controller: controller),
  ),
);

class _RewardsSheetContent extends StatefulWidget {
  const _RewardsSheetContent({required this.controller});
  final GameController controller;

  @override
  State<_RewardsSheetContent> createState() => _RewardsSheetContentState();
}

class _RewardsSheetContentState extends State<_RewardsSheetContent> {
  bool _loadingAd = false;

  Future<void> _earnSparksAd() async {
    if (_loadingAd) return;
    setState(() => _loadingAd = true);
    final ok = await widget.controller.earnSparksFromRewardedAd();
    if (!mounted) return;
    setState(() => _loadingAd = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Anuncio no disponible ahora mismo')),
        ),
      );
    }
  }

  Future<void> _unlockPackAd(String packId) async {
    if (_loadingAd) return;
    setState(() => _loadingAd = true);
    final ok = await widget.controller.unlockPackWithRewardedAd(packId);
    if (!mounted) return;
    setState(() => _loadingAd = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Anuncio no disponible ahora mismo')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    final outline = scheme.outline.withValues(alpha: .35);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .82,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(c.rankTitle),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        context.isEnglish
                            ? '${c.totalTurnsPlayed} turns  ·  ${c.totalGamesPlayed} games'
                            : '${c.totalTurnsPlayed} turnos  ·  ${c.totalGamesPlayed} partidas',
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: scheme.primary.withValues(alpha: .28),
                    ),
                  ),
                  child: Text(
                    '⚡ ${c.sparks}',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _loadingAd ? null : _earnSparksAd,
              icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
              label: Text(context.tr('Ganar +60 Chispas')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              context.tr('MAZOS EXTRA'),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.7,
              ),
            ),
            const SizedBox(height: 10),
            for (final pack in bonusPacks) ...[
              _buildPackTile(context, pack, c, scheme, outline),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 14),
            Text(
              context.tr('LOGROS DESBLOQUEADOS'),
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.7,
              ),
            ),
            const SizedBox(height: 10),
            for (final ach in appAchievements) ...[
              _buildAchievementTile(context, ach, c, scheme, outline),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPackTile(
    BuildContext context,
    BonusPack pack,
    GameController c,
    ColorScheme scheme,
    Color outline,
  ) {
    final unlocked = c.unlockedPacks.contains(pack.id);
    final active = c.activeBonusPacks.contains(pack.id);
    final canAfford = c.sparks >= pack.costSparks;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.onSurface.withValues(alpha: .04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? scheme.primary : outline,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(pack.emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pack.title(english: context.isEnglish),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      pack.subtitle(english: context.isEnglish),
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (unlocked)
                Switch.adaptive(
                  value: active,
                  onChanged: (_) {
                    AppAudio.play(AppSound.toggle);
                    c.toggleBonusPackActive(pack.id);
                  },
                ),
            ],
          ),
          if (!unlocked) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: canAfford
                        ? () {
                            AppAudio.play(AppSound.confirm);
                            c.unlockPackWithSparks(pack.id);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('${pack.costSparks} ⚡'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loadingAd
                        ? null
                        : () => _unlockPackAd(pack.id),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(context.tr('Ver vídeo')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAchievementTile(
    BuildContext context,
    AchievementDef ach,
    GameController c,
    ColorScheme scheme,
    Color outline,
  ) {
    final done = c.unlockedAchievements.contains(ach.id);
    return Opacity(
      opacity: done ? 1 : .55,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: .035),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done ? scheme.primary.withValues(alpha: .5) : outline,
          ),
        ),
        child: Row(
          children: [
            Text(ach.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(ach.title),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    context.tr(ach.description),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              done ? '✓' : '+${ach.rewardSparks} ⚡',
              style: TextStyle(
                color: done ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomCardsSheetContent extends StatefulWidget {
  const _CustomCardsSheetContent({required this.controller});
  final GameController controller;

  @override
  State<_CustomCardsSheetContent> createState() =>
      _CustomCardsSheetContentState();
}

class _CustomCardsSheetContentState extends State<_CustomCardsSheetContent> {
  final _textController = TextEditingController();
  CardType _selectedType = CardType.verdad;
  bool _loadingAd = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submitWithSparks() {
    final added = widget.controller.addCustomCard(
      _selectedType,
      _textController.text,
    );
    if (added) {
      AppAudio.play(AppSound.confirm);
      _textController.clear();
    }
  }

  Future<void> _submitWithAd() async {
    if (_loadingAd || _textController.text.trim().length < 4) return;
    setState(() => _loadingAd = true);
    final earned = await AdService.instance.showRewardedAd();
    if (!mounted) return;
    setState(() => _loadingAd = false);
    if (!earned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Anuncio no disponible ahora mismo')),
        ),
      );
      return;
    }
    if (widget.controller.addCustomCard(
      _selectedType,
      _textController.text,
      paidWithAd: true,
    )) {
      AppAudio.play(AppSound.confirm);
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 4, 22, 20 + bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .78,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('Mis tarjetas'),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.6,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: .14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '⚡ ${c.sparks}',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                c.nextCustomCardIsFree
                    ? (context.isEnglish
                          ? '${c.freeCustomCardsRemaining} free cards left · Then ${GameController.customCardCost} ⚡ or a video'
                          : 'Te quedan ${c.freeCustomCardsRemaining} gratis · Después ${GameController.customCardCost} ⚡ o vídeo')
                    : (context.isEnglish
                          ? 'Each new custom card costs ${GameController.customCardCost} ⚡ or watching a short video'
                          : 'Cada tarjeta nueva cuesta ${GameController.customCardCost} ⚡ o ver un vídeo'),
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ChoiceChip(
                    selected: _selectedType == CardType.verdad,
                    label: Text('💬 ${context.tr('VERDAD')}'),
                    onSelected: (_) =>
                        setState(() => _selectedType = CardType.verdad),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    selected: _selectedType == CardType.reto,
                    label: Text('⚡ ${context.tr('RETO')}'),
                    onSelected: (_) =>
                        setState(() => _selectedType = CardType.reto),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _textController,
                maxLength: 140,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: context.tr('Escribe una verdad o un reto...'),
                  filled: true,
                  fillColor: scheme.onSurface.withValues(alpha: .045),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _textController.text.trim().length >= 4 &&
                              c.canAffordCustomCard
                          ? _submitWithSparks
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        c.nextCustomCardIsFree
                            ? context.tr('Añadir gratis')
                            : context.tr('Añadir por 30 ⚡'),
                      ),
                    ),
                  ),
                  if (!c.nextCustomCardIsFree) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            !_loadingAd &&
                                _textController.text.trim().length >= 4
                            ? _submitWithAd
                            : null,
                        icon: const Icon(Icons.play_arrow_rounded, size: 18),
                        label: Text(context.tr('Añadir viendo vídeo')),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: c.includeCustomCards,
                onChanged: c.setIncludeCustomCards,
                title: Text(
                  context.tr('Incluir mis tarjetas'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (c.customCards.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      context.tr('Aún no tienes tarjetas personalizadas'),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: c.customCards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final card = c.customCards[index];
                      return Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: .04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Text(
                              card.type.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                card.text,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              onPressed: () => c.removeCustomCard(card),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesSheetContent extends StatelessWidget {
  const _FavoritesSheetContent({required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Favoritas'),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.6,
                ),
              ),
              const SizedBox(height: 12),
              if (controller.favoriteCards.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      context.tr('Aún no tienes tarjetas favoritas'),
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.favoriteCards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final card = controller.favoriteCards[index];
                      return Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: .04),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Text(
                              card.type.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                card.text,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            IconButton(
                              onPressed: () => controller.toggleFavorite(card),
                              icon: Icon(
                                Icons.favorite_rounded,
                                size: 20,
                                color: scheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardTimerPill extends StatefulWidget {
  const CardTimerPill({required this.seconds, super.key});
  final int seconds;

  @override
  State<CardTimerPill> createState() => _CardTimerPillState();
}

class _CardTimerPillState extends State<CardTimerPill> {
  late int _remaining;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.seconds;
  }

  @override
  void didUpdateWidget(covariant CardTimerPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seconds != widget.seconds) {
      _timer?.cancel();
      _running = false;
      _remaining = widget.seconds;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    if (_remaining <= 0) _remaining = widget.seconds;
    setState(() => _running = true);
    AppAudio.play(AppSound.tap);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_remaining <= 1) {
        timer.cancel();
        setState(() {
          _remaining = 0;
          _running = false;
        });
        AppAudio.play(AppSound.timerEnd);
        if (AppAudio.hapticsEnabled) HapticFeedback.mediumImpact();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final finished = _remaining == 0;
    final label = finished
        ? context.tr('¡Tiempo!')
        : _running
        ? '${_remaining}s'
        : '${widget.seconds}s';
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: finished
              ? Colors.white.withValues(alpha: .28)
              : Colors.white.withValues(alpha: _running ? .22 : .14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: _running ? .45 : .22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              finished
                  ? Icons.check_circle_outline_rounded
                  : _running
                  ? Icons.pause_rounded
                  : Icons.timer_outlined,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
