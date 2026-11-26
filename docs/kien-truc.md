# KIẾN TRÚC HỆ THỐNG QUẢN LÝ BỆNH VIỆN DT01

## 1. Tổng quan kiến trúc

Hệ thống quản lý bệnh viện DT01 được xây dựng theo mô hình kiến trúc phân tầng (Layered Architecture), nhằm tách biệt trách nhiệm giữa các thành phần, giúp hệ thống dễ bảo trì, kiểm thử và mở rộng.

Các tầng chính bao gồm:

- Controller Layer
- Service Layer
- Repository Layer
- Entity Layer

## 2. Sơ đồ kiến trúc tổng thể

```text
             CLIENT
                |
                v
        CONTROLLER LAYER
                |
                v
          SERVICE LAYER
                |
                v
        REPOSITORY LAYER
                |
                v
          ENTITY LAYER
                |
                v
          POSTGRESQL 16
```

Các thành phần hỗ trợ:

- Spring Security: Xác thực và phân quyền người dùng.
- Flyway: Quản lý phiên bản và thay đổi cấu trúc CSDL.
- Testcontainers: Tạo môi trường PostgreSQL phục vụ kiểm thử.
- Docker Compose: Quản lý môi trường triển khai.

## 3. Mô tả các tầng kiến trúc

### 3.1. Controller Layer

Tiếp nhận các HTTP Request từ phía Client và trả về HTTP Response.

Nhiệm vụ:
- Tiếp nhận yêu cầu từ người dùng.
- Kiểm tra dữ liệu đầu vào.
- Gọi Service tương ứng.
- Trả kết quả dưới dạng JSON.
- Không xử lý trực tiếp logic nghiệp vụ phức tạp.

### 3.2. Service Layer

Chứa các logic nghiệp vụ chính của hệ thống.

Nhiệm vụ:
- Xử lý nghiệp vụ quản lý bệnh viện.
- Kiểm tra các điều kiện nghiệp vụ.
- Điều phối các thao tác giữa nhiều Repository.
- Quản lý Transaction.
- Xử lý ngoại lệ nghiệp vụ.

Các nghiệp vụ chính:
- Đăng nhập và quản lý tài khoản.
- Quản lý lịch hẹn.
- Quản lý hồ sơ khám bệnh.
- Quản lý đơn thuốc.
- Quản lý cấp phát thuốc.
- Quản lý hóa đơn và thanh toán.

### 3.3. Repository Layer

Sử dụng Spring Data JPA để tương tác với cơ sở dữ liệu.

Nhiệm vụ:
- Truy vấn dữ liệu.
- Thêm dữ liệu.
- Cập nhật dữ liệu.
- Xóa dữ liệu khi nghiệp vụ cho phép.

### 3.4. Entity Layer

Đại diện cho các thực thể được ánh xạ từ cơ sở dữ liệu sang Java Object.

Các Entity dự kiến được xây dựng dựa trên ERD và migration do TV2 phụ trách.

Một số thực thể chính:
- KhoaPhong
- NhanVien
- TaiKhoan
- BenhNhan
- LichHen
- HoSoKham
- Thuoc
- LoThuoc
- DonThuoc
- HoaDon
- AuditLog

Tên bảng, tên cột và quan hệ phải thống nhất với thiết kế CSDL của nhóm.

### 3.5. DTO

DTO (Data Transfer Object) được sử dụng để trao đổi dữ liệu giữa Client và các tầng trong ứng dụng.

Mục đích:
- Kiểm soát dữ liệu đầu vào và đầu ra.
- Không trả trực tiếp các Entity chứa thông tin nhạy cảm.
- Giảm sự phụ thuộc giữa API và cấu trúc database.

## 4. Công nghệ sử dụng

| Thành phần | Công nghệ |
|---|---|
| Ngôn ngữ | Java |
| Backend | Spring Boot |
| Build Tool | Maven |
| Database | PostgreSQL 16 |
| ORM | Hibernate |
| Data Access | Spring Data JPA |
| Migration | Flyway |
| Authentication | Spring Security |
| Testing | JUnit, Spring Boot Test |
| Integration Testing | Testcontainers |
| Deployment | Docker Compose |

Phiên bản Java và Spring Boot chính thức cần được thống nhất theo cấu hình dự án của nhóm.

