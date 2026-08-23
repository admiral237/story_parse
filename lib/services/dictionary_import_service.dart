import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Result returned after picking a file — we hand the path/bytes back to
/// the caller so the actual DB work can run on an isolate.
class DictionaryFileResult {
  final String fileName;
  final String filePath;   // absolute path (desktop/mobile)
  final Uint8List? bytes;  // populated only on web or when path unavailable

  DictionaryFileResult({
    required this.fileName,
    required this.filePath,
    this.bytes,
  });
}

/// Parsed line from the JSONL file, ready for bulk insert.
class ParsedDictionaryEntry {
  final String word;
  final String langCode;
  final String? pos;
  final String? sensesJson;
  final String? formsJson;
  final String? soundsJson;

  ParsedDictionaryEntry({
    required this.word,
    required this.langCode,
    this.pos,
    this.sensesJson,
    this.formsJson,
    this.soundsJson,
  });
}

class DictionaryImportService {
  /// Show the file picker and return the selected .jsonl file.
  /// Returns null if the user cancelled.
  Future<DictionaryFileResult?> pickDictionaryFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jsonl', 'json'],
      withData: kIsWeb,         // need bytes on web; use path on desktop
      withReadStream: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final path = file.path;

    if (path == null || path.isEmpty) {
      // Web fallback — use bytes
      final bytes = file.bytes;
      if (bytes == null) return null;
      return DictionaryFileResult(
        fileName: file.name,
        filePath: '',
        bytes: bytes,
      );
    }
    return DictionaryFileResult(
      fileName: file.name,
      filePath: path,
    );
  }

  /// Parse the JSONL file, filtering to [targetLangCode], and yield parsed
  /// entries in batches.  Calls [onProgress] with (linesRead, matchedSoFar)
  /// so the UI can display a live counter.
  ///
  /// Runs on the calling isolate — callers should use [compute] or run from
  /// a non-UI context if the file is very large.
  Stream<List<ParsedDictionaryEntry>> parseBatched({
    required String targetLangCode,
    required String filePath,
    Uint8List? fileBytes,
    int batchSize = 500,
    void Function(int linesRead, int matched)? onProgress,
  }) async* {
    // Build a stream of lines from either file bytes or path.
    final Stream<String> lines;
    if (fileBytes != null && fileBytes.isNotEmpty) {
      final content = utf8.decode(fileBytes, allowMalformed: true);
      lines = Stream.fromIterable(content.split('\n'));
    } else {
      lines = File(filePath)
          .openRead()
          .transform(utf8.decoder)
          .transform(const LineSplitter());
    }

    final batch = <ParsedDictionaryEntry>[];
    int linesRead = 0;
    int matched = 0;

    await for (final line in lines) {
      final trimmed = line.trim();
      linesRead++;

      if (trimmed.isEmpty) continue;

      // Quick pre-check before full JSON decode — avoids parsing lines that
      // clearly don't match the target language code.
      if (!trimmed.contains('"$targetLangCode"')) continue;

      Map<String, dynamic> obj;
      try {
        obj = jsonDecode(trimmed) as Map<String, dynamic>;
      } catch (_) {
        continue; // skip malformed lines
      }

      final langCode = obj['lang_code']?.toString() ?? '';
      if (langCode != targetLangCode) continue;

      final word = obj['word']?.toString() ?? '';
      if (word.isEmpty) continue;

      final pos = obj['pos']?.toString();

      // Serialise nested arrays back to JSON strings for storage.
      final senses = obj['senses'];
      final forms = obj['forms'];
      final sounds = obj['sounds'];

      batch.add(ParsedDictionaryEntry(
        word: word,
        langCode: langCode,
        pos: pos,
        sensesJson: senses != null ? jsonEncode(senses) : null,
        formsJson: forms != null ? jsonEncode(forms) : null,
        soundsJson: sounds != null ? jsonEncode(sounds) : null,
      ));
      matched++;

      if (batch.length >= batchSize) {
        onProgress?.call(linesRead, matched);
        yield List.from(batch);
        batch.clear();
      }

      // Yield control every ~5k lines so UI stays responsive.
      if (linesRead % 5000 == 0) {
        onProgress?.call(linesRead, matched);
        await Future.delayed(Duration.zero);
      }
    }

    if (batch.isNotEmpty) {
      onProgress?.call(linesRead, matched);
      yield List.from(batch);
    }
  }

  /// Extract just the first English gloss from a serialised senses JSON string.
  /// Returns null if no gloss found.
  static String? firstGloss(String? sensesJson) {
    if (sensesJson == null) return null;
    try {
      final senses = jsonDecode(sensesJson) as List<dynamic>;
      for (final sense in senses) {
        final glosses = (sense as Map<String, dynamic>)['glosses'];
        if (glosses is List && glosses.isNotEmpty) {
          return glosses.first.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  /// Extract all glosses, one per sense, from a serialised senses JSON string.
  static List<String> allGlosses(String? sensesJson) {
    if (sensesJson == null) return [];
    final result = <String>[];
    try {
      final senses = jsonDecode(sensesJson) as List<dynamic>;
      for (final sense in senses) {
        final glosses = (sense as Map<String, dynamic>)['glosses'];
        if (glosses is List) {
          for (final g in glosses) {
            final s = g.toString();
            if (s.isNotEmpty) result.add(s);
          }
        }
      }
    } catch (_) {}
    return result;
  }
}
