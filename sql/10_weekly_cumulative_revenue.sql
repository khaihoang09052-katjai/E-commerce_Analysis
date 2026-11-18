-- Query 10: Revenue by week from May to July 2017 and cumulative revenue
-- Fields: date, hits.product.productRevenue
-- Revenue is stored x 1,000,000, so divide by 1,000,000 to get USD
-- Week starts on Monday (%W)
-- Step 1: Revenue per week
-- Step 2: Cumulative revenue = sum of the revenue of all weeks up to the current week (self join on week)

WITH totals_week AS (
  SELECT
    FORMAT_DATE('%Y-%W', PARSE_DATE('%Y%m%d', date)) AS week
    , SUM(p.productRevenue) / 1000000 AS sum_week_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '0501' AND '0731'
    AND p.productRevenue IS NOT NULL
  GROUP BY 1
)

SELECT
  a.week
  , ROUND(a.sum_week_revenue, 2) AS weekly_revenue
  , ROUND(SUM(b.sum_week_revenue), 2) AS cumulative_revenue
FROM totals_week AS a
JOIN totals_week AS b
  ON b.week <= a.week
GROUP BY a.week, a.sum_week_revenue
ORDER BY 1;
