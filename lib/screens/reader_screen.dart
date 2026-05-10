import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/word_entry.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'flashcard_screen.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  bool _showTranslation = true;
  String? _selectedWord;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final text        = provider.selectedText;
        final paras       = provider.paragraphs;
        final idx         = provider.selectedParagraphIndex;
        final currentPara = provider.currentParagraph;
        final hasEnglish  = text?.englishContent != null;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon     : const Icon(Icons.arrow_back),
              tooltip  : 'Back to texts',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(text?.title ?? 'Reader',
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (hasEnglish)
                IconButton(
                  icon: Icon(_showTranslation
                      ? Icons.translate
                      : Icons.translate_outlined),
                  tooltip  : 'Toggle translation',
                  onPressed: () => setState(() => _showTranslation = !_showTranslation),
                ),
              IconButton(
                icon     : const Icon(Icons.style_outlined),
                tooltip  : 'Flashcards for this paragraph',
                onPressed: currentPara == null ? null      : () => _launchParaFlashcards(context, provider, currentPara),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildParagraphSelector(context, provider, paras, idx),
              const Divider(height: 1),
              Expanded(
                child: currentPara == null
                    ? const Center(child: Text('No paragraphs found'))
                    : _buildParagraphView(context, provider, currentPara, hasEnglish),
              ),
            ],
          ),
          bottomNavigationBar: _buildNavBar(context, provider, idx, paras.length),
        );
      },
    );
  }

  Widget _buildParagraphSelector(
      BuildContext context, AppProvider provider,
      List<Map<String, dynamic>> paras, int idx) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: paras.length,
        itemBuilder: (ctx, i) {
          final selected = i == idx;
          return GestureDetector(
            onTap: () => provider.selectParagraph(i),
            child: AnimatedContainer(
              duration  : const Duration(milliseconds: 200),
              margin    : const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              padding   : const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color       : selected ? AppTheme.accent: AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text('${i + 1}',
                  style: TextStyle(
                    color     : selected ? Colors.white   : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.bold: FontWeight.normal,
                    fontSize  : 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParagraphView(BuildContext context, AppProvider provider,
      Map<String, dynamic> para, bool hasEnglish) {
    final targetText  = para['content'] as String;
    final englishText = para['english_content'] as String?;
    final showEN      = hasEnglish && _showTranslation && englishText != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Target language paragraph with tappable words
          _buildTappableText(context, provider, targetText),
          if (showEN) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color       : AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border      : Border.all(color: AppTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('🇺🇸', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Text('English', style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.accent, fontWeight: FontWeight.w600,
                    )),
                  ]),
                  const SizedBox(height: 8),
                  Text(englishText,
                    style: GoogleFonts.dmSans(
                      fontSize: 15, color: AppTheme.textSecondary, height: 1.7,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_selectedWord != null) ...[
            const SizedBox(height: 20),
            _buildWordPanel(context, provider, _selectedWord!),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildTappableText(BuildContext context, AppProvider provider, String text) {
    // Build a fast lookup set (lower-case) for O(1) membership tests.
    final learnedSet = <String>{};
    final trackedSet = <String>{};
    for (final w in provider.words) {
      trackedSet.add(w.word.toLowerCase());
      if (w.learned) learnedSet.add(w.word.toLowerCase());
    }

    // Tokenise into alternating [word, non-word, word, …] spans so we can
    // render every character without losing spaces / punctuation.
    // The pattern matches a "word" — one or more letters/digits/apostrophe/
    // hyphen, including accented Latin, Cyrillic, Arabic, CJK, Kana, Hangul.
    final wordPattern = RegExp(
      r"[\w\u00C0-\u024F\u0400-\u04FF\u0600-\u06FF"
      r"\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF\uAC00-\uD7AF'-]+",
    );

    final spans = <InlineSpan>[];
    int cursor = 0;

    for (final match in wordPattern.allMatches(text)) {
      // Non-word gap before this match (spaces, punctuation, newlines…)
      if (match.start > cursor) {
        spans.add(TextSpan(
          text: text.substring(cursor, match.start),
          style: GoogleFonts.notoSans(
            fontSize: 18, color: AppTheme.textPrimary, height: 1.8,
          ),
        ));
      }

      final token      = match.group(0)!;
      final key        = token.toLowerCase();
      final isSelected = _selectedWord == key;
      final isLearned  = learnedSet.contains(key);
      final isTracked  = trackedSet.contains(key);

      final bgColor = isSelected
          ? AppTheme.accent.withOpacity(0.3)
          : isLearned
              ? AppTheme.success.withOpacity(0.15)
              : isTracked
                  ? AppTheme.warning.withOpacity(0.15)
                  : null;

      final fgColor = isSelected
          ? AppTheme.accentLight
          : isLearned
              ? AppTheme.success
              : AppTheme.textPrimary;

      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline : TextBaseline.alphabetic,
        child    : GestureDetector(
          onTap: () => setState(() {
            _selectedWord = isSelected ? null : key;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            decoration: bgColor != null
                ? BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(4),
                    border: isSelected
                        ? Border.all(color: AppTheme.accent, width: 1.5)
                        : null,
                  )
                : null,
            child: Text(
              token,
              style: GoogleFonts.notoSans(
                fontSize  : 18,
                color     : fgColor,
                height    : 1.8,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ));

      cursor = match.end;
    }

    // Any trailing non-word text after the last match.
    if (cursor < text.length) {
      spans.add(TextSpan(
        text: text.substring(cursor),
        style: GoogleFonts.notoSans(
          fontSize: 18, color: AppTheme.textPrimary, height: 1.8,
        ),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.left,
    );
  }

  Widget _buildWordPanel(BuildContext context, AppProvider provider, String word) {
    // Words are auto-extracted on import, so they will almost always be in the DB.
    final existing = provider.words.firstWhere(
      (w) => w.word.toLowerCase() == word.toLowerCase(),
      orElse: () => WordEntry(languageId: -1, word: word),
    );
    final isTracked = existing.languageId != -1;

    // Use StatefulBuilder so the controllers don't rebuild on every parent setState.
    return StatefulBuilder(
      builder: (ctx, setInner) {
        final readingCtrl = TextEditingController(text: existing.reading ?? '');
        final defCtrl = TextEditingController(text: existing.definition ?? '');

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color       : AppTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border      : Border.all(color: AppTheme.accent.withOpacity(0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(word,
                    style: Theme.of(context).textTheme.headlineMedium,
                  )),
                  if (isTracked)
                    Chip(
                      label: Text(existing.learned ? '✓ Learned' : '📚 Studying'),
                      backgroundColor: existing.learned
                          ? AppTheme.success.withOpacity(0.2)
                          : AppTheme.warning.withOpacity(0.2),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: readingCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reading / Pronunciation',
                  hintText : 'e.g. furigana, IPA...',
                  isDense  : true,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: defCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Definition / Translation',
                  hintText : 'Add your notes...',
                  isDense  : true,
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: ElevatedButton(
                  onPressed: () async {
                    await provider.addWord(
                      word      : word.toLowerCase(),
                      reading   : readingCtrl.text.trim().isEmpty ? null: readingCtrl.text.trim(),
                      definition: defCtrl.text.trim().isEmpty ? null    : defCtrl.text.trim(),
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('"$word" saved')),
                      );
                      setState(() {}); // refresh colour in text
                    }
                  },
                  child: Text(isTracked ? 'Save Notes' : 'Track Word'),
                )),
                if (isTracked) ...[
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () async {
                      await provider.markWordLearned(existing, !existing.learned);
                      if (mounted) setState(() {});
                    },
                    child: Text(existing.learned ? 'Unlearn' : 'Mark Learned'),
                  ),
                ],
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavBar(BuildContext context, AppProvider provider, int idx, int total) {
    return Container(
      padding   : const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color : AppTheme.cardBg,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            icon     : const Icon(Icons.arrow_back_ios),
            onPressed: idx > 0 ? () => provider.selectParagraph(idx - 1): null,
          ),
          Expanded(child: Center(child: Text(
            'Paragraph ${idx + 1} of $total',
            style: Theme.of(context).textTheme.bodyMedium,
          ))),
          IconButton(
            icon     : const Icon(Icons.arrow_forward_ios),
            onPressed: idx < total - 1 ? () => provider.selectParagraph(idx + 1) : null,
          ),
        ],
      ),
    );
  }

  void _launchParaFlashcards(BuildContext context, AppProvider provider, Map<String, dynamic> para) {
    final text = para['content'] as String;
    final words = text
        .split(RegExp(r'\W+'))
        .where((w) => w.length > 1)
        .toList();
    provider.buildFlashcardQueueFromParagraph(words);
    if (provider.flashcardQueue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unlearned tracked words in this paragraph')),
      );
      return;
    }
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const FlashcardScreen(),
    ));
  }
}
