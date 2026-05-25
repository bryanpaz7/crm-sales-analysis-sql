/* =========================================================
   CRM SALES PIPELINE ANALYSIS PROJECT
   Author: Bryan Paz
   Tools Used: MySQL
========================================================= */


/* =========================================================
   OBJECTIVE 1 — SALES PIPELINE ANALYSIS
========================================================= */

-- 1. Calculate the number of sales opportunities created each month
-- using engage_date, and identify the month with the most opportunities.

SELECT
    DATE_FORMAT(engage_date, '%Y-%m') AS engage_month,
    COUNT(opportunity_id) AS total_opportunities
FROM sales_pipeline
WHERE engage_date IS NOT NULL
GROUP BY DATE_FORMAT(engage_date, '%Y-%m')
ORDER BY total_opportunities DESC;


-- 2. Find the average time deals stayed open
-- from engage_date to close_date, and compare closed deals versus won deals.

SELECT
    deal_stage,
    ROUND(AVG(DATEDIFF(close_date, engage_date)), 2) AS avg_days_open
FROM sales_pipeline
WHERE engage_date IS NOT NULL
    AND close_date IS NOT NULL
    AND deal_stage IN ('Won', 'Lost')
GROUP BY deal_stage;


-- 3. Calculate the percentage of deals in each stage,
-- and determine what share were lost.

SELECT
    deal_stage,
    COUNT(*) AS total_deals,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS stage_percentage
FROM sales_pipeline
GROUP BY deal_stage
ORDER BY stage_percentage DESC;


-- 4. Compute the win rate for each product,
-- and identify which one had the highest win rate.

SELECT
    product,
    COUNT(*) AS total_deals,
    SUM(
        CASE
            WHEN deal_stage = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_deals,
    ROUND(
        SUM(
            CASE
                WHEN deal_stage = 'Won' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS win_rate
FROM sales_pipeline
GROUP BY product
ORDER BY win_rate DESC;


/* =========================================================
   OBJECTIVE 2 — SALES AGENT PERFORMANCE
========================================================= */

-- 5. Calculate the win rate for each sales agent,
-- and find the top performer.

SELECT
    sales_agent,
    COUNT(*) AS total_deals,
    SUM(
        CASE
            WHEN deal_stage = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_deals,
    ROUND(
        SUM(
            CASE
                WHEN deal_stage = 'Won' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS win_rate
FROM sales_pipeline
GROUP BY sales_agent
ORDER BY win_rate DESC;


-- 6. Calculate the total revenue by agent,
-- and see who generated the most revenue.

SELECT
    sales_agent,
    ROUND(SUM(close_value), 2) AS total_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY sales_agent
ORDER BY total_revenue DESC;


-- 7. Calculate win rates by manager
-- to determine which manager’s team performed best.

SELECT
    st.manager,
    COUNT(sp.opportunity_id) AS total_deals,
    SUM(
        CASE
            WHEN sp.deal_stage = 'Won' THEN 1
            ELSE 0
        END
    ) AS won_deals,
    ROUND(
        SUM(
            CASE
                WHEN sp.deal_stage = 'Won' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(sp.opportunity_id),
        2
    ) AS win_rate
FROM sales_pipeline AS sp
JOIN sales_teams AS st
    ON sp.sales_agent = st.sales_agent
GROUP BY st.manager
ORDER BY win_rate DESC;


-- 8. For the product GTX Plus Pro,
-- find which regional office sold the most units.

SELECT
    st.regional_office,
    COUNT(sp.opportunity_id) AS units_sold
FROM sales_pipeline AS sp
JOIN sales_teams AS st
    ON sp.sales_agent = st.sales_agent
WHERE sp.product = 'GTX Plus Pro'
    AND sp.deal_stage = 'Won'
GROUP BY st.regional_office
ORDER BY units_sold DESC;


/* =========================================================
   OBJECTIVE 3 — PRODUCT ANALYSIS
========================================================= */

-- 9. For March deals, identify the top product by revenue.

SELECT
    product,
    ROUND(SUM(close_value), 2) AS total_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
    AND MONTH(close_date) = 3
GROUP BY product
ORDER BY total_revenue DESC;


-- 10. For March deals, identify the top product by units sold.

SELECT
    product,
    COUNT(opportunity_id) AS units_sold
FROM sales_pipeline
WHERE deal_stage = 'Won'
    AND MONTH(close_date) = 3
GROUP BY product
ORDER BY units_sold DESC;


-- 11. Calculate the average difference between sales_price
-- and close_value for each product.
-- NOTE:
-- This query assumes a product_catalog table exists
-- containing product and sales_price columns.

SELECT
    sp.product,
    ROUND(
        AVG(pc.sales_price - sp.close_value),
        2
    ) AS avg_price_difference
FROM sales_pipeline AS sp
JOIN product_catalog AS pc
    ON sp.product = pc.product
WHERE sp.deal_stage = 'Won'
GROUP BY sp.product
ORDER BY avg_price_difference DESC;


-- 12. Calculate total revenue by product series
-- and compare their performance.

SELECT
    CASE
        WHEN product LIKE 'GTX%' THEN 'GTX Series'
        WHEN product LIKE 'MG%' THEN 'MG Series'
        WHEN product LIKE 'GTK%' THEN 'GTK Series'
        ELSE 'Other'
    END AS product_series,
    ROUND(SUM(close_value), 2) AS total_revenue
FROM sales_pipeline
WHERE deal_stage = 'Won'
GROUP BY product_series
ORDER BY total_revenue DESC;


/* =========================================================
   OBJECTIVE 4 — ACCOUNT ANALYSIS
========================================================= */

-- 13. Calculate revenue by office location,
-- and identify the lowest performer.

SELECT
    a.office_location,
    ROUND(SUM(sp.close_value), 2) AS total_revenue
FROM sales_pipeline AS sp
JOIN accounts AS a
    ON sp.account = a.account
WHERE sp.deal_stage = 'Won'
GROUP BY a.office_location
ORDER BY total_revenue ASC;


-- 14. Find the gap in years between the oldest
-- and newest customer, and name those companies.

SELECT
    oldest.account AS oldest_customer,
    oldest.year_established AS oldest_year,
    newest.account AS newest_customer,
    newest.year_established AS newest_year,
    newest.year_established - oldest.year_established AS year_gap
FROM accounts AS oldest
JOIN accounts AS newest
WHERE oldest.year_established = (
        SELECT MIN(year_established)
        FROM accounts
    )
    AND newest.year_established = (
        SELECT MAX(year_established)
        FROM accounts
    );


-- 15. Which subsidiary accounts had the most
-- lost sales opportunities?

SELECT
    a.account,
    a.subsidiary_of,
    COUNT(sp.opportunity_id) AS lost_opportunities
FROM accounts AS a
JOIN sales_pipeline AS sp
    ON a.account = sp.account
WHERE a.subsidiary_of IS NOT NULL
    AND sp.deal_stage = 'Lost'
GROUP BY a.account, a.subsidiary_of
ORDER BY lost_opportunities DESC;


-- 16. Join companies to their subsidiaries.
-- Determine which parent company generated
-- the highest total revenue.

SELECT
    parent.account AS parent_company,
    COUNT(DISTINCT child.account) AS total_subsidiaries,
    ROUND(SUM(sp.close_value), 2) AS total_revenue
FROM accounts AS child
JOIN accounts AS parent
    ON child.subsidiary_of = parent.account
JOIN sales_pipeline AS sp
    ON child.account = sp.account
WHERE sp.deal_stage = 'Won'
GROUP BY parent.account
ORDER BY total_revenue DESC;
