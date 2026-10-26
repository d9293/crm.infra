# Decisions needed to start development

Version 0.1 · 26 October 2026 · Prepared for the owner conversation

Five questions block the start of work. Everything else can wait.

`decisions.md` lists all eighteen open decisions, but asking the owner to settle eighteen things at once is how a project stalls — and the specification says as much: *"Resolve only the decisions needed for the next sprint."* This document is the subset that cannot wait, each with a recommendation so the conversation is a review rather than an open-ended discussion.

**How to use it.** Each decision has the question as it should actually be asked (Russian phrasing included), why it blocks work, a recommended answer, and what it costs to defer. Record the answer and date at the bottom, then update `decisions.md`.

**What you can show.** A working prototype of the booking journey exists at `/dev/prototype` in the frontend repository. It makes D-06, D-07 and the response-window part of D-16 concrete instead of hypothetical — people answer "is five minutes enough?" far better after watching a countdown than after reading about one.

---

## Summary

| # | Decision | Who decides | Blocks |
|---|---|---|---|
| D-18 | Build fresh, or upgrade the existing site | Owner | Scope, estimate, migration — **largest single unknown** |
| D-01 | Python or Go | Engineering, owner ratifies | All backend work |
| D-16 | Volumes, recovery targets, hosting, support | Owner | 5 of 9 infrastructure tickets |
| D-02 | How customers get accounts | Owner | S1 access, S2 identity model |
| D-04 | What each role may actually do | Owner | S1 permissions |

Recommended order: **D-18 first.** It changes the answer to several others, and it is the one the business document and the current plan disagree about.

---

## D-18 — Build fresh, or upgrade the existing site?

**Ask:** «Мы делаем новую систему с нуля или доделываем существующий сайт, сохраняя его данные?»

### Why it blocks everything

`instructions.docx` §1 says the developer should *use the existing site as a base and preserve the necessary data*. The current plan — three new repositories on local infrastructure — assumes a fresh build. The specifications were written assuming fresh.

Both are legitimate. But they are different projects, with different estimates, and the disagreement is currently unresolved rather than decided.

### Recommendation

**Run the audit before answering.** The business document's own §11 makes "аудит и оценка" step one, and it is the cheapest way to answer this honestly rather than by preference. The audit needs:

- access to the existing source code and its repository
- a database export or read access
- access to the current hosting

It should produce: a map of what already works, the actual data model, how much of the data is real versus demo, and an estimate for each path.

Until that exists, any estimate for either option is a guess. If the audit is impossible — no source access, no database export — then **fresh build is the only option**, and that itself answers D-18.

### Cost of deferring

S0 can continue (the contract and frontend foundation are built and are not wasted either way). But no credible estimate or timeline can be given, and the S9 migration plan (D-17) cannot be started.

---

## D-01 — Python or Go for the server?

**Ask:** Engineering question. The owner needs only to confirm there is no constraint from their side — for example a developer they intend to hire long-term who works in one language.

### Why it blocks work

`development/README.md` §3 forbids scaffolding a framework before this is settled, so **no backend code exists yet**. The API contract is already written and is language-neutral, so nothing else is waiting.

### Recommendation

**Python** — FastAPI, SQLAlchemy, Alembic, PostgreSQL. The reasoning is in `crm.backend/README.md`; in short, the difficulty here is exact money arithmetic, versioned migrations, Excel export matching a supplied sample, and the OpenAPI contract — all of which have direct library support in Python. Go's advantages are throughput and single-binary deployment, neither of which is this system's constraint.

Worth stating plainly: the hard part — preventing two customers from booking the same court — lives in PostgreSQL row locking and an exclusion constraint. **That is identical in both languages.** Choosing Go would not make it easier; choosing Python will not make it harder.

### Cost of deferring

Total backend blockage. This is the cheapest decision on the list and the one with the most waiting behind it.

---

## D-16 — Scale, recovery and who runs it

**Ask:** Six concrete questions rather than one abstract one.

1. «Сколько примерно клиентов в базе и сколько броней в день?»
2. «Сколько сотрудников работает в системе одновременно?»
3. «Если система упадёт, за какое время нужно восстановить работу?»
4. «Какую потерю данных можно допустить — час, день? Это определяет, как часто делать резервные копии.»
5. «На чьё имя оформляются домен и хостинг? Они должны быть на владельце.»
6. «Кому звонить, если система перестала работать в субботу вечером?»

### Why it blocks work

Five of the nine infrastructure tickets depend on these answers: database sizing, backup schedule and retention, whether report generation must be asynchronous, monitoring destinations, and support ownership. An alert with no recipient is not monitoring.

### Recommendation

Rough answers are enough to start — order of magnitude, not precision. Proposed starting values to confirm or correct:

