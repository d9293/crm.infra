# CRM UI and UX specification

Version 0.1 · 25 October 2026 · Proposed design direction authorized for development refinement

This is the visual and interaction companion to `frontend.md`. It covers all P01–P21 pages, shared templates and customer/staff/coach journeys. Confirmed business rules in `README.md` remain authoritative. Visual examples contain synthetic data and do not prove backend behavior. Open decisions in `decisions.md` remain open; a design must not silently decide them.

## 1. Design direction

Use a calm sports-club workspace: deep green primary actions, warm neutral surfaces, restrained court-line geometry and clear typography. Dense operational information belongs in schedules and tables; customer tasks use generous spacing and short steps. Avoid decorative revenue charts, stock sports photos, glass effects, gradients and oversized dashboard cards that displace daily work.

The demo provides business context, not the visual template. Improvements:

- Staff land on today's work and urgent approval requests, not a large financial chart above the schedule.
- Customer language distinguishes a request from a confirmed reservation and cancellation approval from immediate cancellation.
- Coach navigation centers on upcoming sessions and rosters, with finance present only when permitted.
- Location is always visible. Financial totals, request queues and resource availability have an explicit location scope.
- Use dedicated pages for complex workflows and side panels for short details; avoid nested dialogs and a universal New record form that hides whether a court will actually be reserved.

## 2. Navigation and information architecture

### Staff shell

Desktop left rail, width 232 px. Top: ACE / CSKA CRM wordmark. Navigation groups:

1. Daily work: Schedule; Reservation requests (active count); Cancellation requests (active count).
2. People and training: Customers; Groups; Memberships; Coaches; Saved lessons.
3. Finance: Payments; Reports; Coach statements; Payroll.
4. Administration: Employees; Locations and resources; Services; Audit.

Only authorized destinations are rendered. Footer: profile/role and sign out. Header contains location selector, notification entry and account/theme controls. Page title and primary action sit in the content header. Permission scope is not conveyed by a theme color.

Default staff landing: schedule for selected permitted location, with a compact pending-request banner linking to the queue. Remember a permitted location preference; never silently retain data from the previous location. Power User may use cross-location reporting only if the API and policy allow it. No All locations option on a resource calendar.

### Customer shell

Brand/location context at top; two primary destinations: Book a court and My reservations. Account and sign out live in account menu, not an invented full customer dashboard. On mobile, two labeled bottom navigation items; content includes bottom safe-area padding. Membership/payment-profile pages are deferred under D-03.

### Coach shell

My schedule, assigned groups/rosters and permitted saved-lesson actions. Notification/account controls shared. Earnings destination only with explicit grant. On phones, upcoming sessions in an agenda; no 12-column calendar scaled into unreadable text.

## 3. Design tokens

Names below are product CSS variables; use semantic tokens instead of raw values in components. Light/dark pairs are intended to preserve hierarchy. Verify final component contrast after composition, including disabled controls and group colors.

| Token | Light | Dark | Use |
|---|---|---|---|
| `--crm-bg` | `#F5F6F3` | `#111815` | Page canvas |
| `--crm-surface` | `#FFFFFF` | `#1A2420` | Panels, tables, dialogs |
| `--crm-surface-alt` | `#EBF0EB` | `#25332C` | Headers, subtle grouping |
| `--crm-text` | `#172B23` | `#EDF5EF` | Primary text |
| `--crm-text-muted` | `#52645B` | `#ADBEB3` | Secondary text |
| `--crm-border` | `#D3DDD5` | `#43564A` | Structural separators |
| `--crm-control-border` | `#788A7D` | `#83998A` | Input/control outlines |
| `--crm-primary` | `#176344` | `#A7E2BE` | Primary button fill/selected controls |
| `--crm-on-primary` | `#FFFFFF` | `#10271B` | Text on primary |
| `--crm-focus` | `#155CC4` | `#9BC4FF` | Keyboard focus ring |
| `--crm-success-bg/text` | `#E4F3E9 / #205B39` | `#203D2D / #B1E6BE` | Confirmed/success |
| `--crm-warning-bg/text` | `#FFF0CC / #76510C` | `#443719 / #F6D889` | Pending/attention |
| `--crm-danger-bg/text` | `#FCE8E6 / #9B2E29` | `#432824 / #FFB9B2` | Destructive/error |

