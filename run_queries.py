"""Run every query in sql/ against BigQuery and save the result to results/<name>.csv.

Usage:  GCP_PROJECT=your-project-id python run_queries.py
The source dataset is public; queries bill to your project (~4 GB each, inside the free tier).
"""
import os, pathlib, warnings
from google.cloud import bigquery

warnings.filterwarnings("ignore")
client = bigquery.Client(project=os.environ["GCP_PROJECT"])
out = pathlib.Path("results"); out.mkdir(exist_ok=True)

for sql_file in sorted(pathlib.Path("sql").glob("*.sql")):
    df = client.query(sql_file.read_text()).to_dataframe()
    df.to_csv(out / f"{sql_file.stem}.csv", index=False)
    print(f"{sql_file.stem}: {len(df)} rows")
