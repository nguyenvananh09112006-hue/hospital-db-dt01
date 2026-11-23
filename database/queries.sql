-- =====================================================================
-- DT01 – QUẢN LÝ BỆNH VIỆN: TRUY VẤN NGHIỆP VỤ (20 CÂU BẮT BUỘC)
-- Hệ QTCSDL: PostgreSQL 16
-- Yêu cầu Slide 10: Đầy đủ JOIN >= 3 bảng, OUTER JOIN, GROUP BY + HAVING,
-- Correlated Subquery, CTE đệ quy, Window Function, Phép chia / NOT EXISTS.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q01. Lấy danh sách bệnh nhân khám hôm nay kèm bác sĩ phụ trách và phòng khám
-- Kỹ thuật: JOIN 4 bảng
-- ---------------------------------------------------------------------
SELECT 
    ck.ma_ca_kham,
    bn.ho_ten AS ten_benh_nhan,
    bn.cccd,
    nv.ho_ten AS bac_si_kham,
    kp.ten_khoa AS phong_kham,
    ck.ngay_kham,
    ck.trang_thai
FROM ca_kham ck
JOIN benh_nhan bn ON ck.benh_nhan_id = bn.id
JOIN nhan_vien nv ON ck.bac_si_id = nv.id
JOIN khoa_phong kp ON ck.phong_kham_id = kp.id
WHERE ck.ngay_kham::DATE = CURRENT_DATE;


-- ---------------------------------------------------------------------
-- Q02. Thống kê tất cả các loại thuốc trong danh mục và số lần được kê (kể cả thuốc chưa bao giờ kê)
-- Kỹ thuật: OUTER JOIN (LEFT JOIN) + GROUP BY
-- ---------------------------------------------------------------------
SELECT 
    t.ma_thuoc,
    t.ten_thuoc,
    t.hoat_chat,
    COUNT(ct.id) AS so_lan_duoc_ke,
    COALESCE(SUM(ct.so_luong), 0) AS tong_so_luong_ke
FROM thuoc t
LEFT JOIN lo_thuoc lt ON t.id = lt.thuoc_id
LEFT JOIN chi_tiet_don_thuoc ct ON lt.id = ct.lo_thuoc_id
GROUP BY t.id, t.ma_thuoc, t.ten_thuoc, t.hoat_chat
ORDER BY so_lan_duoc_ke DESC;


-- ---------------------------------------------------------------------
-- Q03. Tìm các bác sĩ có trên 10 ca khám trong tháng và doanh thu tiền khám trên 1.500.000 VNĐ
-- Kỹ thuật: GROUP BY + HAVING
-- ---------------------------------------------------------------------
SELECT 
    nv.ma_nv,
    nv.ho_ten AS ten_bac_si,
    COUNT(ck.id) AS so_ca_kham,
    SUM(hd.tien_kham) AS tong_tien_kham
FROM nhan_vien nv
JOIN ca_kham ck ON nv.id = ck.bac_si_id
JOIN hoa_don hd ON ck.id = hd.ca_kham_id
WHERE hd.trang_thai = 'DA_THANH_TOAN'
  AND hd.ngay_lap >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY nv.id, nv.ma_nv, nv.ho_ten
HAVING COUNT(ck.id) >= 10 AND SUM(hd.tien_kham) >= 1500000;


-- ---------------------------------------------------------------------
-- Q04. Tìm các ca khám có tiền thuốc cao hơn mức tiền thuốc trung bình của chính khoa đó
-- Kỹ thuật: Truy vấn con tương quan (Correlated Subquery)
-- ---------------------------------------------------------------------
SELECT 
    ck.ma_ca_kham,
    ck.ngay_kham,
    kp.ten_khoa,
    hd.tien_thuoc
FROM ca_kham ck
JOIN khoa_phong kp ON ck.phong_kham_id = kp.id
JOIN hoa_don hd ON ck.id = hd.ca_kham_id
WHERE hd.tien_thuoc > (
    SELECT AVG(hd2.tien_thuoc)
    FROM ca_kham ck2
    JOIN hoa_don hd2 ON ck2.id = hd2.ca_kham_id
    WHERE ck2.phong_kham_id = ck.phong_kham_id
      AND hd2.trang_thai = 'DA_THANH_TOAN'
);


