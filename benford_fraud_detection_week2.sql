-- ================================================================
-- BENFORD'S LAW FRAUD DETECTION ENGINE
-- Author: Tanishq Khavate
-- Dataset: Northwind Database (PostgreSQL)
-- Period: 
-- Tools: PostgreSQL, Microsoft Excel, Power BI
-- Status: Week 2 Complete
-- ================================================================


-- ════════════════════════════════════════════════════════════════
-- SECTION 1: EXPECTED FREQUENCY (WEEK 1)
-- ════════════════════════════════════════════════════════════════

-- PURPOSE: Generate Benford's expected digit distribution (1-9)
-- INPUT:   None — uses mathematical formula only
-- OUTPUT:  9 rows, one per digit, with expected_pct

CREATE OR REPLACE VIEW benford_expected AS
WITH RECURSIVE
	DIGIT_SERIES AS (
		SELECT
			1 AS DIGIT
		UNION ALL
		SELECT
			DIGIT + 1
		FROM
			DIGIT_SERIES
		WHERE
			DIGIT < 9
	)
SELECT
	DIGIT,
	ROUND(
		(LOG(1 + 1.0 / DIGIT) / LOG(10))::NUMERIC * 100,
		2
	) AS EXPECTED_PCT
FROM
	DIGIT_SERIES
ORDER BY
	DIGIT;



-- ════════════════════════════════════════════════════════════════
-- SECTION 2: FIRST DIGIT EXTRACTION & OBSERVED FREQUENCY (WEEK 1)
-- ════════════════════════════════════════════════════════════════

-- PURPOSE: Extract leading digit from financial columns
--          and calculate observed frequency per digit
-- INPUT:   order_details (TotalSales, UnitPrice, Freight)
-- OUTPUT:  9 rows per column with observed count and %
===============================================================================================================
--- benford_observed_totalsales
===============================================================================================================
CREATE OR REPLACE VIEW benford_observed_totalsales AS
WITH TOTAL_SALES AS (
    SELECT
        ROUND(
            (UNITPRICE::NUMERIC * (1 - DISCOUNT::NUMERIC)) * QUANTITY,
            2
        ) AS TOTAL_SALES
    FROM ORDER_DETAILS
    WHERE UNITPRICE > 0
      AND QUANTITY > 0
      AND UNITPRICE IS NOT NULL
      AND QUANTITY IS NOT NULL
),
WITH_DIGIT AS (
    SELECT
        TOTAL_SALES,
        LEFT(CAST(ABS(FLOOR(TOTAL_SALES)) AS TEXT), 1)::INT AS FIRST_DIGIT
    FROM TOTAL_SALES
    WHERE TOTAL_SALES > 0   -- handles 100% discount edge case
)
SELECT
    FIRST_DIGIT,
    COUNT(*) AS OBSERVED_COUNT,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)   AS OBSERVED_PCT
FROM WITH_DIGIT
GROUP BY FIRST_DIGIT
ORDER BY FIRST_DIGIT;

===============================================================================================================
-- for freight 
===============================================================================================================
CREATE OR REPLACE VIEW benford_observed_freight AS
WITH
	FREIGHT AS (
		SELECT
			O.ORDERID,
			O.FREIGHT,
			LEFT(CAST(ABS(FLOOR(O.FREIGHT)) AS TEXT), 1)::INT AS FIRST_DIGIT_FREIGHT
		FROM
			ORDERS O
		WHERE
			O.FREIGHT > 0
			AND O.FREIGHT IS NOT NULL
		ORDER BY
			O.ORDERID
	)
SELECT
	FIRST_DIGIT_FREIGHT,
	COUNT(*) AS OBSERVED_COUNT,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS OBSERVED_PCT
FROM
	FREIGHT
GROUP BY
	FIRST_DIGIT_FREIGHT
ORDER BY
	FIRST_DIGIT_FREIGHT

