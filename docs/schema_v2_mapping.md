# EcoTrace schema v2 naming and backend mapping

## Refactoring map

| Previous table / attribute | New name | Design rationale |
|---|---|---|
| `organizations` | `orgs` | Organization tables may remain for domain entities. Authentication users are independent. |
| `organization_id` on users | *(removed)* | Authentication does not depend on organization membership. |
| `user_devices` | `devices` | Device records are not a user subtype; ownership is `user_id`. |
| `user_id` in `users` | `id` | Every entity uses the same primary-key name. |
| `role_id` in `roles` | `id` | Removes redundant table prefix from the primary key. |
| `role_name` | `name` | Entity-local name is unambiguous. |
| `organization_code` / `organization_name` | `code` / `name` | Concise attributes within `orgs`. |
| `external_identifier` / `staff_code` | *(removed)* | Username is the only login identifier. |
| `account_status` | `status` | Standard status attribute. |
| `phone_number` | `phone` | Common concise contact attribute. |
| `last_login_at` | `last_login` | Standardized audit/login field. |
| `device_id` / `device_token` | `id` / `token` | Consistent PK and concise device credential field. |
| `ecotrace_plants` | `trees` | Domain name, plural snake_case noun. |
| `tree_id` in tree entity | `id` | Consistent PK; references remain `tree_id`. |
| `tree_code` | `code` | Entity-local external/display identifier. |
| `tree_name` | `name` | Removes redundant entity prefix. |
| `tree_planted_date` | `planted_at` | Concise event/date naming. |
| `tree_status` | `status` | Standard status attribute. |
| `location_address` | `address` | Clear and concise location field. |
| `tree_planter_name` | `planter_name` | Removes redundant entity prefix. |
| `ecotrace_plant_verifications` | `verifications` | Domain noun; `tree_id` retains the relationship. |
| `ecotrace_incidents` / `ecotrace_photos` | `incidents` / `photos` | Domain nouns with no legacy prefix. |
| `event_title` / `event_description` | `name` / `description` | Entity-local attributes. |
| `created_by` | `created_by` | Explicit actor reference retained; all actor fields use user IDs. |

## Entity relationship overview

- `orgs` has many `users`, `events`, and `trees`.
- `roles` has many `users`; `users` has many `devices`.
- `events` connect users through `event_users` and trees through `event_trees`.
- `trees` have many `verifications`, `incidents`, and `photos`.
- `verifications` optionally belong to an event and may have photos.
- `incidents` optionally belong to an event and may have photos.
- `users` are retained as the audit actor for creation, reporting, review, assignment, and upload actions.

## Backend query updates

The existing authentication code cannot use the v2 schema without these substitutions:

```sql
-- old
SELECT u.*, r.role_name, o.organization_name
FROM users u
JOIN roles r ON r.role_id = u.role_id
LEFT JOIN organizations o ON o.organization_id = u.organization_id
WHERE u.user_id = ?;

-- v2; aliases preserve the current JS response contract
SELECT u.*, r.name AS role_name, o.name AS organization_name
FROM users AS u
JOIN roles AS r ON r.id = u.role_id
LEFT JOIN orgs AS o ON o.id = u.org_id
WHERE u.id = ?;
```

Required controller changes:

- `INSERT INTO users`: use `phone` instead of `phone_number`; use `org_id` when an organization is supplied.
- Login update: `UPDATE users SET failed_login_attempts = 0, last_login = CURRENT_TIMESTAMP WHERE id = ?`.
- `auth.js`: `user.id` replaces `user.user_id`; `user.staff_code` replaces `user.external_identifier`; `user.phone` replaces `user.phone_number`; `user.status` replaces `user.account_status`.
- The SQL aliases `role_name` and `organization_name` above allow the existing JWT role and public-user mapping to remain stable during the client transition.
- Public JSON can continue exposing `externalId` for compatibility, sourced from `staff_code`; a future API version may expose `staffCode` as the canonical field.
- Existing tree API queries must migrate from `ecotrace_plants` and prefixed columns to `trees`, `id`, `code`, `zone`, `name`, `planted_at`, `status`, `address`, `planter_name`, and `description`. Alternatively, a compatibility view should be introduced during a rolling deployment.

This is a fresh-schema DDL. Do not run it over the legacy database without a staged table/column migration, data backfill, foreign-key validation, and an application cutover.
