import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/study_text.dart';
import '../providers/app_provider.dart';
import '../services/database_service.dart';
import '../services/text_import_service.dart';
import '../theme.dart';
import 'reader_screen.dart';
import 'vocabulary_screen.dart';
import 'flashcard_screen.dart';

class TextsScreen extends StatelessWidget {
  const TextsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final lang = provider.selectedLanguage;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back to languages',
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text('${lang?.flagEmoji ?? ''} ${lang?.name ?? ''} — Texts'),
            actions: [
              IconButton(
                icon: const Icon(Icons.style_outlined),
                tooltip: 'Flashcards',
                onPressed: provider.unlearnedWords.isEmpty
                    ? null
                    : () {
                        provider.buildFlashcardQueue();
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const FlashcardScreen(),
                        ));
                      },
              ),
              IconButton(
                icon: const Icon(Icons.menu_book_outlined),
                tooltip: 'Vocabulary',
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const VocabularyScreen(),
                )),
              ),
            ],
          ),
          body: Column(
            children: [
              _buildStats(context, provider),
              const Divider(height: 1),
              Expanded(
                child: provider.texts.isEmpty
                    ? _buildEmpty(context)
                    : _buildList(context, provider),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showImportDialog(context, provider),
            icon: const Icon(Icons.add),
            label: const Text('Add Text'),
            backgroundColor: AppTheme.accent,
          ),
        );
      },
    );
  }

  Widget _buildStats(BuildContext context, AppProvider provider) {
    final s = provider.stats;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _stat(context, '${s['texts'] ?? 0}', 'Texts'),
          const SizedBox(width: 24),
          _stat(context, '${s['total_words'] ?? 0}', 'Words tracked'),
          const SizedBox(width: 24),
          _stat(context, '${s['learned_words'] ?? 0}', 'Learned'),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppTheme.accent, fontWeight: FontWeight.bold,
        )),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.article_outlined, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text('No texts yet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Import a .txt, .csv, or paste a URL',
            style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, AppProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: provider.texts.length,
      itemBuilder: (ctx, i) {
        final text = provider.texts[i];
        return _TextCard(
          text: text,
          onTap: () async {
            await provider.selectText(text);
            if (ctx.mounted) {
              Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => const ReaderScreen(),
              ));
            }
          },
          onDelete: () async {
            final confirm = await showDialog<bool>(
              context: ctx,
              builder: (d) => AlertDialog(
                backgroundColor: AppTheme.surface,
                title: const Text('Delete text?'),
                content: Text('Delete "${text.title}"? This cannot be undone.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(d, true),
                    child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
                  ),
                ],
              ),
            );
            if (confirm == true) await provider.deleteText(text.id!);
          },
        );
      },
    );
  }

  void _showImportDialog(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _ImportSheet(provider: provider),
    );
  }
}

class _TextCard extends StatelessWidget {
  final StudyText text;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _TextCard({required this.text, required this.onTap, required this.onDelete});

  IconData get _sourceIcon {
    return switch (text.sourceType) {
      'url' => Icons.link,
      'csv' => Icons.table_chart_outlined,
      _ => Icons.text_snippet_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppTheme.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_sourceIcon, color: AppTheme.accentLight, size: 22),
        ),
        title: Text(text.title, style: Theme.of(context).textTheme.titleLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(text.source, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
            ),
            Text(
              '${text.englishContent != null ? "🇺🇸 EN included · " : ""}Added ${_formatDate(text.createdAt)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppTheme.textSecondary),
          onPressed: onDelete,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _ImportSheet extends StatefulWidget {
  final AppProvider provider;
  const _ImportSheet({required this.provider});

  @override
  State<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends State<_ImportSheet> {
  final _service = TextImportService();
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24,
          MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Import Text', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_error!, style: const TextStyle(color: AppTheme.error)),
            ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            Row(children: [
              Expanded(child: _importBtn(context, Icons.text_snippet_outlined, '.TXT File', _importTxt)),
              const SizedBox(width: 12),
              Expanded(child: _importBtn(context, Icons.table_chart_outlined, '.CSV File', _importCsv)),
            ]),
            const SizedBox(height: 16),
            const Text('— or paste a webpage URL —',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'https://example.com/article',
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_outlined),
                label: const Text('Download & Import URL'),
                onPressed: _importUrl,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _importBtn(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon     : Icon(icon, size: 18),
      label    : Text(label),
    );
  }

  Future<void> _importTxt() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.importTxt();
      if (result != null) await _save(result);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _importCsv() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.importCsv();
      if (result != null) await _save(result);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _importUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _service.importUrl(url);
      if (result != null) await _save(result);
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _save(ImportResult result) async {
    final lang = widget.provider.selectedLanguage;
    if (lang == null) return;
    final text = StudyText(
      languageId    : lang.id!,
      title         : result.title,
      source        : result.source,
      sourceType    : result.type.name,
      content       : result.content,
      englishContent: result.englishContent,
    );
    await widget.provider.addText(text);
    if (mounted) Navigator.pop(context);
  }
}
