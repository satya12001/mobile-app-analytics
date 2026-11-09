-- Disengagement: in progressive mode, where do users stop?
-- For each level: players who started it, fail rate, and how many users never started another level after it.
-- "Stopped here" = this was the user's highest level and they had no activity in the last 14 days of data.
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
lvl AS (
  SELECT user_id, date, event_name,
    -- level number: the 'level' param is mostly empty in this export, so fall back to 'level_name' (e.g. "level_5")
    COALESCE(
      (SELECT p.value.int_value FROM UNNEST(event_params) p WHERE p.key = 'level'),
      (SELECT SAFE_CAST(REGEXP_EXTRACT(p.value.string_value, r'level_(\d+)') AS INT64)
         FROM UNNEST(event_params) p WHERE p.key = 'level_name')) AS level
  FROM events WHERE event_name IN ('level_start', 'level_fail', 'level_complete')
),
last_seen AS (SELECT user_id, MAX(date) AS last_active FROM active_days GROUP BY 1),
max_level AS (
  SELECT l.user_id, MAX(l.level) AS top_level
  FROM lvl l JOIN last_seen s USING (user_id)
  WHERE l.event_name = 'level_start' AND s.last_active < DATE_SUB(DATE '2018-10-03', INTERVAL 14 DAY)
  GROUP BY 1
)
SELECT
  l.level,
  COUNT(DISTINCT IF(l.event_name = 'level_start', l.user_id, NULL))     AS players_started,
  COUNTIF(l.event_name = 'level_start')                                AS attempts,
  ROUND(SAFE_DIVIDE(COUNTIF(l.event_name = 'level_fail'), COUNTIF(l.event_name = 'level_start')), 3) AS fail_rate,
  (SELECT COUNT(*) FROM max_level m WHERE m.top_level = l.level)        AS users_stopped_here
FROM lvl l
WHERE l.level BETWEEN 1 AND 30
GROUP BY l.level
ORDER BY l.level;