## 5. Bảo mật và phân quyền

Hệ thống có bốn nhóm vai trò chính:

| Vai trò | Chức năng |
|---|---|
| Admin | Quản trị và cấu hình hệ thống |
| Receptionist/Cashier | Tiếp nhận bệnh nhân, quản lý lịch hẹn và viện phí |
| Doctor | Khám bệnh, chẩn đoán và kê đơn |
| Pharmacist | Quản lý thuốc và cấp phát thuốc |

Các nguyên tắc bảo mật:

- Yêu cầu đăng nhập trước khi truy cập chức năng nội bộ.
- Kiểm soát quyền truy cập theo vai trò.
- Mật khẩu phải được băm bằng BCrypt hoặc thuật toán phù hợp.
- Không lưu mật khẩu dạng văn bản thuần.
- Không đưa thông tin bí mật vào mã nguồn.
- Sử dụng biến môi trường để cấu hình thông tin kết nối.

## 6. Quản lý cơ sở dữ liệu

Hệ thống sử dụng PostgreSQL 16 làm hệ quản trị cơ sở dữ liệu.

Spring Data JPA và Hibernate được sử dụng để ánh xạ Entity và thực hiện các thao tác dữ liệu.

Flyway chịu trách nhiệm quản lý các thay đổi cấu trúc CSDL thông qua migration.

Các migration phải tuân thủ quy ước chung của nhóm và không tự ý chỉnh sửa những migration đã được áp dụng.

Vị trí migration hiện tại là `database/migrations/`. Cấu hình Flyway của ứng dụng cần được thống nhất để đọc đúng thư mục này.

## 7. Giao dịch và xử lý đồng thời

### 7.1. Transaction

Sử dụng `@Transactional` trong Service Layer để đảm bảo tính toàn vẹn dữ liệu khi thực hiện các nghiệp vụ gồm nhiều thao tác database.

### 7.2. Concurrency

Cần kiểm soát xung đột dữ liệu khi nhiều người dùng thao tác đồng thời, đặc biệt trong các nghiệp vụ:

- Nhập và xuất kho thuốc.
- Cập nhật tồn kho.
- Thanh toán hóa đơn.
- Cập nhật hồ sơ khám bệnh.

Cơ chế kiểm soát đồng thời sẽ được lựa chọn phù hợp với thiết kế CSDL và nghiệp vụ.

## 8. Kiểm thử hệ thống

### 8.1. Unit Test

Sử dụng JUnit để kiểm thử các thành phần xử lý độc lập.

### 8.2. Integration Test

Kiểm thử sự phối hợp giữa Controller, Service, Repository và cơ sở dữ liệu.

### 8.3. Testcontainers

Sử dụng Testcontainers để tạo PostgreSQL container phục vụ kiểm thử tích hợp.

Các nội dung cần kiểm thử:
- Kết nối database.
- Flyway Migration.
- Các thao tác Repository.
- Nghiệp vụ đăng nhập.
- Các nghiệp vụ quản lý lịch hẹn và hồ sơ khám.

## 9. Triển khai hệ thống

Docker và Docker Compose được sử dụng để quản lý môi trường chạy ứng dụng và cơ sở dữ liệu.

Thông tin cấu hình được quản lý bằng biến môi trường.

Không đưa mật khẩu thực tế hoặc thông tin nhạy cảm vào repository.

## 10. Cấu trúc mã nguồn dự kiến

```text
app/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/hospital/
│   │   │       ├── config/
│   │   │       ├── controller/
│   │   │       ├── service/
│   │   │       ├── repository/
│   │   │       ├── entity/
│   │   │       ├── dto/
│   │   │       ├── security/
│   │   │       └── exception/
│   │   └── resources/
│   └── test/
│
└── pom.xml
```

Đây là cấu trúc dự kiến, có thể điều chỉnh theo quá trình triển khai thực tế.

## 11. Kết luận

Kiến trúc phân tầng giúp hệ thống quản lý bệnh viện DT01 có cấu trúc rõ ràng, dễ bảo trì và mở rộng.

Việc kết hợp Spring Boot, Spring Data JPA, PostgreSQL, Flyway, Spring Security và Testcontainers tạo nền tảng cho quá trình phát triển, kiểm thử và triển khai hệ thống.
