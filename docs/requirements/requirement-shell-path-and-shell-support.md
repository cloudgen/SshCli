**file**: docs/requirements/requirement-shell-path-and-shell-support.md  
**Status**: Retired (Python generation 2.0.0. The live ship unit is the SshCli package. This file records the /bin/sh ship unit through 1.35.1. Where it disagrees with requirement-domain-sshd 1.28.0 or an Active requirement-python-*.md / requirement-runtime-prerequisites.md file, those win.) Was  (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-path-and-shell-support`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This file is the **topic-owner** for **shell-rc** edits on sshd-cli: after a **user-bin** install, this login can run `sshd-cli` by name, and an SSH login can reach that PATH.

It owns **path-ensure** (one shared `USER_BIN` line on interactive rc) and **profile-ensure** (create `~/.profile` if missing so a login shell sources `.bashrc`). It also owns **sibling unify** so another similar CLI does not, *by design*, make `.bashrc` non-compliant; **heal** on every `install`; **scoped uninstall**; and **detect** via a Type 0 `rc-test` (not a lock on the file).

**Scope:** Which rc files this product writes; the exact PATH line; create / append / no-op; profile create-if-absent; write-path env; sibling comments; uninstall of **this** product’s stickers; fixture tests; `rc-test`.  
**Out of scope (cited, not re-owned):** Placing or removing the binary (`requirement-shell-self-management`); Termux `pkg` (`requirement-shell-termux-ish`); sshd start/stop (`requirement-domain-sshd`); scratch/cache (`requirement-shell-cli-storage`).

**Not claimed:** login-review hook; Type 1 `setup` `chown` of another login’s rc; `/etc/environment`; crontab.

### 1.1 Human-facing

**In one sentence:** After `sshd-cli install`, this login’s desk note (`.bashrc`) gets “also look in `~/.local/bin`,” and if the door note (`.profile`) is missing the program hangs one that sources `.bashrc` — without wiping notes other programs already wrote.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The person who ran install | `sshd-cli install` |
| The other role | Tests that point `BASHRC` at a throw-away folder | `sshd-cli rc-test --root "$tmpdir" --file bashrc --case create` |
| Not this file | Copying the program into `~/.local/bin`; starting sshd | `requirement-shell-self-management.md` · `requirement-domain-sshd.md` |

| Includes | Excludes |
|----------|----------|
| One shared PATH line; create `.bashrc` if missing; create `.profile` if missing | Login-review scrap; dest JSON owner; `/etc` PATH |
| Keep other apps’ comments; heal PATH if a sibling deleted the line | Locking `.bashrc` so nobody else can write; replacing the whole file |

| Surface | What you open | What for |
|---------|---------------|----------|
| `sshd-cli install` | Command | Companion writes PATH + profile |
| `sshd-cli rc-test` | Test-purpose command | Create / modify / no-op against a temp folder |
| `sshd-cli help` | Command | Environment lists `BASHRC`; testers listed **apart** from operational verbs |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Install for yourself | Program file goes in `USER_BIN`; PATH line is added once; missing `.profile` is created. A second install does not duplicate the PATH line. | `sshd-cli install` |
| Prove PATH without touching this login’s real `.bashrc` | A temp folder is the scratch pad. Real home rc stays still. | `sshd-cli rc-test --root "$tmpdir" --file bashrc --case create` |
| Remove this program while other tools remain in `~/.local/bin` | PATH line stays. Only this product’s installer comments may go. | `sshd-cli --force self-uninstall` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Catalog (claimed vs unused)

| Feature | This product | Files |
|---------|--------------|-------|
| **path-ensure** | **Claimed** | `.bashrc` (`BASHRC`): create if missing. `.zshrc` (`ZSHRC`): only if the file exists (do **not** invent it). Fish `config.fish` (`FISH_CONFIG`): create the config dir if needed. **Not** `.profile` |
| **profile-ensure** | **Claimed** | `.profile` (`PROFILE`): create if absent with a sample that sources `.bashrc`; **never overwrite** an existing body |
| **login-hook** | **Unused** | Do **not** plant a review scrap in `.bashrc` or `.profile` |
| **rc-owner** | **This-login writer** | After create/modify, mode readable (`0644`). No Type 1 `setup` `chown` of another login’s home. Writer **is** this login |

| File | path-ensure | profile-ensure | login-hook | rc-owner |
|------|-------------|----------------|------------|----------|
| `.bashrc` | Yes (create) | — | **Unused** | This login |
| `.zshrc` | Yes if exists | — | Unused | This login |
| `.profile` | **No** PATH line | **Yes** | Unused | This login |
| Fish `config.fish` | Yes (create dir) | — | Unused | This login |

**MUST NOT** treat `~/.ssh-*` vault dirs as this family. **MUST NOT** write another user’s rc.

### 2.2 Shared identity (measure 1)

Several similar CLIs **MAY** write the same login’s `.bashrc`. They **MUST** share **one** PATH identity.

| MUST | MUST NOT |
|------|----------|
| Use the exact bash/zsh line `export PATH="<USER_BIN>:$PATH"` (`USER_BIN` default `${HOME}/.local/bin`) | A second dialect (`$HOME` vs the expanded path, extra quotes, a different prefix) that would miss the exact-line check |
| Fish: exact `set -gx PATH <USER_BIN> $PATH` | A second Fish dialect |
| If that exact PATH line already exists (this product or a sibling), **do not** append a second `export PATH=` | Duplicate the exact export |
| **MAY** append **only** `# Added by sshd-cli installer (<VERSION>)` when the shared PATH line is already present and this product’s comment is absent | Rewrite `# Added by <other-app> installer …` or any other product’s comment |
| Match the **exact** export line, not a `USER_BIN` substring | Treat a comment or unrelated line that contains `USER_BIN` as already-good |

The PATH line is **shared**. Compliance is “`USER_BIN` is on PATH,” not “only sshd-cli’s sticker is on the note.”

### 2.3 Append, never replace (measure 2)

| MUST | MUST NOT |
|------|----------|
| Create `BASHRC` if missing (header with `sshd-cli` / `VERSION`, then PATH) | `printf … >` an **existing** `.bashrc` / `.zshrc` / Fish config |
| Keep the prior body; append PATH if the exact line is absent | Truncate or rewrite the whole file to “ensure PATH” |
| Create `.profile` only when **absent** | Overwrite an existing `.profile` body |
| No-op when this product’s `VERSION` comments **and** the exact export already match (file bytes unchanged) | Replace a dongle or user rc |

A sibling that “ensures PATH” by writing a fresh file is how the first app’s compliance dies. This product **MUST NOT** be that sibling.

### 2.4 Scoped uninstall (measure 3)

`self-uninstall` PATH cleanup is `inst_self_uninstall_cleanup_path`. Dual mention: `requirement-shell-self-management` (remove the binary) · this file (what may be edited in rc).

| Situation | This product MAY remove | MUST NOT remove |
|-----------|-------------------------|-----------------|
| Other files still in `USER_BIN` | **Only** `# Added by sshd-cli installer …` comments | The shared `export PATH=` line; other apps’ comments; `.profile`; unrelated user lines |
| `USER_BIN` empty or missing | This product’s comments **and** the shared PATH line | `.profile`; unrelated user lines |

**MUST** match `# Added by sshd-cli installer` (this `APP_NAME`).  
**MUST NOT** use `/# Added by .* installer/d` while other tools remain.  
**MUST NOT** delete `.profile`.  
Root/global uninstall **MUST NOT** edit this-login rc PATH (system `GLOBAL_BIN` is already on PATH).

There is **no** OS lock that stops a naive other program from rewriting `.bashrc`. This product **MUST** follow the table so *it* is not that program.

### 2.5 Heal on every `install` (measure 4)

`inst_ensure_companion` **MUST** run **before** the already-installed binary no-op (call site: `requirement-shell-self-management`). This file owns what that companion does to rc:

1. Missing `BASHRC` → create + PATH.  
2. Exact PATH line gone → append once (header comment + export).  
3. Exact PATH + this `VERSION` comments already match → no-op.  
4. Missing `.profile` → create source-bashrc sample. Existing `.profile` → leave the body.

User-bin install only. **MUST NOT** run path-ensure for a root/global place into `GLOBAL_BIN`.

Re-running `sshd-cli install` **MUST** restore a missing exact PATH line without duplicating it. That is recovery after a bad sibling, not a file lock.

### 2.6 Detect, do not police (measure 5)

This product **MUST NOT** `chattr +i`, flock, or otherwise lock `.bashrc` against other writers. It **MUST** make non-compliance **visible** and **healable**.

| Detector | Role |
|----------|------|
| Type 0 **`rc-test`** | Test-purpose verb. Target = caller `--root` tmp/cache folder (or `mktemp -d`). **MUST NOT** write this login’s real `{{HOME}}/.bashrc`. Dual mention: `requirement-shell-cli-interface`. |
| Fixture suites | **TP-LC-20** create / **TP-LC-21** modify dongle / **TP-LC-22** VERSION+exact-PATH no-op with `BASHRC` in a random temp folder; real `{{HOME}}/.bashrc` untouched |
| `about` / `help` | Help Environment lists `BASHRC`. `about` **MUST NOT** claim rc is healthy without a check. `about` **MAY** report whether the exact PATH line is present |

**`rc-test` argv (normative sample):**

```text
sshd-cli rc-test --root "$tmpdir" --file bashrc --case create
sshd-cli rc-test --root "$tmpdir" --file bashrc --case modify
sshd-cli rc-test --root "$tmpdir" --file bashrc --case noop
sshd-cli rc-test --root "$tmpdir" --file profile --case create
```

| Flag | Meaning |
|------|---------|
| `--root` | Fixture directory (tmp/cache). Keep real `HOME`. |
| `--file` | `bashrc` \| `zshrc` \| `profile` (Fish when claimed) |
| `--case` | `create` \| `modify` \| `noop` |
| `--feature` | Optional: `path-ensure` \| `profile-ensure` (default from `--file`) |

**MUST:** invoke the same `path_add_*` / `path_ensure_profile` helpers production uses; assert real home rc untouched; no `sudo` except wrapping chmod/chown of **that** folder (this product: skip sudo — this login owns the fixture).  
**MUST NOT:** call `install` / dest / `setup` as part of `rc-test`; set `HOME=/tmp/…` to “isolate.”  
Help **MUST** list `rc-test` under a heading **apart** from operational verbs (install, start, …).

### 2.7 Write-path env

| Variable | Default | Tests |
|----------|---------|-------|
| `BASHRC` | `${HOME}/.bashrc` | Fixture file; **MUST** honor a non-empty override |
| `ZSHRC` | `${HOME}/.zshrc` | Fixture; honor override when zsh PATH is claimed |
| `FISH_CONFIG` | `${HOME}/.config/fish/config.fish` | Fixture; honor override when Fish PATH is claimed |
| `PROFILE` | `${HOME}/.profile` | Fixture; honor override when profile-ensure is claimed |

**MUST NOT** ignore a non-empty `BASHRC` (always write `${HOME}/.bashrc` instead). Same for `ZSHRC` / `FISH_CONFIG` / `PROFILE` when those helpers run.

Helpers: `path_add_shell` (orchestrator), `path_add_bashrc`, `path_add_zshrc`, `path_add_fish`, `path_ensure_profile`. Prefix ownership: `requirement-shell-modular-function-design`.

### 2.8 Implementation Notes (this project)

| Item | Value for sshd-cli |
|------|------------------------|
| **Product / binary** | `sshd-cli` (`APP_NAME`) |
| **Implementation** | Repo root `./sshd-cli` (`path_add_*`, `path_ensure_profile`, `inst_ensure_companion`, `inst_self_uninstall_cleanup_path`) |
| **USER_BIN** | `${HOME}/.local/bin` |
| **Exact PATH line** | `export PATH="<USER_BIN>:$PATH"` |
| **Installer comment** | `# Added by sshd-cli installer (<VERSION>)` |
| **Profile sample** | `# BEGIN sshd-cli profile source-bashrc` … source `${HOME}/.bashrc` … `# END sshd-cli profile source-bashrc` |
| **Companion call site** | `inst_ensure_companion` on `install` (including already-installed binary no-op). `self-install` / NI empty argv **MAY** call `path_add_shell` only (`requirement-shell-cli-self-install`). |
| **Privilege** | Type 0 this-login only |

#### Compliance notes (implementation status)

| Rule | Status |
|------|--------|
| Bash `BASHRC` create / exact-line append / VERSION+PATH no-op (**TP-LC-20..22**) | **Implemented** |
| Profile create-if-absent; never overwrite (**TP-LC-12** / **TP-LC-14**) | **Implemented** (`path_ensure_profile`; write path still `${HOME}/.profile`, not `PROFILE` env) |
| Heal on every `install` companion | **Implemented** |
| Empty-dir uninstall keeps shared PATH while `USER_BIN` has files | **Implemented** |
| Uninstall comment match **only** `sshd-cli` (not `# Added by .* installer`) | **Implemented** |
| Exact-line match on zsh / Fish (not `USER_BIN` substring) | **Implemented** |
| Honor `ZSHRC` / `FISH_CONFIG` / `PROFILE` env | **Implemented** |
| Comment-only append when sibling already wrote the exact PATH | **Implemented** (MAY) |
| `rc-test` routed; help testers heading | **Implemented** (`path_rc_test`; **TP-LC-31** · **TP-CLI-18**) |
| Login-hook | **Unused** (honest) |

#### Worked samples (this project — from `./sshd-cli`)

**Invocation (test-purpose, listed apart from operational help):**

```sh
sshd-cli rc-test --root "$tmpdir" --file bashrc --case create
sshd-cli rc-test --root "$tmpdir" --file bashrc --case modify
sshd-cli rc-test --root "$tmpdir" --file bashrc --case noop
sshd-cli rc-test --root "$tmpdir" --file profile --case create
sshd-cli --json rc-test --root "$tmpdir" --file bashrc --case create
```

**Sibling-unify comment-only** (exact PATH already present; MAY append this product’s sticker):

```sh
_comment=$(printf '# Added by %s installer (%s)' "$APP_NAME" "$VERSION")
if ! grep -qF "${_comment}" "$bashrc" 2>/dev/null; then
    printf '\n%s\n' "${_comment}" >> "$bashrc"
fi
```

**Profile create-if-absent** (never overwrite; honor `PROFILE`): helpers `path_ensure_profile` + `path_add_shell`. Bodies live in `./sshd-cli`.

### 2.9 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Never replace an existing rc body; never strip a shared `USER_BIN` PATH while other tools remain.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): File vs feature vs fixture named; PATH line vs this product’s comment named.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Second install heals a missing PATH line; sibling comments stay.  
- **CIAO Principle 5 – Single Source of Output** (https://github.com/cloudgen/ciao): User-visible PATH tips via `out_*`; file appends are class-C printf exceptions (`requirement-shell-output-requirements`).  
- **CIAO Principle 10 – Least-Privilege User** (https://github.com/cloudgen/ciao): This-login rc only; no in-tool `sudo` to edit another home.  
- **CIAO Principle 16 – Interactive vs Non-Interactive** (https://github.com/cloudgen/ciao): `rc-test` and install companion **MUST NOT** hang under `--json` / pipes.  
- **CIAO Principle 4 (O) / Principle 20** (https://github.com/cloudgen/ciao): Exact-line identity, scoped uninstall, and fixture tests are Protection Zone — not “simplify to echo PATH into `.bashrc`.”

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Assume another similar CLI will write the same files; assume `install` will be re-run.  
- **Intentional:** One exact PATH line; per-app comments; profile is the door note, not a second PATH file.  
- **Anti-fragile:** Heal on companion; no-op when already exact; keep sibling stickers.  
- **Over-protect:** Do not lock the file; do not police other writers; do not become the sibling that wipes the note.  
- **SSOT:** `path_*` bodies here; binary lifecycle on self-management; dispatcher on CLI-interface.  
- **Respect old working logic:** Keep `path_add_bashrc` exact-line grep and `path_ensure_profile` never-overwrite; surgical fixes for Gaps only.

---

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Write **this login’s** `BASHRC` / `USER_BIN` PATH | Rewrite another user’s rc; in-tool `sudo`; wrap `apt` |
| Termux: named `pkg` stays Type 0 (`requirement-shell-termux-ish`) | Recommend `sudo curl \| sh` so PATH ensure runs as root |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** PATH / profile ensure stay Type 0 this-login file writes. Tests retarget `BASHRC` to a temp folder — they **MUST NOT** require `sudo` or the developer’s real home.

---

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Replace an existing `.bashrc` / `.zshrc` / Fish config / `.profile` body to “ensure PATH.”  
2. Append a second exact `export PATH="<USER_BIN>:$PATH"` or invent a private PATH dialect.  
3. Rewrite another product’s `# Added by … installer` comment.  
4. Strip the shared PATH line on uninstall while `USER_BIN` still contains files.  
5. Delete `.profile` on uninstall.  
6. Ignore a non-empty `BASHRC` env (always write `${HOME}/.bashrc` instead).  
7. Leave `BASHRC` missing when `install` can create it.  
8. Skip `inst_ensure_companion` rc ensure because the CLI binary is already placed.  
9. Plant a login-review hook in `.bashrc` or `.profile` (unused on this product).  
10. Lock `.bashrc` (`chattr`, flock, exclusive ownership of the whole file) as “sibling protection.”  
11. Prove PATH ensure by rewriting this login’s real `~/.bashrc`.  
12. Claim path-ensure without **TP-LC-20** / **TP-LC-21** / **TP-LC-22**, or without dual-mentioning Type 0 **`rc-test --root`**.  
13. Mix `rc-test` into operational help grouping, or treat `rc-test` as install.  
14. Strip the **Under command line for normal user only** section, or wrap `sudo` / `apt` to write rc.

**Violating this rule is a critical shell-rc regression.**

---

## 5. Definition of done (path and shell support)

Work claiming PATH / login-rc support for sshd-cli is **not done** if any of the following fail:

1. User-bin `install` creates `BASHRC` if missing and appends the exact PATH line if absent.  
2. Existing rc body is kept.  
3. `.profile` is created only when absent; existing body is kept.  
4. Second install does not duplicate the exact PATH line; VERSION+exact-PATH is a no-op.  
5. Uninstall keeps the shared PATH line while `USER_BIN` has other files; does not delete `.profile`.  
6. **TP-LC-20** / **TP-LC-21** / **TP-LC-22** pass with `BASHRC` in a random temp folder; real `{{HOME}}/.bashrc` untouched. A HOME-isolated substring grep alone (**TP-LC-11**) is **not** sufficient.  
7. `rc-test` is dual-mentioned here and on `requirement-shell-cli-interface` and is routed.  
8. Implementation changes cite `requirement-shell-path-and-shell-support`.

---

## 6. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-cli-interface.md` | Dispatcher, `BASHRC` env, dual mention `install` / `rc-test` |
| `docs/requirements/requirement-shell-self-management.md` | Binary place/remove; companion **call site** |
| `docs/requirements/requirement-shell-idempotency.md` | Re-run matrix for PATH / profile |
| `docs/requirements/requirement-shell-modular-function-design.md` | `path_` prefix |
| `docs/requirements/requirement-shell-output-requirements.md` | `out_*`; class-C file printf |
| `docs/requirements/requirement-shell-termux-ish.md` | Termux `pkg` (not rc) |
| `docs/requirements/requirement-domain-sshd.md` | Help `install` row names `.bashrc` / `.profile` |
| `./sshd-cli` | Implementation under test |

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-LC-11** create `~/.bashrc` (HOME-isolated) | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-12** create `~/.profile` | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-13** no duplicate PATH | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-14** keep existing `.profile` | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-20** `BASHRC` env create-if-missing | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-21** `BASHRC` env modify dongle | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-22** `BASHRC` env VERSION+exact-PATH no-op | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-23 / 24** `ZSHRC` env modify / no-op | — | todo (when `ZSHRC` env is honored) |
| **TP-LC-25 / 26** `PROFILE` env create / keep-body | — | todo (when `PROFILE` env is honored) |
| **TP-LC-27** sibling PATH already present | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-28** uninstall keeps shared PATH | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-29** heal missing PATH | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-30** uninstall keeps `.profile` | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-31** `rc-test` create/modify/noop | `tests/test_local_lifecycle.sh` | have |
| **TP-CLI-18** help testers heading | `tests/test_cli.sh` | have |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-09-09  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
