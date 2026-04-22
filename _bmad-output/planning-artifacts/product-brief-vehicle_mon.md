---
title: "Product Brief: Vehicle Service Tracker"
status: "complete"
created: "2026-04-22"
updated: "2026-04-22"
inputs: []
---

# Product Brief: Vehicle Service Tracker

## Executive Summary

Most car owners leave vehicle maintenance to memory — a sticky note on the
dashboard, a vague recollection of "maybe six months ago," or a reminder from
a mechanic they haven't seen in a year. The result is missed service intervals,
unexpected breakdowns, and anxiety at every inspection.

The Vehicle Service Tracker is a responsive web application that gives car
owners a clear, organized history of every service performed on every vehicle
they own — and proactively alerts them when the next service is approaching,
based on whichever comes first: elapsed mileage or elapsed time. Built for
individuals managing one or more household vehicles, it transforms reactive
maintenance into a planned, confident monthly routine.

## The Problem

Service records are scattered — some in the glovebox, some with the mechanic,
most nowhere at all. When it's time to ask "when did I last change the oil?"
most owners genuinely don't know.

The consequences are real: oil changes missed by thousands of kilometers, timing
belts replaced too late, warranty claims rejected due to missing records. For
someone managing two household cars, the cognitive load doubles. Existing
solutions are either overkill (commercial fleet tools) or underbuilt (generic
note apps with no reminder logic). There's a clear gap for a focused, personal
maintenance tracker with intelligent, per-vehicle reminder logic.

## The Solution

The Vehicle Service Tracker lets users:

- **Register multiple vehicles** — make, model, year, with periodic manual
  mileage updates to keep the odometer current
- **Log service events** — from a predefined catalog of service types (engine
  oil, spark plugs, air filter, brake pads, transmission fluid, etc.), recording
  date, mileage at service, service center name, parts cost, labour cost,
  and optional notes
- **Review service history** — a clean per-vehicle timeline optimized for a
  quick monthly review to plan upcoming service center visits
- **Get due-soon in-app reminders** — each service type has a mileage threshold
  and/or a time threshold configured per vehicle; the app alerts when either
  is approaching, whichever comes first

Fully browser-based with a responsive mobile layout — usable at the garage
or on the couch.

## What Makes This Different

- **Dual-threshold reminders** — alerts fire on mileage OR time interval,
  whichever comes first. This mirrors how real-world maintenance actually works;
  most trackers force a single dimension.
- **Per-vehicle, per-service thresholds** — reminder intervals are configurable
  per vehicle and service type, not global defaults. A diesel and a petrol car
  can have different oil change intervals.
- **Cost tracking from day one** — parts and labour costs are captured on every
  log entry, giving users a running cost history per vehicle and per service
  type.
- **Household-scale, not fleet-scale** — designed for the individual managing
  1–3 vehicles. Fast, focused UX without fleet management overhead.

## Who This Serves

**Primary user:** A car-owning adult managing one or more household vehicles.
Organized enough to check in monthly. Values knowing their vehicles are well
maintained. Wants to see what the last brake job actually cost and whether the
next oil change is coming up.

## Success Criteria

- Users return monthly to review history and respond to due-soon reminders
- Reminder accuracy: alerts fire correctly based on configured per-vehicle,
  per-service mileage and time thresholds
- Time-to-first-log: new users add a vehicle and first service entry in under
  5 minutes
- Cost capture rate: majority of service logs include cost data

## Scope

**In for v1:**
- Multi-user authentication (register / sign in)
- Vehicle management (add, edit, delete — make, model, year, mileage)
- Periodic manual mileage update per vehicle
- Service log from predefined catalog: date, mileage at service, service center
  name, parts cost, labour cost, optional notes
- Per-vehicle, per-service-type configurable mileage and time thresholds
- Per-vehicle service history timeline
- Due-soon reminder logic (mileage + time, whichever first) — in-app only
- Responsive layout (desktop + mobile browser)
- Ruby on Rails + PostgreSQL

**Explicitly out of v1:**
- Vehicle or record sharing between users
- Email or push notifications
- Custom service type creation
- Service record import/export
- OBD2 or third-party integrations

## Vision

As the dataset matures: receipt and document attachment (making logs genuinely
useful for warranty claims), custom service type definitions, export to PDF for
resale documentation, and eventually shareable service history that demonstrably
increases a vehicle's resale value. The story evolves from "stay organized"
to "protect your investment."
