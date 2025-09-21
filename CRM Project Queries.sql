# MySQL Workbench does not recognize the data type of the following column, so we manually fixed it.

ALTER TABLE crm.sales_pipeline
MODIFY COLUMN engage_date date ;

UPDATE crm.sales_pipeline
SET engage_date = STR_TO_DATE(engage_date, '%Y-%m-%d');



# Q1. Count of deals by sales pipeline stage ?
Select deal_stage, count(*) As DealCount
From crm.sales_pipeline
group by deal_stage;


# Q2. Total number of accounts per Sector?
select sector, count(*) as TotalAccounts
From crm.accounts
group by sector
order by TotalAccounts DESC;


# Q3. Average number of employees by industry?

Select sector, round(avg(employees),0) as AvgEmployees
From crm.accounts
group by sector
Order by AvgEmployees DESC;

# Q4. Which regional office has the most sales agents?

select regional_office, count(sales_agent) as TotalSalesAgents
From crm.sales_teams
group by regional_office
order by TotalSalesAgents DESC;


# Q5. Which product series contains the highest number of products?

select series, count(product) as TotalProducts
From crm.products
group by series
order by TotalProducts DESC;

# Q6. Compare performance of sales teams by total annual revenue of their accounts?

SELECT st.regional_office,
       SUM(CAST(a.revenue AS DECIMAL(15,2))) AS TotalAnnualRevenue
FROM crm.sales_pipeline sp
JOIN crm.sales_teams st ON sp.sales_agent = st.sales_agent
JOIN crm.accounts a ON sp.Company_name = a.Company_name
WHERE sp.deal_stage = 'Won'
GROUP BY st.regional_office
ORDER BY TotalAnnualRevenue DESC;


# Q7. Identify sales agents with below-average performance ?

SELECT sp.sales_agent,
       COUNT(*) AS WonDeals
FROM crm.sales_pipeline sp
WHERE sp.deal_stage = 'Won'
GROUP BY sp.sales_agent
HAVING WonDeals < (
    SELECT AVG(WonDealsSub)
    FROM (
        SELECT COUNT(*) AS WonDealsSub
        FROM crm.sales_pipeline
        WHERE deal_stage = 'Won'
        GROUP BY sales_agent
    ) t
);


# Q8. Top 3 products by popularity?

SELECT product, DealCount
FROM (
    SELECT sp.product,
           COUNT(*) AS DealCount,
           RANK() OVER (ORDER BY COUNT(*) DESC) AS rnk
    FROM crm.sales_pipeline sp
    GROUP BY sp.product
) ranked
WHERE rnk <= 3;

# Q9. Sales manager with the largest team size?

SELECT manager, COUNT(sales_agent) AS AgentCount
FROM crm.sales_teams
GROUP BY manager
ORDER BY AgentCount DESC
LIMIT 1;


# Q10. Sectors ranked by average annual revenue?

SELECT sector,
       AVG(CAST(revenue AS DECIMAL(15,2))) AS AvgAnnualRevenue,
       RANK() OVER (ORDER BY AVG(CAST(revenue AS DECIMAL(15,2))) DESC) AS RevenueRank
FROM crm.accounts
GROUP BY sector;


# Q11. Quarter-over-quarter deal volume growth trend ?

WITH deals AS (
    SELECT 
        QUARTER(STR_TO_DATE(engage_date,'%Y-%m-%d')) AS DealQuarter,
        YEAR(STR_TO_DATE(engage_Date,'%Y-%m-%d')) AS DealYear,
        COUNT(*) AS TotalDeals
    FROM crm.sales_pipeline
    WHERE engage_date IS NOT NULL
    GROUP BY DealYear, DealQuarter
)
SELECT DealYear, DealQuarter, TotalDeals,
       LAG(TotalDeals) OVER (ORDER BY DealYear, DealQuarter) AS PrevQuarterDeals,
       (TotalDeals - LAG(TotalDeals) OVER (ORDER BY DealYear, DealQuarter)) AS QoQChange
FROM deals;


# Q12. Conversion rate by product (Won ÷ Engaged)?

WITH product_stats AS (
    SELECT product,
           SUM(CASE WHEN deal_stage = 'Won' THEN 1 ELSE 0 END) AS WonDeals,
           COUNT(*) AS EngagedDeals
    FROM crm.sales_pipeline
    WHERE deal_stage IN ('Engaging','Won','Lost')
    GROUP BY product
)
SELECT product,
       round((WonDeals * 100.0 / EngagedDeals),2) AS ConversionRatePct
FROM product_stats
ORDER BY ConversionRatePct DESC;


# Q13. Sales agents handling the widest variety of products ?

SELECT sales_agent,
       COUNT(DISTINCT product) AS UniqueProducts
FROM crm.sales_pipeline
GROUP BY sales_agent
ORDER BY UniqueProducts DESC;


# Q14. Find the top 5 industries contributing the highest total account revenue ?

SELECT sector, 
       SUM(CAST(revenue AS DECIMAL(15,2))) AS TotalSectorRevenue
FROM crm.accounts
GROUP BY sector
ORDER BY TotalSectorRevenue DESC
LIMIT 5;


# Q15. Rolling 3-month average of engaged deals ?

WITH monthly_deals AS (
    SELECT DATE_FORMAT(STR_TO_DATE(engage_date,'%Y-%m-%d'),'%Y-%m') AS Month,
           COUNT(*) AS DealCount
    FROM crm.sales_pipeline
    WHERE engage_date IS NOT NULL
    GROUP BY DATE_FORMAT(STR_TO_DATE(engage_date,'%Y-%m-%d'),'%Y-%m')
)
SELECT Month, DealCount,
       AVG(DealCount) OVER (ORDER BY Month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Rolling3MoAvg
FROM monthly_deals;
