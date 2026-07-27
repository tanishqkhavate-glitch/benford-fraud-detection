# Benford's Law Fraud Detection Engine

**Tools:** PostgreSQL · Power BI
**Status:** ✅ Complete
**Dataset:** Northwind Database (PostgreSQL)
**Period:** Aug 1994 – Jun 1996 | 29 Suppliers | 830 Orders | 77 Products

---

## What This Project Does

Implements a forensic fraud detection system using Benford's Law
entirely in pure PostgreSQL — no Python, no machine learning libraries.

Benford's Law states that in any naturally occurring financial dataset,
digit 1 appears as the first digit ~30% of the time, digit 2 ~17%,
and so on. When humans fabricate or manipulate numbers, they violate
this pattern. This project detects those violations using three
independent statistical signals.

---

## Detection Methods

| Method | What It Catches | SQL Technique |
|--------|----------------|---------------|
| Benford's Law + Chi-Square | Systematic digit pattern manipulation across many transactions | Recursive CTEs, window functions, POWER(), SUM() |
| Z-Score Anomaly Detection | Individual transactions with statistically extreme values | STDDEV() OVER(), AVG() OVER(), NULLIF() |
| Duplicate & Pattern Detection | Near-duplicates, threshold avoidance, round number clustering | Self-joins, HAVING, FILTER, FLOOR() |

All three signals are combined into a weighted risk score (0-100)
per supplier using a normalised multi-signal scoring engine.

---

## Project Phases

| Phase | Content | Status |
|-------|---------|--------|
| Week 1 | Benford expected frequency engine, first digit extraction, observed vs expected comparison, supplier deviation ranking | ✅ Complete |
| Week 2 | Chi-square significance testing, Z-score anomaly detection, duplicate detection, weighted risk scoring engine | ✅ Complete |
| Week 3 | Power BI fraud dashboard (2 pages), final presentation | ✅ Complete |

---

## Key Findings

### Column-Level Analysis
- **UnitPrice:** χ²=217.69 — VERY HIGH RISK (p<0.01, 99% confidence)
- **TotalSales:** χ²=21.12 — VERY HIGH RISK (p<0.01, 99% confidence)
- **Freight:** χ²=10.79 — CONFORMS (no significant deviation)

### Top Supplier Risk Scores
| Rank | Supplier | Risk Score | Primary Signal |
|------|---------|------------|---------------|
| 1 | Nord-Ost-Fisch Handelsgesellschaft | 57.5 | Chi-square=21.34 (VERY HIGH, n=32) |
| 2 | Aux joyeux ecclésiastiques | 47.5 | Z-score outliers=17 (luxury product caveat) |
| 3 | New Orleans Cajun Delights | 46.3 | Chi-square=21.19 + round number anomaly |
| 4 | Plutzer Lebensmittelgroßmärkte AG | 46.1 | Z-score=8 outliers despite clean chi-square |

### Strongest Individual Transaction Finding
**Order #10983** — Freight=$657.54 on goods worth $720.90 = **91.2%
freight-to-revenue ratio**. Flagged independently by three separate
methods: EDA ratio analysis, Z-score detection (Z=4.96), and
cross-reference validation. Cross-method validation eliminates
false positive risk.

### Negative Results (Also Findings)
- Zero near-duplicate transactions across 830 orders
- No threshold avoidance pattern at any approval limit zone
- No supplier reached HIGH RISK (>70) — consistent with Northwind
  being a clean demonstration dataset

---

## SQL Concepts Used

- Recursive CTEs (digit series generation)
- Window Functions: `OVER()`, `PARTITION BY`, `SUM OVER`, `STDDEV OVER`
- `COUNT(*) FILTER (WHERE ...)` — PostgreSQL-specific aggregate filtering
- `POWER()`, `LOG()`, `FLOOR()`, `ABS()`, `NULLIF()`
- Chi-square formula: `Σ [(O-E)² / E]` implemented in pure SQL
- Z-score: `(value - AVG OVER()) / STDDEV OVER()`
- Self-joins for near-duplicate detection
- Multi-CTE risk scoring with LEFT JOINs and COALESCE

---



## Files in This Repository

| File | Description |
|------|-------------|
| `week1/benford_week1.sql` | Week 1 SQL — expected frequency, first digit extraction, deviation comparison |
| `week2/benford_week2.sql` | Week 2 SQL — chi-square, Z-score, duplicate detection, risk scoring engine |
| `outputs/Benfords_Law_Fraud_Detection.pptx` | Final presentation (10 slides) |
| `outputs/Benfords_Law_Fraud_Detection.pbix` | Power BI dashboard file |

---

## Dataset
Northwind Database — loaded into PostgreSQL
Financial columns analysed: TotalSales, UnitPrice, Freight
Entities: 29 Suppliers · 91 Customers · 77 Products · 9 Employees
