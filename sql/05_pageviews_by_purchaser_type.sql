-- Query 05: Average pageviews by purchaser type (purchasers vs non-purchasers) in June and July 2017
-- Average pageviews = total pageviews / number of unique users
-- Purchasers: totals.transactions >= 1 AND hits.product.productRevenue IS NOT NULL
-- Non-purchasers: totals.transactions IS NULL AND hits.product.productRevenue IS NULL
-- Step 1: Average pageviews of purchasers by month
-- Step 2: Average pageviews of non-purchasers by month
-- Step 3: Join both results by month

WITH pageviews_purchase AS (
  SELECT
    FORMAT_DATE('%G %B', PARSE_DATE('%Y%m%d', date)) AS month_2017
    , SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'
    AND totals.transactions >= 1
    AND p.productRevenue IS NOT NULL
  GROUP BY 1
),

non_pageviews_purchase AS (
  SELECT
    FORMAT_DATE('%G %B', PARSE_DATE('%Y%m%d', date)) AS month_2017
    , SUM(totals.pageviews) / COUNT(DISTINCT fullVisitorId) AS avg_pageviews_non_purchase
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '0601' AND '0731'
    AND totals.transactions IS NULL
    AND p.productRevenue IS NULL
  GROUP BY 1
)

SELECT
  a.month_2017
  , a.avg_pageviews_purchase
  , b.avg_pageviews_non_purchase
FROM pageviews_purchase AS a
LEFT JOIN non_pageviews_purchase AS b
  ON a.month_2017 = b.month_2017
ORDER BY 2, 3;
