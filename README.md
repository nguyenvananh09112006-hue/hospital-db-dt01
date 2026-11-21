# DT01 – Quản lý bệnh viện

Đồ án Cơ sở dữ liệu – Bộ môn HTTT, Khoa CNTT, Trường ĐH Công nghệ GTVT.

Hệ thống quản lý bệnh viện với 4 tác nhân: Nhân viên hành chính, Bác sĩ, Dược sĩ, Quản trị viên.

## Công nghệ

## Công nghệ

| Thành phần | Phiên bản |
| --- | --- |
| Java (JDK LTS) | Java 17 LTS / Java 21 LTS |
| Spring Boot | Spring Boot 3.3.x |
| JPA / Hibernate | Hibernate 6.x |
| Flyway | Flyway 10.x |
| Hệ QTCSDL | PostgreSQL 16 (Alpine Docker) |
| Container | Docker Compose v2.x |

## Chạy dự án (≤ 5 lệnh)

```bash
git clone <url-repo>
cd hospital-db-dt01
cp .env.example .env
docker compose up -d --build
# Swagger: http://localhost:8080/swagger-ui.html
```

## Cấu trúc thư mục

| Thư mục / tệp | Nội dung |
| --- | --- |
| `README.md`, `CONTRIBUTING.md` | Cách chạy, phiên bản công nghệ; phân công từng thành viên |
| `docker-compose.yml`, `.env.example` | Dựng toàn bộ hệ thống; mẫu biến môi trường, không chứa bí mật |
| `docs/` | Khảo sát, đặc tả, ERD gốc và ảnh xuất, báo cáo PDF, slide |
| `database/migrations/` | DDL qua Flyway (`V1__...sql`, `V2__...sql`) |
| `database/seed/` | Script sinh dữ liệu mẫu, chạy lại được |
| `database/programmability/` | View, thủ tục, hàm, trigger |
| `database/security/` | Vai trò CSDL, GRANT/REVOKE |
| `database/queries.sql` | Truy vấn nghiệp vụ, mỗi câu có chú thích câu hỏi |
| `database/performance/` | EXPLAIN ANALYZE trước/sau khi tạo chỉ mục |
| `database/backup/` | Script sao lưu, phục hồi |
| `app/` | Mã nguồn Spring Boot |
| `tests/` | Kiểm thử tầng dữ liệu (Testcontainers), test đồng thời |

## Nguồn tham khảo

Liệt kê mã mẫu, thư viện, lược đồ công khai đã tham khảo (bắt buộc theo quy định học thuật).

- _chưa có_
