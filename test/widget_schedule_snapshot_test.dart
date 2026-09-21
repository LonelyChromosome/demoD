import 'dart:convert';

import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:better_phenikaa_schedule/features/widget/domain/widget_schedule_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('widget contract contains normalized study classes only', () {
    final source = ScheduleSnapshot(
      displayName: 'Nguyễn Minh Đạo',
      syncedAt: DateTime(2026, 9, 21, 6),
      records: <ScheduleRecord>[
        ScheduleRecord(
          id: 'exam',
          isExam: true,
          subjectName: 'Thi C++',
          room: 'A6-101',
          startAt: DateTime(2026, 9, 22, 9),
          endAt: DateTime(2026, 9, 22, 10),
        ),
        ScheduleRecord(
          id: 'class',
          isExam: false,
          subjectName: 'Lập trình mobile',
          room: 'A6-205',
          startAt: DateTime(2026, 9, 21, 9),
          endAt: DateTime(2026, 9, 21, 11),
        ),
      ],
    );

    final encoded = WidgetScheduleSnapshot.fromSchedule(source).encode();
    final json = jsonDecode(encoded) as Map<String, dynamic>;
    final classes = json['classes']! as List<dynamic>;

    expect(json['schemaVersion'], 1);
    expect(json.containsKey('displayName'), isFalse);
    expect(json.containsKey('records'), isFalse);
    expect(classes, hasLength(1));
    expect((classes.single as Map<String, dynamic>)['id'], 'class');
  });
}
