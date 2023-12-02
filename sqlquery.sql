SELECT * 
FROM portfolio..sales_data_sample

--Checking Unique Values 
/* SELECT DISTINCT STATUS,YEAR_ID,TERRITORY,DEALSIZE,COUNTRY,PRODUCTLINE
FROM sales_data_sample */
SELECT DISTINCT STATUS FROM sales_data_sample --plot
SELECT DISTINCT YEAR_ID FROM sales_data_sample 
SELECT DISTINCT TERRITORY FROM sales_data_sample --plot
SELECT DISTINCT DEALSIZE FROM sales_data_sample --plot
SELECT DISTINCT COUNTRY FROM sales_data_sample --plot
SELECT DISTINCT PRODUCTLINE FROM sales_data_sample --plot

--Analysis

--Grouping Sales by Productline
SELECT PRODUCTLINE,sum(SALES) AS Revenue
FROM sales_data_sample
GROUP BY PRODUCTLIne
ORDER BY 2 DESC

--Grouping Sales by Year ID
SELECT YEAR_ID,SUM(SALES) AS Revenue
FROM sales_data_sample
GROUP BY YEAR_ID
ORDER BY 2 DESC

--Grouping Sales by Dealsize
SELECT DEALSIZE, SUM(SALES) AS Revenue
FROM sales_data_sample
GROUP BY DEALSIZE
ORDER BY 2 DESC

--What was the best month for sales in specific year? and how muchwas earned that month?
SELECT MONTH_ID, SUM(SALES) AS REVENUE, COUNT(ORDERNUMBER) AS Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2003 --change year to see the rest
GROUP BY MONTH_ID
ORDER BY 2 DESC

--November is the best month for Sales: What product sales in november 
SELECT MONTH_ID, PRODUCTLINE, SUM(SALES) AS Revenue, COUNT(ORDERNUMBER) AS Frequency
FROM sales_data_sample
WHERE YEAR_ID = 2003 AND MONTH_ID = 11
GROUP BY MONTH_ID,PRODUCTLINE
ORDER BY 3 DESC

--who is the best customer?
DROP TABLE IF EXISTS #rfm;
WITH rfm as(
SELECT CUSTOMERNAME,
SUM(SALES) AS Montery_Value,
AVG(SALES) AS AVG_Month_Value,
COUNT(ORDERNUMBER) AS Frequency,
MAX(ORDERDATE) AS Last_Order_Date,
(SELECT MAX(ORDERDATE) FROM sales_data_sample) AS max_order_date,
DATEDIFF(day,MAX(ORDERDATE) ,(SELECT MAX(ORDERDATE) FROM sales_data_sample)) AS "Recency"
FROM sales_data_sample
GROUP BY CUSTOMERNAME),

rfm_calc as
(
SELECT r.*,
NTILE(4) OVER (ORDER BY Recency) rfm_Recency,
NTILE(4) OVER (ORDER BY Frequency) rfm_Frequency,
NTILE(4) OVER (ORDER BY AVG_Month_Value) rfm_monetry
FROM rfm r)

SELECT c.*,rfm_Recency+rfm_Frequency+rfm_monetry as rfm_cell,
cast(rfm_Recency as varchar) + cast(rfm_Frequency as varchar) + cast(rfm_monetry as varchar)as rfm_cell_string
into #rfm
FROM rfm_calc c

select * from #rfm

select CUSTOMERNAME,rfm_Recency,rfm_Frequency,rfm_monetry,
case
    when rfm_cell_string in (111,112,121,123,132,211,212,114,141) then 'lost customer'
	when rfm_cell_string in (133,134,143,244,334,343,344) then 'slipping away cannot lose'
	when rfm_cell_string in (311,411,331) then 'new customer'
	when rfm_cell_string in (222,223,233,322) then 'potential churners'
	when rfm_cell_string in (323,333,321,422,332,432) then 'active'
	when rfm_cell_string in (433,434,443,444) then 'loyal'
end rfm_segment
from #rfm

--what product are often sells together

SELECT PRODUCTCODE
FROM sales_data_sample
WHERE ORDERNUMBER IN(
SELECT ORDERNUMBER
FROM(
SELECT ORDERNUMBER,COUNT(*) RN
FROM portfolio..sales_data_sample
WHERE STATUS = 'shipped'
GROUP BY ORDERNUMBER) m
WHERE RN = 2)





