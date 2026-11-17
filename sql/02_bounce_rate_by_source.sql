-- Query 02: Bounce rate per traffic source in July 2017 (order by total visits DESC)
-- Bounce rate = total bounces / total visits
-- Fields: trafficSource.source, totals.visits, totals.bounces
-- totals.bounces is NULL when the visit did not bounce, so replace it with 0

SELECT
  trafficSource.source AS source
  , SUM(totals.visits) AS amount_visits
  , SUM(COALESCE(totals.bounces, 0)) AS amount_bounces
  , ROUND(SUM(COALESCE(totals.bounces, 0)) * 100.0 /
      SUM(totals.visits), 3) AS bounce_rates
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
WHERE _TABLE_SUFFIX BETWEEN '01' AND '31'
GROUP BY 1
ORDER BY 2 DESC;
