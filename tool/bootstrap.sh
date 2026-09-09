#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo 'Flutter not found. Use the Dev Container or install Flutter 3.47.2.' >&2
  exit 1
fi

required_flutter='3.47.2'
current_flutter="$(flutter --version | head -n 1 | awk '{print $2}')"
if [[ "${current_flutter}" != "${required_flutter}" ]]; then
  echo "Expected Flutter ${required_flutter}, found ${current_flutter}." >&2
  exit 1
fi

needs_android=false
needs_web=false
[[ -f android/app/build.gradle.kts || -f android/app/build.gradle ]] || needs_android=true
[[ -f web/index.html ]] || needs_web=true

if [[ "${needs_android}" == true || "${needs_web}" == true ]]; then
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' EXIT

  flutter create \
    --platforms=android,web \
    --org vn.edu.phenikaa \
    --project-name better_phenikaa_schedule \
    "${tmp_dir}/scaffold"

  if [[ "${needs_android}" == true ]]; then
    rm -rf android
    cp -R "${tmp_dir}/scaffold/android" ./android
  fi

  if [[ "${needs_web}" == true ]]; then
    rm -rf web
    cp -R "${tmp_dir}/scaffold/web" ./web
  fi

  if [[ ! -f .metadata ]]; then
    cp "${tmp_dir}/scaffold/.metadata" ./.metadata
  fi
fi

if [[ -d platform/android_widget/app ]]; then
  cp -R platform/android_widget/app/. android/app/

  python3 - <<'PY'
from pathlib import Path

manifest = Path('android/app/src/main/AndroidManifest.xml')
text = manifest.read_text()

permission = '    <uses-permission android:name="android.permission.INTERNET" />\n'
if 'android.permission.INTERNET' not in text:
    text = text.replace(
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n',
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n' + permission,
        1,
    )

receiver = '''        <receiver
            android:name=".ScheduleWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/schedule_widget_info" />
        </receiver>
'''
if '.ScheduleWidgetProvider' not in text:
    text = text.replace('    </application>', receiver + '    </application>', 1)

manifest.write_text(text)
PY
fi

flutter pub get

echo 'Bootstrap complete.'
