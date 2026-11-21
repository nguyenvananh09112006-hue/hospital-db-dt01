# ĐẶC TẢ YÊU CẦU NGHIỆP VỤ (MỐC M1)
## HỆ THỐNG QUẢN LÝ BỆNH VIỆN (MÃ ĐỀ TÀI: DT01)

* **Học phần:** Đồ án Cơ sở dữ liệu (Khoa CNTT – Bộ môn HTTT, Trường ĐH Công nghệ Giao thông vận tải)
* **Giảng viên hướng dẫn:** ThS. NCS Trần Đức Thắng
* **Nhóm thực hiện:** Nhóm 1 (Lớp: 75DCHT23)
* **Thành viên:**
  1. Nguyễn Vân Anh (Trưởng nhóm / Phân tích nghiệp vụ - TV1)
  2. Nguyễn Thị Thùy Dung (Thiết kế CSDL - TV2)
  3. Lương Tiến Dũng (Lập trình CSDL - TV3)
  4. Phùng Thị Minh Ánh (DBA - TV4)
  5. Đinh Tuấn Cường (Phát triển ứng dụng - TV5)

---

## CHƯƠNG 1: TỔNG QUAN HỆ THỐNG

### 1.1. Bối cảnh và Tính cấp thiết
Trong môi trường bệnh viện và các cơ sở y tế hiện đại, việc số hóa quy trình khám chữa bệnh là yêu cầu tiên quyết nhằm nâng cao chất lượng phục vụ, giảm thiểu thời gian chờ đợi của bệnh nhân, hạn chế sai sót trong kê đơn thuốc và tối ưu hóa quản lý tồn kho dược phẩm. Đồ án xây dựng một giải pháp cơ sở dữ liệu quan hệ mạnh mẽ, đảm bảo tính toàn vẹn cao, chống xung đột giao dịch khi nhiều bác sĩ cùng kê đơn và lưu vết kiểm toán chi tiết phục vụ giám sát y khoa.

### 1.2. Mục tiêu hệ thống
* **Chuẩn hóa quy trình nghiệp vụ:** Kết nối liền mạch luồng dữ liệu từ Tiếp đón $\rightarrow$ Khám bệnh $\rightarrow$ Chỉ định cận lâm sàng $\rightarrow$ Kê đơn thuốc $\rightarrow$ Phát thuốc $\rightarrow$ Thanh toán viện phí.
* **Đảm bảo tính toàn vẹn và an toàn dữ liệu:** Quản lý kho dược nghiêm ngặt theo số lô và hạn sử dụng; ngăn chặn tuyệt đối tình trạng kê vượt tồn kho thuốc khả dụng.
* **Kiểm toán và giám sát (Audit Trail):** Ghi nhận chi tiết mọi hành vi sửa đổi đơn thuốc dưới dạng cấu trúc `JSONB` trong PostgreSQL.
* **Hiệu năng và xử lý đồng thời:** Đảm bảo hệ thống vận hành chính xác dưới tải cao khi nhiều bác sĩ cùng thao tác trên các mặt hàng dược phẩm khan hiếm (xử lý Race Condition / Lost Update).

### 1.3. Công nghệ lựa chọn và Căn cứ kỹ thuật
* **Hệ quản trị CSDL:** PostgreSQL 16 (Hỗ trợ JSONB hiệu năng cao, cơ chế khóa dòng mạnh mẽ, Partial Index, Window Functions và CTE đệ quy).
* **Công nghệ ứng dụng:** Java 17 LTS / 21 LTS, Spring Boot 3.3.x, Spring Data JPA / Hibernate 6.x.
* **Quản lý phiên bản CSDL:** Flyway Migration (Đảm bảo DDL đồng bộ, không dùng ddl-auto update).
* **Kiểm thử tự động:** Testcontainers (Chạy test trên container PostgreSQL thật).
* **Đóng gói triển khai:** Docker & Docker Compose v2.

---

## CHƯƠNG 2: PHÂN TÍCH YÊU CẦU NGHIỆP VỤ

