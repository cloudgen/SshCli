**file**: docs/requirements/requirement-class-software-dev.md  
**Status**: Active (Version 1.0.7 – family CLI coding owned by the nine shell coding homes; the Git Bash home owns the MSYS gzip-stdin ban; exit catalog owned by requirement-shell-exit-condition)  
**Area**: class  
**Key**: `requirement-class-software-dev`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

Declare this workspace as a **software-development** project class and hold the **residual collection** of software-engineering stack facts **not already owned** by more specific Active `requirement-shell-*.md` peers: primary language, toolchain policy, package/test tooling, and runtime OS family.

This file is **class law + residual SSOT**, not a second copy of Type 0 lifecycle, checksum, output, or storage tables (those stay on peer shell requirements).

### 1.1 Human-facing

**In one sentence:** This folder’s **project nature** is **software-development**: we write a POSIX `/bin/sh` program people can install (`./sshd-cli`) to **simplify Termux to install sshd** — not a blank starter kit and not a server-maintenance allowlist.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Someone building or installing this CLI | Ship unit `./sshd-cli` + `tests/run.sh` |
| The other role | A genesis seed (empty law) or a server-maintenance tree (host allowlists) | Those are **not** this workspace |
| Not this file | Install, help, checksum, storage — peer shell requirements own those tables | `requirement-shell-cli-interface.md` and peers |

| Includes | Excludes |
|----------|----------|
| Language and toolchain leftovers nobody else owns (`posix-sh`, no package tool) | A second copy of install / output / checksum law |
| Honest “none” when a topic is considered and not used | Inventing a dedicated-account approver this product does not have |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Program file people install | Live stack (POSIX `/bin/sh`) |
| This file | Class + residual notes | What kind of work this folder is |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Confirm the stack | Primary language is POSIX `/bin/sh`. There is no `package.json` / compiler. Tests are shell. | `./tests/run.sh` |
| Look for install rules | They live on the empty-argv and CLI-interface requirements, not here. | Read those peer files; run `sshd-cli help` |

---

## 2. Core Rules (Mandatory)

### 2.0 Project class membership

1. **MUST** treat this workspace as **software-development** (shippable software), not genesis-template and not server-maintenance.  
2. **MUST** use basename **`requirement-class-software-dev.md`** as the sole Active class-law file for this class.  
3. **MUST NOT** register an Active `requirement-class-server-maintenance.md` while class is software-development.  
4. **MUST** retain portable harness knowledge; specialized product knowledge lives in this and peer `requirement-*.md` files.  
5. **MUST** apply software-development SSOT/gate posture when claimed (identity triad, channel, ship unit, precommit when git is used — as applicable).  
6. **MUST NOT** invent hollow product docs solely to look specialized; collect real values or defer explicitly.

### 2.1 Residual collection principle (SSOT hygiene)

7. **MUST** treat this file as the **default home** for software-stack facts **not owned** by another Active requirement.  
8. **MUST NOT** duplicate full normative tables that already live in a more specific Active requirement (e.g. full Type 0 self-management, automatic-checksum law, `out_*` catalog). Prefer a **one-line pointer** to the peer requirement key.  
9. When a new specialized requirement **takes ownership** of a topic previously only listed here, **MUST** update this file in the **same change**: remove or shrink the residual entry and point to the new owner.  
10. **MUST NOT** leave contradictory stack facts across this file and peer requirements (e.g. two different “primary language” claims).

### 2.2 Programming language(s)

11. **MUST** declare at least one **primary programming language** (or language family) for the ship unit / product implementation.  
12. **SHOULD** list secondary languages only when they are real product law, not incidental docs.  
13. **MUST** state whether the product is primarily: interpreted, compiled, polyglot, or package-multi-language — as a closed choice.  
14. **MUST NOT** freeze a marketing product name as if it were the language name; language identifiers are stack facts (e.g. `posix-sh`), not brands of *this* product.

### 2.3 Compilers, interpreters, and toolchains

15. **MUST** declare the **target toolchain class** used to build or run the product.  
16. **MUST** state version policy as one of: unconstrained · minimum version · range · pinned.  
17. **SHOULD** record whether cross-compilation is in scope.  
18. **MUST** fail closed in CI/docs claims: do not claim “supports all compilers” without tests or explicit unconstrained policy.

### 2.4 Project / package / build tools

