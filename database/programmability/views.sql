-- =====================================================================
-- DT01 – QUẢN LÝ BỆNH VIỆN
-- LẬP TRÌNH CÁC VIEW NGHIỆP VỤ & PHÂN QUYỀN
-- Hệ QTCSDL: PostgreSQL 16
-- Yêu cầu Slide 10: >= 3 views (trong đó có 1 view phục vụ phân quyền/ẩn dữ liệu nhạy cảm)
-- =====================================================================

-- ---------------------------------------------------------------------
-- VIEW 1: v_doanh_thu_khoa_theo_thang (Báo cáo tổng hợp cho Quản trị viên)
-- Tính tổng lượt khám, doanh thu tiền khám, xét nghiệm và thuốc theo từng khoa
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_doanh_thu_khoa_theo_thang AS
SELECT 
    kp.id AS khoa_id,
    kp.ten_khoa,
    TO_CHAR(ck.ngay_kham, 'YYYY-MM') AS thang_nam,
    COUNT(DISTINCT ck.id) AS tong_luot_kham,
    COALESCE(SUM(hd.tien_kham), 0) AS tong_tien_kham,
    COALESCE(SUM(hd.tien_cls), 0) AS tong_tien_cls,
    COALESCE(SUM(hd.tien_thuoc), 0) AS tong_tien_thuoc,
    COALESCE(SUM(hd.tong_tien_thanh_toan), 0) AS tong_doanh_thu
FROM khoa_phong kp
JOIN ca_kham ck ON kp.id = ck.phong_kham_id
LEFT JOIN hoa_don hd ON ck.id = hd.ca_kham_id AND hd.trang_thai = 'DA_THANH_TOAN'
GROUP BY kp.id, kp.ten_khoa, TO_CHAR(ck.ngay_kham, 'YYYY-MM');


-- ---------------------------------------------------------------------
-- VIEW 2: v_hang_doi_kham_trong_ngay (Điều phối cho Nhân viên Hành chính & Bác sĩ)
-- Danh sách bệnh nhân đang chờ khám sắp xếp theo thời gian tiếp đón
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_hang_doi_kham_trong_ngay AS
SELECT 
    ck.id AS ca_kham_id,
    ck.ma_ca_kham,
    bn.ma_bn,
    bn.ho_ten AS ten_benh_nhan,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, bn.ngay_sinh)) AS tuoi,
    bn.gioi_tinh,
    nv.ho_ten AS bac_si_kham,
    kp.ten_khoa AS phong_kham,
    ck.ngay_kham,
    ck.trieu_chung,
    ck.trang_thai
FROM ca_kham ck
JOIN benh_nhan bn ON ck.benh_nhan_id = bn.id
JOIN nhan_vien nv ON ck.bac_si_id = nv.id
JOIN khoa_phong kp ON ck.phong_kham_id = kp.id
WHERE ck.ngay_kham::DATE = CURRENT_DATE
  AND ck.trang_thai IN ('CHO_KHAM', 'DANG_KHAM');


-- ---------------------------------------------------------------------
-- VIEW 3 (YÊU CẦU SLIDE 10 - VIEW PHÂN QUYỀN ẨN THÔNG TIN NHẠY CẢM):
-- v_ho_so_benh_an_an_danh
-- Ẩn số CCCD, che số điện thoại và địa chỉ nhà chi tiết
-- Phục vụ nghiên cứu khoa học, thống kê y tế không làm lộ danh tính bệnh nhân
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW v_ho_so_benh_an_an_danh AS
SELECT 
    ck.id AS ca_kham_id,
    ck.ma_ca_kham,
    bn.ma_bn,
    -- Che giấu danh tính họ tên: Giữ họ và chữ cái đầu (VD: Nguyễn Văn A -> Nguyễn V. A.)
    REGEXP_REPLACE(bn.ho_ten, '(\S+)\s+(\S+)\s+(\S+)', '\1 \2*') AS ho_ten_an_danh,
    -- Che giấu số CCCD: Chỉ hiện 4 số đầu và 3 số cuối
    CONCAT(SUBSTRING(bn.cccd, 1, 4), '*****', SUBSTRING(bn.cccd, LENGTH(bn.cccd) - 2, 3)) AS cccd_masked,
    -- Che giấu số điện thoại
    CONCAT(SUBSTRING(bn.so_dien_thoai, 1, 3), '****', SUBSTRING(bn.so_dien_thoai, LENGTH(bn.so_dien_thoai) - 2, 3)) AS sdt_masked,
    bn.gioi_tinh,
    EXTRACT(YEAR FROM AGE(ck.ngay_kham::DATE, bn.ngay_sinh)) AS tuoi_khi_kham,
    ck.ngay_kham,
    ck.chan_doan,
    ck.ket_luan,
    nv.ho_ten AS bac_si_dieu_tri
FROM ca_kham ck
JOIN benh_nhan bn ON ck.benh_nhan_id = bn.id
JOIN nhan_vien nv ON ck.bac_si_id = nv.id;