### 2.1. Danh sách 4 Tác nhân (Actors)
1. **Quản trị viên (Admin):** Quản lý cấu hình toàn hệ thống, danh mục khoa phòng, quản lý nhân viên y tế, phân quyền bảo mật và tra cứu nhật ký kiểm toán (`AuditLog`).
2. **Nhân viên hành chính (Receptionist / Cashier):** Tiếp nhận bệnh nhân, tạo mới và cập nhật hồ sơ bệnh nhân, đặt lịch hẹn và phân phòng khám, lập hóa đơn và thu viện phí.
3. **Bác sĩ (Doctor):** Tiếp nhận ca khám bệnh, ghi nhận triệu chứng, chẩn đoán bệnh án, chỉ định các xét nghiệm/chẩn đoán hình ảnh, xem kết quả cận lâm sàng và kê đơn thuốc điện tử.
4. **Dược sĩ (Pharmacist):** Quản lý kho thuốc (nhập kho theo lô, theo dõi hạn dùng), duyệt đơn thuốc của bác sĩ, kiểm tra tương tác/tồn kho và xác nhận xuất thuốc cho bệnh nhân.

---

### 2.2. Bảng Danh mục 17 Use Cases

| Mã UC | Tên Use Case | Tác nhân chính | Mô tả tóm tắt | Tiền điều kiện | Hậu điều kiện |
| :---: | :--- | :--- | :--- | :--- | :--- |
| **UC01** | Đăng ký hồ sơ bệnh nhân | Hành chính | Nhập thông tin hành chính, số CCCD, thẻ BHYT (nếu có) của bệnh nhân mới. | Bệnh nhân chưa có trong hệ thống | Tạo bản ghi bệnh nhân mới kèm mã định danh |
| **UC02** | Tra cứu hồ sơ bệnh nhân | Hành chính, Bác sĩ | Tìm kiếm thông tin bệnh nhân qua CCCD, Số điện thoại hoặc Mã bệnh nhân. | Đã đăng nhập | Hiển thị hồ sơ hành chính & lịch sử khám cũ |
| **UC03** | Đặt lịch khám & phân phòng | Hành chính | Chọn chuyên khoa, bác sĩ phụ trách và tạo số thứ tự khám cho ca khám. | Đã có hồ sơ bệnh nhân | Ca khám ở trạng thái `CHO_KHAM` |
| **UC04** | Lập hóa đơn viện phí | Hành chính | Tổng hợp chi phí tiền khám, xét nghiệm và tiền thuốc thành hóa đơn. | Ca khám hoàn tất chỉ định/kê đơn | Tạo hóa đơn ở trạng thái `CHO_THANH_TOAN` |
| **UC05** | Thu tiền & in biên lai | Hành chính | Ghi nhận tiền bệnh nhân thanh toán, đóng ca khám và in hóa đơn/biên lai. | Hóa đơn chưa thanh toán | Hóa đơn chuyển trạng thái `DA_THANH_TOAN` |
| **UC06** | Xem hàng đợi khám | Bác sĩ | Xem danh sách bệnh nhân đang chờ khám tại phòng khám của mình trong ngày. | Bác sĩ đã đăng nhập ca trực | Danh sách xếp theo số thứ tự tiếp đón |
| **UC07** | Khám bệnh & Ghi chẩn đoán | Bác sĩ | Bắt đầu ca khám, ghi nhận tiền sử bệnh, triệu chứng lâm sàng và kết luận bệnh án. | Trạng thái ca khám là `CHO_KHAM` | Chuyển trạng thái ca khám sang `DANG_KHAM` |
| **UC08** | Chỉ định dịch vụ cận lâm sàng | Bác sĩ | Chỉ định các xét nghiệm máu, nước tiểu, X-Quang, Siêu âm cho bệnh nhân. | Ca khám đang ở trạng thái `DANG_KHAM` | Tạo các dòng chỉ định ở trạng thái `CHO_KET_QUA` |
| **UC09** | Xem kết quả cận lâm sàng | Bác sĩ | Xem các chỉ số xét nghiệm và kết luận hình ảnh để củng cố chẩn đoán. | Phòng xét nghiệm đã nhập kết quả | Bác sĩ có đủ dữ liệu để ra quyết định kê đơn |
| **UC10** | Kê đơn thuốc điện tử | Bác sĩ | Chọn thuốc, số lượng, hướng dẫn liều dùng; hệ thống kiểm tra tồn kho tức thì. | Ca khám đang `DANG_KHAM` | Tạo đơn thuốc liên kết với ca khám |
| **UC11** | Duyệt & Xuất thuốc theo đơn | Dược sĩ | Kiểm tra đơn thuốc, đối chiếu lô thuốc thực tế trong kho và xác nhận xuất thuốc. | Đơn thuốc ở trạng thái `CHO_XUAT` | Trừ tồn kho thực tế, đơn thuốc chuyển `DA_XUAT` |
| **UC12** | Nhập kho thuốc theo lô | Dược sĩ | Lập phiếu nhập kho thuốc mới gồm mã thuốc, số lô, hạn dùng, số lượng, giá nhập. | Có biên bản bàn giao kho dược | Tăng tồn kho theo lô tương ứng |
| **UC13** | Kiểm kê & Cảnh báo tồn kho | Dược sĩ | Tra cứu thuốc sắp hết hạn (< 30 ngày) hoặc số lượng tồn dưới ngưỡng an toàn. | Đã đăng nhập vai trò Dược sĩ | Hiển thị bảng cảnh báo phục vụ dự trù mua sắm |
| **UC14** | Quản lý danh mục y tế | Quản trị viên | Thêm/sửa thông tin khoa phòng, danh mục dịch vụ cận lâm sàng và danh mục thuốc. | Quyền Admin | Cập nhật bảng danh mục hệ thống |
| **UC15** | Quản lý nhân viên & Tài khoản | Quản trị viên | Tạo mới bác sĩ, điều dưỡng, nhân viên; cấp tài khoản và gán vai trò (`ROLE`). | Quyền Admin | Tạo tài khoản, mã hóa mật khẩu BCrypt |
| **UC16** | Tra cứu nhật ký kiểm toán | Quản trị viên | Xem lịch sử các thao tác nhạy cảm (sửa đơn thuốc, hủy chỉ định) lưu qua JSONB. | Quyền Admin | Hiển thị chi tiết bản ghi cũ/mới và người sửa |
| **UC17** | Hủy chỉ định cận lâm sàng | Bác sĩ | Hủy dịch vụ đã chỉ định nếu phát hiện nhầm lẫn hoặc bệnh nhân từ chối. | Dịch vụ đang `CHO_THUC_HIEN` | Hủy thành công, không tính tiền vào hóa đơn |

