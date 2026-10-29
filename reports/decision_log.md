# Decision Log — Đồ án 7: German Credit

## Câu hỏi nghiệp vụ

Với chi phí cho vay nhầm người xấu gấp 5 lần từ chối nhầm người tốt, liệu hồi quy logistic có giảm tổng chi phí tín dụng so với baseline duyệt tất cả, và mô hình có đối xử công bằng giữa các nhóm giới tính/tình trạng hôn nhân/lao động nước ngoài không?

## Một dòng dữ liệu là gì?

Một hồ sơ vay vốn của một khách hàng tại một thời điểm, với kết quả cuối cùng là Tốt (1) hoặc Xấu (2).

## Dữ liệu không thể trả lời điều gì?

- Không có thu nhập thực tế (chỉ có khoản trả góp hàng tháng).
- Không có ngày vay cụ thể (chỉ có thời hạn vay).
- Dữ liệu từ Đức giai đoạn 1973–1975, không đại diện cho thị trường Việt Nam hiện tại.

## Ai sẽ dùng kết quả?

- Nhân viên tín dụng: dùng ngưỡng tối ưu để quyết định duyệt/từ chối.
- Khách hàng bị từ chối: nhận thông báo từ chối dựa trên hệ số mô hình.
- Nhà quản lý: xem dashboard để đánh giá công bằng giữa các nhóm.

---

## Nhật ký quyết định (decision log)

| # | Quyết định | Lý do | Ảnh hưởng tới con số nào |
| :--- | :--- | :--- | :--- |
| 1 | Không dùng Accuracy làm chỉ số đánh giá chính | Dữ liệu mất cân bằng 700:300 (70% Tốt, 30% Xấu). Nếu mô hình đoán tất cả là "Tốt", Accuracy = 70% nhưng vô dụng vì bỏ sót toàn bộ người Xấu. | Sẽ dùng Cost-based metric theo ma trận chi phí 5:1 của UCI. |
| 2 | Dùng file `german.data` gốc thay vì `german.data-numeric` | File gốc giữ được ý nghĩa các mã A11–A14, cần cho việc giải thích hệ số Logistic Regression và viết thông báo từ chối. | Không ảnh hưởng đến độ chính xác, nhưng cần thiết cho tiêu chí 9 (ethics). |
| 3 | Sẽ map mã A11–A14 sang nhãn có nghĩa | Dữ liệu gốc mã hóa khó hiểu, không thể giải thích cho khách hàng bị từ chối nếu giữ nguyên. | Cần thiết cho "thông báo từ chối" ở cuối đồ án. |
## Ngày 2: EDA & chất lượng dữ liệu

| # | Quyết định | Lý do | Ảnh hưởng tới con số nào |
| :--- | :--- | :--- | :--- |
| 4 | Xác nhận mất cân bằng 700:300, dùng Cost-based metric 5:1 | Nếu dùng Accuracy, baseline đoán tất cả "Good" đã đạt 70% — vô nghĩa. Cost matrix 5:1 phản ánh đúng thiệt hại nghiệp vụ. | Mọi đánh giá mô hình sẽ dùng total_cost = 5*FP + 1*FN. |
| 5 | Sẽ dùng StandardScaler cho biến số, cân nhắc log-transform cho credit_amount | credit_amount có 72 outlier (7.2%), max=18424 gấp 7.9 lần median. Log-transform giảm ảnh hưởng outlier. | Hệ số Logistic Regression ổn định hơn, ít bị lệch bởi outlier. |
| 6 | Đã map mã A11–A14 sang nhãn có nghĩa (14 cột `_label`) | Cần thiết cho thông báo từ chối và giải thích hệ số. Tất cả NaN = 0, map thành công 100%. | Không ảnh hưởng độ chính xác, nhưng cần cho tiêu chí 9 (ethics). |
## Ngày 3: Tiền xử lý

