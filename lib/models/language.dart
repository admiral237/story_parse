class Language {
  final int? id;
  final String name;
  final String code;
  final String? flagEmoji;
  final DateTime createdAt;

  Language({
    this.id,
    required this.name,
    required this.code,
    this.flagEmoji,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Language.fromMap(Map<String, dynamic> map) {
    return Language(
      id       : map['id'] as int?,
      name     : map['name'] as String,
      code     : map['code'] as String,
      flagEmoji: map['flag_emoji'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name'      : name,
      'code'      : code,
      'flag_emoji': flagEmoji,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get displayName => '${flagEmoji ?? ''} $name'.trim();
}
