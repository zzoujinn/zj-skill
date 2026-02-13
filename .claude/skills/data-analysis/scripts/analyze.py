#!/usr/bin/env python3
"""
Basic data analysis script.
Usage: python analyze.py <data_file>
"""

import sys
import argparse
import pandas as pd


def analyze_data(filepath):
    """Perform basic analysis on the data."""
    # Detect file format
    if filepath.endswith('.csv'):
        df = pd.read_csv(filepath)
    elif filepath.endswith(('.xlsx', '.xls')):
        df = pd.read_excel(filepath)
    elif filepath.endswith('.json'):
        df = pd.read_json(filepath)
    else:
        print(f"Unsupported file format: {filepath}")
        return

    print("\n" + "="*50)
    print("DATA ANALYSIS REPORT")
    print("="*50 + "\n")

    print("Dataset Shape:")
    print(f"  Rows: {len(df)}")
    print(f"  Columns: {len(df.columns)}\n")

    print("Column Information:")
    print(df.info())
    print("\n")

    print("Missing Values:")
    missing = df.isnull().sum()
    if missing.sum() > 0:
        print(missing[missing > 0])
    else:
        print("  No missing values")
    print("\n")

    print("Numeric Columns Statistics:")
    print(df.describe())
    print("\n")

    print("Sample Data (first 5 rows):")
    print(df.head())
    print("\n")


def main():
    parser = argparse.ArgumentParser(description='Analyze data from CSV, Excel, or JSON')
    parser.add_argument('file', help='Path to data file')
    args = parser.parse_args()

    analyze_data(args.file)


if __name__ == '__main__':
    main()
