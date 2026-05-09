class StudyText {
  final int? id;
  final int languageId;
  final String title;
  final String source;
  final String sourceType;  // 'txt', 'csv', 'url'
  final String content;
  final String? englishContent;
  final DateTime createdAt;

  StudyText({
    this.id,
    required this.languageId,
    required this.title,
    required this.source,
    required this.sourceType,
    required this.content,
    this.englishContent,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StudyText.fromMap(Map<String, dynamic> map) {
    return StudyText(
      id            : map['id'] as int?,
      languageId    : map['language_id'] as int,
      title         : map['title'] as String,
      source        : map['source'] as String,
      sourceType    : map['source_type'] as String,
      content       : map['content'] as String,
      englishContent: map['english_content'] as String?,
      createdAt     : DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'language_id'    : languageId,
      'title'          : title,
      'source'         : source,
      'source_type'    : sourceType,
      'content'        : content,
      'english_content': englishContent,
      'created_at'     : createdAt.toIso8601String(),
    };
  }
}