Typography: system UI sans-serif with Cyrillic support; optional bundled Inter only after licensing/package review. No external font required. Body 16/24 px; table body 14/20; metadata minimum 12/18; input text 16/24; page title 28/36; section title 20/28; control label 14/20. Weights 400, 500 and 600. Tabular numerals for money/time/countdowns. Avoid uppercase paragraphs and letter spacing on Russian labels.

Spacing scale: 4, 8, 12, 16, 24, 32, 48 px. Standard content padding 32 desktop, 24 tablet, 16 mobile. Panel radius 12 px, control radius 8 px, status-pill radius 999 px. Use subtle border separation; shadows only for floating surfaces. Controls min 44 px high, ordinary desktop table rows 48 px, comfortable rows 56 px. Calendar cells may be denser but retain an accessible list alternative.

Icons: one consistent outline family, 18–20 px with visible labels for important actions. Never use an icon alone for Confirm, Reject, Pay or Refund. Group color is a narrow accent strip plus group name; it must not replace booking-status text or reduce text contrast. Preserve brown as brown across themes rather than auto-remapping it to an unrelated color.

## 4. Responsive templates

Breakpoints are design targets, not device detection: compact below 768 px, medium 768–1199, wide 1200+. Test at 360, 768, 1024 and 1440 px and 200% text zoom. Main document must reflow without horizontal overflow; calendar/table regions may have explicitly labeled local horizontal scrolling.

| Template | Desktop | Compact/mobile |
|---|---|---|
| T1 Access | Centered 400 px form with brand and one clear purpose | Full-width form with 16 px margins, same fields |
| T2 Directory | Title/action → search/filter bar → table → pagination; detail page | Search/filter button → cards with primary fields → detail page |
| T3 Operational calendar | Date/resource toolbar → sticky time/resource headers → grid → detail drawer | Date + one-resource selector or agenda; full-page booking detail |
| T4 Approval queue | Request list (~40%) + selected detail (~60%); expiry-prioritized | List first; tap opens full-page detail with sticky actions |
| T5 Record detail | Identity summary → tabs → section body; secondary history rail when useful | Summary → labeled section selector → single column |
| T6 Customer journey | Selection body + 320 px booking summary; review step | One-column steps; sticky total/primary action with safe-area padding |
| T7 Finance/report | Filters → compact totals → semantic table → export/status | Filters drawer; totals wrap; record cards or deliberate table scroll |
| T8 Roster | Session summary → participant list with status/actions | Large participant rows and explicit attendance actions |
| T9 Settings/audit | Narrow readable forms or searchable event table | Stacked forms; audit event cards |

Panels: short detail drawer 440–520 px; larger forms get dedicated pages. At mobile widths drawers become full-page surfaces with Back and title. Use a small dialog only for a single focused decision. No stacked dialogs; choose an existing customer via an inline search or a separate create step that returns to the preserved booking draft.

## 5. Customer reservation journey P07–P08

### Step A Choose a slot

Location selector first, then date, resource type/court and duration. Show free slots as labeled buttons, occupied slots as unavailable without disclosing who booked. Choosing a slot highlights it but creates no hold. Display local date/time and location persistently. Changing location clears dependent slot selection with an explanation; never silently carry a court from another center.

### Step B Review request

Show location, court, full date, start/end, duration and server-supplied quote. Explain: «Отправьте заявку. Мы удержим время на 5 минут, пока сотрудник её рассматривает». Primary action: «Отправить заявку». No false Confirmed label and no Pay now requirement. If price/availability changed, show the new value and require renewed review before submitting.

### Step C Pending

Receipt-like status page: amber «Ожидает подтверждения», remaining hold time, slot summary and «Обновить статус». Copy: «Время удерживается до 14:05. Если сотрудник не подтвердит заявку, оно снова станет доступно». Use actual server expiry. Keep pending visible in My reservations. Do not add a customer withdraw action until D-06 is resolved.

