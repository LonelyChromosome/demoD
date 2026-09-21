# First run

## 1. Khởi tạo môi trường

Khuyến nghị dùng Dev Container/Codespaces đã pin Flutter 3.47.2, Dart 3.13 và
JDK 17.

```bash
bash tool/bootstrap.sh
bash tool/quality.sh
```

Bootstrap sẽ sinh `android/`, `web/`, `.metadata` nếu thiếu rồi ghép hai overlay
`platform/android_widget` và `platform/android_sync`.

## 2. Quality gate

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Build thành công chưa đủ: trước release cần test đăng nhập/redirect QLĐT, giữ
cache khi mạng lỗi, lịch chạy nền, widget hai chiều, chọn ngày, logout và ít
nhất hai launcher Android có kích thước lưới khác nhau.

## 3. Quy tắc thay đổi

- Bắt đầu từ source 1.0 đã ghi trong README, không từ skeleton `main`.
- Một feature chỉ có một implementation production.
- Refactor cấu trúc không được đổi bố cục/copy/hành vi ngoài phạm vi đã nêu.
- Không thêm workaround theo tên thiết bị, hãng hoặc launcher.
- Thay đổi schema snapshot phải cập nhật cả Dart, worker Android, widget reader
  và contract test trong cùng commit.
- Không ghi thời gian đồng bộ nếu fetch, parse hoặc commit snapshot thất bại.

## 4. Release

Release APK hiện dùng debug signing theo Flutter template. Không commit keystore
hoặc `android/local.properties`.
