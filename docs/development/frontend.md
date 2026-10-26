# Frontend development backlog

Version 0.1 · 25 October 2026

Read `README.md` for confirmed rules, API conventions, page IDs, sprint order and acceptance tests. Open policies are tracked in `decisions.md`. Ticket IDs below are proposed backlog items. Each ticket includes contract integration and targeted UI tests; do not close a ticket using only mocked data.

Use [UI and UX specification](ui-ux.md) as the visual/interaction contract. Every frontend ticket must apply its assigned page template, semantic tokens, responsive layout, state patterns and relevant UX-01–10 checks. FE-00 includes token styles, staff/customer/coach shells and a component state gallery; each later ticket includes wide/compact design review before acceptance. The demo's appearance is a reference, not a pixel-copy requirement.

## Common frontend requirements

- React, Vite and TypeScript; staff and customer navigation separated. Russian labels, KZT formatting, light/dark themes and Asia/Almaty dates.
- Proposed shared components: location selector, accessible date/time inputs, searchable customer picker, status badge, money input, confirmation/reason dialog, paginated table, resource calendar, empty/error state and permission-aware action.
- Use one contract-aware API client. Handle expired sessions, validation errors, conflicts, timeouts and safe retries consistently. Never retry a payment with a new idempotency key merely because its response was lost.
- Do not store session credentials in browser-readable persistent storage if using the proposed secure-cookie session approach. Backend owns authorization and calculations.
- All forms need labels, keyboard access, focus management, readable errors, disabled submission while in flight and preserved input after recoverable failure. Statuses must have text rather than color alone.
- No desktop-only completion path: calendar alternative/list view on narrow screens; no clipped save buttons or obscured modal footers. Test core flows on approximately 360 px, tablet and desktop widths.
- Query state must be partitioned by authenticated user and location. Clear/reload protected caches on logout, scope changes and permission changes.
- Permission checks control visible actions; every API denial must still be handled. Do not display private fields merely because they exist in a response; API should omit unauthorized fields.
- Record IDs and business-state changes come from committed server responses. No optimistic confirmation of reservations, payments, refunds or attendance deductions.

## S0 — Application and contract foundation

### FE-00 Shell and integration foundation

Deliver route layout, lint/typecheck/build scripts, reusable form/table primitives, localization/date/money utilities and API client scaffolding. Set up development environment without committing secrets. Add representative contract fixtures for success, validation, forbidden and conflict responses. Use fixtures only while backend endpoint is being completed.

Acceptance: application builds from documented commands; failed API requests show useful errors; CI verifies types/build; no business records seeded in browser storage. Depends on BE-00 and shared S0 decisions.

## S1 — Access, employees and resources

### FE-01 P01 Sign in and account access

Fields: account identifier and password; show generic invalid-login error, throttling feedback and session expiry. Load current user, capabilities and allowed locations after sign-in. Customer lands in customer navigation; coach in coach navigation; staff in assigned staff area. First-use/reset/recovery flows follow D-02 and must be designed before implementation, not guessed from the demo.

API: session create/read/delete and current-user contract from BE-01.

Acceptance: protected routes cannot be used logged out; revoked access clears protected views; refresh restores a valid session; customer cannot navigate into staff data. A blocked login has no misleading success state.

### FE-02 P02 Employees and permissions

Employee list with name, role, active/blocked access and location assignments. Detail form shows role preset and explicit capability grants. Restrict security-sensitive actions to authorized Power User. Explain that blocking/changing access ends sessions. Prevent saving an invalid last-Power-User change based on server feedback. Do not provide a hard-delete employee action where history exists.

API: BE-02 employee list/detail/create/update/archive/session revocation.

Acceptance: ACE-only assignments are reflected in navigation; unauthorized mutation receives visible denial; stale employee edits display version-conflict feedback. Exact preset defaults are D-04.

### FE-03 P03 Locations and resources

Location list includes ACE and CSKA. Resource fields: name, type, indoor/outdoor classification where applicable, display order, hours, active/archive state and approved capacity settings. Show closures on a timeline/list and explain conflicts returned by the server. Hide unsupported types from customer booking until their scope is agreed.

Acceptance: changing location switches all dependent lists; archiving preserves history; edits that affect existing reservations show actionable server feedback. Depends on BE-03 and D-05/D-06.

## S2 — Customer, coach and catalog pages

### FE-04 P04 Customers and detail

Search/paginate by allowed name/phone fields. Create/edit name, phone, birth date, notes and consent; display representative relationships using the agreed D-02/D-05 identity policy. Sections: profile, bookings, group enrollment, memberships and finance. Later-sprint sections should be hidden or explicitly unavailable until integrated, not show invented zero balances.

Membership status must use the server's derived entitlement fields once S6 is available; avoid an independent editable paid-until date that contradicts payment history. Archive with permission, preserving linked history. Do not reveal customer contacts in public/customer availability.

Acceptance: duplicate-customer feedback follows server matching policy; date of birth never shifts; customer detail is access-scoped; history remains after archival. API: BE-04.

