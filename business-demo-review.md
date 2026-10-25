# CRM demo business review

Review date: 24 October 2026. Source: authenticated Owner interface at https://ace-tennis-crm.yellowoasis4.chatgpt.site/ and the previously reviewed business requirements in instructions.docx.

This review records visible behavior and explanatory text. No business records were created, saved, deleted, or paid during inspection. Server enforcement, concurrency, refund processing, data recovery, and other role sessions were not tested. UI descriptions are evidence of intended behavior, not proof of implementation.

## Agreed direction

Define business workflows and exceptions before decomposition for frontend and backend teams. The demo is a reference, not an automatically approved specification. The highest authority in the planned application is Power User; the demo currently calls its top role Owner. Customer self-service remains undecided.

## Observed business areas

### Locations and bookable resources

- Staff access can be assigned separately to ACE and CSKA locations. Only ACE content was inspected.
- ACE schedule displays ten tennis courts plus Fitness and Assembly Hall.
- Schedule spans 07:00 to 00:00 in Almaty time with half-hour grid positions.
- Groups and reservations can select multiple courts or rooms.

Decisions: single or multiple locations for the initial release; shared versus location-specific customers, tariffs, memberships and reporting; whether multiple selected courts are all occupied or are alternatives; capacities for non-court spaces.

### Customer records

- Customer card contains name, phone, date of birth, membership-paid-until date, membership group, messaging consent, notes and booking history.
- The inspected customer has historical paid membership entries but no membership end date or group assigned in the customer card. This is an observed state, not proof of a failed synchronization rule.
- No separate representative or payer field was visible in the inspected card.
- Notification page explicitly states customer accounts are not supported in the current CRM.

Decisions: participant versus payer versus representative; multiple memberships/groups per customer; whether membership status is calculated or manually maintained; customer self-service scope.

### Services and tariffs

- Catalog contains 28 entries spanning court rental, coaching, group packages, fitness, single lessons, equipment rental, tournament rental, photography and replacement fees.
- Service configuration contains price, duration, coach statement classification, transaction category, export purpose and summary category.
- An eight-lesson package was classified as Services and goods while its summary category was Groups / membership fees and its export purpose was Membership sales.
- No structured lesson-count or validity rule was visible in that service editor, despite lesson counts appearing in package names.

Decisions: separate product kinds and their rules; quantity and duration pricing; which combinations of service and group are valid; effective dates for price changes; treatment of discounts.

### Groups and recurring training

- Group form includes name, statement category, default coach, weekdays, start/end time, multiple resources, color and active status.
- Form text says selected days/times/resources appear automatically as recurring sessions.
- Existing configuration includes a group spanning all ten tennis courts and an active group missing end time and courts.
- Group creation form did not expose capacity or participant management, although schedule cards show occupancy out of 12.

Decisions: group creation versus enrollment; per-court versus whole-group capacity; session generation horizon; effective dates for schedule changes; substitutions; incomplete group activation; court and coach conflict rules.

### Reservations and general entries

- Clicking a court slot opens a reservation with customer, optional coach, service items and quantities, date, time, selected resources, duration, payment method, receipt, status and notes.
- Duration choices run from 30 minutes to five hours in half-hour steps.
- Recurrence expands into separate reservations for selected weekdays through an end date, according to form text.
- Top-menu New entry offers Service and rental or Membership fee. These forms explicitly describe entries without a court reservation.
- General entries allow service selection or a manually entered amount.
- Visible lifecycle statuses are Planned, Attended and Canceled.

Decisions: booking confirmation and payment prerequisites; unpriced holds; series editing/cancellation; conflict policy; no-show versus canceled; how duration and quantities affect price; distinction between a sale and resource occupancy.

### Memberships and attendance

