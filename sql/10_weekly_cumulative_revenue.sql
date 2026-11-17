-- Query 10: Revenue by week from May to July 2017 and cumulative revenue
-- Fields: date, hits.product.productRevenue
-- Week starts on Monday (%W)
-- Step 1: Revenue per week
-- Step 2: Cumulative revenue = sum of the revenue of all weeks up to the current week (self join on week)

WITH totals_week AS (
  SELECT
    FORMAT_DATE('%Y-%W', PARSE_DATE('%Y%m%d', date)) AS week
    , SUM(p.productRevenue) AS sum_week_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS h,
    UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '0501' AND '0731'
    AND p.productRevenue IS NOT NULL
  GROUP BY 1
  ORDER BY 2
)

SELECT
  a.week
  , FORMAT("%'.2f", a.sum_week_revenue * 1.0) AS weekly_revenue
  , FORMAT("%'.2f", SUM(b.sum_week_revenue) * 1.0) AS cumulative_revenue
FROM totals_week AS a
JOIN totals_week AS b
  ON b.week <= a.week
GROUP BY 1, 2
ORDER BY 1;