### FE-05 P05 Coaches

List/detail with contact data, active state, locations and associated employee account if authorized to see it. Link to assigned groups and schedule; use a distinct access-management flow rather than conflating coach business profile with login account.

Acceptance: archive preserves past sessions/payroll; staff without coach-management rights can only view allowed information. API: BE-04.

### FE-06 P06 Services and tariff versions

Fields: service kind, name, pricing unit, amount, duration where applicable, category, reporting classification, eligible locations and effective dates. Membership plans expose structured session counts/term only after D-10/D-11. Show version history and explain that edits do not change past transactions.

Acceptance: cannot silently sell a membership as rental due to ambiguous category; monetary inputs validate precision; archived items are absent from new sales but visible historically. API: BE-05.

## S3 — Customer reservation and employee confirmation

### FE-07 P07 Availability and customer request

Flow: choose ACE/CSKA → date → resource → start/end or supported duration → server quote/summary → submit. Only show actual availability; no names or private booking details of other customers. Customer/requester identity comes from the session. Submit once with a stable idempotency key.

After success show pending status, selected slot, server expiry and countdown. Compute countdown from `server_time` and expiry, compensate for elapsed time, and refresh on focus/reconnect. A local countdown reaching zero triggers server refresh; it must not invent a confirmed/canceled result. Server conflict replaces the stale availability and preserves safe selections.

Acceptance: AC-01–03; double click creates one request; lost response can be recovered; disabled browser tab or device clock skew does not extend the hold. API: BE-06/BE-07.

### FE-08 P08 My reservations and detail

Own records only, with location/date/status filters. Show court, time, request state, hold expiry/decision and independent financial summary when S5 is ready. Expired/rejected requests remain understandable historical entries, not occupied bookings. Customer can see confirmation outcome without requiring notification delivery.

Acceptance: reload and a second device show the same server state; opening another customer's ID returns access denial; an expired request cannot be presented as confirmable. Customer withdrawal before approval is not included until D-06 is settled.

### FE-09 P09 Staff schedule

Daily resource columns for permitted location, time range 07:00–00:00 and distinct pending-hold/confirmed/session indicators. Show start/end and occupancy without depending on color alone. Open booking details; display version and permitted actions through the API capability contract. Support next-day midnight and 90-minute intervals.

Acceptance: a new hold appears across staff views; expired holds disappear as blockers on refresh; 09:00–10:30 and 23:00–00:00 display correctly; scope is enforced across location changes. Staff direct booking is FE-12/D-06, not assumed here.

### FE-10 P10 Reservation approval queue

Filter by location/date/request state; default actionable pending requests sorted by expiry. Detail shows customer, slot, price snapshot and seconds remaining. Employee may confirm or reject with authorized action; handle simultaneous decisions and stale versions. Expired rows lose decision actions after server refresh.

Acceptance: confirmation of an unpaid request succeeds; a second decision shows the final server state; expiry racing with a click produces an understandable result. API: BE-07. No mock-only completion.

## S4 — Cancellation and scheduling lifecycle

### FE-11 P08/P11 Customer cancellation and administrator queue

On a confirmed customer booking, show request-cancellation action until the server-derived two-hour cutoff. Present cutoff in local business time and explain administrator approval; do not imply cancellation is immediate. Form supports a reason/comment according to agreed validation.

Pending state says the court remains reserved. Administrator queue shows request time, booking start, customer, reason, payment summary if permitted, and approve/reject actions. Approval confirmation explicitly states that refund is separate. Show outcome in customer detail; do not let stale state submit duplicate active requests.

Acceptance: AC-05–06; 15:00 booking accepts 13:00 and rejects 13:00:01; API denial works when the form was opened before cutoff. Post-start decisions/repeated requests/rescheduling interaction are D-07. API: BE-08.

### FE-12 P09 Staff booking, rescheduling and recurrence

Support authorized customer selection, coach, resources, line items, start/end, notes and approved direct-booking policy. Keep sale-without-resource entry distinct from occupying a court. Recurrence editor supplies selected weekdays and end date; preview lists every affected date and each conflict. One-occurrence/future-series choices are explicit and never silently skip conflicts.

Reschedule preview shows both old and new allocation, changed price if any and affected cancellation requests. No mutation until the server commits. Handle mid-preview conflicts on final submit.

Acceptance: AC-07–08; failed move preserves original reservation; unsupported options remain unavailable until D-06–D-09 are resolved. API: BE-09.

## S5 — Finance

### FE-13 P12 Finance and payment panel

List filters: location, receipt date range, customer/group, service, receipt number, receiving staff, payment method, transaction status and linked booking status. Display received/refunded/net separately, debts/credits where applicable and totals for all matches, not the page.

Payment form: charge/customer context, amount, method, optional receipt reference and comment. Show current due, allocation and prospective balance. Confirmation does not imply online bank transfer. Preserve idempotency key through retry and recover an uncertain outcome before offering another payment.

Refund/reversal dialog shows original transaction, available refundable amount, reason and permission; separate it from booking cancellation and archive. Do not expose a destructive Delete transaction action. Read-only history shows original and linked corrections.

