-- Active users: DAU, WAU (7-day), MAU (28-day) and stickiness (DAU/MAU).
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
calendar AS (SELECT d FROM UNNEST(GENERATE_DATE_ARRAY(DATE '2018-07-29', DATE '2018-10-03')) AS d)
SELECT
  c.d                                                                 AS date,
  COUNT(DISTINCT IF(a.date = c.d, a.user_id, NULL))                   AS dau,
  COUNT(DISTINCT IF(a.date > DATE_SUB(c.d, INTERVAL 7 DAY), a.user_id, NULL))  AS wau,
  COUNT(DISTINCT a.user_id)                                           AS mau,
  ROUND(COUNT(DISTINCT IF(a.date = c.d, a.user_id, NULL)) / COUNT(DISTINCT a.user_id), 3) AS stickiness
FROM calendar c
JOIN active_days a ON a.date BETWEEN DATE_SUB(c.d, INTERVAL 27 DAY) AND c.d
GROUP BY c.d
ORDER BY c.d;
