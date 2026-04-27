---
stepsCompleted:
  - step-01-document-discovery
  - step-02-prd-analysis
  - step-03-epic-coverage-validation
  - step-04-ux-alignment
  - step-05-epic-quality-review
  - step-06-final-assessment
filesUsed:
  - _bmad-output/planning-artifacts/prd.md
  - _bmad-output/planning-artifacts/architecture.md
  - _bmad-output/planning-artifacts/epics.md
---

# Implementation Readiness Assessment Report

**Date:** 2026-04-24
**Project:** Vehicle Service Tracker
**Assessor:** Implementation Readiness Skill (BMad)

---

## Document Inventory

| Document | File | Size | Date |
|---|---|---|---|
| PRD | `prd.md` | 13K | Apr 23 |
| Architecture | `architecture.md` | 30K | Apr 23 |
| Epics & Stories | `epics.md` | 27K | Apr 24 |
| UX Design | **Not found** | — | — |

---

## PRD Analysis

### Functional Requirements

FR1: Visitors can register a new account with email and password
FR2: Registered users can sign in with email and password
FR3: Authenticated users can sign out
FR4: Authenticated users can view and update their account details
FR5: Authenticated users can add a vehicle with make, model, year, and current mileage
FR6: Authenticated users can edit any of their vehicle's details
FR7: Authenticated users can delete a vehicle and all its associated data
FR8: Authenticated users can update the current mileage of a vehicle at any time
FR9: Authenticated users can view a list of all their registered vehicles
FR10: The system provides a predefined catalog of service types (minimum: engine oil, spark plugs, air filter, brake pads, transmission fluid, tires)
FR11: Users select a service type from the catalog when logging a service entry
FR12: Authenticated users can create a service log entry for a vehicle, selecting a service type from the catalog
FR13: A service log entry captures: date, mileage at service, service center name, parts cost, labour cost, and optional notes
FR14: Authenticated users can edit an existing service log entry
FR15: Authenticated users can delete a service log entry
FR16: Authenticated users can view all service log entries for a vehicle in chronological order
FR17: Authenticated users can configure a mileage threshold for a specific service type on a specific vehicle
FR18: Authenticated users can configure a time (calendar) threshold for a specific service type on a specific vehicle
FR19: Both thresholds are optional — a service type with no threshold configured shows no reminder
FR20: Thresholds are independent per vehicle and per service type
FR21: The system calculates due-soon status per service type per vehicle, based on the last logged entry and configured thresholds
FR22: Due-soon calculation uses mileage OR time, whichever threshold is reached first
FR23: The system recalculates due-soon status when a new service entry is logged
FR24: The system recalculates due-soon status when a vehicle's current mileage is updated
FR25: The system recalculates due-soon status when a threshold is changed
FR26: A service type with no logged entries and no thresholds shows a neutral/unconfigured state
FR27: Authenticated users see a dashboard listing all their vehicles
FR28: The dashboard shows a due-soon status indicator per vehicle
FR29: Authenticated users can navigate to a per-vehicle detail view showing service history and reminder status
FR30: The per-vehicle view shows due-soon status per service type with estimated mileage or time remaining

**Total FRs: 30**

### Non-Functional Requirements

NFR1: Initial page load < 2s on standard broadband
NFR2: Service log save + due-soon recalculation < 500ms server round-trip
NFR3: Dashboard with up to 10 vehicles < 1s load time
NFR4: Reminder calculation consistent up to 500 log entries per vehicle
NFR5: All user data strictly scoped to the authenticated user — no cross-user data access
NFR6: Passwords stored as bcrypt hashes; never persisted or logged in plaintext
NFR7: All data in transit protected via HTTPS (TLS 1.2+)
NFR8: Session tokens invalidated on sign-out
NFR9: No sensitive data exposed in URLs or application logs
NFR10: WCAG 2.1 Level A for all core user flows
NFR11: All form inputs have associated labels
NFR12: Keyboard navigation works for all primary actions
NFR13: Sufficient colour contrast for due-soon status indicators
NFR14: Responsive layout — all core actions usable on a 375px viewport; touch targets ≥44px
NFR15: Browser support: Chrome, Firefox, Safari, Edge — last 2 major versions each

