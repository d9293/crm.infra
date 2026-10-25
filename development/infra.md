# Infrastructure development backlog

Version 0.1 · 25 October 2026

Read `README.md` for authoritative business rules, money/time conventions, authorization model and acceptance criteria; §11 of that document defines the release responsibilities these tickets implement. Open policies are tracked in `decisions.md`. Ticket IDs below are proposed backlog items. Service names, image versions and file layouts are proposals to ratify in S0, not existing configuration.

The initial deployment target is the owner's local infrastructure (`../intro.md`). Public hosting, domain and TLS termination are therefore configured but not procured in S0; the hosting decision is D-16. Backend runtime and image depend on D-01 and are marked as such below. Whether this is a fresh deployment or a migration of the existing site is D-18 and changes INF-06 materially.

## Common infrastructure requirements

- PostgreSQL is the only authoritative store. No business or financial truth may live in container-local filesystems, browser storage or an in-memory cache. A rebuilt container must lose nothing but cache.
- Pin every dependency and image to an exact version. Reproducible builds are a prerequisite for the reconciliation evidence required in S9; a floating `latest` tag invalidates a restore drill.
- Secrets never appear in source, images, logs, CI output, compose files or handover documents. `.env.example` contains placeholder values and documentation only. Real `.env` files are git-ignored and never committed.
- All containers and the database run in UTC. `Asia/Almaty` is applied by the application for business display, report boundaries and recurrence expansion. Do not set a container timezone to compensate for application logic.
- Development, automated test and any demonstration database are separate databases with separate credentials. A test run must be incapable of writing to development data.
- Infrastructure changes that can destroy data — volume removal, database recreation, restore over a live database — require an explicit, documented, non-default command. No convenience script performs them implicitly.
- Every environment-affecting change is recorded in the repository, not applied by hand to a running host. An undocumented manual fix cannot be reproduced during the restore drill.

Not authorized by this specification: procuring production hosting or a domain, Kaspi or any payment-provider integration, fiscalization infrastructure, third-party analytics or error-reporting services that would transmit customer data outside owner-controlled infrastructure. Each requires a separate scope decision.

## S0 — Environment and pipeline foundation

### INF-00 Compose topology and environment template

Deliver a `docker-compose.yml` in `crm.infra` defining the agreed service set: `frontend`, `backend`, `postgres`, `worker` and a reverse proxy for routing and future TLS termination. Provide an override mechanism separating local development from a production-shaped run, so a developer workflow never silently becomes the deployment configuration.

Database requirements to settle in this ticket:

1. Agree the PostgreSQL major version and pin it. Version selection must account for the range-exclusion strategy in BE-06.
2. Enable the `btree_gist` extension through migration or initialization, since the proposed exclusion constraint combines scalar resource identity with a timezone-aware range. An exclusion constraint over `tstzrange` plus a scalar column cannot be created without it.
3. Persist data on a named volume with documented backup and restore paths. Do not bind-mount a developer working directory as the database data directory.
4. Configure connection limits and a pooling approach consistent with the concurrency and locking strategy in BE-06; defaults are a starting point, not a sizing decision.

Provide `.env.example` covering database credentials, application secrets, session and CSRF configuration, allowed origins, base URLs, business timezone and worker settings — placeholders only, with a comment per variable explaining its purpose and whether it is required. Document the migration runner as an explicit one-shot command rather than an implicit side effect of container start, so an operator can see what ran against which database.

Acceptance: a clean checkout starts through documented Compose commands on an empty volume; migrations apply successfully to an empty database; the test database is isolated and provably unreachable from the development configuration; no default or inherited production password exists anywhere in the repository; removing all containers and starting again preserves committed data. Gate: D-01 for the backend service definition and image; initial D-16 answers for resource sizing. Pairs with BE-00 and FE-00.

### INF-01 Continuous integration and dependency policy

Deliver a CI pipeline covering, per repository: dependency install from a lockfile, lint, typecheck, build, unit tests, and — for the backend — migration application against an empty PostgreSQL service plus the integration tests described in `backend.md`. Mocked or embedded databases do not satisfy the backend job; the allocation and concurrency constraints under test exist only in PostgreSQL.

Add a migration check that fails when model definitions and migration history diverge, and a check that the committed OpenAPI document matches the one the backend generates. Frontend type generation or contract validation runs against that committed document, so a drifted contract must break the build rather than surface as a runtime mismatch in S3.

Configure branch protection and a review requirement on each repository's default branch. Document the dependency update and vulnerability review cadence. Record the agreed repository and branch conventions so all three repositories behave identically.

Acceptance: a pull request that breaks types, lint, build, migrations or the contract fails before merge; the backend integration job runs against real PostgreSQL; a deliberately drifted OpenAPI document fails CI; no CI job logs a secret or a connection string containing credentials. Gate: D-01 for backend job content.