===============================================================================================================
-- for unit price 
===============================================================================================================
CREATE OR REPLACE VIEW AS BENFORD_OBSERVED_UNITPRICE
WITH
	UNIT_PRICE AS (
		SELECT
			OD.ORDERID,
			OD.UNITPRICE,
			LEFT(CAST(ABS(FLOOR(UNITPRICE)) AS TEXT), 1)::INT AS FIRST_DIGIT_UNIT_PRICE
		FROM
			ORDER_DETAILS OD
		WHERE
			OD.UNITPRICE > 0
			AND OD.UNITPRICE IS NOT NULL
		ORDER BY
			OD.ORDERID
	)
SELECT
	FIRST_DIGIT_UNIT_PRICE,
	COUNT(*) AS OBSERVED_COUNT,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS OBSERVED_PCT
FROM
	UNIT_PRICE
GROUP BY
	FIRST_DIGIT_UNIT_PRICE
ORDER BY
	FIRST_DIGIT_UNIT_PRICE



-- ════════════════════════════════════════════════════════════════
-- SECTION 3: DEVIATION COMPARISON (WEEK 1)
-- ════════════════════════════════════════════════════════════════

-- PURPOSE: Compare observed vs expected, flag deviations
-- INPUT:   benford_observed_* views + benford_expected view
-- OUTPUT:  9 rows per column with deviation % and risk flag

===============================================================================================================
-- TOTAL SALES
===============================================================================================================
CREATE OR REPLACE VIEW BENFORD_COMPARISON_TOTALSALES AS
SELECT
	O.FIRST_DIGIT,
	O.OBSERVED_COUNT,
	O.OBSERVED_PCT,
	E.EXPECTED_PCT,
	ROUND(ABS(O.OBSERVED_PCT - E.EXPECTED_PCT), 2) AS ABS_DEVIATION,
	CASE
		WHEN ABS(O.OBSERVED_PCT - E.EXPECTED_PCT) > 10 THEN 'HIGH'
		WHEN ABS(O.OBSERVED_PCT - E.EXPECTED_PCT) > 5 THEN 'MEDIUM'
		ELSE 'OK'
	END AS DEVIATION_FLAG
FROM
	BENFORD_OBSERVED_TOTALSALES O
	JOIN BENFORD_EXPECTED E ON O.FIRST_DIGIT = E.DIGIT
ORDER BY
	O.FIRST_DIGIT;

===============================================================================================================
-- FREIGHT 
===============================================================================================================
CREATE OR REPLACE VIEW BENFORD_COMPARISON_FREIGHT AS
SELECT
	F.FIRST_DIGIT_FREIGHT,
	F.OBSERVED_COUNT,
	F.OBSERVED_PCT,
	E.EXPECTED_PCT,
	ROUND(ABS(F.OBSERVED_PCT - E.EXPECTED_PCT), 2) AS ABS_DEVIATION,
	CASE
		WHEN ABS(F.OBSERVED_PCT - E.EXPECTED_PCT) > 10 THEN 'HIGH'
		WHEN ABS(F.OBSERVED_PCT - E.EXPECTED_PCT) > 5 THEN 'MEDIUM'
		ELSE 'OK'
	END AS DEVIATION_FLAG
FROM
	BENFORD_OBSERVED_FREIGHT F
	JOIN BENFORD_EXPECTED E ON F.FIRST_DIGIT_FREIGHT = E.DIGIT
ORDER BY
	F.FIRST_DIGIT_FREIGHT;

===============================================================================================================
-- FOR UNIT PRICE
===============================================================================================================
CREATE OR REPLACE VIEW BENFORD_COMPARISON_UNITPRICE AS
SELECT
	U.FIRST_DIGIT_UNIT_PRICE,
	U.OBSERVED_COUNT,
	U.OBSERVED_PCT,
	E.EXPECTED_PCT,
	ROUND(ABS(U.OBSERVED_PCT - E.EXPECTED_PCT), 2) AS ABS_DEVIATION,
	CASE
		WHEN ABS(U.OBSERVED_PCT - E.EXPECTED_PCT) > 10 THEN 'HIGH'
		WHEN ABS(U.OBSERVED_PCT - E.EXPECTED_PCT) > 5 THEN 'MEDIUM'
		ELSE 'OK'
	END AS DEVIATION_FLAG