| # | Quyết định | Lý do | Ảnh hưởng tới con số nào |
| :--- | :--- | :--- | :--- |
| 7 | Chia train/val/test 60/20/20 với stratify=y | Giữ tỷ lệ 70/30 ở cả 3 tập. Val dùng để chọn ngưỡng tối ưu, test dùng để báo cáo cuối. | Train 600, Val 200, Test 200 — phân bố giống hệt nhau. |
| 8 | Fit scaler CHỈ trên train, transform val/test | Chống data leakage. Nếu fit trên toàn bộ, mean/std sẽ bao gồm val/test → đánh giá sai. | Không có thông tin từ val/test bị "nhìn thấy" khi học scaler. |
| 9 | OneHotEncoder với handle_unknown='ignore' | Nếu val/test có giá trị hạng mục chưa thấy trong train, không bị lỗi — trả về 0 cho tất cả cột. | An toàn khi triển khai thực tế. |
| 10 | Số features tăng từ 20 lên 61 sau OneHot | Mỗi giá trị hạng mục thành một cột 0/1. 61 features là bình thường với 13 biến hạng mục. | Logistic Regression vẫn xử lý tốt với 600 dòng. |
## Ngày 4: Huấn luyện mô hình

| # | Quyết định | Lý do | Ảnh hưởng tới con số nào |
| :--- | :--- | :--- | :--- |
| 11 | Dùng Logistic Regression với class_weight='balanced' | Xử lý mất cân bằng 70/30, giúp mô hình chú ý đến lớp Bad. | Cost trên test: 105 (tốt hơn baseline 300). |
| 12 | Chọn ngưỡng tối ưu 0.70 thay vì 0.5 | Tại 0.70, cost = 105 (test) thấp hơn 0.5 (116). Ngưỡng cao hơn giúp giảm FP — phù hợp cost matrix 5:1. | Giảm 11 đơn vị cost trên test. |
| 13 | Chọn Logistic Regression thay vì Random Forest | LogReg có cost thấp hơn (105 vs 126) và AUC cao hơn (0.7895 vs 0.7734). Quan trọng hơn: LogReg giải thích được hệ số — yêu cầu bắt buộc của đề bài. | Không ảnh hưởng cost, nhưng đảm bảo tiêu chí 5 (giải thích được). |
| 14 | Chấp nhận 65 FN để chỉ còn 8 FP | FP (cho vay nhầm người xấu) đắt gấp 5 lần FN. Đánh đổi này tối ưu theo cost matrix. | Cost = 5×8 + 1×65 = 105. |
## Ngày 5 (tiếp): Kiểm tra tái tạo biến nhạy cảm

| # | Quyết định | Lý do | Ảnh hưởng tới con số nào |
| :--- | :--- | :--- | :--- |
| 18 | Bỏ personal_status, train lại, so sánh cost | Kiểm tra mô hình có tự tái tạo giới tính từ biến thay thế không (yêu cầu CLO7). | Cost giảm nhẹ: 105 → 102. AUC gần như không đổi: 0.7895 → 0.7852. |
| 19 | Kết luận: mô hình không phụ thuộc vào giới tính | Bỏ biến nhạy cảm không làm mô hình tệ đi — thậm chí tốt hơn. Các biến khác không tái tạo đủ thông tin giới tính. | Không cần biện pháp giảm thiểu cho giới tính. |
| 20 | personal_status chỉ có 4 giá trị trong train (thiếu A95) | Do mẫu nhỏ 1000 dòng, female single rơi hết vào test. Cần ghi vào báo cáo là hạn chế của dữ liệu. | Không ảnh hưởng đến kết luận fairness. |
## Ngày 7: Star schema & OLAP

| # | Quyết định | Lý do | Ảnh hưởng |
| 24 | Dùng star schema 1 Fact + 4 Dim | Đề bài yêu cầu tối thiểu 1 Fact + 3 Dim. Thêm Dim_Date để đủ chiều thời gian. | Fact_LoanApplication = 1000 dòng (không mất dòng nào). |
| 25 | Dùng ROLLUP, CUBE, window function cho OLAP | Đề bài yêu cầu truy vấn OLAP thực sự. | 4 truy vấn trả lời câu hỏi nghiệp vụ: mục đích vay, tuổi, ngoại quốc, chi phí. |
| 26 | Phát hiện: mục đích "education" có tỷ lệ duyệt thấp nhất (56%), "retraining" cao nhất (88.9%) | Insight cho dashboard và báo cáo. | Cần thảo luận trong phần kết luận. |