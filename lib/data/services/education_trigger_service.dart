import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../education/education_articles.dart';

enum EducationTrigger {
  afterRegister,
  afterMedicationSkip,
  afterRedUrineReport,
  atWeek8,
  atStreak30,
  priorControl,
  weeklyRandom,
}

class EducationTriggerService {
  static const _boxName = 'delivered_education';
  static const _idsKey = 'ids';

  static Future<void> checkAndDeliverEducation({
    required EducationTrigger trigger,
    required void Function(EducationArticle article) onDeliver,
  }) async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_idsKey);
    final delivered = raw != null ? Set<String>.from(raw as List) : <String>{};

    final article = _findArticle(trigger, delivered);
    if (article == null) return;

    delivered.add(article.id);
    await box.put(_idsKey, delivered.toList());
    onDeliver(article);
  }

  static EducationArticle? _findArticle(
      EducationTrigger trigger, Set<String> delivered) {
    switch (trigger) {
      case EducationTrigger.afterRegister:
        return _getById('tentang-menular', delivered);
      case EducationTrigger.afterMedicationSkip:
        return _getById('bahaya-skip', delivered);
      case EducationTrigger.afterRedUrineReport:
        return _getById('obat-rifampicin', delivered);
      case EducationTrigger.atWeek8:
        return _getById('bahaya-walau-sehat', delivered);
      case EducationTrigger.atStreak30:
        return _getById('bahaya-tb-ro', delivered) ??
            _getRandomUnread(delivered);
      case EducationTrigger.priorControl:
        return _getById('obat-interaksi', delivered);
      case EducationTrigger.weeklyRandom:
        return _getRandomUnread(delivered);
    }
  }

  static EducationArticle? _getById(String id, Set<String> delivered) {
    if (delivered.contains(id)) return null;
    try {
      return educationArticles.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  static EducationArticle? _getRandomUnread(Set<String> delivered) {
    final unread =
        educationArticles.where((a) => !delivered.contains(a.id)).toList();
    if (unread.isEmpty) return null;
    unread.shuffle(Random());
    return unread.first;
  }

  static Future<Set<String>> getDeliveredIds() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_idsKey);
    return raw != null ? Set<String>.from(raw as List) : {};
  }

  static Future<void> reset() async {
    final box = await Hive.openBox(_boxName);
    await box.delete(_idsKey);
  }
}
