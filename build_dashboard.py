"""Build dashboard.html: KPI tiles + charts in one self-contained file (open locally or via GitHub Pages)."""
import base64, json, pathlib
S = json.load(open("results/summary.json"))
img = lambda f: base64.b64encode(pathlib.Path("charts", f).read_bytes()).decode()
kpis = [
    ("New installs", f"{S['installs']:,}", "Jul 2 – Oct 3, 2018"),
    ("Avg daily active users", f"{S['dau_avg']:,}", f"MAU {S['mau_end']:,} at end of period"),
    ("Stickiness (DAU/MAU)", f"{S['stickiness_avg']:.0%}", "share of monthly users who show up daily"),
    ("Day-1 / Day-7 / Day-30", f"{S['retention']['D1']['All']:.0%} / {S['retention']['D7']['All']:.0%} / {S['retention']['D30']['All']:.0%}", "new-user retention"),
    ("Android 7-day uninstall", f"{S['android_uninstall_7d']:.0%}", "of Android installs"),
    ("Unattributed installs", f"{S['channel_share']['Direct / unattributed']:.0%}", "no source captured"),
]
sections = [
    ("Downloads & acquisition", "01_installs_weekly.png"), ("Active users", "02_active_users.png"),
    ("Retention", "03_retention.png"), ("Retention trend", "04_d1_by_cohort.png"),
    ("Usage frequency", "05_frequency_vs_retention.png"), ("User journey", "06_funnel.png"),
    ("Points of disengagement", "07_level_dropoff.png"), ("A/B test: ad frequency", "08_ab_test.png"),
]
tiles = "".join(f'<div class="tile"><div class="label">{a}</div><div class="value">{b}</div><div class="note">{c}</div></div>' for a, b, c in kpis)
charts = "".join(f'<figure><figcaption>{t}</figcaption><img alt="{t}" src="data:image/png;base64,{img(f)}"></figure>' for t, f in sections)
html = f"""<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Mobile App KPI Dashboard</title><style>
:root{{--bg:#f7f7f5;--card:#fff;--ink:#0b0b0b;--muted:#52514e;--line:#e4e3df}}
body{{margin:0;background:var(--bg);color:var(--ink);font:15px/1.45 -apple-system,Segoe UI,Roboto,sans-serif}}
main{{max-width:1100px;margin:0 auto;padding:24px 16px}} h1{{font-size:22px;margin:0 0 4px}} .sub{{color:var(--muted);margin:0 0 20px}}
.tiles{{display:grid;grid-template-columns:repeat(auto-fit,minmax(160px,1fr));gap:12px;margin-bottom:20px}}
.tile,figure{{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px}}
.label{{color:var(--muted);font-size:13px}} .value{{font-size:24px;font-weight:650;margin:2px 0}} .note{{color:var(--muted);font-size:12px}}
.grid{{display:grid;grid-template-columns:repeat(auto-fit,minmax(min(100%,480px),1fr));gap:12px}}
figure{{margin:0}} figcaption{{font-weight:600;margin-bottom:6px}} img{{width:100%;height:auto;display:block}}
</style></head><body><main>
<h1>Mobile app performance dashboard</h1>
<p class="sub">Real Firebase Analytics export (Flood-It!, Google public dataset) · BigQuery · {S['installs']:,} new users</p>
<div class="tiles">{tiles}</div><div class="grid">{charts}</div></main></body></html>"""
pathlib.Path("dashboard.html").write_text(html)
print("dashboard.html written")
