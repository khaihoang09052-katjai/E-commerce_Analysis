-- Query 07: Revenue contribution by device (desktop, mobile, tablet) in 2017 (order by ratio DESC)
-- Fields: device.deviceCategory, hits.product.productRevenue
-- Step 1: Total revenue in 2017
-- Step 2: Revenue per device in 2017
-- Step 3: Ratio = revenue per device / total revenue

WITH revenue_2017 AS (
  SELECT
    EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', date)) AS year
    , SUM(p.productRevenue) AS totals_2017
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '1231'
  GROUP BY 1
),

revenue_per_device_2017 AS (
  SELECT
    EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', date)) AS year
    , device.deviceCategory AS deviceCategory
    , SUM(p.productRevenue) AS totals_per_device_2017
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '1231'
  GROUP BY 1, 2
)

SELECT
  deviceCategory AS device
  , FORMAT("%'.2f", totals_per_device_2017 * 1.0) AS revenue_by_device
  , FORMAT("%'.2f", totals_2017 * 1.0) AS total_revenue
  , ROUND(totals_per_device_2017 * 100.0 / totals_2017, 2) || '%' AS ratio
FROM revenue_per_device_2017 AS a
LEFT JOIN revenue_2017 AS b
  ON a.year = b.year
ORDER BY 4 DESC;
