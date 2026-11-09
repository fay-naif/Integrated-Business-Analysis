-- Superstore analysis queries
-- Table: orders (one row per order line, loaded from data/Superstore_Clean.xlsx)
-- Written for SQLite. python/load_to_sqlite.py builds superstore.db from the Excel file and runs these queries.

-- 1. Headline KPIs
SELECT
    ROUND(SUM(sales), 2)                                   AS total_sales,
    ROUND(SUM(profit), 2)                                  AS total_profit,
    ROUND(100.0 * SUM(profit) / SUM(sales), 1)             AS profit_margin_pct,
    COUNT(DISTINCT order_id)                               AS orders,
    COUNT(DISTINCT customer_id)                            AS customers
FROM orders;

-- 2. Return rate
SELECT
    ROUND(100.0 * COUNT(DISTINCT CASE WHEN is_returned = 1 THEN order_id END)
          / COUNT(DISTINCT order_id), 1)                   AS return_rate_pct
FROM orders;

-- 3. Sales, profit and margin by year, with year-over-year sales growth
WITH yearly AS (
    SELECT order_year,
           SUM(sales)  AS sales,
           SUM(profit) AS profit
    FROM orders
    GROUP BY order_year
)
SELECT order_year,
       ROUND(sales, 0)                                     AS sales,
       ROUND(profit, 0)                                    AS profit,
       ROUND(100.0 * profit / sales, 1)                    AS margin_pct,
       ROUND(100.0 * (sales - LAG(sales) OVER (ORDER BY order_year))
             / LAG(sales) OVER (ORDER BY order_year), 1)   AS sales_yoy_pct
FROM yearly
ORDER BY order_year;

-- 4. Profit margin by discount band
SELECT discount_band,
       COUNT(*)                                            AS order_lines,
       ROUND(SUM(sales), 0)                                AS sales,
       ROUND(SUM(profit), 0)                               AS profit,
       ROUND(100.0 * SUM(profit) / SUM(sales), 1)          AS margin_pct
FROM orders
GROUP BY discount_band
ORDER BY MIN(discount);

-- 5. Order lines with a discount above 20%
SELECT COUNT(*)                                            AS deep_discount_lines,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS share_of_lines_pct,
       ROUND(100.0 * SUM(CASE WHEN profit < 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS losing_lines_pct,
       ROUND(SUM(profit), 0)                               AS total_profit
FROM orders
WHERE discount > 0.2;

-- 6. Sub-categories that lose money
SELECT category, sub_category,
       ROUND(SUM(sales), 0)                                AS sales,
       ROUND(SUM(profit), 0)                               AS profit,
       ROUND(AVG(discount) * 100, 1)                       AS avg_discount_pct
FROM orders
GROUP BY category, sub_category
HAVING SUM(profit) < 0
ORDER BY profit;

-- 7. Sales and profit by region and segment
SELECT region, segment,
       ROUND(SUM(sales), 0)                                AS sales,
       ROUND(SUM(profit), 0)                               AS profit
FROM orders
GROUP BY region, segment
ORDER BY region, sales DESC;

-- 8. Top 10 products by sales
SELECT product_name,
       ROUND(SUM(sales), 0)                                AS sales,
       ROUND(SUM(profit), 0)                               AS profit
FROM orders
GROUP BY product_name
ORDER BY SUM(sales) DESC
LIMIT 10;

-- 9. Average days to ship by ship mode
SELECT ship_mode,
       ROUND(AVG(days_to_ship), 1)                         AS avg_days_to_ship,
       COUNT(DISTINCT order_id)                            AS orders
FROM orders
GROUP BY ship_mode
ORDER BY avg_days_to_ship;

-- 10. Return rate by region and region manager
SELECT region, region_manager,
       COUNT(DISTINCT order_id)                            AS orders,
       COUNT(DISTINCT CASE WHEN is_returned = 1 THEN order_id END) AS returned_orders,
       ROUND(100.0 * COUNT(DISTINCT CASE WHEN is_returned = 1 THEN order_id END)
             / COUNT(DISTINCT order_id), 1)                AS return_rate_pct
FROM orders
GROUP BY region, region_manager
ORDER BY return_rate_pct DESC;
