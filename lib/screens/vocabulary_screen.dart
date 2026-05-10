import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/word_entry.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'flashcard_screen.dart';

class VocabularyScreen extends StatefulWidget {
  const VocabularyScreen({super.key});

  @override
  State<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends State<VocabularyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final lang = provider.selectedLanguage;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('${lang?.name ?? ''} Vocabulary'),
            bottom: TabBar(
              controller: _tabCtrl,
              tabs: [
                Tab(text: 'Studying (${provider.unlearnedWords.length})'),
                Tab(text: 'Learned (${provider.learnedWords.length})'),
              ],
              indicatorColor: AppTheme.accent,
              labelColor: AppTheme.accent,
              unselectedLabelColor: AppTheme.textSecondary,
            ),
            actions: [
              if (provider.unlearnedWords.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.style_outlined),
                  tooltip: 'Practice all unlearned',
                  onPressed: () {
                    provider.buildFlashcardQueue();
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const FlashcardScreen(),
                    ));
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              _buildSearch(),
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildWordList(context, provider,
                        _filter(provider.unlearnedWords), false),
                    _buildWordList(context, provider,
                        _filter(provider.learnedWords), true),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<WordEntry> _filter(List<WordEntry> words) {
    if (_search.isEmpty) return words;
    final q = _search.toLowerCase();
    return words.where((w) =>
      w.word.toLowerCase().contains(q) ||
      (w.definition?.toLowerCase().contains(q) ?? false) ||
      (w.reading?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search vocabulary...',
          prefixIcon: Icon(Icons.search),
          isDense: true,
        ),
        onChanged: (v) => setState(() => _search = v),
      ),
    );
  }

  Widget _buildWordList(BuildContext context, AppProvider provider,
      List<WordEntry> words, bool isLearned) {
    if (words.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isLearned ? Icons.check_circle_outline : Icons.school_outlined,
              size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 12),
            Text(
              isLearned ? 'No learned words yet' : 'No words being studied',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: words.length,
      itemBuilder: (ctx, i) => _WordTile(
        entry: words[i],
        onToggleLearned: () => provider.markWordLearned(words[i], !words[i].learned),
        onDelete: () async {
          // Just mark as untracked by removing from list (no delete method needed for MVP)
          // In a real app, add a delete word method
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Long press to delete — coming soon')),
          );
        },
      ),
    );
  }
}

class _WordTile extends StatelessWidget {
  final WordEntry entry;
  final VoidCallback onToggleLearned;
  final VoidCallback onDelete;

  const _WordTile({
    required this.entry,
    required this.onToggleLearned,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word + reading + definition
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(entry.word,
                        style: GoogleFonts.notoSans(
                          fontSize: 20, fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (entry.reading != null && entry.reading!.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text('[${entry.reading}]',
                          style: GoogleFonts.notoSans(
                            fontSize: 14, color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (entry.definition != null && entry.definition!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(entry.definition!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if (entry.timesSeen > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Seen ${entry.timesSeen}× · ${(entry.accuracy * 100).toStringAsFixed(0)}% correct',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            // Learned toggle
            GestureDetector(
              onTap: onToggleLearned,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: entry.learned
                      ? AppTheme.success.withValues(alpha: 0.2)
                      : AppTheme.surfaceLight,
                  border: Border.all(
                    color: entry.learned ? AppTheme.success : AppTheme.divider,
                  ),
                ),
                child: Icon(
                  entry.learned ? Icons.check : Icons.circle_outlined,
                  size: 18,
                  color: entry.learned ? AppTheme.success : AppTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