19. **MUST** declare the **primary project or package tool** used for dependencies and builds.  
20. **MUST** declare how dependencies are resolved when the ecosystem supports lockfiles.  
21. **SHOULD** name the test runner and linter/formatter **classes** when they are project law.  
22. **MUST NOT** require a secret token or private registry password in this file.

### 2.5 Runtime and platform (residual)

23. **MUST** declare the intended **primary runtime/OS family** choice set when not fully owned by another architecture requirement.  
24. **SHOULD** declare minimum CPU/arch support only when it is real product law.  
25. **MUST** separate **developer machine** toolchain requirements from **end-user runtime** requirements when they differ.

### 2.6 No-hardcode / dual policy (class file)

26. **MUST NOT** hard-code a single product/app brand, one org’s production hostname, or personal owner identity as universal core law.  
27. **MUST** put live product name, repo slug, and concrete stack choices in **Implementation Notes** (and product README/Config SSOTs where applicable) after collection — complete, not stubbed, when Status is Active.  
28. **MUST NOT** store secrets, PATs, or toy credentials in this file.

### 2.7 Implementation Notes (this project)

| Field | Value (sshd-cli) |
|-------|---------------------|
| **Project display name** | `sshd-cli` (product root `README.md` H1 SSOT) |
| **Project class** | software-development |
| **Class requirement basename** | `requirement-class-software-dev.md` |
| **Primary language(s)** | `posix-sh` (`/bin/sh`) |
| **Language role** | primary only — single-file shell ship unit |
| **Execution model** | **interpreted** — no compile step |
| **Toolchain / interpreter** | POSIX `/bin/sh` (dash/bash-as-sh compatible subset); no compiler |
| **Toolchain version policy** | **unconstrained** among POSIX sh implementations that pass `tests/` |
| **Cross-compile in scope?** | no |
| **Primary project/package tool** | **none** — no `package.json` / `pyproject` / language module system; ship unit is the source |
| **Lockfile policy** | not used |
| **Test runner** | `tests/run.sh` + `tests/test_cli.sh` + `tests/test_local_lifecycle.sh` (POSIX shell) |
| **Linter/formatter** | none as project law (shellcheck optional for maintainers, not required gate) |
| **Primary runtime / OS family** | POSIX Linux **and Termux** (Android userspace; `PREFIX` bin/etc). Git Bash and Windows cmd are the same **command line for normal user only** class as Termux (Type 1/2 unused). Also compatible UNIX where `/bin/sh` + coreutils/`sha256sum`/`mktemp` exist. Family coding: `requirement-shell-fedora-redhat-cli-coding`, `requirement-shell-debian-cli-coding`, `requirement-shell-macos-cli-coding`, `requirement-shell-termux-cli-coding`, `requirement-shell-windows-git-bash-cli-coding`, `requirement-shell-windows-cmd-cli-coding`, `requirement-shell-alpine-cli-coding`, `requirement-shell-busybox-cli-coding`, `requirement-shell-other-linux-cli-coding`. The Git Bash home owns the MSYS gzip-stdin ban. This file does not copy that ban. `sshd_fix_os_class` stays `alpine` \| `termux` \| `posix` |
| **Architectures supported** | any arch with a POSIX sh and the external tools the script invokes (no arch-specific binary) |
| **Git surface** | used for product publish (`github.com/cloudgen/sshd-cli`) |
| **Ship unit / install** | yes — repo root `./sshd-cli` + companion `sshd-cli.sha256`; Type 0 online install (peer shell REQs) |
| **Product version SSOT** | `VERSION="…"` hard-assign in `./sshd-cli` (currently `1.6.0`) |

**Residual ownership table:**

