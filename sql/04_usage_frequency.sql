-- Usage frequency: days active in a user's first week, and how that relates to day-30 retention.
-- Cohort: users who installed by 2018-09-03 (so every user has 30 days of follow-up).
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
per_user AS (
  SELECT n.user_id,
    COUNT(DISTINCT IF(DATE_DIFF(a.date, n.install_date, DAY) BETWEEN 0 AND 6, a.date, NULL)) AS active_days_wk1,
    LOGICAL_OR(DATE_DIFF(a.date, n.install_date, DAY) BETWEEN 28 AND 34)                      AS active_wk5
  FROM new_users n LEFT JOIN active_days a USING (user_id)
  WHERE n.install_date <= DATE '2018-08-30'
  GROUP BY 1
),
sessions AS (
  SELECT n.user_id, COUNT(*) AS sessions_wk1
  FROM new_users n JOIN events e USING (user_id)
  WHERE e.event_name = 'session_start' AND DATE_DIFF(e.date, n.install_date, DAY) BETWEEN 0 AND 6
  GROUP BY 1
)
SELECT
  CASE WHEN active_days_wk1 <= 1 THEN '1 day'
       WHEN active_days_wk1 = 2  THEN '2 days'
       WHEN active_days_wk1 <= 4 THEN '3-4 days'
       ELSE '5-7 days' END                       AS days_active_first_week,
  COUNT(*)                                       AS users,
  ROUND(AVG(IFNULL(s.sessions_wk1, 0)), 1)       AS avg_sessions_first_week,
  ROUND(AVG(IF(active_wk5, 1, 0)), 3)            AS active_in_week_5
FROM per_user LEFT JOIN sessions s USING (user_id)
GROUP BY 1
ORDER BY 1;
