#!/usr/bin/env bash
set -euo pipefail

# End-to-end bootstrap for a File Browser fork workspace.
# This script does not require manual edits once environment variables are set.

: "${GITHUB_USER:?Set GITHUB_USER}"
: "${FORK_REPO:?Set FORK_REPO, e.g. filebrowser-custom}"
: "${BASE_BRANCH:=main}"
: "${FEATURE_BRANCH:=feature/custom-share-slugs}"
: "${UPSTREAM_REPO:=https://github.com/filebrowser/filebrowser.git}"

WORKDIR="${WORKDIR:-$PWD/.filebrowser-work}"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

if [[ ! -d "$FORK_REPO" ]]; then
  git clone "$UPSTREAM_REPO" "$FORK_REPO"
fi

cd "$FORK_REPO"

git checkout "$BASE_BRANCH" || git checkout -b "$BASE_BRANCH"
git pull --ff-only origin "$BASE_BRANCH" || true

git checkout -B "$FEATURE_BRANCH"

cat > FILEBROWSER_CUSTOM_SHARE_TASKS.md <<'PLAN'
# Custom Share Slug + Lifetime Link Tasks

## Backend
- Add `slug` and `slug_norm` to share model and persistence layer.
- Allow nullable `expires_at` semantics for lifetime links.
- Add slug validation + normalization utilities.
- Extend share creation endpoint with `slug`, `neverExpire`, `expiresAt`.
- Add `/s/{slug}` resolver route.

## Frontend
- Add Custom Link field in share modal.
- Add expiration mode with `never` option.
- Show final slug URL and copy action.

## Testing
- Unit tests for slug validation.
- API tests for duplicate slug conflict and lifetime links.
- Migration compatibility tests.
PLAN

mkdir -p deploy
cat > deploy/docker-compose.override.yml <<'YAML'
services:
  filebrowser:
    image: ${IMAGE_NAME:-ghcr.io/your-org/filebrowser-custom:latest}
    ports:
      - "8080:80"
    environment:
      - FB_SHARE_ALLOW_CUSTOM_SLUG=true
      - FB_SHARE_ALLOW_NEVER_EXPIRE=true
YAML

cat > DEPLOY_CHECKLIST.md <<'DOC'
# Deploy Checklist

1. Build image:
   `docker build -t ghcr.io/<org>/filebrowser-custom:<tag> .`
2. Push image:
   `docker push ghcr.io/<org>/filebrowser-custom:<tag>`
3. Deploy with compose/k8s using the new image tag.
4. Verify:
   - legacy token links still work
   - new `/s/<slug>` links resolve
   - `neverExpire` links do not expire
DOC


git add FILEBROWSER_CUSTOM_SHARE_TASKS.md deploy/docker-compose.override.yml DEPLOY_CHECKLIST.md
if git diff --cached --quiet; then
  echo "No changes to commit"
else
  git commit -m "Add automation scaffolding for custom-share File Browser fork rollout"
fi

echo "Bootstrap complete in $WORKDIR/$FORK_REPO on branch $FEATURE_BRANCH"
