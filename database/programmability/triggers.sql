-- =====================================================================
-- DT01 – QUẢN LÝ BỆNH VIỆN
-- LẬP TRÌNH TRIGGER NGHIỆP VỤ & KIỂM TOÁN JSONB
-- Hệ QTCSDL: PostgreSQL 16
-- =====================================================================

-- ---------------------------------------------------------------------
-- TRIGGER 1 (YÊU CẦU RIÊNG DT01 & BR03):
-- Chặn kê đơn thuốc vượt số lượng tồn kho khả dụng
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_trg_kiem_tra_ton_kho_ke_don()
RETURNS TRIGGER AS $$
DECLARE
    v_ton_kho INT;
    v_ten_thuoc VARCHAR(150);
    v_trang_thai_don VARCHAR(20);
BEGIN
    -- 1. Lấy trạng thái của đơn thuốc
    SELECT trang_thai INTO v_trang_thai_don
    FROM don_thuoc
    WHERE id = NEW.don_thuoc_id;

    -- Chỉ kiểm tra khi đơn đang ở trạng thái CHO_XUAT
    IF v_trang_thai_don = 'DA_XUAT' THEN
        RAISE EXCEPTION 'Đơn thuốc số % đã xuất kho, không thể thay đổi chi tiết!', NEW.don_thuoc_id;
    END IF;

    -- 2. Lấy số lượng tồn khả dụng và tên thuốc của lô thuốc được chọn
    SELECT lt.so_luong_ton, t.ten_thuoc
    INTO v_ton_kho, v_ten_thuoc
    FROM lo_thuoc lt
    JOIN thuoc t ON lt.thuoc_id = t.id
    WHERE lt.id = NEW.lo_thuoc_id;

    -- 3. Kiểm tra số lượng kê với số lượng tồn
    IF NEW.so_luong > v_ton_kho THEN
        RAISE EXCEPTION 'Kê đơn thất bại: Thuốc "%" (Lô ID: %) chỉ còn tồn % trong kho, không đủ số lượng yêu cầu (%)!',
            v_ten_thuoc, NEW.lo_thuoc_id, v_ton_kho, NEW.so_luong;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_kiem_tra_ton_kho_ke_don ON chi_tiet_don_thuoc;
CREATE TRIGGER trg_kiem_tra_ton_kho_ke_don
BEFORE INSERT OR UPDATE ON chi_tiet_don_thuoc
FOR EACH ROW
EXECUTE FUNCTION fn_trg_kiem_tra_ton_kho_ke_don();


-- ---------------------------------------------------------------------
-- TRIGGER 2 (YÊU CẦU RIÊNG DT01 & BR06):
-- Tự động ghi nhật ký kiểm toán (Audit Trail) dưới dạng JSONB
-- Bắt mọi thao tác UPDATE hoặc DELETE trên chi tiết đơn thuốc
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_trg_audit_don_thuoc_jsonb()
RETURNS TRIGGER AS $$
DECLARE
    v_user_name VARCHAR(50);
BEGIN
    -- Lấy thông tin user hiện tại (hoặc từ biến session ứng dụng)
    v_user_name := COALESCE(current_setting('app.current_user', true), CURRENT_USER);

    IF (TG_OP = 'UPDATE') THEN
        INSERT INTO audit_log (table_name, action, record_id, changed_by, changed_at, change_data)
        VALUES (
            TG_TABLE_NAME,
            'UPDATE',
            NEW.id::TEXT,
            v_user_name,
            CURRENT_TIMESTAMP,
            jsonb_build_object(
                'old_state', to_jsonb(OLD),
                'new_state', to_jsonb(NEW),
                'diff', jsonb_build_object(
                    'old_so_luong', OLD.so_luong,
                    'new_so_luong', NEW.so_luong,
                    'old_lieu_dung', OLD.lieu_dung,
                    'new_lieu_dung', NEW.lieu_dung
                )
            )
        );
        RETURN NEW;
    ELSIF (TG_OP = 'DELETE') THEN
        INSERT INTO audit_log (table_name, action, record_id, changed_by, changed_at, change_data)
        VALUES (
            TG_TABLE_NAME,
            'DELETE',
            OLD.id::TEXT,
            v_user_name,
            CURRENT_TIMESTAMP,
            jsonb_build_object(
                'deleted_state', to_jsonb(OLD)
            )
        );
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_audit_chi_tiet_don ON chi_tiet_don_thuoc;
CREATE TRIGGER trg_audit_chi_tiet_don
AFTER UPDATE OR DELETE ON chi_tiet_don_thuoc
FOR EACH ROW
EXECUTE FUNCTION fn_trg_audit_don_thuoc_jsonb();


-- ---------------------------------------------------------------------
-- TRIGGER 3 (BR05):
-- Khóa đơn thuốc: Cấm sửa hoặc xóa đơn thuốc sau khi Dược sĩ đã xuất
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_trg_khoa_don_thuoc_da_xuat()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.trang_thai = 'DA_XUAT' AND (TG_OP = 'DELETE' OR NEW.trang_thai <> 'DA_XUAT') THEN
        RAISE EXCEPTION 'Quy tắc BR05: Đơn thuốc số % đã xuất kho thành công, cấm thay đổi hoặc xóa bỏ!', OLD.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_khoa_don_thuoc ON don_thuoc;
CREATE TRIGGER trg_khoa_don_thuoc
BEFORE UPDATE OR DELETE ON don_thuoc
FOR EACH ROW
EXECUTE FUNCTION fn_trg_khoa_don_thuoc_da_xuat();
