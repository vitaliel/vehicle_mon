---
title: "Product Brief Distillate: vehicle_mon"
type: llm-distillate
source: "product-brief-vehicle_mon.md"
created: "2026-04-22"
purpose: "Token-efficient context for downstream PRD creation"
---

# Product Brief Distillate: Vehicle Service Tracker

## Product Identity

- Personal vehicle maintenance tracker, NOT a fleet management or commercial tool
- Target: individuals managing 1–3 household vehicles (e.g., own car + spouse's car)
- Primary use pattern: monthly review to plan service center visits + reactive reminder checks
- Tagline signal: "protect your investment" / "stay organized" — resale value angle is future story

## Users & Personas

- Single user per account — no collaboration or sharing in v1
- Typical scenario: user manages 2 vehicles (their car + partner's car)
- Monthly check-in behavior: user reviews history to decide what needs attention soon
- Mobile use case: checking/logging at the garage or service center

## Core Features — Requirements Hints

### Vehicles
- Each user has a set of vehicles (make, model, year, current mileage)
- Mileage is manually updated by the user, periodically (weekly or monthly cadence)
- Mileage is NOT auto-fetched (no OBD2, no integrations in v1)
- Current mileage is the baseline for due-soon reminder calculations

### Service Catalog
- Predefined list of service types — not user-defined in v1
- Examples: engine oil, spark plugs, air filter, brake pads, transmission fluid
- Full list TBD — should cover standard passenger vehicle maintenance items

### Service Logs
- Fields per log entry:
  - Service type (from predefined catalog)
  - Date of service
  - Mileage at time of service
  - Service center / company name
  - Parts cost (currency value)
  - Labour cost (currency value)
  - Notes (optional free text)
- Logs are per-vehicle, ordered chronologically

### Reminder Thresholds
- Configurable per vehicle AND per service type (not global defaults)
- Two threshold dimensions: mileage interval AND time interval (e.g., 10,000 km or 12 months)
- Reminder fires when EITHER threshold is reached — whichever comes first
- Time interval examples: 1 year, 2 years
- Mileage interval: user-configured value per service type per vehicle
- Due-soon = approaching threshold (not just overdue) — exact "soon" window TBD

### Notifications
- In-app only for v1 — no email, no push notifications
- Notification triggers: due-soon reminders per vehicle per service type

### Authentication
- Multi-user web app — each user has their own account and data
- Standard register / sign-in flow
- No OAuth requirement stated — assume email/password sufficient for v1

## Technical Constraints & Preferences

- **Framework:** Ruby on Rails
- **Database:** PostgreSQL
- **Deployment:** not specified — standard Rails deployment assumed
- **Frontend:** responsive web (mobile-friendly browser layout) — NOT a native mobile app
- **No mobile push notifications** (browser app only)

## Explicitly Out of Scope (v1)

- Sharing vehicles or service records between users
- Email notifications
- Push notifications
- Custom user-defined service types
- Cost analytics / expense reports (captured in log, not surfaced as dashboard)
- Service record import / export
- OBD2 or external data integrations
- Fleet management features

## Rejected Ideas & Rationale

- **Collaboration/sharing:** explicitly deferred — each user manages their own vehicles independently
- **Custom service types:** deferred in favor of predefined catalog for v1 simplicity
- **Email/push notifications:** out of v1 scope — in-app only

## Resolved Decisions

- **Predefined service types:** seeded directly in the database (not user-managed UI) — list maintained by developer/admin
- **"Due soon" window:** 500 km OR 2 weeks before threshold — whichever comes first
- **Cost fields (parts cost, labour cost):** REQUIRED on every service log entry

- **Currency:** user selects from predefined list at profile level: MDL, EUR, USD — one currency per user account
- **Authentication:** username + password only — no social/OAuth login
- **Service history:** paginated list view

## Open Questions (Unresolved)

- None — all questions resolved.

## Future Vision Signals (v2+)

- Receipt / document attachment per service log — warranty claim utility
- PDF export of service history — useful for resale
- Shareable service history per vehicle — resale value angle
- Custom service type definitions
- Cost analytics / totals per vehicle or service type
