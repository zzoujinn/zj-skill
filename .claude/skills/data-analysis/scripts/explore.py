#!/usr/bin/env python3
"""
Data exploration script.
Usage: python explore.py <data_file> [--correlations]
"""

import sys
import argparse
import pandas as pd
import numpy as np


def explore_data(filepath, correlations=False):
    """Explore and display dataset information."""
    # Load data
    if filepath.endswith('.csv'):
        df = pd.read_csv(filepath)
    elif filepath.endswith(('.xlsx', '.xls')):
        df = pd.read_excel(filepath)
    elif filepath.endswith('.json'):
        df = pd.read_json(filepath)
    else:
        print(f"Unsupported file format: {filepath}")
        return

    print("\n" + "="*60)
    print("DATA EXPLORATION")
    print("="*60 + "\n")

    # Basic info
    print("Dataset Overview:")
    print(f"  Shape: {df.shape[0]} rows × {df.shape[1]} columns")
    print(f"  Memory usage: {df.memory_usage(deep=True).sum() / 1024 / 1024:.2f} MB")
    print("\n")

    # Column details
    print("Column Details:")
    for col in df.columns:
        dtype = df[col].dtype
        null_count = df[col].isnull().sum()
        null_pct = (null_count / len(df)) * 100
        unique_count = df[col].nunique()

        print(f"  {col}:")
        print(f"    Type: {dtype}")
        print(f"    Missing: {null_count} ({null_pct:.1f}%)")
        print(f"    Unique values: {unique_count}")

        if dtype == 'object' and unique_count <= 10:
            print(f"    Values: {list(df[col].value_counts().index[:5])}")
    print("\n")

    # Statistics for numeric columns
    numeric_cols = df.select_dtypes(include=[np.number]).columns
    if len(numeric_cols) > 0:
        print("Numeric Column Statistics:")
        print(df[numeric_cols].describe())
        print("\n")

    # Missing values report
    missing = df.isnull().sum()
    if missing.sum() > 0:
        print("Missing Values Detail:")
        missing_df = pd.DataFrame({
            'Column': missing[missing > 0].index,
            'Missing': missing[missing > 0].values,
            'Percentage': (missing[missing > 0].values / len(df) * 100).round(1)
        })
        print(missing_df.to_string(index=False))
        print("\n")

    # Duplicate rows
    duplicates = df.duplicated().sum()
    print(f"Duplicate Rows: {duplicates} ({(duplicates/len(df)*100):.1f}%)\n")

    # Correlations
    if correlations and len(numeric_cols) >= 2:
        print("Correlation Matrix:")
        corr_matrix = df[numeric_cols].corr()
        print(corr_matrix)
        print("\n")

        # Strong correlations
        print("Strong Correlations (|r| > 0.7):")
        for i, col1 in enumerate(numeric_cols):
            for j, col2 in enumerate(numeric_cols):
                if i < j:
                    corr_val = corr_matrix.loc[col1, col2]
                    if abs(corr_val) > 0.7:
                        print(f"  {col1} ↔ {col2}: {corr_val:.3f}")
        print("\n")

    # Sample data
    print("Sample Data (first 3 rows):")
    print(df.head(3))
    print("\n")


def main():
    parser = argparse.ArgumentParser(description='Explore data structure')
    parser.add_argument('file', help='Path to data file')
    parser.add_argument('--correlations', action='store_true',
                       help='Include correlation analysis')
    args = parser.parse_args()

    explore_data(args.file, args.correlations)


if __name__ == '__main__':
    main()
