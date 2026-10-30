/// Оқу-әдістемелік материал (тізімдегі бір карточка).
class StudyMaterial {
  const StudyMaterial({
    required this.id,
    required this.title,
    required this.description,
    required this.fileType,
    this.grade,
    this.subject,
    this.slug,
  });

  final int id;
  final String title;
  final String description;

  /// Файл түрі: doc, ppt, pdf, ...
  final String fileType;

  /// Мысалы: "6-сынып"
  final String? grade;

  /// Мысалы: "Қазақ әдебиеті"
  final String? subject;

  /// Сайттағы атаудың латынша нұсқасы (`lat_title`) — материал бетін ашу үшін
  final String? slug;
}

/// Сүзгідегі бір нұсқа (пән, бағыт немесе сынып) және оның материал саны.
class FilterOption {
  const FilterOption({
    required this.id,
    required this.name,
    this.count,
    this.type = FilterOptionType.regular,
  });

  final String id;
  final String name;

  /// Материал саны; null — белгісіз (көрсетілмейді)
  final int? count;

  /// Сыныптар терезесінде қай жерде шығатыны
  final FilterOptionType type;
}

/// Сынып нұсқасының түрі: «Мектепке дейінгі» мен «Басқа» торға кірмей,
/// толық енді бөлек жолмен шығады.
enum FilterOptionType { regular, preschool, other }

/// Таңдалған сүзгілер.
class MaterialFilters {
  const MaterialFilters({
    this.subjects = const {},
    this.directions = const {},
    this.grades = const {},
  });

  final Set<String> subjects;
  final Set<String> directions;
  final Set<String> grades;

  bool get isEmpty => subjects.isEmpty && directions.isEmpty && grades.isEmpty;

  MaterialFilters copyWith({
    Set<String>? subjects,
    Set<String>? directions,
    Set<String>? grades,
  }) {
    return MaterialFilters(
      subjects: subjects ?? this.subjects,
      directions: directions ?? this.directions,
      grades: grades ?? this.grades,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is MaterialFilters &&
      _setEq(other.subjects, subjects) &&
      _setEq(other.directions, directions) &&
      _setEq(other.grades, grades);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(subjects),
    Object.hashAllUnordered(directions),
    Object.hashAllUnordered(grades),
  );

  static bool _setEq(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}

/// Бір бет нәтиже.
class MaterialsPage {
  const MaterialsPage({
    required this.items,
    required this.total,
    required this.hasMore,
  });

  final List<StudyMaterial> items;
  final int total;
  final bool hasMore;
}

/// Іздеу кезіндегі ұсыныс.
class SearchSuggestion {
  const SearchSuggestion({
    required this.text,
    required this.tag,
    this.fromHistory = false,
  });

  final String text;

  /// Мысалы: "Пән", "Курс / Бағыт", "ҚМЖ / Сабақ"
  final String tag;
  final bool fromHistory;
}

/// Ұсынылатын санат (іздеу бетіндегі тор).
class MaterialCategory {
  const MaterialCategory({
    required this.subjectId,
    required this.name,
    required this.countLabel,
  });

  /// Басқанда осы пән бойынша сүзіледі
  final String subjectId;
  final String name;

  /// Мысалы: "14,200+ материал"
  final String countLabel;
}
