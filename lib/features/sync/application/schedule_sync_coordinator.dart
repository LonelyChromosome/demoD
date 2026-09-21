import 'package:better_phenikaa_schedule/features/sync/data/local_schedule_repository.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/background_sync_scheduler.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot_repository.dart';
import 'package:better_phenikaa_schedule/features/sync/platform/daily_sync_scheduler.dart';
import 'package:better_phenikaa_schedule/features/widget/data/widget_publisher.dart';
import 'package:better_phenikaa_schedule/features/widget/domain/widget_snapshot_publisher.dart';
import 'package:flutter/foundation.dart';

typedef ScheduleFetcher = Future<ScheduleSnapshot?> Function();

/// Owns the only fetch -> validate -> persist -> widget publication pipeline.
final class ScheduleSyncCoordinator {
  const new({
    this.repository = const LocalScheduleRepository(),
    this.widgetPublisher = const WidgetPublisher(),
    this.backgroundScheduler = const DailySyncScheduler(),
  });

  final ScheduleSnapshotRepository repository;
  final WidgetSnapshotPublisher widgetPublisher;
  final BackgroundSyncScheduler backgroundScheduler;

  Future<ScheduleSnapshot?> restore() async {
    final data = await repository.read();
    if (data == null) {
      return null;
    }
    _validate(data);
    await _refreshConsumers(data);
    return data;
  }

  Future<ScheduleSnapshot?> synchronize(ScheduleFetcher fetch) async {
    final imported = await fetch();
    if (imported == null) {
      return null;
    }
    _validate(imported);

    // The canonical app snapshot is committed before any consumer is refreshed.
    // A failed fetch/parse never reaches this line, preserving the previous cache.
    await repository.replace(imported);
    await _refreshConsumers(imported);
    return imported;
  }

  Future<void> clear({required Future<void> Function() clearSession}) async {
    await _bestEffort('disable background sync', backgroundScheduler.disable);
    await _bestEffort('clear QLĐT session', clearSession);
    await _bestEffort('clear local snapshot', repository.clear);
    await _bestEffort('clear widget snapshot', widgetPublisher.clear);
  }

  static void _validate(ScheduleSnapshot data) {
    final ids = <String>{};
    for (final record in data.records) {
      if (record.id.isEmpty ||
          record.subjectName.isEmpty ||
          !record.endAt.isAfter(record.startAt) ||
          !ids.add(record.id)) {
        throw const FormatException('Dữ liệu lịch QLĐT không hợp lệ.');
      }
    }
  }

  Future<void> _refreshConsumers(ScheduleSnapshot data) async {
    await _bestEffort(
      'publish widget snapshot',
      () => widgetPublisher.publish(data),
    );
    await _bestEffort('enable background sync', backgroundScheduler.enable);
  }

  static Future<void> _bestEffort(
    String operation,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object catch (error) {
      debugPrint('Unable to $operation: $error');
    }
  }
}
