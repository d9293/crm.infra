# crm.infra

Infrastructure, environment and release engineering for the ACE / CSKA tennis-centre CRM.

Docker Compose, routing and TLS configuration, environment templates, migration and run procedures, backups, restore and deployment documentation.

## Specification

The whole specification set lives in [`docs/`](docs/) in this repository — it has no separate repository of its own. Start at [`docs/README.md`](docs/README.md) for the reading order, or [`docs/decision-briefing.md`](docs/decision-briefing.md) for the decisions currently blocking work.

| Document | Use |
|---|---|
| [`docs/development/infra.md`](docs/development/infra.md) | Ticket backlog INF-00–INF-08 |
| [`docs/development/README.md`](docs/development/README.md) §11 | Infrastructure and release responsibilities |
| [`docs/development/README.md`](docs/development/README.md) §10 | Acceptance tests AC-01–15, including AC-14 recovery |
| [`docs/development/decisions.md`](docs/development/decisions.md) | Open decisions — D-16 gates five of the nine infrastructure tickets |

## Status

Partial. PostgreSQL is fully defined and runnable now. The backend, worker, frontend and proxy services are documented placeholders in `docker-compose.yml`, completed in INF-00 once **D-01** fixes the backend language and framework — their image, command, healthcheck and Dockerfile all follow from that choice.

Backup tooling (INF-04), monitoring (INF-07) and the migration rehearsal (INF-06) are later sprints and are not present yet.

## Requirements

Docker with Compose v2 or later. Verified against Docker 29.6 / Compose v5.3.

## Getting started

```sh
cp .env.example .env
```

Fill in the values marked REQUIRED — the stack refuses to start without them rather than falling back to an insecure default. Generate secrets locally:

```sh
openssl rand -base64 24
```

Then start the database:

```sh
docker compose up -d postgres
docker compose ps                    # wait for (healthy)
```

## Commands

No Makefile: `make` is not present on a default Windows developer machine, so the commands are documented directly rather than wrapped in something half the team cannot run.

```sh
# Lifecycle
docker compose up -d postgres        # start the database
docker compose ps                    # service status and health
docker compose logs -f postgres      # follow logs
docker compose stop                  # stop, keep data
docker compose down                  # remove containers, keep data

# Database shell
docker compose exec postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"

# Test database — separate credentials, ephemeral tmpfs storage
docker compose --profile test up -d postgres-test
```

### Destructive commands

Per `development/infra.md`, operations that can destroy data require an explicit, non-default command. There is deliberately no convenience wrapper for these.

```sh
# Deletes ALL database data in the named volume. Irreversible.
docker compose down -v
```

Take and verify a backup first. Once INF-04 lands, use the documented backup procedure rather than improvising.

## Database configuration notes

Decisions encoded in `docker-compose.yml` that are easy to get wrong, with the reason recorded so nobody "simplifies" them back:

**Data mount path.** PostgreSQL 18+ images store data in a major-version subdirectory to support `pg_upgrade --link`. The volume mounts at `/var/lib/postgresql`, **not** `/var/lib/postgresql/data`. The older path makes the container refuse to start with a message about `pg_ctlcluster` compatibility (docker-library/postgres#1259).

**Debian image, not Alpine.** The Alpine variant uses musl, whose locale support for Cyrillic is weaker. Customer names are Russian.

**ICU collation `ru-KZ`.** Not cosmetic. Under the default `C` collation, Cyrillic sorts by code point, so `Ёлкин` lands before `Абаев` — a customer list ordered that way is simply wrong. Verified:

```
C collation:    Ёлкин < Абаев < Яковлев        (wrong)
ICU ru-KZ:      Абаев < Егоров < Ёлкин < Жуков < Яковлев
```

Changing the locale after data exists can invalidate existing text indexes, so treat it as a migration, not a setting.

**`C.UTF-8` for lc_ctype.** ICU governs collation; `lc_ctype` still governs character classification. `C.UTF-8` handles Unicode case conversion correctly, including `ёлка` → `ЁЛКА`. Plain `C` would not.

**UTC everywhere in the container.** Server and log timezone are UTC. `Asia/Almaty` is applied by the application for business display, report boundaries and recurrence expansion. Never set a container timezone to compensate for application logic.

**`btree_gist` extension** is created by `db/init/01-extensions.sql`, because the BE-06 exclusion constraint combines scalar resource identity with a timezone-aware range and scalar types have no GiST operator class by default.

Verified against this configuration:

```sql
EXCLUDE USING gist (resource_id WITH =, occupied_during WITH &&)
  WHERE (allocation_active)
```

- 10:00–11:00 and 11:00–12:00 on one court — both accepted (half-open `[start, end)`, AC-07)
- 10:00–11:00 on two different courts — both accepted
- 10:30–11:30 overlapping 10:00–11:00 on one court — rejected by the constraint (AC-01)

`db/init/` runs **once**, on an empty data directory only, and holds extensions exclusively. Schema belongs in the backend's migration history: an init-script schema cannot be versioned or rolled back, and would not be reproduced by the AC-14 restore drill.

## Constraints

Carried from `development/infra.md`:

- PostgreSQL is the only authoritative store. A rebuilt container must lose nothing but cache.
- Pin every image and dependency to an exact version. A floating `latest` tag invalidates a restore drill.
- Secrets never appear in source, images, logs, CI output, compose files or handover documents.
- Development, test and any demonstration database are separate databases with separate credentials.
- Record environment changes in this repository. A manual fix applied to a running host cannot be reproduced during the restore drill.
- The database port binds to `127.0.0.1` only.

## Not configurable by design

The five-minute reservation hold (BR-04) and two-hour cancellation cutoff (BR-07) are confirmed business rules, not settings. They live in application code with tests pinning them, so no environment file can silently change a rule the owner approved and that AC-03 and AC-05 verify.

No Kaspi, bank, fiscalization, SMS or analytics credential appears here. None of those integrations is authorized — see `development/README.md` §2.