**Total NFRs: 15**

### Additional Requirements

ARC1: Project initialization using `rails new vehicle_mon --database=postgresql --asset-pipeline=propshaft --skip-test --skip-jbuilder`
ARC2: Gemfile additions: `devise (~> 5.0)`, `rspec-rails`, `factory_bot_rails`, `shoulda-matchers`
ARC3: Global ServiceType seed data — 6 records: engine oil, spark plugs, air filter, brake pads, transmission fluid, tires
ARC4: `DueSoonCalculator` service object as sole calculation authority
ARC5: All controllers scope queries through `current_user` association chain
ARC6: Bootstrap 5.3.8 and Bootstrap Icons loaded via CDN
ARC7: GitHub Actions CI workflow — RSpec on push
ARC8: Kamal 2 deployment configuration for Docker-based VPS deployment
ARC9: `config.force_ssl = true` in production environment
ARC10: `rescue_from ActiveRecord::RecordNotFound` in ApplicationController
ARC11: Validation failures render with `status: :unprocessable_entity` for Turbo compatibility

**Total ARCs: 11**

### PRD Completeness Assessment

The PRD is well-structured, complete, and implementable. Requirements are numbered, testable, and scoped to MVP Phase 1. User journeys are detailed and map cleanly to functional requirements. The PRD correctly separates Phase 2/3 features as out of scope.

---

## Epic Coverage Validation

### Coverage Matrix

| FR | PRD Requirement | Epic Coverage | Status |
|---|---|---|---|
| FR1 | Register with email/password | Epic 1 – Story 1.2 | ✓ Covered |
| FR2 | Sign in with email/password | Epic 1 – Story 1.3 | ✓ Covered |
| FR3 | Sign out | Epic 1 – Story 1.3 | ✓ Covered |
| FR4 | View/update account details | Epic 1 – Story 1.4 | ✓ Covered |
| FR5 | Add vehicle | Epic 2 – Story 2.1 | ✓ Covered |
| FR6 | Edit vehicle details | Epic 2 – Story 2.2 | ✓ Covered |
| FR7 | Delete vehicle + cascade | Epic 2 – Story 2.3 | ✓ Covered |
| FR8 | Update current mileage | Epic 2 – Story 2.4 | ✓ Covered |
| FR9 | View vehicle list | Epic 2 – Story 2.1 | ✓ Covered |
| FR10 | Predefined service catalog | Epic 3 – Story 3.1 | ✓ Covered |
| FR11 | Select service type on log entry | Epic 3 – Story 3.2 | ✓ Covered |
| FR12 | Create service log entry | Epic 3 – Story 3.2 | ✓ Covered |
| FR13 | Log entry fields (date, mileage, center, costs, notes) | Epic 3 – Story 3.2 | ✓ Covered |
| FR14 | Edit service log entry | Epic 3 – Story 3.4 | ✓ Covered |
| FR15 | Delete service log entry | Epic 3 – Story 3.5 | ✓ Covered |
| FR16 | Chronological history view | Epic 3 – Story 3.3 | ✓ Covered |
| FR17 | Configure mileage threshold | Epic 4 – Story 4.2 | ✓ Covered |
| FR18 | Configure time threshold | Epic 4 – Story 4.2 | ✓ Covered |
| FR19 | Optional thresholds / no-threshold state | Epic 4 – Story 4.2 | ✓ Covered |
| FR20 | Independent per-vehicle per-service thresholds | Epic 4 – Story 4.2 | ✓ Covered |
| FR21 | Calculate due-soon status | Epic 4 – Story 4.1, 4.3 | ✓ Covered |
| FR22 | Mileage OR time (whichever first) | Epic 4 – Story 4.1 | ✓ Covered |
| FR23 | Recalculate on new log entry | Epic 4 – Story 4.4 | ✓ Covered |
| FR24 | Recalculate on mileage update | Epic 4 – Story 4.4 | ✓ Covered |
| FR25 | Recalculate on threshold change | Epic 4 – Story 4.4 | ✓ Covered |
| FR26 | Neutral/unconfigured state | Epic 4 – Story 4.1, 4.3 | ✓ Covered |
| FR27 | Multi-vehicle dashboard | Epic 5 – Story 5.1 | ✓ Covered |
| FR28 | Dashboard due-soon status indicators | Epic 5 – Story 5.1 | ✓ Covered |
| FR29 | Navigate to per-vehicle detail view | Epic 5 – Story 5.2 | ✓ Covered |
| FR30 | Per-vehicle view: due-soon per service type with remaining | Epic 4 – Story 4.3 | ✓ Covered |

