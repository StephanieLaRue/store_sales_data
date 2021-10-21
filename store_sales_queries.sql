-- USE sales;
-- total sales per store
SELECT 
    Store, 
	SUM(weekly_sales) AS Sales
FROM
    store_sales
GROUP BY Store
ORDER BY Sales DESC;

-- total sales for years 2010-2012
SELECT * FROM(
	SELECT
		Store StoreNumber,
		YEAR(Date) Year,
		SUM(weekly_sales) TotalSales
	FROM
		store_sales
	GROUP BY Store, YEAR(Date)
) sales_tb
PIVOT(SUM(TotalSales) FOR Year IN ([2010],[2011],[2012])) pivot_tb;

-- holiday sales for 3 years
-- sales for each year
SELECT * FROM(
	SELECT
		Store StoreNumber,
		IsHoliday,
		YEAR(Date) Year,
		SUM(weekly_sales) TotalSales
	FROM
		store_sales
	GROUP BY Store, YEAR(Date), IsHoliday
) sales_tb
PIVOT(SUM(TotalSales) FOR Year IN ([2010],[2011],[2012])) pivot_tb
ORDER BY StoreNumber, IsHoliday desc;

-- only holiday sales
SELECT * FROM(
	SELECT
		Store StoreNumber,
		YEAR(Date) Year,
		SUM(weekly_sales) TotalSales,
		IsHoliday
	FROM
		store_sales
	WHERE
		IsHoliday = 'TRUE'
	GROUP BY Store, YEAR(Date), IsHoliday
) sales_tb
PIVOT(SUM(TotalSales) FOR Year IN ([2010],[2011],[2012])) pivot_tb
ORDER BY StoreNumber, IsHoliday desc;

-- avg WEEKLY sales by store and all departments
SELECT 
    Store StoreNumber,
    FORMAT(AVG(weekly_sales),'C') AS AvgSales_AllDepts
FROM
    store_sales
GROUP BY Store
ORDER BY StoreNumber;

-- markdowns vs store sales
SELECT 
    sf.Store, TotalMarkdowns, TotalSales
FROM
    ((SELECT 
        Store,
            SUM(MarkDown1+MarkDown2+MarkDown3+MarkDown4+MarkDown5) AS TotalMarkdowns
    FROM
        store_features
    GROUP BY Store) sf
    JOIN (SELECT 
        Store,
            SUM(weekly_sales) AS TotalSales
    FROM
        store_sales
    GROUP BY Store) ss ON sf.Store = ss.Store);
    
-- holiday sales totals vs non holidays all years
SELECT 
    Store,
    IsHoliday,
    FORMAT(SUM(weekly_sales), 'C') Holiday_Sales,
    COUNT(IsHoliday) AS Days
FROM
    store_sales
GROUP BY Store, IsHoliday
ORDER BY store, IsHoliday DESC;

-- avg sales on holidays vs avg sales on non holidays
SELECT 
    Store,
    IsHoliday,
    FORMAT(AVG(weekly_sales), 'C') AvgHolidaySales
FROM
    store_sales
GROUP BY Store , IsHoliday
ORDER BY store , IsHoliday DESC;

-- total number of markdowns per store & total sales
-- all years
SELECT 
    sf.Store StoreNumber,
    NumberOfMarkdowns,
    TotalSales
FROM
    ((SELECT 
        Store,
            COUNT(MarkDown1)+COUNT(MarkDown2)+COUNT(MarkDown3)
			+COUNT(MarkDown4)+COUNT(Markdown5) AS NumberOfMarkdowns
    FROM
        store_features
		WHERE 
			MarkDown1 > 0 AND MarkDown2 > 0 
			AND MarkDown3 > 0 AND MarkDown4 > 0 
			AND MarkDown5 > 0 
    GROUP BY Store) sf
    JOIN (SELECT 
        Store,
        SUM(weekly_sales) TotalSales
    FROM
        store_sales
    GROUP BY Store) ss ON sf.Store = ss.Store)
ORDER BY TotalSales desc;

-- number of markdowns on holidays vs non holidays
SELECT 
    Store,
    IsHoliday,
    COUNT(MarkDown1)+COUNT(MarkDown2)+COUNT(MarkDown3)
	+COUNT(MarkDown4)+COUNT(Markdown5) AS NumberOfMarkdowns
