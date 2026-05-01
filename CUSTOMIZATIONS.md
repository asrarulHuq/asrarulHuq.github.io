# Customizations

A running log of all customizations applied on top of upstream filebrowser.

---

## [Unreleased]

### Added
- Initial fork of filebrowser/filebrowser @ v2.63.2
- GitHub Actions: CI, auto-merge, upstream sync, PR lint workflows
- Issue templates: bug report, customization request
- PR template
- Custom share slugs: users can now optionally set a human-readable name for share links (e.g. `/share/my-project-docs`). Random generation is kept as the fallback. Backend validates length (3–64 chars), character set (`[a-zA-Z0-9_-]`), reserved words, and uniqueness (HTTP 409 on conflict).

---

*This file is updated automatically by each customization PR.*