---

### 2.3. Bảng 10 Quy tắc nghiệp vụ bắt buộc (Business Rules - BR)

| Mã BR | Tên quy tắc nghiệp vụ | Mô tả đặc tả chi tiết | Giải pháp CSDL đảm bảo |
| :---: | :--- | :--- | :--- |
| **BR01** | Tránh trùng lịch khám bác sĩ | Trong cùng một khung giờ của một ngày, một bác sĩ không được phép có $\ge 2$ lịch hẹn khám trùng nhau. | `UNIQUE (bac_si_id, ngay_kham, ca_kham)` hoặc `EXCLUSION CONSTRAINT` trên khoảng thời gian |
| **BR02** | Ràng buộc luồng ca khám | Bác sĩ chỉ được phép chỉ định cận lâm sàng hoặc kê đơn thuốc khi trạng thái ca khám đang là `DANG_KHAM`. | Ràng buộc `CHECK (trang_thai IN ('CHO_KHAM', 'DANG_KHAM', 'HOAN_THANH', 'DA_HUY'))` và Trigger validate |
| **BR03** | Chặn kê đơn vượt tồn kho | *(Yêu cầu trọng tâm DT01)* Số lượng thuốc kê trong chi tiết đơn thuốc không được vượt quá số lượng tồn khả dụng trong kho (`so_luong_ton - so_luong_tam_giu`). Nếu vi phạm, hệ thống phải chặn ngay lập tức. | **Trigger `BEFORE INSERT OR UPDATE`** trên bảng `chi_tiet_don_thuoc` bắn ngoại lệ `RAISE EXCEPTION` |
| **BR04** | Kiểm soát hạn dùng thuốc | Thuốc có hạn sử dụng nhỏ hơn ngày hiện tại (`han_su_dung < CURRENT_DATE`) hoặc tồn kho $\le 0$ không được phép xuất hiện để bác sĩ kê đơn hoặc dược sĩ xuất kho. | `CHECK (han_su_dung > ngay_san_xuat)` + View lọc thuốc khả dụng (`WHERE han_su_dung >= CURRENT_DATE AND so_luong_ton > 0`) |
| **BR05** | Bất biến đơn thuốc đã xuất | Đơn thuốc sau khi đã chuyển sang trạng thái `DA_XUAT` (Dược sĩ đã giao thuốc) thì bị khóa vĩnh viễn, cấm mọi thao tác `UPDATE` số lượng hoặc `DELETE`. | **Trigger `BEFORE UPDATE OR DELETE`** trên bảng `don_thuoc` từ chối nếu `OLD.trang_thai = 'DA_XUAT'` |
| **BR06** | Kiểm toán sửa đổi qua JSONB | *(Yêu cầu trọng tâm DT01)* Mọi thao tác chỉnh sửa đơn thuốc hoặc chi tiết đơn thuốc phải tự động ghi vào bảng `audit_log`. Cột `data_changes` kiểu `JSONB` phải lưu trọn vẹn trạng thái cũ (`to_jsonb(OLD)`) và mới (`to_jsonb(NEW)`). | **Trigger `AFTER UPDATE OR DELETE`** tự động đóng gói dữ liệu sang `JSONB` và ghi log kiểm toán |
| **BR07** | Nhất quán tiền hóa đơn | Tổng số tiền thanh toán của hóa đơn phải bằng chính xác: $\sum(\text{Dịch vụ CLS}) + \sum(\text{Tiền thuốc}) - \text{BHYT chi trả}$. Số tiền thanh toán không bao giờ được âm. | `CHECK (tong_tien >= 0)` + Stored Procedure quyết toán hoặc Trigger đồng bộ tính toán |
| **BR08** | Tính duy nhất định danh bệnh nhân | Số CCCD/Định danh cá nhân của bệnh nhân là duy nhất trong toàn hệ thống. Mã thẻ BHYT (nếu có) phải gồm đúng 15 ký tự theo quy định chuẩn của Bảo hiểm Xã hội Việt Nam. | `UNIQUE (cccd)` và `CHECK (ma_bhyt IS NULL OR LENGTH(ma_bhyt) = 15)` |
| **BR09** | Điều kiện hủy cận lâm sàng | Bác sĩ chỉ được phép hủy chỉ định cận lâm sàng khi trạng thái của dịch vụ đó đang là `CHO_THUC_HIEN`. Khi kỹ thuật viên xét nghiệm đã bấm `DANG_THUC_HIEN` thì không được hủy. | Trigger kiểm tra trạng thái trước khi cho phép `DELETE` hoặc chuyển cờ hủy |
| **BR10** | Toàn vẹn xóa logic (Soft Delete) | Không được phép `DELETE` vật lý các bản ghi danh mục thuốc, dịch vụ hoặc nhân viên y tế đã từng phát sinh liên kết với hồ sơ bệnh án cũ nhằm bảo tồn lịch sử y khoa. Sử dụng cờ `is_active = FALSE`. | Ràng buộc khóa ngoại `ON DELETE RESTRICT` trên các bảng giao dịch chính |

