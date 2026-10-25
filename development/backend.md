# Backend development backlog

Version 0.1 · 25 October 2026

Read `README.md` for authoritative business rules, states, money/time conventions and acceptance criteria. Endpoint names below are proposed contracts to finalize in S0/refinement, not claims about the existing demo API. Implement with the chosen Python or Go stack after D-01; PostgreSQL is required. Each ticket includes OpenAPI examples, migrations, authorization, audit and targeted tests.

## Common backend requirements

- Enforce role/capability, location, ownership and coach assignment on every read/write/export. Derive authenticated identities server-side. Fail closed when a required policy has not been configured.
- Validate domain transitions in the service layer inside the transaction, not only request-field validation. Record actor, reason, timestamp, correlation and affected version.
- Use exact monetary arithmetic, immutable posted financial entries, historical price/rule snapshots and linked correction records. Do not delete operational history through entity cascades.
- Use idempotent commands for all duplicate-prone effects. Store command key, request digest and committed response/operation reference transactionally. Validate request ownership and location even on retries.
- Return optimistic versions and reject stale updates. Avoid lost updates, write skew and check-then-insert booking races.
- Transactional outbox for post-commit notifications. Retry delivery with deduplication; a successful business transaction must not be undone because push/email is unavailable.
- Add meaningful integration tests against PostgreSQL for concurrency and finance. SQLite/mocks alone cannot validate the allocation constraints.
- Define and test pagination/filter contracts, UTC instants, Asia/Almaty date boundaries, validation errors and privacy-safe logs. Index frequently filtered location/date/state/foreign-key columns.

## S0 — Service and contract foundation

### BE-00 Server skeleton, migrations and OpenAPI

Deliver modular application layout (identity, directory, scheduling, entitlements, finance, payroll, reporting), health/readiness checks, structured error handling, test database and migration runner. Publish OpenAPI and fixture payloads matching FE-00. Set up reproducible dependency installs and CI migrations/unit/integration tests.

Acceptance: clean setup starts through Compose; migrations apply on empty database; test environment is isolated; no default production password or hard-coded secret. Gate: D-01 and initial D-16 environment decisions.

## S1 — Identity, permissions and location scope

### BE-01 Authentication and customer identity

Proposed API: `POST/GET/DELETE /session`, `GET /me`; onboarding/recovery endpoints after D-02.

Store strong password hashes, revocable sessions and account state. Proposed browser session is secure HttpOnly cookie with CSRF protection for state-changing requests; define cookie/domain/CORS details with deployment. Rate-limit sign-in and recovery without revealing account existence. Establish user/customer and user/coach links separately from business profiles.

Customer linking requires verified ownership or authorized employee action. Never link an account to an existing customer solely because the entered phone number matches. Guardian authority must follow D-02; customer access to children is not automatic.

Acceptance: session revocation works across devices; blocked accounts cannot use prior sessions; role/customer IDs cannot be impersonated by request input; no secrets in logs. FE-01 dependency.

### BE-02 Employees and authorization

API: `/employees`, `/employees/{id}`, explicit block/archive and session-revoke commands; role/capability metadata for authorized management UI.

Implement Power User, Administrator, Operator, Coach and Customer presets with versioned explicit grants and location scope after D-04. Prevent removal of the final active Power User. Grant updates invalidate affected sessions or permission caches immediately. Employee archive preserves actor references.

Emit audit events from this sprint onward. Tests must include list/detail/mutation/export isolation and direct API attempts beyond UI-visible options. FE-02 dependency.

### BE-03 Locations, resources and closures

API: `/locations`, `/locations/{id}/resources`, `/resources/{id}`, `/resources/{id}/closures`.

Seed approved location identifiers for ACE/CSKA; import actual resource inventories only after validation. Model resource type, display order, indoor/outdoor metadata, active/archive state, operating hours and closures. Resource references must belong to the declared location. Reject invalid duration/end-before-start/out-of-hours input; apply midnight convention consistently.

Closure or archival affecting future allocations must follow approved policy and cannot silently cancel paid bookings. Reuse scheduling conflict service introduced in S3. FE-03 dependency; D-05/D-06.

