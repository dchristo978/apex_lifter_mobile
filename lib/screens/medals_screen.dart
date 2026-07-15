import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/api_client.dart';
import '../widgets/confetti_burst.dart';

/// A lifter's medal case: one gold medal per challenge won, presented as a
/// dark "trophy room" with a confetti cannon. The owner can attach a short
/// story (max 100 words) to each medal; visitors just admire.
class MedalsScreen extends StatefulWidget {
  const MedalsScreen({super.key, required this.userId, this.initialName});

  final int userId;
  final String? initialName;

  @override
  State<MedalsScreen> createState() => _MedalsScreenState();
}

class _MedalsScreenState extends State<MedalsScreen>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFFFD700);
  static const _dimGold = Color(0xFFB8860B);

  List<Medal>? _medals;
  bool _isOwner = false;
  String? _ownerName;
  String? _error;

  final _cannon = ConfettiController(duration: const Duration(seconds: 1));
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _cannon.dispose();
    _shimmer.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final json =
          await context.read<ApiClient>().get('/users/${widget.userId}/medals');
      if (!mounted) return;
      setState(() {
        _medals = ((json['medals'] as List?) ?? const [])
            .map((m) => Medal.fromJson(m as Map<String, dynamic>))
            .toList();
        _isOwner = json['is_owner'] as bool? ?? false;
        _ownerName = (json['user'] as Map<String, dynamic>?)?['name'] as String?;
      });
      // Welcome blast — only when there is something to celebrate.
      if (_medals!.isNotEmpty) _cannon.play();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // A deliberate dark-gold "trophy room" look in both app themes.
    return Theme(
      data: ThemeData.dark(useMaterial3: true),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(l10n.medalCase),
          backgroundColor: Colors.transparent,
          foregroundColor: _gold,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1F1607), Color(0xFF120E05), Color(0xFF0A0805)],
            ),
          ),
          child: Stack(
            children: [
              _body(context, l10n),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _cannon,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.05,
                  numberOfParticles: 25,
                  maxBlastForce: 30,
                  minBlastForce: 8,
                  gravity: 0.3,
                  colors: kCelebrationColors,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      );
    }
    final medals = _medals;
    if (medals == null) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _header(context, l10n, medals.length)),
        if (medals.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Opacity(
                      opacity: 0.35,
                      child: Text('🏆', style: TextStyle(fontSize: 72))),
                  const SizedBox(height: 16),
                  Text(l10n.noMedalsYet,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
            sliver: SliverList.builder(
              itemCount: medals.length,
              itemBuilder: (context, i) => _animatedIn(
                index: i,
                child: _medalCard(context, l10n, medals[i], i),
              ),
            ),
          ),
      ],
    );
  }

  Widget _header(BuildContext context, AppLocalizations l10n, int count) {
    return Padding(
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight + 8,
          bottom: 16),
      child: Column(
        children: [
          // Trophy pops in with a springy scale.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.elasticOut,
            builder: (context, v, child) =>
                Transform.scale(scale: v, child: child),
            child: const Text('🏆', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 8),
          // Shimmering gold medal count.
          AnimatedBuilder(
            animation: _shimmer,
            builder: (context, child) => ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment(-1.5 + 3 * _shimmer.value, -0.3),
                end: Alignment(-0.5 + 3 * _shimmer.value, 0.3),
                colors: const [_dimGold, Color(0xFFFFF9C4), _dimGold],
              ).createShader(bounds),
              child: child,
            ),
            child: Text(
              l10n.medalsWithCount(count),
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
          if (_ownerName != null || widget.initialName != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _ownerName ?? widget.initialName!,
                style: const TextStyle(color: Colors.white60, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }

  /// Staggered fade-and-rise entrance for each medal card.
  Widget _animatedIn({required int index, required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + 90 * (index > 8 ? 8 : index)),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 24 * (1 - v)), child: child),
      ),
      child: child,
    );
  }

  Widget _medalCard(
      BuildContext context, AppLocalizations l10n, Medal m, int index) {
    final weight =
        m.targetWeightKg.toStringAsFixed(m.targetWeightKg % 1 == 0 ? 0 : 1);
    final detail = [
      l10n.challengeTarget(weight, m.targetReps, m.targetSets),
      if (m.gymName != null) m.gymName!,
      if (m.wonAt != null)
        l10n.medalWonOn(DateFormat('d MMM yyyy').format(m.wonAt!)),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          // Every medal deserves an ovation.
          onTap: () => _cannon.play(),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A2110), Color(0xFF1C160A)],
              ),
              border: Border.all(color: _gold.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.08),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _medalDisc(index + 1),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m.machineName ?? '—',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700),
                            ),
                            if (m.defeated != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  l10n.medalDefeated(m.defeated!.name),
                                  style: const TextStyle(
                                      color: _gold, fontSize: 13),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                detail,
                                style: const TextStyle(
                                    color: Colors.white54, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isOwner)
                        IconButton(
                          tooltip: m.note == null
                              ? l10n.addMedalStory
                              : l10n.editMedalStory,
                          icon: Icon(
                              m.note == null
                                  ? Icons.edit_note
                                  : Icons.edit_outlined,
                              color: _gold),
                          onPressed: () => _editStory(m),
                        ),
                    ],
                  ),
                  if (m.note != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '“${m.note!}”',
                        style: const TextStyle(
                          color: Color(0xFFEADFA8),
                          fontStyle: FontStyle.italic,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ] else if (_isOwner) ...[
                    const SizedBox(height: 4),
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: _gold),
                      onPressed: () => _editStory(m),
                      icon: const Icon(Icons.auto_stories_outlined, size: 18),
                      label: Text(l10n.addMedalStory),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The gold disc with the medal's number, newest first.
  Widget _medalDisc(int number) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF3B0), _gold, Color(0xFFB8860B)],
        ),
        boxShadow: [
          BoxShadow(
              color: _gold.withValues(alpha: 0.45),
              blurRadius: 10,
              spreadRadius: 1),
        ],
      ),
      child: Center(
        child: Text(
          '$number',
          style: const TextStyle(
            color: Color(0xFF4A3200),
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  int _wordCount(String text) =>
      text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// Owner-only: write/edit the medal's story (max 100 words, live counter).
  Future<void> _editStory(Medal medal) async {
    final l10n = AppLocalizations.of(context);
    final api = context.read<ApiClient>();
    final controller = TextEditingController(text: medal.note ?? '');
    var saving = false;
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C160A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final words = _wordCount(controller.text);
          final tooLong = words > 100;

          Future<void> save() async {
            setSheetState(() {
              saving = true;
              error = null;
            });
            try {
              final json = await api.patch(
                '/challenges/${medal.challengeId}/medal-note',
                {'note': controller.text.trim()},
              );
              final saved = json['medal_note'] as String?;
              if (mounted) {
                setState(() {
                  final i = _medals!
                      .indexWhere((m) => m.challengeId == medal.challengeId);
                  if (i != -1) _medals![i] = medal.copyWith(note: saved);
                });
              }
              if (sheetContext.mounted) Navigator.of(sheetContext).pop();
            } catch (e) {
              setSheetState(() {
                saving = false;
                error = e.toString();
              });
            }
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(
                16, 16, 16, MediaQuery.of(sheetContext).viewInsets.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medal.note == null ? l10n.addMedalStory : l10n.editMedalStory,
                  style: const TextStyle(
                      color: _gold, fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (_) => setSheetState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.medalStoryHint,
                    hintStyle: const TextStyle(color: Colors.white38),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: _gold.withValues(alpha: 0.4)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: _gold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tooLong ? l10n.storyTooLong : l10n.wordsOf100(words),
                  style: TextStyle(
                    fontSize: 12,
                    color: tooLong
                        ? Theme.of(sheetContext).colorScheme.error
                        : Colors.white54,
                  ),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error!,
                        style: TextStyle(
                            color:
                                Theme.of(sheetContext).colorScheme.error)),
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          saving ? null : () => Navigator.of(sheetContext).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: _gold,
                          foregroundColor: const Color(0xFF4A3200)),
                      onPressed: saving || tooLong ? null : save,
                      child: Text(saving ? '...' : l10n.save),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
