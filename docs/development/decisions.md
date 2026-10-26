# Decisions and refinement gates

Version 0.1 · 25 October 2026

Confirmed: both ACE and CSKA; customer accounts; payroll following demo; Power User; five-minute customer hold and employee decision; unpaid confirmation; administrator-approved customer cancellation submitted at least two hours before start; no automatic refund on booking cancellation.

The items below are not approved rules. Resolve only the decisions needed for the next sprint, rather than asking the owner to settle everything at once. Suggested owners are business owner/Power User plus product analyst, with finance or engineering input as appropriate.

## Resolved

| ID | Decision | Resolved | Notes |
|---|---|---|---|
| D-01 | **Python.** FastAPI, SQLAlchemy 2.x, Alembic, psycopg 3, PostgreSQL. Session as a secure `HttpOnly` cookie with CSRF on state-changing requests. | 26 October 2026 | Rationale in `crm.backend/README.md`. The PostgreSQL locking and exclusion-constraint strategy in BE-06 is language-neutral and unchanged by this choice. Supported deployment environment still follows D-16. |

## Open

| ID | Decision needed | Blocks |
|---|---|---|
| D-02 | How customers receive accounts: employee invitation, self-registration or both; verification and recovery; linking an existing record without takeover; parent/child account management. | S1 production customer onboarding |
| D-03 | Customer pages beyond reservation scope: memberships, balances, receipts, profile changes, family records; what coaches may see about free courts. | Extra customer/coach pages |
| D-04 | Exact role defaults and delegated permissions: operator confirmation, administrator financial visibility, coach customer creation/cancellation/attendance, Power User delegation. | Each affected permission; baseline S1 |
| D-05 | Cross-location sharing of customer identity/history, tariffs, groups, membership validity, balances and payroll. Prevent data leakage until explicitly granted. | S2 model and cross-location use |
| D-06 | Staff-created reservations: immediate confirmation or approval; customer duration/advance-booking limits; active-hold limits; withdrawal of a pending request; quote validity and resource closures. | S3–S4 affected paths |
| D-07 | Cancellation requests: admin decision after cutoff/start; repeat request after rejection; rescheduling while cancellation pending; staff cancellation override; no-show and completion policies. Customer cutoff itself is already agreed. | S4 affected transitions |
| D-08 | Recurrence horizon; all-or-nothing versus explicitly accepted conflict-free subset; one/future-series edit semantics; multiple resources simultaneous or alternative; coach overlap rules. | S4 recurring; S6 timetable |
| D-09 | When a charge is created; canceled unpaid charge treatment; refund eligibility/amounts; partial allocation and overpayment use; split payment methods; price amendments/discounts and approval. | S5 finance policy |
| D-10 | Tariff list and structured pricing units; quantities versus time; membership lesson counts for Sports 2/3/4; schedule source when tariff weekdays disagree with group weekdays. | S2 tariff completion; S6 |
| D-11 | Membership activation on partial/full payment; start-date rules; term/expiry; one/multiple memberships; transfers and freezes; attendance allowed with debt; cancellation/refund after use. | S6 activation and entitlement |
| D-12 | Absence and deduction rules; who marks/corrects attendance; group cancellation eligibility; saved-lesson expiry, redemption, transfer and reversal; capacity across multiple courts. | S6 capacity; S7 |
| D-13 | Exact earnings examples, VAT extraction, percentages, rounding, partial payments, refunds, substitute coaches, effective dates; actual payout recording and adjustment rules. Demo formulas are the starting reference, not verified tax logic. | S8 calculations |
| D-14 | Supply original `Отчет 02.10.2026.xls` and any coach-statement sample; agree exact columns, formulas, date basis and totals. | S8 export acceptance |
| D-15 | Notification channels and delivery consent; whether customer outcomes need push/email/SMS or in-app only; renewal schedules/manual triggers; amounts visible to coaches. | S9 external delivery |
| D-16 | Expected users/data volume/concurrency, performance targets, backup RPO/RTO/retention, hosting/domain, monitoring and support ownership. | S0 environment sizing; S9 release |
| D-17 | Prototype source/database export access, real versus demo records, import mapping, cutover downtime and rollback approach. | S9 migration |
| D-18 | Fresh implementation on the new repositories versus audit and upgrade of the existing site. `../instructions.docx` §1 directs the developer to build on the existing site and preserve its data; `../intro.md` plans three new repositories on owner-local infrastructure. The specifications currently assume fresh implementation. Resolve explicitly rather than by inference, since the answer changes S0 scope, the D-17 migration approach, rollback requirements and the overall estimate. An upgrade additionally requires source-code, database and hosting audit access before estimation. | S0 scope; INF-06 cutover; D-17 |

## Proposed engineering decisions to ratify during S0

- One modular server with PostgreSQL; common allocation locking for every booking path.
- UTC instants with Asia/Almaty recurrence/report rules, half-open occupancy intervals.
- Exact money and versioned tariff/earnings snapshots.
- Versioned REST/OpenAPI commands, optimistic versions, idempotency keys and transactional outbox.
- Reservation and cancellation state machines from the master specification.
- Audit events are append-only and financial correction uses linked entries rather than destructive deletion.

These choices provide implementation consistency. They do not decide customer eligibility, pricing, refunds or access beyond the confirmed scope.

## Refinement output for every page/workflow

Record: actor; location/ownership scope; prerequisites; input fields and validation; normal sequence; result; error and concurrency cases; price/entitlement/resource effects; permission; event/audit; API example; acceptance scenario. Link each approved change to its date and affected ticket IDs.
