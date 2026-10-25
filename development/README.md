# ACE and CSKA CRM development requirements

Version 0.1 · 25 October 2026 · Business baseline and proposed engineering plan

This specification defines the first release, its page inventory, sprint sequence, shared contracts and acceptance criteria. Frontend tasks are in `frontend.md`; backend tasks are in `backend.md`; infrastructure and release tasks are in `infra.md`; unresolved decisions are in `decisions.md`. It is ready for backlog refinement. Features affected by open business decisions must not be treated as implementation-ready until those decisions are resolved.

Visual and interaction requirements are in [UI and UX specification](ui-ux.md): product design tokens, role navigation, nine reusable layouts, all P01–P21 page layouts, booking/approval/cancellation journeys and sprint-level design acceptance.

## 1. Sources and authority

1. Explicit decisions in this conversation take precedence over the older business document and demo.
2. `../instructions.docx` supplies the business requirements and acceptance scenarios.
3. `../business-demo-review.md` records authenticated demo observations from 24 October 2026. The prototype is https://ace-tennis-crm.yellowoasis4.chatgpt.site/.
4. Engineering choices below are proposals for implementation, not additional owner-approved business rules. Demo financial formulas require numerical reconciliation before production use.

The review was of the Owner interface and forms. It did not prove server authorization, concurrent booking protection, refund handling or backup recovery. Customer self-service is new scope relative to the demo. No credentials or personal demo records are included in these deliverables.

## 2. Confirmed first-release requirements

| ID | Requirement | Source |
|---|---|---|
| BR-01 | Support ACE and CSKA, with employee access restricted by assigned locations. | Conversation; demo |
| BR-02 | Power User is the highest authority; administrators, operators, coaches and customers have restricted capabilities. | Conversation |
| BR-03 | Customer accounts are included. Confirmed customer scope is availability, reservation requests, own reservation status and cancellation requests; other customer pages remain undecided. | Conversation |
| BR-04 | Customer reservation requests immediately hold the requested court/time for five minutes pending employee approval. | Conversation |
| BR-05 | Employee confirmation within the hold confirms the reservation. Rejection or expiry releases the slot. Expired requests cannot be confirmed. | Conversation |
| BR-06 | Confirmation does not require payment. Reservation status and financial status are separate. | Conversation |
| BR-07 | Customers may request cancellation at least two hours before the reservation starts. Administrator approval is required. | Conversation |
| BR-08 | A pending cancellation keeps the slot reserved. Approval cancels and releases it; rejection preserves the confirmed booking. The cutoff applies to submission, including exactly two hours before start. | Conversation |
| BR-09 | Booking cancellation does not automatically refund money. | Conversation; demo |
| BR-10 | Include coach earnings calculations, owner/Power User approved accruals, payouts and balances as separate concepts, following the demo. | Conversation; demo |
| BR-11 | Russian interface, tenge, Asia/Almaty business timezone, light/dark themes and desktop/tablet/phone support. | Business document |
| BR-12 | Court hours 07:00–00:00, support 90-minute sessions and next-date midnight end times; recurring bookings must show conflicts before saving. | Business document |
| BR-13 | Groups have coaches, timetable, resources, participants and consistent colors. Default capacity is at most 12 per court; overcapacity is blocked. Multi-court allocation needs clarification. | Business document |
| BR-14 | Keep bookings, charges, receipts, refunds, memberships and attendance as separate linked records. Preserve history and use exact monetary arithmetic. | Business document |
| BR-15 | Payment and attendance retries must not duplicate effects; server stores shared data and enforces permissions. | Business document |
| BR-16 | Financial reports and exports must reconcile; archives preserve history; tested backups and restore instructions are required. | Business document |

Not authorized as part of this specification: automated bank charging, Kaspi API integration, fiscalization, public self-registration, customer access to other people's records, new marketing channels, or automatic financial write-offs. These need separate scope decisions, not implementation by inference.

