-- =====================================================================
-- DT01 – QUẢN LÝ BỆNH VIỆN: PHÂN QUYỀN BẢO MẬT CSDL
-- Hệ QTCSDL: PostgreSQL 16
-- Yêu cầu Slide 11: >= 3 vai trò CSDL, GRANT/REVOKE theo quyền tối thiểu,
-- Ứng dụng dùng app_user chuyên dụng, tuyệt đối không dùng superuser postgres.
-- =====================================================================

-- 1. XÓA CÁC ROLE CŨ NẾU TỒN TẠI
DROP ROLE IF EXISTS role_doctor;
DROP ROLE IF EXISTS role_pharmacist;
DROP ROLE IF EXISTS role_receptionist;
DROP ROLE IF EXISTS hospital_app_user;

-- 2. TẠO TÀI KHOẢN ỨNG DỤNG (Dùng cho Spring Boot Backend)
-- Mật khẩu được cấu hình từ biến môi trường APP_DB_PASSWORD
CREATE USER hospital_app_user WITH PASSWORD 'AppHospital_Secure2026!';

-- 3. TẠO 3 VAI TRÒ (ROLES) CHUYÊN BIỆT THEO ACTOR

-- ROLE 1: BÁC SĨ (role_doctor)
-- Quyền: Xem danh mục, xem bệnh nhân, tạo ca khám, chỉ định CLS, kê đơn thuốc
CREATE ROLE role_doctor;
GRANT SELECT ON khoa_phong, dich_vu_cls, thuoc, lo_thuoc TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON benh_nhan TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON ca_kham TO role_doctor;
GRANT SELECT, INSERT, UPDATE, DELETE ON chi_tiet_chi_dinh TO role_doctor;
GRANT SELECT, INSERT, UPDATE ON don_thuoc, chi_tiet_don_thuoc TO role_doctor;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_doctor;

-- ROLE 2: DƯỢC SĨ (role_pharmacist)
-- Quyền: Quản lý kho thuốc, duyệt xuất đơn thuốc, xem thông tin thuốc
CREATE ROLE role_pharmacist;
GRANT SELECT ON thuoc TO role_pharmacist;
GRANT SELECT, INSERT, UPDATE ON lo_thuoc TO role_pharmacist;
GRANT SELECT, UPDATE(trang_thai) ON don_thuoc TO role_pharmacist;
GRANT SELECT ON chi_tiet_don_thuoc TO role_pharmacist;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_pharmacist;

-- ROLE 3: NHÂN VIÊN HÀNH CHÍNH / THU NGÂN (role_receptionist)
-- Quyền: Tiếp đón bệnh nhân, đặt lịch hẹn, lập và thanh toán hóa đơn
CREATE ROLE role_receptionist;
GRANT SELECT, INSERT, UPDATE ON benh_nhan, the_bhyt TO role_receptionist;
GRANT SELECT, INSERT, UPDATE ON lich_hen TO role_receptionist;
GRANT SELECT, INSERT ON ca_kham TO role_receptionist;
GRANT SELECT, INSERT, UPDATE ON hoa_don TO role_receptionist;
GRANT SELECT ON khoa_phong, nhan_vien, dich_vu_cls, thuoc TO role_receptionist;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO role_receptionist;

-- 4. GÁN TOÀN BỘ QUYỀN VẬN HÀNH CHO TÀI KHOẢN APP (Không cấp quyền Superuser)
GRANT role_doctor, role_pharmacist, role_receptionist TO hospital_app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO hospital_app_user;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO hospital_app_user;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO hospital_app_user;
GRANT EXECUTE ON ALL PROCEDURES IN SCHEMA public TO hospital_app_user;

-- Không cấp quyền DROP/ALTER TABLE cho tài khoản app
REVOKE CREATE ON SCHEMA public FROM hospital_app_user;