---

## CHƯƠNG 3: BƯỚC ĐỆM CHUẨN BỊ CHO THIẾT KẾ CSDL (MỐC M2)

Từ 17 Use Cases và 10 Quy tắc nghiệp vụ trên, phân hệ dữ liệu dự kiến được phân công cho **TV2 (Nguyễn Thị Thùy Dung)** xây dựng mô hình ERD với các thực thể cốt lõi sau:

1. `KhoaPhong` (Phòng ban/Chuyên khoa - Phân cấp cây)
2. `NhanVien` (Bác sĩ, Điều dưỡng, Dược sĩ, Nhân viên)
3. `TaiKhoan` (Tài khoản người dùng, quan hệ 1-1 với `NhanVien`)
4. `BenhNhan` (Hồ sơ bệnh nhân)
5. `TheBHYT` (Thực thể yếu phụ thuộc vào `BenhNhan`)
6. `LichHen` (Lịch hẹn khám của bệnh nhân)
7. `HoSoKham` / `CaKham` (Hồ sơ từng đợt khám bệnh)
8. `DichVuCLS` (Danh mục dịch vụ xét nghiệm, chẩn đoán)
9. `ChiTietChiDinh` (Bảng nối n-n giữa `CaKham` và `DichVuCLS`)
10. `Thuoc` (Danh mục biệt dược, hoạt chất)
11. `LoThuoc` (Thực thể yếu theo dõi số lô, hạn dùng, tồn kho của `Thuoc`)
12. `DonThuoc` (Đơn thuốc điện tử gắn với `CaKham`)
13. `ChiTietDonThuoc` (Bảng nối n-n giữa `DonThuoc` và `LoThuoc`)
14. `HoaDon` (Hóa đơn viện phí)
15. `AuditLog` (Bảng nhật ký kiểm toán chứa cột `data_changes JSONB`)
