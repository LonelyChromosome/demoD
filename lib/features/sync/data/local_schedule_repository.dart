import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot.dart';
import 'package:better_phenikaa_schedule/features/sync/domain/schedule_snapshot_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The single owner of the canonical app-local schedule snapshot.
final class LocalScheduleRepository implements ScheduleSnapshotRepository {
  const new();

  static const storageKey = 'better_phenikaa_snapshot_v1';

  @override
  Future<ScheduleSnapshot?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return ScheduleSnapshot.decode(raw);
  }

  @override
  Future<void> replace(ScheduleSnapshot data) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(storageKey, data.encode());
    if (!saved) {
      throw StateError('Không thể lưu dữ liệu lịch trên thiết bị.');
    }
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(storageKey);
    if (!removed && preferences.containsKey(storageKey)) {
      throw StateError('Không thể xóa dữ liệu lịch trên thiết bị.');
    }
  }
}
