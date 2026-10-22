# What to review — SshCli

**Living checklist** (review plan). Product: **SshCli** **2.0.0** — console script `sshd-cli`. Python text menu for OpenSSH sshd and this login’s SSH client.  
**Class:** software-development · domain SSOT `requirement-domain-sshd` **1.28.0** · pip lifecycle · TTY menu / non-TTY help.  
**Always load first:** `reviews/lessons.md`

**Last plan update:** 2026-10-22  
**Ship unit VERSION:** 2.0.0 (Python). Last shell ship unit: 1.35.1 in `legacy/sshd-cli.sh`.  
**Suite baseline:** see `reviews/test-plan.md`

The shell review rows below this pre-flight describe the retired `/bin/sh` program. Use them when a behavior is supposed to survive. The Active law is the Python requirements.

---

## Pre-flight

| # | Check | Notes |
|---|--------|-------|
| P1 | Read `docs/requirements/index.md` | Active: class **1.1.0**, twelve Python requirements, domain **1.28.0**. Shell rows are Retired. An MSYS reader still uses a finished file |
| P2 | Confirm ship unit `src/SshCli` and `./sshd-cli` | Package version **2.0.0**. Console script `sshd-cli`. `./sshd-cli` is the Python launcher, not a byte copy of the shell script |
| P2a | Menu numbers | Front **1** client-side, **2** server-side, **3** system-log, **4** language, **5** sudoers, **8** self-management, **9** Exit. Language **41–53**. Pip **82–87**. Shell **6** and **7** are not rows |
| P3 | Load `reviews/lessons.md` and re-check open L-* that still apply | Skip L-SUDOERS / restore lessons as parent-only |
| P4 | Run `./tests/run.sh` | Python unittest. Record PASS/FAIL/SKIP. Do not require the legacy shell suite |
| P5 | Confirm the repository is `cloudgen/sshd-cli` | Install is `python -m pip`, not `curl \| sh` |
| P6 | Confirm removed video verbs stay unknown | `join` and `list-videos`. `hello` still prints the welcome line. `print-sudoers` is live (menu **53**) |
| P7 | Human-facing | Active requirements have §1.1. README is people language. Help does not lead with Type 0 |
| P8 | Normal-user-only CLI | Termux / Git Bash / Windows cmd: no sudoers row, no backup-config row, no `sudo` wrap, no `pkg` except Termux `install` |

---

## Product law surfaces

| Surface | Path | Review focus |
|---------|------|--------------|
| Class | `requirement-class-software-dev.md` | posix-sh; Termux sshd purpose; **project nature** |
| Domain | `requirement-domain-sshd.md` | status/start/stop/port/keys/menu/dns; `fix-config` comments unsupported OpenSSH client keywords by OS and runs on every start against `~/.ssh/config`; Termux daemonize; POSIX Linux systemd `systemctl` unit path; this-login ssh_config dns-ip; non-root server hides **22–24**; Termux Old OpenSSH comments + `ssh -o`; TTY unknown choice redisplay; **upload** client **14** (**TP-UL-01..18** are a fake `ssh`, not an MSYS reader; **TP-OS-GB-01..04** and **TP-OS-CMD-01** have; **TP-OS-ALP-01**, **TP-OS-BB-01**, **TP-OS-OTH-01** stay todo); sudoers front **5** |
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
