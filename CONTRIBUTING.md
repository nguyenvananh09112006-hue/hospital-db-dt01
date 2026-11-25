# Quy ước làm việc nhóm – DT01 Quản lý bệnh viện (Nhóm 1)

## Phân công

| Thành viên | GitHub | Vai trò | Phụ trách chính | Hỗ trợ | Thư mục chính |
| --- | --- | --- | --- | --- | --- |
| TV1 – Nguyễn Vân Anh | @nguyenvananh09112006-hue | Trưởng nhóm / Phân tích nghiệp vụ | Đặc tả yêu cầu, use case, quy tắc BR; quản lý GitHub Projects; nộp các mốc; tổng hợp báo cáo và slide | Thiết kế ERD cùng TV2 | `docs/` |
| TV2 – Nguyễn Thị Thùy Dung | @dungnguyen280706 | Thiết kế CSDL | ERD, chuẩn hóa 3NF, từ điển dữ liệu, DDL qua migration Flyway | Script sinh dữ liệu mẫu cùng TV5 | `database/migrations/`, `database/seed/`, `docs/erd/` |
| TV3 – Lương Tiến Dũng | @luongtiendung-tech | Lập trình CSDL | Truy vấn nghiệp vụ, view, thủ tục lưu trữ, hàm, trigger nghiệp vụ và trigger audit | Kiểm thử tầng dữ liệu cùng TV5 | `database/queries.sql`, `database/programmability/` |
| TV4 – Phùng Thị Minh Ánh | @phunganh2006123-cmyk | DBA | Vai trò CSDL và GRANT/REVOKE, chỉ mục và EXPLAIN ANALYZE, xử lý đồng thời, sao lưu và phục hồi | Kiểm tra ràng buộc trong DDL của TV2 | `database/security/`, `database/performance/`, `database/backup/`, `tests/concurrency/` |
| TV5 – Đinh Tuấn Cường | @cuongdanghocutt-afk | Phát triển ứng dụng | Spring Boot, ánh xạ JPA, API, Swagger, giao diện tối thiểu, kiểm thử Testcontainers, Docker Compose | Video demo cùng TV1 | `app/`, `tests/`, `docker-compose.yml` |

Việc chung của cả nhóm:

- Mỗi người tự viết **4 truy vấn** trong `database/queries.sql`, ghi tên người viết ở chú thích. TV3 điều phối để đủ các loại bắt buộc.
- TV2, TV3, TV4 mỗi người viết **≥ 3 ca kiểm thử** cho phần mình; TV5 dựng khung Testcontainers.
- **Mọi thành viên vẫn tự viết SQL và hiểu toàn bộ lược đồ**, vì vấn đáp hỏi từng cá nhân.

Tiến độ theo dõi trên board GitHub Projects: [DT01 – Kế hoạch 13 tuần](https://github.com/users/nguyenvananh09112006-hue/projects/2) (thực hiện trong 5 tuần, 23/11 – 27/12/2026).

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
   git checkout -b db/tv2-schema-v1
   ```
3. Commit nhỏ, thông điệp rõ ràng:
   ```bash
   git add .
   git commit -m "db: tao bang benh nhan va the bhyt"
   git push -u origin db/tv2-schema-v1
   ```
4. Mở Pull Request vào `main`, gắn issue (`Closes #12`), chọn reviewer theo vòng xoay.
5. Chỉ merge khi có ≥ 1 approve. Xóa nhánh sau khi merge.

Hạn nội bộ: mở PR trước **21h**, reviewer duyệt trong **12 giờ**.

### Đặt tên nhánh

`<loại>/<tvX>-<mô-tả-ngắn>`. Loại: `feature`, `fix`, `docs`, `db`, `test`, `chore`.

Ví dụ: `db/tv3-trigger-chan-ke-vuot-ton`, `db/tv4-roles-grant`, `docs/tv1-dac-ta-m1`.

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

Riêng PR thay đổi DDL (`database/migrations/`) của TV2 luôn cần thêm **TV4** duyệt phần ràng buộc.

## Đánh giá đóng góp

Điểm cá nhân = Điểm nhóm (90%) × hệ số đóng góp + Vấn đáp cá nhân (10%).
Hệ số 0,6–1,2, xét theo **commit và pull request**, đánh giá chéo ẩn danh (M2, cuối kỳ) và vấn đáp. Không giải thích được lược đồ của nhóm thì hệ số tối đa 0,7.
Vì vậy mỗi người phải tự commit phần việc của mình bằng tài khoản của mình; không nhờ người khác commit hộ.

## Quy định bắt buộc

- **Git:** commit bằng tài khoản của mình, làm trên nhánh riêng, gộp qua PR có ≥ 1 người review. Không force push lên `main`; không sửa lịch sử sau khi gắn tag `final`.
- **Bí mật:** không commit `.env`, mật khẩu, file dump CSDL.
- **Công cụ AI:** được dùng nếu khai báo trong phụ lục báo cáo. ERD và chuẩn hóa do nhóm tự làm, AI chỉ rà soát. Mọi dòng SQL trong repo, người commit phải giải thích được khi vấn đáp; không giải thích được thì phần đó không được tính điểm.
- **Sao chép:** mã mẫu, thư viện, lược đồ công khai phải ghi nguồn trong mục "Nguồn tham khảo" của `README.md`. Đồ án khóa trước cũng là nguồn. Trùng lặp không ghi nguồn bị xử lý theo quy định của trường.
- **Dữ liệu:** chỉ dùng dữ liệu sinh tự động hoặc dữ liệu công khai có giấy phép. Không dùng dữ liệu cá nhân thật của bệnh nhân.
