import 'package:better_phenikaa_schedule/features/sync/domain/background_sync_scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Android bridge for the one-shot work that is re-armed for the next local
/// 06:00 after each run. Android may delay execution because of Doze, battery
/// policy or network constraints; the native worker records real run times.
final class DailySyncScheduler implements BackgroundSyncScheduler {
  const new();

  static const _channel = MethodChannel('better_phenikaa/daily_sync');

  @override
  Future<void> enable() async {
    if (!_isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('enable');
  }

  @override
  Future<void> disable() async {
    if (!_isAndroid) {
      return;
    }
    await _channel.invokeMethod<void>('disable');
  }

  Future<Map<String, Object?>> status() async {
    if (!_isAndroid) {
      return const <String, Object?>{};
    }
    final value = await _channel.invokeMapMethod<String, Object?>('status');
    return value ?? const <String, Object?>{};
  }

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
}
