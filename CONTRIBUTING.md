# Quy ước làm việc nhóm

## Phân công

| Thành viên | GitHub | Vai trò kỹ thuật | Phân hệ (actor) | Thư mục chính |
| --- | --- | --- | --- | --- |
| TV1 – _Nguyễn Vân Anh_ | @nguyenvananh09112006-hue | Trưởng nhóm / Phân tích nghiệp vụ; bảo mật, phân quyền, sao lưu | Quản trị viên | `docs/`, `database/security/`, `database/backup/` |
| TV2 – _Nguyễn Thị Thùy Dung_ | @_username_ | Thiết kế CSDL: ERD, chuẩn hóa, DDL, migration, dữ liệu mẫu | Nhân viên hành chính | `database/migrations/`, `database/seed/`, `docs/erd/` |
| TV3 – _Lương Tiến Dũng_ | @_username_ | Lập trình CSDL: truy vấn, view, chỉ mục, EXPLAIN | Bác sĩ | `database/queries.sql`, `database/programmability/views/`, `database/performance/` |
| TV4 – _Phùng Thị Minh Ánh_ | @_username_ | DBA: thủ tục, hàm, trigger, giao dịch đồng thời | Dược sĩ | `database/programmability/`, `tests/concurrency/` |
| TV5 – _Đinh Tuấn Cường_ | @_username_ | Phát triển ứng dụng: ORM, API, kiểm thử, Docker | Lịch hẹn + khung ứng dụng | `app/`, `tests/`, `docker-compose.yml` |

Mọi thành viên đều tự viết SQL và phải giải thích được toàn bộ lược đồ khi vấn đáp.

## Quy trình Git

1. Cấu hình danh tính **trùng với tài khoản GitHub** (để commit được tính cho bạn):
   ```bash
   git config --global user.name "Tên GitHub"
   git config --global user.email "email-đã-đăng-ký-GitHub"
   ```
2. Luôn cập nhật `main` trước khi bắt đầu việc mới:
   ```bash
   git checkout main
   git pull
   git checkout -b feature/tv2-khao-sat-hanh-chinh
   ```
3. Commit nhỏ, thông điệp rõ ràng:
   ```bash
   git add .
   git commit -m "docs: khao sat nghiep vu hanh chinh"
   git push -u origin feature/tv2-khao-sat-hanh-chinh
   ```
4. Mở Pull Request vào `main`, gắn issue (`Closes #12`), chọn reviewer theo vòng xoay.
5. Chỉ merge khi có ≥ 1 approve. Xóa nhánh sau khi merge.

### Đặt tên nhánh

`<loại>/<tvX>-<mô-tả-ngắn>`. Loại: `feature`, `fix`, `docs`, `db`, `test`, `chore`.

Ví dụ: `db/tv4-trigger-chan-ke-vuot-ton`, `docs/tv1-dac-ta-m1`.

### Thông điệp commit

`<loại>: <mô tả>` – ví dụ `db: them trigger audit don thuoc`, `test: ca vi pham unique cccd`.

### Review xoay vòng

| Người mở PR | Reviewer |
| --- | --- |
| TV1 | TV5 |
| TV2 | TV1 |
| TV3 | TV2 |
| TV4 | TV3 |
| TV5 | TV4 |

## Quy định bắt buộc

- Không commit bí mật: `.env`, mật khẩu, file dump CSDL.
- Không force push lên `main`; không sửa lịch sử sau khi gắn tag `final`.
- Chỉ dùng dữ liệu sinh tự động, không dùng dữ liệu bệnh nhân thật.
- Dùng công cụ AI phải khai báo trong phụ lục báo cáo. ERD và chuẩn hóa do nhóm tự làm.