### Missing Requirements

None — all 30 FRs are covered by at least one story.

### Coverage Statistics

- Total PRD FRs: 30
- FRs covered in epics: 30
- **Coverage: 100%**

---

## UX Alignment Assessment

### UX Document Status

**Not Found.** No UX design document exists in `_bmad-output/planning-artifacts/`.

The epics document itself notes: "_No UX Design document provided._"

### Alignment Issues

No direct UX ↔ Architecture misalignment found, as the PRD's user journeys and the Architecture document together serve as the UX specification:

- PRD user journeys describe key interaction flows in detail
- Architecture defines Bootstrap 5.3.8, responsive breakpoints, status badge classes (`badge-due-soon`, `badge-ok`, `badge-unconfigured`), and Bootstrap Icons for indicators
- Architecture specifies mobile-first CSS, 375px min viewport, touch targets ≥44px
- Architecture defines shared partials: `_vehicle_card.html.erb`, `_flash_messages.html.erb`

These are sufficient for a household-scale web app with no novel interaction patterns.

### Warnings

⚠️ **WARNING: No formal UX document.** This is a user-facing responsive web application. While PRD user journeys and architecture notes partially compensate, there is no wireframe, component spec, or UX flow document. Implementors will make UI decisions ad-hoc.

**Risk level:** Low — for a simple CRUD app with Bootstrap, this is unlikely to cause functional failures but may result in inconsistent UI between stories.

---

## Epic Quality Review

### Epic Structure Validation

#### User Value Focus Check

| Epic | Title | User Value | Assessment |
|---|---|---|---|
| Epic 1 | Project Foundation & User Authentication | Mixed: "Project Foundation" is technical; "User Authentication" is user-value | 🟡 Borderline |
| Epic 2 | Vehicle Fleet Management | ✓ User-centric | ✓ Pass |
| Epic 3 | Service History Logging | ✓ User-centric | ✓ Pass |
| Epic 4 | Maintenance Reminders & Due-Soon Engine | ✓ User-centric | ✓ Pass |
| Epic 5 | Dashboard & Production Readiness | Mixed: "Dashboard" is user value; "Production Readiness" is technical | 🟡 Borderline |

**Epic 1 note:** The "Project Foundation" scope includes Story 1.1 (rails new initialization) which is a pure developer story. This is standard for greenfield projects but technically a best-practices violation. The user value of this epic only begins with Story 1.2.

**Epic 5 note:** "Production Readiness" (ARC8 — Kamal deployment) is included in the epic description but **has no implementation story**. See critical issue below.

#### Epic Independence Validation

- Epic 1 → stands alone ✓
- Epic 2 → uses only Epic 1 (Devise auth) ✓
- Epic 3 → uses Epic 1 & 2 (auth + vehicles) ✓
- Epic 4 → uses Epic 1, 2, 3 (auth + vehicles + service log entries for calculation) ✓
- Epic 5 → uses Epic 1–4 ✓

No circular dependencies found. Epic ordering is correct.

---

### Story Quality Assessment

#### Developer Stories (Best-Practices Concern)

