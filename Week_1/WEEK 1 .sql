-- ================================================================
-- BENFORD'S LAW FRAUD DETECTION ENGINE
-- Author: Tanishq Khavate
-- Dataset: Northwind Database (PostgreSQL)
-- Status: Week 1 Complete — Foundation Queries
-- Description: Implements Benford's Law digit frequency analysis
--              to detect anomalous transaction patterns
-- ================================================================


-- SECTION 1: EXPECTED FREQUENCY VIEW
-- Purpose: Generate Benford's expected digit distribution
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- benford_expected VIEW 

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
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- purpose - what does this query do ?
-- this query gives the expected percentages of occurences in any large naturally occuring large numeric data sets such as taxes, invoices, population etc.
-- by using the loagarithmic formula log (1 + 1 / digit(1 to 9)) *  100 
-- which helps maily to determine if any person is trying to fabricate the numbers. 
-- we can comapre the results with the benfords expected results with tolerances and can have a clear conclusion. 

-- input- what tables have used in thid query ?
-- no tables are used in this query
-- it is writtern purely using the math formulas and functions. 

-- output- what does the result look like ? 
-- in the resulat we can see the expected percentage values for the leading digits across 1 to 9. 
-- result columns include digit and expected percentage. 

-- note - any edge cases or the important details ?
-- this query used the recursive cte and call by executing itself for every row. 
-- ROUND(
		(LOG(1 + 1.0 / DIGIT) / LOG(10))::NUMERIC * 100,
		2
	) AS EXPECTED_PCT
-- in this part that 0 after the decimal of 1.0 is important because it gives the results in the decimal format.
-- if that 0 is not there then the round function will not work, it will throw an error of explicit type casting. 
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SECTION 2: FIRST DIGIT EXTRACTION
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- EXTRACT FROM TotalSales

WITH
	REVENUE AS (
		SELECT
			UNITPRICE,
			QUANTITY,
			DISCOUNT,
			(UNITPRICE * (1 - DISCOUNT)) * QUANTITY AS TOTAL_SALES
		FROM
			ORDER_DETAILS
	)
SELECT
	TOTAL_SALES,
	LEFT(CAST(ABS(FLOOR(TOTAL_SALES)) AS TEXT), 1)::INT AS FIRST_DIGIT
FROM
	REVENUE
WHERE
	TOTAL_SALES > 0
	AND TOTAL_SALES IS NOT NULL
LIMIT
	20
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EXTRACT FROM FREIGHT

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
LIMIT
	20
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- EXTRACT FROM UnitPrice

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
LIMIT
	20
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- purpose - what does this query do ? 
-- extract the leading (first) digit from the financial columns. 

--INPUT: Which table(s) does it read from?
-- different tables are used to extract the leading the digits 
1. ORDER_DETAILS -(total_sales)
2. orders - (freight)

--OUTPUT: What does the result look like?
-- output includes financial column and the leadin digits extracted from the numbers. 

-- NOTE: Any edge cases or important details?
-- the value in the fianancial column must be greater then 0 as benfords law is not applicable to digit 0.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SECTION 3: OBSERVED FREQUENCY VIEWS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--- benford_observed_totalsales

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
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- for freight 

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
			O.FREIGHT > 1
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
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- for unit price 

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
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SECTION 4: DEVIATION COMPARISON VIEWS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- THE CORE COMPARISON QUERY

SELECT
	O.FIRST_DIGIT,
	O.OBSERVED_COUNT,
	O.OBSERVED_PCT,
	E.EXPECTED_PCT,
	ROUND(ABS(O.OBSERVED_PCT - E.EXPECTED_PCT), 2) AS ABS_DEVIATION,
	ROUND(
		ABS(
			O.OBSERVED_PCT - E.EXPECTED_PCT / NULLIF(E.EXPECTED_PCT, 0)
		),
		2
	) AS RELATIVE_DEVIATION_PCT,
	CASE
		WHEN ABS(O.OBSERVED_PCT - E.EXPECTED_PCT) > 10 THEN 'High'
		WHEN ABS(O.OBSERVED_PCT - E.EXPECTED_PCT) > 5 THEN 'Medium'
		ELSE 'ok'
	END AS DEVIATION_FLAG
FROM
	BENFORD_OBSERVED_TOTALSALES O
	JOIN BENFORD_EXPECTED E ON O.FIRST_DIGIT = E.DIGIT
