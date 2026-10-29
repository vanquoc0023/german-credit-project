# Đồ án Khai phá dữ liệu — German Credit Risk Scoring & Fairness

## Câu hỏi nghiệp vụ

Với chi phí cho vay nhầm người xấu gấp 5 lần từ chối nhầm người tốt, liệu hồi quy logistic có giảm tổng chi phí tín dụng so với baseline duyệt tất cả, và mô hình có đối xử công bằng giữa các nhóm giới tính/tình trạng hôn nhân/lao động nước ngoài không?

## Cấu trúc project

- `notebooks/` — 5 notebook phân tích (EDA, preprocessing, classification, fairness, association rules)
- `sql/` — 3 script SQL + 1 file OLAP + script nạp dữ liệu
- `reports/` — decision log, báo cáo, ảnh dashboard
- `data/raw/` — dữ liệu gốc (không commit, tải từ UCI)
- `requirements.txt` — thư viện cần cài

## Cách chạy lại từ đầu

### 1. Cài môi trường

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt

2. Tải dữ liệu**
Tải german.data từ https://archive.ics.uci.edu/dataset/144/statlog+german+credit+data và đặt vào data/raw/.
3. Dựng kho dữ liệu PostgreSQL
bash
docker run --name postgres-german -e POSTGRES_USER=dm -e POSTGRES_PASSWORD=dm -e POSTGRES_DB=dm_course -p 5432:5432 -d postgres:15
python sql/load_data.py
Get-Content sql/02-star-schema.sql | docker exec -i postgres-german psql -U dm -d dm_course
Get-Content sql/03-transform.sql | docker exec -i postgres-german psql -U dm -d dm_course
Get-Content sql/04-olap-queries.sql | docker exec -i postgres-german psql -U dm -d dm_course
4. Chạy notebook
Mở lần lượt 01_eda_quality.ipynb → 05_association_rules.ipynb, chạy Run All.

5. Dashboard
Chạy Metabase: docker run -d -p 3000:3000 --name metabase metabase/metabase, kết nối PostgreSQL với host host.docker.internal.

Kết quả chính
Mô hình LogReg: cost test = 105 (baseline 300) — giảm 65%.

AUC test = 0.7895.

Fairness: chênh lệch tỷ lệ duyệt nam/nữ = 3.1 điểm %, FNR = 0.8 điểm %.

Luật kết hợp: 88 luật dẫn đến Bad, mạnh nhất có confidence 43.7%, lift 2.01.