| Topic | Owner | Notes |
|-------|-------|--------|
| Project class membership | **this file** | Fixed |
| Primary language + toolchain policy | **this file** | posix-sh, unconstrained |
| Package/build tool + lockfile | **this file** | none / not used |
| Type 0 CLI surface / flags / dispatch | `requirement-shell-cli-interface` | Do not duplicate |
| Empty argv TTY menu / non-TTY CLI self-install | `requirement-shell-cli-zero-arguments` · `requirement-shell-cli-self-install` | Do not duplicate |
| Self-management lifecycle | `requirement-shell-self-management` | Do not duplicate |
| PATH / profile / shell-rc sibling unify | `requirement-shell-path-and-shell-support` | Do not duplicate |
| Automatic companion digest | `requirement-shell-automatic-checksum` | Do not duplicate |
| Output SSOT (`out_*`) | `requirement-shell-output-requirements` | Do not duplicate |
| Process exit catalog | `requirement-shell-exit-condition` | Do not duplicate the exit tables |
| Scratch/cache storage resolve | `requirement-shell-cli-storage` | Do not duplicate |
| Idempotency / re-run safety | `requirement-shell-idempotency` | Do not duplicate |
| Interactive vs non-interactive | `requirement-shell-interactive-vs-noninteractive` | Do not duplicate |
| Modular prefixes / single-file layout | `requirement-shell-modular-function-design` | Do not duplicate |
| Domain features / help / about extras | `requirement-domain-sshd` | OpenSSH sshd helper (Termux-first) |
| Termux-ish `pkg` invoke | `requirement-shell-termux-ish` | This-login `pkg`; not Linux `apt` |
| Command line for normal user only | `requirement-shell-cli-interface` · `requirement-shell-termux-ish` | Termux / Git Bash / Windows cmd: Type 1/2 unused; named section on related shell REQs |
| Coding-style related REQ | `requirement-shell-script-coding` | Portable style; class residual **points** |
| Fedora / Red Hat CLI coding | `requirement-shell-fedora-redhat-cli-coding` | One family; no `dnf` wrap; not a new OS class |
| Debian CLI coding | `requirement-shell-debian-cli-coding` | One family; no `apt` wrap; no hardcoded Ubuntu |
| macOS CLI coding | `requirement-shell-macos-cli-coding` | Darwin cache and digest fence |
| Termux CLI coding | `requirement-shell-termux-cli-coding` | Detect and coding fence; `pkg` stays on termux-ish |
| Windows Git Bash CLI coding | `requirement-shell-windows-git-bash-cli-coding` | Git Bash fence; owns the MSYS gzip-stdin ban; Windows cmd stays a different detect |
| Windows cmd CLI coding | `requirement-shell-windows-cmd-cli-coding` | Keeps the streamed pipe; `Windows_NT` is not the MSYS ban |
| Alpine CLI coding | `requirement-shell-alpine-cli-coding` | Keeps the streamed pipe; GSSAPI stays on the domain file |
| BusyBox CLI coding | `requirement-shell-busybox-cli-coding` | Keeps the streamed pipe; applet calls stay `busybox APPLET` |
| Other Linux CLI coding | `requirement-shell-other-linux-cli-coding` | POSIX Linux outside the named families; keeps the streamed pipe |
| Actor / role / subject / approver | *none* (considered — **no dest approver**) | No dest review machine |
| Dest fence conditions | *none* (considered — **no dest fence conditions**) | No dest inbound queue |
| Login-review hook | *none* (considered — **no login-hook**) | Type 0 sshd helper; no dest review scrap |
| Type 1 rc-owner heal | *none* (considered — **this-login writer**) | No elevated `setup` `chown` of another home |

---

