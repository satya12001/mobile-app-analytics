"""Turn results/*.csv into charts/*.png and results/summary.json (numbers quoted in the README)."""
import json, pathlib
import numpy as np, pandas as pd
import matplotlib; matplotlib.use("Agg")
import matplotlib.pyplot as plt
from scipy import stats

R, C = pathlib.Path("results"), pathlib.Path("charts"); C.mkdir(exist_ok=True)
BLUE, ORANGE, AQUA, GRAY, INK, MUTED = "#2a78d6", "#eb6834", "#1baf7a", "#b9b8b3", "#0b0b0b", "#52514e"
END = pd.Timestamp("2018-10-03")
plt.rcParams.update({"font.size": 10, "axes.spines.top": False, "axes.spines.right": False,
                     "axes.edgecolor": GRAY, "axes.labelcolor": MUTED, "xtick.color": MUTED,
                     "ytick.color": MUTED, "axes.grid": True, "grid.color": "#ecebe8", "grid.linewidth": 0.8,
                     "axes.axisbelow": True, "axes.titleweight": "bold", "axes.titlesize": 11,
                     "axes.titlelocation": "left", "figure.dpi": 150, "lines.linewidth": 2})
pct = matplotlib.ticker.PercentFormatter(1.0, decimals=0)
def save(fig, name): fig.tight_layout(); fig.savefig(C / name, facecolor="white"); plt.close(fig)
S = {}

# 1. Acquisition ---------------------------------------------------------------
acq = pd.read_csv(R / "01_acquisition.csv", parse_dates=["install_week"])
ch = acq.groupby("channel")["installs"].sum().sort_values(ascending=False)
S["installs"] = int(ch.sum()); S["channel_share"] = (ch / ch.sum()).round(3).to_dict()
andr = acq[acq.platform == "ANDROID"]
S["android_uninstall_7d"] = round(andr.uninstalled_within_7d.sum() / andr.installs.sum(), 3)
wk = acq.pivot_table(index="install_week", columns="platform", values="installs", aggfunc="sum").iloc[:-1]  # drop partial last week
fig, ax = plt.subplots(figsize=(7, 3.2))
for p, col in [("ANDROID", BLUE), ("IOS", ORANGE)]:
    ax.plot(wk.index, wk[p], color=col, marker="o", ms=4)
    ax.annotate("Android" if p == "ANDROID" else "iOS", (wk.index[-1], wk[p].iloc[-1]), xytext=(6, 0),
                textcoords="offset points", va="center", color=INK)
ax.set_title("New installs per week"); ax.set_ylim(0); ax.set_ylabel("installs")
save(fig, "01_installs_weekly.png")

# 2. Active users ----------------------------------------------------------------
au = pd.read_csv(R / "02_active_users.csv", parse_dates=["date"])
S["dau_avg"] = int(au.dau.mean()); S["mau_end"] = int(au.mau.iloc[-1]); S["stickiness_avg"] = round(au.stickiness.mean(), 3)
fig, ax = plt.subplots(figsize=(7, 3.2))
for col, c, lab in [("mau", BLUE, "MAU (28-day)"), ("wau", AQUA, "WAU (7-day)"), ("dau", ORANGE, "DAU")]:
    ax.plot(au.date, au[col], color=c); ax.annotate(lab, (au.date.iloc[-1], au[col].iloc[-1]), xytext=(6, 0),
                                                   textcoords="offset points", va="center", color=INK)
ax.set_title("Active users"); ax.set_ylim(0); ax.set_ylabel("users")
save(fig, "02_active_users.png")

# 3. Retention -----------------------------------------------------------------------
ret = pd.read_csv(R / "03_retention.csv", parse_dates=["cohort_week"])
overall = {}
for d in [1, 7, 14, 30]:
    col = f"d{d}_retention"
    ok = ret[ret.cohort_week + pd.Timedelta(days=6) <= END - pd.Timedelta(days=d)]  # fully observed cohorts only
    overall[f"D{d}"] = {p: round(np.average(g[col], weights=g.new_users), 3) for p, g in ok.groupby("platform")}
    overall[f"D{d}"]["All"] = round(np.average(ok[col], weights=ok.new_users), 3)
S["retention"] = overall
fig, ax = plt.subplots(figsize=(7, 3.2))
x = np.arange(4); w = 0.38
for i, (p, c, lab) in enumerate([("ANDROID", BLUE, "Android"), ("IOS", ORANGE, "iOS")]):
    v = [overall[k][p] for k in overall]
    b = ax.bar(x + (i - 0.5) * w, v, w - 0.03, color=c, label=lab)
    ax.bar_label(b, labels=[f"{y:.0%}" for y in v], padding=2, color=INK, fontsize=9)
ax.set_xticks(x, ["Day 1", "Day 7", "Day 14", "Day 30"]); ax.yaxis.set_major_formatter(pct)
ax.set_title("Share of new users active N days after install"); ax.legend(frameon=False)
save(fig, "03_retention.png")

c1 = pd.Series({k: np.average(g.d1_retention, weights=g.new_users) for k, g in ret.groupby("cohort_week")}).iloc[:-1]
S["d1_july"] = round(c1[c1.index < "2018-08-01"].mean(), 3); S["d1_late"] = round(c1[c1.index >= "2018-08-27"].mean(), 3)
fig, ax = plt.subplots(figsize=(7, 3))
ax.plot(c1.index, c1.values, color=BLUE, marker="o", ms=4)
ax.yaxis.set_major_formatter(pct); ax.set_ylim(0, 0.35); ax.set_title("Day-1 retention by install week")
save(fig, "04_d1_by_cohort.png")