Three stories are developer-oriented with no direct user value:

| Story | Type | Verdict |
|---|---|---|
| 1.1: Rails Application Initialization | Developer setup | 🟡 Expected for greenfield; acceptable |
| 3.1: Service Type Catalog Seed | Developer data setup | 🟡 Acceptable; no meaningful user story alternative |
| 4.1: DueSoonCalculator Service Object | Developer infrastructure | 🟡 Acceptable; encapsulates critical domain logic |

These are common in greenfield Rails projects. Flag them as non-user stories in documentation but they are functionally necessary.

#### Acceptance Criteria Review

All stories use proper Given/When/Then BDD structure. Error conditions (422 responses, RecordNotFound, cross-user access) are explicitly covered in most stories. Happy path is complete.

---

### Dependency Analysis

#### 🔴 CRITICAL: Missing Story — Kamal Deployment (ARC8)

Epic 5 explicitly states **"ARCs covered: ARC5, ARC8"** but contains only two stories:
- Story 5.1: Multi-Vehicle Dashboard
- Story 5.2: Navigate to Vehicle Detail View

**ARC8 (Kamal 2 deployment configuration for Docker-based VPS deployment) has no implementation story.**

The architecture document dedicates a full section to Kamal deployment, yet no story exists to implement it. An AI developer agent following the epics document will deploy zero production infrastructure.

**Impact:** Critical — production deployment will not be implemented.
**Recommendation:** Add Story 5.3: Production Deployment (Kamal 2 Configuration) to Epic 5 covering: Dockerfile, `config/deploy.yml`, `config.force_ssl = true` (ARC9), smoke-test deployment to a VPS.

---

#### 🟠 MAJOR: Missing Base `vehicles#show` Page Story

The vehicle detail page (`vehicles#show`) is **referenced by 5 stories across 4 epics** but is never explicitly created:

- Story 2.4: "Given I am on my vehicle's detail page..." (Epic 2)
- Story 4.3: Adds due-soon status to the vehicle detail page (Epic 4)
- Story 4.4: Redirects to vehicle detail page after changes (Epic 4)
- Story 5.2: "the detail page shows the vehicle's service history and per-service-type due-soon status" (Epic 5)

**No story says: "Create the vehicles#show view."**

Story 2.1 creates the `vehicles#index` (list). Story 4.3 adds content to `vehicles#show` but assumes it already exists. Story 5.2 references it as displaying both service history *and* due-soon status — but service history is in `service_log_entries#index` (Story 3.3), not `vehicles#show`.

**Impact:** Major — a developer agent will need to invent what `vehicles#show` contains in Story 2.4 or 4.3, creating inconsistency risk. The relationship between `vehicles#show` and `service_log_entries#index` is undefined.

**Recommendation:** Add an AC to Story 2.1 explicitly creating `vehicles#show` with a minimal scaffold (vehicle info + mileage update form), OR add a dedicated sub-story 2.5 "Vehicle Detail Page" that establishes the view as the navigation hub.

---

#### 🟠 MAJOR: ARC9 (config.force_ssl) Not in Any Story AC

`config.force_ssl = true` (ARC9) is listed as an ARC requirement and is covered by Epic 1 in the ARC coverage map, but **Story 1.1's acceptance criteria do not mention it**.

Story 1.1 ACs cover: Bootstrap layout, flash partial, vehicle_card partial stub, Gemfile gems, GitHub Actions CI. `config.force_ssl = true` is absent.

**Impact:** Major — security requirement NFR7 (HTTPS TLS 1.2+) may not be implemented.
**Recommendation:** Add an AC to Story 1.1: "Given `config/environments/production.rb` is reviewed, Then `config.force_ssl = true` is set."

Alternatively, address this in the proposed Story 5.3 (Kamal/production deployment) since force_ssl is a production concern.

---

#### 🟡 MINOR: Story 2.4 Does Not Mention Recalculation Trigger

