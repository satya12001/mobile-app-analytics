-- User journey: new-user funnel from install to week-2 return. Each step requires the previous one.
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
u AS (
  SELECT n.user_id,
    LOGICAL_OR(e.date = n.install_date AND e.event_name IN ('level_start','level_start_quickplay'))       AS s1_started_game,
    LOGICAL_OR(e.date = n.install_date AND e.event_name IN ('level_complete','level_complete_quickplay')) AS s2_won_game,
    LOGICAL_OR(DATE_DIFF(e.date, n.install_date, DAY) = 1 AND e.event_name = 'user_engagement')           AS s3_returned_d1,
    LOGICAL_OR(DATE_DIFF(e.date, n.install_date, DAY) BETWEEN 2 AND 6 AND e.event_name = 'user_engagement') AS s4_returned_d2_6,
    LOGICAL_OR(DATE_DIFF(e.date, n.install_date, DAY) BETWEEN 7 AND 13 AND e.event_name = 'user_engagement') AS s5_returned_wk2
  FROM new_users n JOIN events e USING (user_id)
  WHERE n.install_date <= DATE '2018-09-20'
  GROUP BY 1
)
SELECT step, users, ROUND(users / FIRST_VALUE(users) OVER (ORDER BY step_no), 3) AS pct_of_installs
FROM (
  SELECT 0 step_no, 'Installed (first_open)' step, COUNT(*) users FROM u UNION ALL
  SELECT 1, 'Started a game on day 0', COUNTIF(s1_started_game) FROM u UNION ALL
  SELECT 2, 'Won a game on day 0', COUNTIF(s1_started_game AND s2_won_game) FROM u UNION ALL
  SELECT 3, 'Came back on day 1', COUNTIF(s1_started_game AND s2_won_game AND s3_returned_d1) FROM u UNION ALL
  SELECT 4, 'Came back on days 2-6', COUNTIF(s1_started_game AND s2_won_game AND s3_returned_d1 AND s4_returned_d2_6) FROM u UNION ALL
  SELECT 5, 'Came back in week 2', COUNTIF(s1_started_game AND s2_won_game AND s3_returned_d1 AND s4_returned_d2_6 AND s5_returned_wk2) FROM u
)
ORDER BY step_no;
