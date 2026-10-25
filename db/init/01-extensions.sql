-- Database initialization — runs once, on an empty data directory only.
--
-- Scope: extensions the schema depends on. Tables, indexes and constraints
-- belong in the backend's migration history, never here. A schema created by
-- an init script cannot be versioned, reviewed or rolled back, and would not
-- be reproduced by the restore drill that AC-14 requires.

-- btree_gist is required by the range exclusion constraint proposed in BE-06
-- as second-line protection against double booking. That constraint combines
-- scalar resource identity with a timezone-aware range:
--
--   EXCLUDE USING gist (resource_id WITH =, occupied_during WITH &&)
--     WHERE (allocation_active)
--
-- Scalar types have no GiST operator class by default, so the constraint
-- cannot be created without this extension. Enabling it here means a fresh
-- database is ready before the first migration runs.
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Note for BE-06 implementation: do not place a time-dependent now()
-- predicate in the exclusion index in an attempt to expire holds
-- automatically. Index predicates must be immutable. Expiry is handled
-- inside the allocation transaction using database time, per backend.md.
