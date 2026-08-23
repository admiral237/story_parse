import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/dictionary_import_service.dart';
import '../theme.dart';

class DictionaryScreen extends StatefulWidget {
  const DictionaryScreen({super.key});

  @override
  State<DictionaryScreen> createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _importService = DictionaryImportService();
  String? _error;
  bool _done = false;
  int _finalCount = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final lang = provider.selectedLanguage;
        final dictCount = provider.stats['dict_words'] ?? 0;
        final importing = provider.dictImporting;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Back',
              onPressed: importing ? null : () => Navigator.of(context).pop(),
            ),
            title: Text('${lang?.flagEmoji ?? ''} Dictionary'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildInfoCard(context, lang?.name ?? '', lang?.code ?? '',
                  dictCount, importing),
              const SizedBox(height: 20),
              if (_error != null) _buildError(),
              if (importing)
                _buildProgress(provider)
              else if (_done)
                _buildSuccess()
              else ...[
                _buildInstructions(context, lang?.name ?? '', lang?.code ?? ''),
                const SizedBox(height: 20),
                _buildImportButton(context, provider, lang?.code ?? ''),
                if (dictCount > 0) ...[
                  const SizedBox(height: 12),
                  _buildClearButton(context, provider),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BuildContext context, String langName, String langCode,
      int dictCount, bool importing) {
    final hasDict = dictCount > 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDict ? AppTheme.success.withValues(alpha: 0.4) : AppTheme.divider,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: hasDict
                  ? AppTheme.success.withValues(alpha: 0.15)
                  : AppTheme.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasDict ? Icons.library_books : Icons.library_books_outlined,
              color: hasDict ? AppTheme.success : AppTheme.accentLight,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDict ? '$langName Dictionary Loaded' : 'No Dictionary Loaded',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: hasDict ? AppTheme.success : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasDict
                      ? '${_fmt(dictCount)} entries (lang_code: "$langCode")'
                      : 'Import a Kaikki.org JSONL file to enable in-reader lookups',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions(
      BuildContext context, String langName, String langCode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How to get the dictionary file',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15)),
          const SizedBox(height: 10),
          _step(context, '1',
              'Go to kaikki.org and navigate to the $langName dictionary download page.'),
          _step(context, '2',
              'Download the raw JSONL file (e.g. kaikki.org-dictionary-$langName.jsonl). '
              'These files are large — allow time to download.'),
          _step(context, '3',
              'Tap "Import Dictionary File" below and select the .jsonl file. '
              'Only entries with lang_code = "$langCode" will be imported.'),
          const SizedBox(height: 4),
          Text(
            'Note: Import may take several minutes for large files. '
            'Keep the app in the foreground.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            margin: const EdgeInsets.only(top: 1, right: 10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentLight),
              ),
            ),
          ),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildImportButton(
      BuildContext context, AppProvider provider, String langCode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.upload_file),
        label: const Text('Import Dictionary File (.jsonl)'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _startImport(context, provider, langCode),
      ),
    );
  }

  Widget _buildClearButton(BuildContext context, AppProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.delete_outline, color: AppTheme.error),
        label: const Text('Clear Dictionary',
            style: TextStyle(color: AppTheme.error)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppTheme.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _confirmClear(context, provider),
      ),
    );
  }

  Widget _buildProgress(AppProvider provider) {
    final lines = provider.dictImportLines;
    final matched = provider.dictImportMatched;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Importing dictionary…',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${_fmt(lines)} lines scanned',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('${_fmt(matched)} entries matched',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.accentLight, fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 16),
          Text(
            'Keep the app in the foreground.\nThis may take several minutes for large files.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 12, fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppTheme.success, size: 48),
          const SizedBox(height: 12),
          Text('Import Complete!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${_fmt(_finalCount)} dictionary entries imported.\n'
            'Words in the reader will now show definitions automatically.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Texts'),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!,
                style: const TextStyle(color: AppTheme.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Future<void> _startImport(
      BuildContext context, AppProvider provider, String langCode) async {
    setState(() { _error = null; _done = false; });

    DictionaryFileResult? fileResult;
    try {
      fileResult = await _importService.pickDictionaryFile();
    } catch (e) {
      setState(() => _error = 'Could not open file picker: $e');
      return;
    }
    if (fileResult == null) return; // user cancelled

    await provider.importDictionary(
      filePath: fileResult.filePath,
      fileBytes: fileResult.bytes,
      langCode: langCode,
    );

    if (provider.error != null) {
      setState(() => _error = provider.error);
      provider.clearError();
    } else {
      setState(() {
        _done = true;
        _finalCount = provider.stats['dict_words'] ?? 0;
      });
    }
  }

  Future<void> _confirmClear(
      BuildContext context, AppProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Clear dictionary?'),
        content: const Text(
            'All dictionary entries for this language will be deleted. '
            'Your vocabulary progress is not affected.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.clearDictionary();
      setState(() { _done = false; _error = null; });
    }
  }

  String _fmt(int n) {
    // Simple thousands separator.
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
