![E-commerce Analysis with SQL](docs/images/banner.png)

# E-commerce Analysis with SQL

This project uses SQL on Google BigQuery to analyze Google Analytics data from the Google Merchandise Store, an online store selling Google-branded products. The data is a public sample covering August 2016 to August 2017.

The project answers 10 questions about traffic, traffic sources, purchasing behavior and revenue.

**Tool:** Google BigQuery (GoogleSQL)

**SQL techniques:** CTEs, `UNNEST` on nested data, wildcard tables with `_TABLE_SUFFIX`, `JOIN`, `UNION ALL`, date handling with `PARSE_DATE` / `FORMAT_DATE`

## Questions

| # | Question | SQL file |
|---|---|---|
| 1 | Monthly visits, pageviews and transactions (Q1 2017) | [01_monthly_traffic_overview.sql](sql/01_monthly_traffic_overview.sql) |
| 2 | Bounce rate by traffic source (July 2017) | [02_bounce_rate_by_source.sql](sql/02_bounce_rate_by_source.sql) |
| 3 | Revenue by traffic source, by week and by month (June 2017) | [03_revenue_by_source_week_month.sql](sql/03_revenue_by_source_week_month.sql) |
| 4 | Conversion rate by traffic source (2017) | [04_conversion_rate_by_source.sql](sql/04_conversion_rate_by_source.sql) |
| 5 | Average pageviews: purchasers vs non-purchasers (June–July 2017) | [05_pageviews_by_purchaser_type.sql](sql/05_pageviews_by_purchaser_type.sql) |
| 6 | Average transactions per purchaser (July 2017) | [06_transactions_per_purchaser.sql](sql/06_transactions_per_purchaser.sql) |
| 7 | Revenue share by device (2017) | [07_revenue_share_by_device.sql](sql/07_revenue_share_by_device.sql) |
| 8 | Other products bought by customers who bought “YouTube Men's Vintage Henley” (July 2017) | [08_cross_sell_vintage_henley.sql](sql/08_cross_sell_vintage_henley.sql) |
| 9 | Product funnel: view → add to cart → purchase (Q1 2017) | [09_product_funnel.sql](sql/09_product_funnel.sql) |
| 10 | Weekly revenue and cumulative revenue (May–July 2017) | [10_weekly_cumulative_revenue.sql](sql/10_weekly_cumulative_revenue.sql) |

## Data

**Table:** `bigquery-public-data.google_analytics_sample.ga_sessions_YYYYMMDD`. One table per day, from 01/08/2016 to 01/08/2017.

**Each row is one session:** one visit, from the moment a visitor lands on the website until they leave.

For example, a visitor comes to the store and:

1. Opens the home page
2. Opens the YouTube Men's Vintage Henley product page
3. Clicks "Add to cart"
4. Checks out, buying the Henley and a pair of Google Sunglasses

This whole visit is stored in **one row**, split into three main parts:

| Part | Data type | What it stores | Example from the visit above |
|---|---|---|---|
| `totals` | STRUCT (one group of values) | Totals for the whole session | `visits` = 1, `pageviews` = 3, `transactions` = 1 |
| `hits` | ARRAY of STRUCT (a list) | Each action of the visitor, one hit per action | `type` = PAGE (opens a page) or EVENT (clicks a button); `eCommerceAction.action_type` = 2 (product view), 3 (add to cart), 6 (purchase) |
| `hits.product` | ARRAY of STRUCT, inside each hit | Products linked to that action | `v2ProductName` = YouTube Men's Vintage Henley, `productQuantity` = 1, `productRevenue` = 29990000 |

A few things to know when reading the data:

- A STRUCT is read with a dot, for example `totals.pageviews`. An ARRAY is a list, so it has to be unnested first, for example `UNNEST(hits)` then `UNNEST(h.product)`. (In the BigQuery Schema tab, a STRUCT is shown as RECORD and an ARRAY as RECORD with mode REPEATED.)
- `productRevenue` only has a value when the product is purchased. At the view or add-to-cart step it is NULL.
- Money columns are stored multiplied by 1,000,000. For example, 29990000 means 29.99 USD.

