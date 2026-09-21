import 'package:better_phenikaa_schedule/features/sync/data/local_schedule_repository.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('writes, reads, and clears the canonical local snapshot', () async {
    const repository = LocalScheduleRepository();
    final snapshot = ScheduleSnapshot(
      displayName: 'Nguyễn Minh Đạo',
      syncedAt: DateTime(2026, 9, 21, 6),
      records: <ScheduleRecord>[
        ScheduleRecord(
          id: 'class-one',
          isExam: false,
          subjectName: 'Lập trình mobile',
          room: 'A6-205',
          startAt: DateTime(2026, 9, 21, 7),
          endAt: DateTime(2026, 9, 21, 9),
        ),
      ],
    );

    await repository.replace(snapshot);

    final restored = await repository.read();
    expect(restored?.displayName, snapshot.displayName);
    expect(restored?.records.single.id, 'class-one');

    await repository.clear();
    expect(await repository.read(), isNull);
  });
}