## S2 — Directory and product rules

### BE-04 Customers, representatives and coaches

API: `/customers`, `/customers/{id}`, authorized archive; `/customers/{id}/history`; `/coaches`, `/coaches/{id}`; representative relationships after D-02/D-05.

Normalize phone/search fields while retaining original display value; implement agreed duplicate detection without assuming one phone equals one person. Store date of birth as date, consent with timestamp/source, and scoped notes. Participant/payer/representative are distinct roles. Customer merge is not included without a defined policy.

History aggregations must preserve historical references and conceal unauthorized finance/other-location fields. Archive blocks inappropriate new use while retaining history. Coach profile and login identity are separate, linked records. FE-04/05 dependency.

### BE-05 Services, tariffs and quoting

API: `/services`, `/services/{id}/versions`, `/membership-plans`, `POST /quotes`.

Use explicit product kind, pricing unit, currency, duration, effective dates, eligible resources/locations and reporting classification. Reject incompatible group/service combinations according to approved rules. Snapshot labels, unit prices, quantities and rule/version IDs on charges/bookings; new price versions never change history.

Structured membership lesson count/weekdays/term must not be inferred solely from names such as '8 lessons'. Quote returns canonical priced lines, total, currency, tariff version and validity policy; backend recalculates/verifies on submit. D-10 defines duration-based pricing and plan details. FE-06 and S3 dependency.

## S3 — Atomic reservation holds and confirmation

### BE-06 Availability and shared allocation engine

API: `GET /availability?location_id=...&date=...&resource_ids=...`, `GET /reservations` with ownership/capability scope, `GET /reservations/{id}`.

Return public availability without other customer identities, plus allowed durations and server time. Staff detail returns only permitted private fields. Availability is advisory; mutations recheck atomically.

Proposed PostgreSQL strategy:

1. Maintain a resource-allocation row per occupied interval and booking/session, with timezone-aware half-open range.
2. Lock stable resource rows in deterministic ID order for every operation that allocates, releases or moves those resources.
3. Inside the same transaction, deactivate logically expired pending holds for affected resources using database time, then inspect overlaps.
4. Use a PostgreSQL range exclusion constraint over active allocations as a second protection where feasible. Do not use a time-dependent `now()` predicate in an exclusion index to attempt automatic expiry.
5. Insert/update all requested allocations and reservation state atomically. All creation paths, including recurrence and group sessions, use this engine.

Availability queries ignore pending holds whose expiry has passed, independently of the sweeper. The allocation transaction removes their blocking state before inserting. Document exact schema/index/lock strategy during implementation and test it under concurrency.

Acceptance: AC-01/02/07/08; adjacent intervals allowed; same-time different courts allowed; partial resource allocation impossible; no deadlock from opposite resource selection order. FE-07/09 dependency.

### BE-07 Customer request and employee decision

API: `POST /reservations/requests`, `POST /reservations/{id}/confirm`, `POST /reservations/{id}/reject`; pending queue via scoped `GET /reservations?state=pending_confirmation`.

Request command validates customer eligibility, location, resource, time, quote and ownership; creates pending reservation/allocations with `hold_expires_at = accepted_at + 300 seconds`. Caller cannot set approval status, requester or expiry. Idempotent retries return the original request without extending the hold.

Confirm locks the reservation/allocation context and checks fresh database time after acquiring locks. It succeeds only if still pending and strictly before expiry. Confirmation has no payment requirement. Rejection atomically records actor/reason and releases allocations. Sweeper uses compatible locking/state checks; it cannot expire a confirmed booking.

Return server time, expiry, version, current state and financial summary if available. Publish audit/outbox events for requested/confirmed/rejected/expired transitions. Basic customer status is readable without push delivery.

Acceptance: AC-01–04, replay protection, confirm-versus-reject race, hold cleanup stopped, lost-response retry and unauthorized approval. FE-07/08/10 dependency. Pending-request withdrawal/limits are D-06, not implicit features.

## S4 — Cancellation, rescheduling and recurrence

