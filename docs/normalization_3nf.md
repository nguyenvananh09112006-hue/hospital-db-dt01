## Mục tiêu
Sửa `docs/normalization_3nf.md` cho đúng định nghĩa 2NF/3NF và khớp với đặc tả 1.1 (`docs/specifications.md`).
Theo quy định học phần, phần chuẩn hóa do nhóm tự viết; AI chỉ dùng để rà soát.

## Định nghĩa dùng thống nhất
- **2NF:** mọi thuộc tính không khóa phụ thuộc đầy đủ vào **mọi** khóa ứng viên (không chỉ khóa chính).
- **3NF:** với mọi phụ thuộc hàm không tầm thường X → A: X là siêu khóa, hoặc A là thuộc tính khóa.
- **Heath:** R(X, Y, Z) có X → Y ⇒ tách R1(X, Y), R2(X, Z) không mất thông tin.
- Mỗi bảng làm theo 6 bước: thuộc tính → tập phụ thuộc hàm đầy đủ → mọi khóa ứng viên → thuộc tính khóa/không khóa → kiểm tra 1NF/2NF/3NF → tách (chứng minh không mất thông tin và bảo toàn phụ thuộc).

## Checklist

### Phần I – Nguyên tắc
- [ ] Sửa "Slide 9" → slide 10 ("Yêu cầu chung 1/3")
- [ ] Thêm mô tả quy trình 6 bước

### II.1 – `benh_nhan`
- [ ] Bổ sung khóa ứng viên `ma_bn`; bỏ `cccd` khỏi khóa ứng viên (cho phép NULL theo BR08, chỉ là UNIQUE)
- [ ] Viết đủ vế phải các phụ thuộc hàm, không dùng "..."
- [ ] 2NF: lập luận theo **mọi** khóa ứng viên
- [ ] Chọn một cách lưu địa chỉ (bảng `tinh_thanh` hoặc chuỗi), xóa câu mâu thuẫn ở dòng 40, khớp với DDL
- [ ] Chứng minh tách không mất thông tin (Heath) và bảo toàn phụ thuộc

### II.2 – `chi_tiet_don_thuoc` (theo QĐ01: nối `thuoc_id`)
- [ ] Đổi `lo_thuoc_id` → `thuoc_id`; quan hệ ban đầu có thêm thuộc tính của thuốc để phân tích tách
- [ ] Chốt có `UNIQUE (don_thuoc_id, thuoc_id)` hay không, rồi xác định khóa ứng viên tương ứng
- [ ] Xóa câu "khi chọn id làm khóa thay thế…"; nêu rõ dạng chuẩn xét theo mọi khóa ứng viên
- [ ] Giải thích `don_gia` là giá chụp tại thời điểm kê (không bắc cầu qua `thuoc_id`)
- [ ] Thống nhất tên cột `don_gia`; nhắc tới bảng `chi_tiet_xuat_lo`

### II.3 – `lo_thuoc`
- [ ] Thêm `phieu_nhap_id`
- [ ] 2NF: xét khóa phức hợp `{thuoc_id, so_lo}`
- [ ] (Gợi ý) Quan hệ ban đầu có ngày nhập, nhà cung cấp → chỉ ra bắc cầu qua `phieu_nhap_id`, tách ra `phieu_nhap_kho`
- [ ] Chuyển `so_luong_ton` sang phần III

### Bảng bổ sung
- [ ] Chứng minh thêm 1 bảng có khóa phức hợp tự nhiên: `ca_kham` hoặc `the_bhyt`

### Phần III – Phi chuẩn hóa (mỗi trường hợp đủ 7 mục: cột, công thức, vì sao vi phạm, lý do lưu, rủi ro, cơ chế nhất quán, kiểm chứng)
- [ ] `hoa_don`: chỉ rõ phụ thuộc hàm trong cùng dòng vi phạm 3NF; lý do chính là chốt số tiền tại thời điểm lập; bỏ "O(N) → O(1)"
- [ ] `hoa_don`: cơ chế theo đặc tả (tính ở UC04; BR02 + trạng thái `HOAN_THANH`; BR14; CHECK); thống nhất tên cột với BR07
- [ ] `hoa_don`: giải thích lựa chọn mức cô lập giao dịch
- [ ] `lo_thuoc.so_luong_ton`: công thức, nơi được cập nhật, CHECK, quyền UPDATE, truy vấn đối soát

### Phần IV – Bảng tổng hợp
- [ ] Bảng gồm mọi bảng trong lược đồ: khóa chính, khóa ứng viên/UNIQUE, dạng chuẩn, ghi chú

### Hoàn tất
- [ ] Tên bảng/cột khớp đặc tả 1.1 và DDL Flyway
- [ ] Mỗi thành viên đọc và tự trả lời được 6 câu hỏi vấn đáp (khóa ứng viên vs siêu khóa; cột `id` và 2NF; `don_gia`; JSONB và 1NF; `so_luong_ton`; chứng minh tách `benh_nhan`)
- [ ] Mở PR, reviewer: TV1 và TV4
