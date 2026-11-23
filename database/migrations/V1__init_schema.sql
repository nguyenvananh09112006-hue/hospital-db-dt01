-- =====================================================================
-- DT01 – QUẢN LÝ BỆNH VIỆN
-- Flyway Migration V1: Khởi tạo lược đồ vật lý (15 bảng)
-- Hệ QTCSDL: PostgreSQL 16
-- Đảm bảo: PK, FK (ON DELETE/UPDATE), UNIQUE, CHECK, NOT NULL, DEFAULT
-- =====================================================================

-- 1. BẢNG KHOA PHÒNG (Có quan hệ phân cấp cây qua parent_id)
CREATE TABLE khoa_phong (
    id SERIAL PRIMARY KEY,
    ma_khoa VARCHAR(20) UNIQUE NOT NULL,
    ten_khoa VARCHAR(100) NOT NULL,
    loai_khoa VARCHAR(50) NOT NULL, -- 'KHOA_CHUYEN_MON', 'PHONG_KHAM', 'PHONG_XET_NGHIEM', 'KHO_DUOC'
    parent_id INT REFERENCES khoa_phong(id) ON DELETE SET NULL,
    mo_ta TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. BẢNG NHÂN VIÊN
CREATE TABLE nhan_vien (
    id SERIAL PRIMARY KEY,
    ma_nv VARCHAR(20) UNIQUE NOT NULL,
    ho_ten VARCHAR(100) NOT NULL,
    chuc_vu VARCHAR(50) NOT NULL, -- 'BAC_SI', 'DUOC_SI', 'HANH_CHINH', 'QUAN_TRI'
    khoa_phong_id INT NOT NULL REFERENCES khoa_phong(id) ON DELETE RESTRICT,
    so_dien_thoai VARCHAR(15),
    email VARCHAR(100),
    so_chung_chi_hanh_nghe VARCHAR(50),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. BẢNG TÀI KHOẢN (Quan hệ 1-1 với nhan_vien)
CREATE TABLE tai_khoan (
    id SERIAL PRIMARY KEY,
    nhan_vien_id INT UNIQUE NOT NULL REFERENCES nhan_vien(id) ON DELETE CASCADE,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    vai_tro VARCHAR(30) NOT NULL, -- 'ADMIN', 'BAC_SI', 'DUOC_SI', 'HANH_CHINH'
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'HOAT_DONG',
    CONSTRAINT chk_trang_thai_tk CHECK (trang_thai IN ('HOAT_DONG', 'KHOA', 'TAM_NGUNG'))
);

-- 4. BẢNG BỆNH NHÂN
CREATE TABLE benh_nhan (
    id SERIAL PRIMARY KEY,
    ma_bn VARCHAR(20) UNIQUE NOT NULL,
    ho_ten VARCHAR(100) NOT NULL,
    ngay_sinh DATE NOT NULL,
    gioi_tinh VARCHAR(10) NOT NULL,
    cccd VARCHAR(20) UNIQUE NOT NULL,
    so_dien_thoai VARCHAR(15),
    dia_chi TEXT,
    tien_su_benh TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_gioi_tinh CHECK (gioi_tinh IN ('NAM', 'NU', 'KHAC'))
);

-- 5. BẢNG THẺ BẢO HIỂM Y TẾ (Thực thể yếu phụ thuộc benh_nhan)
CREATE TABLE the_bhyt (
    id SERIAL PRIMARY KEY,
    benh_nhan_id INT NOT NULL REFERENCES benh_nhan(id) ON DELETE CASCADE,
    ma_the VARCHAR(15) UNIQUE NOT NULL,
    ngay_hieu_luc DATE NOT NULL,
    ngay_het_han DATE NOT NULL,
    muc_huong INT NOT NULL DEFAULT 80,
    noi_dang_ky_kcb VARCHAR(200),
    CONSTRAINT chk_bhyt_do_dai CHECK (LENGTH(ma_the) = 15),
    CONSTRAINT chk_bhyt_han_dung CHECK (ngay_het_han > ngay_hieu_luc),
    CONSTRAINT chk_muc_huong CHECK (muc_huong BETWEEN 0 AND 100)
);

-- 6. BẢNG LỊCH HẸN KHÁM
CREATE TABLE lich_hen (
    id SERIAL PRIMARY KEY,
    benh_nhan_id INT NOT NULL REFERENCES benh_nhan(id) ON DELETE RESTRICT,
    bac_si_id INT NOT NULL REFERENCES nhan_vien(id) ON DELETE RESTRICT,
    khoa_phong_id INT NOT NULL REFERENCES khoa_phong(id) ON DELETE RESTRICT,
    ngay_hen DATE NOT NULL,
    ca_kham VARCHAR(10) NOT NULL, -- 'SANG', 'CHIEU'
    ly_do_kham TEXT,
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'CHO_KHAM',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_ca_kham CHECK (ca_kham IN ('SANG', 'CHIEU')),
    CONSTRAINT chk_trang_thai_lich CHECK (trang_thai IN ('CHO_KHAM', 'DA_DEN', 'DA_HUY')),
    CONSTRAINT uq_lich_bac_si UNIQUE (bac_si_id, ngay_hen, ca_kham) -- BR01: Chống trùng lịch bác sĩ
);

-- 7. BẢNG CA KHÁM / HỒ SƠ KHÁM (Bảng đo hiệu năng ≥ 100.000 dòng)
CREATE TABLE ca_kham (
    id BIGSERIAL PRIMARY KEY,
    ma_ca_kham VARCHAR(30) UNIQUE NOT NULL,
    benh_nhan_id INT NOT NULL REFERENCES benh_nhan(id) ON DELETE RESTRICT,
    bac_si_id INT NOT NULL REFERENCES nhan_vien(id) ON DELETE RESTRICT,
    phong_kham_id INT NOT NULL REFERENCES khoa_phong(id) ON DELETE RESTRICT,
    ngay_kham TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    trieu_chung TEXT,
    chan_doan TEXT,
    ket_luan TEXT,
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'CHO_KHAM',
    CONSTRAINT chk_trang_thai_ca_kham CHECK (trang_thai IN ('CHO_KHAM', 'DANG_KHAM', 'HOAN_THANH', 'DA_HUY'))
);

-- 8. BẢNG DANH MỤC DỊCH VỤ CẬN LÂM SÀNG
CREATE TABLE dich_vu_cls (
    id SERIAL PRIMARY KEY,
    ma_dv VARCHAR(20) UNIQUE NOT NULL,
    ten_dich_vu VARCHAR(150) NOT NULL,
    loai_dv VARCHAR(50) NOT NULL, -- 'XET_NGHIEM_MAU', 'X_QUANG', 'SIEU_AM', 'NOI_SOI'
    gia_tien NUMERIC(12,2) NOT NULL CHECK (gia_tien >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 9. BẢNG CHI TIẾT CHỈ ĐỊNH (Quan hệ n-n giữa ca_kham và dich_vu_cls)
CREATE TABLE chi_tiet_chi_dinh (
    id BIGSERIAL PRIMARY KEY,
    ca_kham_id BIGINT NOT NULL REFERENCES ca_kham(id) ON DELETE CASCADE,
    dich_vu_id INT NOT NULL REFERENCES dich_vu_cls(id) ON DELETE RESTRICT,
    bac_si_chi_dinh_id INT NOT NULL REFERENCES nhan_vien(id) ON DELETE RESTRICT,
    ngay_chi_dinh TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ket_qua TEXT,
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'CHO_THUC_HIEN',
    CONSTRAINT chk_trang_thai_cls CHECK (trang_thai IN ('CHO_THUC_HIEN', 'DANG_THUC_HIEN', 'DA_CO_KET_QUA', 'DA_HUY'))
);

-- 10. BẢNG DANH MỤC THUỐC
CREATE TABLE thuoc (
    id SERIAL PRIMARY KEY,
    ma_thuoc VARCHAR(20) UNIQUE NOT NULL,
    ten_thuoc VARCHAR(150) NOT NULL,
    hoat_chat VARCHAR(150) NOT NULL,
    don_vi_tinh VARCHAR(30) NOT NULL, -- 'VIEN', 'HOP', 'LO', 'GOI'
    quy_cach VARCHAR(100),
    gia_ban NUMERIC(12,2) NOT NULL CHECK (gia_ban >= 0),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- 11. BẢNG LÔ THUỐC (Thực thể yếu phụ thuộc thuoc, quản lý hạn dùng & tồn kho)
CREATE TABLE lo_thuoc (
    id SERIAL PRIMARY KEY,
    thuoc_id INT NOT NULL REFERENCES thuoc(id) ON DELETE RESTRICT,
    so_lo VARCHAR(50) NOT NULL,
    ngay_san_xuat DATE NOT NULL,
    han_su_dung DATE NOT NULL,
    so_luong_nhap INT NOT NULL CHECK (so_luong_nhap > 0),
    so_luong_ton INT NOT NULL CHECK (so_luong_ton >= 0),
    gia_nhap NUMERIC(12,2) NOT NULL CHECK (gia_nhap >= 0),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_thuoc_so_lo UNIQUE (thuoc_id, so_lo),
    CONSTRAINT chk_lo_han_dung CHECK (han_su_dung > ngay_san_xuat)
);

-- 12. BẢNG ĐƠN THUỐC (Bảng giao dịch chính ≥ 10.000 dòng)
CREATE TABLE don_thuoc (
    id BIGSERIAL PRIMARY KEY,
    ma_don VARCHAR(30) UNIQUE NOT NULL,
    ca_kham_id BIGINT NOT NULL REFERENCES ca_kham(id) ON DELETE CASCADE,
    bac_si_id INT NOT NULL REFERENCES nhan_vien(id) ON DELETE RESTRICT,
    ngay_ke TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ghi_chu TEXT,
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'CHO_XUAT',
    CONSTRAINT chk_trang_thai_don CHECK (trang_thai IN ('CHO_XUAT', 'DA_XUAT', 'DA_HUY'))
);

-- 13. BẢNG CHI TIẾT ĐƠN THUỐC (Quan hệ n-n giữa don_thuoc và lo_thuoc)
CREATE TABLE chi_tiet_don_thuoc (
    id BIGSERIAL PRIMARY KEY,
    don_thuoc_id BIGINT NOT NULL REFERENCES don_thuoc(id) ON DELETE CASCADE,
    lo_thuoc_id INT NOT NULL REFERENCES lo_thuoc(id) ON DELETE RESTRICT,
    so_luong INT NOT NULL CHECK (so_luong > 0),
    don_gia NUMERIC(12,2) NOT NULL CHECK (don_gia >= 0),
    lieu_dung VARCHAR(100) NOT NULL,
    cach_dung VARCHAR(100) NOT NULL
);

-- 14. BẢNG HÓA ĐƠN VIỆN PHÍ
CREATE TABLE hoa_don (
    id BIGSERIAL PRIMARY KEY,
    ma_hd VARCHAR(30) UNIQUE NOT NULL,
    ca_kham_id BIGINT UNIQUE NOT NULL REFERENCES ca_kham(id) ON DELETE RESTRICT,
    nhan_vien_thu_id INT NOT NULL REFERENCES nhan_vien(id) ON DELETE RESTRICT,
    tien_kham NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (tien_kham >= 0),
    tien_cls NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (tien_cls >= 0),
    tien_thuoc NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (tien_thuoc >= 0),
    tien_bhyt_chi_tra NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (tien_bhyt_chi_tra >= 0),
    tong_tien_thanh_toan NUMERIC(12,2) NOT NULL CHECK (tong_tien_thanh_toan >= 0),
    ngay_lap TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'CHO_THANH_TOAN',
    CONSTRAINT chk_trang_thai_hd CHECK (trang_thai IN ('CHO_THANH_TOAN', 'DA_THANH_TOAN', 'DA_HUY'))
);

-- 15. BẢNG NHẬT KÝ KIỂM TOÁN (Yêu cầu riêng DT01: Lưu vết JSONB)
CREATE TABLE audit_log (
    id BIGSERIAL PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    action VARCHAR(10) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    record_id VARCHAR(50) NOT NULL,
    changed_by VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    change_data JSONB NOT NULL
);
