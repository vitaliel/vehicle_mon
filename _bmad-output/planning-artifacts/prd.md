---
stepsCompleted:
  - step-01-init
  - step-02-discovery
  - step-02b-vision
  - step-02c-executive-summary
  - step-03-success
  - step-04-journeys
  - step-05-domain
  - step-06-innovation
  - step-07-project-type
  - step-08-scoping
  - step-09-functional
  - step-10-nonfunctional
  - step-11-polish
  - step-12-complete
inputDocuments:
  - _bmad-output/planning-artifacts/product-brief-vehicle_mon.md
workflowType: 'prd'
classification:
  projectType: web_app
  domain: general
  complexity: low
  projectContext: greenfield
---

# Product Requirements Document — Vehicle Service Tracker

**Author:** Vitalie
**Date:** 2026-04-23
**Stack:** Ruby on Rails + PostgreSQL · Greenfield · Web Application

---

## Executive Summary

The Vehicle Service Tracker is a responsive web application for household car owners managing one to three vehicles. It solves the chronic problem of scattered, forgotten maintenance records by providing a single organised history of every service event per vehicle, paired with proactive due-soon alerts. Existing options are either fleet-grade overkill or generic note apps with no reminder logic; this fills the gap at household scale.

### What Makes This Special

Three capabilities combine to differentiate this product:

1. **Dual-threshold reminders** — alerts fire on mileage *or* elapsed time, whichever arrives first. A car sitting unused still needs an oil change; single-dimension trackers miss this.
2. **Per-vehicle, per-service configurability** — thresholds set independently per vehicle and service type. A diesel and a petrol car can have different oil change intervals.
3. **Cost tracking as a first-class feature** — parts and labour captured on every log entry, building a running cost history valuable at resale and warranty time.

---

## Success Criteria

### User Success

- **Time-to-first-log:** New user registers, adds a vehicle, and logs a first service entry in under 5 minutes
- **Reminder accuracy:** Due-soon alerts fire correctly for every configured threshold — no false positives, no missed triggers
- **Monthly return:** Users return at least monthly to review history or act on reminders
- **Cost capture rate:** ≥70% of service log entries include at least one cost field (parts or labour)

### Technical Success

- Application runs correctly on current Ruby on Rails LTS + PostgreSQL
- Responsive layout verified on Chrome, Firefox, and Safari (desktop + mobile)
- Reminder calculation unit-tested across all edge cases: mileage-only, time-only, both thresholds, no threshold configured
- No unauthenticated access to any user data

### Measurable Outcomes

- All defined service types available in log entry catalog
- Dual-threshold reminder logic correctly handles all four threshold states
- Service history timeline displays entries in correct chronological order per vehicle
- Cost totals aggregate correctly per vehicle and per service type

---

## Product Scope

### MVP — Phase 1

- Multi-user authentication (register, sign in, sign out)
- Vehicle management: add, edit, delete (make, model, year, current mileage)
- Manual mileage update per vehicle
- Service log from predefined catalog: date, mileage at service, service center name, parts cost, labour cost, optional notes
- Predefined service type catalog (minimum 6 types: engine oil, spark plugs, air filter, brake pads, transmission fluid, tires)
- Per-vehicle, per-service-type configurable mileage and time thresholds (each optional independently)
- Due-soon reminder calculation (mileage OR time, whichever first); graceful no-threshold state
- Multi-vehicle dashboard with per-vehicle due-soon status indicators
- Per-vehicle service history timeline (chronological)
- Responsive layout — desktop + mobile browser

**Out of scope for v1:** email/push notifications, custom service type creation, receipt attachment, PDF export, household sharing.

### Growth — Phase 2

- Receipt and document attachment per log entry
- Custom service type creation by user
- Export service history to PDF
- Email/push due-soon notifications

### Vision — Phase 3

- Shareable read-only service history (supports resale value)
- OBD2 / third-party mileage sync
- Household vehicle sharing between accounts
- Service center recommendations based on history and location

---

## User Journeys

