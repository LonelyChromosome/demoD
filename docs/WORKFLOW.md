# Development workflow

## Branch

Tạo branch theo thay đổi, ví dụ:

```text
feature/feature-first-refactor
feature/qldt-login-diagnostics
feature/daily-sync
fix/widget-navigation
```

Tên branch mô tả feature, không mô tả người thực hiện và không tạo chuỗi
`fix2/fix3/old/new`.

## Mỗi checkpoint

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

Commit nhỏ theo ranh giới feature. Không trộn refactor, thay UI và workaround
thiết bị trong cùng commit.

## Regression bắt buộc

- App không có dữ liệu mở đúng login screen.
- Fetch/parse lỗi giữ snapshot cũ.
- Sync thành công lưu trước khi refresh widget.
- Logout hủy job, xóa session, local snapshot và widget snapshot.
- Widget chọn đúng ngày/index và vuốt được về record trước/lên record sau.
- Job nền không mở Activity/UI và kết thúc/destroy WebView.
- Mốc 06:00 được tính theo timezone hiện tại; receiver căn lại sau thay đổi.
- WebView không khóa redirect chỉ vào một host và không bỏ qua SSL.

## Review dependency direction

Feature UI chỉ đọc domain model/contract. Không import implementation storage,
WebView hoặc native widget trực tiếp. Mọi thay đổi snapshot schema phải có test
contract và update cả Dart/Kotlin consumer.