## 3. Architecture and ownership

- `crm.frontend`: React + Vite + TypeScript. Staff and customer interfaces may share components but must have separate navigation and data scopes. TypeScript is the default for new application code.
- `crm.backend`: server API and domain logic; Python versus Go is still an owner/team decision. Requirements and contracts are language-neutral. Do not scaffold a framework until D-01 is resolved.
- `crm.infra`: Docker Compose, routing/TLS configuration, environment templates, migrations/run procedures, backups, restore and deployment documentation.
- PostgreSQL is the authoritative persistent store. Browser storage is only for harmless preferences and transient drafts, not financial or booking truth.
- Proposed architecture: one modular backend, one PostgreSQL database, web frontend and a background worker. Do not introduce microservices or a message broker without a demonstrated need.
- Proposed role of the worker: hold cleanup, reliable notification delivery and scheduled operational jobs. Expiry correctness must never depend on the worker running on time.
- API contract is versioned OpenAPI under the backend repository; frontend types/client are generated or validated against that contract. Each sprint begins with contract examples agreed by both teams.

## 4. Page inventory

Routes are proposed. A form/drawer may be part of a parent page; a page entry does not imply an independent service.

| Page | Audience | Proposed route | Sprint |
|---|---|---|---|
| P01 Sign in and account access | All | `/login`, `/account` | S1 |
| P02 Employees and permissions | Power User | `/staff/employees` | S1 |
| P03 Locations and resources | Authorized staff | `/staff/locations`, `/staff/resources` | S1 |
| P04 Customers and customer detail | Authorized staff | `/staff/customers`, `/staff/customers/:id` | S2 |
| P05 Coaches and coach detail | Authorized staff | `/staff/coaches` | S2 |
| P06 Services and tariff versions | Authorized staff | `/staff/services` | S2 |
| P07 Customer availability and request form | Customer | `/customer/availability` | S3 |
| P08 My reservations and detail | Customer | `/customer/reservations`, `/customer/reservations/:id` | S3–S4 |
| P09 Staff schedule and booking detail | Authorized staff/limited coach | `/staff/schedule` | S3–S4 |
| P10 Reservation approval queue | Authorized employees | `/staff/reservation-requests` | S3 |
| P11 Cancellation approval queue | Administrator, Power User | `/staff/cancellation-requests` | S4 |
| P12 Finance and payment detail | Finance-authorized staff | `/staff/finance` | S5 |
| P13 Groups and enrollment | Authorized staff | `/staff/groups`, `/staff/groups/:id` | S6 |
| P14 Memberships and membership detail | Authorized staff | `/staff/memberships`, `/staff/memberships/:id` | S6 |
| P15 Coach schedule and session roster | Coach/authorized staff | `/coach/schedule`, `/coach/sessions/:id` | S7 |
| P16 Saved lessons and resolution | Authorized staff/coach per policy | `/staff/saved-lessons` | S7 |
| P17 Dashboard and financial exports | Authorized staff | `/staff/reports` | S8 |
| P18 Coach earnings statements | Power User/authorized finance | `/staff/coach-statements` | S8 |
| P19 Coach payroll | Power User | `/staff/payroll` | S8 |
| P20 Notifications and reminder settings | Scoped users/authorized staff | `/notifications`, `/staff/reminders` | S9 |
| P21 Audit history | Power User/authorized reviewer | `/staff/audit` | S9 |

Customer membership, payment-history, profile-management and representative-account pages are not committed pages yet. Their scope is D-03. Minimal customer booking outcomes are visible on P08 even before S9 notification channels.

## 5. Sprint plan

Proposed planning cadence is two weeks per sprint with a shorter setup sprint, subject to staffing and refinement. This is a sequence, not an estimate or delivery-date commitment. Split large sprints by complete workflow if capacity is insufficient. Both teams work on the same workflow in the same sprint.