### BE-08 Cancellation request and decision

API: `POST /reservations/{id}/cancellation-requests`, scoped `GET /cancellation-requests`, `POST /cancellation-requests/{id}/approve|reject`.

Submission transaction verifies authenticated customer ownership, confirmed state, no active request and `database_now <= starts_at - interval '2 hours'`. Store original booking version/start time, requester, submission timestamp and reason. Keep allocations unchanged.

Approval requires administrator/Power User location permission; revalidate request and booking version, write approved decision, transition reservation to canceled and release resources in one transaction. Rejection closes request while leaving confirmed state intact. Duplicate decisions must not duplicate release or events. Do not reverse payments or write off debt implicitly.

Decide post-start handling, rescheduling interaction and resubmission policy before implementing those paths (D-07). Tests: AC-05/06, exact cutoff, untrusted client time, concurrent admin decisions and another customer's request ID. FE-11 dependency.

### BE-09 Staff creation, moves and series

API: `POST /reservations` for authorized staff per D-06; `POST /reservations/{id}/reschedule-preview`, `POST /reservations/{id}/reschedule`; `POST /reservation-series/preview`, `POST /reservation-series`, explicit occurrence/future-series commands.

Generate occurrence instants from local calendar dates/weekdays in Asia/Almaty. Preview returns candidate dates, allocations, prices and specific conflicts. Final commit revalidates since preview is not a lock. Proposed default is atomic all-or-nothing commit; partial creation requires explicit D-08 approval and an explicit selected subset.

Move acquires old/new resource locks in consistent order and preserves old allocations if new ones cannot be acquired. Financial amendment and pending cancellation implications must use approved policies. Series changes preserve past history and distinguish occurrence overrides from future template changes.

Attendance/no-show/completion states are defined in D-07; no destructive booking deletion. Acceptance: AC-07/08 and failure rollback. FE-12 dependency.

## S5 — Charges, receipts, refunds and balances

### BE-10 Charges, payments and allocation

API: `/charges`, `/charges/{id}`, `POST /payments`, `GET /payments`, `GET /payments/{id}`, `GET /customers/{id}/balance`.

Charge contains versioned line snapshots and total. Payment is a receipt of money with customer/payer, amount, method, receipt reference, received_at and receiving employee. PaymentAllocation links receipts to charges; customer credit is explicit rather than a negative outstanding balance hidden in a form. D-09 defines when charges arise and how excess/partial receipts are allocated.

Transaction locks the relevant charge/balance, validates amount/method/scope, persists receipt/allocations and resulting membership activation when applicable, and records audit/outbox events. Membership activation in S6 reuses this transaction boundary. Preserve one committed effect under retries and simultaneous cashiers.

Unpaid reservation confirmation is independent. A receipt does not mark attendance or imply a bank integration. Financial fields in paid compositions are locked; amendments use explicit correction flows. No binary floats; exact decimal intermediate calculations.

Acceptance: AC-09; concurrent partial payments cannot over-allocate; total receipt equals allocations plus unapplied credit; a lost response can be recovered without duplicate receipt. FE-13 dependency.

### BE-11 Refunds, reversals and finance query

API: `POST /payments/{id}/refunds`, explicit correction/reversal commands, `GET /finance/summary` and filtered payment lists.

Maintain immutable original entries and linked correction records with reason/actor. Lock payment/refund context and prevent cumulative refunds exceeding approved refundable balance. Distinguish reversing an erroneous receipt from refunding actual received money; define effect on charge obligations/credit/entitlements via D-09/D-11.

Query received, refunded, net, debt and credits consistently. Booking canceled/archived state is descriptive and must not by itself remove a receipt from cash totals. A canceled payment/reversal does affect active financial totals. Use the same filtered dataset for count, totals and export; pagination does not alter aggregate totals.

Acceptance: AC-10; full 10,000-tenge refund yields zero net for that receipt, original survives, payment-method net totals agree; cancellation alone creates no refund. Test duplicate/refund race and over-refund rejection. FE-13 dependency.

## S6 — Groups, enrollment and memberships