## S1 — Access hardening

### INF-02 Session, transport and bootstrap configuration

Configure the infrastructure half of BE-01 and BE-02. Supply session cookie configuration — `Secure`, `HttpOnly`, `SameSite`, domain and path — together with CORS allowed origins and the CSRF configuration the backend expects, as environment-driven values rather than code constants. Local development over plain HTTP must not require weakening the deployed configuration; document the two profiles explicitly.

Configure TLS termination and secure response headers at the proxy, with a documented certificate acquisition and renewal procedure to activate when a domain exists under D-16. Supply password hashing parameters as reviewed configuration with a documented basis, not an undocumented default. Provide the rate-limiting configuration supporting sign-in and recovery throttling, positioned so it cannot be bypassed by addressing the backend container directly.

Deliver a first Power User bootstrap procedure that requires an operator-supplied credential at run time and forces a change on first use. A seeded default administrator password must not exist in any repository, image or document.

Configure log redaction before S1 closes: passwords, session identifiers, CSRF tokens, recovery tokens and authorization headers are never written by any service. Verify this against actual emitted logs rather than intended behavior.

Acceptance: the deployed profile serves only over TLS with the agreed headers; cookies carry the agreed attributes; a direct request to the backend port bypasses neither authentication nor throttling; bootstrap produces exactly one Power User and no stored default credential; a sign-in attempt with a wrong password leaves no credential material in any log. Gate: D-02 for recovery endpoints; D-04 baseline for role presets. Pairs with BE-01 and BE-02.

## S3 — Scheduling reliability

### INF-03 Time integrity, worker operation and observability

Support the atomic hold mechanism in BE-06 and BE-07. Confirm that hold expiry is evaluated from database time, document that this is the authoritative clock, and ensure no service substitutes its own clock for an expiry decision. Configure host time synchronization regardless, since report boundaries, audit timestamps and operator-facing displays still depend on correct host time, and record how synchronization is verified.

Run the worker as its own service with a restart policy, a liveness signal and a documented concurrency limit. Confirm with the backend team that a stopped worker leaves correctness intact and affects only cleanup latency — AC-02 must pass with the worker deliberately stopped, and infrastructure must not be configured in a way that creates a hidden dependency on it. Prevent duplicate worker instances from multiplying scheduled work unless the implementation is proven idempotent under concurrency.

Expose operational signals: worker heartbeat and last successful sweep, count and age of logically expired holds still awaiting cleanup, unprocessed outbox depth and delivery failure count, database connection saturation, lock wait and deadlock counts, and request error rates. Record employee decision latency on reservation requests, since README §11 requires evidence on whether the five-minute response window is operationally viable; that measurement is a business input, not a performance metric.

Review index coverage with the backend team for the location, date, state and foreign-key columns identified in `backend.md`, and establish how slow queries are captured. Run a concurrency test against the Compose-provisioned database rather than a developer's local instance.

Acceptance: AC-02 passes with the worker stopped; stale-hold age and worker heartbeat are observable; no deadlock appears under the opposing-resource-order test from BE-06; duplicate worker instances do not duplicate committed effects; decision-latency figures are available for the D-16 review. Gate: D-16 for retention of operational data. Pairs with BE-06 and BE-07.

## S5 — Financial data protection

### INF-04 Backup, restore and financial-data safeguards

Implement the backup schedule, retention and access policy for financial data. Backups are consistent, verified on completion, restricted to a named set of operators, encrypted in transport and at rest where the chosen storage supports it, and stored so that loss of the application host does not lose them. Schedule, retention period and recovery objectives come from D-16; propose values and record the approved figures rather than assuming them.

Every backup run reports success or failure through the signals established in INF-03. A silent backup failure is a release blocker. Restore is exercised on a schedule, not only once at release — a backup never restored is not a backup.

Document and test the restore procedure into a separate environment, including a reconciliation step covering entity counts, payment and refund totals, outstanding debt, membership balances and payroll totals. This procedure is the mechanism AC-14 verifies and INF-06 re-runs at release.

Extend log redaction for finance: receipt references, amounts tied to identifiable customers, phone numbers and other personal data must not land in infrastructure logs or metrics labels. Confirm that an export artifact is never written to a path served publicly by the proxy.

Acceptance: a scheduled backup completes, reports its outcome and is restorable; a restore into a separate environment reconciles against the source on all listed totals; backup storage is inaccessible to an unprivileged account; a failed backup raises a visible signal; no customer-identifying data appears in infrastructure logs. Gate: D-16 for RPO, RTO, retention and storage location. Pairs with BE-10 and BE-11.

## S8 — Export delivery

### INF-05 Export artifact handling and asynchronous capacity

Support BE-16 report and Excel generation. Determine from the D-16 volume and performance answers whether generation is synchronous or requires a queued job; provision the latter only if the measured need exists, consistent with the README direction against unnecessary components.