-- ---------------------------------------------------------------------
-- Q05. Truy vấn sơ đồ cây phân cấp khoa phòng bệnh viện (từ Khoa cha đến Phòng con)
-- Kỹ thuật: CTE ĐỆ QUY (RECURSIVE CTE) - Bắt buộc theo Slide 10
-- ---------------------------------------------------------------------
WITH RECURSIVE cay_khoa_phong AS (
    -- Điểm neo: Các khoa đầu ngành (không có khoa cha)
    SELECT 
        id, ma_khoa, ten_khoa, parent_id, 1 AS cap_do,
        ten_khoa::TEXT AS duong_dan
    FROM khoa_phong
    WHERE parent_id IS NULL

    UNION ALL

    -- Phần đệ quy: Tìm các phòng ban/buồng khám con
    SELECT 
        kp.id, kp.ma_khoa, kp.ten_khoa, kp.parent_id, c.cap_do + 1,
        c.duong_dan || ' -> ' || kp.ten_khoa
    FROM khoa_phong kp
    JOIN cay_khoa_phong c ON kp.parent_id = c.id
)
SELECT id, ma_khoa, cap_do, duong_dan
FROM cay_khoa_phong
ORDER BY duong_dan;


-- ---------------------------------------------------------------------
-- Q06. Xếp hạng top 3 thuốc được kê nhiều nhất trong từng tháng
-- Kỹ thuật: Window function DENSE_RANK() OVER (PARTITION BY ... ORDER BY ...)
-- ---------------------------------------------------------------------
WITH thong_ke_thuoc AS (
    SELECT 
        TO_CHAR(dt.ngay_ke, 'YYYY-MM') AS thang_nam,
        t.ten_thuoc,
        SUM(ct.so_luong) AS tong_so_luong,
        DENSE_RANK() OVER (
            PARTITION BY TO_CHAR(dt.ngay_ke, 'YYYY-MM') 
            ORDER BY SUM(ct.so_luong) DESC
        ) AS xep_hang
    FROM don_thuoc dt
    JOIN chi_tiet_don_thuoc ct ON dt.id = ct.don_thuoc_id
    JOIN lo_thuoc lt ON ct.lo_thuoc_id = lt.id
    JOIN thuoc t ON lt.thuoc_id = t.id
    WHERE dt.trang_thai = 'DA_XUAT'
    GROUP BY TO_CHAR(dt.ngay_ke, 'YYYY-MM'), t.id, t.ten_thuoc
)
SELECT thang_nam, xep_hang, ten_thuoc, tong_so_luong
FROM thong_ke_thuoc
WHERE xep_hang <= 3;


-- ---------------------------------------------------------------------
-- Q07. Tính doanh thu viện phí tích lũy (Running Total) theo từng ngày trong tháng
-- Kỹ thuật: Window function SUM() OVER (ORDER BY ...)
-- ---------------------------------------------------------------------
SELECT 
    ngay_lap::DATE AS ngay,
    SUM(tong_tien_thanh_toan) AS doanh_thu_trong_ngay,
    SUM(SUM(tong_tien_thanh_toan)) OVER (
        ORDER BY ngay_lap::DATE 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS doanh_thu_tich_luy
FROM hoa_don
WHERE trang_thai = 'DA_THANH_TOAN'
  AND ngay_lap >= DATE_TRUNC('month', CURRENT_DATE)
GROUP BY ngay_lap::DATE
ORDER BY ngay;


-- ---------------------------------------------------------------------
-- Q08. Tìm những bệnh nhân đã thực hiện TẤT CẢ các xét nghiệm trong danh mục 'XET_NGHIEM_MAU'
-- Kỹ thuật: Phép chia quan hệ sử dụng NOT EXISTS kép (Slide 10)
-- ---------------------------------------------------------------------
SELECT bn.id, bn.ma_bn, bn.ho_ten
FROM benh_nhan bn
WHERE NOT EXISTS (
    -- Tất cả các dịch vụ xét nghiệm máu
    SELECT dv.id
    FROM dich_vu_cls dv
    WHERE dv.loai_dv = 'XET_NGHIEM_MAU' AND dv.is_active = TRUE
    EXCEPT
    -- Các dịch vụ mà bệnh nhân này đã từng làm
    SELECT ctd.dich_vu_id
    FROM ca_kham ck
    JOIN chi_tiet_chi_dinh ctd ON ck.id = ctd.ca_kham_id
    WHERE ck.benh_nhan_id = bn.id AND ctd.trang_thai = 'DA_CO_KET_QUA'
);


-- ---------------------------------------------------------------------
-- Q09. Tìm các lô thuốc sắp hết hạn trong vòng 30 ngày tới nhưng vẫn còn tồn kho > 0
-- Kỹ thuật: Điều kiện lọc ngày tháng + JOIN
-- ---------------------------------------------------------------------
SELECT 
    t.ma_thuoc,
    t.ten_thuoc,
    lt.so_lo,
    lt.han_su_dung,
    lt.so_luong_ton,
    (lt.han_su_dung - CURRENT_DATE) AS so_ngay_con_lai
FROM lo_thuoc lt
JOIN thuoc t ON lt.thuoc_id = t.id
WHERE lt.so_luong_ton > 0
  AND lt.han_su_dung BETWEEN CURRENT_DATE AND (CURRENT_DATE + INTERVAL '30 days')
ORDER BY lt.han_su_dung ASC;


-- ---------------------------------------------------------------------
-- Q10. Thống kê chi phí trung bình một ca khám theo từng nhóm tuổi bệnh nhân (<18, 18-60, >60)
-- Kỹ thuật: CASE WHEN + GROUP BY
-- ---------------------------------------------------------------------
SELECT 
    CASE 
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, bn.ngay_sinh)) < 18 THEN 'Tre em (<18)'
        WHEN EXTRACT(YEAR FROM AGE(CURRENT_DATE, bn.ngay_sinh)) BETWEEN 18 AND 60 THEN 'Nguoi lon (18-60)'
        ELSE 'Nguoi cao tuoi (>60)'
    END AS nhom_tuoi,
    COUNT(ck.id) AS tong_ca_kham,
    ROUND(AVG(hd.tong_tien_thanh_toan), 2) AS chi_phi_trung_binh
