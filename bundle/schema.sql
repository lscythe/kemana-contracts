-- SQLite schema for the offline transit bundle.
--
-- The writer must run `PRAGMA foreign_keys = ON;` before loading this script
-- and before inserting rows, so the declared foreign keys are enforced.
--
-- Every entity id is TEXT, namespaced `<operator_id>:<source_id>`.
-- Times are integer seconds since the start of the service day. Values may
-- exceed 86400 for trips that run past midnight.
-- Dates are INTEGER YYYYMMDD service dates in the operator's timezone.
-- A service with NULL start_date and end_date has no weekly pattern and runs
-- only on dates added by service_exceptions. exception_type 1 adds the
-- service on that date, 2 removes it.
--
-- `PRAGMA user_version` is the bundle schema version. Bump it on every
-- schema change.

PRAGMA user_version = 2;

CREATE TABLE operators (
    id   TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    url  TEXT,
    timezone TEXT NOT NULL
);

CREATE TABLE stops (
    id             TEXT PRIMARY KEY,
    code           TEXT,
    name           TEXT NOT NULL,
    lat            REAL NOT NULL,
    lon            REAL NOT NULL,
    location_type  INTEGER NOT NULL DEFAULT 0,
    parent_station TEXT REFERENCES stops (id),
    wheelchair_boarding INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE routes (
    id          TEXT PRIMARY KEY,
    operator_id TEXT NOT NULL REFERENCES operators (id),
    short_name  TEXT,
    long_name   TEXT,
    route_type  INTEGER NOT NULL,
    color       TEXT,
    text_color  TEXT
);

CREATE TABLE services (
    id         TEXT PRIMARY KEY,
    monday     INTEGER NOT NULL DEFAULT 0 CHECK (monday IN (0, 1)),
    tuesday    INTEGER NOT NULL DEFAULT 0 CHECK (tuesday IN (0, 1)),
    wednesday  INTEGER NOT NULL DEFAULT 0 CHECK (wednesday IN (0, 1)),
    thursday   INTEGER NOT NULL DEFAULT 0 CHECK (thursday IN (0, 1)),
    friday     INTEGER NOT NULL DEFAULT 0 CHECK (friday IN (0, 1)),
    saturday   INTEGER NOT NULL DEFAULT 0 CHECK (saturday IN (0, 1)),
    sunday     INTEGER NOT NULL DEFAULT 0 CHECK (sunday IN (0, 1)),
    start_date INTEGER,
    end_date   INTEGER,
    CHECK ((start_date IS NULL) = (end_date IS NULL))
);

CREATE TABLE service_exceptions (
    service_id     TEXT NOT NULL REFERENCES services (id),
    date           INTEGER NOT NULL,
    exception_type INTEGER NOT NULL CHECK (exception_type IN (1, 2)),
    PRIMARY KEY (service_id, date)
) WITHOUT ROWID;

CREATE TABLE trips (
    id           TEXT PRIMARY KEY,
    route_id     TEXT NOT NULL REFERENCES routes (id),
    service_id   TEXT NOT NULL REFERENCES services (id),
    headsign     TEXT,
    direction_id INTEGER,
    shape_id     TEXT,
    wheelchair_accessible INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE stop_times (
    trip_id        TEXT NOT NULL REFERENCES trips (id),
    stop_sequence  INTEGER NOT NULL,
    stop_id        TEXT NOT NULL REFERENCES stops (id),
    arrival_time   INTEGER NOT NULL,
    departure_time INTEGER NOT NULL,
    pickup_type    INTEGER NOT NULL DEFAULT 0,
    drop_off_type  INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (trip_id, stop_sequence)
) WITHOUT ROWID;

CREATE TABLE shapes (
    shape_id    TEXT NOT NULL,
    pt_sequence INTEGER NOT NULL,
    lat         REAL NOT NULL,
    lon         REAL NOT NULL,
    dist_traveled REAL,
    PRIMARY KEY (shape_id, pt_sequence)
) WITHOUT ROWID;

CREATE TABLE frequencies (
    trip_id      TEXT NOT NULL REFERENCES trips (id),
    start_time   INTEGER NOT NULL,
    end_time     INTEGER NOT NULL,
    headway_secs INTEGER NOT NULL,
    exact_times  INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (trip_id, start_time)
) WITHOUT ROWID;

CREATE TABLE fares (
    id                TEXT PRIMARY KEY,
    operator_id       TEXT NOT NULL REFERENCES operators (id),
    price             REAL NOT NULL,
    currency          TEXT NOT NULL,
    payment_method    INTEGER NOT NULL,
    transfers         INTEGER,
    transfer_duration INTEGER
);

CREATE TABLE transfers (
    from_stop_id      TEXT NOT NULL REFERENCES stops (id),
    to_stop_id        TEXT NOT NULL REFERENCES stops (id),
    transfer_type     INTEGER NOT NULL DEFAULT 0,
    min_transfer_time INTEGER,
    PRIMARY KEY (from_stop_id, to_stop_id)
) WITHOUT ROWID;

CREATE TABLE bundle_meta (
    id             INTEGER PRIMARY KEY CHECK (id = 1),
    schema_version INTEGER NOT NULL,
    source_sha256  TEXT NOT NULL,
    built_at       TEXT NOT NULL
);

CREATE INDEX idx_service_exceptions_date ON service_exceptions (date);
CREATE INDEX idx_trips_service ON trips (service_id);
CREATE INDEX idx_stops_lat_lon ON stops (lat, lon);
CREATE INDEX idx_stop_times_stop_departure ON stop_times (stop_id, departure_time);
