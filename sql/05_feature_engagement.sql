-- Feature engagement: share of new users who use each feature on install day,
-- and their day 7-13 return rate vs. users who did not. (Correlation, not causation.)
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
day0 AS (
  SELECT n.user_id,
    LOGICAL_OR(e.event_name = 'level_start')            AS progressive_mode,
    LOGICAL_OR(e.event_name = 'level_start_quickplay')  AS quickplay_mode,
    LOGICAL_OR(e.event_name = 'use_extra_steps')        AS extra_steps_powerup,
    LOGICAL_OR(e.event_name = 'ad_reward')              AS watched_reward_ad,
    LOGICAL_OR(e.event_name = 'challenge_a_friend')     AS challenged_friend,
    LOGICAL_OR(e.event_name = 'completed_5_levels')     AS completed_5_levels
  FROM new_users n JOIN events e USING (user_id)
  WHERE e.date = n.install_date AND n.install_date <= DATE '2018-09-20'
  GROUP BY 1
),
ret AS (
  SELECT n.user_id, LOGICAL_OR(DATE_DIFF(a.date, n.install_date, DAY) BETWEEN 7 AND 13) AS returned_wk2
  FROM new_users n LEFT JOIN active_days a USING (user_id)
  GROUP BY 1
),
long AS (
  SELECT feature, used, returned_wk2
  FROM day0 JOIN ret USING (user_id),
  UNNEST([
    STRUCT('Progressive mode' AS feature, progressive_mode AS used),
    ('Quick-play mode', quickplay_mode),
    ('Extra-steps power-up', extra_steps_powerup),
    ('Rewarded ad', watched_reward_ad),
    ('Challenge a friend', challenged_friend),
    ('Completed 5 levels', completed_5_levels)
  ])
)
SELECT
  feature,
  ROUND(AVG(IF(used, 1, 0)), 3)                              AS adoption_day0,
  COUNTIF(used)                                              AS users_used,
  ROUND(AVG(IF(used,     IF(returned_wk2, 1, 0), NULL)), 3)  AS week2_return_if_used,
  ROUND(AVG(IF(NOT used, IF(returned_wk2, 1, 0), NULL)), 3)  AS week2_return_if_not
FROM long
GROUP BY feature
ORDER BY adoption_day0 DESC;
