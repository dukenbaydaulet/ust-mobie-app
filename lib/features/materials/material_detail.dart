import 'material.dart';

/// Материалдың толық беті үшін деректер.
class MaterialDetail {
  const MaterialDetail({
    required this.material,
    required this.fullDescription,
    required this.direction,
    required this.date,
    required this.downloads,
    required this.views,
    required this.fileSize,
    required this.document,
    required this.similarCount,
    this.isSaved = false,
    this.pageCount,
    this.fileUrl,
    this.previewHtml,
  });

  final StudyMaterial material;

  /// Толық сипаттама («Толығырақ» басқанда ашылады)
  final String fullDescription;

  /// Бағыты: «Презентация», «Сабақ жоспары»...
  final String direction;

  /// Жарияланған күні, көрсетуге дайын: «18 ақпан 2025»
  final String date;
  final int downloads;
  final int views;

  /// Мысалы: «1.8 MB»
  final String fileSize;

  /// Құжаттың мазмұны — беттерге бөлінбеген, бір тұтас мәтін
  /// (Word файлды беттерге дәл бөліп көрсету мүмкін емес).
  final List<DocBlock> document;

  /// Ұқсас материалдар саны
  final int similarCount;

  /// Пайдаланушы сақтаған ба (бетбелгі)
  final bool isSaved;

  /// Құжаттың бет саны (backend білсе)
  final int? pageCount;

  /// Файлдың өзі (алдын ала көрініс жоқ PDF-ті осыдан көрсетеміз)
  final String? fileUrl;

  /// Сайттағы құжат көрінісі (backend `savehtml`, HTML). Бар болса —
  /// сайттағыдай браузерде көрсетіледі. Айналдырылмаған Word файлдарында
  /// мұнда Office Online iframe-і тұрады.
  final String? previewHtml;
}

/// Құжаттағы бір бөлік.
sealed class DocBlock {
  const DocBlock();
}

/// Ортадағы тақырып (мыс. мектеп атауы, сабақ тақырыбы)
class DocHeading extends DocBlock {
  const DocHeading(this.text);
  final String text;
}

/// Нөмірлі бөлім тақырыбы: «1. Сабақтың тақырыбы:»
class DocSection extends DocBlock {
  const DocSection(this.number, this.title);
  final int number;
  final String title;
}

/// Беттің суреті (презентация слайды, құжат беті)
class DocImage extends DocBlock {
  const DocImage(this.url);
  final String url;
}

/// Қарапайым мәтін
class DocParagraph extends DocBlock {
  const DocParagraph(this.text);
  final String text;
}

/// «Кілт: мән» жұптары (Пән: Математика, Сынып: 5 ...)
class DocFields extends DocBlock {
  const DocFields(this.fields);
  final List<(String, String)> fields;
}

/// Жазылым тарифі.
class Tariff {
  const Tariff({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    this.oldPrice,
    this.best = false,
    this.note,
  });

  final String id;
  final String title;
  final String subtitle;

  /// Теңгемен
  final int price;

  /// «/ 1 күнге», «/ 30 күн», «/ 365 күн»
  final String period;
  final int? oldPrice;

  /// «ЕҢ ТИІМДІ» белгісі
  final bool best;

  /// Ескерту мәтіні (жеңілдік мерзімі)
  final String? note;
}
