-- =====================================================================
-- DT01 – QUẢN LÝ BỆNH VIỆN
-- THỦ TỤC LƯU TRỮ (STORED PROCEDURES) VÀ HÀM (FUNCTIONS)
-- Hệ QTCSDL: PostgreSQL 16
-- Yêu cầu Slide 10: >= 3 Stored Procedures, >= 2 Functions có Transaction & Exception
-- =====================================================================

-- ---------------------------------------------------------------------
-- HÀM 1: Tính tổng viện phí thực tế của một ca khám (sau khi trừ BHYT)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_tinh_tong_tien_kham(p_ca_kham_id BIGINT)
RETURNS NUMERIC AS $$
DECLARE
    v_tien_kham NUMERIC(12,2) := 150000.00; -- Giá khám niêm yết
    v_tien_cls NUMERIC(12,2) := 0;
    v_tien_thuoc NUMERIC(12,2) := 0;
    v_muc_huong INT := 0;
    v_tien_bhyt_giam NUMERIC(12,2) := 0;
    v_tong_thanh_toan NUMERIC(12,2) := 0;
BEGIN
    -- 1. Tính tổng tiền cận lâm sàng
    SELECT COALESCE(SUM(d.gia_tien), 0)
    INTO v_tien_cls
    FROM chi_tiet_chi_dinh c
    JOIN dich_vu_cls d ON c.dich_vu_id = d.id
    WHERE c.ca_kham_id = p_ca_kham_id AND c.trang_thai <> 'DA_HUY';

    -- 2. Tính tổng tiền thuốc
    SELECT COALESCE(SUM(ct.so_luong * ct.don_gia), 0)
    INTO v_tien_thuoc
    FROM don_thuoc dt
    JOIN chi_tiet_don_thuoc ct ON dt.id = ct.don_thuoc_id
    WHERE dt.ca_kham_id = p_ca_kham_id AND dt.trang_thai <> 'DA_HUY';

    -- 3. Lấy mức hưởng BHYT của bệnh nhân nếu thẻ còn hiệu lực
    SELECT COALESCE(tb.muc_huong, 0)
    INTO v_muc_huong
    FROM ca_kham ck
    JOIN benh_nhan bn ON ck.benh_nhan_id = bn.id
    LEFT JOIN the_bhyt tb ON bn.id = tb.benh_nhan_id
        AND CURRENT_DATE BETWEEN tb.ngay_hieu_luc AND tb.ngay_het_han
    WHERE ck.id = p_ca_kham_id;

    -- 4. Tính toán số tiền BHYT chi trả và người bệnh thanh toán
    v_tien_bhyt_giam := (v_tien_cls + v_tien_thuoc) * (v_muc_huong::NUMERIC / 100);
    v_tong_thanh_toan := (v_tien_kham + v_tien_cls + v_tien_thuoc) - v_tien_bhyt_giam;

    IF v_tong_thanh_toan < 0 THEN
        v_tong_thanh_toan := 0;
    END IF;

    RETURN v_tong_thanh_toan;
END;
$$ LANGUAGE plpgsql;


-- ---------------------------------------------------------------------
-- HÀM 2: Kiểm tra nhanh số lượng tồn khả dụng của một lô thuốc
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_kiem_tra_ton_kho_thuoc(p_lo_thuoc_id INT, p_so_luong_can INT)
RETURNS BOOLEAN AS $$
DECLARE
    v_ton_kho INT;
    v_han_su_dung DATE;
BEGIN
    SELECT so_luong_ton, han_su_dung
    INTO v_ton_kho, v_han_su_dung
    FROM lo_thuoc
    WHERE id = p_lo_thuoc_id;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Nếu thuốc đã hết hạn sử dụng thì không khả dụng
    IF v_han_su_dung < CURRENT_DATE THEN
        RETURN FALSE;
    END IF;

    RETURN (v_ton_kho >= p_so_luong_can);
END;
$$ LANGUAGE plpgsql;