Countdown is visual only; announce initial status and meaningful state changes to assistive technology, not each second. No promise that an employee will respond. At local zero show checking state until server reconciliation; do not invent confirmation. Lost connectivity shows «Нет соединения. Проверим статус после подключения» and last update time; a draft or local timer is not a valid booking.

### Step D Outcome

- Confirmed: «Бронь подтверждена»; independently show «Не оплачено» when finance data exists. Payment is allowed later; do not block access with a payment wall.
- Rejected: «Заявка отклонена» and an authorized customer-safe reason if supplied; action «Выбрать другое время».
- Expired: «Время ожидания истекло. Бронь не подтверждена»; action «Посмотреть свободное время». Resubmission is a new request after availability recheck.

## 6. Employee approval journey P10

Queue header: location, number of active requests and last update time. Default list sorted by nearest expiry, preserving selected item while background data refreshes. Each row: pending label + time left, court/time, customer display name (authorized staff only). Do not reorder keyboard focus when expiry changes sort order.

Detail hierarchy: status/timer → court and date/time → customer/allowed contact → quote and payment state → request time → actions. Primary «Подтвердить бронь», secondary «Отклонить». Confirmation does not request payment. Rejection opens a focused optional/required reason step according to API policy; never require a reason because the designer assumed one.

At server expiry, replace decision buttons with «Заявка истекла» and availability link. If another employee decided, display who/when if authorized and refresh details. Busy state disables only conflicting actions; retain context. A successful server response updates list/calendar and status, then politely announces the result. No optimistic success toast before commit.

## 7. Cancellation journey P08/P11

Customer confirmed detail shows «Запросить отмену» and cutoff: «Отмену можно запросить до 13:00, 25 октября». For a 15:00 start, 13:00 submission is valid, 13:00:01 is not. After cutoff, show an explanatory unavailable action; do not invent a contact number or promise an override.

Review explains: «Бронь останется действующей, пока администратор не одобрит отмену». Include refund separation only if relevant: «Отмена брони не оформляет возврат автоматически». Submission creates cancellation-pending indicator alongside the still-confirmed reservation. Avoid replacing confirmed with a single ambiguous Pending status.

Administrator cancellation detail: original booking, submission time, cutoff, reason, payment summary if permitted; primary «Одобрить отмену», secondary «Отклонить запрос». Approval confirmation says the slot will be released; it does not offer an implicit refund checkbox. Rejection restores no money and preserves confirmed booking. Post-start decisions and resubmission await D-07; do not depict unapproved options as working features.

## 8. Page-by-page layout contract

Every page inherits the global failure/loading/permission patterns. The state column highlights additional page-specific cases.

