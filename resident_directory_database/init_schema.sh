#!/bin/bash

# PostgreSQL schema initialization script for resident directory management system
# Reads connection string from db_connection.txt and executes each DDL as a standalone psql command.

set -e

CONNSTR=$(cat db_connection.txt)

# Table: residents
psql "$CONNSTR" -c "
CREATE TABLE IF NOT EXISTS residents (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    unit VARCHAR(20) NOT NULL,
    phone VARCHAR(40),
    email VARCHAR(120) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);
"

# Table: users (system logins; both admins & residents)
psql "$CONNSTR" -c "
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(40) UNIQUE NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    password_hash VARCHAR(200) NOT NULL,
    role VARCHAR(30) NOT NULL CHECK (role IN ('admin', 'resident')),
    is_active BOOLEAN DEFAULT TRUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);
"

# Table: moderation_requests (for when residents update their info; needs approval)
psql "$CONNSTR" -c "
CREATE TABLE IF NOT EXISTS moderation_requests (
    id SERIAL PRIMARY KEY,
    resident_id INTEGER REFERENCES residents(id) ON DELETE CASCADE,
    submitted_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    field_changed VARCHAR(40) NOT NULL,
    old_value TEXT,
    new_value TEXT NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'approved', 'rejected')) DEFAULT 'pending',
    reviewed_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    submitted_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);
"

# Table: audit_log
psql "$CONNSTR" -c "
CREATE TABLE IF NOT EXISTS audit_log (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    resident_id INTEGER REFERENCES residents(id) ON DELETE CASCADE,
    action VARCHAR(40) NOT NULL,
    field_changed VARCHAR(40),
    old_value TEXT,
    new_value TEXT,
    timestamp TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    details TEXT
);
"

# Indexes for search/filter speed
psql "$CONNSTR" -c "CREATE INDEX IF NOT EXISTS idx_residents_name ON residents(name);"
psql "$CONNSTR" -c "CREATE INDEX IF NOT EXISTS idx_residents_unit ON residents(unit);"
psql "$CONNSTR" -c "CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);"

echo "Schema initialization complete."