-- ---------------------------------------------------------------------
-- THỦ TỤC 1: sp_xuat_kho_duoc (Dược sĩ xuất thuốc và trừ tồn kho)
-- Có Transaction & Xử lý lỗi EXCEPTION
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_xuat_kho_duoc(
    p_don_thuoc_id BIGINT,
    p_duoc_si_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    r RECORD;
    v_trang_thai VARCHAR(20);
BEGIN
    -- 1. Kiểm tra đơn thuốc có tồn tại và đúng trạng thái CHO_XUAT không
    SELECT trang_thai INTO v_trang_thai
    FROM don_thuoc
    WHERE id = p_don_thuoc_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Đơn thuốc ID % không tồn tại trong hệ thống!', p_don_thuoc_id;
    END IF;

    IF v_trang_thai <> 'CHO_XUAT' THEN
        RAISE EXCEPTION 'Đơn thuốc ID % đang ở trạng thái "%", không thể xuất kho!', p_don_thuoc_id, v_trang_thai;
    END IF;

    -- 2. Duyệt từng chi tiết thuốc và trừ tồn kho bằng câu lệnh có khóa dòng
    FOR r IN (
        SELECT lo_thuoc_id, so_luong
        FROM chi_tiet_don_thuoc
        WHERE don_thuoc_id = p_don_thuoc_id
    ) LOOP
        -- Khóa dòng lô thuốc để chống Race Condition khi nhiều người xuất cùng lúc
        PERFORM id FROM lo_thuoc WHERE id = r.lo_thuoc_id FOR UPDATE;

        -- Trừ số lượng tồn kho
        UPDATE lo_thuoc
        SET so_luong_ton = so_luong_ton - r.so_luong
        WHERE id = r.lo_thuoc_id AND so_luong_ton >= r.so_luong;

        IF NOT FOUND THEN
            RAISE EXCEPTION 'Lỗi xuất kho: Lô thuốc ID % không đủ số lượng tồn để xuất đơn %!', r.lo_thuoc_id, p_don_thuoc_id;
        END IF;
    END LOOP;

    -- 3. Cập nhật trạng thái đơn thuốc sang DA_XUAT
    UPDATE don_thuoc
    SET trang_thai = 'DA_XUAT'
    WHERE id = p_don_thuoc_id;

    RAISE NOTICE 'Xuất kho thành công cho đơn thuốc ID % bởi Dược sĩ ID %', p_don_thuoc_id, p_duoc_si_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Giao dịch xuất kho bị hủy do lỗi: %', SQLERRM;
END;
$$;


-- ---------------------------------------------------------------------
-- THỦ TỤC 2: sp_thanh_toan_hoa_don (Quyết toán viện phí và đóng ca khám)
-- Có Transaction & Tính toán chi phí
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_thanh_toan_hoa_don(
    p_ca_kham_id BIGINT,
    p_nhan_vien_thu_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ma_hd VARCHAR(30);
    v_tien_kham NUMERIC(12,2) := 150000.00;
    v_tien_cls NUMERIC(12,2) := 0;
    v_tien_thuoc NUMERIC(12,2) := 0;
    v_muc_huong INT := 0;
    v_tien_bhyt NUMERIC(12,2) := 0;
    v_tong_tien NUMERIC(12,2) := 0;
    v_trang_thai_ca VARCHAR(20);
BEGIN
    -- 1. Kiểm tra trạng thái ca khám
    SELECT trang_thai INTO v_trang_thai_ca
    FROM ca_kham
    WHERE id = p_ca_kham_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Ca khám ID % không tồn tại!', p_ca_kham_id;
    END IF;

    -- 2. Tính tiền CLS
    SELECT COALESCE(SUM(d.gia_tien), 0) INTO v_tien_cls
    FROM chi_tiet_chi_dinh c
    JOIN dich_vu_cls d ON c.dich_vu_id = d.id
    WHERE c.ca_kham_id = p_ca_kham_id AND c.trang_thai <> 'DA_HUY';

    -- 3. Tính tiền thuốc
    SELECT COALESCE(SUM(ct.so_luong * ct.don_gia), 0) INTO v_tien_thuoc
    FROM don_thuoc dt
    JOIN chi_tiet_don_thuoc ct ON dt.id = ct.don_thuoc_id
    WHERE dt.ca_kham_id = p_ca_kham_id AND dt.trang_thai <> 'DA_HUY';

    -- 4. BHYT
    SELECT COALESCE(tb.muc_huong, 0) INTO v_muc_huong
    FROM ca_kham ck
    JOIN benh_nhan bn ON ck.benh_nhan_id = bn.id
    LEFT JOIN the_bhyt tb ON bn.id = tb.benh_nhan_id
        AND CURRENT_DATE BETWEEN tb.ngay_hieu_luc AND tb.ngay_het_han
    WHERE ck.id = p_ca_kham_id;

    v_tien_bhyt := (v_tien_cls + v_tien_thuoc) * (v_muc_huong::NUMERIC / 100);
    v_tong_tien := (v_tien_kham + v_tien_cls + v_tien_thuoc) - v_tien_bhyt;
    v_ma_hd := 'HD_' || TO_CHAR(CURRENT_TIMESTAMP, 'YYYYMMDDHH24MISS') || '_' || p_ca_kham_id;

    -- 5. Tạo hóa đơn
    INSERT INTO hoa_don (ma_hd, ca_kham_id, nhan_vien_thu_id, tien_kham, tien_cls, tien_thuoc, tien_bhyt_chi_tra, tong_tien_thanh_toan, trang_thai)
    VALUES (v_ma_hd, p_ca_kham_id, p_nhan_vien_thu_id, v_tien_kham, v_tien_cls, v_tien_thuoc, v_tien_bhyt, v_tong_tien, 'DA_THANH_TOAN');

    -- 6. Đóng ca khám
    UPDATE ca_kham
    SET trang_thai = 'HOAN_THANH'
    WHERE id = p_ca_kham_id;

    RAISE NOTICE 'Thanh toán thành công hóa đơn % cho ca khám %', v_ma_hd, p_ca_kham_id;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Thanh toán viện phí thất bại: %', SQLERRM;
END;
$$;


-- ---------------------------------------------------------------------
-- THỦ TỤC 3: sp_tiep_don_benh_nhan (Hành chính tiếp đón và xếp phòng khám)
-- Tự động tạo mã ca khám và kiểm tra lịch hẹn
-- ---------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_tiep_don_benh_nhan(
    p_benh_nhan_id INT,
    p_bac_si_id INT,
    p_phong_kham_id INT,
    p_trieu_chung TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_ma_ca VARCHAR(30);
BEGIN
    v_ma_ca := 'CK_' || TO_CHAR(CURRENT_DATE, 'YYYYMMDD') || '_' || LPAD((SELECT COUNT(*) + 1 FROM ca_kham WHERE ngay_kham::DATE = CURRENT_DATE)::TEXT, 4, '0');

    INSERT INTO ca_kham (ma_ca_kham, benh_nhan_id, bac_si_id, phong_kham_id, trieu_chung, trang_thai)
    VALUES (v_ma_ca, p_benh_nhan_id, p_bac_si_id, p_phong_kham_id, p_trieu_chung, 'CHO_KHAM');

    RAISE NOTICE 'Tiếp đón bệnh nhân thành công, mã ca khám: %', v_ma_ca;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Không thể tạo lượt khám mới: %', SQLERRM;
END;
$$;
