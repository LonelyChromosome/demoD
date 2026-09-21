# Better Phenikaa App 1.0

Ứng dụng Flutter xem lịch học, lịch thi và widget lịch học từ QLĐT Phenikaa.
Dữ liệu sinh viên được lưu cục bộ; dự án không dùng server, Firebase hay cơ sở
dữ liệu đám mây.

## Source chuẩn

- Repository: `LonelyChromosome/demoD`
- Baseline ứng dụng đầy đủ: `feature/full-app-implementation` tại `fd599e35`
- Phiên bản baseline: `1.0.4+5`
- `main` tại `1047955b` chỉ là skeleton `0.1.0+1`, không phải source APK 1.0.

## Kiến trúc

Code được tổ chức feature-first:

```text
lib/
  app/             # composition, navigation, lifecycle
  core/            # UI primitive và utility dùng bởi nhiều feature
  features/
    qldt_login/    # WebView/session/parser QLĐT
    sync/          # validate, local snapshot, lịch chạy 06:00
    schedule/      # màn lịch học
    exams/         # màn lịch thi
    widget/        # snapshot tối giản + preview
    settings/      # tài khoản, sync, logout
    theme/         # ThemeData duy nhất
platform/
  android_widget/  # widget Android production duy nhất
  android_sync/    # WorkManager + headless QLĐT sync
```

Mỗi feature có một implementation production. Không duy trì các bản `old/new`,
`fix2` hoặc nhánh xử lý riêng theo hãng/model thiết bị.

## Luồng dữ liệu

```text
QLĐT login/parser
       ↓
ScheduleSyncCoordinator
       ↓ validate
canonical local snapshot
       ↓ sau khi lưu thành công
normalized widget snapshot → Android widget
```

Nếu fetch hoặc parse lỗi, snapshot cũ không bị ghi đè. Widget không đăng nhập và
không gọi QLĐT; nó chỉ đọc `better_phenikaa_widget_snapshot_v1`.

## Đồng bộ nền

Sau khi có snapshot hợp lệ, Android đặt một WorkManager job cho mốc 06:00 kế
tiếp theo theo múi giờ thiết bị. Job chạy im lặng, cần mạng, lưu dữ liệu trước
rồi mới refresh widget và tự kết thúc. WorkManager có thể chạy muộn do Doze,
giới hạn pin hoặc thiếu mạng; app lưu riêng thời điểm yêu cầu, bắt đầu và thành
công thực tế, không giả timestamp 06:00. Lịch được căn lại sau reboot, cập nhật
app, đổi giờ hoặc đổi múi giờ.

## Môi trường và lệnh

- Flutter 3.47.2 / Dart 3.13
- JDK 17
- Android SDK 37

```bash
bash tool/setup.sh
bash tool/quality.sh
flutter build apk --release
```

`tool/bootstrap.sh` sinh scaffold Android/Web nếu thiếu, ghép đúng các overlay
widget/sync và chạy `flutter pub get`.

## Bảo mật

- Đăng nhập qua trang QLĐT/Microsoft chính thức trong WebView; app không tự thu
  hoặc lưu mật khẩu.
- Không commit cookie, session, token, HTML/dữ liệu sinh viên thật, keystore hay
  database thiết bị.
- Không bỏ qua lỗi SSL và không bật mixed content để chữa lỗi hiển thị.

Xem thêm: `docs/ARCHITECTURE.md`, `docs/WORKFLOW.md`,
`docs/FEATURE_FIRST_MAPPING.md`.
