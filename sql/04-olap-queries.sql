-- 04-olap-queries.sql
-- Mục đích: Truy vấn OLAP trả lời câu hỏi nghiệp vụ

-- ============================================================
-- TRUY VẤN 1: ROLLUP — Tỷ lệ duyệt theo mục đích vay
-- ============================================================
SELECT
    COALESCE(p.purpose_label, 'TỔNG CỘNG') AS purpose,
    COUNT(*) AS total_apps,
    SUM(CASE WHEN f.credit_risk = 'Good' THEN 1 ELSE 0 END) AS good_apps,
    ROUND(100.0 * SUM(CASE WHEN f.credit_risk = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 1) AS approval_rate_pct
FROM Fact_LoanApplication f
JOIN Dim_Purpose p ON f.purpose_key = p.purpose_key
GROUP BY ROLLUP (p.purpose_label)
ORDER BY p.purpose_label NULLS LAST;

-- ============================================================
-- TRUY VẤN 2: CUBE — Tỷ lệ duyệt theo nhóm tuổi và ngoại quốc
-- ============================================================
SELECT
    COALESCE(a.age_group, 'TẤT CẢ') AS age_group,
    COALESCE(a.foreign_worker, 'TẤT CẢ') AS foreign_worker,
    COUNT(*) AS total_apps,
    ROUND(100.0 * SUM(CASE WHEN f.credit_risk = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 1) AS approval_rate_pct
FROM Fact_LoanApplication f
JOIN Dim_Applicant a ON f.applicant_key = a.applicant_key
GROUP BY CUBE (a.age_group, a.foreign_worker)
ORDER BY a.age_group NULLS LAST, a.foreign_worker NULLS LAST;

-- ============================================================
-- TRUY VẤN 3: WINDOW FUNCTION — Xếp hạng mục đích vay theo tỷ lệ duyệt
-- ============================================================
SELECT
    p.purpose_label,
    COUNT(*) AS total_apps,
    ROUND(100.0 * SUM(CASE WHEN f.credit_risk = 'Good' THEN 1 ELSE 0 END) / COUNT(*), 1) AS approval_rate_pct,
    RANK() OVER (ORDER BY 100.0 * SUM(CASE WHEN f.credit_risk = 'Good' THEN 1 ELSE 0 END) / COUNT(*) DESC) AS rank_by_approval
FROM Fact_LoanApplication f
JOIN Dim_Purpose p ON f.purpose_key = p.purpose_key
GROUP BY p.purpose_label
ORDER BY rank_by_approval;

-- ============================================================
-- TRUY VẤN 4: WINDOW FUNCTION — So sánh chi phí trung bình theo nhóm tuổi
-- ============================================================
SELECT
    a.age_group,
    COUNT(*) AS total_apps,
    SUM(f.cost_weight) AS total_cost,
    ROUND(AVG(f.cost_weight), 2) AS avg_cost,
    RANK() OVER (ORDER BY SUM(f.cost_weight) DESC) AS rank_by_cost
FROM Fact_LoanApplication f
JOIN Dim_Applicant a ON f.applicant_key = a.applicant_key
GROUP BY a.age_group
ORDER BY rank_by_cost;