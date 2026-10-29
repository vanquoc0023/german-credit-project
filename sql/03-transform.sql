-- 03-transform.sql
-- Mục đích: Chuyển dữ liệu từ staging.german_raw vào star schema
-- Chạy lại nhiều lần không lỗi (idempotent)

-- Xóa dữ liệu cũ trong các bảng
TRUNCATE Fact_LoanApplication CASCADE;
TRUNCATE Dim_Applicant CASCADE;
TRUNCATE Dim_Purpose CASCADE;
TRUNCATE Dim_EmploymentStatus CASCADE;

-- ============================================================
-- 1. Nạp Dim_Purpose (mục đích vay)
-- ============================================================
INSERT INTO Dim_Purpose (purpose_code, purpose_label)
SELECT DISTINCT
    purpose,
    CASE purpose
        WHEN 'A40' THEN 'new car'
        WHEN 'A41' THEN 'used car'
        WHEN 'A42' THEN 'furniture/equipment'
        WHEN 'A43' THEN 'radio/TV'
        WHEN 'A44' THEN 'domestic appliances'
        WHEN 'A45' THEN 'repairs'
        WHEN 'A46' THEN 'education'
        WHEN 'A47' THEN 'vacation'
        WHEN 'A48' THEN 'retraining'
        WHEN 'A49' THEN 'business'
        WHEN 'A410' THEN 'others'
        ELSE purpose
    END
FROM staging.german_raw;

-- ============================================================
-- 2. Nạp Dim_EmploymentStatus
-- ============================================================
INSERT INTO Dim_EmploymentStatus (employment_code, employment_label, savings_status, installment_rate)
SELECT DISTINCT
    employment,
    CASE employment
        WHEN 'A71' THEN 'unemployed'
        WHEN 'A72' THEN '< 1 year'
        WHEN 'A73' THEN '1-4 years'
        WHEN 'A74' THEN '4-7 years'
        WHEN 'A75' THEN '>= 7 years'
        ELSE employment
    END,
    savings_status,
    installment_commitment::INT
FROM staging.german_raw;

-- ============================================================
-- 3. Nạp Dim_Applicant
-- ============================================================
INSERT INTO Dim_Applicant (personal_status, age_group, foreign_worker, own_telephone, job, housing, num_dependents)
SELECT DISTINCT
    personal_status,
    CASE
        WHEN age::INT < 30 THEN '<30'
        WHEN age::INT BETWEEN 30 AND 50 THEN '30-50'
        ELSE '>50'
    END,
    CASE foreign_worker
        WHEN 'A201' THEN 'yes'
        WHEN 'A202' THEN 'no'
        ELSE foreign_worker
    END,
    CASE own_telephone
        WHEN 'A191' THEN 'none'
        WHEN 'A192' THEN 'yes'
        ELSE own_telephone
    END,
    job,
    CASE housing
        WHEN 'A151' THEN 'rent'
        WHEN 'A152' THEN 'own'
        WHEN 'A153' THEN 'for free'
        ELSE housing
    END,
    num_dependents::INT
FROM staging.german_raw;

-- ============================================================
-- 4. Nạp Fact_LoanApplication
-- ============================================================
INSERT INTO Fact_LoanApplication (applicant_key, purpose_key, employment_key, date_key, amount, duration, credit_risk, cost_weight)
SELECT
    a.applicant_key,
    p.purpose_key,
    e.employment_key,
    1,  -- date_key = 1
    s.credit_amount::INT,
    s.duration::INT,
    CASE s.credit_risk
        WHEN '1' THEN 'Good'
        WHEN '2' THEN 'Bad'
        ELSE s.credit_risk
    END,
    CASE s.credit_risk
        WHEN '1' THEN 1
        WHEN '2' THEN 5
        ELSE 1
    END
FROM staging.german_raw s
JOIN Dim_Applicant a ON
    a.personal_status = s.personal_status
    AND a.age_group = CASE
        WHEN s.age::INT < 30 THEN '<30'
        WHEN s.age::INT BETWEEN 30 AND 50 THEN '30-50'
        ELSE '>50'
    END
    AND a.foreign_worker = CASE s.foreign_worker WHEN 'A201' THEN 'yes' WHEN 'A202' THEN 'no' ELSE s.foreign_worker END
    AND a.own_telephone = CASE s.own_telephone WHEN 'A191' THEN 'none' WHEN 'A192' THEN 'yes' ELSE s.own_telephone END
    AND a.job = s.job
    AND a.housing = CASE s.housing WHEN 'A151' THEN 'rent' WHEN 'A152' THEN 'own' WHEN 'A153' THEN 'for free' ELSE s.housing END
    AND a.num_dependents = s.num_dependents::INT
JOIN Dim_Purpose p ON p.purpose_code = s.purpose
JOIN Dim_EmploymentStatus e ON
    e.employment_code = s.employment
    AND e.savings_status = s.savings_status
    AND e.installment_rate = s.installment_commitment::INT;

-- Kiểm tra kết quả
SELECT 'Transform hoàn tất' AS status;
SELECT 'Fact_LoanApplication' AS table_name, COUNT(*) AS row_count FROM Fact_LoanApplication
UNION ALL
SELECT 'Dim_Applicant', COUNT(*) FROM Dim_Applicant
UNION ALL
SELECT 'Dim_Purpose', COUNT(*) FROM Dim_Purpose
UNION ALL
SELECT 'Dim_EmploymentStatus', COUNT(*) FROM Dim_EmploymentStatus
UNION ALL
SELECT 'Dim_Date', COUNT(*) FROM Dim_Date;