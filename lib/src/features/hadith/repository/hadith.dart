class Hadith {
  const Hadith({
    required this.id,
    required this.title,
    required this.category,
    required this.source,
    required this.textUz,
    required this.textRu,
    required this.textEn,
    required this.order,
    this.titleEn = '',
    this.titleRu = '',
    this.categoryEn = '',
    this.categoryRu = '',
    this.sourceEn = '',
    this.sourceRu = '',
  });

  final String id, title, category, source, textUz, textRu, textEn;
  final num order;
  final String titleEn, titleRu, categoryEn, categoryRu, sourceEn, sourceRu;

  String _localized(String base, String ru, String en, String language) {
    final value = language == 'ru'
        ? ru
        : language == 'en'
        ? en
        : base;
    return value.isNotEmpty ? value : base;
  }

  String titleFor(String language) =>
      _localized(title, titleRu, titleEn, language);
  String categoryFor(String language) =>
      _localized(category, categoryRu, categoryEn, language);
  String sourceFor(String language) =>
      _localized(source, sourceRu, sourceEn, language);

  Map<String, dynamic> toMap() => {
    'title': title,
    'titleEn': titleEn,
    'titleRu': titleRu,
    'category': category,
    'categoryEn': categoryEn,
    'categoryRu': categoryRu,
    'source': source,
    'sourceEn': sourceEn,
    'sourceRu': sourceRu,
    'textUz': textUz,
    'textRu': textRu,
    'textEn': textEn,
    'order': order,
  };

  factory Hadith.fromMap(String id, Map<String, dynamic> data) {
    String text(String key) =>
        data[key] is String ? (data[key] as String).trim() : '';
    final rawOrder = data['order'];
    final parsedOrder = rawOrder is num
        ? rawOrder
        : num.tryParse(rawOrder?.toString() ?? '');
    return Hadith(
      id: id,
      title: text('title'),
      titleEn: text('titleEn'),
      titleRu: text('titleRu'),
      categoryEn: text('categoryEn'),
      categoryRu: text('categoryRu'),
      sourceEn: text('sourceEn'),
      sourceRu: text('sourceRu'),
      category: text('category'),
      source: text('source'),
      textUz: text('textUz'),
      textRu: text('textRu'),
      textEn: text('textEn'),
      order: parsedOrder != null && parsedOrder.isFinite
          ? parsedOrder
          : double.maxFinite,
    );
  }

  bool get hasText =>
      textUz.isNotEmpty || textRu.isNotEmpty || textEn.isNotEmpty;

  String textFor(String language) {
    final preferred = switch (language) {
      'ru' => textRu,
      'en' => textEn,
      _ => textUz,
    };
    if (preferred.isNotEmpty) return preferred;
    for (final text in [textUz, textRu, textEn]) {
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
