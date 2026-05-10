import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/language.dart';
import '../models/study_text.dart';
import '../models/word_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    // Use FFI for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, 'StoryParse', 'story_parse.db');

    return openDatabase(
      dbPath,
      version : 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE languages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL UNIQUE,
        flag_emoji TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE study_texts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        language_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        source TEXT NOT NULL,
        source_type TEXT NOT NULL,
        content TEXT NOT NULL,
        english_content TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (language_id) REFERENCES languages (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE paragraphs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        english_content TEXT,
        position INTEGER NOT NULL,
        FOREIGN KEY (text_id) REFERENCES study_texts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE word_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        language_id INTEGER NOT NULL,
        word TEXT NOT NULL,
        reading TEXT,
        definition TEXT,
        learned INTEGER NOT NULL DEFAULT 0,
        times_seen INTEGER NOT NULL DEFAULT 0,
        times_correct INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        learned_at TEXT,
        UNIQUE(language_id, word),
        FOREIGN KEY (language_id) REFERENCES languages (id) ON DELETE CASCADE
      )
    ''');

    // Seed common languages
    final now = DateTime.now().toIso8601String();
    final langs = [
      {'name': 'Spanish',              'code': 'es', 'flag_emoji': '🇪🇸'},
      {'name': 'Japanese',             'code': 'ja', 'flag_emoji': '🇯🇵'},
      {'name': 'French',               'code': 'fr', 'flag_emoji': '🇫🇷'},
      {'name': 'German',               'code': 'de', 'flag_emoji': '🇩🇪'},
      {'name': 'Italian',              'code': 'it', 'flag_emoji': '🇮🇹'},
      {'name': 'Portuguese',           'code': 'pt', 'flag_emoji': '🇧🇷'},
      {'name': 'Chinese (Simplified)', 'code': 'zh', 'flag_emoji': '🇨🇳'},
      {'name': 'Korean',               'code': 'ko', 'flag_emoji': '🇰🇷'},
      {'name': 'Russian',              'code': 'ru', 'flag_emoji': '🇷🇺'},
    ];
    for (final lang in langs) {
      await db.insert('languages', {...lang, 'created_at': now});
    }
  }

  // ── Languages ──────────────────────────────────────────────
  Future<List<Language>> getLanguages() async {
    final db   = await database;
    final rows = await db.query('languages', orderBy: 'name ASC');
    return rows.map((r) => Language.fromMap(r)).toList();
  }

  Future<int> insertLanguage(Language lang) async {
    final db = await database;
    return db.insert('languages', lang.toMap());
  }

  Future<void> deleteLanguage(int id) async {
    final db = await database;
    await db.delete('languages', where: 'id = ?', whereArgs: [id]);
  }

  // ── Study Texts ────────────────────────────────────────────
  Future<List<StudyText>> getTextsForLanguage(int languageId) async {
    final db = await database;
    final rows = await db.query(
      'study_texts',
      where    : 'language_id = ?',
      whereArgs: [languageId],
      orderBy  : 'created_at DESC',
    );
    return rows.map((r) => StudyText.fromMap(r)).toList();
  }

  Future<int> insertStudyText(StudyText text) async {
    final db = await database;
    final id = await db.insert('study_texts', text.toMap());

    // Split into paragraphs and store
    final paras        = _splitParagraphs(text.content);
    final englishParas = text.englishContent != null
        ? _splitParagraphs(text.englishContent!)
        :  <String>[];

    for (int i = 0; i < paras.length; i++) {
      await db.insert('paragraphs', {
        'text_id'        : id,
        'content'        : paras[i],
        'english_content': i < englishParas.length ? englishParas[i] : null,
        'position'       : i,
      });
    }

    // Extract every unique word from the full content and upsert into word_entries.
    // Words with no existing definition are inserted as "unlearned" placeholders
    // so they show up coloured in the reader immediately.
    await _extractAndStoreWords(db, text.languageId, text.content);

    return id;
  }

  /// Tokenise [content] into distinct words and insert any that don't already
  /// exist in word_entries for [languageId].  Uses INSERT OR IGNORE so existing
  /// entries (with definitions / learned state) are never overwritten.
  Future<void> _extractAndStoreWords(
      Database db, int languageId, String content) async {
    // Split on anything that is not a letter, digit, apostrophe, hyphen,
    // or CJK / kana / hangul / Arabic / Cyrillic character.
    // The broad Unicode range covers Japanese, Chinese, Korean, Arabic, etc.
    final tokenPattern = RegExp(
      r"[^\w\u00C0-\u024F"         // Latin extended (accented chars)
      r"\u0400-\u04FF"             // Cyrillic
      r"\u0600-\u06FF"             // Arabic
      r"\u3000-\u303F"             // CJK punctuation (kept as delimiters)
      r"\u3040-\u309F"             // Hiragana
      r"\u30A0-\u30FF"             // Katakana
      r"\u4E00-\u9FFF"             // CJK Unified Ideographs
      r"\uAC00-\uD7AF"             // Hangul syllables
      r"'-]+"                      // apostrophe / hyphen allowed inside words
    );

    final now = DateTime.now().toIso8601String();
    final seen = <String>{};

    final tokens = content
        .split(tokenPattern)
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.length > 1)          // skip single chars / punctuation
        .where((t) => !RegExp(r'^\d+$').hasMatch(t)); // skip pure numbers

    for (final word in tokens) {
      if (seen.contains(word)) continue;
      seen.add(word);
      // INSERT OR IGNORE — never overwrite an existing entry.
      await db.rawInsert('''
        INSERT OR IGNORE INTO word_entries
          (language_id, word, reading, definition, learned,
           times_seen, times_correct, created_at)
        VALUES (?, ?, NULL, NULL, 0, 0, 0, ?)
      ''', [languageId, word, now]);
    }
  }

  Future<void> deleteStudyText(int id) async {
    final db = await database;
    await db.delete('study_texts', where: 'id = ?', whereArgs: [id]);
  }

  /// Split [content] into paragraphs.
  ///
  /// Priority order:
  ///  1. Double-newline (blank line) separated — the standard paragraph break.
  ///  2. Single-newline separated — common in plain .txt exports.
  ///  3. Fallback: treat the whole content as one paragraph.
  List<String> _splitParagraphs(String content) {
    // Normalise Windows line endings.
    final normalised = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    // Try double-newline split first.
    var paras = normalised
        .split(RegExp(r'\n\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paras.length > 1) return paras;

    // Fall back to single-newline split.
    paras = normalised
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (paras.length > 1) return paras;

    // Last resort: one big paragraph.
    final trimmed = normalised.trim();
    return trimmed.isEmpty ? [] : [trimmed];
  }

  // ── Paragraphs ─────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getParagraphs(int textId) async {
    final db = await database;
    return db.query(
      'paragraphs',
      where    : 'text_id = ?',
      whereArgs: [textId],
      orderBy  : 'position ASC',
    );
  }

  // ── Word Entries ───────────────────────────────────────────
  Future<List<WordEntry>> getWordsForLanguage(int languageId, {bool? learned}) async {
    final db = await database;
    String? where = 'language_id = ?';
    List<Object?> args = [languageId];
    if (learned != null) {
      where += ' AND learned = ?';
      args.add(learned ? 1 : 0);
    }
    final rows = await db.query(
      'word_entries',
      where    : where,
      whereArgs: args,
      orderBy  : 'word ASC',
    );
    return rows.map((r) => WordEntry.fromMap(r)).toList();
  }

  Future<WordEntry?> getWord(int languageId, String word) async {
    final db   = await database;
    final rows = await db.query(
      'word_entries',
      where    : 'language_id = ? AND word = ?',
      whereArgs: [languageId, word],
    );
    if (rows.isEmpty) return null;
    return WordEntry.fromMap(rows.first);
  }

  Future<int> upsertWord(WordEntry entry) async {
    final db       = await database;
    final existing = await getWord(entry.languageId, entry.word);
    if (existing == null) {
      return db.insert('word_entries', entry.toMap());
    } else {
      await db.update(
        'word_entries',
        entry.toMap(),
        where    : 'id = ?',
        whereArgs: [existing.id],
      );
      return existing.id!;
    }
  }

  Future<void> markWordLearned(int id, bool learned) async {
    final db = await database;
    await db.update(
      'word_entries',
      {
        'learned'   : learned ? 1                               : 0,
        'learned_at': learned ? DateTime.now().toIso8601String(): null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> recordFlashcardResult(int id, bool correct) async {
    final db = await database;
    await db.rawUpdate('''
      UPDATE word_entries
      SET times_seen = times_seen + 1,
          times_correct = times_correct + ?
      WHERE id = ?
    ''', [correct ? 1 : 0, id]);
  }

  Future<Map<String, int>> getStats(int languageId) async {
    final db = await database;
    final total = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM word_entries WHERE language_id = ?', [languageId])) ?? 0;
    final learned = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM word_entries WHERE language_id = ? AND learned = 1', [languageId])) ?? 0;
    final texts = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM study_texts WHERE language_id = ?', [languageId])) ?? 0;
    return {'total_words': total, 'learned_words': learned, 'texts': texts};
  }
}
