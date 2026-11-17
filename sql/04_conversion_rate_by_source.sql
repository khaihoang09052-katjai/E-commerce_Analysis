-- Query 04: Conversion rate by traffic source in 2017 (order by conversion_rate DESC)
-- Conversion rate = total transactions / total visits
-- Fields: trafficSource.source, totals.visits, totals.transactions
-- Use SUM(totals.transactions) because one visit can have more than one transaction
-- Keep only sources with at least 50 transactions

WITH count_raw_data AS (
  SELECT
    trafficSource.source AS sources
    , SUM(totals.visits) AS visits
    , SUM(totals.transactions) AS transactions
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
  WHERE _TABLE_SUFFIX BETWEEN '0101' AND '1231'
  GROUP BY 1
  HAVING transactions >= 50
)

SELECT
  sources
  , visits
  , transactions
  , transactions * 100.0 / visits AS conversion_rate
FROM count_raw_data
ORDER BY 4 DESC;
