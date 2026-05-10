import 'package:flip_card/flip_card.dart';
import 'package:flip_card/flip_card_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/word_entry.dart';
import '../providers/app_provider.dart';
import '../theme.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen>
    with SingleTickerProviderStateMixin {
  final FlipCardController _flipCtrl = FlipCardController();
  int _currentIndex = 0;
  bool _flipped = false;
  bool _sessionDone = false;
  int _learnedThisSession = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final queue = provider.flashcardQueue;

        if (queue.isEmpty || _sessionDone) {
          return _buildDone(context, provider);
        }

        final card = queue[_currentIndex.clamp(0, queue.length - 1)];

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Flashcards'),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '${_currentIndex + 1} / ${queue.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildProgressBar(_currentIndex, queue.length),
              Expanded(child: _buildCardView(context, provider, card)),
              _buildButtons(context, provider, card),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(int current, int total) {
    return LinearProgressIndicator(
      value: total == 0 ? 0 : current / total,
      backgroundColor: AppTheme.surfaceLight,
      valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
      minHeight: 4,
    );
  }

  Widget _buildCardView(BuildContext context, AppProvider provider, WordEntry card) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            _flipped ? 'Answer' : 'What does this mean?',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FlipCard(
              controller: _flipCtrl,
              flipOnTouch: true,
              onFlip: () => setState(() => _flipped = !_flipped),
              front: _CardFace(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(card.word,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        fontSize: 42, fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (card.reading != null && card.reading!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(card.reading!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.notoSans(
                          fontSize: 22, color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text('Tap to reveal',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              back: _CardFace(
                color: AppTheme.accent.withOpacity(0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(card.word,
                      style: GoogleFonts.notoSans(
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: AppTheme.accentLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (card.definition != null && card.definition!.isNotEmpty)
                      Text(card.definition!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 22, color: AppTheme.textPrimary, height: 1.5,
                        ),
                      )
                    else
                      Text('No definition added yet',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 16),
                    _StatRow(entry: card),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(BuildContext context, AppProvider provider, WordEntry card) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          if (_flipped) ...[
            Row(children: [
              Expanded(
                child: _ActionButton(
                  label: 'Still learning',
                  icon: Icons.refresh,
                  color: AppTheme.warning,
                  onTap: () => _onResult(context, provider, card, false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ActionButton(
                  label: 'Got it!',
                  icon: Icons.check,
                  color: AppTheme.success,
                  onTap: () => _onResult(context, provider, card, true),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Mark as Learned'),
                onPressed: () async {
                  await provider.markWordLearned(card, true);
                  provider.removeFromQueue(card);
                  setState(() {
                    _flipped = false;
                    _learnedThisSession++;
                    if (provider.flashcardQueue.isEmpty) {
                      _sessionDone = true;
                    } else {
                      _currentIndex = _currentIndex.clamp(0, provider.flashcardQueue.length - 1);
                    }
                  });
                  if (_flipCtrl.state?.isFront == false) {
                    _flipCtrl.toggleCard();
                  }
                },
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flip),
                label: const Text('Reveal Answer'),
                onPressed: () {
                  _flipCtrl.toggleCard();
                  setState(() => _flipped = true);
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onResult(BuildContext context, AppProvider provider,
      WordEntry card, bool correct) async {
    await provider.recordFlashcardResult(card, correct);

    // If correct, move to end of queue (spaced repetition lite)
    // If wrong, keep in queue to see again
    final queue = provider.flashcardQueue;

    setState(() {
      _flipped = false;
      if (_currentIndex >= queue.length - 1) {
        if (!correct) {
          _currentIndex = 0;
        } else {
          _sessionDone = true;
        }
      } else {
        _currentIndex++;
      }
    });

    // Reset flip
    if (_flipCtrl.state?.isFront == false) {
      await Future.delayed(const Duration(milliseconds: 100));
      _flipCtrl.toggleCard();
    }
  }

  Widget _buildDone(BuildContext context, AppProvider provider) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Flashcards'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              Text('Session Complete!',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text('You marked $_learnedThisSession word(s) as learned this session.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  provider.buildFlashcardQueue();
                  setState(() {
                    _currentIndex = 0;
                    _flipped = false;
                    _sessionDone = false;
                    _learnedThisSession = 0;
                  });
                },
                child: const Text('Practice Again'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Texts'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  final Widget child;
  final Color? color;
  const _CardFace({required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color ?? AppTheme.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.divider, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label, required this.icon,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final WordEntry entry;
  const _StatRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.timesSeen == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Seen ${entry.timesSeen}× · ${(entry.accuracy * 100).toStringAsFixed(0)}% correct',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
      ),
    );
  }
}
