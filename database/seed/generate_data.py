"""
=====================================================================
DT01 – QUẢN LÝ BỆNH VIỆN: SCRIPT SINH DỮ LIỆU MẪU (SEED DATA)
Yêu cầu Slide 9:
  - >= 10.000 bản ghi ở bảng giao dịch chính (don_thuoc, chi_tiet_don_thuoc)
  - >= 100.000 bản ghi ở 1 bảng đo hiệu năng (ca_kham)
  - Dữ liệu tiếng Việt tự nhiên, đúng toàn vẹn khóa ngoại và ràng buộc CHECK.
=====================================================================
"""

import random
from datetime import datetime, timedelta

HO_VIET = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Huỳnh", "Phan", "Vũ", "Võ", "Đặng", "Bùi", "Đỗ", "Hồ", "Ngô", "Dương"]
DEM_NAM = ["Văn", "Đức", "Tiến", "Tuấn", "Minh", "Quốc", "Hữu", "Đình", "Thành", "Gia"]
DEM_NU = ["Thị", "Thùy", "Thu", "Ngọc", "Mai", "Phương", "Khánh", "Mỹ", "Bích", "Hồng"]
TEN_NAM = ["Anh", "Dũng", "Cường", "Nam", "Long", "Hải", "Sơn", "Tùng", "Bách", "Khoa", "Thắng", "Phúc"]
TEN_NU = ["Anh", "Dung", "Hoa", "Linh", "Trang", "Lan", "Hương", "Hà", "Nhung", "Hiền", "Yến", "Mai"]

KHOA_PHONG_LIST = [
    ("K_NOI", "Khoa Nội Tổng Hợp", "KHOA_CHUYEN_MON", None),
    ("K_NGOAI", "Khoa Ngoại Tổng Quát", "KHOA_CHUYEN_MON", None),
    ("K_SAN", "Khoa Phụ Sản", "KHOA_CHUYEN_MON", None),
    ("K_NHI", "Khoa Nhi", "KHOA_CHUYEN_MON", None),
    ("K_DUOC", "Khoa Dược Bệnh Viện", "KHO_DUOC", None),
    ("PK_NOI_1", "Phòng Khám Nội 1", "PHONG_KHAM", 1),
    ("PK_NOI_2", "Phòng Khám Nội 2", "PHONG_KHAM", 1),
    ("PK_NGOAI_1", "Phòng Khám Ngoại 1", "PHONG_KHAM", 2),
    ("PK_SAN_1", "Phòng Khám Sản 1", "PHONG_KHAM", 3),
    ("PK_NHI_1", "Phòng Khám Nhi 1", "PHONG_KHAM", 4),
    ("PXN_MAU", "Phòng Xét Nghiệm Huyết Học", "PHONG_XET_NGHIEM", 1),
    ("PXN_XQUANG", "Phòng Chụp X-Quang Kỹ Thuật Số", "PHONG_XET_NGHIEM", 2)
]

THUOC_LIST = [
    ("TH001", "Paracetamol 500mg", "Paracetamol", "VIEN", "Hộp 10 vỉ x 10 viên", 2000),
    ("TH002", "Amoxicillin 500mg", "Amoxicillin", "VIEN", "Hộp 2 vỉ x 10 viên", 3500),
    ("TH003", "Augmentin 1g", "Amoxicillin + Clavulanic", "VIEN", "Hộp 14 viên", 18000),
    ("TH004", "Panadol Extra", "Paracetamol + Caffeine", "VIEN", "Hộp 15 vỉ x 12 viên", 2500),
    ("TH005", "Omeprazol 20mg", "Omeprazol", "VIEN", "Lọ 30 viên", 4000),
    ("TH006", "Berberin 50mg", "Berberin", "VIEN", "Lọ 100 viên", 800),
    ("TH007", "Gliclazide 80mg", "Gliclazide", "VIEN", "Hộp 60 viên", 5500),
    ("TH008", "Amlodipin 5mg", "Amlodipin", "VIEN", "Hộp 30 viên", 3000),
    ("TH009", "Atorvastatin 20mg", "Atorvastatin", "VIEN", "Hộp 30 viên", 12000),
    ("TH010", "Cefixim 200mg", "Cefixim", "VIEN", "Hộp 10 viên", 9000)
]

