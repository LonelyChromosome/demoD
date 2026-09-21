import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:better_phenikaa_schedule/features/widget/domain/widget_schedule_snapshot.dart';
import 'package:better_phenikaa_schedule/features/widget/domain/widget_snapshot_publisher.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Publishes the normalized local-only snapshot and then refreshes the widget.
final class WidgetPublisher implements WidgetSnapshotPublisher {
  const new();

  static const storageKey = 'better_phenikaa_widget_snapshot_v1';
  static const androidProvider = 'ScheduleWidgetProvider';

  @override
  Future<void> publish(ScheduleSnapshot data) async {
    if (!_supportsHomeWidget) {
      return;
    }
    final snapshot = WidgetScheduleSnapshot.fromSchedule(data);
    await HomeWidget.saveWidgetData<String>(storageKey, snapshot.encode());
    await _refresh();
  }

  @override
  Future<void> clear() async {
    if (!_supportsHomeWidget) {
      return;
    }
    await HomeWidget.saveWidgetData<String>(storageKey, null);
    await _refresh();
  }

  Future<void> _refresh() {
    return HomeWidget.updateWidget(
      name: androidProvider,
      androidName: androidProvider,
    );
  }

  bool get _supportsHomeWidget =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
