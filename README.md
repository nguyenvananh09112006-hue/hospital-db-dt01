# DT01 – Quản lý bệnh viện

Đồ án Cơ sở dữ liệu – Bộ môn HTTT, Khoa CNTT, Trường ĐH Công nghệ GTVT · **Nhóm 1**

Hệ thống quản lý bệnh viện với 5 tác nhân: Nhân viên hành chính, Bác sĩ, Dược sĩ, Kỹ thuật viên cận lâm sàng, Quản trị viên (đặc tả: [docs/specifications.md](docs/specifications.md)).
Yêu cầu riêng của đề tài: chặn kê đơn vượt tồn kho thuốc và truy lại lịch sử sửa đơn từ bảng audit (JSONB).

> Trạng thái: đang phát triển (kế hoạch 5 tuần, 23/11 – 27/12/2026). Phân công thành viên: xem [CONTRIBUTING.md](CONTRIBUTING.md).

## Công nghệ

| Thành phần | Phiên bản | Ghi chú |
| --- | --- | --- |
| Java (JDK) | 21 / 25 LTS | Bản LTS |
| Spring Boot | 3.3.x / 3.4.x | Bản ổn định |
| Spring Data JPA / Hibernate | Theo Spring Boot | Không khai báo version riêng trong `pom.xml` |
| Flyway | Theo Spring Boot | Kèm `flyway-database-postgresql`; không dùng `ddl-auto=update` |
| PostgreSQL | 18 | Image Docker `postgres:18-alpine` |
| Testcontainers | Theo Spring Boot | Kiểm thử trên PostgreSQL thật |
| Docker Compose | v2 | Lệnh `docker compose` (không có dấu gạch ngang) |
| Build | Maven (Maven Wrapper `./mvnw`) | |

> Phiên bản chính xác của Hibernate, Flyway, Testcontainers ghi theo `app/pom.xml` sau khi khởi tạo dự án.

## Yêu cầu cài đặt

- Git
- Docker Desktop (đã bật), có Docker Compose v2
- Chỉ cần JDK nếu muốn chạy ứng dụng hoặc test ngoài Docker

## Chạy dự án (≤ 5 lệnh)

```bash
git clone https://github.com/nguyenvananh09112006-hue/hospital-db-dt01.git
cd hospital-db-dt01
cp .env.example .env
docker compose up -d --build
docker compose ps        # kiểm tra container hospital_postgres đang chạy
```

> **Giai đoạn hiện tại:** `docker-compose.yml` mới dựng PostgreSQL 18 (cổng 5432). Service ứng dụng Spring Boot, Flyway và Swagger (`http://localhost:8080/swagger-ui.html`) sẽ được bổ sung khi hoàn thiện `app/`.

Khi hoàn thiện, ứng dụng chạy Flyway để tạo bảng, view, thủ tục, trigger và vai trò CSDL từ `database/migrations/`.
Dừng hệ thống: `docker compose down` (thêm `-v` để xóa luôn dữ liệu).

## Tài khoản dùng thử

| Vai trò | Tên đăng nhập | Mật khẩu |
| --- | --- | --- |
| Quản trị viên | *(cập nhật khi có)* | *(cập nhật khi có)* |
| Bác sĩ | *(cập nhật khi có)* | *(cập nhật khi có)* |
| Dược sĩ | *(cập nhật khi có)* | *(cập nhật khi có)* |
| Nhân viên hành chính | *(cập nhật khi có)* | *(cập nhật khi có)* |
| Kỹ thuật viên CLS | *(cập nhật khi có)* | *(cập nhật khi có)* |

## Dữ liệu mẫu

*(cập nhật khi có: lệnh sinh và nạp dữ liệu mẫu, ví dụ `python3 database/seed/generate_data.py` rồi nạp vào CSDL)*
Quy mô: ≥ 10.000 đơn thuốc, ≥ 100.000 ca khám; dữ liệu tiếng Việt sinh tự động, không dùng dữ liệu thật.

## Kiểm thử

```bash
cd app
./mvnw test        # Windows: mvnw.cmd test
```

Test chạy trên PostgreSQL thật qua Testcontainers (cần Docker đang bật).

## Trình diễn yêu cầu riêng DT01

1. **Chặn kê vượt tồn:** đăng nhập Bác sĩ → kê đơn với số lượng lớn hơn tồn khả dụng → hệ thống từ chối và báo số tồn hiện có.
2. **Lịch sử sửa đơn:** sửa số lượng hoặc liều dùng của một đơn → đăng nhập Quản trị viên → xem lịch sử sửa đơn (dữ liệu cũ/mới lưu trong `audit_log`, kiểu JSONB).

*(cập nhật khi có: tên API hoặc câu SQL tương ứng)*

## Sao lưu và phục hồi

```bash
bash database/backup/backup.sh     # tạo file .dump trong database/backup/
bash database/backup/restore.sh <tên-file.dump>
```

## Cấu trúc thư mục

| Thư mục / tệp | Nội dung |
| --- | --- |
| `README.md`, `CONTRIBUTING.md` | Cách chạy, phiên bản công nghệ; phân công từng thành viên |
| `docker-compose.yml`, `.env.example` | Dựng toàn bộ hệ thống; mẫu biến môi trường, không chứa bí mật |
| `docs/` | Đặc tả, ERD, chuẩn hóa, từ điển dữ liệu, báo cáo PDF, slide |
| `database/migrations/` | DDL và đối tượng CSDL qua Flyway (`V1__...sql`, `V2__...sql`) |
| `database/seed/` | Script sinh dữ liệu mẫu, chạy lại được |
| `database/programmability/` | View, thủ tục, hàm, trigger (bản đọc; bản chạy nằm trong migrations) |
| `database/security/` | Vai trò CSDL, GRANT/REVOKE |
| `database/queries.sql` | 20 truy vấn nghiệp vụ, mỗi câu có chú thích câu hỏi và người viết |
| `database/performance/` | EXPLAIN ANALYZE trước/sau khi tạo chỉ mục |
| `database/backup/` | Script sao lưu, phục hồi |
| `app/` | Mã nguồn Spring Boot |
| `tests/` | Kiểm thử tầng dữ liệu, test đồng thời |

## Nguồn tham khảo

Liệt kê mọi mã mẫu, thư viện, lược đồ công khai đã tham khảo (bắt buộc theo quy định học thuật).

- Tài liệu PostgreSQL: https://www.postgresql.org/docs/
- Tài liệu Spring Boot: https://docs.spring.io/spring-boot/
- Tài liệu Flyway: https://documentation.red-gate.com/flyway
- Tài liệu Testcontainers: https://java.testcontainers.org/
- *(bổ sung khi tham khảo thêm nguồn khác)*

Việc sử dụng công cụ AI được khai báo trong phụ lục báo cáo.
