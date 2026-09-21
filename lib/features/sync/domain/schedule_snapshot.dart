import 'dart:convert';

/// One normalized QLDT calendar record used by schedule, exams, sync and widget.
final class ScheduleRecord {
  const new({
    required this.id,
    required this.isExam,
    required this.subjectName,
    required this.room,
    required this.startAt,
    required this.endAt,
    this.className = '',
    this.examForm = '',
    this.periodStart,
    this.periodEnd,
  });

  factory fromJson(Map<String, Object?> json) {
    return ScheduleRecord(
      id: json['id']! as String,
      isExam: json['isExam']! as bool,
      subjectName: json['subjectName']! as String,
      room: json['room']! as String,
      startAt: DateTime.parse(json['startAt']! as String),
      endAt: DateTime.parse(json['endAt']! as String),
      className: json['className'] as String? ?? '',
      examForm: json['examForm'] as String? ?? '',
      periodStart: json['periodStart'] as int?,
      periodEnd: json['periodEnd'] as int?,
    );
  }

  final String id;
  final bool isExam;
  final String subjectName;
  final String room;
  final DateTime startAt;
  final DateTime endAt;
  final String className;
  final String examForm;
  final int? periodStart;
  final int? periodEnd;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'isExam': isExam,
    'subjectName': subjectName,
    'room': room,
    'startAt': startAt.toIso8601String(),
    'endAt': endAt.toIso8601String(),
    'className': className,
    'examForm': examForm,
    'periodStart': periodStart,
    'periodEnd': periodEnd,
  };
}

/// Canonical, app-local snapshot replaced only after a successful sync.
final class ScheduleSnapshot {
  const new({
    required this.displayName,
    required this.records,
    required this.syncedAt,
    this.source = 'qldt',
  });

  factory decode(String source) {
    final raw = jsonDecode(source) as Map<String, dynamic>;
    final recordsRaw = raw['records'] as List<dynamic>? ?? const <dynamic>[];
    return ScheduleSnapshot(
      displayName: raw['displayName'] as String? ?? '',
      records: recordsRaw
          .map(
            (item) => ScheduleRecord.fromJson(
              Map<String, Object?>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList(growable: false),
      syncedAt: DateTime.parse(raw['syncedAt']! as String),
      source: raw['source'] as String? ?? 'qldt',
    );
  }

  final String displayName;
  final List<ScheduleRecord> records;
  final DateTime syncedAt;
  final String source;

  Iterable<ScheduleRecord> get classes =>
      records.where((record) => !record.isExam);

  Iterable<ScheduleRecord> get exams =>
      records.where((record) => record.isExam);

  Map<String, Object?> toJson() => <String, Object?>{
    'displayName': displayName,
    'records': records.map((record) => record.toJson()).toList(),
    'syncedAt': syncedAt.toIso8601String(),
    'source': source,
  };

  String encode() => jsonEncode(toJson());
}
