import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

enum ImportType { txt, csv, url }

class ImportResult {
  final String title;
  final String content;
  final String? englishContent;
  final ImportType type;
  final String source;

  ImportResult({
    required this.title,
    required this.content,
    this.englishContent,
    required this.type,
    required this.source,
  });
}

class TextImportService {
  /// Pick and parse a .txt file. Returns content as plain text.
  Future<ImportResult?> importTxt() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      withData         : true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file  = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;

    final content = utf8.decode(bytes, allowMalformed: true);
    final title   = file.name.replaceAll('.txt', '');

    return ImportResult(
      title  : title,
      content: content,
      // englishContent not assigned, leave null
      type   : ImportType.txt,
      source : file.name,
    );
  }

  /// Pick and parse a .csv file.
  /// Expected format:
  ///   - 1-column CSV: just the target language text per row (rows become paragraphs)
  ///   - 2-column CSV: column 1 = target language, column 2 = English translation
  Future<ImportResult?> importCsv() async {
    final result = await FilePicker.pickFiles(
      type             : FileType.custom,
      allowedExtensions: ['csv'],
      withData         : true,
    );
    if (result == null || result.files.isEmpty) return null;

    final file  = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;

    final csvString = utf8.decode(bytes, allowMalformed: true);
    // csv v8: use Csv().decode() � CsvToListConverter is still present but
    // the canonical API is now the Csv codec. Auto-detection handles both
    // comma and semicolon delimiters and \n / \r\n line endings.
    final rows = Csv(lineDelimiter: '\n').decode(csvString);

    final targetParagraphs  = <String>[];
    final englishParagraphs = <String>[];

    for (final row in rows) {
      if (row.isEmpty) continue;
      final cell0 = row[0].toString().trim();
      if (cell0.isEmpty) continue;
      targetParagraphs.add(cell0);
      if (row.length > 1) {
        englishParagraphs.add(row[1].toString().trim());
      }
    }

    final title          = file.name.replaceAll('.csv', '');
    final content        = targetParagraphs.join('\n\n');
    final englishContent = englishParagraphs.isNotEmpty
        ? englishParagraphs.join('\n\n')
        :  null;

    return ImportResult(
      title         : title,
      content       : content,
      englishContent: englishContent,
      type          : ImportType.csv,
      source        : file.name,
    );
  }

  /// Download and parse a webpage by URL.
  /// Strips HTML and extracts body text as paragraphs.
  Future<ImportResult?> importUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) throw Exception('Invalid URL');

    final response = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0 (compatible; StoryParse/1.0)',
    }).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: Could not download page');
    }

    final document = html_parser.parse(response.body);

    // Remove scripts, styles, nav, footer, header
    for (final el in document.querySelectorAll(
        'script, style, nav, footer, header, [role="navigation"]')) {
      el.remove();
    }

    // Try to find main content area
    final mainEl = document.querySelector('main, article, .content, #content, .post, #post');
    final bodyEl = mainEl ?? document.body;
    if (bodyEl == null) throw Exception('Could not parse page content');

    // Extract paragraphs
    final paras = bodyEl
        .querySelectorAll('p')
        .map((el) => el.text.trim())
        .where((t) => t.length > 30)
        .toList();

    String content;
    if (paras.isNotEmpty) {
      content = paras.join('\n\n');
    } else {
      // Fallback: full body text, split by newlines
      content = bodyEl.text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.length > 30)
          .join('\n\n');
    }

    if (content.trim().isEmpty) {
      throw Exception('No readable text found on this page');
    }

    // Derive title from <title> tag or URL
    final titleEl = document.head?.querySelector('title');
    final title   = titleEl?.text.trim() ?? uri.host;

    return ImportResult(
      title  : title,
      content: content,
      type   : ImportType.url,
      source : url,
    );
  }
}
