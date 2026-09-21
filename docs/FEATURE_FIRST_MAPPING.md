# DemoD 1.0 feature-first mapping

## Authoritative baseline

- Repository: `LonelyChromosome/demoD`
- Source branch: `feature/full-app-implementation`
- Baseline commit: `fd599e35d6e2cffddddef09aea491d920b4e6b76`
- Baseline version: `1.0.4+5`
- `main` at `1047955b` is the `0.1.0+1` skeleton, not the app baseline.

## Completed ownership map

| Production concern | Owner |
| --- | --- |
| App composition, navigation, lifecycle | `lib/app` |
| Shared UI primitives and date formatting | `lib/core` |
| QLĐT WebView, session and parser | `lib/features/qldt_login` |
| Normalized calendar domain, validation, persistence and scheduling contract | `lib/features/sync` |
| Study-schedule presentation | `lib/features/schedule` |
| Exam presentation | `lib/features/exams` |
| Minimal widget contract and publication | `lib/features/widget` |
| Account/settings presentation | `lib/features/settings` |
| App theme | `lib/features/theme` |
| Android widget runtime | `platform/android_widget` |
| Android 06:00 worker and rescheduling | `platform/android_sync` |

The former `lib/features/qldt_intake` and unused `lib/core/contracts` trees were
removed. Schedule, exam, account, theme, persistence and widget publication no
longer live in the root app widget.

## Dependency direction

```text
app
  -> qldt_login
  -> sync
  -> schedule
  -> exams
  -> widget
  -> theme
  -> settings

qldt_login -> sync/domain
sync -> local snapshot + background scheduler + widget publication contract
schedule -> sync/domain
exams -> sync/domain
widget -> sync/domain
settings -> callbacks supplied by app composition
```

`core` contains only utilities or presentation primitives shared by multiple
features. It does not own QLĐT, schedule, exam, sync or widget business logic.

## Data ownership

- `ScheduleSyncCoordinator` is the foreground fetch → validate → persist →
  publish pipeline.
- `LocalScheduleRepository` is the only Dart reader/writer for the canonical app
  snapshot.
- `WidgetPublisher` emits the versioned, class-only widget snapshot.
- `WidgetSnapshotStore` is the only Android widget reader and never opens a
  session or network connection.
- `QldtDailySyncWorker` is the single silent Android background path. It commits
  the canonical and widget snapshots together before refreshing the widget.

The CI architecture gate verifies these boundaries and rejects legacy feature
paths, parallel implementation suffixes, widget networking, periodic 24-hour
work, SSL bypasses and app-wide hardware-acceleration workarounds.
