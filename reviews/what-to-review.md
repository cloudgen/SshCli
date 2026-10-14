# What to review — sshd-cli

**Living checklist** (review plan). Product: **sshd-cli** — simplify Termux to install sshd.  
**Class:** software-development · domain SSOT `requirement-domain-sshd` · online-install channel + TTY menu / non-TTY CLI self-install.  
**Always load first:** `reviews/lessons.md`

**Last plan update:** 2026-10-14  
**Ship unit VERSION:** 1.35.0  
**Suite baseline:** see `reviews/test-plan.md`

---

## Pre-flight

| # | Check | Notes |
|---|--------|-------|
| P1 | Read `docs/requirements/index.md` | 33 Active (class + 28 shell + domain sshd + 3 pointers), including `requirement-shell-exit-condition` and the nine CLI coding homes. The Git Bash home owns the MSYS gzip-stdin ban. The ship unit still pipes |
| P2 | Confirm ship unit `src/sshd-cli` / `./sshd-cli` | `APP_NAME` / `VERSION` hard-assign (**1.35.0**); same bytes |
| P2a | Language menu numbers | Front **7** language. Block **70–89** is at most 20 languages. Assigned **71–83**. **70** and **84–89** are not printed. Front **8** is not a row. **TP-CLI-24** |
| P3 | Load `reviews/lessons.md` and re-check open L-* that still apply | Skip L-SUDOERS / restore lessons as parent-only |
| P4 | Run `./tests/run.sh` | Record PASS/FAIL/SKIP in report |
| P5 | Confirm install **channel** is `cloudgen/sshd-cli` | `SCRIPT_URL` default raw GitHub |
| P6 | Confirm retired verbs stay unknown | `backup` / `restore` (not `backup-config`). `print-sudoers` is live (menu **53**) |
| P7 | Human-facing | Every REQ has §1.1; README Description is people language; help does not lead with Type 0 |
| P8 | Normal-user-only CLI | Termux / Git Bash / Windows cmd: no `sudo curl`, no `pkg` except Termux named list |

---

## Product law surfaces

| Surface | Path | Review focus |
|---------|------|--------------|
| Class | `requirement-class-software-dev.md` | posix-sh; Termux sshd purpose; **project nature** |
| Domain | `requirement-domain-sshd.md` | status/start/stop/port/keys/menu/dns; `fix-config` comments unsupported OpenSSH client keywords by OS and runs on every start against `~/.ssh/config`; Termux daemonize; POSIX Linux systemd `systemctl` unit path; this-login ssh_config dns-ip; non-root server hides **22–24**; Termux Old OpenSSH comments + `ssh -o`; TTY unknown choice redisplay; **upload** client **14** (**TP-UL-01..18** are a fake `ssh`, not an MSYS reader; **TP-OS-*** are todo); sudoers front **5** |
| CLI interface | `requirement-shell-cli-interface.md` | This-login + domain commands, flags, dispatch; dual mention |
| Empty argv | `requirement-shell-cli-zero-arguments.md` · `requirement-shell-cli-self-install.md` | TTY **menu** / non-TTY **CLI self-install** (not payload) |
| Self-management | `requirement-shell-self-management.md` | install / self-update / self-uninstall; companion **call site** |
| Path / shell-rc | `requirement-shell-path-and-shell-support.md` | PATH + profile; sibling unify; **TP-LC-20..22**; `rc-test` ship Gap |
| Output SSOT | `requirement-shell-output-requirements.md` | `out_*`; JSON errors |
| Exit catalog | `requirement-shell-exit-condition.md` | `out_die` status 1; direct `return 1`; status 0; warn-and-continue |
| Modular design | `requirement-shell-modular-function-design.md` | domain prefix **`sshd_*`** |
| Idempotency | `requirement-shell-idempotency.md` | Re-install / pipe re-run (not TTY empty argv); bashrc exact-PATH no-op |
| Storage | `requirement-shell-cli-storage.md` | Per-login per-process cache (Linux shm → tmp → `~/.cache`; Git Bash tmp → AppData; Mac tmp → Library/Caches → `~/cache`); silent tier miss; persistence `${HOME}/.local/${APP_NAME}` |
| Interactive vs non-interactive | `requirement-shell-interactive-vs-noninteractive.md` | TTY ask vs pipe never-wait; unknown TTY menu redisplay |
| Script coding | `requirement-shell-script-coding.md` | `set -u`; do-not-capture-read |
| Automatic checksum | `requirement-shell-automatic-checksum.md` | Companion link/value/result; CHECKSUM not on help |
| Termux-ish | `requirement-shell-termux-ish.md` | Detect / named `pkg`; Android wake lock auto-acquire + `wake-lock`; Git Bash / Windows cmd |

**Do not review as this product’s law:** folder-archive backup, restore dest whitelist, sudoers-file emit (those remain on sibling **folder-backup**).

---

## Coverage honesty (this product)

| Claim | Truth |
|-------|--------|
| Online channel | **In scope** (`SCRIPT_URL`, `self-update`, `version-check`) |
| Empty argv | Split: TTY menu / non-TTY CLI self-install |
| Checksum in Core CI | **TP-CSUM-01** (file:// link + PASS-or-warn); not TP-LC-01 |
| Domain TPs | Present for status Connect, menu, pkg, start-after-install, ssh/download/upload, TTY unknown-menu retry; full start/stop/port/keys behavior still residual |

---

## Human-readability gate

- [ ] Each registered `requirement-*.md` has **§1.1 Human-facing** (one sentence, three boxes, includes/excludes, practice)
- [ ] Lead is not only Type 0 / Type 1 / euid / F6
- [ ] §1.1 says **project nature**, not **project class**
- [ ] Product README Description uses the same voice pack; Features/Usage do not lead with catalog codes
- [ ] README does **not** recommend `sudo curl | sh` for Termux / Git Bash / Windows cmd


## Menu numbers (2026-10-14)

- [x] Front **5** is sudoers on POSIX Linux (children **51–55**). Termux / Git Bash / Windows cmd omit **5** and print the sudoers hide sentence
- [x] Front **6** is self-management (children **61–67**). TTY **62** runs about
- [x] Front **7** is language on every host, including Termux / Git Bash / Windows cmd
- [x] Language rows are reserved **70–89** (twenty numbers, not more than 20 languages)
- [x] Assigned rows are **71** English, **72** 简体中文, **73** 繁體中文, **74** Español, **75** العربية, **76** Français, **77** Português, **78** Русский, **79** Deutsch, **80** 日本語, **81** 한국어, **82** Nederlands, **83** Ελληνικά
- [x] **70** and **84–89** are not printed; choosing **70**, **84**, or **89** warns and does not write `language`
- [x] Front **8** is not a row
- [x] Requirements, review matrix, test plan, and **TP-CLI-14** / **TP-CLI-21** / **TP-CLI-24** / **TP-CFG-17** name the same numbers
- [x] `src/sshd-cli` and `./sshd-cli` are the same bytes, and `sshd-cli.sha256` is the bare hex of that file