### Journey 1 — Marcus: First-Time Setup (Onboarding)

Marcus just bought a used 2019 Honda Civic and doesn't know when the previous owner last changed the oil.

**Opening:** Registers in under a minute. Adds his Civic — make, model, year, current mileage (~87,000 km).

**Rising action:** Picks "Engine Oil" from the catalog. Sets a 10,000 km / 12-month threshold. Logs an oil change from two months ago — date, ~85,000 km, cost €45.

**Climax:** Dashboard shows "Due in ~7,500 km or ~10 months." Immediate relief — the app knows what he knows.

**Resolution:** 4 minutes total. Bookmarks the app.

*Requires: registration, vehicle creation, mileage entry, service catalog, threshold configuration, service log creation, due-soon calculation and display.*

---

### Journey 2 — Elena: Monthly Check-In (Core Recurring Loop)

Elena manages her Golf and her husband's Skoda. Opens the app on a Sunday evening.

**Opening:** Dashboard shows both vehicles. Golf has a yellow "Due soon" badge on brake pads — within 500 km of threshold. Skoda is all green.

**Rising action:** Taps through to the Golf's history. Last brake job was 18 months ago — makes sense. Updates the Golf's current mileage from this morning's glance at the odometer.

**Climax:** Reminder updates to "Due in ~350 km." Accurate. Useful. One action item in her head.

**Resolution:** Two minutes. Two cars reviewed. She closes the app feeling on top of things.

*Requires: multi-vehicle dashboard, due-soon status display, per-vehicle history view, manual mileage update.*

---

### Journey 3 — Marcus: Post-Visit Log Entry

Marcus picks up his Civic after an oil change. Wants to log it in the car park.

**Opening:** Opens app on mobile. Taps Civic → "Add Service Entry."

**Rising action:** Selects "Engine Oil." Date auto-fills to today. Enters mileage (92,400 km), garage name, parts €28, labour €35. Adds a note.

**Climax:** Saves. Dashboard immediately shows "Due in ~9,800 km or ~11 months." Record captured.

**Resolution:** 90 seconds. The record exists for resale day.

*Requires: mobile-friendly log entry form, catalog selection, date/mileage/cost/notes fields, immediate reminder recalculation after log.*

---

### Journey 4 — Elena: Edge Case — No Threshold Configured

Elena adds her mother's Peugeot and logs some old entries from paper records, but sets no thresholds yet.

**Opening:** Peugeot on dashboard with no due-soon badges — history entries only.

**Rising action:** Notices no reminders. Navigates to the Peugeot's threshold configuration screen. Fields are empty.

**Climax:** Sets Oil (12,000 km / 12 months) and Tires (annual). Dashboard shows calculated reminders immediately.

**Resolution:** No frustration. Graceful empty state, clear path to configure, correct calculation on save.

*Requires: graceful no-threshold state (neutral, not an error), accessible threshold configuration per vehicle, recalculation on threshold save.*

### Journey Requirements Summary

| Capability Area | Journeys |
|---|---|
| Registration & authentication | 1 |
| Vehicle CRUD + mileage field | 1, 2 |
| Manual mileage update | 2 |
| Service catalog (predefined types) | 1, 3 |
| Service log entry (date, mileage, cost, notes, center) | 1, 3 |
| Per-vehicle, per-service threshold configuration | 1, 4 |
| Due-soon calculation (mileage OR time) | All |
| Multi-vehicle dashboard with status indicators | 2 |
| Per-vehicle history timeline | 2, 3 |
| Graceful no-threshold state | 4 |
| Mobile-responsive layout | 3 |

---

## Project-Type Requirements

### Architecture Overview

Server-rendered MPA built with Ruby on Rails. Standard request/response cycle. No SPA framework — complexity does not justify it. Mobile-responsive via CSS. Rails 7+ with Turbo for lightweight transitions without a JS framework.

### Browser Support

