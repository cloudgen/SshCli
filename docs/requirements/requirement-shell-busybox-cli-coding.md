**file**: docs/requirements/requirement-shell-busybox-cli-coding.md  
**Status**: Active (Version 1.0.0)  
**Area**: shell  
**Key**: `requirement-shell-busybox-cli-coding`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This file owns BusyBox and toybox CLI coding for sshd-cli: how a multi-call applet is started, and the rule that a BusyBox `tar` keeps the streamed `tar.gz` pipe.

### 1.1 Human-facing

**In one sentence:** When `tar` is BusyBox, folder upload still uses the pipe, and a multi-call tool is started as `busybox` plus the tool name.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Someone whose `tar` is a BusyBox applet | `busybox tar` |
| The other role | A standalone `tar` binary | Leave that filename alone |
| Not this file | The MSYS2 file transfer | Git Bash coding home |

| Includes | Excludes |
|----------|----------|
| `busybox APPLET` / `toybox APPLET` and the streamed pipe | `--coreutils-prog` and applet renaming |
| Fail closed when `tar czf -` is missing | Switching to the MSYS file transfer |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Upload where tar is BusyBox | The pipe stays | `sshd-cli upload phone ./box` |

---

## 2. Core Rules / Requirements (Mandatory)

1. A multi-call BusyBox tool **MUST** be started as `busybox APPLET`, or by a symlink whose own name is the applet. Toybox uses `toybox APPLET`. A regular file that already is the applet **MUST** be left as that file.  
2. The program **MUST NOT** pass `--coreutils-prog`. It **MUST NOT** rename a filename-selected applet, and it **MUST NOT** rename one and wrap the new name in a script that uses the old name.  
3. The version line is the first line of `busybox` with no arguments. This ship unit does not print that line. A test **MUST NOT** expect it.  
4. An interpreter basename `busybox` during self-install is a shell, not an applet. That case stays on `requirement-shell-cli-self-install`.  
5. `download` and `upload` **MUST** keep the streamed pipe when `tar` or `gzip` is BusyBox or toybox. They **MUST NOT** use the MSYS2 finished-file transfer. A BusyBox reader that cannot do `tar czf -` **MUST** fail closed and name `tar` or `gzip`. It **MUST NOT** switch to the MSYS file transfer to get past that missing feature.  
6. The live BusyBox call in this ship unit is `busybox ifconfig` as a fallback. This file does not add a second call.

### 2.1 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Live call | `busybox ifconfig` fallback only |
| Transfer | streamed pipe. Ship unit already pipes |
| Proof | **TP-OS-BB-01** todo |

### 2.2 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): BusyBox `tar` is not MSYS `tar`. The pipe stays.  
- **CIAO Principle 5 – SSOT** (https://github.com/cloudgen/ciao): Applet start shape has this file. The MSYS ban does not.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Do not rename an applet to make a test pass.  
- **Intentional**: The pipe is the transfer.  
- **Anti-fragile**: A missing `czf -` fails closed and names `tar` or `gzip`.  
- **Over-protect**: Do not borrow the MSYS file transfer.

## 4. Protection Rules

**Future AI assistants or maintainers MUST NOT**:

1. Pass `--coreutils-prog`.  
2. Rename a filename-selected applet.  
3. Replace a BusyBox pipe with the MSYS finished-file transfer.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-domain-sshd.md` | Pipe contract |
| `docs/requirements/requirement-shell-alpine-cli-coding.md` | Alpine often ships BusyBox |
| `docs/requirements/requirement-shell-cli-self-install.md` | Interpreter basename `busybox` |
| `docs/requirements/requirement-shell-windows-git-bash-cli-coding.md` | MSYS2 exception |
| `docs/requirements/index.md` | Registry |

## 6. Design-time verification

| TP family / ID | What it shows | Status |
|----------------|---------------|--------|
| **TP-OS-BB-01** | BusyBox keeps the streamed pipe and does not rename applets | todo |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-10-14 (1.0.0 BusyBox keeps the streamed pipe)  
**Owner**: sshd-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
