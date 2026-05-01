# File Browser Fork Implementation Plan

This repository now includes a complete implementation plan to fork the open-source **File Browser** project and add:

1. Customizable share links (user-defined slugs)
2. Optional unlimited/lifetime links (never expire)

---

## 1) Scope (v1)

### In scope
- Optional custom slug for every share link
- `neverExpire`/lifetime share option
- Admin policies for enabling/disabling these features
- Backward compatibility with existing random token links

### Out of scope for v1
- Editing slug after share creation
- Per-user namespace for slugs
- Download-limit counters (can be future enhancement)

---

## 2) Data model changes

Add the following columns to the `shares` table:

- `slug` (nullable text)
- `slug_norm` (nullable text, lowercase normalized slug)
- `expires_at` (nullable timestamp; `NULL` means no expiry)

### Constraints
- Unique index on `slug_norm` where non-null
- `slug_norm` should be generated in backend logic from user slug input

---

## 3) Suggested SQL migration patterns

### PostgreSQL / SQLite
```sql
ALTER TABLE shares ADD COLUMN slug TEXT NULL;
ALTER TABLE shares ADD COLUMN slug_norm TEXT NULL;
-- Ensure expires_at is nullable.

CREATE UNIQUE INDEX IF NOT EXISTS ux_shares_slug_norm
ON shares (slug_norm)
WHERE slug_norm IS NOT NULL;

CREATE INDEX IF NOT EXISTS ix_shares_expires_at
ON shares (expires_at);
```

### MySQL
```sql
ALTER TABLE shares ADD COLUMN slug TEXT NULL;
ALTER TABLE shares ADD COLUMN slug_norm TEXT NULL;
-- Ensure expires_at allows NULL.

CREATE UNIQUE INDEX ux_shares_slug_norm ON shares (slug_norm);
CREATE INDEX ix_shares_expires_at ON shares (expires_at);
```

---

## 4) Backend/API changes

Extend share create endpoint to accept:

- `slug` (optional)
- `neverExpire` (boolean)
- `expiresAt` (nullable datetime)

### Validation rules
- If `slug` provided, verify:
  - policy allows custom slug
  - format is valid (regex)
  - length in bounds
  - not in reserved names
  - unique (case-insensitive via `slug_norm`)
- If `neverExpire = true`:
  - policy must allow it
  - force `expiresAt = null`
- If `neverExpire = false` and `expiresAt` provided:
  - value must be in the future (UTC)

### Error mapping
- `400`: validation error
- `403`: disabled by admin policy
- `409`: slug already taken
- `410`: expired share access

---

## 5) Slug format and normalization

Recommended regex:

```text
^[a-z0-9](?:[a-z0-9-_]{1,62}[a-z0-9])?$
```

Reserved slugs to block (example list):

- `admin`, `api`, `login`, `logout`, `settings`, `share`, `shares`, `s`, `static`

Normalization strategy:

- `trim` input
- lowercase result as `slug_norm`
- store user-facing input in `slug`
- query and uniqueness checks on `slug_norm`

---

## 6) Routing and backward compatibility

Add slug route:

- `/s/{slug}`

Keep existing token route unchanged.

Resolution order should be explicit by route path:

- `/s/{slug}` resolves via `slug_norm`
- existing token endpoint resolves via token

Do not break old links.

---

## 7) Expiration semantics

- `expires_at = NULL` means lifetime/unlimited
- Non-null timestamp means hard expiry point in UTC

Expired links should return **410 Gone** (recommended) instead of generic 404.

---

## 8) Admin policy settings

Add global config keys:

```json
{
  "share": {
    "allowCustomSlug": true,
    "allowNeverExpire": true,
    "slugMinLen": 3,
    "slugMaxLen": 64,
    "slugRegex": "^[a-z0-9](?:[a-z0-9-_]{1,62}[a-z0-9])?$"
  }
}
```

Recommended defaults:
- `allowCustomSlug = true`
- `allowNeverExpire = true` (or false if stricter security policy is preferred)

---

## 9) UI changes

In Share dialog/UI:

1. Add "Custom Link" text input
2. Show link preview (`https://domain/s/<slug>`)
3. Add expiration selector:
   - 1 day
   - 7 days
   - custom date/time
   - never expire (if policy allows)
4. Show clear errors for duplicate/invalid slug

Optional UX improvement:
- "Check availability" action for slug

---

## 10) Test plan

### Unit tests
- slug validation and normalization
- reserved slug rejection
- expiration logic with null and non-null dates

### API tests
- create share without slug (legacy behavior)
- create share with slug success
- duplicate slug conflict (409)
- never-expire share persists
- expired share returns 410

### Migration tests
- migrate existing DB snapshot
- verify old token links still function

### UI tests/manual QA
- create/copy slug links
- policy toggles reflected in UI
- invalid slug feedback

---

## 11) Deployment path (Docker)

1. Fork File Browser upstream repository
2. Create feature branch `feature/custom-share-slugs`
3. Implement migration + backend + UI
4. Build image
5. Deploy to staging with production-like DB copy
6. Validate old links and new slug links
7. Roll out to production

---

## 12) Suggested PR split

- PR 1: DB migrations + backend API + tests
- PR 2: frontend share UI + validation UX
- PR 3: docs + upgrade notes + sample config

---

## 13) Security recommendations

- Keep share password support for slug links
- Optional rate limit on slug availability check endpoint
- Audit log for share creation/deletion
- Optionally restrict lifetime links to admins only