| Browser | Target | Priority |
|---|---|---|
| Chrome | Last 2 major versions | Primary |
| Firefox | Last 2 major versions | Primary |
| Safari | Last 2 major versions | Primary (mobile) |
| Edge | Last 2 major versions | Secondary |

### Responsive Design

- Mobile-first CSS; breakpoints at 768px (tablet) and 1024px (desktop)
- All core actions usable on a 375px viewport
- Touch targets ≥44px

### Implementation Constraints

- Devise (or equivalent) for authentication — no hand-rolled auth
- PostgreSQL for all persistent data
- Reminder calculation synchronous on page load — no background job queue needed for v1

---

## Functional Requirements

### User Account Management

- **FR1:** Visitors can register a new account with email and password
- **FR2:** Registered users can sign in with email and password
- **FR3:** Authenticated users can sign out
- **FR4:** Authenticated users can view and update their account details

### Vehicle Management

- **FR5:** Authenticated users can add a vehicle with make, model, year, and current mileage
- **FR6:** Authenticated users can edit any of their vehicle's details
- **FR7:** Authenticated users can delete a vehicle and all its associated data
- **FR8:** Authenticated users can update the current mileage of a vehicle at any time
- **FR9:** Authenticated users can view a list of all their registered vehicles

### Service Catalog

- **FR10:** The system provides a predefined catalog of service types (minimum: engine oil, spark plugs, air filter, brake pads, transmission fluid, tires)
- **FR11:** Users select a service type from the catalog when logging a service entry

### Service Log

- **FR12:** Authenticated users can create a service log entry for a vehicle, selecting a service type from the catalog
- **FR13:** A service log entry captures: date, mileage at service, service center name, parts cost, labour cost, and optional notes
- **FR14:** Authenticated users can edit an existing service log entry
- **FR15:** Authenticated users can delete a service log entry
- **FR16:** Authenticated users can view all service log entries for a vehicle in chronological order

### Reminder Thresholds

- **FR17:** Authenticated users can configure a mileage threshold for a specific service type on a specific vehicle
- **FR18:** Authenticated users can configure a time (calendar) threshold for a specific service type on a specific vehicle
- **FR19:** Both thresholds are optional — a service type with no threshold configured shows no reminder
- **FR20:** Thresholds are independent per vehicle and per service type

### Due-Soon Reminder Calculation

- **FR21:** The system calculates due-soon status per service type per vehicle, based on the last logged entry and configured thresholds
- **FR22:** Due-soon calculation uses mileage OR time, whichever threshold is reached first
- **FR23:** The system recalculates due-soon status when a new service entry is logged
- **FR24:** The system recalculates due-soon status when a vehicle's current mileage is updated
- **FR25:** The system recalculates due-soon status when a threshold is changed
- **FR26:** A service type with no logged entries and no thresholds shows a neutral/unconfigured state

### Dashboard & Navigation

- **FR27:** Authenticated users see a dashboard listing all their vehicles
- **FR28:** The dashboard shows a due-soon status indicator per vehicle
- **FR29:** Authenticated users can navigate to a per-vehicle detail view showing service history and reminder status
- **FR30:** The per-vehicle view shows due-soon status per service type with estimated mileage or time remaining

*The FR list is the capability contract. Any capability not listed here will not exist in the final product unless explicitly added.*

---

## Non-Functional Requirements

### Performance

- Initial page load: <2s on standard broadband
- Service log save + due-soon recalculation: <500ms server round-trip
- Dashboard with up to 10 vehicles: <1s load time
- Reminder calculation response consistent up to 500 log entries per vehicle

### Security

- All user data strictly scoped to the authenticated user — no cross-user data access
- Passwords stored as bcrypt hashes; never persisted or logged in plaintext
- All data in transit protected via HTTPS (TLS 1.2+)
- Session tokens invalidated on sign-out
- No sensitive data exposed in URLs or application logs

### Accessibility

- WCAG 2.1 Level A for all core user flows
- All form inputs have associated labels
- Keyboard navigation works for all primary actions
- Sufficient colour contrast for due-soon status indicators
