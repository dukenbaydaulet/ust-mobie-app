import 'package:flutter/material.dart';

/// Қосымшаның мәтін стильдері — дизайннан (Figma) алынған.
/// Жаңа экран жасағанда дизайндағы мәтінге ең жақын стильді осы жерден таңдаймыз.
///
/// Ереже: тақырыптар — Arimo, қалған мәтін — Inter.
class AppText {
  // ---- Түстер ----
  static const ink = Color(0xFF0D1C2F); // негізгі мәтін
  static const muted = Color(0xFF64748B); // сұр мәтін, placeholder
  static const slate = Color(0xFF424654); // сүзгі батырмасы, пән тегі
  static const link = Color(0xFF004BC0); // сілтеме, белсенді мәтін

  static const _arimo = 'Arimo';
  static const _inter = 'Inter';

  // ---- Arimo (тақырыптар) ----

  /// Бет тақырыбы: «Оқу әдістемелік материалдар» — Arimo 600 22/22.5
  static const pageTitle = TextStyle(
    fontFamily: _arimo,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 22.5 / 22,
    letterSpacing: 0,
    color: ink,
  );

  /// Бос күй тақырыбы: «Ешнәрсе табылмады» — Arimo 600 22/28
  static const emptyTitle = TextStyle(
    fontFamily: _arimo,
    fontWeight: FontWeight.w600,
    fontSize: 22,
    height: 28 / 22,
    letterSpacing: 0,
    color: ink,
  );

  /// Бөлім тақырыбы: «Соңғы іздеулер», «Танымал сұраулар» — Arimo 600 18/24
  static const sectionTitle = TextStyle(
    fontFamily: _arimo,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 24 / 18,
    letterSpacing: 0,
    color: ink,
  );

  /// Карточка тақырыбы: материал атауы — Arimo 600 16/100%
  static const cardTitle = TextStyle(
    fontFamily: _arimo,
    fontWeight: FontWeight.w600,
    fontSize: 16,
    height: 1,
    letterSpacing: 0,
    color: ink,
  );

  /// Кішi тақырып: «N материал табылды», «Іздеу бойынша кеңестер» — Arimo 600 14/18
  static const label = TextStyle(
    fontFamily: _arimo,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 18 / 14,
    letterSpacing: 0,
    color: ink,
  );

  /// Тізім жолы: соңғы іздеу мәтіні — Arimo 400 14/20
  static const listItem = TextStyle(
    fontFamily: _arimo,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 20 / 14,
    letterSpacing: 0,
    color: ink,
  );

  /// Санат атауы: «Бастауыш сынып» — Arimo 400 14/18
  static const tileTitle = TextStyle(
    fontFamily: _arimo,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 18 / 14,
    letterSpacing: 0,
    color: ink,
  );

  // ---- Inter (негізгі мәтін) ----

  /// Іздеу өрісіне жазылған мәтін — Inter 400 15/20, -0.38
  static const input = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 20 / 15,
    letterSpacing: -0.38,
    color: ink,
  );

  /// Placeholder — Inter 400 14/100%
  static const placeholder = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1,
    letterSpacing: 0,
    color: muted,
  );

  /// Сүзгі батырмасы: «Пән», «Бағыт» — Inter 600 15/16
  static const filterChip = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 16 / 15,
    letterSpacing: 0,
    color: slate,
  );

  /// Батырма-сілтеме: «Болдырмау» — Inter 600 14/18
  static const action = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 18 / 14,
    letterSpacing: 0,
    color: link,
  );

  /// Беттің жоғарғы жолағындағы атау: «Материал» — Inter 600 14/18
  static const topBarTitle = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 18 / 14,
    letterSpacing: 0,
    color: ink,
  );

  /// Кіші сілтеме: «Тазалау» — Inter 400 12/16
  static const smallLink = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    color: link,
  );

  /// Чип: «Математика 5 сынып» — Inter 400 12/16
  static const chip = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    color: ink,
  );

  /// Ерекшеленген чип: «ҚМЖ 2024–2025» — Inter 600 12/16
  static const chipStrong = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w600,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    color: Color(0xFF2C1600),
  );

  /// Кіші тег: «6-сынып», «Қазақ әдебиеті» — Inter 600 10/12
  static const tag = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w600,
    fontSize: 10,
    height: 12 / 10,
    letterSpacing: 0,
  );

  /// Сипаттама: карточка мәтіні, бос күй түсіндірмесі — Inter 400 12/100%
  static const description = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1,
    letterSpacing: 0,
    color: muted,
  );

  /// Қосымша мәтін: санат саны — Inter 400 12/16
  static const caption = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0,
    color: muted,
  );

  /// Кеңес мәтіні — Inter 400 12/16.5
  static const hintText = TextStyle(
    fontFamily: _inter,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16.5 / 12,
    letterSpacing: 0,
    color: muted,
  );
}
