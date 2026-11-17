-- Query 08: Other products purchased by customers who purchased "YouTube Men's Vintage Henley" in July 2017
-- Output: product name and the quantity ordered
-- Fields: fullVisitorId, hits.product.v2ProductName, hits.product.productQuantity
-- Purchase: totals.transactions >= 1 AND hits.product.productRevenue IS NOT NULL
-- Step 1: List customers who bought "YouTube Men's Vintage Henley" (DISTINCT, one customer can buy it more than once)
-- Step 2: Find the other products these customers bought
-- Step 3: Sum the quantity per product

WITH buyer_list AS (
  SELECT DISTINCT
    fullVisitorId
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
    AND totals.transactions >= 1
    AND product.productRevenue IS NOT NULL
)

SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`,
  UNNEST(hits) AS hits,
  UNNEST(hits.product) AS product
JOIN buyer_list USING (fullVisitorId)
WHERE product.v2ProductName != "YouTube Men's Vintage Henley"
  AND product.productRevenue IS NOT NULL
  AND totals.transactions >= 1
GROUP BY other_purchased_products
ORDER BY quantity DESC;