```
ga_sessions_YYYYMMDD          1 row = 1 session
├── fullVisitorId, date
├── totals          STRUCT    visits, pageviews, transactions
├── trafficSource   STRUCT    source, medium
├── device          STRUCT    deviceCategory
└── hits            ARRAY     1 item = 1 action
    ├── type, page.pagePath
    ├── eCommerceAction       action_type 2 / 3 / 6
    └── product     ARRAY     1 item = 1 product
        └── v2ProductName, productQuantity, productRevenue
```

Full column reference: [BigQuery Export schema](https://support.google.com/analytics/answer/3437719?hl=en)

## How to access the data

1. Open [the dataset in BigQuery](https://console.cloud.google.com/bigquery?p=bigquery-public-data&d=google_analytics_sample&page=dataset) and sign in with a Google account.
2. If asked, create a new project. BigQuery Sandbox is free and does not need a credit card.
3. In the **Explorer** panel, search for `ga_sessions` and select the dataset.
4. Select the table to see its columns in the **Schema** tab and sample rows in the **Preview** tab.
5. To run a query, open a new query tab, paste a file from the [`sql/`](sql/) folder and click **Run**.

A quick query to look at one day of data:

```sql
SELECT
  date,
  fullVisitorId,
  totals.visits,
  totals.pageviews,
  trafficSource.source,
  device.deviceCategory
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_20170801`
LIMIT 10;
```

Notes when writing queries:

- Use `ga_sessions_2017*` with `_TABLE_SUFFIX` to pick a date range, for example `WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'`.
- BigQuery charges by the amount of data read, so select only the columns you need instead of `SELECT *`.

## Analysis

### 1. Monthly visits, pageviews and transactions (Q1 2017)

**Problem:** Get an overview of the website in the first three months of 2017: how many visits, pageviews and transactions each month.

**Expected output:** One row per month with `month`, `visits`, `pageviews`, `transactions`, ordered by month.

**Solution:** All three metrics are already stored in `totals` for each session, so no `UNNEST` is needed. The month comes from the `date` column, `_TABLE_SUFFIX` limits the scan to the tables from 01/01 to 31/03, and the values are summed by month.

<details>
<summary>View SQL</summary>

```sql
SELECT
  FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
  SUM(totals.visits) AS visits,
  SUM(totals.pageviews) AS pageviews,
  SUM(totals.transactions) AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
WHERE _TABLE_SUFFIX BETWEEN '0101' AND '0331'
GROUP BY 1
ORDER BY 1;
```

</details>

### 2. Bounce rate by traffic source (July 2017)

**Problem:** Find which traffic sources bring visitors who leave right after landing.

**Expected output:** One row per source with `source`, `amount_visits`, `amount_bounces`, `bounce_rates`, ordered by visits descending.

**Solution:** Bounce rate = total bounces / total visits × 100. `totals.bounces` is NULL when the visitor did not bounce, so `COALESCE` turns it into 0 before summing. The rate is kept as a number without a `%` sign.

<details>
<summary>View SQL</summary>

```sql
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
```

</details>

### 3. Revenue by traffic source, by week and by month (June 2017)

**Problem:** Find which sources generate revenue in June and how that revenue is spread across the weeks.

**Expected output:** One table with `time_type` (Month or Week), `month` (month or week code), `source`, `revenue`. Month rows and week rows are grouped separately.

**Solution:** Revenue sits inside `hits.product`, so `hits` and `product` are unnested and only rows with `productRevenue IS NOT NULL` are kept, divided by 1,000,000. One CTE groups by month, another by week (`%Y%W`), the two are combined with `UNION ALL`, and `ORDER BY time_type` keeps months and weeks in separate blocks.

<details>
<summary>View SQL</summary>

```sql
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
```

</details>

### 4. Conversion rate by traffic source (2017)

**Problem:** Find which sources turn visits into transactions most effectively.

**Expected output:** One row per source with `sources`, `visits`, `transactions`, `conversion_rate`, ordered by conversion rate descending.

**Solution:** Conversion rate = total transactions / total visits × 100. One visit can contain more than one transaction, so the query uses `SUM(totals.transactions)`. Only sources with at least 50 transactions are kept with `HAVING`, so very small sources do not distort the ranking.

<details>
<summary>View SQL</summary>

```sql
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
```

</details>

### 5. Average pageviews: purchasers vs non-purchasers (June–July 2017)

**Problem:** Compare how many pages purchasers and non-purchasers view.

**Expected output:** One row per month with `month_2017`, `avg_pageviews_purchase`, `avg_pageviews_non_purchase`.

**Solution:** Purchasers: `totals.transactions >= 1` and `productRevenue IS NOT NULL`. Non-purchasers: `totals.transactions IS NULL` and `productRevenue IS NULL`. Each group has its own CTE that divides total pageviews by the number of unique visitors (`COUNT(DISTINCT fullVisitorId)`) per month, then the two groups are joined by month.

<details>
<summary>View SQL</summary>

```sql
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
```

</details>

### 6. Average transactions per purchaser (July 2017)

**Problem:** Find how many transactions a purchasing visitor makes on average in a month.

**Expected output:** One row with `month_2017` and `avg_total_transactions_per_user`.

**Solution:** Purchasers are filtered with the same condition as in question 5, then total transactions are divided by the number of unique visitors.

<details>
<summary>View SQL</summary>

```sql
SELECT
  FORMAT_DATE('%G %B', PARSE_DATE('%Y%m%d', date)) AS month_2017
  , SUM(totals.transactions) / COUNT(DISTINCT fullVisitorId) AS avg_total_transactions_per_user
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
  UNNEST(hits) AS h,
  UNNEST(h.product) AS p
WHERE _TABLE_SUFFIX BETWEEN '0701' AND '0731'
  AND totals.transactions >= 1
  AND p.productRevenue IS NOT NULL
GROUP BY 1;
```

</details>

### 7. Revenue share by device (2017)

**Problem:** Find how revenue is split between desktop, mobile and tablet.

**Expected output:** One row per device with `device`, `revenue_by_device`, `total_revenue`, `ratio`, ordered by share descending.

**Solution:** Three steps: total revenue for the year, revenue per device, then join the two by year and divide device revenue by total revenue.

<details>
<summary>View SQL</summary>

```sql
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
```

</details>

### 8. Other products bought by customers who bought “YouTube Men's Vintage Henley” (July 2017)

**Problem:** Find what else customers buy when they buy the YouTube Men's Vintage Henley, as a starting point for product recommendations.

**Expected output:** One row per product with `other_purchased_products` and `quantity`, ordered by quantity descending.

**Solution:** Step 1: list the customers who bought the Henley, using `DISTINCT` because one customer can buy it more than once. Step 2: join this list with all July purchases to get the other products they bought, excluding the Henley. Step 3: sum the quantity per product.

<details>
<summary>View SQL</summary>

```sql
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
```

</details>

### 9. Product funnel: view → add to cart → purchase (Q1 2017)

**Problem:** Out of all product views, find the share that is added to cart and the share that is purchased. For example: 100% view, 40% add to cart, 10% purchase.

**Expected output:** One row per month with `month_2017`, `num_product_view`, `num_addtocart`, `num_purchase`, `add_to_cart_rate`, `purchase_rate`.

**Solution:** Counted at product level using `eCommerceAction.action_type`: `'2'` is a product view, `'3'` is add to cart, `'6'` is a purchase (with `productRevenue IS NOT NULL`). Each step has its own CTE counting products by month, then the three CTEs are joined by month and both rates are calculated against product views.

<details>
<summary>View SQL</summary>

```sql
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
```

</details>

### 10. Weekly revenue and cumulative revenue (May–July 2017)

**Problem:** Track revenue per week and the running total up to each week.

**Expected output:** One row per week with `week`, `weekly_revenue`, `cumulative_revenue`, ordered by week.

**Solution:** Weekly revenue is calculated in a CTE, with weeks starting on Monday (`%Y-%W`). Cumulative revenue comes from joining the weekly table to itself on earlier week ≤ current week and summing.

<details>
<summary>View SQL</summary>

```sql
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
```

</details>

## Contact

Nguyễn Hoàng Khải · khaihoang09052@gmail.com · [GitHub](https://github.com/khaihoang09052-katjai)