FROM
	BENFORD_OBSERVED_UNITPRICE U
	JOIN BENFORD_EXPECTED E ON U.FIRST_DIGIT_UNIT_PRICE = E.DIGIT
ORDER BY
	U.FIRST_DIGIT_UNIT_PRICE



-- ════════════════════════════════════════════════════════════════
-- SECTION 4: SEGMENTED BENFORD ANALYSIS (WEEK 1)
-- ════════════════════════════════════════════════════════════════

-- PURPOSE: Benford deviation per supplier and per employee
-- INPUT:   order_details, products, suppliers, employees
-- OUTPUT:  One row per supplier/employee with deviation score

===============================================================================================================
CREATE OR REPLACE VIEW benford_supplier_deviation AS
WITH supplier_digits AS (
    SELECT
        s.CompanyName AS supplier,
        LEFT(CAST(ABS(FLOOR(od.TOTAL_SALES)) AS TEXT), 1)::INT
            AS first_digit,
        COUNT(*) AS observed_count,
        ROUND(
            COUNT(*) * 100.0
            / SUM(COUNT(*)) OVER (PARTITION BY s.CompanyName),
        2) AS observed_pct
    FROM ORDER_DETAILS od
    JOIN PRODUCTS  p ON od.PRODUCTID  = p.PRODUCTID
    JOIN SUPPLIERS s ON p.SUPPLIERID  = s.SUPPLIERID
    WHERE od.TOTAL_SALES > 0
    GROUP BY s.CompanyName, first_digit
)
SELECT
    sd.supplier,
    SUM(sd.observed_count)                              AS total_transactions,
    ROUND(AVG(ABS(sd.observed_pct - be.expected_pct)), 2)
                                                        AS avg_deviation,
    CASE
        WHEN AVG(ABS(sd.observed_pct - be.expected_pct)) > 15 THEN 100
        WHEN AVG(ABS(sd.observed_pct - be.expected_pct)) > 10 THEN 75
        WHEN AVG(ABS(sd.observed_pct - be.expected_pct)) > 7  THEN 50
        WHEN AVG(ABS(sd.observed_pct - be.expected_pct)) > 4  THEN 25
        ELSE                                                        10
    END AS benford_score
FROM supplier_digits sd
JOIN benford_expected be ON sd.first_digit = be.digit
GROUP BY sd.supplier
HAVING SUM(sd.observed_count) >= 5
ORDER BY avg_deviation DESC;
===============================================================================================================


-- ════════════════════════════════════════════════════════════════
-- SECTION 5: CHI-SQUARE SIGNIFICANCE TESTING (DAY 9)
-- ════════════════════════════════════════════════════════════════

-- PURPOSE: Test if Benford deviations are statistically significant
-- METHOD:  Chi-square formula, df=8, thresholds 13.36/15.51/20.09
-- INPUT:   benford_observed_* views + benford_expected view
-- OUTPUT:  Chi-square value + risk level per supplier and per column

===============================================================================================================
-- chi_square_totalsales 
===============================================================================================================
 CREATE OR REPLACE VIEW CHI_SQUARE_TOTALSALES AS

WITH
	OBSERVED_VS_EXPECTED AS (
		SELECT
			O.FIRST_DIGIT,
			O.OBSERVED_COUNT,
			ROUND(
				E.EXPECTED_PCT / 100.0 * SUM(O.OBSERVED_COUNT) OVER (),
				4
			) AS EXPECTED_COUNT
		FROM
			BENFORD_OBSERVED_TOTALSALES O
			JOIN BENFORD_EXPECTED E ON O.FIRST_DIGIT = E.DIGIT
	)
