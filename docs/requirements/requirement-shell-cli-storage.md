**file**: docs/requirements/requirement-shell-cli-storage.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.3.4)  
**Area**: shell  
**Key**: `requirement-shell-cli-storage`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **shell CLI storage** of sshd-cli. **Storage** means **two** classes:

| Class | Role | Survives reboot |
|-------|------|-----------------|
| **Cache folder** | Volatile scratch / temps / staging | No (shm/tmp) or maybe (home fallback) |
| **Persistence storage** | Durable per-user app data for this login | Yes (under this login’s `$HOME`) |

It owns path **shapes**, the cache resolver, the persistence resolver, the `app_main` wire, and about diagnostics for both classes.

Scratch files (mktemp, self-install staging, config edit temps) live in the cache folder. Durable leaves (`preferred-remote`, `download-folders`, `upload-folders`, `language`) live in persistence storage. The `language` leaf’s codes and menu copy are `requirement-shell-cli-language`.

The preferred cache is **not** a ram-drive **project** tree (`/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${login}`). It lives under `/dev/shm/cache/` (Linux, including Termux) or `/tmp/cache/` (Git Bash and Mac). The leaf is **per login and per process** so two logins never share one cache directory.

**Scope:** Resolve priority; isolation; `util_resolve_storage` contract; `EFFECTIVE_STORAGE_DIR` / `TMPDIR` export; about human + JSON fields.  
**Out of scope (cited, not re-owned):** Binary install paths (`USER_BIN` / `GLOBAL_BIN`); `/var/sshd-cli` config deposit (`requirement-shell-config-backup`); companion checksum; PATH shell-rc (`requirement-shell-path-and-shell-support`).

### 1.1 Human-facing

Scratch for this run goes in a cache folder named for this login and this process. Durable data for this login stays under persistence storage.

| You | Another role | Not this |
|-----|--------------|----------|
| Let the CLI pick cache + persistence | Another login on the same host has a different cache leaf | Putting scratch in `/tmp` with a guessed name; treating `~/.local/bin` as data |

| Includes | Excludes |
|----------|----------|
| Cache resolver, persistence resolver, about fields | Where the program binary is installed |
| Temp files under the chosen cache root | Hard-coded `/tmp/sshd-cli` dumps |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Inspect storage | about shows Cache folder used, preferred, 1st fallback, 2nd fallback when that host has one, and Persistence storage. A skipped tier prints nothing | `sshd-cli about` / `sshd-cli --json about` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Two storage classes (mandatory split)

Volatile leaf (shared parents `/dev/shm` and `/tmp`): `cache-${APP_NAME}-${login}-$$`.  
Home leaf (already per login): `cache-${APP_NAME}-$$`.  
`$$` is **this process id**. `${login}` is `id -un` as one path segment (characters outside `[A-Za-z0-9._-]` become `_`). **MUST NOT** hardcode either.

| Host | Preferred | 1st fallback | 2nd fallback |
|------|-----------|--------------|--------------|
| Linux (and Termux, and any host that is not Git Bash or Mac) | `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/.cache/cache-${APP_NAME}-$$` |
| Git Bash (`MSYSTEM`, or `uname -s` `MINGW*` / `MSYS*`) | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$` | none |
| Mac (`uname -s` `Darwin`) | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/Library/Caches/cache-${APP_NAME}-$$` | `${HOME}/cache/cache-${APP_NAME}-$$` |

| Class | Helper |
|-------|--------|
| Cache folder (preferred) | `util_preferred_cache_dir` |
| Cache folder (1st fallback) | `util_fallback_cache_dir` |
| Cache folder (2nd fallback) | `util_fallback2_cache_dir` (empty on Git Bash) |
| Persistence storage | `util_persistent_storage_dir` → `${HOME}/.local/${APP_NAME}` |

Live chosen **cache** root: `util_resolve_storage` (stdout).  
Live **persistence** root: `util_resolve_persistent_storage` (stdout; create-before-return).

On Termux, the chosen cache root (including `/tmp` and `/dev/shm`) **MAY** be **`noexec`**. Termux uses the **Linux** chain. Cache remains scratch **only**. **MUST NOT** exec a downloaded or staged binary from the cache root. Self-install copies into the cache folder and **moves** the file to bin; it does not run it from the cache folder.

**Silent fallback.** Choosing a later tier **MUST NOT** print a warning or an error. **MUST NOT** say that a fallback happened. An error is allowed only when **every** tier for this host failed to be created.

**MUST NOT** mix these with:

