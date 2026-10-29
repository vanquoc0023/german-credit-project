import pandas as pd
import psycopg2
from psycopg2.extras import execute_values

# Đọc dữ liệu thô
columns = ['checking_status', 'duration', 'credit_history', 'purpose',
           'credit_amount', 'savings_status', 'employment', 'installment_commitment',
           'personal_status', 'other_parties', 'residence_since', 'property_magnitude',
           'age', 'other_payment_plans', 'housing', 'existing_credits',
           'job', 'num_dependents', 'own_telephone', 'foreign_worker', 'credit_risk']

df = pd.read_csv('data/raw/german.data', sep=' ', header=None, names=columns)
print(f"Đọc được {len(df)} dòng từ german.data")

# Kết nối PostgreSQL
conn = psycopg2.connect(
    host='localhost', port=5432, user='dm', password='dm', dbname='dm_course'
)
cur = conn.cursor()

# Xóa dữ liệu cũ (idempotent)
cur.execute("TRUNCATE staging.german_raw")
print("Đã xóa dữ liệu cũ trong staging.german_raw")

# Chuẩn bị dữ liệu để insert
rows = [tuple(row) for row in df.values]

# Insert hàng loạt
execute_values(
    cur,
    "INSERT INTO staging.german_raw VALUES %s",
    rows
)
conn.commit()

# Kiểm tra
cur.execute("SELECT COUNT(*) FROM staging.german_raw")
count = cur.fetchone()[0]
print(f"Đã nạp {count} dòng vào staging.german_raw")

# Xem 3 dòng đầu
cur.execute("SELECT * FROM staging.german_raw LIMIT 3")
for row in cur.fetchall():
    print(row)

cur.close()
conn.close()
print("Hoàn tất!")