ORDER BY
	O.FIRST_DIGIT
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SAVING THE QUERY AS A VIEW - TOTAL SALES

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
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FREIGHT 

CREATE OR REPLACE VIEW BENFORD_COMPARISON_TOTALSALES AS
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
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FOR UNIT PRICE

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
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SECTION 5: SEGMENTED ANALYSIS
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
BENFORD ANALYSIS PER SUPPLIER

SELECT
	S.COMPANYNAME AS SUPPLIER,
	LEFT(CAST(ABS(FLOOR(OD.TOTAL_SALES)) AS TEXT), 1)::INT AS FIRST_DIGIT,
	COUNT(*) AS TXN_COUNT,
	ROUND(
		COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
			PARTITION BY
				S.COMPANYNAME
		),
		2
	) AS OBS_PCT
FROM
	ORDER_DETAILS OD
	JOIN PRODUCTS P ON OD.PRODUCTID = P.PRODUCTID
	JOIN SUPPLIERS S ON S.SUPPLIERID = P.SUPPLIERID
WHERE
	OD.TOTAL_SALES > 0
GROUP BY
	S.COMPANYNAME,
	FIRST_DIGIT
ORDER BY
	S.COMPANYNAME,
	FIRST_DIGIT
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DEVIATION SCORE PER SUPPLIER — FIND THE WORST

CREATE OR REPLACE VIEW DEVIATION_PER_SUPPLIER AS 
WITH SUPPLIER_DETAILS AS (
    SELECT
        S.COMPANYNAME AS SUPPLIER,
        LEFT(CAST(ABS(FLOOR(OD.TOTAL_SALES)) AS TEXT), 1)::INT AS FIRST_DIGIT,
        COUNT(*) AS OBSERVED_COUNT,
        ROUND(
            COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY S.COMPANYNAME),
            2
        ) AS OBS_PCT
    FROM ORDER_DETAILS OD
    JOIN PRODUCTS P ON OD.PRODUCTID = P.PRODUCTID
    JOIN SUPPLIERS S ON S.SUPPLIERID = P.SUPPLIERID
    WHERE OD.TOTAL_SALES > 0
    GROUP BY S.COMPANYNAME, FIRST_DIGIT
),

-- Step 1: Calculate per-supplier deviation scores
SUPPLIER_SCORES AS (
    SELECT
        SD.SUPPLIER,
        COUNT(SD.FIRST_DIGIT)                                    AS DIGITS_PRESENT,
        SUM(SD.OBSERVED_COUNT)                                   AS TOTAL_TRANSACTIONS,
        ROUND(AVG(ABS(SD.OBS_PCT - BE.EXPECTED_PCT)), 2)        AS AVG_DEVIATION,
        ROUND(MAX(ABS(SD.OBS_PCT - BE.EXPECTED_PCT)), 2)        AS MAX_DEVIATION
    FROM SUPPLIER_DETAILS SD
    JOIN BENFORD_EXPECTED BE ON SD.FIRST_DIGIT = BE.DIGIT
    GROUP BY SD.SUPPLIER
    HAVING SUM(SD.OBSERVED_COUNT) >= 5
),

-- Step 2: Calculate the dataset average deviation
-- so every supplier can be compared against it
DATASET_AVG AS (
    SELECT ROUND(AVG(AVG_DEVIATION), 2) AS DATASET_AVG_DEVIATION
    FROM SUPPLIER_SCORES
)

-- Step 3: Final output with both benchmarks applied
SELECT
    SS.SUPPLIER,
    SS.DIGITS_PRESENT,
    SS.TOTAL_TRANSACTIONS,
    SS.AVG_DEVIATION,
    SS.MAX_DEVIATION,
    DA.DATASET_AVG_DEVIATION,

    -- How many times worse than the dataset average?
    ROUND(SS.AVG_DEVIATION / NULLIF(DA.DATASET_AVG_DEVIATION, 0), 2)
        AS TIMES_WORSE_THAN_AVG,

    -- Benchmark 1: Fixed threshold classification
	-- The thresholds 3%, 7%, 15% come from Dr. Mark Nigrini's research. 
	-- He is a forensic accounting professor at The College of New Jersey 
	-- and literally wrote the book on Benford's Law in auditing 
	-- "Benford's Law: Applications for Forensic Accounting, Auditing, and Fraud Detection" (2012).
    CASE
        WHEN SS.AVG_DEVIATION > 15 THEN '🔴 HIGH RISK'
        WHEN SS.AVG_DEVIATION > 7  THEN '🟡 MEDIUM RISK'
        WHEN SS.AVG_DEVIATION > 3  THEN '🟠 MONITOR'
        ELSE                            '🟢 CONFORMS'
    END AS RISK_LEVEL,

    -- Benchmark 2: Compared to dataset average
    CASE
        WHEN SS.AVG_DEVIATION > DA.DATASET_AVG_DEVIATION * 2
        THEN '⚠ ABOVE DATASET AVERAGE'
        ELSE 'Within Normal Range'
    END AS VS_DATASET

