-- Retention: % of new users active on day 1 / 7 / 14 / 30 after install, by weekly cohort and platform.
-- Each day-N rate only counts users who installed at least N days before the data ends.
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
user_ret AS (
  SELECT n.user_id, n.install_date, n.platform,
    LOGICAL_OR(DATE_DIFF(a.date, n.install_date, DAY) = 1)  AS d1,
    LOGICAL_OR(DATE_DIFF(a.date, n.install_date, DAY) = 7)  AS d7,
    LOGICAL_OR(DATE_DIFF(a.date, n.install_date, DAY) = 14) AS d14,
    LOGICAL_OR(DATE_DIFF(a.date, n.install_date, DAY) = 30) AS d30
  FROM new_users n LEFT JOIN active_days a USING (user_id)
  GROUP BY 1, 2, 3
)
SELECT
  DATE_TRUNC(install_date, WEEK(MONDAY)) AS cohort_week,
  platform,
  COUNT(*)                                AS new_users,
  ROUND(AVG(IF(install_date <= DATE_SUB(DATE '2018-10-03', INTERVAL 1 DAY),  IF(d1,  1, 0), NULL)), 3) AS d1_retention,
  ROUND(AVG(IF(install_date <= DATE_SUB(DATE '2018-10-03', INTERVAL 7 DAY),  IF(d7,  1, 0), NULL)), 3) AS d7_retention,
  ROUND(AVG(IF(install_date <= DATE_SUB(DATE '2018-10-03', INTERVAL 14 DAY), IF(d14, 1, 0), NULL)), 3) AS d14_retention,
  ROUND(AVG(IF(install_date <= DATE_SUB(DATE '2018-10-03', INTERVAL 30 DAY), IF(d30, 1, 0), NULL)), 3) AS d30_retention
FROM user_ret
GROUP BY 1, 2
ORDER BY 1, 2;
