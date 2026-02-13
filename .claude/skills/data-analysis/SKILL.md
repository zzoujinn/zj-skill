---
name: data-analysis
description: 分析和可视化来自 CSV、JSON 或 Excel 文件的数据。当用户要求分析数据、创建图表、生成报告、探索数据集、查找数据模式或执行统计分析时使用。触发条件包括："analyze this data"、"create charts"、"data visualization"、"explore dataset"、"find patterns"、"statistical analysis"、"generate report from data"、"data insights"。
---

# 数据分析

## 快速开始

```bash
# 基础分析
python scripts/analyze.py data.csv

# 生成可视化图表
python scripts/visualize.py data.csv --output charts/

# 生成完整报告
python scripts/report.py data.csv --output report.html
```

## 支持的格式

| 格式 | 扩展名 | 说明 |
|--------|-----------|-------|
| CSV | .csv | 最常用，逗号分隔 |
| Excel | .xlsx, .xls | 使用 `openpyxl` 或 `xlrd` |
| JSON | .json | 对象数组或键值对 |

## 分析流水线

### 1. 数据加载
加载并检查数据结构：
```bash
python scripts/explore.py data.csv
```

这将显示：
- 列名和类型
- 缺失值计数
- 基本统计信息（均值、中位数、标准差、最小值、最大值）
- 示例行

### 2. 数据清洗
处理常见的数据问题：
- 缺失值（删除或填充）
- 重复记录
- 异常值检测
- 类型转换

使用清洗脚本：
```bash
python scripts/clean.py data.csv --output clean.csv
```

### 3. 探索性分析
生成洞察：
```bash
python scripts/explore.py data.csv --correlations
```

这将生成：
- 相关性矩阵
- 分布图
- 分类列的值计数

### 4. 可视化
使用可视化脚本创建图表：

```bash
# 单个图表
python scripts/visualize.py data.csv --type histogram --column age

# 多个图表
python scripts/visualize.py data.csv --output ./charts/

# 特定图表类型
python scripts/visualize.py data.csv --type scatter --x age --y income
python scripts/visualize.py data.csv --type bar --column category
python scripts/visualize.py data.csv --type pie --column region
python scripts/visualize.py data.csv --type line --x date --y value
```

可用的图表类型：
- `histogram` - 数值列的分布
- `scatter` - 两个数值列之间的关系
- `bar` - 分类数据比较
- `pie` - 部分与整体的关系
- `line` - 随时间变化的趋势
- `box` - 分布的箱线图
- `heatmap` - 相关性热力图

### 5. 统计检验
执行统计分析：

```bash
# 相关性分析
python scripts/stats.py data.csv --correlation

# 假设检验
python scripts/stats.py data.csv --test ttest --group column --value column

# 回归分析
python scripts/stats.py data.csv --regression --target target_column
```

### 6. 报告生成
创建综合 HTML 报告：

```bash
python scripts/report.py data.csv --output report.html --title "数据分析报告"
```

报告包括：
- 执行摘要
- 数据概览
- 主要发现
- 可视化
- 统计分析
- 建议

## 常见分析模式

### 时间序列分析
对于基于日期的数据：
```bash
python scripts/visualize.py data.csv --type line --x date --y value
python scripts/scripts/trend.py data.csv --column value --period daily
```

### 分组分析
跨类别比较：
```bash
python scripts/scripts/group_analysis.py data.csv --group category --agg sum
```

### 异常值检测
查找异常值：
```bash
python scripts/scripts/outliers.py data.csv --column value --threshold 3
```

## 最佳实践

1. **先检查数据** - 分析前使用 `explore.py`
2. **记录发现** - 使用报告生成进行文档化
3. **前后可视化** - 比较清洗后的数据与原始数据
4. **考虑样本量** - 小数据集的统计能力有限
5. **检查假设** - 许多统计检验需要正态性

## 脚本参考

### analyze.py
基本摘要统计和概览。

### visualize.py
生成图表和可视化。
- `--type`: 图表类型（histogram, scatter, bar, pie, line, box, heatmap）
- `--column`: 要可视化的列
- `--x`, `--y`: 散点图/折线图的列
- `--output`: 图表输出目录
- `--title`: 图表标题

### explore.py
探索数据集结构。
- `--correlations`: 包含相关性分析
- `--missing`: 详细的缺失值报告

### clean.py
清洗和预处理数据。
- `--drop-missing`: 删除有缺失值的行
- `--fill-missing`: 用均值/中位数/众数填充
- `--remove-duplicates`: 删除重复行
- `--output`: 输出文件路径

### report.py
生成 HTML 报告。
- `--output`: 输出文件路径
- `--title`: 报告标题
- `--author`: 报告作者

### stats.py
统计检验和分析。
- `--correlation`: 相关性矩阵
- `--test`: 统计检验类型（ttest, anova, chi2）
- `--regression`: 线性回归
- `--target`: 回归的目标列

## 依赖项

脚本需要：
- Python 3.8+
- pandas
- numpy
- matplotlib
- seaborn
- plotly
- scipy
- openpyxl（用于 Excel 文件）

安装方式：
```bash
pip install pandas numpy matplotlib seaborn plotly scipy openpyxl
```