| Sprint | Deliverable | Pages | Dependencies and gate |
|---|---|---|---|
| S0 | Contract, project skeleton and local environment | Shell only | Decide backend language; establish shared contracts, CI and migrations |
| S1 | Secure access for both locations | P01–P03 | S0; customer account onboarding policy D-02 |
| S2 | Customers, coaches and service catalog | P04–P06 | S1; identity, representative and tariff decisions |
| S3 | Customer request → five-minute hold → employee confirmation | P07–P10 | S1–S2; basic duration/pricing rules; no payment dependency |
| S4 | Cancellation approval and reservation lifecycle | P08–P11 | S3; staff booking/override, recurrence and late-cancellation decisions |
| S5 | Reliable receipts, balances, refunds and finance | P12; finance panels in P04/P09 | S2–S4; charge timing/refund/allocation decisions |
| S6 | Group enrollment and membership activation | P13–P14 | S2–S5; approved membership policy table |
| S7 | Session attendance and saved lessons | P15–P16 | S6; deduction, absence, cancellation and redemption policies |
| S8 | Reports, coach statements and payroll | P17–P19 | S5–S7; report sample and reconciled earnings formulas |
| S9 | Notifications, audit UI and release preparation | P20–P21 | Earlier sprints; migration evidence, restore test and end-to-end acceptance |

Audit event capture begins in S1, not S9. Payment/booking event publication begins with the corresponding workflow. S9 supplies the complete management UI and delivery channels.

## 6. Shared state and time contracts

### Reservation state

`pending_confirmation → confirmed | rejected | expired`

`confirmed → canceled` only through an authorized staff action or an approved cancellation request. Completion/attendance is separate from approval state; paid/unpaid is never a reservation state. Staff direct-create behavior is D-06.

Persist `requested_at`, `hold_expires_at`, `starts_at`, `ends_at`, `location_id`, resource allocations, customer, requester, decision actor/time, version and audit references. Hold expiry is server request-acceptance time + 300 seconds. Client countdown is informational.

- Confirmation is valid only while server time is strictly before `hold_expires_at`.
- At exactly the expiry instant the hold is inactive, even if its stored status has not yet been swept to expired.
- Confirm and expire operations must serialize; only one wins.
- Availability, requests, staff edits and group scheduling must use the same allocation/conflict mechanism.
- Intervals use `[start, end)`: 10:00–11:00 and 11:00–12:00 do not conflict.
- Server rejects any request that overlaps a confirmed allocation or unexpired hold. A failed multi-resource request must leave no partial allocation.
- A stale client must receive a conflict response, refreshed state and a clear retry option. It must never revive an expired request.

### Cancellation state

Separate record: `pending → approved | rejected`. While pending, the reservation remains confirmed and occupies resources.

- Customer can request cancellation only for their own confirmed reservation and when `server_now <= starts_at - 2 hours`.
- Enforce the rule on the server even if the customer opened the form before the cutoff.
- Permit at most one active cancellation request per reservation; duplicate retries return the existing result.
- Approval atomically records the decision, marks the reservation canceled and releases all allocations. Rejection records the decision and leaves the reservation intact.
- Approval does not mutate payments, charge obligations or payroll implicitly. Financial consequences are governed by the explicit policy in D-09.
- Whether an administrator may decide after the start time, whether customers can resubmit after rejection and how pending requests interact with rescheduling are D-07. Do not invent a second timeout.

### Time and money

- Persist instants with timezone-aware database types; API uses ISO 8601 timestamps with offset/UTC. Use `Asia/Almaty` for business display, report boundaries and recurrence expansion, not the workstation timezone.
- End at local 00:00 is the next calendar date. Date-only birth dates and tariff dates must not shift on timezone conversion.
- Monetary API values: integer minor units, currency `KZT`. Display tenge. Percent/tax calculations use exact decimal arithmetic and an explicit rounding rule; no binary floating-point money.
- Receipt period and session/service period are distinct filters and must be labeled distinctly.