FROM
    store_features
WHERE 
	MarkDown1 > 0 AND MarkDown2 > 0 
	AND MarkDown3 > 0 AND MarkDown4 > 0 
	AND MarkDown5 > 0 
GROUP BY Store, IsHoliday 
ORDER BY Store, IsHoliday desc;
    
-- avg markdown on holidays vs non holidays
SELECT 
    Store,
    IsHoliday,
    FORMAT(AVG(MarkDown1+MarkDown2+MarkDown3+MarkDown4+Markdown5),
        'c') AS AvgMarkdown
FROM
    store_features
GROUP BY Store, IsHoliday
ORDER BY Store;
    
-- total and avg sales all years by store type
SELECT 
    st.Store,
    Type StoreType,
	AVG(weekly_sales) AS AvgSales,
    SUM(weekly_sales) AS TotalSales
FROM
    store_types st
JOIN
    store_sales ss 
	ON st.Store = ss.Store
GROUP BY st.Store, Type
ORDER BY Type, TotalSales desc;

-- avg and total sales for specific store types
SELECT 
    Type StoreType,
	AVG(weekly_sales) AS AvgSales,
    SUM(weekly_sales) AS TotalSales
FROM
    store_types st
JOIN
    store_sales ss 
	ON st.Store = ss.Store
GROUP BY Type
ORDER BY Type, TotalSales desc;

-- individual year totals and avgs by store type
SELECT 
	YEAR(Date) Year,
    Type StoreType,
	AVG(weekly_sales) AS AvgSales,
    SUM(weekly_sales) AS TotalSales
FROM
    store_types st
JOIN
    store_sales ss 
	ON st.Store = ss.Store
GROUP BY Type, YEAR(Date)
ORDER BY Year, Type, TotalSales desc;
    
-- year over year sales differences for each store
SELECT 
       Store,
	   YEAR(Date) AS Year,
       FORMAT(SUM(weekly_sales),'C') AS TotalSales,
       format(LAG(SUM(weekly_sales)) OVER (partition by Store ORDER BY YEAR(Date) ),'C') AS PreviousYear,
       format(SUM(weekly_sales) - LAG(SUM(weekly_sales)) OVER (partition by Store ORDER BY YEAR(Date) ),'C') AS YOY_Difference
FROM   store_sales
WHERE YEAR(Date) IS NOT NULL 
GROUP BY Store, YEAR(Date);

-- % growth year over year
WITH cte AS (
    SELECT DISTINCT
		Store,
	   YEAR(Date) AS Year,
	   SUM(weekly_sales) AS Total,
       LAG(SUM(weekly_sales)) OVER (partition by Store ORDER BY YEAR(Date) ) AS PreviousYear,
       SUM(weekly_sales) - LAG(SUM(weekly_sales)) OVER (partition by Store ORDER BY YEAR(Date) ) AS YOY_Difference
FROM   store_sales WHERE YEAR(Date) IS NOT NULL 
	GROUP BY Store, YEAR(Date))
SELECT 
	Store,
    Year, 
	FORMAT(Total,'C') Total_Sales, 
	FORMAT(YOY_Difference,'C') YOY_Difference,
	FORMAT(100*(YOY_Difference/PreviousYear),'N') AS Percentage_Change
FROM cte;

-- highest grossing months for each store 2010-2012
SELECT 
	Store,
	Year,
    Month,
	FORMAT(TotalSales,'C') TotalSales
FROM 
	(SELECT DISTINCT
	   Store,
       ROW_NUMBER() OVER(PARTITION By Year, Store Order By TotalSales DESC) as year_rows,
	   Year,
       Month,
	   TotalSales
	FROM 
		(SELECT Store, 
            Year(Date) as Year, 
            Month(Date) as Month, 
            SUM(weekly_sales) as TotalSales
            FROM   store_sales 
            WHERE YEAR(Date) IS NOT NULL
            GROUP BY 
                Store, 
                Year(Date), 
                Month(Date)
              ) ss2
    GROUP BY Store, Year, Month, TotalSales) sales_tb
    WHERE sales_tb.year_rows = 1
	ORDER BY Store, Year, Month;


    