Acceptance: AC-09–10; payment retry has one effect; canceled booking can still show retained payment; catalog edits cannot rewrite a paid composition; all screens use returned authoritative balances. API: BE-10/BE-11. D-09 gates financial policy.

## S6 — Groups and memberships

### FE-14 P13 Groups, timetable and enrollment

Group form: name, coach, weekdays, start/end, assigned resources, capacity/allocation, color and active state. Participants tab contains enrollment status and membership eligibility; do not require creating a service just to create a group. Validate incomplete timetable activation with server rules.

Provide schedule preview/conflicts and enrollment capacity feedback. Transfers must expose their effective date and entitlement consequences after D-11/D-12. Color persists consistently in list/calendar and both themes.

Acceptance: concurrent final-seat enrollment shows conflict correctly; no silent session creation gaps; past rosters do not change when membership is edited. API: BE-12.

### FE-15 P14 Membership issuance and detail

Issue from customer or membership list: customer/participant, group if required, versioned plan, start date, expected lessons, expiry and price. Server preview shows generated dates and activation prerequisites. Receive payment through the common finance component, never a second payment implementation.

Detail shows status, entitlement ledger, used/remaining lessons, expiry, payments and adjustments. Freeze, renew, transfer and revoke actions must have approved policies and server previews. Do not provide fake functionality for policies still unresolved.

Acceptance: retry cannot issue two memberships; exact expected session count/weekday calendar is shown; prior membership history survives renewal. API: BE-13; D-10/D-11 are entry gates.

## S7 — Coach sessions, attendance and saved lessons

### FE-16 P15 Coach schedule and roster

Coach sees assigned sessions/groups and necessary participant data. Session roster displays eligibility and attendance; mark/correct attendance only with the approved grant. Display deductions returned by server rather than decrementing a local counter. A canceled session clearly indicates saved-lesson consequences.

Acceptance: own-scope enforcement; refresh/retry does not deduct twice; another staff member's correction produces stale-version feedback. API: BE-14; D-04/D-12.

### FE-17 P16 Saved lessons

List customer, original session/group/date, reason, status and resolution. Detail links original entitlement effect and approved redemption options. Show expiry and destination-session eligibility only after business policy is settled. A group cancellation should explain participant-level credit effects before confirmation.

Acceptance: one credit per eligible participant/session; repeated cancellation does not duplicate credits; redemption cannot happen twice. API: BE-15.

## S8 — Reports, statements and payroll

### FE-18 P17 Dashboard and exports

Provide receipt-period totals, refunds, net receipts, payment-method breakdown and debts. Label service-date versus receipt-date reports distinctly. Age/customer metrics have an explicit as-of date; avoid overlapping age buckets unless labeled as such.

Exports preserve selected location, dates, filters and authorized scope. Show generation progress/failure, and use approved sample layout. Booking status filters must not silently act as refund filters.

Acceptance: AC-10/13; screen and export contain equivalent operations/totals; totals remain stable across pagination. API: BE-16; D-14.

### FE-19 P18 Coach earnings statements

Filters: period, coach, group, classification and search. Show contributing receipts/refunds, applied rule version, base, rate, VAT component where applicable and calculated share. Separate unclassified items requiring review. Show calculation explanation and export.

Acceptance: matched numerical examples for every demo category; rental/goods excluded from coach share; refunds and rule-version changes handled explicitly. API: BE-17; D-13.

### FE-20 P19 Payroll

Monthly/yearly coach view with calculated earnings, approved accruals, payouts, balance/advance and comments. Power User enters approvals and payout records as separate actions. Corrections link to original entries; show reason/history. Do not label calculated earnings as paid or initiate external bank transfers.

Acceptance: approval does not create a payout; repeated payout submission does not duplicate; formulas and sign of balance/advance match backend examples. API: BE-18.

## S9 — Notifications, audit and release

### FE-21 P20 Notifications and reminders

Scoped inbox with read state and links to allowed records. Admin renewal lead-day settings and trigger/history follow approved policy. Browser push permissions are requested only through explicit user action. Avoid exposing financial amounts to a coach lacking finance-view rights.

Acceptance: duplicate processing yields one notification; inaccessible targets do not leak records; expired holds and cancellation outcomes show correct final state. API: BE-19; D-15.

### FE-22 P21 Audit history

Read-only filters for actor/action/date/location/entity, event detail with reason and allowed before/after changes. No editing/deleting controls. Avoid exposing credentials or unnecessary private values.

Acceptance: customer/coach cannot inspect unrestricted staff audit; events link to business records without bypassing authorization. API: BE-20.

### FE-23 Integrated acceptance and handover

Execute AC-01–15 with backend/QA, emphasizing the customer request/employee decision/cancellation journey across devices. Verify both themes, narrow-screen forms, permission errors, lost responses and session expiry. Supply frontend setup/deployment documentation and page walkthrough. Resolve material UI failures before release; do not treat visual demo similarity as proof of correct business logic.
