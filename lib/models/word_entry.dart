class WordEntry {
  final int? id;
  final int languageId;
  final String word;
  final String? reading;   // e.g. furigana for Japanese
  final String? definition;
  final bool learned;
  final int timesSeen;
  final int timesCorrect;
  final DateTime createdAt;
  final DateTime? learnedAt;

  WordEntry({
    this.id,
    required this.languageId,
    required this.word,
    this.reading,
    this.definition,
    this.learned = false,
    this.timesSeen = 0,
    this.timesCorrect = 0,
    DateTime? createdAt,
    this.learnedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory WordEntry.fromMap(Map<String, dynamic> map) {
    return WordEntry(
      id          : map['id'] as int?,
      languageId  : map['language_id'] as int,
      word        : map['word'] as String,
      reading     : map['reading'] as String?,
      definition  : map['definition'] as String?,
      learned     : (map['learned'] as int) == 1,
      timesSeen   : map['times_seen'] as int,
      timesCorrect: map['times_correct'] as int,
      createdAt   : DateTime.parse(map['created_at'] as String),
      learnedAt   : map['learned_at'] != null
          ? DateTime.parse(map['learned_at'] as String)
          :  null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'language_id'  : languageId,
      'word'         : word,
      'reading'      : reading,
      'definition'   : definition,
      'learned'      : learned ? 1 : 0,
      'times_seen'   : timesSeen,
      'times_correct': timesCorrect,
      'created_at'   : createdAt.toIso8601String(),
      'learned_at'   : learnedAt?.toIso8601String(),
    };
  }

  double get accuracy =>
      timesSeen == 0 ? 0 : timesCorrect / timesSeen;

  WordEntry copyWith({
    int? id,
    String? reading,
    String? definition,
    bool? learned,
    int? timesSeen,
    int? timesCorrect,
    DateTime? learnedAt,
  }) {
    return WordEntry(
      id          : id ?? this.id,
      languageId  : languageId,
      word        : word,
      reading     : reading ?? this.reading,
      definition  : definition ?? this.definition,
      learned     : learned ?? this.learned,
      timesSeen   : timesSeen ?? this.timesSeen,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      createdAt   : createdAt,
      learnedAt   : learnedAt ?? this.learnedAt,
    );
  }
}