### BE-12 Group timetable, session generation and enrollment

API: `/groups`, `/groups/{id}`, `/groups/{id}/schedule-preview`, `/groups/{id}/enrollments`, approved transfer commands, `/sessions`.

Group definition is independent of a service sale. Store coach, timetable version, color, resource assignments, capacity rules and active state. Generate bounded session occurrences idempotently; use uniqueness on group/timetable version/date as appropriate and allocation engine BE-06. Preview and commit detect conflicts; incomplete active schedules must follow agreed policy.

Enrollment locks capacity context so simultaneous final-seat claims cannot exceed the approved limit. Per-court maximum 12 is the baseline; multi-court participant distribution must be decided (D-12), not assumed to be simply 12 times resource count. Preserve effective enrollment dates and historical session rosters.

Acceptance: AC-08/12; no duplicate generated sessions; coach/resource conflicts follow D-08; archived group retains history. FE-14 dependency.

### BE-13 Membership entitlement lifecycle

API: `POST /memberships/preview`, `POST /memberships`, `GET /memberships`, `GET /memberships/{id}`, approved activate/renew/freeze/transfer/revoke commands.

Use versioned plans with explicit included lessons, term, start rules and eligible groups/locations. Separate purchase/charge/payment from active entitlement state. Activation produces the planned lesson calendar/entitlement ledger exactly once in the relevant payment transaction or an approved explicit activation command.

Enforce D-10/D-11 rules for partial payment, holidays/weekday generation, expiry, backdating, freezing and transfers. Derive used/remaining balance from ledger; do not maintain an independent editable customer paid-until flag as the primary truth. Adjustments preserve original entitlement history.

Acceptance: AC-09; exact approved session dates/count; renewal does not overwrite old membership; simultaneous activation cannot double credits. FE-15 dependency. Freeze/transfer rules are gates, not defaults to invent.

## S7 — Attendance and saved lessons

### BE-14 Session roster and attendance

API: `GET /coach/sessions`, `GET /sessions/{id}/roster`, `PUT /sessions/{id}/attendance/{participant_id}`, authorized correction command.

Resolve actor assignment, enrollment validity, membership eligibility and approved attendance state. Apply one entitlement consumption per participant/session, with unique business key plus transaction/idempotency protection. Correction appends compensating ledger entry and reason rather than deleting history.

Attendance and booking payment status remain separate. Insufficient entitlement/debt treatment follows D-11/D-12; server must not silently allow or reject on guessed policy. Roster excludes unrelated customers and unauthorized finance data.

Acceptance: AC-09/11; refresh, retry and concurrent marking deduct once; correction restores exactly the intended amount. FE-16 dependency.

### BE-15 Training cancellation and saved-lesson resolution

API: authorized `POST /sessions/{id}/cancel`, `GET /saved-lessons`, approved `POST /saved-lessons/{id}/redeem|resolve`.

Cancel group session atomically records cancellation, releases resource occupancy and creates one saved lesson for each eligible participant according to D-12. Ensure no double benefit: if a deduction already exists, compensate it or create a redeemable credit according to the approved ledger policy, never both accidentally. Payments are unchanged by session cancellation.

Redemption transaction validates ownership, expiry, destination eligibility/capacity, consumes credit once and links replacement session. Reversal/transfer rules require D-12. Emit notifications through outbox without duplicate credits on retries.

Acceptance: repeated cancellation/redemption is harmless; original session and reason preserved; concurrent redemption has one winner. FE-17 dependency.

## S8 — Reporting, earnings and payroll

### BE-16 Reports and Excel export

API: `/reports/finance`, `/reports/customer-metrics`, `POST /exports` and scoped export status/download if generation is asynchronous.

Reuse canonical finance query predicates and timezone boundaries. Distinguish gross receipts/refunds/net, charge debt and unapplied credit; define report date basis. Generate agreed Excel sample layout with matching totals, filters and formulas where required. Prevent formula injection from customer-entered text fields.

Export authorization is checked at request and download, scoped to actor/location; do not expose public permanent URLs for private exports. D-14 sample gates layout acceptance. Performance criteria from D-16 determine synchronous versus asynchronous generation.

