
/***************************************************************************************************************************************************/
/*--------------------------------------------------------------QUESTIONS WITH ANSWERS-------------------------------------------------------------*/
/***************************************************************************************************************************************************/


use db_SQLCaseStudies

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Q1.LIST ALL THE STATES IN WE HAVE CUSTOMERS WHO HAVE BOUGHT CELLPHONES FROM 2005 TILL TODAY ?                                                                                      |  
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

	SELECT DISTINCT State FROM FACT_TRANSACTIONS AS TRANSACTIONS
	LEFT JOIN DIM_LOCATION AS LOCATIONS
	ON 
	TRANSACTIONS.IDLocation = LOCATIONS.IDLocation
	WHERE  Date between '01-01-2005' AND GETDATE();



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Q2.What state in the US is buying more 'Samsung' cell phones?                                                                                                                      |  
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT TOP 1 Country, State  FROM DIM_LOCATION AS LOC 
	LEFT JOIN FACT_TRANSACTIONS AS TRANSACTIONS ON 
	LOC.IDLocation = TRANSACTIONS.IDLocation
	LEFT JOIN DIM_MODEL AS MODEL ON
	TRANSACTIONS.IDModel = MODEL.IDModel
	LEFT JOIN DIM_MANUFACTURER AS MANUFACTORER ON 
	MODEL.IDManufacturer = MANUFACTORER.IDManufacturer
	WHERE Manufacturer_Name = 'Samsung' AND Country = 'US'
	GROUP BY Country, State
	ORDER BY SUM(Quantity) DESC;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
--Q3.Show the number of transactions for each model per zip code per state.                                                                                                          |
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	

	SELECT Model_Name ,
	State, ZipCode,COUNT(IDCUSTOMER) AS [Transaction count] 
	FROM FACT_TRANSACTIONS AS TRANSACTIONS
	INNER JOIN DIM_LOCATION AS LOCATIONS ON 
	TRANSACTIONS.IDLocation = LOCATIONS.IDLocation
	INNER JOIN DIM_MODEL AS MODEL ON 
	TRANSACTIONS.IDModel = MODEL.IDModel
	GROUP BY Model_Name,ZipCode,State ;


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Q4.Show the cheapest cellphone                                                                                                                                                     | 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------																  

	SELECT TOP 1 * FROM DIM_MODEL									  
	ORDER BY Unit_price ASC	;										  


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Q5.Find out the average price for each model in the Top 5 manufacturers in terms of sales quantity and order by average price.                                                      |
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	SELECT Manufacturer_Name,Model_Name, AVG(TotalPrice) as [Average price] FROM FACT_TRANSACTIONS AS TRANSACTIONS 
	LEFT JOIN DIM_MODEL AS MODEL ON 
	TRANSACTIONS.IDModel = MODEL.IDModel
	LEFT JOIN DIM_MANUFACTURER AS MANUFACTURAR ON 
	MODEL.IDManufacturer = MANUFACTURAR.IDManufacturer
	WHERE Manufacturer_Name 
	IN 
		(			
			SELECT TOP 5 Manufacturer_Name FROM FACT_TRANSACTIONS AS TRANSACTIONS
			LEFT JOIN DIM_MODEL AS MODEL ON 
			TRANSACTIONS.IDModel = MODEL.IDModel
			LEFT JOIN DIM_MANUFACTURER AS MANUFACTURER ON
			MODEL.IDManufacturer = MANUFACTURER.IDManufacturer
			GROUP BY Manufacturer_Name
			ORDER BY SUM(QUANTITY) DESC
		)
	GROUP BY 
	Manufacturer_Name,Model_Name
	ORDER BY AVG(TotalPrice) DESC
		
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Q6.List the names of the customers and the average amount spent in 2009, where the average is higher than 500 ?                                                                    |
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
	SELECT Customer_Name ,AVG(TotalPrice) AS Average FROM FACT_TRANSACTIONS AS TRANSACTIONS
	LEFT JOIN DIM_CUSTOMER AS CUSTOMER ON
	TRANSACTIONS.IDCustomer = CUSTOMER.IDCustomer
	WHERE DATEPART(YEAR ,DATE) = 2009	
	GROUP BY Customer_Name
	HAVING AVG(TotalPrice) > 500;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Q7.List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010 ?                                                                   |
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
	
	SELECT  * FROM
	(
		SELECT * FROM
		(
			SELECT TOP 5 Model_Name FROM FACT_TRANSACTIONS AS TRANSACTIONS
			LEFT JOIN DIM_MODEL AS MODEL ON
			TRANSACTIONS.IDModel = MODEL.IDModel
			WHERE DATEPART(YEAR , Date) = 2008
			GROUP BY Model_Name
			ORDER BY 
			SUM(Quantity) DESC
		) TOP5

		UNION ALL
		SELECT * FROM
		(
			SELECT TOP 5 Model_Name FROM FACT_TRANSACTIONS AS TRANSACTIONS
			LEFT JOIN DIM_MODEL AS MODEL ON
			TRANSACTIONS.IDModel = MODEL.IDModel
			WHERE DATEPART(YEAR , Date) = 2009
			GROUP BY Model_Name
			ORDER BY 
			SUM(Quantity) DESC
		) TOP5
		
		UNION ALL

		SELECT * FROM
		(
			SELECT TOP 5 Model_Name FROM FACT_TRANSACTIONS AS TRANSACTIONS
			LEFT JOIN DIM_MODEL AS MODEL ON
			TRANSACTIONS.IDModel = MODEL.IDModel
			WHERE DATEPART(YEAR , Date) = 2010
			GROUP BY Model_Name
			ORDER BY 
			SUM(Quantity) DESC
		) TOP5

	)	AS TOP_5_TABLE
		GROUP BY Model_Name
		HAVING COUNT(*) = 3





