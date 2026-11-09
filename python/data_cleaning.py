"""
Superstore data preparation and quality checks.

Reads data/Superstore_Clean.xlsx, rebuilds the derived columns from the
base columns, checks that they match, runs the data quality checks and
saves a small report to python/output/.

Run from the repository root:
    pip install -r python/requirements.txt
    python python/data_cleaning.py
"""
from pathlib import Path

import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data" / "Superstore_Clean.xlsx"
OUT = ROOT / "python" / "output"

REGION_MANAGERS = {
    "Central": "Kelly Williams",
    "East": "Chuck Magee",
    "South": "Cassandra Brandow",
    "West": "Anna Andreadi",
}


def discount_band(d):
    if d == 0:
        return "0%"
    if d <= 0.10:
        return "1-10%"
    if d <= 0.20:
        return "11-20%"
    if d <= 0.30:
        return "21-30%"
    if d <= 0.50:
        return "31-50%"
    return ">50%"


def load():
    df = pd.read_excel(DATA, sheet_name="Superstore")
    df["order_date"] = pd.to_datetime(df["order_date"])
    df["ship_date"] = pd.to_datetime(df["ship_date"])
    df["postal_code"] = df["postal_code"].astype(str)
    return df


def rebuild_columns(df):
    """Recalculate the columns that were added during cleaning."""
    new = pd.DataFrame(index=df.index)
    new["order_year"] = df["order_date"].dt.year
    new["order_month"] = df["order_date"].dt.strftime("%Y-%m")
    new["days_to_ship"] = (df["ship_date"] - df["order_date"]).dt.days
    new["discount_band"] = df["discount"].apply(discount_band)
    new["region_manager"] = df["region"].map(REGION_MANAGERS)
    return new


def quality_checks(df):
    text_cols = [c for c in df.columns if df[c].dtype == object or pd.api.types.is_string_dtype(df[c])]
    rebuilt = rebuild_columns(df)
    checks = {
        "Records": len(df),
        "Columns": df.shape[1],
        "Blank cells": int(df.isna().sum().sum()),
        "Duplicate full records": int(df.duplicated().sum()),
        "Duplicate row_id": int(df["row_id"].duplicated().sum()),
        "Ship date before order date": int((df["ship_date"] < df["order_date"]).sum()),
        "order_year mismatches": int((rebuilt["order_year"] != df["order_year"]).sum()),
        "order_month mismatches": int((rebuilt["order_month"] != df["order_month"].astype(str)).sum()),
        "days_to_ship mismatches": int((rebuilt["days_to_ship"] != df["days_to_ship"]).sum()),
        "region_manager mismatches": int((rebuilt["region_manager"] != df["region_manager"]).sum()),
        "Discount outside 0 to 1": int((~df["discount"].between(0, 1)).sum()),
        "Nonpositive quantity": int((df["quantity"] <= 0).sum()),
        "Invalid return flag": int((~df["is_returned"].isin([0, 1])).sum()),
        "Discount band mismatches": int((rebuilt["discount_band"] != df["discount_band"]).sum()),
        "Cells with surrounding whitespace": int(
            sum((df[c].astype(str) != df[c].astype(str).str.strip()).sum() for c in text_cols)
        ),
        "Negative-profit rows (kept)": int((df["profit"] < 0).sum()),
    }
    return pd.Series(checks, name="Result")


def summary(df):
    total_sales = df["sales"].sum()
    total_profit = df["profit"].sum()
    orders = df["order_id"].nunique()
    returned = df.loc[df["is_returned"] == 1, "order_id"].nunique()
    return pd.Series(
        {
            "Total sales": round(total_sales, 2),
            "Total profit": round(total_profit, 2),
            "Profit margin %": round(100 * total_profit / total_sales, 1),
            "Orders": orders,
            "Customers": df["customer_id"].nunique(),
            "Return rate %": round(100 * returned / orders, 1),
        },
        name="Value",
    )


def by_discount_band(df):
    order = ["0%", "1-10%", "11-20%", "21-30%", "31-50%", ">50%"]
    g = df.groupby("discount_band").agg(lines=("row_id", "count"), sales=("sales", "sum"), profit=("profit", "sum"))
    g["margin_%"] = (100 * g["profit"] / g["sales"]).round(1)
    return g.reindex(order).round(2)


def main():
    df = load()
    checks = quality_checks(df)
    OUT.mkdir(parents=True, exist_ok=True)
    checks.to_csv(OUT / "quality_checks.csv", header=True)
    by_discount_band(df).to_csv(OUT / "margin_by_discount_band.csv")

    print("Data quality checks")
    print(checks.to_string())
    print()
    print("Summary")
    print(summary(df).to_string())
    print()
    print("Profit margin by discount band")
    print(by_discount_band(df).to_string())


if __name__ == "__main__":
    main()