| Forbidden as this product’s storage | Why |
|-------------------------------------|-----|
| `${HOME}/.local/bin` / `USER_BIN` | Install binary dir |
| `/var/sshd-cli` | Config deposit (`requirement-shell-config-backup`) |
| `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` | Looks like a ram-drive project folder |
| `${HOME}/.local/share/${APP_NAME}` | Not this product’s persistence shape |
| `$PREFIX/tmp`, `$TEMP/cache`, or `/tmp/${APP_NAME}-${USERNAME}` | Not in this chain |

### 2.2 Single cache resolver SSOT

1. **MUST** keep **one** authoritative cache-resolve helper: **`util_resolve_storage`**.  
2. New code that needs a product scratch/cache **root** **MUST** call `util_resolve_storage` (or `mktemp` under a path it returned). **MUST NOT** introduce parallel hard-coded `/tmp/sshd-cli` dumps.  
3. Resolver **MUST** print the chosen directory path on **stdout** for `$(util_resolve_storage)` capture (data return — not product UI).  
4. User-visible failure about cache **MUST** use Output SSOT (`out_die`). The closed failure text is **`Cannot create cache folder`**.

Preferred and fallback **path shapes** **MUST** be `util_preferred_cache_dir`, `util_fallback_cache_dir`, and `util_fallback2_cache_dir` (or the same literals those helpers print).

### 2.3 Live cache resolve priority

Walk this host’s chain in order. First directory that can be created **and** is writable wins. The chain is the table in §2.1. **MUST NOT** replace that chain with one shared `cache-${APP_NAME}` leaf, with `XDG_CACHE_HOME`, or with an operator `STORAGE_DIR` override.

**Parent:** for `/dev/shm/cache` and `/tmp/cache` the resolver **MUST** create that parent (prefer mode **1777** when creating) so each login can add its own `cache-${APP_NAME}-${login}-$$` leaf. The **leaf** **MUST** be mode **0700**.

**Create before return:** for the **chosen** leaf, the resolver **MUST** create it, confirm it is **writable**, then print the path. If create/write fails → try the next tier **with no message**. If none work → **MUST** fail closed. **MUST NOT** return a path without creating it.

**MUST NOT** use these as cache:

| Forbidden cache path | Why |
|----------------------|-----|
| `/dev/shm/${APP_NAME}` | Looks like a ram-drive project folder |
| `/dev/shm/${APP_NAME}-${USERNAME}` | Same confusion. Login belongs in the leaf **under** `cache/`, as `cache-${APP_NAME}-${login}-$$` |
| `/dev/shm/cache/${APP_NAME}-${USERNAME}` | Shared by every process of that login. The leaf includes `$$` |
| `/dev/shm` or `/tmp` as a dump | No app-named cache leaf |
| Persistence storage | Durable data is not scratch |

### 2.4 Cache isolation

1. Cache leaves **MUST** include **`cache-${APP_NAME}`** (app identity).  
2. Volatile leaves (`/dev/shm/cache` and `/tmp/cache`) **MUST** be `cache-${APP_NAME}-${login}-$$`. Home leaves **MUST** be `cache-${APP_NAME}-$$` (no login segment). Isolation is the login segment plus this process id.  
3. **MUST NOT** use a single shared world-writable directory for all logins or all apps.  
4. Live product **MUST** export `TMPDIR=${EFFECTIVE_STORAGE_DIR}` so `mktemp -t` inherits the isolated **cache** root.  
5. Scratch **files** **MUST** be created with `mktemp` (template ending in `XXXXXX`) under that root.  
6. The **cache directory** name includes `$$` (this process). Scratch **file** names **MUST NOT** be a predictable `$$` name (forbidden: `/tmp/${APP_NAME}.$$`, `${EFFECTIVE_STORAGE_DIR}/${APP_NAME}.$$`).

### 2.5 Persistence storage

1. Persistence **MUST** be **`${HOME}/.local/${APP_NAME}`** (this login’s home + app name). No login suffix and no `$$`.  
2. Helper **`util_persistent_storage_dir`** **MUST** print that path. **`util_resolve_persistent_storage`** **MUST** `mkdir -p` it, confirm it is writable, then print it (fail closed).  
3. **MUST NOT** use `${HOME}/.local/bin` as persistence (that is `USER_BIN`).  
4. **MUST NOT** use `/var/sshd-cli` as this login’s persistence.  
5. **MUST NOT** store scratch/temps in persistence when a cache root is available.  
6. Persistence **MUST** be under the invoking login’s `$HOME`. **MUST** include `${APP_NAME}`.  
7. Durable leaves **`preferred-remote`**, **`download-folders`**, **`upload-folders`**, and **`language`** live here. **MUST NOT** put those leaves in the cache folder. The `language` file is one line, one of `en`, `zh-Hans`, `zh-Hant`, `es`, `ar`, `fr`, `pt`, `ru`, `de`, `ja`, `ko`, `nl`, or `el`, mode 0600 (`requirement-shell-cli-language`).