FROM SUPPLIER_SCORES SS
CROSS JOIN DATASET_AVG DA
ORDER BY SS.AVG_DEVIATION DESC;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DEVIATION PER EMPLOYEE - 
CREATE OR REPLACE VIEW EMPLOYEE_DEVIATION AS 
WITH
	EMPLOYEE_ANALYSIS AS (
		SELECT
			CONCAT(E.FIRSTNAME, ' ', E.LASTNAME) AS EMPLOYEE_NAME,
			LEFT(CAST(ABS(FLOOR(OD.TOTAL_SALES)) AS TEXT), 1)::INT AS FIRST_DIGIT,
			COUNT(*) AS OBSERVED_COUNT,
			ROUND(
				COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
					PARTITION BY
						E.EMPLOYEEID
				),
				2
			) AS OBS_PCT
		FROM
			ORDER_DETAILS OD
			JOIN ORDERS O USING (ORDERID)
			JOIN EMPLOYEES E USING (EMPLOYEEID)
		GROUP BY
			EMPLOYEE_NAME,
			FIRST_DIGIT,
			E.EMPLOYEEID
		ORDER BY
			EMPLOYEE_NAME,
			FIRST_DIGIT,
			E.EMPLOYEEID
	),
	----------------------------------------------------------------------------------------------
	EMPLOYEE_DEVIATION AS (
		SELECT
			EA.EMPLOYEE_NAME,
			COUNT(EA.FIRST_DIGIT) AS DIGITS_PRESENT,
			SUM(EA.OBSERVED_COUNT) AS TOTAL_ORDERS,
			ROUND(AVG(ABS(EA.OBS_PCT - BE.EXPECTED_PCT)), 2) AS AVG_DEVIATION,
			ROUND(MAX(ABS(EA.OBS_PCT - BE.EXPECTED_PCT)), 2) AS MAX_DEVIATION
		FROM
			EMPLOYEE_ANALYSIS EA
			JOIN BENFORD_EXPECTED BE ON EA.FIRST_DIGIT = BE.DIGIT
		GROUP BY
			EA.EMPLOYEE_NAME
		HAVING
			SUM(EA.OBSERVED_COUNT) >= 5
		ORDER BY
			AVG_DEVIATION DESC
	),
	----------------------------------------------------------------------------------------------
	DATASET_AVG AS (
		SELECT
			ROUND(AVG(AVG_DEVIATION), 2) AS DATASET_AVG_DEVIATION
		FROM
			EMPLOYEE_DEVIATION
	)
	----------------------------------------------------------------------------------------------
SELECT
	ED.EMPLOYEE_NAME,
	ED.DIGITS_PRESENT,
	ED.TOTAL_ORDERS,
	ED.AVG_DEVIATION,
	ED.MAX_DEVIATION,
	DA.DATASET_AVG_DEVIATION,
	CASE
		WHEN ED.AVG_DEVIATION > 15 THEN '🔴 HIGH RISK'
		WHEN ED.AVG_DEVIATION > 7 THEN '🟡 MEDIUM RISK'
		WHEN ED.AVG_DEVIATION > 3 THEN '🟠 MONITOR'
		ELSE '🟢 CONFORMS'
	END AS RISK_LEVEL,
	CASE
		WHEN ED.AVG_DEVIATION > DA.DATASET_AVG_DEVIATION * 2 THEN '⚠ ABOVE DATASET AVERAGE'
		ELSE 'Within Normal Range'
	END AS VS_DATASET
FROM
	EMPLOYEE_DEVIATION ED
	CROSS JOIN DATASET_AVG DA
ORDER BY
	ED.AVG_DEVIATION DESC;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
