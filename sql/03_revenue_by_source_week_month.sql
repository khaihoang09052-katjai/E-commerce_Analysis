-- Query 03: Revenue by traffic source by week and by month in June 2017
-- Fields: date, trafficSource.source, hits.product.productRevenue
-- Step 1: Revenue by traffic source for the month of June
-- Step 2: Revenue by traffic source for each week in June
-- Step 3: Combine both with UNION ALL, order by time_type so months and weeks are shown in separate groups

WITH month_data AS (
  SELECT
    "Month" AS time_type,
    FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
    trafficSource.source AS source,
    SUM(p.productRevenue) / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST(hits) AS hits,
    UNNEST(product) AS p
  WHERE p.productRevenue IS NOT NULL
  GROUP BY 1, 2, 3
  ORDER BY revenue DESC
),

week_data AS (
  SELECT
    "Week" AS time_type,
    FORMAT_DATE("%Y%W", PARSE_DATE("%Y%m%d", date)) AS week,
    trafficSource.source AS source,
    SUM(p.productRevenue) / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    UNNEST(hits) AS hits,
    UNNEST(product) AS p
  WHERE p.productRevenue IS NOT NULL
  GROUP BY 1, 2, 3
  ORDER BY revenue DESC
)

SELECT * FROM month_data
UNION ALL
SELECT * FROM week_data
ORDER BY time_type;