# 4. Usage frequency -------------------------------------------------------------------
fq = pd.read_csv(R / "04_usage_frequency.csv")
S["frequency"] = fq.set_index("days_active_first_week")[["users", "active_in_week_5"]].to_dict("index")
fig, ax = plt.subplots(figsize=(7, 3))
b = ax.bar(fq.days_active_first_week, fq.active_in_week_5, color=BLUE, width=0.6)
ax.bar_label(b, labels=[f"{v:.0%}\n(n={n:,})" for v, n in zip(fq.active_in_week_5, fq.users)], padding=2, color=INK, fontsize=9)
ax.yaxis.set_major_formatter(pct); ax.set_ylim(0, 0.5)
ax.set_xlabel("days active in first week"); ax.set_title("Still active in week 5, by first-week habit")
save(fig, "05_frequency_vs_retention.png")

# 5. Funnel --------------------------------------------------------------------------
fn = pd.read_csv(R / "06_user_journey.csv")
S["funnel"] = fn.set_index("step").pct_of_installs.to_dict()
fig, ax = plt.subplots(figsize=(7, 3))
y = np.arange(len(fn))[::-1]
b = ax.barh(y, fn.pct_of_installs, color=BLUE, height=0.6)
ax.bar_label(b, labels=[f"{v:.0%}  ({n:,})" for v, n in zip(fn.pct_of_installs, fn.users)], padding=3, color=INK, fontsize=9)
ax.set_yticks(y, fn.step); ax.xaxis.set_major_formatter(pct); ax.set_xlim(0, 1.2); ax.grid(axis="y", visible=False)
ax.set_title("New-user journey (each step requires the one before)")
save(fig, "06_funnel.png")

# 6. Disengagement by level ----------------------------------------------------------------
lv = pd.read_csv(R / "07_disengagement_by_level.csv")
S["level_players"] = {int(k): int(v) for k, v in lv.set_index("level").players_started.items()}
S["level_fail"] = {int(k): float(v) for k, v in lv.set_index("level").fail_rate.items()}
fig, (a1, a2) = plt.subplots(2, 1, figsize=(7, 4.6), sharex=True)
a1.bar(lv.level, lv.players_started, color=BLUE, width=0.75); a1.set_title("Players who reached each level"); a1.set_ylabel("players")
a2.bar(lv.level, lv.fail_rate, color=[ORANGE if f >= 0.25 else GRAY for f in lv.fail_rate], width=0.75)
a2.yaxis.set_major_formatter(pct); a2.set_title("Fail rate per attempt (orange = 25%+)"); a2.set_xlabel("level")
a2.set_xticks(range(1, 31, 2))
save(fig, "07_level_dropoff.png")

un = pd.read_csv(R / "08_uninstall_timing.csv")
S["uninstall_timing"] = un.set_index("uninstalled").pct_of_installs.to_dict()

# 7. A/B test ------------------------------------------------------------------------------
ab = pd.read_csv(R / "09_ab_test_ad_frequency.csv")
ab["rate"] = ab.returned_7d / ab.users
base = ab.iloc[0]; rows = []
srm_p = stats.chisquare(ab.users).pvalue
for _, r in ab.iloc[1:].iterrows():
    p1, p0, n1, n0 = r.rate, base.rate, r.users, base.users
    pp = (r.returned_7d + base.returned_7d) / (n1 + n0)
    z = (p1 - p0) / np.sqrt(pp * (1 - pp) * (1 / n1 + 1 / n0))
    se = np.sqrt(p1 * (1 - p1) / n1 + p0 * (1 - p0) / n0)
    t = stats.ttest_ind_from_stats(r.avg_minutes_7d, r.sd_minutes_7d, n1, base.avg_minutes_7d, base.sd_minutes_7d, n0, equal_var=False)
    rows.append({"arm": r.arm, "users": int(n1), "return_rate": round(p1, 3), "diff_vs_baseline_pts": round((p1 - p0) * 100, 1),
                 "ci95_low_pts": round((p1 - p0 - 1.96 * se) * 100, 1), "ci95_high_pts": round((p1 - p0 + 1.96 * se) * 100, 1),
                 "p_value_return": round(2 * stats.norm.sf(abs(z)), 3),
                 "minutes_diff": round(r.avg_minutes_7d - base.avg_minutes_7d, 2), "p_value_minutes": round(t.pvalue, 3)})
abt = pd.DataFrame(rows); abt.to_csv(R / "ab_test_stats.csv", index=False)
mde = (1.96 + 0.84) * np.sqrt(2 * base.rate * (1 - base.rate) / base.users)
S["ab"] = {"baseline_rate": round(base.rate, 3), "srm_p": round(srm_p, 3), "mde_pts": round(mde * 100, 1), "arms": rows}
fig, ax = plt.subplots(figsize=(7, 3))
se = np.sqrt(ab.rate * (1 - ab.rate) / ab.users)
cols = [GRAY] + [BLUE] * 3
ax.barh(ab.arm[::-1], ab.rate[::-1], xerr=1.96 * se[::-1], color=cols[::-1], height=0.55,
        error_kw={"ecolor": INK, "elinewidth": 1, "capsize": 3})
for yy, v in enumerate(ab.rate[::-1]): ax.text(0.405, yy, f"{v:.1%}", va="center", color=INK, fontsize=9)
ax.xaxis.set_major_formatter(pct); ax.set_xlim(0, 0.45); ax.grid(axis="y", visible=False)
ax.set_title("Returned within 7 days, by ad-frequency arm (95% CI)")
save(fig, "08_ab_test.png")

fe = pd.read_csv(R / "05_feature_engagement.csv"); S["features"] = fe.set_index("feature").to_dict("index")
json.dump(S, open(R / "summary.json", "w"), indent=1, default=float)
print(json.dumps(S, indent=1, default=float))
