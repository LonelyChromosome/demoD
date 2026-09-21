# Feature-first architecture

## Ranh giới feature

| Feature | Sở hữu | Không được làm |
| --- | --- | --- |
| `qldt_login` | WebView, redirect/session, QLĐT parser | Ghi local snapshot hoặc gọi widget |
| `sync` | Fetch pipeline, validate, canonical snapshot, lịch 06:00 | Vẽ UI lịch/widget |
| `schedule` | Lọc và hiển thị lịch học | Đọc SharedPreferences/HTML trực tiếp |
| `exams` | Lọc và hiển thị lịch thi | Đọc SharedPreferences/HTML trực tiếp |
| `widget` | Contract tối giản, publish, preview, native widget | Login hoặc gọi mạng/QLĐT |
| `settings` | Tài khoản và callback sync/logout | Xóa cookie/storage trực tiếp |
| `theme` | `ThemeData` duy nhất | Chứa logic feature |

`app` chỉ composition, navigation state và lifecycle. `core` chỉ chứa thành
phần thực sự được từ hai feature trở lên sử dụng.

## Snapshot contracts

### Canonical app snapshot

Key: `better_phenikaa_snapshot_v1`.

Chứa display name, toàn bộ class/exam, thời điểm sync thật và source. Chỉ
`LocalScheduleRepository` đọc/ghi key này.

### Normalized widget snapshot

Key: `better_phenikaa_widget_snapshot_v1`.

Schema version 1 chỉ chứa:

- `generatedAt`
- `classes[]`: `id`, `subjectName`, `room`, `startAt`, `endAt`

Android widget chỉ đọc contract này; account, exam, cookie và response QLĐT
không đi qua ranh giới widget.

## Sync transaction order

1. `qldt_login` trả `ScheduleSnapshot` hoặc lỗi/cancel.
2. `ScheduleSyncCoordinator` validate toàn bộ record.
3. Canonical snapshot được commit.
4. Widget snapshot được publish và widget refresh.
5. Job 06:00 được bật/căn lịch.

Bước 1–2 lỗi thì cache cũ giữ nguyên. Lỗi consumer sau bước 3 không che dữ liệu
đã commit khỏi UI.

## Android background sync

`DailySyncScheduler` đặt một one-shot WorkManager job cho 06:00 local kế tiếp.
`QldtDailySyncWorker` dùng cookie WebView hiện có, tải QLĐT bằng WebView headless,
parse một lần, commit đồng thời canonical/widget snapshot, refresh widget, hủy
WebView và đặt job ngày tiếp theo.

Receiver căn lại job khi reboot, package update, đổi giờ hoặc múi giờ. Đây là
thời điểm yêu cầu; Android có quyền trì hoãn vì Doze, battery policy và network
constraint. `lastStartedAt`/`lastSuccessAt` phản ánh thời gian thực tế.

## Widget navigation

`WidgetSnapshotStore` là reader native duy nhất. Nó sắp xếp class theo thời gian
thật và tính index của ngày đã chọn. Provider neo StackView vào index đó, để
record cũ nằm phía trước và record mới nằm phía sau; `loopViews=false` giữ đúng
ranh giới thay vì vòng từ cuối về đầu.

## WebView diagnostics

Luồng login ghi provider/version, URL redirect, `load-start`, `page-visible`,
`load-stop`, lỗi main-frame và renderer termination. Readiness của JS được poll
sau `load-stop` để không phụ thuộc một timing DOM duy nhất. Hybrid composition
và hardware acceleration mặc định được giữ; không tắt acceleration toàn app và
không bỏ qua SSL/mixed-content policy. Log redirect chỉ giữ scheme/host/path;
query và fragment có thể chứa OAuth code luôn bị loại bỏ.
