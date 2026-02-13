#!/usr/bin/env python3
"""
Data visualization script.
Usage: python visualize.py <data_file> --type <chart_type> [options]
"""

import sys
import argparse
import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns


# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (10, 6)


def load_data(filepath):
    """Load data from file."""
    if filepath.endswith('.csv'):
        return pd.read_csv(filepath)
    elif filepath.endswith(('.xlsx', '.xls')):
        return pd.read_excel(filepath)
    elif filepath.endswith('.json'):
        return pd.read_json(filepath)
    else:
        print(f"Unsupported file format: {filepath}")
        return None


def create_histogram(df, column, output=None, title=None):
    """Create histogram."""
    plt.figure()
    sns.histplot(data=df, x=column, kde=True)
    plt.title(title or f'Distribution of {column}')
    plt.xlabel(column)
    plt.ylabel('Frequency')
    if output:
        plt.savefig(f"{output}/histogram_{column}.png", dpi=150, bbox_inches='tight')
    else:
        plt.show()
    plt.close()


def create_scatter(df, x, y, output=None, title=None):
    """Create scatter plot."""
    plt.figure()
    sns.scatterplot(data=df, x=x, y=y)
    plt.title(title or f'{x} vs {y}')
    plt.xlabel(x)
    plt.ylabel(y)
    if output:
        plt.savefig(f"{output}/scatter_{x}_{y}.png", dpi=150, bbox_inches='tight')
    else:
        plt.show()
    plt.close()


def create_bar(df, column, output=None, title=None):
    """Create bar chart."""
    plt.figure()
    counts = df[column].value_counts()
    sns.barplot(x=counts.index, y=counts.values)
    plt.title(title or f'Count by {column}')
    plt.xlabel(column)
    plt.ylabel('Count')
    plt.xticks(rotation=45)
    if output:
        plt.savefig(f"{output}/bar_{column}.png", dpi=150, bbox_inches='tight')
    else:
        plt.show()
    plt.close()


def create_pie(df, column, output=None, title=None):
    """Create pie chart."""
    plt.figure()
    counts = df[column].value_counts()
    plt.pie(counts.values, labels=counts.index, autopct='%1.1f%%')
    plt.title(title or f'Distribution of {column}')
    if output:
        plt.savefig(f"{output}/pie_{column}.png", dpi=150, bbox_inches='tight')
    else:
        plt.show()
    plt.close()


def create_line(df, x, y, output=None, title=None):
    """Create line chart."""
    plt.figure()
    sns.lineplot(data=df, x=x, y=y)
    plt.title(title or f'{y} over {x}')
    plt.xlabel(x)
    plt.ylabel(y)
    plt.xticks(rotation=45)
    if output:
        plt.savefig(f"{output}/line_{x}_{y}.png", dpi=150, bbox_inches='tight')
    else:
        plt.show()
    plt.close()


def create_box(df, column, output=None, title=None):
    """Create box plot."""
    plt.figure()
    sns.boxplot(data=df, y=column)
    plt.title(title or f'Box plot of {column}')
    plt.ylabel(column)
    if output:
        plt.savefig(f"{output}/box_{column}.png", dpi=150, bbox_inches='tight')
    else:
        plt.show()
    plt.close()


def create_heatmap(df, output=None, title=None):
    """Create correlation heatmap."""
    plt.figure(figsize=(12, 8))
    numeric_cols = df.select_dtypes(include=['number']).columns
    if len(numeric_cols) < 2:
        print("Need at least 2 numeric columns for heatmap")
        return
    corr = df[numeric_cols].corr()
    sns.heatmap(corr, annot=True, cmap='coolwarm', center=0,
                square=True, linewidths=1)
    plt.title(title or 'Correlation Heatmap')
    if output:
        plt.savefig(f"{output}/heatmap.png", dpi=150, bbox_inches='tight')
    else:
        plt.show()
    plt.close()


def main():
    parser = argparse.ArgumentParser(description='Create data visualizations')
    parser.add_argument('file', help='Path to data file')
    parser.add_argument('--type', choices=['histogram', 'scatter', 'bar', 'pie', 'line', 'box', 'heatmap'],
                       help='Chart type')
    parser.add_argument('--column', help='Column to visualize (for single-column charts)')
    parser.add_argument('--x', help='X column (for scatter/line plots)')
    parser.add_argument('--y', help='Y column (for scatter/line plots)')
    parser.add_argument('--output', help='Output directory for charts')
    parser.add_argument('--title', help='Chart title')
    args = parser.parse_args()

    df = load_data(args.file)
    if df is None:
        return

    if args.output:
        os.makedirs(args.output, exist_ok=True)

    if args.type == 'histogram':
        if not args.column:
            print("Error: --column required for histogram")
            return
        create_histogram(df, args.column, args.output, args.title)

    elif args.type == 'scatter':
        if not args.x or not args.y:
            print("Error: --x and --y required for scatter plot")
            return
        create_scatter(df, args.x, args.y, args.output, args.title)

    elif args.type == 'bar':
        if not args.column:
            print("Error: --column required for bar chart")
            return
        create_bar(df, args.column, args.output, args.title)

    elif args.type == 'pie':
        if not args.column:
            print("Error: --column required for pie chart")
            return
        create_pie(df, args.column, args.output, args.title)

    elif args.type == 'line':
        if not args.x or not args.y:
            print("Error: --x and --y required for line chart")
            return
        create_line(df, args.x, args.y, args.output, args.title)

    elif args.type == 'box':
        if not args.column:
            print("Error: --column required for box plot")
            return
        create_box(df, args.column, args.output, args.title)

    elif args.type == 'heatmap':
        create_heatmap(df, args.output, args.title)


if __name__ == '__main__':
    main()