FROM ca_kham ck
JOIN benh_nhan bn ON ck.benh_nhan_id = bn.id
JOIN hoa_don hd ON ck.id = hd.ca_kham_id
WHERE hd.trang_thai = 'DA_THANH_TOAN'
GROUP BY nhom_tuoi;


-- ---------------------------------------------------------------------
-- Q11. Tìm các bác sĩ chưa từng kê đơn loại thuốc chứa hoạt chất 'Paracetamol'
-- Kỹ thuật: NOT IN với Subquery
-- ---------------------------------------------------------------------
SELECT nv.id, nv.ma_nv, nv.ho_ten
FROM nhan_vien nv
WHERE nv.chuc_vu = 'BAC_SI'
  AND nv.id NOT IN (
      SELECT DISTINCT dt.bac_si_id
      FROM don_thuoc dt
      JOIN chi_tiet_don_thuoc ctd ON dt.id = ctd.don_thuoc_id
      JOIN lo_thuoc lt ON ctd.lo_thuoc_id = lt.id
      JOIN thuoc t ON lt.thuoc_id = t.id
      WHERE t.hoat_chat ILIKE '%Paracetamol%'
  );


-- ---------------------------------------------------------------------
-- Q12. Lấy danh sách bệnh nhân có bảo hiểm Y tế đã khám bệnh trên 3 lần trong năm
-- Kỹ thuật: JOIN + GROUP BY + HAVING
-- ---------------------------------------------------------------------
SELECT 
    bn.ma_bn,
    bn.ho_ten,
    tb.ma_the AS ma_bhyt,
    tb.muc_huong,
    COUNT(ck.id) AS so_lan_kham
FROM benh_nhan bn
JOIN the_bhyt tb ON bn.id = tb.benh_nhan_id
JOIN ca_kham ck ON bn.id = ck.benh_nhan_id
WHERE EXTRACT(YEAR FROM ck.ngay_kham) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY bn.id, bn.ma_bn, bn.ho_ten, tb.ma_the, tb.muc_huong
HAVING COUNT(ck.id) >= 3;


-- ---------------------------------------------------------------------
-- Q13. Thống kê top 5 dịch vụ cận lâm sàng mang lại doanh thu cao nhất
-- Kỹ thuật: JOIN + AGGREGATION + LIMIT
-- ---------------------------------------------------------------------
SELECT 
    dv.ma_dv,
    dv.ten_dich_vu,
    dv.loai_dv,
    COUNT(ct.id) AS so_lan_chi_dinh,
    SUM(dv.gia_tien) AS tong_doanh_thu
FROM dich_vu_cls dv
JOIN chi_tiet_chi_dinh ct ON dv.id = ct.dich_vu_id
WHERE ct.trang_thai = 'DA_CO_KET_QUA'
GROUP BY dv.id, dv.ma_dv, dv.ten_dich_vu, dv.loai_dv
ORDER BY tong_doanh_thu DESC
LIMIT 5;


-- ---------------------------------------------------------------------
-- Q14. Tìm kiếm các đơn thuốc đã bị chỉnh sửa liều lượng sau khi kê từ bảng audit_log
-- Kỹ thuật: Truy vấn dữ liệu JSONB (Slide 12 DT01)
-- ---------------------------------------------------------------------
SELECT 
    a.id AS audit_id,
    a.record_id AS chi_tiet_don_id,
    a.changed_by,
    a.changed_at,
    a.change_data->'diff'->>'old_so_luong' AS so_luong_cu,
    a.change_data->'diff'->>'new_so_luong' AS so_luong_moi
FROM audit_log a
WHERE a.table_name = 'chi_tiet_don_thuoc'
  AND a.action = 'UPDATE'
  AND a.change_data->'diff'->>'old_so_luong' IS NOT NULL;