| Question | Proposed starting value |
|---|---|
| Recovery time (RTO) | Within one business day |
| Acceptable data loss (RPO) | 24 hours — nightly backup |
| Backup retention | 30 days |
| Domain and hosting | Registered to the owner, transferred at handover |
| Support | Named person, business hours |

A nightly backup is the minimum defensible position for a system holding financial records. If losing a day of payments is unacceptable, the answer is more frequent backups and that changes the infrastructure cost.

### Cost of deferring

The system can be built, but **cannot be responsibly released**. The AC-14 recovery test has no target to verify against.

---

## D-02 — How do customers get accounts?

**Ask:** «Как клиент получает доступ в систему: сотрудник создаёт ему логин, или клиент регистрируется сам? И как быть с детьми — доступ у родителя?»

### Why it blocks work

Customer accounts are confirmed scope (BR-03), but the route to having one is not. It determines the S1 sign-in flow, password recovery, and — most importantly — how an account is linked to an existing customer record.

### Recommendation

**Employee invitation only, for the first release.** Public self-registration is explicitly outside the authorized scope, and it brings verification, spam and duplicate-identity problems that add real work for little gain at two locations.

For children: **the parent's account, with the child as a participant.** Not a login for the child.

One rule regardless of the answer, already in the specification and worth stating aloud: **a matching phone number must never automatically link an account to an existing customer record.** Two family members share a phone; that is an account-takeover path, not a convenience.

### Cost of deferring

S1 sign-in can be built for staff only, and the customer half deferred. Workable, but it splits the sprint.

---

## D-04 — What may each role actually do?

**Ask:** Best answered as a table, not a conversation. Print it and have the owner tick boxes.

«Отметьте, что может делать каждая роль.» Roles: **Владелец (Power User) · Администратор · Оператор · Тренер**

| Action | Владелец | Админ. | Оператор | Тренер |
|---|---|---|---|---|
| See the schedule | ✓ | ✓ | ✓ | own only |
| Create a booking | ✓ | | | |
| Confirm a customer's request | ✓ | | | |
| Cancel a booking | ✓ | | | |
| Approve a cancellation request | ✓ | | | — |
| Add or edit a customer | ✓ | | | |
| Receive payment | ✓ | | | — |
| Issue a refund | ✓ | | | — |
| See financial reports | ✓ | | | — |
| See coach earnings | ✓ | | | own only? |
| Edit services and prices | ✓ | | | — |
| Create and edit groups | ✓ | | | |
| Mark attendance | ✓ | | | |
| Cancel a group session | ✓ | | | ? |
| Manage employees and permissions | ✓ | — | — | — |
| See the activity log | ✓ | | — | — |

Power User is pre-filled: it is the highest authority by definition. `—` marks combinations that should stay closed. `?` marks two the demo left contradictory and that need an explicit answer.

### Why it blocks work

The employee permissions screen (P02) cannot be built without the defaults, and every later screen depends on who sees what. Absence of a grant means denial, so an unanswered row is a locked door.

### The two contradictions worth resolving

The demo's own text disagreed with itself, so these need deciding rather than copying:

1. **Coach cancelling a group session.** One page said coaches cannot book or take payment; another described coaches cancelling training and generating saved lessons for participants. Which is it?
2. **Coach seeing earnings.** Payment notifications were described as going to the session's coach. Should a coach see payment amounts, or only that a session is paid?

### Cost of deferring

S1 can ship with Power User and a single Administrator preset, deferring Operator and Coach. That is a reasonable fallback but means revisiting permissions in S2.

---

## Not needed yet

So the conversation stays short. These are real decisions, but they belong to later sprints and asking now would waste the owner's attention:

| Later | Needed by |
|---|---|
| D-06, D-07 — staff bookings, withdrawal, post-cutoff decisions | S3–S4 implementation |
| D-08 — recurrence rules | S4 |
| D-09 — when charges arise, refund policy | S5 |
| D-10, D-11 — tariff structure, membership activation | S2, S6 |
| D-12 — absence, deduction, capacity across courts | S6–S7 |
| D-13, D-14 — earnings formulas, the report sample file | S8 |
| D-15 — notification channels | S9 |
| D-17 — migration source and mapping | S9 |

Two of these are worth flagging early because they need the owner to *find* something rather than decide it:

- **D-14 needs the actual file** `Отчет 02.10.2026.xls`. The export must reproduce it, and it cannot be specified from a description.
- **D-13 needs worked examples** of coach earnings — real numbers for each category, with the expected result. The demo's percentages are observations, not verified tax logic.

Requesting both now gives time to locate them.

---

## Record of decisions

| ID | Decision | Date | Decided by |
|---|---|---|---|
| D-18 | | | |
| D-01 | | | |
| D-16 | | | |
| D-02 | | | |
| D-04 | | | |

Update `development/decisions.md` with each answer and its date, and link any affected ticket IDs.
