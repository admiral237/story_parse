import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/language.dart';
import '../providers/app_provider.dart';
import '../theme.dart';
import 'texts_screen.dart';
import 'vocabulary_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: Row(children: [
              Text('Story', style: GoogleFonts.playfairDisplay(
                color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 24,
              )),
              Text(' Parse', style: GoogleFonts.playfairDisplay(
                color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 24,
              )),
            ]),
            actions: [
              IconButton(
                icon     : const Icon(Icons.add),
                tooltip  : 'Add language',
                onPressed: () => _showAddLanguageDialog(context, provider),
              ),
            ],
          ),
          body: provider.loading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, provider),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, AppProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 8),
        Expanded(
          child: provider.languages.isEmpty
              ? _buildEmpty(context)
              : _buildLanguageGrid(context, provider),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a language to study',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Container(height: 2, width: 48,
            decoration: BoxDecoration(
              color: AppTheme.accent,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageGrid(BuildContext context, AppProvider provider) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 200,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.languages.length,
      itemBuilder: (context, i) {
        return _LanguageCard(lang: provider.languages[i]);
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.language, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text('No languages yet', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text('Tap + to add a language to study',
            style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _showAddLanguageDialog(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final flagCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Add Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Language name', hintText: 'e.g. Spanish')),
            const SizedBox(height: 12),
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Language code', hintText: 'e.g. es')),
            const SizedBox(height: 12),
            TextField(controller: flagCtrl, decoration: const InputDecoration(labelText: 'Flag emoji', hintText: 'e.g. 🇪🇸')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && codeCtrl.text.isNotEmpty) {
                await provider.addLanguage(nameCtrl.text.trim(), codeCtrl.text.trim(), flagCtrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final Language lang;
  const _LanguageCard({required this.lang});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return GestureDetector(
      onTap: () async {
        await provider.selectLanguage(lang);
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => const TextsScreen(),
          ));
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(lang.flagEmoji ?? '🌐',
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 10),
            Text(lang.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
