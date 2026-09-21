abstract interface class BackgroundSyncScheduler {
  Future<void> enable();

  Future<void> disable();
}