SELECT
	SUM(OBSERVED_COUNT) AS TOTAL_TRANSACTIONS,
	ROUND(
		SUM(
			POWER(OBSERVED_COUNT - EXPECTED_COUNT, 2) / NULLIF(EXPECTED_COUNT, 0)
		),
		4
	) AS CHI_SQUARE, -- df is always 8 for Benford's 9-digit analysis
	8 AS DEGREES_OF_FREEDOM, -- Compare against critical values
	CASE
		WHEN SUM(
			POWER(OBSERVED_COUNT - EXPECTED_COUNT, 2) / NULLIF(EXPECTED_COUNT, 0)
		) > 20.09 THEN 'VERY HIGH RISK (p < 0.01 | 99% confidence)'
		WHEN SUM(
			POWER(OBSERVED_COUNT - EXPECTED_COUNT, 2) / NULLIF(EXPECTED_COUNT, 0)
		) > 15.51 THEN 'HIGH RISK (p < 0.05 | 95% confidence)'
		WHEN SUM(
			POWER(OBSERVED_COUNT - EXPECTED_COUNT, 2) / NULLIF(EXPECTED_COUNT, 0)
		) > 13.36 THEN 'MODERATE (p < 0.10 | 90% confidence)'
		ELSE 'CONFORMS (no significant deviation)'
	END AS SIGNIFICANCE
FROM
	OBSERVED_VS_EXPECTED;

===============================================================================================================
-- chi_square_per_supplier 
===============================================================================================================
CREATE OR REPLACE VIEW CHI_SQUARE_PER_SUPPLIER AS
WITH
	SUPPLIER_OBSERVED AS (
		SELECT
			S.COMPANYNAME AS SUPPLIER_NAME,
			LEFT(CAST(ABS(FLOOR(O.TOTAL_SALES)) AS TEXT), 1)::INT AS FIRST_DIGIT,
			COUNT(*) AS OBSERVED_COUNT
		FROM
			ORDER_DETAILS O
			JOIN PRODUCTS P ON O.PRODUCTID = P.PRODUCTID
			JOIN SUPPLIERS S ON P.SUPPLIERID = S.SUPPLIERID
		GROUP BY
			S.COMPANYNAME,
			FIRST_DIGIT
	),
	SUPPLIER_WITH_EXPECTED AS (
		SELECT
			SO.SUPPLIER_NAME,
			SO.FIRST_DIGIT,
			SO.OBSERVED_COUNT,
			SUM(SO.OBSERVED_COUNT) OVER (
				PARTITION BY
					SO.SUPPLIER_NAME
			) AS SUPPLIER_TOTAL,
			ROUND(
				(B.EXPECTED_PCT / 100.0) * SUM(SO.OBSERVED_COUNT) OVER (
					PARTITION BY
						SO.SUPPLIER_NAME
				),
				4
			) AS EXPECTED_COUNT
		FROM
			SUPPLIER_OBSERVED SO
			JOIN PUBLIC.BENFORD_EXPECTED B ON SO.FIRST_DIGIT = B.DIGIT
	),
	SUPPLIER_CHI_SQUARE AS (
		SELECT
			SUPPLIER_NAME,
			SUPPLIER_TOTAL AS TOTAL_TRANSACTIONS,
			8 AS DEGREES_OF_FREEDOM,
			ROUND(
				SUM(
					POWER(OBSERVED_COUNT - EXPECTED_COUNT, 2) / NULLIF(EXPECTED_COUNT, 0)
				),
				4
			) AS CHI_SQUARE
		FROM
			SUPPLIER_WITH_EXPECTED
		GROUP BY
			SUPPLIER_NAME,
			SUPPLIER_TOTAL
		HAVING
			SUPPLIER_TOTAL > 10
	)
SELECT
	SUPPLIER_NAME,
	TOTAL_TRANSACTIONS,
	DEGREES_OF_FREEDOM,
	CHI_SQUARE,
	CASE
		WHEN CHI_SQUARE > 20.19 THEN 'VERY HIGH RISK'
		WHEN CHI_SQUARE > 15.51 THEN 'HIGH RISK'
		WHEN CHI_SQUARE > 13.36 THEN 'MODERATE'
		ELSE 'CONFORMS'
	END AS RISK_LEVEL,
	ROUND(CHI_SQUARE - 15.51, 2) AS DEVIATION_FROM_95PCT_THRESHOLD
FROM
	SUPPLIER_CHI_SQUARE
ORDER BY
	CHI_SQUARE DESC;



-- ════════════════════════════════════════════════════════════════
-- SECTION 6: Z-SCORE ANOMALY DETECTION (DAY 10)
-- ════════════════════════════════════════════════════════════════