- Membership-fee entry uses group, customer, coach, optional services/manual amount, date, status and notes.
- Paid membership record shows payment status, cost, amount received, remainder and payment history.
- Its service list and amount are locked after payment. Other controls remain visible, but saving changes was not tested.
- No session-credit ledger, freeze controls, or generated membership calendar was visible in the inspected customer and membership forms.
- Saved lessons page states that coach cancellation of group training preserves one lesson for each participant and does not change payments. The list was empty, so resolution actions could not be inspected.

Decisions: what payment activates; membership start/expiry; generation of lessons; attendance deduction; no-shows; freezing; group transfers; saved-lesson expiry and redemption; effect of refunds on used and unused lessons.

### Payments and financial history

- Finance page filters by receipt date in Almaty time, customer/group, receipt, type, payment method, receiving employee, service and linked booking status.
- Methods include Cash, Kaspi and ForteBank. Dashboard also shows a non-cash total.
- Eight displayed payments total 361,000 tenge; payment-method totals reconcile with that total.
- Payments linked to deleted bookings remain in the all-payments view. Page explicitly says cancellation of a booking does not imply refund of money.
- Finance rows offer Delete. No deletion or refund was attempted, so its semantics are unverified.
- Paid records display received and remaining amounts; partial-payment processing was not exercised.

Decisions: charges versus receipts; partial payment and overpayment allocation; booking cancellation versus payment cancellation versus refund; correction authority and reason; preservation of original transactions; report treatment of each state.

### Coach statements and payroll

- Statement UI describes group shares of 40% for Baby Tennis, 30% for Start/Junior and Amateur, 50% for Sports 2/3, and 80% for Sports 4, calculated from full payment without VAT deduction.
- UI describes single lessons as 30% after removing 16% VAT and individual sessions as a statement with VAT separated. These are observed demo formulas, not validated tax guidance or approved requirements.
- Court rental and goods are excluded from coach share according to page text.
- Statement export is described as seven sections with formulas and filtered coach/group/search scope.
- Payroll separates calculated earnings from owner-entered accruals and actual payouts, with monthly balances/advances and comments.

Decisions: whether payroll belongs in first release; exact formulas and rounding; effective dates; allocation to substitute coaches; refunded payments; payout approval and correction rules.

### Employees and authorization

- Demo roles are Administrator, Owner, Senior administrator and Coach.
- Staff form exposes location access plus permissions to edit schedule, customers, services/prices, coaches and receive payments.
- Form says disabling a modification permission leaves section viewing available; changing access terminates sessions.
- Coach-access guidance says coaches may view their own schedule/customers and add customers, but cannot book or receive payment.
- Saved-lessons guidance additionally refers to coach cancellation of training; this needs reconciliation with the broad booking restriction.

Decisions: map Owner to the agreed Power User; administrator versus operator scope; separate viewing, creating, editing, canceling, refunding and exporting permissions; coach cancellation rights; finance visibility; scope of customer access across coaches and locations.

### Notifications and audit

- Payment notifications are described as automatic to owners, administrators with payment rights and the session coach.
- Renewal reminders have configurable lead days but are manually triggered with a button; page states repeat sends on the same day do not duplicate notifications.
- Activity log is described as read-only and filterable by employee, action and date.

Decisions: scheduled versus manual reminders; recipients and message content; whether coaches should see payment amounts; customer messages and consent; which business actions require an audit record.

## Recommended order for business workshops

1. Agree locations, resources, role responsibilities and customer self-service scope.
2. Trace court rental from request through reservation, payment, attendance, cancellation and refund.
3. Trace customer/child registration, group enrollment, membership purchase, activation and first attendance.
4. Resolve missed lessons, coach cancellation, saved lessons, transfers, freezes and renewals.
5. Agree payment corrections, reporting, coach earnings and payroll scope.
6. Translate approved workflows into acceptance scenarios, then frontend/backend responsibilities and API contracts.

For each workflow record the actor, prerequisites, steps, resulting states, money/resource/entitlement effects, exceptions, permissions and acceptance examples.
