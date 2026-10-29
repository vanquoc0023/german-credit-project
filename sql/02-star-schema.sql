-- 02-star-schema.sql
-- Mục đích: Tạo star schema gồm 1 Fact + 4 Dimension
-- Chạy lại nhiều lần không lỗi (idempotent)

-- Xóa các bảng cũ nếu tồn tại (theo thứ tự: Fact trước, Dim sau)
DROP TABLE IF EXISTS Fact_LoanApplication CASCADE;
DROP TABLE IF EXISTS Dim_Applicant CASCADE;
DROP TABLE IF EXISTS Dim_Purpose CASCADE;
DROP TABLE IF EXISTS Dim_EmploymentStatus CASCADE;
DROP TABLE IF EXISTS Dim_Date CASCADE;

-- ============================================================
-- DIMENSION 1: Dim_Applicant (thông tin nhân khẩu học)
-- ============================================================
CREATE TABLE Dim_Applicant (
    applicant_key       SERIAL PRIMARY KEY,
    personal_status     TEXT,           -- A91-A95
    age_group           TEXT,           -- '<30', '30-50', '>50'
    foreign_worker      TEXT,           -- 'yes', 'no'
    own_telephone       TEXT,           -- 'none', 'yes'
    job                 TEXT,           -- A171-A174
    housing             TEXT,           -- 'rent', 'own', 'for free'
    num_dependents      INT
);

-- ============================================================
-- DIMENSION 2: Dim_Purpose (mục đích vay)
-- ============================================================
CREATE TABLE Dim_Purpose (
    purpose_key         SERIAL PRIMARY KEY,
    purpose_code        TEXT,           -- A40-A410
    purpose_label       TEXT            -- 'new car', 'used car', ...
);

-- ============================================================
-- DIMENSION 3: Dim_EmploymentStatus (tình trạng việc làm)
-- ============================================================
CREATE TABLE Dim_EmploymentStatus (
    employment_key      SERIAL PRIMARY KEY,
    employment_code     TEXT,           -- A71-A75
    employment_label    TEXT,           -- 'unemployed', '< 1 year', ...
    savings_status      TEXT,           -- A61-A65
    installment_rate    INT             -- 1-4
);

-- ============================================================
-- DIMENSION 4: Dim_Date (chiều ngày giả định)
-- ============================================================
CREATE TABLE Dim_Date (
    date_key            SERIAL PRIMARY KEY,
    year                INT,
    quarter             INT,
    month               INT,
    month_name          TEXT,
    is_weekend          BOOLEAN
);

-- Tạo sẵn 12 tháng cho năm 2024 (vì dữ liệu gốc không có ngày cụ thể)
INSERT INTO Dim_Date (year, quarter, month, month_name, is_weekend)
SELECT 2024,
       CEIL(month / 3.0)::INT,
       month,
       TO_CHAR(TO_DATE(month::TEXT, 'MM'), 'Month'),
       FALSE
FROM generate_series(1, 12) AS month;

-- ============================================================
-- FACT TABLE: Fact_LoanApplication (sự kiện vay)
-- ============================================================
CREATE TABLE Fact_LoanApplication (
    app_id              SERIAL PRIMARY KEY,
    applicant_key       INT REFERENCES Dim_Applicant(applicant_key),
    purpose_key         INT REFERENCES Dim_Purpose(purpose_key),
    employment_key      INT REFERENCES Dim_EmploymentStatus(employment_key),
    date_key            INT REFERENCES Dim_Date(date_key),
    amount              INT,            -- credit_amount
    duration            INT,            -- duration (tháng)
    credit_risk         TEXT,           -- 'Good' / 'Bad'
    cost_weight         INT             -- 1 nếu Good, 5 nếu Bad (dùng cho tính cost)
);

-- Kiểm tra các bảng đã tạo
SELECT 'Star schema đã tạo thành công' AS status;