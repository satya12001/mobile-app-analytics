# Memo: Mobile app growth and retention

**To:** Director, Digital Marketing · **Re:** Q3 app performance and next steps

## Bottom line
The app gets installs but doesn't keep users. **81% of new users don't come back the next day, and fewer than 2% are still active at day 30.** More acquisition spend won't fix this. The next gains come from the first 7 days of use.

## What the data shows
1. **The first week decides everything.** Users active 5+ days in week 1 are 13× more likely to still be active in week 5 (38% vs 3%). Only 5% of users get there.
2. **A difficulty wall pushes users out.** Fail rates jump from 5% to 27–42% at levels 5–9, and 63% of players are lost in that stretch.
3. **Android users leave on day one.** 30% uninstall on install day.
4. **Channel ROI can't be measured.** 69% of installs carry no source.
5. **Retention is slipping.** Day-1 retention fell from 23% to 14% from July to September.
6. **Ad frequency had no measurable effect** on 7-day return (p > 0.25), but the test was too small to rule out drops of up to 6 points.

## Recommendations (in priority order)

| # | Action | Why | Measure | Effort |
|---|---|---|---|---|
| 1 | **Day-1 return prompt:** a push or daily challenge 20–24 h after install | Day 0 → day 1 is the biggest drop | D1 retention (A/B test) | Low |
| 2 | **Smooth levels 5–9:** add a hint or ease the difficulty curve | 63% of players lost there | Level 10 reach, D7 | Medium |
| 3 | **Fix attribution:** UTM-tagged store links, Play install referrer, Ads ↔ Firebase linking | Can't judge channels at 69% unattributed | % attributed installs | Low |
| 4 | **Diagnose the September decline:** split those cohorts by campaign and source | D1 fell 9 pts | D1 by source | Low |
| 5 | **Rerun the ad-frequency test** at about 4× the sample before raising ad load | Current test can't detect < 6 pt effects | 7-day return, minutes | Low |

## KPIs to report weekly
Installs by channel · % attributed · D1/D7/D30 retention by cohort · share of users with 2+ active days in week 1 · DAU/MAU · Android day-0 uninstall rate.
