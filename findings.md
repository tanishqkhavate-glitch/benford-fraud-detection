## Key Findings

### Column-Level Analysis
- UnitPrice: χ²=217.69 — VERY HIGH RISK (p<0.01)
- TotalSales: χ²=21.12 — VERY HIGH RISK (p<0.01)
- Freight: χ²=10.79 — CONFORMS

### Top Supplier Risk Scores
1. Nord-Ost-Fisch Handelsgesellschaft — 57.5 (MEDIUM)
2. Aux joyeux ecclésiastiques — 47.5 (MEDIUM)
3. New Orleans Cajun Delights — 46.3 (MEDIUM)
4. Plutzer Lebensmittelgroßmärkte AG — 46.1 (MEDIUM)

### Key Transaction Finding
- Order #10983: Freight=$657.54 on Revenue=$720.90
  = 91.2% freight-to-revenue ratio
  Flagged independently by EDA, Z-score, and ratio analysis

### Notable Pattern
- No supplier crossed HIGH RISK threshold (>70)
  Consistent with Northwind being a clean demonstration dataset
  Model validates correctly — relative ranking is meaningful
