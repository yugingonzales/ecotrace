# EcoTrace Schema v2 Setup with phpMyAdmin

This guide explains how to import and test the EcoTrace database schema using **XAMPP MariaDB/MySQL** and **phpMyAdmin**.

Schema file:

```text
C:\flutter_workspace\ecotrace\docs\schema_v2.sql
```

## Important warning

`schema_v2.sql` creates a new normalized schema for a fresh test database. Do **not** import it directly into a production or legacy EcoTrace database without a backup and staged migration.

Recommended test database:

```text
ecotrace_v2_test
```

## 1. Start XAMPP services

1. Open the XAMPP Control Panel.
2. Start **Apache**.
3. Start **MySQL**.
4. Confirm both services show **Running**.

If MySQL does not start, another MySQL/MariaDB service may already use port `3306`.

## 2. Open phpMyAdmin

Open:

```text
http://localhost/phpmyadmin
```

If Apache uses another port, use the port shown in XAMPP, for example:

```text
http://localhost:8080/phpmyadmin
```

## 3. Create a fresh test database

1. Select the **Databases** tab.
2. Enter `ecotrace_v2_test` under **Create database**.
3. Select collation `utf8mb4_unicode_ci`.
4. Click **Create**.
5. Select `ecotrace_v2_test` in the left navigation panel.

The database should initially contain no tables.

## 4. Import the schema file

1. With `ecotrace_v2_test` selected, click **Import**.
2. Click **Choose File**.
3. Select:

   ```text
   C:\flutter_workspace\ecotrace\docs\schema_v2.sql
   ```

4. Keep the format set to **SQL**.
5. Scroll to the bottom and click **Import** or **Go**.

A successful import should report that the SQL queries executed successfully.

## 5. Confirm that tables were created

Refresh the database in the left navigation panel. These 11 tables should exist:

```text
orgs
roles
users
devices
events
trees
event_users
event_trees
verifications
incidents
photos
```

You can also run:

```sql
SHOW TABLES;

DESCRIBE users;
DESCRIBE trees;
DESCRIBE verifications;

SHOW CREATE TABLE users;
SHOW CREATE TABLE trees;
```

## 6. Verify the seeded roles

The schema automatically inserts `admin`, `staff`, `volunteer`, and `intern`:

```sql
SELECT id, name, created_at
FROM roles
ORDER BY id;
```

Expected result: four rows. The role seed is safe to run again because `roles.name` is unique.

## 7. Insert a test organization

```sql
INSERT INTO orgs (code, name)
VALUES ('ECOTRACE-TEST', 'EcoTrace Test Organization');

SELECT id, code, name, created_at, updated_at
FROM orgs;
```

If you receive a duplicate-key error, the organization already exists:

```sql
SELECT * FROM orgs WHERE code = 'ECOTRACE-TEST';
```

## 8. Insert a test user

First find the organization and volunteer role IDs:

```sql
SELECT id, code FROM orgs WHERE code = 'ECOTRACE-TEST';
SELECT id, name FROM roles WHERE name = 'volunteer';
```

Use the returned IDs below. The example assumes organization ID `1` and volunteer role ID `3`; replace them if necessary.

```sql
INSERT INTO users (
  org_id, role_id, username, staff_code,
  first_name, middle_name, last_name, email,
  password_hash, phone, home_address, status
)
VALUES (
  1, 3, 'test.volunteer', 'VOL-TEST-0001',
  'Test', NULL, 'Volunteer', 'test.volunteer@example.com',
  'replace-with-a-bcrypt-hash', '+63 900 000 0000',
  'EcoTrace Test Site', 'active'
);
```

Verify the user and its relationships:

```sql
SELECT
  u.id, u.username, u.staff_code, u.first_name, u.last_name,
  u.email, r.name AS role_name, o.name AS organization_name,
  u.status, u.created_at
FROM users AS u
JOIN roles AS r ON r.id = u.role_id
LEFT JOIN orgs AS o ON o.id = u.org_id
WHERE u.email = 'test.volunteer@example.com';
```

### Password hash note

`replace-with-a-bcrypt-hash` is only a database-structure placeholder and cannot authenticate. Generate a real bcrypt hash using the backend utility or Node.js, then run:

```sql
UPDATE users
SET password_hash = 'YOUR_BCRYPT_HASH_HERE'
WHERE email = 'test.volunteer@example.com';
```


## 10. Test relationships and foreign keys

Connect the test event, user, and tree:

```sql
INSERT INTO event_users (event_id, user_id, role)
VALUES (1, 1, 'participant');

INSERT INTO event_trees (event_id, tree_id, assigned_to)
VALUES (1, 1, 1);
```

Create a verification:

```sql
INSERT INTO verifications (
  tree_id, event_id, user_id, status, health_status,
  stage, height_cm, notes, verified_at
)
VALUES (
  1, 1, 1, 'pending', 'healthy', 'seedling', 35.50,
  'Initial test verification.', CURRENT_TIMESTAMP
);
```

Create an incident:

```sql
INSERT INTO incidents (
  tree_id, event_id, reported_by, severity, status,
  description, occurred_at
)
VALUES (
  1, 1, 1, 'low', 'open',
  'Test incident for schema validation.', CURRENT_TIMESTAMP
);
```

Check the relationships:

