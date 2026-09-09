# Better Phenikaa Web Bridge

Chrome bridge dùng cho **web demo** để đọc lịch từ một tab QLĐT đã đăng nhập, trong khi mật khẩu vẫn chỉ được nhập trên Microsoft/QLĐT chính thức.

## Cài một lần để test web thật

1. Tải/clone repository `demoD` về máy và checkout `feature/full-app-implementation`.
2. Mở `chrome://extensions`.
3. Bật **Developer mode**.
4. Chọn **Load unpacked**.
5. Chọn đúng thư mục `tools/web_qldt_bridge`.
6. Tải lại `https://lonelychromosome.github.io/demoD/`.

Trong Better Phenikaa App, bấm **Đăng nhập QLĐT (Microsoft)**. Khi hộp kết nối báo `Better Phenikaa Web Bridge: đã bật`, bấm **Mở QLĐT**, đăng nhập trên trang chính thức, quay lại app và bấm **Đã đăng nhập · Đồng bộ**.

Bridge cũng cho phép test trên Codespaces `*.app.github.dev`, `localhost` và `127.0.0.1`.

## Riêng tư

Extension không có form mật khẩu và không gửi thông tin đăng nhập sang GitHub Pages hay server trung gian. Nó chỉ chạy yêu cầu lấy lịch trong context của tab QLĐT đang đăng nhập và chuyển kết quả lịch + tên hiển thị về Better Phenikaa App trong trình duyệt cục bộ.
