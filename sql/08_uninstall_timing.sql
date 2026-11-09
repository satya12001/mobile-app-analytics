-- Disengagement: how soon after install do Android users uninstall? (app_remove is Android-only in Firebase.)
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
removes AS (SELECT user_id, MIN(date) AS remove_date FROM events WHERE event_name = 'app_remove' GROUP BY user_id)
SELECT
  CASE WHEN d = 0 THEN 'Day 0' WHEN d = 1 THEN 'Day 1' WHEN d <= 6 THEN 'Days 2-6'
       WHEN d <= 13 THEN 'Week 2' WHEN d <= 29 THEN 'Weeks 3-4' ELSE 'Day 30+' END AS uninstalled,
  COUNT(*) AS users,
  ROUND(COUNT(*) / (SELECT COUNT(*) FROM new_users WHERE platform = 'ANDROID'), 3) AS pct_of_installs
FROM (SELECT DATE_DIFF(r.remove_date, n.install_date, DAY) AS d
      FROM new_users n JOIN removes r USING (user_id)
      WHERE r.remove_date >= n.install_date AND n.platform = 'ANDROID')
GROUP BY 1
ORDER BY MIN(d);
