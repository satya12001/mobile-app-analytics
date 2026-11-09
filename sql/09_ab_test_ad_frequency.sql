-- A/B test: Firebase experiment firebase_exp_1 (Remote Config parameter ad_frequency).
-- Variant 0 = baseline (Firebase convention). Mapping verified in the data:
--   0 -> ad every 4 games, 1 -> every 2, 2 -> every 8, 3 -> every 16.
-- Outcome: returned on days 1-7 after first exposure; engagement minutes in those 7 days.
-- Users exposed after 2018-09-26 are excluded so everyone has 7 days of follow-up.
-- Analysis window: 2018-07-02 to 2018-10-03 (see 00_data_audit.sql)
-- "Active" = Firebase user_engagement event (same definition Firebase uses for active users).
WITH events AS (
  SELECT
    user_pseudo_id                              AS user_id,
    PARSE_DATE('%Y%m%d', event_date)            AS date,
    event_name,
    platform,
    traffic_source.source                       AS source,
    traffic_source.medium                       AS medium,
    event_params
  FROM `firebase-public-project.analytics_153293282.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181003'
),
new_users AS (            -- one row per user who installed inside the window
  SELECT user_id, MIN(date) AS install_date,
         ANY_VALUE(platform) AS platform,
         ANY_VALUE(source) AS source, ANY_VALUE(medium) AS medium
  FROM events WHERE event_name = 'first_open'
  GROUP BY user_id
),
active_days AS (
  SELECT DISTINCT user_id, date FROM events WHERE event_name = 'user_engagement'
),
exposure AS (
  SELECT user_pseudo_id AS user_id,
         MIN(PARSE_DATE('%Y%m%d', event_date)) AS exposed_date,
         ANY_VALUE(up.value.string_value)      AS variant
  FROM `firebase-public-project.analytics_153293282.events_*`, UNNEST(user_properties) up
  WHERE _TABLE_SUFFIX BETWEEN '20180702' AND '20181003' AND up.key = 'firebase_exp_1'
  GROUP BY 1
),
engagement AS (
  SELECT x.user_id,
    SUM((SELECT p.value.int_value FROM UNNEST(e.event_params) p WHERE p.key = 'engagement_time_msec')) / 60000 AS minutes_7d
  FROM exposure x JOIN events e USING (user_id)
  WHERE e.event_name = 'user_engagement' AND DATE_DIFF(e.date, x.exposed_date, DAY) BETWEEN 0 AND 6
  GROUP BY 1
),
ret AS (
  SELECT x.user_id, LOGICAL_OR(DATE_DIFF(a.date, x.exposed_date, DAY) BETWEEN 1 AND 7) AS returned
  FROM exposure x LEFT JOIN active_days a USING (user_id)
  GROUP BY 1
)
SELECT
  x.variant,
  CASE x.variant WHEN '0' THEN 'Baseline: ad every 4 games' WHEN '1' THEN 'Ad every 2 games'
                 WHEN '2' THEN 'Ad every 8 games' WHEN '3' THEN 'Ad every 16 games' END AS arm,
  COUNT(*)                                       AS users,
  COUNTIF(r.returned)                            AS returned_7d,
  ROUND(AVG(IFNULL(g.minutes_7d, 0)), 2)         AS avg_minutes_7d,
  ROUND(STDDEV(IFNULL(g.minutes_7d, 0)), 2)      AS sd_minutes_7d
FROM exposure x
JOIN ret r USING (user_id)
LEFT JOIN engagement g USING (user_id)
WHERE x.exposed_date <= DATE '2018-09-26'
GROUP BY 1, 2
ORDER BY 1;