-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Q8.Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.                                                  |
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
		
		SELECT Manufacturer_Name,YEARS,TOTAL FROM 
		(
			SELECT
			Manufacturer_Name, DATEPART(YEAR ,DATE) AS YEARS, SUM(TOTALPRICE) AS TOTAL,
			ROW_NUMBER() OVER (PARTITION BY DATEPART(YEAR ,DATE) ORDER BY SUM(TOTALPRICE) DESC) AS RNUM1 																						 
			FROM FACT_TRANSACTIONS AS F																		 
			INNER JOIN DIM_MODEL AS MODEL																	 
			ON F.IDModel = MODEL.IDModel																	 
			INNER JOIN DIM_MANUFACTURER AS MANUFACTURER														 
			ON MANUFACTURER.IDManufacturer = MODEL.IDManufacturer											 
			WHERE DATEPART(YEAR ,DATE) = 2009 OR DATEPART(YEAR ,DATE) = 2010 								 
			GROUP BY Manufacturer_Name,DATEPART(YEAR ,DATE)
		
		)AS T1
		WHERE RNUM1 = 2

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Q9.Show the manufacturers that sold cellphone in 2010 but didn’t in 2009.                                                                                                            |
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	SELECT Manufacturer_Name FROM DIM_MANUFACTURER AS MANUFACTURAR
	LEFT JOIN DIM_MODEL AS MODEL ON
	MANUFACTURAR.IDManufacturer = MODEL.IDManufacturer
	LEFT JOIN FACT_TRANSACTIONS AS TRANSACTIONS ON 
	TRANSACTIONS.IDModel = MODEL.IDModel
	WHERE DATEPART(YEAR , DATE) = 2010		
	
	EXCEPT
	
	SELECT Manufacturer_Name FROM DIM_MANUFACTURER AS MANUFACTURAR
	LEFT JOIN DIM_MODEL AS MODEL ON
	MANUFACTURAR.IDManufacturer = MODEL.IDManufacturer
	LEFT JOIN FACT_TRANSACTIONS AS TRANSACTIONS ON 
	TRANSACTIONS.IDModel = MODEL.IDModel
	WHERE DATEPART(YEAR , DATE) = 2009



----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Q.10 Find top 10 customers and their average spend, average quantity by each year.	Also find the percentage of change in their spend.                                             |
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

	WITH Report
	AS
	(
	SELECT Customer_Name, 																
	AVG(TotalPrice) AS [Average Spend],												
	AVG(Quantity) AS [Average Quantity],												
	DATEPART(YEAR,Date) AS YEARS,
	((AVG(TotalPrice) - LAG(AVG(TotalPrice),1,NULL) over (partition by  Customer_Name order by  DATEPART(YEAR,Date) ))/ AVG(TotalPrice))* 100 as [Percentages Change]
	FROM DIM_CUSTOMER AS CUSTOMERS														
	LEFT JOIN FACT_TRANSACTIONS AS TRANSACTIONS 										
	ON CUSTOMERS.IDCustomer = TRANSACTIONS.IDCustomer
	GROUP BY Customer_Name,DATEPART(YEAR,Date)											
	)

	SELECT * FROM Report
	WHERE Customer_Name IN (SELECT TOP 10 customer_name FROM DIM_CUSTOMER GROUP BY customer_name ORDER BY [Average Spend]  )
