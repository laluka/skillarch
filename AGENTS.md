# AGENTS.md

Instructions for AI coding agents (Claude Code, Pi, OpenAI Codex, Cursor, OpenCode, etc.) when editing the SkillArch repo. Keep it lean.

---

## What SkillArch is

Reproducible hacker workstation for CachyOS/Arch. One `make install` sets up dotfiles, shell, WM, dev runtimes, offensive tools, wordlists. Also ships two Docker images (`lite`, `full`) and a cloud target (`make cloud`, Plasma browser desktop + cloud-init).

---

## Source-of-truth layout

| File | Role |
|---|---|
| [Makefile](Makefile) | **Source of truth.** All install steps live here. |
| [readme.md](readme.md) | User-facing docs (install guide, bindings, package list). |
| [skillarch-ai.md](skillarch-ai.md) | AI-loadable skill: full awareness of tools/aliases/bindings. |
| [config/aliases](config/aliases) | All shell aliases — sourced by [config/zshrc](config/zshrc). |
| [config/i3/config](config/i3/config) | i3 keybindings (AZERTY workspace keys). |
| [Dockerfile-lite](Dockerfile-lite) / [Dockerfile-full](Dockerfile-full) | Lite = CLI only. Full = lite + GUI + wordlists. |
| [.github/workflows/cicd.yml](.github/workflows/cicd.yml) | Builds both Docker images + semgrep/trivy/gitleaks. |

All dotfiles live in `config/` and are **symlinked** into `$HOME` by the `ska-link` Makefile macro (original is renamed to `*.skabak`).

---

## Where a new tool goes

Match the right `make install-*` target — Makefile is authoritative, then mirror into the two docs.

| Tool kind | Makefile target | Pattern |
|---|---|---|
| Arch package | `install-cli-tools` / `install-offensive` / `install-gui-tools` | `$(PACMAN_INSTALL) <pkg>` |
| AUR (yay) | same, via `yay --noconfirm --needed -S <pkg>` | wrap each pkg in a loop that warns on failure |
| Python (PyPI) | `install-cli-tools` (CLI) or `install-offensive` (offensive) | `uv tool install <pkg>` |
| Go | `install-offensive` | `mise exec -- go install <pkg>@latest &` (parallel, `wait` at end) |
| pdtm (ProjectDiscovery) | `install-offensive` via `pdtm -install-all` | no code change needed if upstream adds it |
| GitHub binary release | `install-offensive` | `curl` release URL from `api.github.com/repos/.../releases/latest`, chmod, move to `/usr/local/bin/` |
| Git-cloned tool | `install-offensive` or `install-wordlists` | `ska_clone <url> &` then `wait`; lands in `/opt/<name>` |
| Dotfile / config | `config/` + add a `ska-link` in the relevant `install-*` | symlink into `$HOME` |
| Alias | [config/aliases](config/aliases) | group with existing section |
| i3 binding | [config/i3/config](config/i3/config) | keep AZERTY workspace conventions |

### Doc sync after a Makefile change

1. [readme.md](readme.md) — "Installed Packages, Plugins, Tools" section (line ~278). Append to the matching sub-list (Pacman / Yay / Go / Pdtm / uv / Cloned).
2. [skillarch-ai.md](skillarch-ai.md) — the corresponding "Installed Tools" sub-section. Also add to the Cloned Tools table if `/opt/<name>`.
3. If it exposes a useful CLI, add a smoke-test row in `make test` (and `test-lite` if it's CLI-lite-worthy).
4. If it gets an alias, update [config/aliases](config/aliases) + the alias tables in both docs.

Three places for one tool is by design — readme is user-facing, skillarch-ai is agent-loadable, Makefile installs it. Don't skip any.

---

## Testing changes

```bash
# Bare-metal (in /opt/skillarch or /opt/skillarch-original):
make install-offensive   # isolated target, fast re-run
make test                # smoke tests all binaries & symlinks
make doctor              # broken symlinks, disk, docker health
make list-tools          # prints versions of every major tool

# Docker (full pipeline, slow):
make docker-build        # lite
make docker-build-full   # full
```

`sanity-check` requires cwd = `/opt/skillarch` or `/opt/skillarch-original`. Everything else is idempotent — existing symlinks / clones are no-ops.

---

## Conventions

- **No secrets in the repo.** The user's private aliases live in `~/.myaliases` (sourced if present). Never commit tokens, keys, `.env`.
- **Idempotent Makefile.** Every step must tolerate re-runs: `|| true`, `--needed`, existence guards, `ska-link` (backs up originals).
- **Parallel where it helps.** Go installs, git clones, wordlist downloads run with `&` + `wait`. See `install-offensive` / `install-wordlists`.
- **GitHub API rate limit.** `pdtm` hits the 60 req/h cap — the retry loop waits 4min. Don't remove it.
- **Docker-aware guards.** `[[ ! -f /.dockerenv ]]` skips systemd / flatpak / mirror-rate in container builds.
- **Makefile color helpers.** Use `$(call INFO,...)`, `$(call OK,...)`, `$(call WARN,...)`, `$(call ERR,...)`, `$(call STEP,N,M,msg)`, `$(call DONE,...)` — don't inline raw echo.
- **`$(comma)`**, not a literal `,`, inside `$(call ...)` arguments.

---

## Things NOT to touch without a reason

- `chaotic-aur` setup in `install-base` — the HKP keyserver is slow; the direct `.pkg.tar.zst` download is deliberate.
- `sleep` calls between Docker builds — GitHub rate-limits fast consecutive builds.
- `ska-link` macro — renames existing files to `*.skabak`; this is the user's backup mechanism (`.gitignore`'d).
- `QT_QPA_PLATFORMTHEME=kde` + `XDG_SESSION_TYPE=x11` in `~/.xprofile` — makes Qt apps dark under i3 and pins X11 over Wayland.
- `install-gui` KDE BreezeDark writes (kwriteconfig6 + GTK settings) — they fail silently at install-time (no D-Bus) and that's expected.

---

## When in doubt

- Read the Makefile target you're modifying end-to-end before changing it.
- Run `make doctor` after local changes.
- The user prefers small, focused PRs and does NOT want backwards-compat shims.