| Page | Template and content order | Primary action | Page-specific states |
|---|---|---|---|
| P01 Access | T1 brand → title → identifier/password → error/help → submit | Sign in | Invalid credentials, throttled, blocked, session expired; recovery D-02 |
| P02 Employees | T2 search/role/location/status → employee table; T5 profile → access → history | Add employee | Last Power User protected, revoked sessions, stale permission edit |
| P03 Resources | T2 location → courts/rooms → order/hours/closures; T5 resource form | Add resource | Archived, closure overlaps existing bookings, no resources configured |
| P04 Customers | T2 search → name/phone → profile; T5 profile → bookings → groups/memberships → permitted finance | Add customer | Possible duplicate, archived, no history, hidden finance, representative D-02 |
| P05 Coaches | T2 coach/status/location → T5 contact → linked account → groups/schedule | Add coach | No login account, archived, restricted profile fields |
| P06 Services | T2 kind/location/status filters → price/unit table → T5 version history | Add service | New effective version, archived sale item, unresolved membership fields |
| P07 Availability | T6 location → date/duration → slots → review | Send request | No slots, stale quote, conflict, submission uncertain |
| P08 My reservations | T2 Upcoming/History → date/status cards → T5 receipt-like detail | Open booking; cancellation request when eligible | Hold expiry, rejected, confirmed unpaid, pending cancellation, canceled |
| P09 Schedule | T3 compact request banner → date/court filters → calendar → booking drawer | Create booking if authorized | Holds, confirmed, closure, group slot, calendar unavailable; no silent fallback to empty |
| P10 Approvals | T4 expiring request rows → context and timer → decision | Confirm booking | Another employee acted, expired, connection lost |
| P11 Cancellations | T4 pending list → original booking/request/payment context → decision | Approve cancellation | Booking version changed, already decided, late decision D-07 |
| P12 Finance | T7 date basis/filter → received/refunded/net → transactions; T5 original/linked corrections | Receive payment | Partial/overpayment, refund eligibility, duplicate/uncertain response |
| P13 Groups | T2 active/location/coach → T5 Overview, Timetable, Participants, History | Create group / enroll participant | Incomplete timetable, conflict preview, full capacity, archived |
| P14 Memberships | T2 customer/group/state → T5 plan/calendar/ledger/payments | Issue membership | Pending activation, expiry, no credits, freeze/transfer only per D-11 |
| P15 Coach roster | T8 session/court/time → participants → attendance status and action | Record attendance | Unassigned access, ineligible entitlement, duplicate marking, correction |
| P16 Saved lessons | T2 customer/group/state → original session and resolution history | Resolve eligible lesson | Empty, already redeemed, expired only if approved policy |
| P17 Reports | T7 date basis/location → clear totals → detail → export | Export | Processing, failed generation, filter mismatch prevention, no records |
| P18 Statements | T7 coach/period/category → calculation lines → formula explanation | Export statement | Unclassified receipt, rule versions, refund adjustment |
| P19 Payroll | T7 coach/year → monthly rows: calculated/accrued/paid/balance → detail | Approve accrual or record payout, in separate contexts | Advance, adjusted period, unpaid; never Paid from calculation alone |
| P20 Notifications | T2 scoped inbox → event detail; T9 reminder settings separately | Open related record | Delivery failure, already read, destination access revoked |
| P21 Audit | T9 actor/action/date/location filters → event rows → read-only details | Filter | No records, restricted event fields, archived entity |

Finance filters must remain accessible on small screens. Put summaries adjacent to the relevant table rather than scattered cards. Money right-aligned, negative/refund amounts labeled, date basis in the heading. Receipt and reservation statuses have separate columns/badges.

## 9. Component contracts

| Component | Inputs/behavior | Required variants |
|---|---|---|
| LocationSwitcher | Allowed locations; clears dependent selection safely | Single location, two locations, loading, unavailable |
| StatusBadge | Explicit enum-to-label mapping; icon/text and semantic tone | Request, booking, cancellation, payment, membership independently |
| HoldTimer | Server expiry/time; no mutation from browser clock | Active, checking, server-expired, offline; no second-by-second live announcements |
| MoneyField | KZT units/precision and validation; server total separate | Empty, invalid, disabled paid amount, positive/negative display |
| CustomerSearch | Scoped results and selected identity; no free text masquerading as ID | Loading, no match, duplicate suggestion, selection revoked |
| ResourceSlot | Start/end, court, availability; no other-customer PII | Free/selected/held/unavailable/closed; keyboard equivalent |
| ApprovalDetail | Record version/context, decision commands | Pending/submitting/committed/conflict/expired |
| DataTable | Stable row ID, sort/filter/page, total scope label | Loading skeleton, empty, error, stale data, pagination |
| RecordTimeline | Immutable events, local dates, safe actor display | Corrections, archived link, limited visibility |
| DecisionDialog | Exact consequence + reason policy + explicit action | Reject, cancel approval, refund, archive; never generic Are you sure alone |
| InlineAlert | Message, recovery action, optional correlation reference | Warning/error/info, offline and uncertain transaction |

Do not choose a component library merely from the demo. Implementation may use accessible primitives after a dependency evaluation in S0; the visual contract applies regardless of library. Use a component gallery with documented variants for review, not disconnected one-off CSS per page.

## 10. State, language and recovery

Use short Russian action labels with an object: «Подтвердить бронь», «Запросить отмену», «Принять оплату», «Оформить возврат». Avoid «Готово» for a state-changing action and avoid «Оплачено» when only a charge exists.

