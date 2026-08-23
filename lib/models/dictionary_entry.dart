/// Represents one entry from a Kaikki.org JSONL dictionary file.
///
/// Complex nested fields (senses, forms, sounds) are kept as raw JSON
/// strings so we don't need extra tables, but are still preserved verbatim.
class DictionaryEntry {
  final int? id;
  final int languageId;   // FK → languages.id
  final String word;      // "word" field
  final String langCode;  // "lang_code" field, e.g. "es"
  final String? pos;      // part-of-speech, e.g. "verb", "noun"
  final String? sensesJson;  // serialised JSON array of sense objects
  final String? formsJson;   // serialised JSON array of form objects
  final String? soundsJson;  // serialised JSON array of sound objects

  DictionaryEntry({
    this.id,
    required this.languageId,
    required this.word,
    required this.langCode,
    this.pos,
    this.sensesJson,
    this.formsJson,
    this.soundsJson,
  });

  factory DictionaryEntry.fromMap(Map<String, dynamic> map) {
    return DictionaryEntry(
      id: map['id'] as int?,
      languageId: map['language_id'] as int,
      word: (map['word'] ?? '').toString(),
      langCode: (map['lang_code'] ?? '').toString(),
      pos: map['pos']?.toString(),
      sensesJson: map['senses_json']?.toString(),
      formsJson: map['forms_json']?.toString(),
      soundsJson: map['sounds_json']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'language_id': languageId,
    'word': word,
    'lang_code': langCode,
    'pos': pos,
    'senses_json': sensesJson,
    'forms_json': formsJson,
    'sounds_json': soundsJson,
  };
}