```sql
SELECT
  t.code AS tree_code,
  e.name AS event_name,
  u.email AS participant_email
FROM event_trees AS et
JOIN trees AS t ON t.id = et.tree_id
JOIN events AS e ON e.id = et.event_id
LEFT JOIN users AS u ON u.id = et.assigned_to;

SELECT
  v.id,
  t.code AS tree_code,
  u.email AS submitted_by,
  v.status,
  v.verified_at
FROM verifications AS v
JOIN trees AS t ON t.id = v.tree_id
JOIN users AS u ON u.id = v.user_id;
```

## 11. Test the Node.js authentication query

The following query matches the schema v2 backend mapping:

```sql
SELECT
  u.*,
  r.name AS role_name,
  o.name AS organization_name
FROM users AS u
JOIN roles AS r ON r.id = u.role_id
LEFT JOIN orgs AS o ON o.id = u.org_id
WHERE u.email = 'test.volunteer@example.com'
LIMIT 1;
```

It should return one user and the aliases `role_name` and `organization_name`.

The backend must use these v2 fields:

```text
users.id
users.staff_code
users.phone
users.status
users.last_login
roles.id
roles.name
orgs.id
orgs.name
```

Test the API after pointing it to this database:

```text
POST http://localhost:3000/api/auth/register
POST http://localhost:3000/api/auth/login
GET  http://localhost:3000/api/auth/profile
```

Use the returned JWT as a Bearer token for the profile request.

## 12. Check indexes and foreign keys

```sql
SHOW INDEX FROM users;
SHOW INDEX FROM trees;
SHOW INDEX FROM verifications;
```

List foreign keys:

```sql
SELECT
  TABLE_NAME,
  COLUMN_NAME,
  CONSTRAINT_NAME,
  REFERENCED_TABLE_NAME,
  REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE CONSTRAINT_SCHEMA = 'ecotrace_v2_test'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;
```

## 13. Test cascade behavior carefully

Only run destructive tests in `ecotrace_v2_test`.

Inspect dependent rows first:

```sql
SELECT * FROM devices WHERE user_id = 1;
SELECT * FROM event_users WHERE user_id = 1;
SELECT * FROM event_trees WHERE assigned_to = 1;
```

For a test tree, related records should be removed according to the defined foreign keys:

```sql
DELETE FROM trees
WHERE id = 1
  AND code = 'TRE-TEST-0001';
```

## 14. Configure the backend connection

Set the Node.js backend environment values to match your XAMPP installation:

```text
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=
DB_NAME=ecotrace_v2_test
```

Use the actual username, password, host, and port configured on your machine. Restart the backend after changing these values.

## 15. Common phpMyAdmin problems

### File upload size error

This schema is normally small enough for direct import. If phpMyAdmin reports a size or timeout problem, update `php.ini`:

```ini
upload_max_filesize = 20M
post_max_size = 20M
max_execution_time = 300
```

Restart Apache after changing `php.ini`.

### Unknown collation

If `utf8mb4_unicode_ci` is unavailable, remove the `COLLATE=utf8mb4_unicode_ci` portions from the SQL file or choose a collation supported by your server.

### Foreign-key error

Confirm that:

- All tables use `ENGINE=InnoDB`.
- Referenced tables are created before dependent tables.
- Referenced and foreign-key columns both use `INT UNSIGNED`.
- You imported the current `schema_v2.sql`.

### Duplicate table or column errors

Create a new database named `ecotrace_v2_test`, select it, and import again. Do not repeatedly import into a partially created legacy database.

### Duplicate role errors

Check existing roles:

```sql
SELECT id, name FROM roles;
```

## 16. Final checklist

- [ ] Apache is running.
- [ ] MySQL/MariaDB is running.
- [ ] phpMyAdmin opens.
- [ ] `ecotrace_v2_test` exists.
- [ ] All 11 tables were created.
- [ ] Four roles were inserted.
- [ ] A test organization was inserted.
- [ ] A test user was inserted.
- [ ] A test event and tree were inserted.
- [ ] Foreign-key relationship inserts succeeded.
- [ ] The authentication query returned the expected aliases.
- [ ] The backend points to `ecotrace_v2_test`.
- [ ] Login and profile endpoints were tested.

After successful testing, create a proper migration plan before replacing the existing EcoTrace database.

Never store a plain-text password in `password_hash`.

## 9. Insert a test event and tree

The following example assumes organization ID `1` and test user ID `1`. Replace IDs with the values returned by your queries.

```sql
INSERT INTO events (
  org_id, name, description, start_date, end_date,
  trees_per_user, target_year, status, created_by
)
VALUES (
  1, 'phpMyAdmin Test Event',
  'Test event for validating the EcoTrace schema.',
  '2026-01-01', '2026-12-31', 2, '2026', 'active', 1
);

INSERT INTO trees (
  org_id, code, zone, name, planted_at, latitude, longitude,
  address, planter_name, description, status, created_by
)
VALUES (
  1, 'TRE-TEST-0001', 'Test Zone', 'Narra', '2026-01-15',
  12.3456789, 124.5678901, 'EcoTrace Test Site', 'Test Volunteer',
  'Tree created to validate the schema.', 'pending', 1
);
```

Verify the records:

```sql
SELECT id, name, status, start_date, end_date FROM events;
SELECT id, code, name, zone, status, latitude, longitude FROM trees;
```

The event insert should fail if `end_date` is earlier than `start_date` on servers enforcing the check constraint.