Loading: skeleton matching final geometry; no zero totals during load. Empty: describe genuine empty result, keep filters and add a relevant authorized action. Error: preserve user input in memory and expose retry; no raw stack trace. Stale data: show last update and reconnect state; revalidate before decisions. No permission: concise explanation and safe navigation, without leaking the hidden entity's name. Unknown financial outcome: «Проверяем результат операции» and transaction lookup/retry with same command key, never a fresh duplicate payment.

Background list updates preserve focus/scroll and current filters. Use URL query parameters for non-sensitive date/status/location filters; no names/phones/passwords in URLs. Unsaved form navigation asks to keep/discard a draft; closing an untouched inspection form does not prompt. Do not persist sensitive drafts across logout.

## 11. Accessibility and interaction acceptance

Target implementation checks: ordinary text contrast at least 4.5:1, large text and essential non-text controls 3:1; visible keyboard focus; meaningful headings/labels; errors linked to fields; no color-only status; 44 px effective touch targets; keyboard alternatives for drag, timetable selection and hover details. These are testable design targets, not a claim of certified compliance.

Dialog focus enters at an appropriate heading/field, remains within modal, and returns to its triggering action. Escape closes only when safe; unsaved edits follow draft rules. Calendar uses an explicit labeled navigation model plus an agenda/list alternative. Use native date/time inputs or accessible equivalents; local-date/time entry includes timezone context. Never announce a ticking timer every second.

Respect reduced-motion preference. Keep transitions subtle (120–180 ms) and never animate essential countdown/state information. Screen-reader live regions announce committed outcomes and errors. Test Russian strings at 200% text zoom, long names, large monetary values and keyboard-only usage.

## 12. Design delivery per sprint

| Sprint | UI/UX deliverable before implementation acceptance |
|---|---|
| S0 | Token styles, three role shells, template gallery, component state gallery; contract review with both teams |
| S1 | P01–P03 wide/compact layouts and permission/error states |
| S2 | P04–P06 forms, version history and linked-record navigation |
| S3 | P07–P10 complete prototype: choose slot → request → hold → employee decision → customer outcome |
| S4 | Cancellation request/decision plus booking move/recurrence conflict views |
| S5 | Receipt/refund/uncertain-outcome flow with balance reconciliation UI |
| S6 | Group/plan/enrollment/membership flows after policy decisions |
| S7 | Coach roster/attendance/correction and saved-lesson resolution |
| S8 | Reports/statement/payroll tables and export states; validate actual sample layout |
| S9 | Notification/audit screens, accessibility and responsive review, handover screenshots and integrated walkthrough |

For each page provide: wide and compact layout, field/action order, loading/empty/error/conflict/permission states, keyboard/focus behavior, sample content, API dependencies and acceptance criteria. Design approval cannot replace backend acceptance tests.

## 13. UX acceptance tasks

- UX-01: A new customer can distinguish selected slot, pending request and confirmed booking without explanation.
- UX-02: Employee can locate the next expiring request and see court/time/customer before confirming; keyboard navigation stays stable during updates.
- UX-03: Customer understands that cancellation needs approval and can identify the exact two-hour cutoff.
- UX-04: Confirmed/unpaid and confirmed/cancellation-pending display as distinct combinations; no false payment or cancellation success.
- UX-05: Switching ACE/CSKA never leaves a stale selected court, summary or queue masquerading as the new location.
- UX-06: A 360 px user completes booking/cancellation and an employee completes a decision without clipped controls or horizontal page scrolling.
- UX-07: Payment/network timeout offers outcome recovery, not a duplicate-payment invitation.
- UX-08: Coach can find the next session and mark permitted attendance without viewing unauthorized finance.
- UX-09: Keyboard/screen reader can complete forms, navigate a resource list and understand status changes without color or hover.
- UX-10: Both themes preserve semantic state contrast and group color identity. Verify final rendered components, not just token swatches.

Run these as short observed usability walkthroughs with representative staff/customer/coach users. Record confusion and completion failures; fix critical issues before corresponding sprint acceptance. No usability results are claimed by this specification.
