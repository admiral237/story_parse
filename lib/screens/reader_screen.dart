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
        final text = provider.selectedText;
        final paras = provider.paragraphs;
        final idx = provider.selectedParagraphIndex;
        final currentPara = provider.currentParagraph;
        final hasEnglish = text?.englishContent != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(text?.title ?? 'Reader',
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (hasEnglish)
                IconButton(
                  icon: Icon(_showTranslation
                      ? Icons.translate
                      : Icons.translate_outlined),
                  tooltip: 'Toggle translation',
                  onPressed: () => setState(() => _showTranslation = !_showTranslation),
                ),
              IconButton(
                icon: const Icon(Icons.style_outlined),
                tooltip: 'Flashcards for this paragraph',
                onPressed: currentPara == null ? null : () => _launchParaFlashcards(context, provider, currentPara),
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
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text('${i + 1}',
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14,
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
    final targetText = para['content'] as String;
    final englishText = para['english_content'] as String?;
    final showEN = hasEnglish && _showTranslation && englishText != null;

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
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
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
    // Tokenize by whitespace and punctuation, preserving spacing
    final words = text.split(RegExp(r'(?<=\s)|(?=\s)'));
    return Wrap(
      children: words.map((token) {
        final clean = token.replaceAll(RegExp(r'[^\w\u3000-\u9fff\u4e00-\u9fff]'), '');
        if (clean.isEmpty || token.trim().isEmpty) {
          return Text(token, style: GoogleFonts.notoSans(
            fontSize: 18, color: AppTheme.textPrimary, height: 1.8,
          ));
        }
        final isSelected = _selectedWord == clean;
        final learned = provider.words.any((w) =>
          w.word.toLowerCase() == clean.toLowerCase() && w.learned);
        final tracked = provider.words.any((w) =>
          w.word.toLowerCase() == clean.toLowerCase());
        return GestureDetector(
          onTap: () => setState(() {
            _selectedWord = isSelected ? null : clean;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.accent.withOpacity(0.3)
                  : learned
                      ? AppTheme.success.withOpacity(0.15)
                      : tracked
                          ? AppTheme.warning.withOpacity(0.15)
                          : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: isSelected ? Border.all(color: AppTheme.accent, width: 1.5) : null,
            ),
            child: Text(token, style: GoogleFonts.notoSans(
              fontSize: 18,
              color: isSelected
                  ? AppTheme.accentLight
                  : learned
                      ? AppTheme.success
                      : AppTheme.textPrimary,
              height: 1.8,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            )),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWordPanel(BuildContext context, AppProvider provider, String word) {
    final existing = provider.words.firstWhere(
      (w) => w.word.toLowerCase() == word.toLowerCase(),
      orElse: () => WordEntry(languageId: -1, word: word),
    );
    final isTracked = existing.languageId != -1;

    final readingCtrl = TextEditingController(text: existing.reading ?? '');
    final defCtrl = TextEditingController(text: existing.definition ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withOpacity(0.4)),
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
              hintText: 'e.g. furigana, IPA...',
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: defCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Definition / Translation',
              hintText: 'Add your notes...',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: () async {
                await provider.addWord(
                  word: word,
                  reading: readingCtrl.text.trim().isEmpty ? null : readingCtrl.text.trim(),
                  definition: defCtrl.text.trim().isEmpty ? null : defCtrl.text.trim(),
                );
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$word" added to vocabulary')),
                );
              },
              child: Text(isTracked ? 'Update' : 'Track Word'),
            )),
            if (isTracked) ...[
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () => provider.markWordLearned(existing, !existing.learned),
                child: Text(existing.learned ? 'Unlearn' : 'Mark Learned'),
              ),
            ],
          ]),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, AppProvider provider, int idx, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.cardBg,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: idx > 0 ? () => provider.selectParagraph(idx - 1) : null,
          ),
          Expanded(child: Center(child: Text(
            'Paragraph ${idx + 1} of $total',
            style: Theme.of(context).textTheme.bodyMedium,
          ))),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
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
