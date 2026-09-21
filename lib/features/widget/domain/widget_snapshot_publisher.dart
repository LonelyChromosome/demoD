import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';

abstract interface class WidgetSnapshotPublisher {
  Future<void> publish(ScheduleSnapshot data);

  Future<void> clear();
}
