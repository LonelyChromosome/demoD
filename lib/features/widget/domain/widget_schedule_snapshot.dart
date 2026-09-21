import 'dart:convert';

import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';

/// Stable, minimal contract consumed by the native Android widget.
///
/// It deliberately contains study classes only. The widget never reads the
/// app's account, exam, session or QLĐT payload.
final class WidgetScheduleSnapshot {
  const new({required this.generatedAt, required this.classes});

  factory fromSchedule(ScheduleSnapshot data) {
    final classes =
        data.classes.map(WidgetScheduleClass.fromRecord).toList(growable: false)
          ..sort((a, b) => a.startAt.compareTo(b.startAt));
    return WidgetScheduleSnapshot(generatedAt: data.syncedAt, classes: classes);
  }

  final DateTime generatedAt;
  final List<WidgetScheduleClass> classes;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': 1,
    'generatedAt': generatedAt.toIso8601String(),
    'classes': classes.map((item) => item.toJson()).toList(growable: false),
  };

  String encode() => jsonEncode(toJson());
}

final class WidgetScheduleClass {
  const new({
    required this.id,
    required this.subjectName,
    required this.room,
    required this.startAt,
    required this.endAt,
  });

  factory fromRecord(ScheduleRecord record) {
    return WidgetScheduleClass(
      id: record.id,
      subjectName: record.subjectName,
      room: record.room,
      startAt: record.startAt,
      endAt: record.endAt,
    );
  }

  final String id;
  final String subjectName;
  final String room;
  final DateTime startAt;
  final DateTime endAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'subjectName': subjectName,
    'room': room,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt.toIso8601String(),
  };
}
