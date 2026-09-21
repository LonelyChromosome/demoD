#!/usr/bin/env bash
set -euo pipefail

fail() {
  echo "Architecture check failed: $1" >&2
  exit 1
}

[[ ! -e lib/features/qldt_intake ]] || fail 'legacy qldt_intake still exists'
[[ ! -e lib/core/contracts ]] || fail 'unused core/contracts still exists'

for required_path in \
  lib/features/qldt_login/data/qldt_parser.dart \
  lib/features/sync/application/schedule_sync_coordinator.dart \
  lib/features/sync/data/local_schedule_repository.dart \
  lib/features/widget/data/widget_publisher.dart \
  platform/android_widget/app/src/main/kotlin/vn/edu/phenikaa/better_phenikaa_schedule/WidgetSnapshotStore.kt \
  platform/android_sync/app/src/main/kotlin/vn/edu/phenikaa/better_phenikaa_schedule/QldtDailySyncWorker.kt; do
  [[ -f "${required_path}" ]] || fail "missing ${required_path}"
done

if find lib platform -type f \
    \( -iname '*old*' -o -iname '*new*' -o -iname '*fix[0-9]*' \
       -o -iname '*a-fix*' -o -iname '*b-fix*' \) | grep -q .; then
  fail 'parallel old/new/fix implementation filename found'
fi

if rg -n "shared_preferences|home_widget|flutter_inappwebview" lib/app lib/features/schedule lib/features/exams lib/features/settings; then
  fail 'presentation or app composition imports a platform data implementation'
fi

if rg -n "https?://|qldt|CookieManager|WebView|HttpURLConnection|OkHttp" platform/android_widget --glob '*.kt'; then
  fail 'Android widget must remain local-only'
fi

if rg -n "PeriodicWorkRequest|repeatInterval|24L.*HOURS" platform/android_sync --glob '*.kt'; then
  fail 'daily sync must be re-armed for local 06:00, not drift every 24 hours'
fi

if rg -n "onReceivedSslError|\.proceed\(\)|MIXED_CONTENT_ALWAYS_ALLOW|hardwareAccelerated=\"false\"" lib platform; then
  fail 'unsafe WebView workaround found'
fi

grep -q 'android:loopViews="false"' \
  platform/android_widget/app/src/main/res/layout/schedule_widget.xml \
  || fail 'widget collection must stop at chronological boundaries'
grep -q 'setDisplayedChild(R.id.widget_list, selectedIndex)' \
  platform/android_widget/app/src/main/kotlin/vn/edu/phenikaa/better_phenikaa_schedule/ScheduleWidgetProvider.kt \
  || fail 'widget must open at the real selected index'
grep -q 'flutter.better_phenikaa_widget_snapshot_v1' \
  platform/android_widget/app/src/main/kotlin/vn/edu/phenikaa/better_phenikaa_schedule/WidgetSnapshotStore.kt \
  || fail 'native widget snapshot contract is missing'
grep -q "storageKey = 'better_phenikaa_widget_snapshot_v1'" \
  lib/features/widget/data/widget_publisher.dart \
  || fail 'Dart widget snapshot contract is missing'

echo 'Architecture contracts verified.'
