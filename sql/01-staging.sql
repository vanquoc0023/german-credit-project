-- 01-staging.sql
-- Mục đích: Tạo schema staging và nạp dữ liệu thô từ german.data
-- Chạy lại nhiều lần không lỗi (idempotent)

-- Xóa schema cũ nếu tồn tại (cascade để xóa cả bảng bên trong)
DROP SCHEMA IF EXISTS staging CASCADE;

-- Tạo schema mới
CREATE SCHEMA staging;

-- Tạo bảng thô với 21 cột (20 thuộc tính + 1 nhãn)
-- Tất cả dùng TEXT để nạp dữ liệu gốc dễ dàng
CREATE TABLE staging.german_raw (
    checking_status        TEXT,
    duration               TEXT,
    credit_history         TEXT,
    purpose                TEXT,
    credit_amount          TEXT,
    savings_status         TEXT,
    employment             TEXT,
    installment_commitment TEXT,
    personal_status        TEXT,
    other_parties          TEXT,
    residence_since        TEXT,
    property_magnitude     TEXT,
    age                    TEXT,
    other_payment_plans    TEXT,
    housing                TEXT,
    existing_credits       TEXT,
    job                    TEXT,
    num_dependents         TEXT,
    own_telephone          TEXT,
    foreign_worker         TEXT,
    credit_risk            TEXT
);

-- Kiểm tra bảng đã tạo
SELECT 'Bảng staging.german_raw đã tạo' AS status;
