import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';

abstract interface class ScheduleSnapshotRepository {
  Future<ScheduleSnapshot?> read();

  Future<void> replace(ScheduleSnapshot data);

  Future<void> clear();
}
