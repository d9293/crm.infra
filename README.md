# ACE and CSKA CRM — specification repository

Business and engineering specification for the tennis-centre CRM. This repository holds documents only; application code lives in `crm.backend`, `crm.frontend` and `crm.infra`.

Version 0.1 · 25 October 2026

## Reading order

Start at the top. Later documents assume the earlier ones.

| Order | Document | Purpose |
|---|---|---|
| 1 | [`intro.md`](intro.md) | Project framing: sources, chosen stack, repository split |
| 2 | `instructions.docx` | Business source document, 15 October 2026 |
| 3 | [`business-demo-review.md`](business-demo-review.md) | Authenticated prototype review, 24 October 2026 |
| 4 | [`development/README.md`](development/README.md) | **Master specification** — business rules, pages, sprints, contracts, acceptance |
| 5 | [`development/decisions.md`](development/decisions.md) | Open decisions D-01–D-18 and their sprint gates |
| 5a | [`decision-briefing.md`](decision-briefing.md) | **The five decisions blocking the start of work**, with recommendations — for the owner conversation |
| 6 | [`development/ui-ux.md`](development/ui-ux.md) | Visual and interaction contract |
| 7 | [`development/backend.md`](development/backend.md) | Backend backlog BE-00–BE-21 |
| 8 | [`development/frontend.md`](development/frontend.md) | Frontend backlog FE-00–FE-23 |
| 9 | [`development/infra.md`](development/infra.md) | Infrastructure backlog INF-00–INF-08 |

New team member: read 4, then the backlog for your area, then 5 to see what is still undecided in it.

## Authority

1. Explicit owner decisions take precedence over the business document and the demo.
2. `instructions.docx` supplies business requirements and acceptance scenarios.
3. `business-demo-review.md` records observed demo behaviour — evidence of intent, not proof of implementation, and not an approved specification.
4. Everything in `development/` beyond the confirmed-requirements table is an engineering proposal for refinement, not an owner-approved business rule.

Full statement in [`development/README.md` §1](development/README.md).

## Status

Confirmed and ready for refinement: both locations, customer accounts, Power User authority, the five-minute hold and employee decision, unpaid confirmation, administrator-approved customer cancellation at least two hours before start, no automatic refund on cancellation.

Blocking the start of work — see [`decision-briefing.md`](decision-briefing.md) for the questions as they should be asked, with recommendations:

| Decision | Question |
|---|---|
| D-18 | Fresh implementation versus upgrade of the existing site — largest unknown |
| D-01 | Backend language: Python or Go |
| D-16 | Volumes, recovery targets, hosting, support ownership — gates five of nine infrastructure tickets |
| D-02 | How customers receive accounts |
| D-04 | Role defaults — what each role may actually do |

A feature whose decisions are unresolved is not implementation-ready regardless of how completely its ticket is written.

Already built and not waiting on any of the above: the specification set, the S1/S3/S4 API contract, the frontend foundation, and a working prototype of the booking and cancellation journeys.

## Conventions

- Document versions use `Version 0.N · D Month YYYY`. Record the date and affected ticket IDs when an approved change lands.
- IDs are stable and must not be renumbered: `BR-nn` business requirement, `P-nn` page, `S-n` sprint, `AC-nn` acceptance test, `D-nn` decision, `BE-/FE-/INF-nn` tickets, `UX-nn` usability task.
- No credentials, personal demo records, or exported business data in this repository. See `.gitignore`.