### 2.6 Wire and diagnostics

| Surface | Requirement |
|---------|-------------|
| `app_main` | Resolve once early: `EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)`; `STORAGE_DIR` is the 1st fallback path; `PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)`; export `EFFECTIVE_STORAGE_DIR`, `STORAGE_DIR`, `PERSISTENT_STORAGE_DIR`, `TMPDIR` (`TMPDIR` = cache root) |
| `app_about` human | **MUST** print **`Cache folder used:`** then the live directory; **`Cache folder (preferred):`** then this host’s preferred path; **`Cache folder (1st fallback):`** then the 1st fallback; **`Cache folder (2nd fallback):`** only when this host has a 2nd fallback; **`Persistence storage:`** then `${HOME}/.local/${APP_NAME}`. **MUST NOT** label cache lines **Storage (effective)** or **Storage (fallback)**. **MUST NOT** warn or error when the used directory is a fallback |
| `app_about` JSON | **MUST** include `cache_used`, `cache_preferred`, `cache_fallback` (1st), `cache_fallback_2` (2nd, empty string when the host has none), `persistence_storage`, and the live chosen cache root as `effective_storage` (same value as `cache_used`; `storage_dir` = 1st fallback). **MUST NOT** include `CHECKSUM` |

Linux `about` lines (placeholders, not a fixed process id). `Cache folder used` is the tier that was created. When the preferred tier is the one used, the used line and the preferred line are the same path. When a fallback is used, the used line is that fallback and the preferred line still shows the preferred path.

```
[INFO] Cache folder used: /dev/shm/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (preferred): /dev/shm/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (1st fallback): /tmp/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (2nd fallback): ${HOME}/.cache/cache-${APP_NAME}-$$
[INFO] Persistence storage: ${HOME}/.local/${APP_NAME}
```

Git Bash omits the 2nd fallback line. Mac prints preferred under `/tmp/cache/`, 1st fallback under `${HOME}/Library/Caches/`, and 2nd fallback under `${HOME}/cache/`.

Test-purpose environment (not help verbs): `SSHD_CLI_CACHE_HOST=linux|gitbash|mac` forces the host chain. `SSHD_CLI_CACHE_SKIP=preferred` skips tier 1 with no message.

### 2.7 Implementation Notes (this project)