-- PURPOSE: Flag individual transactions with extreme values
-- METHOD:  Z-score = (value - mean) / stddev, threshold ±3
-- INPUT:   order_details, orders (for freight)
-- OUTPUT:  Flagged transactions + outlier count per supplier

===============================================================================================================
-- zscore_supplier_flags 
===============================================================================================================
CREATE OR REPLACE VIEW zscore_supplier_flags AS
WITH z_scores AS (
    SELECT
        od.OrderID,
        od.ProductID,
        od.TOTAL_SALES,
        ROUND(
            (od.TOTAL_SALES - AVG(od.TOTAL_SALES) OVER())
            / NULLIF(STDDEV(od.TOTAL_SALES) OVER(), 0),
        2) AS z_score
    FROM ORDER_DETAILS od
    WHERE od.TOTAL_SALES > 0
)
SELECT
    s.CompanyName                           AS supplier,
    COUNT(*) FILTER (WHERE ABS(z.z_score) > 3)
                                            AS outlier_count,
    COUNT(*)                                AS total_transactions,
    ROUND(
        COUNT(*) FILTER (WHERE ABS(z.z_score) > 3)
        * 100.0 / NULLIF(COUNT(*), 0),
    1)                                      AS outlier_pct
FROM z_scores z
JOIN PRODUCTS p  ON z.ProductID  = p.ProductID
JOIN SUPPLIERS s ON p.SupplierID = s.SupplierID
GROUP BY s.CompanyName
HAVING COUNT(*) FILTER (WHERE ABS(z.z_score) > 3) > 0
ORDER BY outlier_count DESC;



-- ════════════════════════════════════════════════════════════════
-- SECTION 7: DUPLICATE & PATTERN DETECTION (DAY 11)
-- ════════════════════════════════════════════════════════════════

-- PURPOSE: Detect near-duplicates, threshold avoidance,
--          round number clustering
-- INPUT:   orders, order_details, suppliers
-- OUTPUT:  Duplicate pairs, threshold buckets, round% per supplier

===============================================================================================================
-- duplicate_flags_per_supplier 
===============================================================================================================

CREATE OR REPLACE VIEW duplicate_flags_per_supplier AS

WITH round_pct AS (
    SELECT
        s.CompanyName AS supplier,
        ROUND(
            COUNT(*) FILTER (
                WHERE od.TOTAL_SALES = FLOOR(od.TOTAL_SALES)
            ) * 100.0 / NULLIF(COUNT(*), 0), 1
        ) AS round_number_pct
    FROM ORDER_DETAILS od
    JOIN PRODUCTS  p ON od.ProductID  = p.ProductID
    JOIN SUPPLIERS s ON p.SupplierID  = s.SupplierID
    WHERE od.TOTAL_SALES > 0
    GROUP BY s.CompanyName
)
SELECT
    supplier,
    round_number_pct,
    CASE
        WHEN round_number_pct > 30 THEN 'HIGH'
        WHEN round_number_pct > 15 THEN 'MODERATE'
        ELSE 'NORMAL'
    END AS round_flag
FROM round_pct
WHERE round_number_pct > 0
ORDER BY round_number_pct DESC;




-- ════════════════════════════════════════════════════════════════
-- SECTION 8: RISK SCORING ENGINE (DAY 12)
-- ════════════════════════════════════════════════════════════════
-- PURPOSE: Combine all signals into one weighted risk score
-- METHOD:  Normalise each signal to 0-100, apply weights
--          Chi=40%, Z-Score=35%, Benford=25%, Round modifier flat
-- INPUT:   All views from Sections 4-7
-- OUTPUT:  One risk score (0-100) and risk level per supplier

===============================================================================================================
-- supplier_risk_scores 
===============================================================================================================
    CREATE OR REPLACE VIEW supplier_risk_scores AS