Story 2.4 (Update Vehicle Mileage) is the user-facing action for FR8. FR24 says the system must recalculate due-soon status when mileage is updated. Story 2.4's ACs do not mention recalculation — this is deferred to Story 4.4.

This means a developer implementing Story 2.4 in isolation will NOT trigger recalculation (DueSoonCalculator doesn't exist yet in Epic 2). Story 4.4 must revisit the mileage update controller action to add the recalculation call.

This is a valid incremental approach but **Story 4.4 should explicitly state it modifies the VehiclesController#update_mileage action**, not just test the end result. Currently Story 4.4 ACs only verify the outcome without specifying the implementation change needed.

**Recommendation:** Add to Story 4.4 ACs: "And the `update_mileage` action calls `DueSoonCalculator.call` after saving."

---

#### 🟡 MINOR: Epic 1 & Epic 5 Titles Mix Technical and User Value

- Epic 1: "Project Foundation & User Authentication" — "Project Foundation" describes no user value
- Epic 5: "Dashboard & Production Readiness" — "Production Readiness" describes no user value

**Recommendation:** Cosmetic improvement. Rename to "User Authentication & App Foundation" and "Dashboard & Deployment" respectively. Low priority.

---

### Best Practices Compliance Checklist

| Epic | User Value | Independent | Stories Sized | No Forward Deps | Tables When Needed | Clear ACs | FR Traceable |
|---|---|---|---|---|---|---|---|
| Epic 1 | 🟡 Mixed | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Epic 2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Epic 3 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Epic 4 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| Epic 5 | 🟡 Mixed | ✓ | 🔴 ARC8 gap | ✓ | ✓ | ✓ | ✓ |

---

## Summary and Recommendations

### Overall Readiness Status

**🟠 NEEDS WORK** — The planning artifacts are of high quality with 100% FR coverage and well-written stories, but two material gaps must be addressed before implementation begins.

---

### Critical Issues Requiring Immediate Action

#### Issue 1 — Missing Story: Production Deployment / Kamal (ARC8 + ARC9) 🔴

Epic 5 claims ARC8 (Kamal deployment) coverage but no story exists. ARC9 (force_ssl) is also unclaimed in any story AC.

**Action:** Add Story 5.3 to Epic 5:
> "As a developer, I want the application deployed to a VPS via Kamal 2, so that users can access a production instance over HTTPS."
>
> ACs: Dockerfile present; `config/deploy.yml` configured; `config.force_ssl = true` in production; app accessible at production URL.

---

#### Issue 2 — Undefined `vehicles#show` Page 🟠

The vehicle detail view is the navigation hub of the entire app (mileage update, service history, due-soon status) but is never explicitly created in any story.

**Action:** Add to Story 2.1's acceptance criteria:
> "Given I click on a vehicle in my list, When the detail page loads, Then I see the vehicle's make, model, year, and current mileage, and a mileage update form."

This establishes the page in Epic 2 so Epics 4 and 5 can build on it.

---

### Recommended Next Steps

1. **Add Story 5.3** (Kamal deployment) to `epics.md` under Epic 5 to close the ARC8/ARC9 gap
2. **Add vehicles#show AC** to Story 2.1 explicitly establishing the detail page in Epic 2
3. **Add implementation note to Story 4.4** clarifying it modifies `VehiclesController#update_mileage` to call DueSoonCalculator
4. **(Optional)** Add `config.force_ssl = true` AC to Story 1.1 or Story 5.3 to ensure NFR7/ARC9 is explicitly implemented
5. **(Optional)** Rename Epic 1 and Epic 5 titles to be fully user-value-centric

### Final Note

This assessment identified **4 issues** across **3 categories** (missing story, undefined page, missing AC). The two material issues (Story 5.3 and vehicles#show AC) are quick fixes — likely under 30 minutes to add to `epics.md`. The 30 FRs are 100% covered, the architecture is solid, and the stories are well-written with proper BDD acceptance criteria. This project is in excellent shape and will be **READY** after addressing the two material issues.