DICH_VU_LIST = [
    ("DV01", "Tổng phân tích tế bào máu ngoại vi", "XET_NGHIEM_MAU", 85000),
    ("DV02", "Sinh hóa máu (Glucose, Ure, Creatinin)", "XET_NGHIEM_MAU", 120000),
    ("DV03", "Chụp X-quang ngực thẳng", "X_QUANG", 150000),
    ("DV04", "Siêu âm màu ổ bụng tổng quát", "SIEU_AM", 200000),
    ("DV05", "Điện tâm đồ (ECG)", "XET_NGHIEM_MAU", 60000),
    ("DV06", "Nội soi thực quản - dạ dày", "NOI_SOI", 650000)
]

def tao_ten(gioi_tinh):
    ho = random.choice(HO_VIET)
    if gioi_tinh == "NAM":
        dem = random.choice(DEM_NAM)
        ten = random.choice(TEN_NAM)
    else:
        dem = random.choice(DEM_NU)
        ten = random.choice(TEN_NU)
    return f"{ho} {dem} {ten}"

def generate_seed_sql(filename="database/seed/seed_data.sql"):
    print("Bắt đầu sinh dữ liệu mẫu đạt chuẩn Slide 9...")
    with open(filename, "w", encoding="utf-8") as f:
        f.write("-- DỮ LIỆU MẪU HỆ THỐNG QUẢN LÝ BỆNH VIỆN DT01\n")
        f.write("SET client_encoding = 'UTF8';\n\n")

        # 1. Khoa phòng
        f.write("-- 1. KHOA PHÒNG\n")
        for ma, ten, loai, parent in KHOA_PHONG_LIST:
            parent_val = str(parent) if parent else "NULL"
            f.write(f"INSERT INTO khoa_phong (ma_khoa, ten_khoa, loai_khoa, parent_id) VALUES ('{ma}', '{ten}', '{loai}', {parent_val});\n")
        f.write("\n")

        # 2. Nhân viên & Tài khoản (20 nhân sự)
        f.write("-- 2. NHÂN VIÊN & TÀI KHOẢN\n")
        chuc_vus = ["BAC_SI", "DUOC_SI", "HANH_CHINH", "QUAN_TRI"]
        for i in range(1, 21):
            cv = "BAC_SI" if i <= 10 else ("DUOC_SI" if i <= 14 else ("HANH_CHINH" if i <= 18 else "QUAN_TRI"))
            gt = "NAM" if i % 2 == 1 else "NU"
            ten = tao_ten(gt)
            ma_nv = f"NV{i:03d}"
            kp_id = random.randint(6, 10) if cv == "BAC_SI" else (5 if cv == "DUOC_SI" else 1)
            sdt = f"09{random.randint(10000000, 99999999)}"
            email = f"nv{i}@hospital.vn"
            f.write(f"INSERT INTO nhan_vien (ma_nv, ho_ten, chuc_vu, khoa_phong_id, so_dien_thoai, email) VALUES ('{ma_nv}', '{ten}', '{cv}', {kp_id}, '{sdt}', '{email}');\n")
            # Account
            user = f"user_{ma_nv.lower()}"
            # Pass hash demo: BCrypt '123456'
            hash_pass = "$2a$12$e80yqXg35r2p71w8bWbF8u7B3jWk3X7D8H9V0B1C2D3E4F5G6H7I8"
            f.write(f"INSERT INTO tai_khoan (nhan_vien_id, username, password_hash, vai_tro) VALUES ({i}, '{user}', '{hash_pass}', '{cv}');\n")
        f.write("\n")

        # 3. Thuốc & Lô thuốc
        f.write("-- 3. THUỐC & LÔ THUỐC\n")
        for ma, ten, hc, dvt, qc, gia in THUOC_LIST:
            f.write(f"INSERT INTO thuoc (ma_thuoc, ten_thuoc, hoat_chat, don_vi_tinh, quy_cach, gia_ban) VALUES ('{ma}', '{ten}', '{hc}', '{dvt}', '{qc}', {gia});\n")
        f.write("\n")
        for i in range(1, 11):
            so_lo = f"LO2026_{i:02d}"
            nsx = "2026-01-01"
            hsd = "2028-01-01"
            f.write(f"INSERT INTO lo_thuoc (thuoc_id, so_lo, ngay_san_xuat, han_su_dung, so_luong_nhap, so_luong_ton, gia_nhap) VALUES ({i}, '{so_lo}', '{nsx}', '{hsd}', 10000, 8500, 1500.00);\n")
        f.write("\n")

        # 4. Dịch vụ cận lâm sàng
        f.write("-- 4. DỊCH VỤ CẬN LÂM SÀNG\n")
        for ma, ten, loai, gia in DICH_VU_LIST:
            f.write(f"INSERT INTO dich_vu_cls (ma_dv, ten_dich_vu, loai_dv, gia_tien) VALUES ('{ma}', '{ten}', '{loai}', {gia});\n")
        f.write("\n")

        # 5. Bệnh nhân (5.000 bệnh nhân ban đầu)
        print("Đang sinh 5.000 bệnh nhân...")
        f.write("-- 5. BỆNH NHÂN & THẺ BHYT (5.000 bản ghi)\n")
        for i in range(1, 5001):
            gt = "NAM" if random.random() > 0.5 else "NU"
            ten = tao_ten(gt)
            ma_bn = f"BN{i:06d}"
            cccd = f"001{random.randint(100000000, 999999999)}"
            sdt = f"09{random.randint(10000000, 99999999)}"
            f.write(f"INSERT INTO benh_nhan (ma_bn, ho_ten, ngay_sinh, gioi_tinh, cccd, so_dien_thoai, dia_chi) VALUES ('{ma_bn}', '{ten}', '1990-01-01', '{gt}', '{cccd}', '{sdt}', 'Hà Nội');\n")
            if i % 2 == 0:
                ma_the = f"DN401{i:010d}"
                f.write(f"INSERT INTO the_bhyt (benh_nhan_id, ma_the, ngay_hieu_luc, ngay_het_han, muc_huong) VALUES ({i}, '{ma_the}', '2026-01-01', '2027-01-01', 80);\n")
        f.write("\n")

        # 6. Ca khám (100.000 bản ghi để test EXPLAIN ANALYZE)
        print("Đang sinh 100.000 ca khám (Bảng đo hiệu năng)...")
        f.write("-- 6. CA KHÁM (100.000 bản ghi đo hiệu năng)\n")
        start_date = datetime(2025, 1, 1)
        for i in range(1, 100001):
            ma_ca = f"CK_{i:07d}"
            bn_id = random.randint(1, 5000)
            bs_id = random.randint(1, 10)
            pk_id = random.randint(6, 10)
            rand_days = random.randint(0, 680)
            ngay = start_date + timedelta(days=rand_days, hours=random.randint(7, 16), minutes=random.randint(0, 59))
            ngay_str = ngay.strftime('%Y-%m-%d %H:%M:%S')
            f.write(f"INSERT INTO ca_kham (ma_ca_kham, benh_nhan_id, bac_si_id, phong_kham_id, ngay_kham, trieu_chung, chan_doan, trang_thai) VALUES ('{ma_ca}', {bn_id}, {bs_id}, {pk_id}, '{ngay_str}', 'Mệt mỏi, đau đầu nhẹ', 'Theo dõi sức khỏe', 'HOAN_THANH');\n")
        f.write("\n")

        # 7. Đơn thuốc (10.000 bản ghi)
        print("Đang sinh 10.000 đơn thuốc & chi tiết đơn...")
        f.write("-- 7. ĐƠN THUỐC & CHI TIẾT ĐƠN THUỐC (>= 10.000 bản ghi)\n")
        for i in range(1, 10001):
            ma_don = f"DT_{i:06d}"
            ca_id = i
            bs_id = random.randint(1, 10)
            f.write(f"INSERT INTO don_thuoc (ma_don, ca_kham_id, bac_si_id, trang_thai) VALUES ('{ma_don}', {ca_id}, {bs_id}, 'DA_XUAT');\n")
            lo_id = random.randint(1, 10)
            sl = random.randint(5, 20)
            f.write(f"INSERT INTO chi_tiet_don_thuoc (don_thuoc_id, lo_thuoc_id, so_luong, don_gia, lieu_dung, cach_dung) VALUES ({i}, {lo_id}, {sl}, 3000.00, 'Ngày 2 lần', 'Sau ăn');\n")
        f.write("\n")

        # 8. Hóa đơn (10.000 bản ghi)
        f.write("-- 8. HÓA ĐƠN VIỆN PHÍ\n")
        for i in range(1, 10001):
            ma_hd = f"HD_{i:06d}"
            f.write(f"INSERT INTO hoa_don (ma_hd, ca_kham_id, nhan_vien_thu_id, tien_kham, tien_cls, tien_thuoc, tien_bhyt_chi_tra, tong_tien_thanh_toan, trang_thai) VALUES ('{ma_hd}', {i}, 15, 150000, 85000, 60000, 50000, 245000, 'DA_THANH_TOAN');\n")

    print(f"ĐÃ SINH THÀNH CÔNG FILE SEED TẠI: {filename}")

if __name__ == "__main__":
    generate_seed_sql()
