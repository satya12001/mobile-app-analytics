# Applying this to a patient rehab app

The same queries work for any app sending data to Firebase. Only the event names and the definition of "success" change.

## Metric translation

| This analysis | Rehab app equivalent |
|---|---|
| Install → first game | Install → account linked → first exercise completed |
| Won a game on day 0 | Completed first home-exercise session |
| Days active in week 1 | Exercise days in week 1 (adherence) |
| Levels 5–9 drop-off | Program week where patients stop (e.g. difficulty increase) |
| Ad-frequency A/B test | Reminder timing or frequency A/B test via Remote Config |
| Uninstall timing | Uninstall timing; spikes after discharge or after an appointment |
| Channel attribution | Discharge QR code vs. website vs. app store vs. paid campaign |

## Core events

| Event | Key parameters |
|---|---|
| `onboarding_step` | `step_name` |
| `exercise_session_start` / `_complete` | `program_week`, `session_length_sec` |
| `reminder_opened` | `reminder_type`, `hour_of_day` |
| `content_view` | `content_type` (video, article) |
| `appointment_click` | `cta_location` |

## HIPAA-safe rules
- **No PHI in analytics events.** No names, diagnoses, conditions, or free text in event parameters or user properties.
- **Use generic program IDs** (`program_a`), not diagnosis-based names.
- **Keep clinical data out of Firebase.** Join analytics to clinical outcomes only inside an approved, de-identified environment, never in the analytics tool.
- **Turn off advertising-ID collection and Google Signals** on patient-facing screens; review with Compliance before launch.
