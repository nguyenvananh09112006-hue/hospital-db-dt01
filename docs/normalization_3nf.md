# BÁO CÁO CHUẨN HÓA DỮ LIỆU ĐẠT CHUẨN 3NF (MỐC M2)
## ĐỀ TÀI: DT01 – QUẢN LÝ BỆNH VIỆN

---

## I. NGUYÊN TẮC CHUẨN HÓA
Theo yêu cầu đề cương môn học (Slide 9):
* Mọi quan hệ trong CSDL vật lý phải đạt tối thiểu **Chuẩn dạng 3 (3NF)**.
* Chứng minh toán học thông qua hệ quy tắc phụ thuộc hàm (FD) cho ít nhất **3 bảng cốt lõi**.
* Giải trình cụ thể nếu có sử dụng kỹ thuật **Phi chuẩn hóa (Denormalization)** và phương án duy trì tính nhất quán.

---

## II. CHỨNG MINH 3NF CHO 3 BẢNG CỐT LÕI

### 1. BẢNG `benh_nhan` (Hồ sơ bệnh nhân)

#### A. Trạng thái chưa chuẩn hóa (Lược đồ ban đầu):
Xét quan hệ:
`R_BENH_NHAN (id, ma_bn, ho_ten, cccd, ngay_sinh, gioi_tinh, so_dien_thoai, dia_chi_chi_tiet, ma_tinh, ten_tinh)`

* **Tập phụ thuộc hàm $F_1$:**
  1. $id \rightarrow \{ma\_bn, ho\_ten, cccd, ngay\_sinh, gioi\_tinh, so\_dien\_thoai, dia\_chi\_chi\_tiet, ma\_tinh, ten\_tinh\}$
  2. $cccd \rightarrow \{id, ma\_bn, ho\_ten, ...\}$
  3. $ma\_tinh \rightarrow \{ten\_tinh\}$

* **Khóa ứng viên (Candidate Key):** $K = \{id\}$ hoặc $K = \{cccd\}$. Chọn Khóa chính: $PK = \{id\}$.

#### B. Phân tích các chuẩn dạng:
* **Đạt 1NF:** Tất cả các thuộc tính đều chứa giá trị nguyên tố (atomic value), không có mảng hay thuộc tính lặp.
* **Đạt 2NF:** Khóa chính $\{id\}$ là khóa đơn (gồm 1 thuộc tính), nên mọi thuộc tính không khóa đều phụ thuộc hàm đầy đủ vào khóa chính, không có phụ thuộc hàm một phần.
* **Vi phạm 3NF:** Tồn tại phụ thuộc hàm bắc cầu:
  $$id \rightarrow ma\_tinh \quad \text{và} \quad ma\_tinh \rightarrow ten\_tinh \quad (ma\_tinh \text{ không phải là siêu khóa})$$
  Điều này dẫn đến dư thừa dữ liệu (tên tỉnh bị lặp lại hàng nghìn lần) và bất thường khi cập nhật.

#### C. Khắc phục chuẩn hóa về 3NF:
Tách quan hệ $R\_BENH\_NHAN$ thành 2 quan hệ không mất mát thông tin:
1. `tinh_thanh (ma_tinh, ten_tinh)` với $PK = \{ma\_tinh\}$.
2. `benh_nhan (id, ma_bn, ho_ten, cccd, ngay_sinh, gioi_tinh, so_dien_thoai, dia_chi_chi_tiet, ma_tinh)` với $PK = \{id\}$, $FK = \{ma\_tinh\}$.
*(Trong thực tế triển khai bảng phẳng địa chỉ, chuỗi `dia_chi` lưu toàn bộ định dạng hành chính, loại bỏ cột `ten_tinh` dư thừa để triệt tiêu phụ thuộc bắc cầu).*

$$\Rightarrow \text{Bảng } benh\_nhan \text{ đạt chuẩn 3NF.}$$

---

### 2. BẢNG `chi_tiet_don_thuoc` (Chi tiết các loại thuốc trong đơn)

#### A. Trạng thái khảo sát:
Xét quan hệ chi tiết đơn thuốc:
`R_CHI_TIET_DON (id, don_thuoc_id, lo_thuoc_id, so_luong, don_gia_ban, lieu_dung, cach_dung, ten_thuoc, han_su_dung)`

* **Tập phụ thuộc hàm $F_2$:**
  1. $id \rightarrow \{don\_thuoc\_id, lo\_thuoc\_id, so\_luong, don\_gia\_ban, lieu\_dung, cach\_dung\}$
  2. $\{don\_thuoc\_id, lo\_thuoc\_id\} \rightarrow \{so\_luong, don\_gia\_ban, lieu\_dung, cach\_dung\}$
  3. $lo\_thuoc\_id \rightarrow \{han\_su\_dung, ten\_thuoc\}$

* **Khóa chính:** $PK = \{id\}$.

