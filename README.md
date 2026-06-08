# Benford's Law Fraud Detection Engine
**Tools:** PostgreSQL · Microsoft Excel · Power BI  
**Status:** 🔄 In Progress — Week 1 of 3 Complete  
**Dataset:** Northwind Database

---

## What This Project Does
Implements a forensic fraud detection system using Benford's Law 
entirely in PostgreSQL — no Python, no ML libraries.

Benford's Law states that in any naturally occurring financial 
dataset, digit 1 appears as the first digit ~30% of the time, 
digit 2 ~17%, and so on. When humans fabricate or manipulate 
numbers, they violate this pattern. This project detects those 
violations.

---

## Project Phases

| Phase | Content | Status |
|-------|---------|--------|
| Week 1 | Expected frequency engine, first digit extraction, observed vs expected comparison, supplier & employee deviation scoring | ✅ Complete |
| Week 2 | Chi-Square significance testing, Z-Score anomaly detection, duplicate detection, risk scoring engine | 🔄 In Progress |
| Week 3 | Excel validation workbook, Power BI fraud dashboard, final presentation | ⏳ Upcoming |

---

## Week 1 — What's Built So Far

- `benford_expected` VIEW — recursive CTE generating all 9 
   expected digit frequencies using the log formula
- First digit extraction from TotalSales, Freight, UnitPrice
- Observed frequency tables per financial column
- Observed vs expected deviation comparison with risk flags
- Segmented analysis by supplier and employee
- Supplier deviation ranking with benchmark classification

---

## Key SQL Concepts Used
- Recursive CTEs
- Window Functions (PARTITION BY, SUM OVER)
- String & Math functions (LEFT, CAST, ABS, FLOOR, LOG)
- NULLIF for division safety
- CREATE OR REPLACE VIEW

---

## Dataset
Northwind Database — loaded into PostgreSQL  
Analysed columns: TotalSales, Freight, UnitPrice  
Entities analysed: 29 Suppliers, 9 Employees, 8 Categories
