import 'package:flutter/foundation.dart';
import '../models/language.dart';
import '../models/study_text.dart';
import '../models/word_entry.dart';
import '../services/database_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  // ── State ──────────────────────────────────────────────────
  List<Language> _languages = [];
  Language? _selectedLanguage;
  List<StudyText> _texts = [];
  StudyText? _selectedText;
  List<Map<String, dynamic>> _paragraphs  = [];
  int             _selectedParagraphIndex = 0;
  List<WordEntry> _words                  = [];
  List<WordEntry> _flashcardQueue         = [];
  bool            _loading                = false;
  String? _error;
  Map<String, int> _stats = {};

  // ── Getters ────────────────────────────────────────────────
  List<Language> get languages => _languages;
  Language? get selectedLanguage => _selectedLanguage;
  List<StudyText> get texts => _texts;
  StudyText? get selectedText => _selectedText;
  List<Map<String, dynamic>> get paragraphs => _paragraphs;
  int get selectedParagraphIndex => _selectedParagraphIndex;
  Map<String, dynamic>? get currentParagraph =>
      _paragraphs.isNotEmpty ? _paragraphs[_selectedParagraphIndex] : null;
  List<WordEntry> get words => _words;
  List<WordEntry> get unlearnedWords =>
      _words.where((w) => !w.learned).toList();
  List<WordEntry> get learnedWords =>
      _words.where((w) => w.learned).toList();
  List<WordEntry> get flashcardQueue => _flashcardQueue;
  bool get loading => _loading;
  String? get error => _error;
  Map<String, int> get stats => _stats;

  // ── Init ───────────────────────────────────────────────────
  Future<void> init() async {
    _setLoading(true);
    try {
      _languages = await _db.getLanguages();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ── Language selection ─────────────────────────────────────
  Future<void> selectLanguage(Language lang) async {
    _selectedLanguage = lang;
    _selectedText = null;
    _paragraphs = [];
    _flashcardQueue = [];
    _setLoading(true);
    try {
      _texts = await _db.getTextsForLanguage(lang.id!);
      _words = await _db.getWordsForLanguage(lang.id!);
      _stats = await _db.getStats(lang.id!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
    notifyListeners();
  }

  Future<void> addLanguage(String name, String code, String? flag) async {
    final lang = Language(name: name, code: code, flagEmoji: flag);
    final id = await _db.insertLanguage(lang);
    _languages = await _db.getLanguages();
    notifyListeners();
  }

  // ── Text management ────────────────────────────────────────
  Future<void> addText(StudyText text) async {
    await _db.insertStudyText(text);
    if (_selectedLanguage != null) {
      _texts = await _db.getTextsForLanguage(_selectedLanguage!.id!);
      _stats = await _db.getStats(_selectedLanguage!.id!);
    }
    notifyListeners();
  }

  Future<void> deleteText(int id) async {
    await _db.deleteStudyText(id);
    if (_selectedText?.id == id) {
      _selectedText = null;
      _paragraphs = [];
    }
    if (_selectedLanguage != null) {
      _texts = await _db.getTextsForLanguage(_selectedLanguage!.id!);
      _stats = await _db.getStats(_selectedLanguage!.id!);
    }
    notifyListeners();
  }

  Future<void> selectText(StudyText text) async {
    _selectedText = text;
    _selectedParagraphIndex = 0;
    _paragraphs = await _db.getParagraphs(text.id!);
    notifyListeners();
  }

  void selectParagraph(int index) {
    _selectedParagraphIndex = index;
    notifyListeners();
  }

  // ── Word / vocabulary management ───────────────────────────
  Future<WordEntry> addWord({
    required String word,
    String? reading,
    String? definition,
  }) async {
    if (_selectedLanguage == null) throw Exception('No language selected');
    final entry = WordEntry(
      languageId: _selectedLanguage!.id!,
      word      : word,
      reading   : reading,
      definition: definition,
    );
    await _db.upsertWord(entry);
    _words = await _db.getWordsForLanguage(_selectedLanguage!.id!);
    _stats = await _db.getStats(_selectedLanguage!.id!);
    notifyListeners();
    return entry;
  }

  Future<void> markWordLearned(WordEntry entry, bool learned) async {
    await _db.markWordLearned(entry.id!, learned);
    _words = await _db.getWordsForLanguage(_selectedLanguage!.id!);
    _stats = await _db.getStats(_selectedLanguage!.id!);
    // Remove from flashcard queue if learned
    if (learned) {
      _flashcardQueue.removeWhere((w) => w.id == entry.id);
    }
    notifyListeners();
  }

  // ── Flashcard management ───────────────────────────────────
  void buildFlashcardQueue({bool includeAll = false}) {
    if (includeAll) {
      _flashcardQueue = List.from(_words)..shuffle();
    } else {
      _flashcardQueue = unlearnedWords.toList()..shuffle();
    }
    notifyListeners();
  }

  void buildFlashcardQueueFromParagraph(List<String> words) {
    // Find words from current paragraph that aren't learned yet
    final lower = words.map((w) => w.toLowerCase()).toSet();
    _flashcardQueue = _words
        .where((w) => lower.contains(w.word.toLowerCase()) && !w.learned)
        .toList()
      ..shuffle();
    notifyListeners();
  }

  Future<void> recordFlashcardResult(WordEntry entry, bool correct) async {
    await _db.recordFlashcardResult(entry.id!, correct);
    _words = await _db.getWordsForLanguage(_selectedLanguage!.id!);
    notifyListeners();
  }

  void removeFromQueue(WordEntry entry) {
    _flashcardQueue.removeWhere((w) => w.id == entry.id);
    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────
  void _setLoading(bool val) {
    _loading = val;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
