# Feature map

- `qldt_login`: login/session/parser QLĐT.
- `sync`: canonical snapshot, validation/orchestration và Android daily sync.
- `schedule`: màn lịch học.
- `exams`: màn lịch thi.
- `widget`: normalized snapshot, publisher, preview và native overlay.
- `settings`: tài khoản, lệnh sync/logout qua callback.
- `theme`: theme ứng dụng duy nhất.

Dependency đi vào domain contract; không import implementation của feature khác
chỉ để truy cập SharedPreferences, WebView hoặc native channel.
