-- Query 06: Average number of transactions per user that made a purchase in July 2017
-- Average transactions = total transactions / number of unique users
-- Fields: date, fullVisitorId, visitId, totals.transactions
-- Purchasers: totals.transactions >= 1 AND hits.product.productRevenue IS NOT NULL
-- Note: same as Query 05, purchase sessions are de-duplicated first so transactions are not counted many times
-- Step 1: Get the list of purchase sessions (one row per session)
-- Step 2: Total transactions / number of unique users

WITH purchase_sessions AS (
  SELECT DISTINCT
    date
    , fullVisitorId
    , visitId
    , totals.transactions AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '0701' AND '0731'
    AND totals.transactions >= 1
    AND p.productRevenue IS NOT NULL
)

SELECT
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month_2017
  , SUM(transactions) / COUNT(DISTINCT fullVisitorId) AS avg_total_transactions_per_user
FROM purchase_sessions
GROUP BY 1;