Acceptance: AC-10/13; screen/export reconciliation across pagination, refunds, timezone boundaries and locations. FE-18 dependency.

### BE-17 Coach earnings calculation and statements

API: `/coach-statements`, `/coach-statements/{coach_id}/details`, statement exports and rule-version management limited to authorized users.

Demo reference: Baby Tennis 40%; Start/Junior and Amateur 30%; Sports 2/3 50%; Sports 4 80% of full group receipts. Single lessons use 30% after VAT extraction; individual sessions have VAT separated; rental/goods excluded. The demo shows 16% VAT. These are source observations pending numerical validation under D-13, not tax advice or automatic production constants.

Version rule applicability by date/category/location as agreed. Snapshot applied rule and contributor receipt allocation, coach, group and base. Never infer pay category from mutable free-text names. Support traceability and unclassified records requiring review. Partial receipts, refunds and substitutions require approved allocation rules.

Before implementation, agree worked numerical examples covering all seven demo statement categories, VAT extraction versus subtraction, rounding stage, combined line items and refunds. Use exact intermediate arithmetic; snapshot historical rules so later rate edits do not rewrite closed periods silently.

Acceptance: golden examples reproduce approved results; query/export totals agree; coach share calculation does not create an actual payout. FE-19 dependency.

### BE-18 Approved accruals and payroll payouts

API: `/payroll?coach_id=...&year=...`, `POST /payroll/accruals`, `POST /payroll/payouts`, explicit adjustments/reversals.

Keep computed earnings, approved accruals and recorded payouts separate. Proposed balance equation is approved accruals plus authorized adjustments minus payouts; negative means advance, subject to D-13 sign-off. Power User decisions carry period, amount, reason, actor and timestamp. Payout is an internal record, not an external bank transfer.

Idempotency and transaction locks protect payout/accrual commands; corrections preserve original entries. Do not silently recalculate an approved historical accrual after a refund: show difference and require the approved adjustment policy.

Acceptance: repeated request creates one payout; correct balance/advance; approval alone never sets paid. FE-20 dependency.

## S9 — Notifications, audit UI and release

### BE-19 Notifications and renewal reminders

API: `/notifications`, read command, authorized `/reminder-settings`, `/reminder-runs`.

Consume durable events from earlier sprints. Scope recipients and payloads by current permissions. Include reservation decisions/expiry and cancellation outcomes in customer in-app experience; external channels follow D-15. Payment notifications/renewal behavior starts from demo policy and must respect finance visibility.

Deduplicate by event + recipient + channel; renewal manual retries for the same customer/threshold/day must not spam. Store delivery attempts and failure state, retry with bounded backoff. Use current membership expiry to avoid stale renewal notices. Read receipts are actor-owned.

Acceptance: failed transport does not lose committed business events; retries produce one logical notification; no sensitive amounts to unauthorized coach/customer. FE-21 dependency.

### BE-20 Audit query and controls

API: scoped `GET /audit-events`, detail access for authorized reviewer.

Expose append-only events captured since S1 for identity/permissions, schedule, cancellation, membership/attendance, finance and payroll. Filter by actor/entity/action/date/location. Include reason and permitted before/after changes; redact credentials and session material. No public mutation/delete endpoint. Operational retention/access is D-16.

Acceptance: all critical accepted commands have an audit link; failed transactions cannot masquerade as committed changes; history remains after archive. FE-22 dependency.

### BE-21 Migration, recovery and release qualification

Build import tooling only after D-17 source/mapping approval. Use staging/import batch IDs, dry-run validation, duplicate handling, relationship checks and a reject report. Reconcile entity counts, allocations, payments/refunds, debts, membership balances and payroll totals. Do not automatically classify or delete demo transactions by heuristic.

With infrastructure team, execute backup/restore into a separate environment, verify migration rollback/recovery process and document measured outcomes. Run AC-01–15 and approved load targets. Provide OpenAPI, domain transition notes, operational runbook and owner handover. A passing UI smoke test alone is insufficient for release.
