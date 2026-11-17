-- Query 09: Cohort map from product view to add-to-cart to purchase in Jan, Feb and Mar 2017
-- Example: 100% product view, then 40% add_to_cart and 10% purchase
-- Add_to_cart_rate = number of products added to cart / number of product views
-- Purchase_rate = number of products purchased / number of product views
-- Calculated at product level
-- action_type: '2' = product view, '3' = add to cart, '6' = purchase
-- Step 1: Count products with action_type = '2'
-- Step 2: Count products with action_type = '3'
-- Step 3: Count products with action_type = '6' and productRevenue IS NOT NULL
-- Step 4: Calculate the rates

WITH amount_product_view AS (
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date)) AS month_2017
    , COUNT(p.v2ProductName) AS count_product_view
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
    AND h.eCommerceAction.action_type = '2'
  GROUP BY 1
),

amount_add_to_cart AS (
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date)) AS month_2017
    , COUNT(p.v2ProductName) AS count_add_to_cart
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
    AND h.eCommerceAction.action_type = '3'
  GROUP BY 1
),

amount_purchase AS (
  SELECT
    EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', date)) AS month_2017
    , COUNT(p.v2ProductName) AS count_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
    AND h.eCommerceAction.action_type = '6'
    AND p.productRevenue IS NOT NULL
  GROUP BY 1
)

SELECT
  a.month_2017
  , count_product_view AS num_product_view
  , count_add_to_cart AS num_addtocart
  , count_purchase AS num_purchase
  , ROUND(count_add_to_cart * 100.0 / count_product_view, 2) || '%' AS add_to_cart_rate
  , ROUND(count_purchase * 100.0 / count_product_view, 2) || '%' AS purchase_rate
FROM amount_product_view AS a
LEFT JOIN amount_add_to_cart AS b
  ON a.month_2017 = b.month_2017
LEFT JOIN amount_purchase AS c
  ON b.month_2017 = c.month_2017
ORDER BY 1;
