# TỪ ĐIỂN DỮ LIỆU (DATA DICTIONARY) - MỐC M2
## HỆ THỐNG QUẢN LÝ BỆNH VIỆN (DT01)

---

### 1. BẢNG `khoa_phong` (Khoa, Phòng ban)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `SERIAL` | PK, NOT NULL | Khóa chính tự tăng | `1` |
| `ma_khoa` | `VARCHAR(20)` | UNIQUE, NOT NULL | Mã định danh phòng ban | `'K_NOI'` |
| `ten_khoa` | `VARCHAR(100)` | NOT NULL | Tên đầy đủ của khoa/phòng | `'Khoa Nội Tiêu Hóa'` |
| `loai_khoa` | `VARCHAR(50)` | NOT NULL | Loại phòng ban chức năng | `'KHOA_CHUYEN_MON'` |
| `parent_id` | `INT` | FK $\rightarrow$ `khoa_phong(id)` | Khóa ngoại phân cấp cây (Khoa cha) | `NULL` hoặc `1` |
| `mo_ta` | `TEXT` | | Ghi chú thêm về phòng ban | `'Tầng 2, Nhà A'` |
| `created_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Thời điểm tạo bản ghi | `'2026-11-20 08:00:00'` |

---

### 2. BẢNG `nhan_vien` (Nhân sự)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `SERIAL` | PK, NOT NULL | Khóa chính tự tăng | `101` |
| `ma_nv` | `VARCHAR(20)` | UNIQUE, NOT NULL | Mã nhân viên | `'BS_001'` |
| `ho_ten` | `VARCHAR(100)` | NOT NULL | Họ và tên nhân sự | `'Nguyễn Văn A'` |
| `chuc_vu` | `VARCHAR(50)` | NOT NULL | Vai trò công tác | `'BAC_SI'` |
| `khoa_phong_id` | `INT` | FK $\rightarrow$ `khoa_phong(id)` | Thuộc khoa phòng nào | `1` |
| `so_dien_thoai` | `VARCHAR(15)` | | Số điện thoại liên hệ | `'0912345678'` |
| `email` | `VARCHAR(100)` | | Email công vụ | `'bs.a@hospital.vn'` |
| `is_active` | `BOOLEAN` | NOT NULL, DEFAULT TRUE | Cờ trạng thái làm việc (Soft delete) | `TRUE` |

---

### 3. BẢNG `tai_khoan` (Tài khoản)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `SERIAL` | PK, NOT NULL | Khóa chính | `1` |
| `nhan_vien_id` | `INT` | FK $\rightarrow$ `nhan_vien(id)`, UNIQUE | Quan hệ 1-1 với nhân viên | `101` |
| `username` | `VARCHAR(50)` | UNIQUE, NOT NULL | Tên đăng nhập | `'bs_nguyenvana'` |
| `password_hash` | `VARCHAR(255)` | NOT NULL | Mật khẩu băm BCrypt | `'$2a$12$...'` |
| `vai_tro` | `VARCHAR(30)` | NOT NULL | Quyền hệ thống | `'BAC_SI'` |
| `trang_thai` | `VARCHAR(20)` | CHECK, DEFAULT 'HOAT_DONG' | Tình trạng tài khoản | `'HOAT_DONG'` |

---

### 4. BẢNG `benh_nhan` (Hồ sơ bệnh nhân)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `SERIAL` | PK, NOT NULL | Khóa chính | `1001` |
| `ma_bn` | `VARCHAR(20)` | UNIQUE, NOT NULL | Mã bệnh nhân | `'BN_2026_0001'` |
| `ho_ten` | `VARCHAR(100)` | NOT NULL | Họ tên người bệnh | `'Trần Thị B'` |
| `ngay_sinh` | `DATE` | NOT NULL | Ngày tháng năm sinh | `'1995-05-15'` |
| `gioi_tinh` | `VARCHAR(10)` | CHECK ('NAM','NU','KHAC') | Giới tính | `'NU'` |
| `cccd` | `VARCHAR(20)` | UNIQUE, NOT NULL | Số CCCD/Định danh | `'001195012345'` |
| `so_dien_thoai` | `VARCHAR(15)` | | Số điện thoại | `'0988776655'` |
| `dia_chi` | `TEXT` | | Địa chỉ cư trú | `'Hà Đông, Hà Nội'` |
| `tien_su_benh` | `TEXT` | | Dị ứng thuốc, tiền sử bệnh | `'Dị ứng Penicillin'` |

---

### 5. BẢNG `the_bhyt` (Bảo hiểm y tế)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `SERIAL` | PK, NOT NULL | Khóa chính | `1` |
| `benh_nhan_id` | `INT` | FK $\rightarrow$ `benh_nhan(id)` | Thuộc bệnh nhân nào | `1001` |
| `ma_the` | `VARCHAR(15)` | UNIQUE, CHECK LENGTH=15 | Mã thẻ BHYT chuẩn quốc gia | `'DN4010123456789'` |
| `ngay_hieu_luc` | `DATE` | NOT NULL | Ngày bắt đầu có giá trị | `'2026-01-01'` |
| `ngay_het_han` | `DATE` | NOT NULL, CHECK > hieu_luc | Ngày hết giá trị | `'2026-12-31'` |
| `muc_huong` | `INT` | CHECK BETWEEN 0 AND 100 | Tỷ lệ BHYT thanh toán (%) | `80` |

---

### 6. BẢNG `ca_kham` (Hồ sơ lượt khám - Bảng đo hiệu năng $\ge 100.000$ dòng)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | PK, NOT NULL | Khóa chính tự tăng | `50001` |
| `ma_ca_kham` | `VARCHAR(30)` | UNIQUE, NOT NULL | Mã ca khám bệnh | `'CK_20261120_001'` |
| `benh_nhan_id` | `INT` | FK $\rightarrow$ `benh_nhan(id)` | Người đến khám | `1001` |
| `bac_si_id` | `INT` | FK $\rightarrow$ `nhan_vien(id)` | Bác sĩ trực tiếp khám | `101` |
| `phong_kham_id`| `INT` | FK $\rightarrow$ `khoa_phong(id)`| Phòng khám thực hiện | `5` |
| `ngay_kham` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Thời điểm khám | `'2026-11-20 08:30:00'` |
| `trieu_chung` | `TEXT` | | Mô tả triệu chứng lâm sàng | `'Đau bụng thượng vị'` |
| `chan_doan` | `TEXT` | | Kết luận chẩn đoán ICD | `'Viêm loét dạ dày'` |
| `trang_thai` | `VARCHAR(20)` | CHECK (CHO_KHAM, DANG_KHAM...) | Trạng thái ca khám | `'HOAN_THANH'` |

---

### 7. BẢNG `thuoc` (Danh mục thuốc)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `SERIAL` | PK, NOT NULL | Khóa chính | `50` |
| `ma_thuoc` | `VARCHAR(20)` | UNIQUE, NOT NULL | Mã dược phẩm | `'TH_PARA500'` |
| `ten_thuoc` | `VARCHAR(150)` | NOT NULL | Tên biệt dược | `'Paracetamol 500mg'` |
| `hoat_chat` | `VARCHAR(150)` | NOT NULL | Thành phần hoạt chất | `'Paracetamol'` |
| `don_vi_tinh` | `VARCHAR(30)` | NOT NULL | Đơn vị bán lẻ | `'VIEN'` |
| `gia_ban` | `NUMERIC(12,2)` | CHECK >= 0 | Đơn giá bán lẻ (VNĐ) | `2000.00` |

---

### 8. BẢNG `lo_thuoc` (Quản lý lô & tồn kho)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `SERIAL` | PK, NOT NULL | Khóa chính | `201` |
| `thuoc_id` | `INT` | FK $\rightarrow$ `thuoc(id)` | Thuộc thuốc nào | `50` |
| `so_lo` | `VARCHAR(50)` | UNIQUE với `thuoc_id` | Số lô nhà sản xuất | `'L2610A'` |
| `ngay_san_xuat`| `DATE` | NOT NULL | Ngày sản xuất | `'2026-01-10'` |
| `han_su_dung` | `DATE` | CHECK > ngay_san_xuat | Ngày hết hạn | `'2028-01-10'` |
| `so_luong_nhap`| `INT` | CHECK > 0 | Tổng số lượng nhập kho | `10000` |
| `so_luong_ton` | `INT` | CHECK >= 0 | Tồn khả dụng hiện tại | `4500` |
| `gia_nhap` | `NUMERIC(12,2)` | CHECK >= 0 | Giá nhập vào kho | `1500.00` |

---

### 9. BẢNG `don_thuoc` (Đơn thuốc điện tử - Bảng giao dịch $\ge 10.000$ dòng)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | PK, NOT NULL | Khóa chính | `12001` |
| `ma_don` | `VARCHAR(30)` | UNIQUE, NOT NULL | Mã đơn thuốc | `'DT_20261120_001'` |
| `ca_kham_id` | `BIGINT` | FK $\rightarrow$ `ca_kham(id)` | Kê cho ca khám nào | `50001` |
| `bac_si_id` | `INT` | FK $\rightarrow$ `nhan_vien(id)` | Bác sĩ kê đơn | `101` |
| `ngay_ke` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Thời gian kê đơn | `'2026-11-20 09:00:00'` |
| `trang_thai` | `VARCHAR(20)` | CHECK (CHO_XUAT, DA_XUAT...) | Tình trạng đơn thuốc | `'DA_XUAT'` |

---

### 10. BẢNG `chi_tiet_don_thuoc` (Thuốc được kê trong đơn)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | PK, NOT NULL | Khóa chính | `80001` |
| `don_thuoc_id` | `BIGINT` | FK $\rightarrow$ `don_thuoc(id)` | Thuộc đơn thuốc nào | `12001` |
| `lo_thuoc_id` | `INT` | FK $\rightarrow$ `lo_thuoc(id)` | Xuất từ lô nào | `201` |
| `so_luong` | `INT` | CHECK > 0 | Số lượng cấp phát | `20` |
| `don_gia` | `NUMERIC(12,2)` | CHECK >= 0 | Đơn giá tại thời điểm kê | `2000.00` |
| `lieu_dung` | `VARCHAR(100)` | NOT NULL | Liều dùng chỉ định | `'Sáng 1 viên, Tối 1 viên'` |
| `cach_dung` | `VARCHAR(100)` | NOT NULL | Cách sử dụng | `'Uống sau ăn no'` |

---

### 11. BẢNG `hoa_don` (Hóa đơn viện phí)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | PK, NOT NULL | Khóa chính | `12001` |
| `ma_hd` | `VARCHAR(30)` | UNIQUE, NOT NULL | Mã hóa đơn | `'HD_20261120_001'` |
| `ca_kham_id` | `BIGINT` | FK $\rightarrow$ `ca_kham(id)`, UNIQUE | Quyết toán cho ca khám | `50001` |
| `nhan_vien_thu_id` | `INT` | FK $\rightarrow$ `nhan_vien(id)` | Thu ngân thu tiền | `102` |
| `tien_kham` | `NUMERIC(12,2)` | CHECK >= 0 | Tiền công khám | `150000.00` |
| `tien_cls` | `NUMERIC(12,2)` | CHECK >= 0 | Tổng tiền xét nghiệm | `300000.00` |
| `tien_thuoc` | `NUMERIC(12,2)` | CHECK >= 0 | Tổng tiền thuốc | `40000.00` |
| `tien_bhyt_chi_tra` | `NUMERIC(12,2)` | CHECK >= 0 | Số tiền BHYT chi trả | `240000.00` |
| `tong_tien_thanh_toan`| `NUMERIC(12,2)` | CHECK >= 0 | Số tiền bệnh nhân phải nộp | `250000.00` |
| `trang_thai` | `VARCHAR(20)` | CHECK (CHO_THANH_TOAN, DA_THANH_TOAN) | Tình trạng hóa đơn | `'DA_THANH_TOAN'` |

---

### 12. BẢNG `audit_log` (Kiểm toán JSONB - Yêu cầu riêng DT01)
| Tên cột | Kiểu dữ liệu | Ràng buộc | Ý nghĩa nghiệp vụ | Ví dụ mẫu |
| :--- | :--- | :--- | :--- | :--- |
| `id` | `BIGSERIAL` | PK, NOT NULL | Khóa chính | `90001` |
| `table_name` | `VARCHAR(50)` | NOT NULL | Tên bảng bị tác động | `'chi_tiet_don_thuoc'` |
| `action` | `VARCHAR(10)` | CHECK ('INSERT','UPDATE','DELETE') | Loại thao tác | `'UPDATE'` |
| `record_id` | `VARCHAR(50)` | NOT NULL | ID của bản ghi bị sửa | `'80001'` |
| `changed_by` | `VARCHAR(50)` | NOT NULL | Người thực hiện | `'bs_nguyenvana'` |
| `changed_at` | `TIMESTAMP` | NOT NULL, DEFAULT NOW() | Thời gian thực hiện | `'2026-11-20 09:15:30'` |
| `change_data` | `JSONB` | NOT NULL | Chi tiết thay đổi trước và sau | `{"old": {"so_luong": 10}, "new": {"so_luong": 20}}` |