SELECT
    -- Use chi_square_per_supplier as the base
    -- because it has all 29 suppliers
    c.supplier_name                                AS supplier,

    -- ── SIGNAL 1: BENFORD SCORE ─────────────────────────────
    COALESCE(b.benford_score, 10)                  AS benford_score,
    COALESCE(b.avg_deviation, 0)                   AS avg_deviation,

    -- ── SIGNAL 2: CHI-SQUARE SCORE ──────────────────────────
    c.chi_square,
    CASE
        WHEN c.chi_square > 20.09 THEN 100
        WHEN c.chi_square > 15.51 THEN 75
        WHEN c.chi_square > 13.36 THEN 50
        WHEN c.chi_square > 8     THEN 25
        ELSE                           10
    END                                            AS chi_score,

    -- ── SIGNAL 3: Z-SCORE OUTLIER COUNT ─────────────────────
    COALESCE(z.outlier_count, 0)                   AS outlier_count,
    LEAST(COALESCE(z.outlier_count, 0) * 12, 100)  AS zscore_score,

    -- ── SIGNAL 4: ROUND NUMBER MODIFIER ─────────────────────
    COALESCE(d.round_number_pct, 0)                AS round_number_pct,
    CASE
        WHEN COALESCE(d.round_number_pct, 0) < 10 THEN 5
        WHEN COALESCE(d.round_number_pct, 0) > 75 THEN 3
        ELSE                                            0
    END                                            AS round_modifier,

    -- ── FINAL WEIGHTED RISK SCORE ────────────────────────────
    ROUND(
        (COALESCE(b.benford_score, 10) * 0.25)
      + (CASE
             WHEN c.chi_square > 20.09 THEN 100
             WHEN c.chi_square > 15.51 THEN 75
             WHEN c.chi_square > 13.36 THEN 50
             WHEN c.chi_square > 8     THEN 25
             ELSE                           10
         END * 0.40)
      + (LEAST(COALESCE(z.outlier_count, 0) * 12, 100) * 0.35)
      + (CASE
             WHEN COALESCE(d.round_number_pct, 0) < 10 THEN 5
             WHEN COALESCE(d.round_number_pct, 0) > 75 THEN 3
             ELSE                                            0
         END),
    1)                                             AS risk_score,

    -- ── RISK CLASSIFICATION ──────────────────────────────────
    CASE
        WHEN ROUND(
            (COALESCE(b.benford_score, 10) * 0.25)
          + (CASE
                 WHEN c.chi_square > 20.09 THEN 100
                 WHEN c.chi_square > 15.51 THEN 75
                 WHEN c.chi_square > 13.36 THEN 50
                 WHEN c.chi_square > 8     THEN 25
                 ELSE                           10
             END * 0.40)
          + (LEAST(COALESCE(z.outlier_count, 0) * 12, 100) * 0.35)
          + (CASE
                 WHEN COALESCE(d.round_number_pct,0) < 10 THEN 5
                 WHEN COALESCE(d.round_number_pct,0) > 75 THEN 3
                 ELSE                                           0
             END),
        1) > 70 THEN 'HIGH RISK'
        WHEN ROUND(
            (COALESCE(b.benford_score, 10) * 0.25)
          + (CASE
                 WHEN c.chi_square > 20.09 THEN 100
                 WHEN c.chi_square > 15.51 THEN 75
                 WHEN c.chi_square > 13.36 THEN 50
                 WHEN c.chi_square > 8     THEN 25
                 ELSE                           10
             END * 0.40)
          + (LEAST(COALESCE(z.outlier_count, 0) * 12, 100) * 0.35)
          + (CASE
                 WHEN COALESCE(d.round_number_pct,0) < 10 THEN 5
                 WHEN COALESCE(d.round_number_pct,0) > 75 THEN 3
                 ELSE                                           0
             END),
        1) > 40 THEN 'MEDIUM RISK'
        ELSE 'LOW RISK'
    END                                            AS risk_level

FROM chi_square_per_supplier          c
LEFT JOIN benford_supplier_deviation  b ON c.supplier_name = b.supplier
LEFT JOIN zscore_supplier_flags       z ON c.supplier_name = z.supplier
LEFT JOIN duplicate_flags_per_supplier d ON c.supplier_name = d.supplier

ORDER BY risk_score DESC;

-- Test it:
SELECT * FROM supplier_risk_scores;