# PostgreSQL Schema Initialization

This container defines the database schema for the Residential Directory Management System.

## How to initialize the schema

1. Ensure the database server is running (`startup.sh`).
2. Ensure you have the correct connection string in `db_connection.txt`.
3. Run the schema initialization script:

    ```bash
    bash init_schema.sh
    ```

This will create the following tables:

- residents: main resident directory info
- users: user accounts (admin, resident; used for authentication & roles)
- moderation_requests: tracks info change requests for moderation/approval
- audit_log: complete record of changes (who, what, when)

Indexes are created for efficient search by name or unit.

## Table Relationships

- `users.role` can be `'admin'` or `'resident'`
- Changes by residents are inserted into `moderation_requests` for admin review
- Any change (approved, rejected, exported, etc.) is recorded in `audit_log`

## Re-Running

The script is idempotent: safe to re-run, existing tables will not be dropped or overwritten.

