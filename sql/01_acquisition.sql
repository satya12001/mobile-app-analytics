-- Downloads & acquisition: weekly installs by platform and channel, plus early uninstalls.
-- Note: Firebase only logs app_remove on Android, so uninstall counts are Android-only.
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
  DATE_TRUNC(n.install_date, WEEK(MONDAY))              AS install_week,
  n.platform,
  CASE
    WHEN n.source = 'google-play'                 THEN 'Google Play organic'
    WHEN n.medium = 'cpc'                         THEN 'Paid search'
    WHEN n.medium = 'organic'                     THEN 'Web search organic'
    WHEN n.source LIKE '%invite%' OR n.medium = 'dynamic_link' THEN 'Referral / invite'
    WHEN n.source = '(direct)' OR n.source IS NULL THEN 'Direct / unattributed'
    ELSE 'Other'
  END                                                    AS channel,
  COUNT(*)                                               AS installs,
  IF(n.platform = 'ANDROID', COUNTIF(DATE_DIFF(r.remove_date, n.install_date, DAY) BETWEEN 0 AND 6), NULL) AS uninstalled_within_7d
FROM new_users n
LEFT JOIN removes r USING (user_id)
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;
