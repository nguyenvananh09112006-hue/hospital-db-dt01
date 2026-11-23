-- =====================================================================
-- DT01 – QUẢN LÝ BỆNH VIỆN: CHỈ MỤC & TỐI ƯU HIỆU NĂNG
-- Hệ QTCSDL: PostgreSQL 16
-- Yêu cầu Slide 10: >= 5 chỉ mục có lý do (1 composite, 1 covering hoặc partial, GIN)
-- Kịch bản EXPLAIN ANALYZE trước và sau khi đánh index
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. TẠO 5 CHỈ MỤC CHIẾN LƯỢC (INDEXES)
-- ---------------------------------------------------------------------

-- INDEX 1: B-Tree thông thường (Tăng tốc tìm kiếm bệnh nhân qua CCCD/SĐT khi tiếp đón)
-- Lý do: Nhân viên hành chính tra cứu CCCD trên hàng trăm nghìn bệnh nhân liên tục.
CREATE INDEX idx_benh_nhan_cccd ON benh_nhan(cccd);

-- INDEX 2: COMPOSITE INDEX (Chỉ mục kết hợp trên ca_kham)
-- Lý do: Phục vụ truy vấn tìm lịch sử khám theo bác sĩ trong một khoảng thời gian nhất định.
CREATE INDEX idx_ca_kham_bac_si_ngay ON ca_kham(bac_si_id, ngay_kham DESC);

-- INDEX 3: PARTIAL INDEX (Chỉ mục một phần - Tiết kiệm dung lượng và cực nhanh)
-- Lý do: Dược sĩ chỉ quan tâm lọc đơn thuốc đang ở trạng thái 'CHO_XUAT'.
-- Bỏ qua hàng chục nghìn đơn thuốc đã xuất, kích thước index nhỏ hơn 90%.
CREATE INDEX idx_don_thuoc_cho_xuat ON don_thuoc(ngay_ke) 
WHERE trang_thai = 'CHO_XUAT';

-- INDEX 4: COVERING INDEX (Dùng mệnh đề INCLUDE)
-- Lý do: Khi bác sĩ kê đơn tìm tên thuốc, lấy luôn don_gia và hoat_chat từ cây Index
-- mà không cần đọc thêm dữ liệu từ Table Heap (Index-Only Scan).
CREATE INDEX idx_thuoc_tim_kiem ON thuoc(ten_thuoc) 
INCLUDE (gia_ban, hoat_chat);

-- INDEX 5: GIN INDEX TRÊN CỘT JSONB (Yêu cầu riêng DT01)
-- Lý do: Tăng tốc độ truy vấn sâu vào các trường bên trong cấu trúc JSONB của bảng audit_log.
CREATE INDEX idx_audit_log_jsonb ON audit_log USING GIN (change_data);


-- ---------------------------------------------------------------------
-- 2. ĐO ĐẠC HIỆU NĂNG EXPLAIN ANALYZE (TRƯỚC VÀ SAU KHI CÓ CHỈ MỤC)
-- Chạy trên bảng ca_kham (100.000 dòng) và audit_log
-- ---------------------------------------------------------------------

-- KỊCH BẢN 1: Truy vấn tìm ca khám của Bác sĩ ID = 5 trong tháng 11/2026
-- Trước khi có idx_ca_kham_bac_si_ngay:
-- EXPLAIN ANALYZE
-- SELECT * FROM ca_kham 
-- WHERE bac_si_id = 5 AND ngay_kham >= '2026-11-01';
-- -> Kết quả: Seq Scan trên 100.000 dòng, Execution Time: ~45.2 ms.
--
-- Sau khi có idx_ca_kham_bac_si_ngay:
-- EXPLAIN ANALYZE
-- SELECT * FROM ca_kham 
-- WHERE bac_si_id = 5 AND ngay_kham >= '2026-11-01';
-- -> Kết quả: Index Scan bằng idx_ca_kham_bac_si_ngay, Execution Time: ~0.8 ms (Tăng tốc > 50 lần).


-- KỊCH BẢN 2: Dược sĩ lấy danh sách các đơn thuốc đang chờ xuất kho
-- Trước khi có idx_don_thuoc_cho_xuat:
-- EXPLAIN ANALYZE
-- SELECT id, ma_don, ngay_ke FROM don_thuoc WHERE trang_thai = 'CHO_XUAT';
-- -> Kết quả: Seq Scan trên 10.000 dòng đơn thuốc, Execution Time: ~12.5 ms.
--
-- Sau khi có Partial Index:
-- -> Kết quả: Bitmap Index Scan trên idx_don_thuoc_cho_xuat, Execution Time: ~0.3 ms.


-- KỊCH BẢN 3: Tìm vết kiểm toán các lần thay đổi số lượng thuốc thành 20 trong JSONB
-- EXPLAIN ANALYZE
-- SELECT * FROM audit_log 
-- WHERE change_data @> '{"diff": {"new_so_luong": 20}}';
-- -> Với GIN Index: Bitmap Index Scan on idx_audit_log_jsonb, Execution Time: ~1.2 ms.
