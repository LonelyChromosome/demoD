import 'package:better_phenikaa_schedule/features/sync/application/schedule_sync_coordinator.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/background_sync_scheduler.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot_repository.dart';
import 'package:better_phenikaa_schedule/features/widget/domain/widget_snapshot_publisher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'successful sync commits before publishing widget and scheduler',
    () async {
      final events = <String>[];
      final repository = _MemoryRepository(events);
      final widget = _RecordingWidgetPublisher(events);
      final scheduler = _RecordingScheduler(events);
      final coordinator = ScheduleSyncCoordinator(
        repository: repository,
        widgetPublisher: widget,
        backgroundScheduler: scheduler,
      );
      final snapshot = _snapshot('new');

      final result = await coordinator.synchronize(() async => snapshot);

      expect(result, same(snapshot));
      expect(repository.value, same(snapshot));
      expect(events, <String>['persist', 'widget', 'schedule']);
    },
  );

  test('failed fetch preserves the previous local snapshot', () async {
    final events = <String>[];
    final previous = _snapshot('previous');
    final repository = _MemoryRepository(events)..value = previous;
    final coordinator = ScheduleSyncCoordinator(
      repository: repository,
      widgetPublisher: _RecordingWidgetPublisher(events),
      backgroundScheduler: _RecordingScheduler(events),
    );

    await expectLater(
      coordinator.synchronize(() => throw StateError('network failed')),
      throwsStateError,
    );

    expect(repository.value, same(previous));
    expect(events, isEmpty);
  });

  test(
    'widget failure cannot hide a successfully committed snapshot',
    () async {
      final events = <String>[];
      final repository = _MemoryRepository(events);
      final coordinator = ScheduleSyncCoordinator(
        repository: repository,
        widgetPublisher: _RecordingWidgetPublisher(events, fail: true),
        backgroundScheduler: _RecordingScheduler(events),
      );
      final snapshot = _snapshot('saved');

      final result = await coordinator.synchronize(() async => snapshot);

      expect(result, same(snapshot));
      expect(repository.value, same(snapshot));
      expect(events, <String>['persist', 'widget', 'schedule']);
    },
  );

  test('invalid snapshot cannot replace the previous snapshot', () async {
    final events = <String>[];
    final previous = _snapshot('previous');
    final repository = _MemoryRepository(events)..value = previous;
    final coordinator = ScheduleSyncCoordinator(
      repository: repository,
      widgetPublisher: _RecordingWidgetPublisher(events),
      backgroundScheduler: _RecordingScheduler(events),
    );
    final invalid = ScheduleSnapshot(
      displayName: 'Sinh viên',
      syncedAt: DateTime(2026, 9, 21, 6),
      records: <ScheduleRecord>[
        ScheduleRecord(
          id: 'invalid',
          isExam: false,
          subjectName: 'Lập trình mobile',
          room: 'A6-205',
          startAt: DateTime(2026, 9, 21, 9),
          endAt: DateTime(2026, 9, 21, 7),
        ),
      ],
    );

    await expectLater(
      coordinator.synchronize(() async => invalid),
      throwsFormatException,
    );

    expect(repository.value, same(previous));
    expect(events, isEmpty);
  });

  test(
    'logout attempts every cleanup even when session clearing fails',
    () async {
      final events = <String>[];
      final repository = _MemoryRepository(events)..value = _snapshot('saved');
      final coordinator = ScheduleSyncCoordinator(
        repository: repository,
        widgetPublisher: _RecordingWidgetPublisher(events),
        backgroundScheduler: _RecordingScheduler(events),
      );

      await coordinator.clear(
        clearSession: () async {
          events.add('session');
          throw StateError('cookie store unavailable');
        },
      );

      expect(repository.value, isNull);
      expect(events, <String>[
        'disable',
        'session',
        'clear-local',
        'clear-widget',
      ]);
    },
  );
}

ScheduleSnapshot _snapshot(String id) {
  return ScheduleSnapshot(
    displayName: 'Nguyễn Minh Đạo',
    syncedAt: DateTime(2026, 9, 21, 6),
    records: <ScheduleRecord>[
      ScheduleRecord(
        id: id,
        isExam: false,
        subjectName: 'Lập trình mobile',
        room: 'A6-205',
        startAt: DateTime(2026, 9, 21, 7),
        endAt: DateTime(2026, 9, 21, 9),
      ),
    ],
  );
}

final class _MemoryRepository implements ScheduleSnapshotRepository {
  new(this.events);

  final List<String> events;
  ScheduleSnapshot? value;

  @override
  Future<void> clear() async {
    events.add('clear-local');
    value = null;
  }

  @override
  Future<ScheduleSnapshot?> read() async => value;

  @override
  Future<void> replace(ScheduleSnapshot data) async {
    events.add('persist');
    value = data;
  }
}

final class _RecordingWidgetPublisher implements WidgetSnapshotPublisher {
  new(this.events, {this.fail = false});

  final List<String> events;
  final bool fail;

  @override
  Future<void> clear() async {
    events.add('clear-widget');
  }

  @override
  Future<void> publish(ScheduleSnapshot data) async {
    events.add('widget');
    if (fail) {
      throw StateError('widget unavailable');
    }
  }
}

final class _RecordingScheduler implements BackgroundSyncScheduler {
  new(this.events);

  final List<String> events;

  @override
  Future<void> disable() async {
    events.add('disable');
  }

  @override
  Future<void> enable() async {
    events.add('schedule');
  }
}