## 7. Proposed authorization model

Role presets plus explicit grants, constrained by location and record ownership. Detailed defaults require D-04; absence of a grant means denial. UI hiding does not enforce authorization.

| Capability | Intended scope |
|---|---|
| `employees.manage`, `permissions.manage`, `locations.manage` | Power User |
| `resources.manage`, `services.manage`, `customers.manage`, `groups.manage` | Explicit employee grants |
| `reservations.request`, `reservations.read_own`, `cancellations.request_own` | Customer linked to their own customer identity |
| `reservations.read`, `reservations.create`, `reservations.edit`, `reservations.confirm`, `reservations.reject` | Employee grants and assigned location |
| `cancellations.decide` | Administrator/Power User and allowed location |
| `sessions.read_own`, `rosters.read_own` | Coach assignment; financial fields excluded unless separately granted |
| `attendance.manage`, `sessions.cancel`, `saved_lessons.resolve` | Explicit grants; coach policy D-04/D-12 |
| `payments.receive`, `finance.read`, `refunds.issue`, `reports.export` | Separate finance grants; sensitive corrections default to Power User |
| `payroll.approve`, `payroll.record_payout`, `audit.read` | Power User; delegation requires explicit policy |

Protect list, detail, mutations and exports equally. Customers must never see another customer's identity in availability responses. Blocked users lose sessions and cannot regain access with old credentials/tokens. Prevent accidental removal of the last active Power User.

## 8. Shared API conventions

Base `/api/v1`. Server-derived identity determines requester and permissions; never trust client-supplied role or customer ownership. Location is explicit for location-scoped calls and is checked server-side.

- List endpoints use documented pagination, stable ordering and filters. Summary totals cover all matching records, not only the current page.
- Detail/mutation responses include IDs, state, version and timestamps. Return `server_time` and `hold_expires_at` for holds.
- Use `Idempotency-Key` on reservation requests, financial commands, membership activation and attendance commands. Bind keys to actor + operation + request digest. Reusing a key with different input is a conflict.
- Use version/`If-Match` on mutable records. Concurrent stale updates fail instead of silently overwriting.
- Error shape: `{ code, message, field_errors, current_version?, correlation_id }`. No stack traces or personal data leakage.
- Suggested codes: `SLOT_UNAVAILABLE`, `HOLD_EXPIRED`, `CANCELLATION_CUTOFF_PASSED`, `INVALID_TRANSITION`, `VERSION_CONFLICT`, `CAPACITY_EXCEEDED`, `PAYMENT_ALREADY_APPLIED`, `REFUND_LIMIT_EXCEEDED`.
- Statuses: 401 unauthenticated; 403 forbidden (or 404 consistently for concealed ownership); 409 conflict/state/version; 422 invalid fields. Document exact response per operation in OpenAPI.
- Proposed customer request: `POST /reservations/requests` with location, resource IDs, start/end and selected offer/version. The server resolves customer identity, price and eligibility. Response includes reservation ID, pending state, expiry and price snapshot.
- Financial writes return the committed operation and recalculated balances in one consistent response; notification delivery failure must not roll back a committed payment.

## 9. Data model boundaries

| Domain | Main records |
|---|---|
| Identity | User, Session, Role, PermissionGrant, UserLocation, UserCustomerLink, CoachUserLink |
| Directory | Location, Resource, OpeningHours, Closure, Customer, RepresentativeRelationship, Coach |
| Catalog | Service, TariffVersion, MembershipPlanVersion, EarningsRuleVersion |
| Scheduling | Reservation, ResourceAllocation, RecurrenceSeries, CancellationRequest, Group, Enrollment, SessionOccurrence |
| Entitlements | Membership, MembershipLesson/EntitlementLedger, Attendance, SavedLesson, SavedLessonResolution |
| Finance | Charge, ChargeLine, Payment, PaymentAllocation, Refund/Reversal, CustomerCredit |
| Payroll | EarningsEntry, ApprovedAccrual, PayrollPayout, PayrollAdjustment |
| Operations | AuditEvent, OutboxEvent, Notification, DeliveryAttempt, ImportBatch |

