#!/usr/bin/env bash
set -euo pipefail

# Fully automated bootstrap for File Browser customization workflow.
# Capabilities:
# - clones upstream File Browser
# - creates/switches feature branch
# - writes implementation task/deploy scaffolding
# - commits and optionally pushes changes
# - optionally opens a PR via gh CLI
# - optionally builds/pushes Docker image
# - optionally deploys over SSH

: "${FORK_REPO:?Set FORK_REPO, e.g. filebrowser-custom}"
: "${UPSTREAM_REPO:=https://github.com/filebrowser/filebrowser.git}"
: "${BASE_BRANCH:=main}"
: "${FEATURE_BRANCH:=feature/custom-share-slugs}"
: "${WORKDIR:=$PWD/.filebrowser-work}"

# Optional automation flags
: "${AUTO_PUSH:=false}"
: "${AUTO_PR:=false}"
: "${AUTO_DOCKER:=false}"
: "${AUTO_DEPLOY:=false}"

# Required when AUTO_PUSH=true
: "${GITHUB_USER:=}"

# Required when AUTO_DOCKER=true
: "${IMAGE_NAME:=}"
: "${IMAGE_TAG:=latest}"

# Required when AUTO_DEPLOY=true
: "${DEPLOY_HOST:=}"
: "${DEPLOY_USER:=}"
: "${DEPLOY_PATH:=}"
: "${DEPLOY_SERVICE:=filebrowser}"

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
if ! git diff --cached --quiet; then
  git commit -m "Add scaffolding for custom-share slug implementation"
fi

if [[ "$AUTO_PUSH" == "true" ]]; then
  : "${GITHUB_USER:?Set GITHUB_USER when AUTO_PUSH=true}"
  FORK_URL="git@github.com:${GITHUB_USER}/${FORK_REPO}.git"
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$FORK_URL"
  else
    git remote add origin "$FORK_URL"
  fi
  git push -u origin "$FEATURE_BRANCH"
fi

if [[ "$AUTO_PR" == "true" ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI not found; skipping PR creation" >&2
  else
    gh pr create \
      --title "Add custom share slug + lifetime link scaffolding" \
      --body "Automated scaffold commit for custom share slug and lifetime link feature work." \
      --base "$BASE_BRANCH" \
      --head "$FEATURE_BRANCH" || true
  fi
fi

if [[ "$AUTO_DOCKER" == "true" ]]; then
  : "${IMAGE_NAME:?Set IMAGE_NAME when AUTO_DOCKER=true}"
  docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .
  docker push "${IMAGE_NAME}:${IMAGE_TAG}"
fi

if [[ "$AUTO_DEPLOY" == "true" ]]; then
  : "${DEPLOY_HOST:?Set DEPLOY_HOST when AUTO_DEPLOY=true}"
  : "${DEPLOY_USER:?Set DEPLOY_USER when AUTO_DEPLOY=true}"
  : "${DEPLOY_PATH:?Set DEPLOY_PATH when AUTO_DEPLOY=true}"
  ssh "${DEPLOY_USER}@${DEPLOY_HOST}" "cd '${DEPLOY_PATH}' && docker compose pull ${DEPLOY_SERVICE} && docker compose up -d ${DEPLOY_SERVICE}"
fi

echo "Done. Workspace: $WORKDIR/$FORK_REPO Branch: $FEATURE_BRANCH"