#### B. Phân tích các chuẩn dạng:
* **Kiểm tra 2NF:** Nếu dùng khóa phức hợp $\{don\_thuoc\_id, lo\_thuoc\_id\}$, thuộc tính $ten\_thuoc, han\_su\_dung$ chỉ phụ thuộc một phần vào $lo\_thuoc\_id$ (vi phạm 2NF).
* **Kiểm tra 3NF:** Khi chọn $id$ làm khóa thay thế (surrogate key), $id \rightarrow lo\_thuoc\_id$ và $lo\_thuoc\_id \rightarrow \{han\_su\_dung, ten\_thuoc\}$, dẫn đến phụ thuộc hàm bắc cầu qua thuộc tính không khóa $lo\_thuoc\_id$.

#### C. Khắc phục chuẩn hóa về 3NF:
Tách triệt để thông tin thuốc và lô thuốc ra khỏi chi tiết đơn thuốc:
* `lo_thuoc (id, thuoc_id, so_lo, han_su_dung, ...)`
* `thuoc (id, ten_thuoc, ...)`
* `chi_tiet_don_thuoc (id, don_thuoc_id, lo_thuoc_id, so_luong, don_gia, lieu_dung, cach_dung)`:
  Mọi thuộc tính $\{so\_luong, don\_gia, lieu\_dung, cach\_dung\}$ đều phụ thuộc trực tiếp vào $\{id\}$ và không có thuộc tính nào phụ thuộc vào thuộc tính không khóa khác.

$$\Rightarrow \text{Bảng } chi\_tiet\_don\_thuoc \text{ đạt chuẩn 3NF.}$$

---

### 3. BẢNG `lo_thuoc` (Quản lý kho dược theo lô)

#### A. Trạng thái khảo sát:
`R_LO_THUOC (id, thuoc_id, so_lo, ngay_san_xuat, han_su_dung, so_luong_nhap, so_luong_ton, gia_nhap)`

* **Tập phụ thuộc hàm $F_3$:**
  1. $id \rightarrow \{thuoc\_id, so\_lo, ngay\_san\_xuat, han\_su\_dung, so\_luong\_nhap, so\_luong\_ton, gia\_nhap\}$
  2. $\{thuoc\_id, so\_lo\} \rightarrow \{id, ngay\_san\_xuat, han\_su\_dung, so\_luong\_nhap, so\_luong\_ton, gia\_nhap\}$

* **Khóa ứng viên:** $K_1 = \{id\}$, $K_2 = \{thuoc\_id, so\_lo\}$. Chọn $PK = \{id\}$ và đặt ràng buộc `UNIQUE (thuoc_id, so_lo)`.

#### B. Phân tích:
* Khóa chính là $id$ (đơn nhất) $\rightarrow$ Đạt 2NF.
* Trong tập thuộc tính không khóa: Không có phụ thuộc hàm $X \rightarrow Y$ nào giữa các thuộc tính không khóa (ví dụ $so\_luong\_ton$ không xác định $han\_su\_dung$).
* Mọi thuộc tính không khóa đều phụ thuộc trực tiếp vào khóa chính.

$$\Rightarrow \text{Bảng } lo\_thuoc \text{ đạt chuẩn 3NF.}$$

---

## III. GIẢI TRÌNH PHI CHUẨN HÓA CÓ CHỦ ĐÍCH (DENORMALIZATION)

Theo Slide 9: *"Phi chuẩn hóa phải nêu lý do và cách giữ nhất quán"*.

* **Bảng áp dụng:** Bảng `hoa_don`.
* **Cột phi chuẩn hóa:** `tien_cls`, `tien_thuoc`, `tong_tien_thanh_toan`.
* **Lý do kỹ thuật:**
  * Bảng `chi_tiet_chi_dinh` và `chi_tiet_don_thuoc` phát sinh hàng trăm nghìn giao dịch mỗi tháng.
  * Nếu mỗi lần thu ngân xem danh sách hóa đơn viện phí đều phải thực hiện `SUM()` qua nhiều bảng lớn với hàng triệu dòng, cơ sở dữ liệu sẽ bị quá tải I/O (Full Table Scan / Hash Aggregate), gây nghẽn màn hình thu viện phí.
  * Việc lưu sẵn `tong_tien_thanh_toan` tại thời điểm xuất hóa đơn giúp giảm độ phức tạp truy vấn từ $O(N)$ xuống $O(1)$.
* **Giải pháp duy trì tính nhất quán tuyệt đối:**
  1. **Tầng Giao dịch (Transaction ACID):** Chỉ cho phép tính toán và ghi nhận tổng tiền trong Stored Procedure đóng ca khám `sp_thanh_toan_hoa_don` với mức cô lập giao dịch `REPEATABLE READ`.
  2. **Ràng buộc CHECK:** `CHECK (tong_tien_thanh_toan = tien_kham + tien_cls + tien_thuoc - tien_bhyt_chi_tra)`.
  3. **Khóa đơn thuốc:** Sử dụng Trigger chặn cập nhật đơn thuốc sau khi hóa đơn đã xuất (`DA_THANH_TOAN`).
