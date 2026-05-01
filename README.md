# asrarulHuq.github.io

## Zero-touch File Browser fork bootstrap

Run this command to scaffold the File Browser customization workflow:

```bash
FORK_REPO=<your-fork-repo-name> ./automation/bootstrap_filebrowser_fork.sh
```

### Optional full automation flags

- `AUTO_PUSH=true GITHUB_USER=<github-user>`: push feature branch to your fork
- `AUTO_PR=true`: open PR automatically via `gh` CLI
- `AUTO_DOCKER=true IMAGE_NAME=ghcr.io/<org>/filebrowser-custom IMAGE_TAG=<tag>`: build and push image
- `AUTO_DEPLOY=true DEPLOY_HOST=<host> DEPLOY_USER=<user> DEPLOY_PATH=<compose-dir> [DEPLOY_SERVICE=filebrowser]`: deploy over SSH

Example end-to-end run:

```bash
FORK_REPO=filebrowser-custom \
AUTO_PUSH=true GITHUB_USER=myuser \
AUTO_PR=true \
AUTO_DOCKER=true IMAGE_NAME=ghcr.io/myorg/filebrowser-custom IMAGE_TAG=v1 \
AUTO_DEPLOY=true DEPLOY_HOST=server.example.com DEPLOY_USER=ubuntu DEPLOY_PATH=/opt/filebrowser \
./automation/bootstrap_filebrowser_fork.sh
```

Reference plan:
- [File Browser Fork Implementation Plan](FILEBROWSER_FORK_IMPLEMENTATION.md)
