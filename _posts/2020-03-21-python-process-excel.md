---
title: 基于openpyxl操作excel
date: 2020-03-21 19:44:12
category: python
tags: openpyxl, python, excel
layout: post
---

因工作中经常需要将系统中的数据或统计结果导出到excel表格中，对于动态生成表头的情况下，不便于将数据或统计结果写入到csv中，于是开始了解如何将数据写入到excel中。

## Python的excel工具类

Python的excel工具类介绍，可参见 [python-excel](http://www.python-excel.org/)。

* openpyxl: 推荐用于读写 excel 2010 的文件（后缀 xlsx/xlsm/xltx/xltm）
* xlsxwriter: 可用于写数据到 excel 2010 的文件（后缀 xlsx）
* xlrd：可用于读 excel 2003 及以前的旧格式 excel 文件（后缀 xls）
* xlwt：可用于写 excel 2003 及以前的旧格式 excel 文件（后缀 xls）
* xlutils：将 xlrd 和 xlwt 进行了整合，可读和写excel 2003 及以前的旧格式 excel 文件（后缀 xls）

根据 pandas 参考文档中 [IO工具类部分](https://pandas.pydata.org/pandas-docs/stable/user_guide/io.html#excel-files) 关于 [Excel写入引擎](https://www.pypandas.cn/docs/user_guide/io.html#excel-%E6%96%87%E4%BB%B6) 的说明；默认情况下， pandas 使用 xlsxwriter 来写入 .xlsx 文件，使用 openpyxl 来写入 .xlsm 文件，使用 xlwt 来写入 .xls 文件；使用 xlrd 来读取 .xls 文件，使用 openpyxl 来读取 .xlsx 文件。

## openpyxl的使用

下面重点介绍一下 [openpyxl](https://openpyxl.readthedocs.io/en/stable/) 的使用。

Excel 中有以下的三大对象：
* WorkBook：工作簿对象
* Sheet：表单对象
* Cell：单元格对象

### 创建一个excel文件
```py
# -*- coding: utf-8 -*-
import openpyxl
wb = Workbook()    # 创建一个工作簿对象
```

### 打开指定名称的excel文件
```py
# -*- coding: utf-8 -*-
import openpyxl
wb = load_workbook('test.xlsx')    # 创建一个工作簿对象
```

### 获取第一个表单
```py
# -*- coding: utf-8 -*-
import openpyxl
wb = Workbook()    # 创建一个工作簿对象
ws = wb.active()
```

### 创建一个新表单
```py
# -*- coding: utf-8 -*-
import openpyxl
wb = Workbook()    # 创建一个工作簿对象
ws = wb.create_sheet('test_sheet')
```

### 根据名称打开指定表单
```py
# -*- coding: utf-8 -*-
import openpyxl
wb = load_workbook('test.xlsx')    # 打开工作簿对象
ws = wb['test_sheet']
```

### 删除一个新表单
```py
# -*- coding: utf-8 -*-
import openpyxl
wb = load_workbook('test.xlsx')    # 打开工作簿对象
ws = wb['test_sheet']
wb.remove(ws)                       # 删除表单 test_sheet
```

### 修改表单名称
```py
# -*- coding: utf-8 -*-
import openpyxl
wb = load_workbook('test.xlsx')    # 创建一个工作簿对象
ws = wb['test_sheet']
ws.title = 'test_modify'
wb.save('test.xlsx')               # 保存修改
wb.close()                         # 关闭文件
```

### 按行读取数据
```py
# -*- coding: utf-8 -*-
import openpyxl
wb = load_workbook('test.xlsx')    # 创建一个工作簿对象
ws = wb['test_sheet']
for row_data in ws.rows  # 读取表单test_sheet的所有行，并按行遍历
    print(row_data)
```

### 读取指定单元格

操作excel的单元格时，第1行A列的坐标是 row = 1, column = 1

```py
# -*- coding: utf-8 -*-
import openpyxl
wb = load_workbook('test.xlsx')    # 创建一个工作簿对象
ws = wb['test_sheet']
ce = ws.cell(row = 1, column = 1)  # 读取表单test_sheet的第1行A列数据
```

### 写入指定单元格
```py
# -*- coding: utf-8 -*-
import openpyxl
wb = load_workbook('test.xlsx')    # 创建一个工作簿对象
ws = wb['test_sheet']
ce = ws.cell(row = 1, column = 1, value = '数值')   # 写入表单test_sheet的第1行A列
ce = ws.cell(row = 2, column = 1, value = 10)       # 写入表单test_sheet的第2行A列
```

### 合并单元格
```py
# -*- coding: utf-8 -*-
import openpyxl
wb = Workbook()
ws = wb.active

ws.merge_cells(start_row = 2, start_column = 1, end_row = 2, end_column = 4)    # 合并第二行的第A至D列
ws.unmerge_cells(start_row = 2, start_column = 1, end_row = 2, end_column = 4)  # 取消合并
```

## 参考
1. [pandas中文手册](https://www.pypandas.cn/docs/user_guide/io.html#excel-%E6%96%87%E4%BB%B6)
2. [pandas官方手册](https://pandas.pydata.org/pandas-docs/stable/user_guide/io.html#excel-files)
3. [openpyxl官方说明文档](https://openpyxl.readthedocs.io/en/stable/)
4. [python-excel](http://www.python-excel.org/)
5. [使用 python 修改 excel 表格的 sheet 名称](https://www.cnblogs.com/valorchang/p/11357385.html)
6. [python操作Excel表格](https://www.cnblogs.com/wanglle/p/11455758.html)
7. [python3编程基础：操作excel(一)](https://blog.csdn.net/kongsuhongbaby/article/details/85646750)

