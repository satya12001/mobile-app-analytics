-- Data audit: daily users, installs and uninstalls across the full export.
-- Used to pick a clean analysis window (see README > Data notes).
SELECT
  PARSE_DATE('%Y%m%d', event_date)                       AS date,
  COUNT(DISTINCT user_pseudo_id)                         AS users_any_event,
  COUNT(DISTINCT IF(event_name = 'user_engagement', user_pseudo_id, NULL)) AS active_users,
  COUNTIF(event_name = 'first_open')                     AS installs,
  COUNTIF(event_name = 'app_remove')                     AS uninstalls,
  COUNT(*)                                               AS events
FROM `firebase-public-project.analytics_153293282.events_*`
GROUP BY date
ORDER BY date;