-- ---------------------------------------------------------------------
-- Q15. Tính khoảng thời gian chờ khám trung bình của bệnh nhân theo từng ngày
-- Kỹ thuật: Phép trừ ngày tháng TIMESTAMP
-- ---------------------------------------------------------------------
SELECT 
    lh.ngay_hen,
    COUNT(ck.id) AS tong_ca,
    ROUND(AVG(EXTRACT(EPOCH FROM (ck.ngay_kham - (lh.ngay_hen || ' 07:30:00')::TIMESTAMP))/60), 1) AS phut_cho_trung_binh
FROM lich_hen lh
JOIN ca_kham ck ON lh.benh_nhan_id = ck.benh_nhan_id AND lh.ngay_hen = ck.ngay_kham::DATE
GROUP BY lh.ngay_hen;


-- ---------------------------------------------------------------------
-- Q16. Tìm các ca khám phát sinh chi phí cận lâm sàng nhưng không phát sinh chi phí tiền thuốc
-- Kỹ thuật: INTERSECT / EXCEPT
-- ---------------------------------------------------------------------
SELECT ca_kham_id FROM chi_tiet_chi_dinh WHERE trang_thai = 'DA_CO_KET_QUA'
EXCEPT
SELECT ca_kham_id FROM don_thuoc WHERE trang_thai = 'DA_XUAT';


-- ---------------------------------------------------------------------
-- Q17. Tính tỷ lệ phần trăm tiền thuốc trên tổng viện phí theo từng ca khám
-- Kỹ thuật: Toán tử chia và ép kiểu NUMERIC
-- ---------------------------------------------------------------------
SELECT 
    ma_hd,
    tong_tien_thanh_toan,
    tien_thuoc,
    CASE 
        WHEN tong_tien_thanh_toan > 0 
        THEN ROUND((tien_thuoc / tong_tien_thanh_toan) * 100, 2)
        ELSE 0 
    END AS ty_le_tien_thuoc_pt
FROM hoa_don
WHERE trang_thai = 'DA_THANH_TOAN'
ORDER BY ty_le_tien_thuoc_pt DESC;


-- ---------------------------------------------------------------------
-- Q18. Tìm bệnh nhân có tổng chi phí điều trị cao nhất trong tháng
-- Kỹ thuật: CTE + MAX
-- ---------------------------------------------------------------------
WITH tong_tien_benh_nhan AS (
    SELECT 
        bn.id, bn.ma_bn, bn.ho_ten,
        SUM(hd.tong_tien_thanh_toan) AS tong_chi_tra
    FROM benh_nhan bn
    JOIN ca_kham ck ON bn.id = ck.benh_nhan_id
    JOIN hoa_don hd ON ck.id = hd.ca_kham_id
    WHERE hd.ngay_lap >= DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY bn.id, bn.ma_bn, bn.ho_ten
)
SELECT * FROM tong_tien_benh_nhan
WHERE tong_chi_tra = (SELECT MAX(tong_chi_tra) FROM tong_tien_benh_nhan);


-- ---------------------------------------------------------------------
-- Q19. Thống kê số lượng bệnh nhân khám theo giới tính và từng chuyên khoa
-- Kỹ thuật: PIVOT mô phỏng bằng CROSSTAB hoặc FILTER
-- ---------------------------------------------------------------------
SELECT 
    kp.ten_khoa,
    COUNT(ck.id) FILTER (WHERE bn.gioi_tinh = 'NAM') AS so_luong_nam,
    COUNT(ck.id) FILTER (WHERE bn.gioi_tinh = 'NU') AS so_luong_nu,
    COUNT(ck.id) AS tong_cong
FROM khoa_phong kp
JOIN ca_kham ck ON kp.id = ck.phong_kham_id
JOIN benh_nhan bn ON ck.benh_nhan_id = bn.id
GROUP BY kp.id, kp.ten_khoa;


-- ---------------------------------------------------------------------
-- Q20. Tìm các cặp bác sĩ thuộc cùng một khoa phòng nhưng có chức vụ khác nhau
-- Kỹ thuật: SELF JOIN
-- ---------------------------------------------------------------------
SELECT 
    nv1.ho_ten AS nhan_vien_1,
    nv1.chuc_vu AS chuc_vu_1,
    nv2.ho_ten AS nhan_vien_2,
    nv2.chuc_vu AS chuc_vu_2,
    kp.ten_khoa
FROM nhan_vien nv1
JOIN nhan_vien nv2 ON nv1.khoa_phong_id = nv2.khoa_phong_id AND nv1.id < nv2.id
JOIN khoa_phong kp ON nv1.khoa_phong_id = kp.id
WHERE nv1.chuc_vu <> nv2.chuc_vu;