These are conceptual boundaries, not a mandatory table-per-name design. Stored references and immutable snapshots preserve historical descriptions, prices and formulas when catalogs change. Financial records and used entitlements must not disappear through cascading deletion.

## 10. Cross-team definition of done

Each workflow has approved business rules, OpenAPI examples, frontend states, server validations, authorization tests, migrations and end-to-end acceptance. Include loading, empty, validation, expired-session, permission, network-failure and conflict states. Refresh/retry must not duplicate effects or lose a valid user draft unnecessarily.

Required targeted acceptance suite:

| Test | Expected result |
|---|---|
| AC-01 Two customers request the same slot concurrently | One active hold; other gets conflict; no partial writes |
| AC-02 No employee action for five minutes | Slot available at expiry even with cleanup worker stopped |
| AC-03 Confirmation races with expiry | Before expiry confirmation may win; at/after expiry cannot confirm; one final outcome |
| AC-04 Confirm unpaid reservation | Remains reserved; independent unpaid balance shown |
| AC-05 Request cancellation for 15:00 | 13:00 accepted; 13:00:01 rejected by server |
| AC-06 Pending cancellation and admin decision | Slot held while pending; released once on approval; retained on rejection; no automatic refund |
| AC-07 09:00–10:30 and 23:00–00:00 | Correct durations, next-date midnight and stable display after reload |
| AC-08 Recurring multi-resource conflict | Exact conflicting dates/resources reported; no silent skips or partial series |
| AC-09 Duplicate payment/membership/attendance requests | One financial operation, one activation and one deduction respectively |
| AC-10 Reversal/full refund of 10,000 tenge | Correct net receipt and method totals everywhere, original transaction retained |
| AC-11 Access boundaries | Customer A cannot access B; coach sees assigned scope; ACE-only employee cannot access CSKA, including exports |
| AC-12 Group capacity | Concurrent final-seat enrollment never exceeds approved per-court capacity |
| AC-13 Reports and payroll | Screen/export reconcile; historical formula unchanged by tariff edits; earnings are not automatically paid |
| AC-14 Recovery | Backup restored to separate environment; counts and financial totals reconciled |
| AC-15 Responsive workflow | Customer booking, admin decision and payment forms usable on phone/tablet/desktop in both themes |

## 11. Infrastructure and release responsibilities

Decomposed into tickets INF-00–INF-08 in [infrastructure backlog](infra.md); the summary below remains the authoritative statement of intent.

- S0: Compose for frontend/backend/PostgreSQL/worker; pinned dependency versions, `.env.example` with placeholders, separate development/test databases, CI build/typecheck/backend checks and migration checks.
- S1: protected session configuration, password hashing, login throttling, secure headers/TLS at deployment, first Power User bootstrap, no credentials in source or logs.
- S3: clock synchronization, indexes/transaction strategy, worker readiness and metrics for stale holds. Monitor decision latency to evaluate whether the five-minute employee response window is operationally viable.
- S5: database backup schedule, restricted backup access, encrypted transport/storage where supported, tested financial invariants and log redaction.
- S9: signed-off migration mapping, dry run, source snapshot, counts and financial/entitlement reconciliation, rollback/recovery procedure, deployment smoke test and restore drill. Import demo data only from an explicitly approved source and record list.
- Handover: source repos, environment setup, migration/runbook, backup/restore instructions, monitoring instructions, owner-controlled accounts/domain and access inventory. Never embed production secrets in handover documents.

Unresolved business policies and missing report/source artifacts are tracked in `decisions.md`. They are sprint-entry gates for affected features, not reasons to stop independent foundation work.