Where artifacts are generated, store them outside any publicly served directory, apply an agreed retention and deletion policy, and ensure download passes through the application's authorization check at request and at download. No permanent unauthenticated URL may exist for a private export. Size generated artifacts against realistic report volumes so a large export does not exhaust container memory or disk.

Acceptance: an export is downloadable only by an authorized actor within the correct location scope; a direct path request to the artifact location is refused; expired artifacts are removed on the agreed schedule; a large export completes without exhausting container resources. Gate: D-14 for the sample layout; D-16 for volume and the synchronous-versus-asynchronous decision. Pairs with BE-16.

## S9 — Release qualification and handover

### INF-06 Migration rehearsal, restore drill and rollback

Provision a staging environment matching the deployment configuration, and rehearse the full cutover there before touching real data. Scope depends on D-18: a fresh deployment rehearses migration of approved imported records only, while an upgrade of the existing site additionally requires a verified snapshot of the current database and hosting before any change, plus a rollback path to it.

Execute, with the backend team, the sequence README §11 requires: signed-off migration mapping, dry run with a reject report, source snapshot, counts and financial and entitlement reconciliation, rollback and recovery procedure, deployment smoke test and restore drill. Record measured outcomes with timestamps — an asserted procedure is not evidence. Agree and document the cutover downtime window and the decision point at which rollback is chosen.

Rollback must be rehearsed, not merely written down, and must be exercised from the same artifacts an operator would actually have available. Import tooling runs only against an explicitly approved source and record list per D-17; no heuristic classifies or deletes records.

Acceptance: AC-14 passes with recorded figures; a rehearsed rollback returns the environment to its pre-cutover state; the smoke test runs against the deployed configuration rather than a developer machine; reconciliation differences are explained individually, not summarized as acceptable. Gate: D-17 for source access and mapping; D-18 for cutover approach. Pairs with BE-21.

### INF-07 Monitoring, alerting and operational runbook

Consolidate the signals from INF-03 and INF-04 into something the owner's operator can actually use. Define which conditions warrant an alert — service down, database unreachable, backup failed, outbox delivery stalled, disk approaching capacity, certificate near expiry — and where those alerts are delivered. Alert routing and support ownership are D-16; an alert with no recipient is not monitoring.

Write a runbook covering start, stop, restart, log inspection, migration application, backup, restore, certificate renewal, credential rotation and first-response steps for each alert condition. Target an operator who did not build the system. State explicitly which procedures are destructive and what must be captured before running them.

Acceptance: each defined alert condition has a tested trigger and a named recipient; an operator unfamiliar with the build completes start, backup and restore from the runbook alone; log inspection requires no source knowledge; certificate expiry is detected before it occurs. Gate: D-16 for monitoring and support ownership.

### INF-08 Handover package and access inventory

Assemble the handover README §11 requires: source repositories, environment setup instructions, migration and operational runbook, backup and restore instructions, monitoring instructions, and an access inventory listing every system, who holds credentials and how each is rotated.

The domain, hosting account, database access and service accounts are registered to the owner, not to a developer or contractor account. Transfer ownership rather than sharing access, and verify the owner can independently authenticate to each system after transfer. The owner must hold a working Power User account and be able to create another without developer assistance.

No production secret appears in any handover document. Secrets transfer through a separate channel and are rotated at handover, so no credential known during development remains valid afterward.

Acceptance: the owner authenticates independently to domain, hosting, database and application; credentials used during development no longer work; the access inventory names a holder for every system; the handover documents contain no secret material; a reader can rebuild the environment from the documents alone. Gate: D-16 for hosting and domain ownership.

## Sprint summary

| Ticket | Sprint | Depends on | Blocking gate |
|---|---|---|---|
| INF-00 Compose and environment template | S0 | BE-00, FE-00 | D-01, D-16 (initial) |
| INF-01 CI and dependency policy | S0 | BE-00, FE-00 | D-01 |
| INF-02 Session, transport and bootstrap | S1 | BE-01, BE-02 | D-02, D-04 |
| INF-03 Time, worker and observability | S3 | BE-06, BE-07 | D-16 |
| INF-04 Backup, restore and finance safeguards | S5 | BE-10, BE-11 | D-16 |
| INF-05 Export artifacts and async capacity | S8 | BE-16 | D-14, D-16 |
| INF-06 Migration, restore drill and rollback | S9 | BE-21 | D-17, D-18 |
| INF-07 Monitoring and runbook | S9 | INF-03, INF-04 | D-16 |
| INF-08 Handover and access inventory | S9 | All | D-16 |

D-16 gates five of nine tickets. Obtaining its answers early — expected users, data volume, concurrency, performance targets, backup RPO/RTO and retention, hosting, domain, monitoring and support ownership — unblocks more infrastructure work than any other single decision.
