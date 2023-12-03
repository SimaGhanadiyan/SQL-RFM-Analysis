--Inspecting Data
SELECT * 
FROM ..sales_data_sample

--Checking Unique Values 
SELECT DISTINCT STATUS FROM sales_data_sample --plot
SELECT DISTINCT YEAR_ID FROM sales_data_sample 
SELECT DISTINCT TERRITORY FROM sales_data_sample --plot
SELECT DISTINCT DEALSIZE FROM sales_data_sample --plot
SELECT DISTINCT COUNTRY FROM sales_data_sample --plot
SELECT DISTINCT PRODUCTLINE FROM sales_data_sample --plot

--Analysis:
--1: Grouping Sales by Product line
SELECT PRODUCTLINE,SUM(SALES) AS Revenue
FROM sales_data_sample
GROUP BY PRODUCTLIne
ORDER BY 2 DESC

--2: Grouping Sales by Year ID
SELECT YEAR_ID,SUM(SALES) AS Revenue
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC

--Why is the amount of sales in 2005 low?
SELECT DISTINCT MONTH_ID
FROM sales_data_sample
WHERE YEAR_ID = 2005

--3: Grouping Sales by Dealsize
SELECT DEALSIZE, SUM(SALES) AS Revenue
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC

--4: What was the best month for sales in specific year? And how much was earned that month?
SELECT MONTH_ID, SUM(SALES) AS REVENUE, COUNT(ORDERNUMBER) AS Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2003 --change year to see the rest
GROUP BY MONTH_ID
ORDER BY 2 DESC

--5: November was the best month for Sales: What product sales in november 
SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2003 AND MONTH_ID = 11
GROUP BY MONTH_ID,PRODUCTLINE
ORDER BY 3 DESC

--6: Who is the best customer?
DROP TABLE IF EXISTS #rfm;
WITH rfm AS(
	SELECT CUSTOMERNAME,
	SUM(SALES) AS Montery_Value,
	AVG(SALES) AS AVG_Month_Value,
	COUNT(ORDERNUMBER) AS Frequency,
	MAX(ORDERDATE) AS Last_Order_Date,
	(SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,
	DATEDIFF(day,MAX(ORDERDATE) ,(SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS "Recency"
	FROM sales_data_sample
	GROUP BY CUSTOMERNAME
),
rfm_calc as
(
	SELECT r.*,
	NTILE(4) OVER (ORDER BY Recency) rfm_Recency,
	NTILE(4) OVER (ORDER BY Frequency) rfm_Frequency,
	NTILE(4) OVER (ORDER BY Montery_Value) rfm_monetry
	FROM rfm r
)
SELECT 
	c.*,rfm_Recency+rfm_Frequency+rfm_monetry as rfm_cell,
	cast(rfm_Recency as varchar) + cast(rfm_Frequency as varchar) + cast(rfm_monetry as varchar)as rfm_cell_string
	into #rfm
FROM rfm_calc c

SELECT * FROM #rfm

SELECT CUSTOMERNAME,rfm_Recency,rfm_Frequency,rfm_monetry,
	CASE
		WHEN rfm_cell_string in (111,112,121,122,123,132,211,212,114,141) THEN 'lost customer'
		WHEN rfm_cell_string in (133,134,143,244,334,343,344) THEN 'slipping away cannot lose'
		WHEN rfm_cell_string in (311,411,331) THEN 'new customer'
		WHEN rfm_cell_string in (222,223,233,322) THEN 'potential churners'
		WHEN rfm_cell_string in (323,333,321,422,332,432) THEN 'active'
		WHEN rfm_cell_string in (433,434,443,444) THEN 'loyal'
	END rfm_segment
FROM #rfm



--7: what product are often sells together
select distinct OrderNumber, stuff(

	(select ',' + PRODUCTCODE
	from [dbo].[sales_data_sample] p
	where ORDERNUMBER in 
		(

			select ORDERNUMBER
			from (
				select ORDERNUMBER, count(*) rn
				FROM sales_data_sample
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 3
		)
		and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path (''))

		, 1, 1, '') ProductCodes

from [dbo].[sales_data_sample] s
order by 2 desc