## 3. Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional Verbosity & Transparency** (https://github.com/cloudgen/ciao): Class and stack choices are explicit, not assumed from folder names.  
- **CIAO Principle 5 – Single Source of Output** (https://github.com/cloudgen/ciao): Residual stack facts have one home until specialized requirements take ownership (SSOT hygiene for law surfaces).  
- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Version and toolchain policies are declared; agents do not invent compilers or package managers.  
- **CIAO Principle 21 – Dual Policies** (https://github.com/cloudgen/ciao): Portable core; filled Implementation Notes; no product brand hardcode in core rules.  
- **CIAO Principle 4 (O) + Principle 20** (https://github.com/cloudgen/ciao): Protection Rule against dual stack SSOTs and wrong-class pollution.

---

## 4. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Assume toolchain and package tools are missing until declared and verified.  
- **Intentional**: Residual collection is deliberate — not a dump of every possible tool.  
- **Anti-fragile**: Unconstrained POSIX sh policy survives multi-env runs when tests pass.  
- **Over-protect**: Protection rule prevents dual stack SSOTs and genesis/class confusion.

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

**This requirement:** residual stack points at those owners; OS family includes Termux / Git Bash / Windows cmd as this class. Related shell REQs **MUST** keep a section with this exact title.

---

## 5. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Delete this file while the workspace remains **software-development** with other Active product requirements.  
2. Rename the specialized basename away from `requirement-class-software-dev.md` without an explicit class-model change.  
3. Hard-code secrets, personal owner identity, or production host FQDNs into core rules as universal law.  
4. Duplicate full peer shell-requirement bodies into this residual section.  
5. Leave Implementation Notes as hollow stubs when Status claims Active.  
6. Claim multi-language / multi-compiler support without tests or explicit policy.  
7. Treat this file as server-maintenance allowlist law, or register an Active server-maintenance class file in parallel.  
8. Invent a second primary language SSOT that contradicts peer modular/CLI requirements.  
9. Strip the **Under command line for normal user only** section, or treat Termux / Git Bash / Windows cmd as Type 1 hosts.

**Violating any of these is considered a critical regression.**

---

## 6. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Active registered `requirement-class-software-dev.md` matches software-development class |
| AC-2 | Primary language + toolchain policy + package tool declared in Implementation Notes (complete) |
| AC-3 | Residual ownership table honest: no silent dual SSOT with peer shell REQs |
| AC-4 | Core rules remain free of frozen secret/host hardcodes |
| AC-5 | No class file conflict with `requirement-class-server-maintenance` |
| AC-6 | Ship unit identity (posix-sh single-file Type 0) consistent with peer shell REQs |

---

## 7. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-shell-cli-interface` | Command surface, flags, dispatch |
| `requirement-shell-cli-zero-arguments` | Type O empty argv |
| `requirement-shell-self-management` | Lifecycle |
| `requirement-shell-path-and-shell-support` | PATH / profile / sibling unify |
| `requirement-shell-automatic-checksum` | Companion integrity |
| `requirement-shell-output-requirements` | `out_*` SSOT |
| `requirement-shell-exit-condition` | Process exit catalog (`out_die` and `return 1`) |
| `requirement-shell-cli-storage` | Scratch/cache resolve |
| `requirement-shell-idempotency` | Re-run safety |
| `requirement-shell-interactive-vs-noninteractive` | Mode policy |
| `requirement-shell-modular-function-design` | Prefixes / single-file modularity |
| `requirement-shell-script-coding` | Portable coding-style home (this file points) |
| `requirement-shell-fedora-redhat-cli-coding` | Fedora / Red Hat CLI coding |
| `requirement-shell-debian-cli-coding` | Debian / Ubuntu CLI coding |
| `requirement-shell-macos-cli-coding` | macOS CLI coding |
| `requirement-shell-termux-cli-coding` | Termux CLI coding |
| `requirement-shell-windows-git-bash-cli-coding` | Windows Git Bash CLI coding; owns the MSYS gzip-stdin ban |
| `requirement-shell-windows-cmd-cli-coding` | Windows cmd CLI coding |
| `requirement-shell-alpine-cli-coding` | Alpine CLI coding |
| `requirement-shell-busybox-cli-coding` | BusyBox CLI coding |
| `requirement-shell-other-linux-cli-coding` | Other POSIX Linux CLI coding |
| `requirement-domain-sshd` | OpenSSH sshd domain SSOT |
| `requirement-shell-sudoer` | Sudoer features SSOT (JSON, print/generate/submit, `util_sudo`) |
| `requirement-shell-config-backup` | `backup-config` / `sync-config` (depends on sudoer) |
| `requirement-sshd-config-backup` | Points at shell-config-backup |
| `requirement-sudoer-json-file` | Points at shell-sudoer |
| `requirement-three-layer-privilege-model` | Type 0/1/2; sudoer verbs point at shell-sudoer |
| `requirement-shell-sudo-command` | Points at shell-sudoer (`util_sudo`) |
| `docs/requirements/index.md` | Registry SSOT |

---

## 8. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-07-19 | Active | Specialized class law for sshd-cli (review fix F1) |
| 2026-10-10 | Active 1.0.5 | Exit catalog points at `requirement-shell-exit-condition`. This file does not copy the tables |
| 2026-10-14 | Active 1.0.6 | Family CLI coding points at the five shell coding homes. This file does not copy those fences |
| 2026-10-14 | Active 1.0.7 | Points at nine shell coding homes. The Git Bash home owns the MSYS gzip-stdin ban. This file does not copy that ban |

---

**Last Updated**: 2026-10-14 (1.0.7 nine family coding homes; Git Bash owns the stdin ban. 1.0.6 family CLI coding pointer. 2026-10-10 (1.0.5 exit catalog pointer. Prior: 2026-09-09 residual path-and-shell-support))  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 4, 5, 20, 21 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