| Item | Live value |
|------|------------|
| **Product / binary** | `sshd-cli` |
| **Cache resolver** | `util_resolve_storage` in `./sshd-cli` |
| **Linux preferred** | `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` |
| **Linux 1st / 2nd** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/.cache/cache-${APP_NAME}-$$` |
| **Git Bash** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$` |
| **Mac** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/Library/Caches/cache-${APP_NAME}-$$` then `${HOME}/cache/cache-${APP_NAME}-$$` |
| **Persistence** | `${HOME}/.local/sshd-cli` |
| **Persistence resolver** | `util_resolve_persistent_storage` |
| **Call sites** | `app_main`, `app_about`; mktemp via `TMPDIR` |
| **Not used for** | Install `~/.local/bin`; `/var/sshd-cli` deposit; ram-drive project dests |
| **Tests** | `tests/test_cli.sh` — **TP-CLI-06** · **TP-CLI-12** · **TP-CLI-19** · **TP-CLI-20** |

### 2.8 Why This Requirement Exists (CIAO)

- **Caution:** Two logins, and two processes of one login, do not share one scratch directory.  
- **Intentional:** Storage = cache folder **and** persistence storage; about says both.  
- **Anti-fragile:** A missing tier still works, and the miss is silent.  
- **Principle 11 – Temps:** Scratch files are mktemp names inside the process directory.

---

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** cache and persistence stay under this login. **MUST NOT** write `/etc` dests from the cache resolver. On Termux the Linux cache chain is scratch only.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- Volatile cache first, home cache last for scratch.  
- Persistence is under `$HOME/.local/${APP_NAME}`, not under `bin` and not under `/var/sshd-cli`.  
- Isolation before convenience.  
- Create fail-closed in the resolvers.  
- Cache path family is distinct from ram-drive **project** folders.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Restore `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` as the preferred cache.  
2. Restore a shared leaf `/dev/shm/cache/${APP_NAME}-${USERNAME}` (no `$$`) as the preferred cache.  
3. Label about cache lines **Storage (effective)** / **Storage (fallback)**. The labels are **Cache folder used**, **Cache folder (preferred)**, **Cache folder (1st fallback)**, **Cache folder (2nd fallback)** when that host has one.  
4. Drop persistence storage from this requirement or from `about`.  
5. Use `${HOME}/.local/bin` or `/var/sshd-cli` as this login’s persistence.  
6. Replace the cache fallback chain with a shared world-writable dump, with `XDG_CACHE_HOME` / `STORAGE_DIR` as a tier, or with one `cache-${APP_NAME}` leaf shared by every login.  
7. Put the login segment back on a home tier (`${HOME}/.cache/cache-${APP_NAME}-${login}-$$`). Home already isolates.  
8. Scatter hard-coded `/tmp/sshd-cli` roots outside the cache resolver.  
9. Leave the resolver dead with no call sites while claiming storage is product law.  
10. Echo a tier path without creating the **chosen** root.  
11. Use predictable `$$` scratch **file** names. The cache **directory** itself includes `$$`.  
12. Warn or error only because a higher cache tier was skipped.  
13. Print a Git Bash **2nd fallback** line. Git Bash has none.  
14. Send Termux cache to `$PREFIX/tmp` instead of the Linux chain.  
15. Exec a binary from the cache folder on Termux.  
16. Strip the **Under command line for normal user only** section, or resolve scratch into `/etc` on that class.  
17. Put `CHECKSUM` in about storage diagnostics.

**Violating this rule is a critical cache isolation regression.**

---

## 5. Definition of done (shell CLI storage)

Storage resolve work for sshd-cli is **not done** if any of the following fail:

1. Exactly one authoritative resolver (`util_resolve_storage`) returns the chosen path on stdout after creating that root.  
2. Linux preferred leaf is `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` when that directory is usable. Git Bash and Mac preferred leaf is `/tmp/cache/cache-${APP_NAME}-${login}-$$`.  
3. `app_main` sets `EFFECTIVE_STORAGE_DIR` / `TMPDIR` / `PERSISTENT_STORAGE_DIR` early.  
4. `about` human prints Cache folder used, preferred, 1st fallback, 2nd fallback when present, and Persistence storage. JSON has `cache_used` / `cache_preferred` / `cache_fallback` / `cache_fallback_2` / `persistence_storage` and omits `CHECKSUM`.  
5. Scratch files use `mktemp` `XXXXXX` under the cache root. The cache directory name includes `$$`. Scratch file names do not.  
6. Skipping a cache tier prints no warning and no error. Git Bash has no 2nd fallback. Mac 2nd fallback is `${HOME}/cache/cache-${APP_NAME}-$$`.  
7. Persistence path is `${HOME}/.local/${APP_NAME}` and the directory exists after resolve.  
8. Tests cover the chains (`tests/test_cli.sh` **TP-CLI-06** · **TP-CLI-12** · **TP-CLI-19** · **TP-CLI-20**).  
9. Implementation changes cite this requirement key `requirement-shell-cli-storage`.

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-modular-function-design.md` | `util_*` ownership |
| `docs/requirements/requirement-shell-output-requirements.md` | about JSON via `out_json` |
| `docs/requirements/requirement-shell-self-management.md` | about lifecycle |
| `docs/requirements/requirement-shell-cli-interface.md` | about command |
| `./sshd-cli` | Implementation under test |
| `tests/test_cli.sh` | Storage diagnostics tests |
| `reviews/test-plan.md` | TP map |
| `reviews/reports/2026-09-27-checklist-temp-file-system-cache-folder.md` | Filled temp-file checklist for this chain |

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-08-03 | Active | Storage resolve for scratch |
| 2026-09-11 | Active | Git Bash `/dev/shm` mkdir fail-soft (INC-20260911-001) |
| 2026-09-17 | Active 1.2.0 | Preferred `/dev/shm/cache/${APP_NAME}-${USERNAME}` |
| 2026-09-27 | Active 1.3.0 | Per-login per-process cache leaves. Linux shm → tmp → `${HOME}/.cache`. Git Bash tmp → AppData Local Temp. Mac tmp → Library/Caches → `${HOME}/cache`. Silent tier miss. `about` prints used / preferred / 1st / 2nd. Persistence stays `${HOME}/.local/${APP_NAME}` |
| 2026-09-28 | Active 1.3.1 | Persistence leaf `language` (menu language). Codes and copy stay on `requirement-shell-cli-language`. |
| 2026-09-28 | Active 1.3.2 | The `language` leaf accepts `en`, `zh-Hant`, `es`, `fr`, `de`, and `zh-Hans`. |
| 2026-09-28 | Active 1.3.3 | The `language` leaf also accepts `ja` and `ko`. |
| 2026-10-02 | Active 1.3.4 | The `language` leaf accepts the thirteen codes on `requirement-shell-cli-language` **1.5.0** (`ar`, `pt`, `ru`, `nl`, `el` added). |

---

**Last Updated**: 2026-10-02 (1.3.4 language leaf accepts the thirteen codes. 1.3.3 language leaf also accepts `ja` and `ko`. 1.3.2 language leaf accepts the six codes. 1.3.1 persistence leaf `language`)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 4, 5, 11, 19, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
