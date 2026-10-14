**file**: docs/requirements/requirement-domain-sshd.md  
**Status**: Active (Version 1.27.4)  
**Area**: domain  
**Key**: `requirement-domain-sshd`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This is the **one Active domain SSOT** for **sshd-cli**. The product **purpose** is to **simplify Termux to install sshd**. OpenSSH **sshd** (the SSH server) plus this login’s **authorized_keys** are the domain; Termux is the first home and ordinary POSIX Linux is the second. Type 0 install/self-update/self-uninstall stay on the shell lifecycle requirements. This file owns specialized subcommands, features, help rows, and about fields.

Bootstrap origin is **selfmanaged** (A → B only). Domain law lives here on B, never on A.

### 1.1 Human-facing

**In one sentence:** You use `sshd-cli` so installing and running OpenSSH sshd on Termux is simple — one program, not a pile of path, port, and key steps.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | The person who wants SSH into this device | `sshd-cli status` · `sshd-cli start` |
| The other role | OpenSSH `sshd` + `sshd_config` + host keys | Termux `$PREFIX/etc/ssh` or Linux `/etc/ssh` |
| Not this file | Installing *this CLI* binary (`self-update`, checksum) | `requirement-shell-self-management.md` |

| Includes | Excludes |
|----------|----------|
| status / start / stop / restart / port / config / host-keys / auth-keys / menu / **dns** / **ssh** / **download** / **upload** | Wrapping `sudo` inside this CLI; writing systemd unit files; `termux-services` / `sv-enable`; cron-as-service; SSH *client* session mux / ProxyJump |
| OpenSSH sshd as a **background daemon** (`sshd -f`) on Termux and on Linux with **no** distro unit | Foreground `-D` on the OpenSSH fallback; `&` / `nohup` wrappers; a routed `systemctl` / `enable-service` verb |
| POSIX Linux **with** a loaded distro ssh/sshd unit: `start` / `stop` / `restart` via `systemctl` (root login) | `systemctl enable` / `disable` / `mask` / `daemon-reload` as CLI verbs; invoking `systemctl` on Termux / Git Bash / Windows cmd |
| This login’s `~/.ssh/config` **Host** entries as a numbered **dns-ip** list (alias → HostName) | Editing `/etc/hosts`; wrapping `systemd-resolved`; following `Include`; listing `Host *` / `?` wildcards |
| Termux `pkg install openssh termux-auth` as a companion of `install` (names + start after; invoke contract on `requirement-shell-termux-ish`) | Wrapping `apt` / `dnf` on POSIX Linux; owning Termux:Boot as a CLI verb |
| Android wake lock auto-acquire on Termux `start` (re-acquire verb on `requirement-shell-termux-ish`) | systemd-inhibit; auto-unlock on `stop`; `termux-services` as the lock |
| Termux user-level sshd and Linux system sshd with a root login | Inventing a dedicated `sshd-adm` account; auto-running `passwd` |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./sshd-cli` | Program | Live domain verbs |
| `sshd-cli help` | Command | Domain rows after Type 0 |
| `sshd-cli` (no args, terminal) or `sshd-cli menu` | Terminal list | Numbered domain choices |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Prepare Termux for sshd | `install` places this program, creates `~/.bashrc` / `~/.profile` if needed, and on Termux runs `pkg install -y openssh termux-auth` | `sshd-cli install` |
| See if sshd is up | Paths, port, pid, and a copy-paste `ssh -p …` line | `sshd-cli status` |
| Listen on Termux | Default port is often 8022. OpenSSH **forks itself** into the background. This is not a boot service. On Termux, `start` also asks Android to keep the CPU awake. | `sshd-cli start` then the Connect line from `status`. Acquire again: `sshd-cli wake-lock` |
| After a reboot | The daemon is gone with the old session. Start again. Termux:Boot (if you use it) is **your** hook, not a `sshd-cli` verb. | `sshd-cli start` — or put that command in `~/.termux/boot/` yourself |
| Allow a laptop key | Append one public-key file | `sshd-cli auth-keys add ./laptop.pub` |
| Name a phone for `ssh` | This login’s `~/.ssh/config` Host list: action menu (edit / add / delete / unset), then pick a Host | Pick **7** on the menu · `sshd-cli dns` · `sshd-cli dns list` · `sshd-cli dns delete 1` · `sshd-cli dns unset 1 user` |
| SSH into a named Host | Numbered Host pick, then **user** with default (Host `User`, else this login) | Pick **7** · `sshd-cli ssh` · `sshd-cli ssh 1` |
| Open a shell on a named phone | Pick that Host from the same list. OpenSSH client uses the alias so User / Port / keys apply. | `sshd-cli ssh` · `sshd-cli ssh 1` · `sshd-cli ssh phone` |
| Copy a folder from a named phone | Pick the Host, then **user** with default (Host `User`, else this login), then a remote folder (numbered previous paths for that Host, or type a path). Remote `tar.gz`, extract here. | `sshd-cli download` · `sshd-cli download phone /opt/app` |
| Copy a folder **to** a named phone | Same Host and **user** walk as **download**. Then a **local** folder (numbered previous local paths for that Host, or type a path). Local `tar.gz` over ssh; extract under the remote login home. | `sshd-cli upload` · `sshd-cli upload phone ./box` · `sshd-cli upload phone ~/box/app` |
| Open the menu on POSIX Linux as a non-root login | Server rows **22** / **23** / **24** (start / stop / restart) are omitted. An INFO line names this OS. Client **11** `dns` stays. Front **5** sudoers stays. | `sshd-cli` on a terminal (not root). Re-run as root to see start/stop/restart. |
| Start sshd on Linux when the distro unit exists | As **root**, this CLI calls `systemctl start` on that unit (Debian/Ubuntu often `ssh.service`; others often `sshd.service`). It does not `sshd -f` beside a systemd listener. | `sshd-cli start` as root |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Specialized CLI subcommands

| Verb | Operands | Handler | Privilege | Errors |
|------|----------|---------|-----------|--------|
| `status` | none | `sshd_cmd_status` | This login | Missing sshd → warn, still print paths |
| `start` | none | `sshd_cmd_start` | Termux: this login. Linux: **root login** (no in-tool sudo). systemd unit path: `systemctl start <unit>` | No binary / bad config / not writable / `systemctl` fail → `out_die` |
| `stop` | none | `sshd_cmd_stop` | Same as start. systemd unit path: `systemctl stop <unit>` | Cannot stop (signal or `systemctl`) → `out_die` |
| `restart` | none | `sshd_cmd_restart` | Same as start. systemd unit path: `systemctl restart <unit>` (one call). Else stop then start | Same as stop then start, or `systemctl` fail |
| `port` | optional `N` | `sshd_cmd_port` | Show: this login if config readable. Set: writable config | Non-numeric / out of 1–65535 → `out_die` |
| `config` | none | `sshd_cmd_config` | This login | Unreadable config → warn |
| `host-keys` | `list` (default) or `generate` | `sshd_cmd_host_keys` | generate needs a writable host-key dir | Unknown action → `out_die` |
| `auth-keys` | `list` (default) or `add <pubkey-file>` | `sshd_cmd_auth_keys` | This login’s `~/.ssh` | Missing file / no key line → `out_die` |
| `dns` | `list` (default non-TTY) · `show <n\|name>` · `edit <n\|name>` · `set <n\|name> …` · `add …` · `delete <n\|name>` · `unset <n\|name> field …` · empty (TTY action menu) | `sshd_cmd_dns` | This login’s `~/.ssh/config` | Missing n / empty dns name / bad port / unset of dns or ip → `out_die` |
| `fix-config` | optional `--input-file PATH` · optional `--output-file PATH` (flags follow the verb) | `sshd_cmd_fix_config` | This login’s OpenSSH client config | Missing or unreadable explicit input, empty flag value, unknown operand, unwritable output → `out_die` |
| `ssh` | optional `<n\|name>` | `sshd_cmd_ssh` | This login OpenSSH **client** `ssh` using a concrete Host alias | Missing n / empty list / ssh missing → `out_die` |
| `download` | optional `<n\|name>` then optional `folder` | `sshd_cmd_download` | This login: remote `tar czf` over `ssh`, extract into **cwd** | Missing n / folder / bad folder / ssh or tar missing / ssh fail → `out_die` |
| `upload` | optional `<n\|name>` then optional `folder` | `sshd_cmd_upload` | This login: local `tar czf` piped over `ssh`, extract under the remote login **home** | Missing n / folder / missing local dir / bad folder / ssh or tar missing / ssh fail → `out_die` |
| `menu` / `main` | none | `app_cmd_menu` | TTY only | `--json` / quiet / non-TTY → `out_die` with named-command hint |
| `backup-config` | none | `sshd_cmd_backup_config` | POSIX Linux: this login then `sudo -n {{GLOBAL_BIN}}/sshd-cli backup-config`. Termux / Git Bash / Windows cmd unused | Missing `~/.ssh/config` / sudo refused / this-login-only host → `out_die` |
| `sync-config` | none | `sshd_cmd_sync_config` | This login, no sudo | Store missing / this-login-only host → `out_die` |
| `sync-from-remote` | optional SPEC | `sshd_cmd_sync_from_remote` | This login `scp`; all hosts | Missing/invalid SPEC / scp fail → `out_die` |
| `print-sudoers` | optional path; `--allow-test-local` | `sshd_cmd_print_sudoers` | Type 0 draft | Non-production without allow → `out_die` |
| `print-sudoers-install-script` | optional path | `sshd_cmd_print_sudoers_install_script` | Type 0 script; admin runs with sudo | Same trust gate |
| `generate-sudoer-request` | optional path; `--add` / `--update` | `sshd_cmd_generate_sudoer_request` | Type 0 local JSON | Same trust gate |
| `submit-sudoer-request` | optional file | `sshd_cmd_submit_sudoer_request` | Type 0 compose sudoer-cli | Missing sudoer-cli / inbound → `out_die` |
| `remove-project-sudoers` | optional path | `sshd_cmd_remove_project_sudoers` | Type 0 draft only | `/etc` path → `out_die` |

**Routing:** `app_main` parses these verbs in the same pass as Type 0. Operands after `port` / `host-keys` / `auth-keys` / **`dns`** / **`fix-config`** / **`ssh`** / **`download`** / **`upload`** are domain operands, not unknown flags. **Numbered tree SSOT:** `requirement-shell-cli-default-interaction` (client **11** dns, **12** ssh, **13** download, **14** upload). The dns / ssh / download / upload **Host** pick is a **separate** list (leave with `0` / empty — not `9`). **MUST NOT** number `port` / `config` / `host-keys` / `auth-keys` / `fix-config` as numbered rows.

**MUST:** `backup-config` / `sync-config` ops SSOT is `requirement-shell-config-backup` (depends on `requirement-shell-sudoer`). Sudoers JSON, print/generate/submit, and `util_sudo` SSOT is `requirement-shell-sudoer`. This domain file **points**; it does not re-own copy or grant emit.  
**MUST:** On Termux / Git Bash / Windows cmd, the client layer’s **menu-hidden message** **MUST** print `[INFO] backup-config and sync-config not available for termux` (or `gitbash` / `windows-cmd`) **before** the **client** numbered list. That cause omits backup-config and sync-config. Client **14** is **upload**. Termux class numbers **18** sync-from-remote. POSIX Linux numbers **15** backup-config, **16** sync-config. Front **5** sudoers (POSIX Linux only; children **51–55**) is a different cause on the **front** board: its menu-hidden message **MUST** print `[INFO] sudoers not available for termux` (or `gitbash` / `windows-cmd`) **before** the front numbered items. Front Exit is **9**. Rule: `requirement-shell-cli-default-interaction`.  
**MUST:** Each verb above is also named on `requirement-shell-cli-interface` (dual mention).  
**MUST:** Interactive empty argv (`TTY=1`, not quiet/json) **MUST** call `app_cmd_menu` (same handler as `menu`). Dual mention: `requirement-shell-cli-zero-arguments`.  
**MUST NOT:** Open this menu on **non-interactive** empty argv (`curl \| sh`, quiet, json, no TTY) — that path is CLI self-install (`requirement-shell-cli-self-install`), not payload.

### 2.1.2 OpenSSH client config — unsupported parameters

Words this section uses. Each row is the term and the definition this file means by it.

| Term | Definition |
|------|------------|
| **OpenSSH** | The SSH client and server this product drives. The client reads this login’s `{{HOME}}/.ssh/config`. `ssh`, `download`, and `upload` use that client. The server program is `sshd`. |
| **Unsupported parameter in the config file** | An **active** keyword line that this OpenSSH build rejects. A line whose first non-space character is `#` is a comment; OpenSSH ignores it. Alpine rejects an active `GSSAPI*` keyword (`Unsupported option "gssapiauthentication"`). Termux rejects an active `HostKeyAlgorithms`, `PubkeyAcceptedAlgorithms`, or `PubkeyAcceptedKeyTypes`. Another OS keeps those keywords active. |

**OS class** is `sshd_fix_os_class`. `SSHD_CLI_OS` set to `alpine`, `termux`, or `posix` wins. Otherwise Termux detect (`sshd_is_termux`) is `termux`, `ID` or `ID_LIKE` containing `alpine` in `/etc/os-release` is `alpine`, and every other host is `posix`.

| OS class | Comment these active keywords | Leave active |
|----------|-------------------------------|--------------|
| `alpine` | every keyword whose name starts with `GSSAPI` (`GSSAPIAuthentication`, `GSSAPIDelegateCredentials`, `GSSAPIKeyExchange`, `GSSAPIClientIdentity`, `GSSAPIServerIdentity`, `GSSAPITrustDNS`, `GSSAPIKexAlgorithms`, `GSSAPIRenewalForcesRekey`, `GSSAPIStoreCredentialsOnRekey`, and the same prefix) | `HostKeyAlgorithms`, `PubkeyAcceptedAlgorithms`, `PubkeyAcceptedKeyTypes`, and every other keyword |
| `termux` | `HostKeyAlgorithms`, `PubkeyAcceptedAlgorithms`, `PubkeyAcceptedKeyTypes` | `GSSAPI*` and every other keyword |
| `posix` | none of the rows above | those keywords stay as written |

The comment keeps the indent and the original keyword text, and inserts `# ` before the keyword (`    GSSAPIAuthentication yes` becomes `    # GSSAPIAuthentication yes`; `GSSAPIAuthentication=no` becomes `# GSSAPIAuthentication=no`). `Host` lines, `Match` lines, and every other keyword stay. A comment that already mentions the word stays a comment. Concrete `Host`, `Host *`, and `Match` blocks are all in scope.

**Add, update, and review use this same rule.**

| Moment | What runs |
|--------|-----------|
| **Add** | `dns add` rewrites the file through `sshd_fix_config_render` before the new Host is inserted. A new `old-openssh yes` on the `termux` class writes the two algorithm lines as comments. |
| **Update** | `dns set`, `dns edit`, and `dns unset` use that same render. An unsupported keyword becomes a comment. It is not dropped, and it is not turned back into an active line. |
| **Review** | Typed `fix-config` renders the chosen file. `dns show` still reports `old-openssh: yes` when the algorithm keywords are only comments. |

**`fix-config` flags** (after the verb; a flag before the verb is an unknown command):

| Flags | Read | Write |
|-------|------|-------|
| none | `{{HOME}}/.ssh/config` | that same file |
| `--input-file PATH` | `PATH` | that same file |
| `--output-file PATH` | `{{HOME}}/.ssh/config` | `PATH` (the source stays as the automatic pass left it) |
| both | the input path | the output path (the input file stays) |

Missing explicit input, an empty flag value, or an unknown operand → `out_die`. A missing output directory → `out_die`. A changed in-place file gets `util_backup`, then an atomic replace, mode **600**. JSON is one object `"type":"fix-config"` with string fields `changed` (`true` or `false`) and `os`. Human mode prints one success line. `--quiet` / `--json` print no human line from this verb.

**Every run** calls `sshd_fix_config_auto` on `{{HOME}}/.ssh/config` after the language load and before dispatch, including a zero-cli-verb (the numbered menu and non-interactive self-install). Missing, unreadable, or unwritable is a silent no-op. Identical text is a no-op (no rewrite). A real change writes a rolling `config.fix-config.bak` (mode **600**) and replaces the file (mode **600**) with no `out_*` line, so `version` and `--json version` stay a single message. The automatic pass does not create `{{HOME}}/.ssh/config` when it is absent. A later explicit `fix-config` on that same file is unchanged when the automatic pass already commented it.

**Sample** (the ship unit’s render; `os` is `sshd_fix_os_class`):

```sh
# Comment an active keyword this OS rejects. Keep the indent. Leave other lines.
awk -v os="${os}" '
    function unsupported(k) {
        if (os == "alpine" && k ~ /^gssapi/) return 1
        if (os == "termux" && (k == "hostkeyalgorithms" || k == "pubkeyacceptedalgorithms" || k == "pubkeyacceptedkeytypes")) return 1
        return 0
    }
    {
        line = $0
        indent = ""
        rest = line
        if (match(line, /^[[:space:]]*/)) {
            indent = substr(line, 1, RLENGTH)
            rest = substr(line, RLENGTH + 1)
        }
        if (rest == "" || substr(rest, 1, 1) == "#") { print line; next }
        if (match(rest, /^[A-Za-z][A-Za-z0-9]*/)) {
            k = tolower(substr(rest, RSTART, RLENGTH))
            if (unsupported(k)) { print indent "# " rest; next }
        }
        print line
    }
' "${HOME}/.ssh/config"
```

```sh
sshd-cli fix-config
sshd-cli fix-config --input-file "${HOME}/.ssh/config"
sshd-cli fix-config --output-file "${HOME}/ssh-config.commented"
sshd-cli fix-config --input-file "${HOME}/.ssh/config" --output-file "${HOME}/ssh-config.commented"
```

**MUST NOT** pass `-o GSSAPIAuthentication` or any other `GSSAPI*` option from `ssh`, `download`, or `upload`.

### 2.1.1 Install companion packages (Termux)

`install` **MUST** call domain helper `sshd_pkg_ensure` (via `inst_ensure_companion`) **before** the already-installed binary no-op. Dual mention: `requirement-shell-termux-ish` (detect / invoke contract), `requirement-shell-cli-interface` (`install` / `self-update` rows), and `requirement-shell-self-management` (orchestrator). Interactive empty argv is the menu. Non-interactive empty argv and `self-install` **MUST NOT** run package ensure or auto-start (`requirement-shell-cli-self-install`).

**`self-update` is CLI-only.** After a successful CLI place it **MUST NOT** call `sshd_cmd_start`, **MUST NOT** run `sshd -t` of `/etc/ssh/sshd_config`, **MUST NOT** rewrite that file, and **MUST NOT** create `/run/sshd`. Operator runs `sshd-cli start` when they want the daemon.

After **`install`** / non-interactive empty-argv CLI place (not `self-update`):

| After CLI place | MUST | MUST NOT |
|-----------------|------|----------|
| **Termux `install`** | Start sshd (idempotent if already running). Fail closed if `sshd` is still missing after `pkg`. | Leave sshd stopped after a successful Termux `install` |
| **POSIX Linux `install`** | Best-effort start when this login can. If start cannot run (`sshd -t` fail, missing `/run/sshd`, not root, no unit), **warn** and **still succeed** the CLI install | `out_die` the CLI install; rewrite `/etc/ssh/sshd_config`; mkdir `/run/sshd` as a CLI-install side effect |
| **`self-update`** | Stop after CLI place + checksum | Auto-start sshd; fail because host sshd_config / privilege-separation dir |
| **JSON `install`** | Termux: start the daemon; **MUST NOT** emit a second JSON object from `start`. Linux: same warn-and-succeed if start fails | Mix two JSON objects on stdout; fail JSON install on Linux `sshd -t` |

| Host | MUST | MUST NOT |
|------|------|----------|
| **Termux** | `pkg install -y openssh termux-auth` (non-interactive `-y`; quiet/json suppress pkg stdout) | Hang on `pkg` prompts; skip packages because the CLI binary is already placed |
| **POSIX Linux** | No-op (operator uses the distro package manager) | Wrap `apt` / `dnf` / `yum` inside this CLI |
| **Termux, `pkg` missing** | Fail closed with operator-readable Next | Pretend sshd is ready |
| **Termux, pkg fail** | Fail closed: “Could not install openssh and termux-auth. Next: run: pkg install openssh termux-auth” | Continue as success |

**MUST NOT** run `passwd` automatically (secret; interactive). Human mode **MAY** hint: set a password with `passwd` if the operator will use password SSH.

**Invocation sample (same verb as CLI lifecycle):**

```sh
sshd-cli install
```

**Invocation samples:**

```sh
sshd-cli status
sshd-cli --json status
sshd-cli start
sshd-cli stop
sshd-cli restart
sshd-cli port
sshd-cli port 8022
sshd-cli config
sshd-cli host-keys
sshd-cli host-keys generate
sshd-cli auth-keys
sshd-cli auth-keys add ./laptop.pub
sshd-cli dns
sshd-cli dns list
sshd-cli --json dns list
sshd-cli dns show 1
sshd-cli dns edit 1
sshd-cli dns set 1 ip 192.168.1.10 user "" port 8022
sshd-cli dns add dns phone ip 192.168.1.10
sshd-cli dns delete 1
sshd-cli dns unset 1 user
sshd-cli dns unset phone user
sshd-cli ssh
sshd-cli ssh 1
sshd-cli ssh phone
sshd-cli download
sshd-cli download phone /opt/app
sshd-cli download phone ~/box/app
sshd-cli upload
sshd-cli upload phone ./box
sshd-cli upload phone ~/box/app
sshd-cli menu
```

### 2.2 Specialized features

**Path resolve (SSOT `sshd_resolve`):**

| Field | Termux | POSIX Linux |
|-------|--------|-------------|
| Platform id | `termux` | `posix` |
| sshd binary | `${PREFIX}/bin/sshd` or `command -v sshd` | `command -v sshd` or `/usr/sbin/sshd` |
| Config | `${PREFIX}/etc/ssh/sshd_config` | `/etc/ssh/sshd_config` |
| Host keys | `${PREFIX}/etc/ssh` | `/etc/ssh` |
| Pid file | `${PREFIX}/var/run/sshd.pid` | `/run/sshd.pid` or `/var/run/sshd.pid` |
| Default Port | `8022` if config has no Port | `22` if config has no Port |
| Login keys | `${HOME}/.ssh/authorized_keys` | same |

Termux detect: `PREFIX` contains `com.termux`, or `TERMUX_VERSION` set, or `/data/data/com.termux/files/usr` exists.

#### 2.2.1 POSIX Linux systemd / `systemctl` (launch-path SSOT)

`start` / `stop` / `restart` pick **exactly one** launch path. Helpers (this product): `sshd_is_systemd_host` · `sshd_systemd_unit` · `sshd_systemd_is_active` · `sshd_systemd_main_pid`. Dual mention: `requirement-shell-cli-interface`. **MUST NOT** add a routed verb named `systemctl`.

**systemd host** (`sshd_is_systemd_host` true) when **all** of:

1. **Not** a command line for normal user only (`sshd_is_normal_user_only_cli` is false).  
2. Directory `/run/systemd/system` exists (this machine is running systemd).  
3. `command -v systemctl` succeeds.

If (2) is true and (3) is false: **warn** once per command, then use the OpenSSH fallback. **MUST NOT** call `systemctl`.

**Unit name** (`sshd_systemd_unit`): probe **`ssh.service`** first (Debian/Ubuntu), then **`sshd.service`**. A name **exists** when `systemctl show -p LoadState --value <name>` is not `not-found` (loaded / stub / masked count as exists). If **both** exist: prefer the one `systemctl is-active` reports **active**; else prefer `ssh.service`. Empty string means no unit.

**Socket:** If `systemctl show -p TriggeredBy --value <unit>` names `ssh.socket` or `sshd.socket`, human **status** **MAY** print that socket. `start` still runs `systemctl start <service-unit>`, not `systemctl start <socket>`.

| Host | Unit exists | `start` / `stop` / `restart` MUST | MUST NOT |
|------|-------------|-----------------------------------|----------|
| Termux / Git Bash / Windows cmd | ignored | OpenSSH fallback (`sshd -f` / pidfile `kill`) | Invoke `systemctl` even if the binary exists |
| POSIX Linux, systemd host, unit exists | yes | `systemctl start` / `stop` / `restart <unit>` as **root login**. `restart` is **one** `systemctl restart` (not this CLI’s stop-then-start). | `sshd -f` beside the unit; `kill` the unit MainPID; `--user`; wrap `sudo` |
| POSIX Linux, systemd host, no unit | no | OpenSSH fallback as root | Pretend a unit exists; invent `sshd.service` when LoadState is `not-found` |
| POSIX Linux, not a systemd host | n/a | OpenSSH fallback as root | Call `systemctl` |

**OpenSSH fallback** (unchanged): `"${SSHD_BIN}" -f "${SSHD_CONFIG}"` so OpenSSH daemonizes. **MUST NOT** pass `-D`. **MUST NOT** wrap in `&` / `nohup`. Stop is signal the sshd pid (pidfile, then process match).

**`systemctl` argv (when the unit path applies):**

| Verb | Command | Privilege | Fail closed |
|------|---------|-----------|-------------|
| start | `systemctl start <unit>` | root (`id -u` 0) | non-zero `systemctl`; permission denied → Next: re-run as root |
| stop | `systemctl stop <unit>` | root | same |
| restart | `systemctl restart <unit>` | root | same |
| is-active / MainPID / LoadState / TriggeredBy | `systemctl is-active` · `systemctl show -p … --value` | **this login** (status/about; no root required) | treat unknown as not-active; **MUST NOT** fail `status` solely because show failed |

**Already running (unit path):** `systemctl is-active <unit>` is `active` → success no-op (do not `systemctl start` again). MainPID from `systemctl show -p MainPID` when non-zero.

**Human copy (unit path, not quiet/json):** **MUST** name the unit (`ssh.service` or `sshd.service`). **MUST** say this CLI used `systemctl` for start/stop/restart. **MUST** say listen-after-reboot is this distro unit. **MUST NOT** say the pid is a “background daemon for this session”, “OpenSSH forks itself”, or “not a systemd” service. **MUST NOT** tell the operator to run `${APP_NAME} start` after a reboot as the Linux boot path.

**Human copy (OpenSSH fallback on POSIX Linux):** same honesty as today: this CLI does not manage systemd; listen-after-reboot is the distro unit **if one exists later**; **MUST NOT** deny systemd for an observed pid.

**Non-root POSIX Linux:** menu rows 2/3/4 stay hidden (semantics 1c). Typed `start` / `stop` / `restart` **MUST NOT** invoke `systemctl start/stop/restart` (would need root). Fail closed: re-run as root. **MUST NOT** wrap `sudo`. `status` **MAY** read `systemctl is-active` / `show` as this login.

**MUST NOT** (systemd scope):

- Routed verbs: `systemctl`, `enable-service`, `sv-enable`, `add-crontab`.  
- `systemctl enable` / `disable` / `mask` / `unmask` / `daemon-reload` / `edit` / `cat` as this CLI’s start/stop/restart.  
- Write or install unit files under `/etc/systemd` / `/usr/lib/systemd`.  
- `--user` instance for system sshd.  
- `termux-services` / runit as a substitute.  
- Invoke `systemctl` because Git Bash or Windows cmd was detected.

**Semantics:**

1. **status** is read-only. Missing sshd is a warning, not a crash. Human mode **MUST** end with a recommended connect line `ssh -p <port> <user>@<lan-ipv4>` when a live IPv4 exists. **User** is `id -un`. **IPv4 SSOT:** `ifconfig wlan0` inet (Termux Wi-Fi). Then `wlan1`, then any `ifconfig` inet, then `ip` fallbacks. **MUST NOT** print a placeholder host (`<this-host>`, `<LAN-IPv4>`, `example.com`). If no usable IPv4: warn and say Next (turn on Wi-Fi, then `status`) — do not invent an address. JSON `connect` is that live string, or empty. **MUST NOT** freeze a session login or a sample home IP into product law. On a systemd host with a resolved unit, human **status** **MUST** print the unit name and active/inactive; JSON **MUST** add `sshd_systemd` (true/false), `sshd_unit` (name or `""`), `sshd_unit_active` (true/false).  
1b. **menu numbers** are owned by `requirement-shell-cli-default-interaction` (front **1** client-side, **2** server-side, **5** sudoers, **6** self-management, **7** language, **9** Exit; language block **70–89** (not more than 20 languages; assigned **71** English / **72** Simplified Chinese / **73** Traditional Chinese / **74** Spanish / **75** Arabic / **76** French / **77** Portuguese / **78** Russian / **79** German / **80** Japanese / **81** Korean / **82** Dutch / **83** Greek; **70** and **84–89** reserved and unprinted), copy on `requirement-shell-cli-language`; sudoers **51–55**; client **11** dns, **12** ssh, **13** download, **14** upload; server **21** status, **22–24** start/stop/restart; submenu **0** Back). This file owns the **handlers**. Choosing **11** (or typing `dns`) runs `sshd_cmd_dns`. Choosing **12** (or typing `ssh`) runs `sshd_cmd_ssh` (numbered Host pick, then **user** with default). Choosing **13** (or typing `download`) runs `sshd_cmd_download`. Choosing **14** (or typing `upload`) runs `sshd_cmd_upload` (Host pick, then **user** with default, then a **local** folder). `port` / `config` / `host-keys` / `auth-keys` stay typed. The Host pick **MUST NOT** reuse front Exit **9** (leave Host pick with **0**).  
1c. **menu daemon rows (22/23/24):** On a **command line for normal user only** (Termux, Git Bash, Windows cmd), **MUST** print rows **22** / **23** / **24** for this login. On POSIX Linux (not that class), **MUST** print those rows **only** when this login is **root** (`id -u` is 0). When those rows are hidden, **MUST** print, **before** the server-side numbered choices, the **menu-hidden message** for this one cause: `start/stop/restart sshd features are not available for non-root in <OS-Name>`. **OS-Name** is `/etc/os-release` `NAME=` (quotes stripped), else `uname -s`, else `Linux`. **MUST NOT** hardcode Ubuntu. **MUST NOT** renumber **21** / **11**. Hidden **22** / **23** / **24** **MUST NOT** dispatch. They are an unknown TTY choice on the **server** list: **MUST** warn and **MUST** display that same list again (**MUST NOT** `out_die`). Typed `start` / `stop` / `restart` still run the handlers (fail-closed without root). **MUST NOT** wrap `sudo` to unhide the rows. Helper: `sshd_menu_show_daemon_rows` · `sshd_os_name`. Dual mention: `requirement-shell-cli-default-interaction`.  
1d. **TTY menu retry (every numbered layer):** On the **main menu**, **sudoers** submenu, **dns action** menu, **Host pick**, **unset extra-settings** picker, and **download** / **upload** folder pick: an unknown or out-of-range numbered choice **MUST** print a warn that names the token, **MUST** display **that same list** again, and **MUST NOT** `out_die` or exit non-zero solely for that bad TTY choice. Empty / Exit / `q` / `exit` still leave that layer. A valid **leaf** command runs the handler, then the **front board** redisplays (not the submenu). Dual mention: `requirement-shell-cli-default-interaction` · `requirement-shell-interactive-vs-noninteractive`. Non-interactive operand paths still fail closed (no hang).  
2. **start** is idempotent: already running → success no-op. Missing host keys → generate when the host-key dir is writable (OpenSSH fallback only; systemd unit path does **not** generate host keys — the distro unit owns that). On the OpenSSH fallback, `sshd -t` must pass before launch; launch **MUST** be `"${SSHD_BIN}" -f "${SSHD_CONFIG}"`. **MUST NOT** pass `-D`. **MUST NOT** wrap the launch in `&` / `nohup`. On a systemd host with a loaded unit, launch **MUST** follow §2.2.1 (`systemctl start <unit>` as root) — **MUST NOT** `sshd -f` beside that unit. Human mode (not quiet/json) **MUST** describe **this host** per §2.2.1 (Termux: session daemon + Termux:Boot + `${APP_NAME} start` after reboot; systemd unit path: name the unit and `systemctl`; POSIX Linux fallback: do not deny systemd). On Termux, **start** (including already-running) **MUST** auto-acquire the Android wake lock (`sshd_wake_lock_acquire`). Missing helper: **warn** + Next naming `${APP_NAME} wake-lock`; **MUST NOT** fail start solely for that. Dual mention: `requirement-shell-termux-ish`. **MUST NOT** auto-unlock on `stop`.  
3. **stop** is idempotent: already stopped → success no-op. systemd unit path: `systemctl stop <unit>` as root (**MUST NOT** `kill` MainPID). OpenSSH fallback: signal the sshd pid (pidfile, then process match).  
4. **port set** rewrites the `Port` line (or appends one). Does not auto-restart; human mode tells the operator to `restart` when sshd is up.  
5. **host-keys generate** creates ed25519 if missing; tries rsa 4096 and warns if declined. Never overwrite existing private host keys.  
6. **auth-keys add** appends one `ssh-ed25519` / `ssh-rsa` / ecdsa / sk- line from a **file**. Duplicate line → success no-op. Creates `~/.ssh` mode `700` and `authorized_keys` mode `600` when possible.  
7. **No in-tool sudo.** If a Linux system path is not writable, fail closed and tell the operator to **re-run as root**. **MUST NOT** name Termux (or any other platform class) as a next step on that Linux path. Termux PREFIX-writable copy is only when Termux was detected.  
8. **Launch path, not extra verbs.** Start/stop/restart follow §2.2.1. On Termux, **MUST NOT** treat a host `pgrep -x sshd` as this login’s daemon — pidfile / `${PREFIX}/bin/sshd` only. **MUST NOT** add routed verbs `systemctl` / `enable-service` / `sv-enable` / `add-crontab`. **MUST NOT** write unit files. **MUST NOT** `systemctl enable` / `disable` / `mask`. Termux:Boot stays an **operator-owned** hook, not a CLI verb. Distro unit **start/stop/restart** is in scope via existing verbs; unit **enable-at-boot** is not.  
9. **dns** (this login’s `~/.ssh/config` as an SSH name/IP list):

| Mode | MUST | MUST NOT |
|------|------|----------|
| **List** | Numbered **concrete** `Host` entries (`Host` first pattern has no `*` / `?`). Human row: `N. <dns>  <ip-or-(empty)>`. Missing file → empty list (success), not a crash. Skip `Host *`, `Match`, and `Include` (do not follow). | Treat `Host *` as a dns-ip row; rewrite `/etc/hosts` |
| **Show** | Fields **dns**, **ip** (`HostName`), **user**, **port**, **identity-file**, **identities-only**, **termux** (yes/no), **old-openssh** (yes/no). Human: **user** empty → print `empty`. **port** empty → print `22`. **termux** is **yes** only when the Termux client bundle is present (Port **8022**, Ciphers **aes128-ctr,aes256-ctr**, MACs **hmac-sha2-256**, ServerAliveInterval **15**, ServerAliveCountMax **12**, TCPKeepAlive **yes**, IPQoS **none**). Keep-alives without those Ciphers/MACs is **termux no**. **old-openssh** is **yes** when HostKeyAlgorithms / PubkeyAcceptedAlgorithms are set, including when those lines are comments. JSON: raw `user`/`port` may be `""`; also `user_display` / `port_display` / `identity_file` / `identities_only` / `termux` / `old_openssh`. | Invent a user or port; print a live Unix login as a sample; treat “as Termux” as this CLI’s platform detect (`sshd_is_termux`) |
| **Interactive** (`dns` with no subcommand, TTY or `INTERACTIVE=1`, not quiet/json) | Print the Host names as **context** (no choice numbers). Then an **action menu**: **1 Edit** · **2 Add** · **3 Delete** · **4 Unset** · **9 Exit**. `read` in the **current shell** (not `$()` of `prompt_ask`). Type `edit` / `add` / `delete` / `unset` is the same as 1/2/3/4. **MUST NOT** treat the first number as a Host row (Host pick is the next screen). Unknown action **MUST** warn and redisplay this action menu (**MUST NOT** `out_die`). | Hang under `--json` / `--quiet` / no TTY (those paths **list** only); `$()` a `read` helper; jump straight to field-walk update; exit non-zero solely for a bad TTY action |
| **Edit path** | After **1 / edit**: numbered Host pick; leave with `0` / `q` / `exit` / empty — **not** `9` (row 9 is a Host when the list is long). Unknown / missing Host **MUST** warn and redisplay the Host list (**MUST NOT** `out_die`). Then **field-by-field** edit (dns, ip, user, **as Termux (Y/n)**, **port if Termux is no**, **identity-file**, **identities-only**, **Old OpenSSH (Y/n)**) with **current values as defaults**. Enter keeps current. Token `""` **or** an empty operand **means empty**. as Termux default is **yes** when the bundle is already on the stanza, else **no**. Old OpenSSH default is **yes** when algorithm lines are present. | Treat `9` as Exit on the Host pick; skip the action menu; prompt Port while as Termux is yes; `out_die` on a bad TTY Host number |
| **Add path** | After **2 / add**: same field walk as `dns add` with no operands. TTY **as Termux** defaults **yes**; TTY **Old OpenSSH** defaults **yes**; **port** is skipped when as Termux is yes. | Require picking a Host first; apply those bundles on non-interactive add without operands |
| **Delete path** | After **3 / delete**: numbered Host pick (`0` to leave). TTY: show details, then `prompt_yes_no` (y/N). No → success no-op (`Delete cancelled.`). Yes / `--force` / non-interactive `dns delete N` → drop that **whole** concrete Host stanza (extra aliases included). | Delete `Host *` / `Match`; skip backup; two JSON objects |
| **edit N** | Same field walk as after the Edit pick. Non-interactive / quiet / json: **fail closed** with Next: `dns set …` | Hang waiting for fields in CI |
| **delete N** / **rm N** | Non-interactive: no prompt; fail closed if n/name missing. JSON: one `out_success` object (`n`, `dns`). `rm` is an unlisted alias of `delete`. | Prompt; follow `Include`; remove other stanzas |
| **unset N field …** / **clear** | Drop **extra** settings on that Host. Allowed fields: **user**, **port**, **identity-file**, **identities-only**, **termux**, **old-openssh** (and `--` forms). **MUST NOT** clear **dns** (Host name) or **ip** (HostName) — those stay; use **delete** to drop the whole stanza. **unset termux** strips the Termux client keep-alive / IPQoS / Ciphers / MACs lines (Port stays unless `port` is also unset). **unset old-openssh** omits the two algorithm lines. Non-interactive: needs n/name **and** at least one field; no prompt. JSON: one `out_success` object (`n`, `dns`, `cleared`). TTY / `INTERACTIVE=1` with no field: numbered picker of currently set extra fields (`0` to leave). Unknown / out-of-range picker number **MUST** warn and redisplay that picker (**MUST NOT** `out_die`). `clear` is an unlisted alias of `unset`. Empty user after unset → omit `User`. Empty port → omit `Port`. Host line and HostName stay. | Unset dns or ip; delete the stanza; hang under `--json` / quiet / no TTY; two JSON objects; `out_die` on a bad TTY extra-settings number |
| **set N** / **add** non-interactive | Operands `dns`/`ip`/`user`/`port`/`identity-file`/`identities-only`/`termux`/`old-openssh`, or the `--` forms. Omitted fields on **set** stay unchanged. **add** requires a dns name. `""` or empty value clears that field. Port empty or `22` → omit `Port` line (OpenSSH default 22). Empty user → omit `User`. Empty ip → omit `HostName`. Empty identity-file → omit `IdentityFile`. Empty identities-only → omit `IdentitiesOnly`. Empty dns name after normalize → `out_die`. Port if set must be 1–65535. **termux yes** (add or set) writes the Termux client bundle (Port **8022**, Ciphers **aes128-ctr,aes256-ctr**, MACs **hmac-sha2-256**, ServerAliveInterval **15**, ServerAliveCountMax **12**, TCPKeepAlive **yes**, IPQoS **none**) and **overrides** port. Simpler Ciphers/MACs exist because some Termux OpenSSH `sshd` versions reply too slowly and the client then aborts with **Connection corrupted** / **Bad packet length**. **termux no** on **set** strips those keep-alive / IPQoS / Ciphers / MACs lines (Port stays unless `port` is also set). **old-openssh yes** writes `HostKeyAlgorithms +ssh-rsa,ssh-dss` and `PubkeyAcceptedAlgorithms +ssh-rsa,ssh-dss`. On the `termux` OS class (`sshd_fix_os_class`) those two lines **MUST** be comments (`# HostKeyAlgorithms …`, `# PubkeyAcceptedAlgorithms …`): an active keyword makes the Termux OpenSSH client error. **old-openssh** stays **yes** when the lines are only comments. **old-openssh no** on **set** omits those two lines, comments included. Non-interactive **add** without `termux yes` / `old-openssh yes` **MUST NOT** write those bundles. Unowned extra keys stay. An active keyword this OS class rejects is commented in place (Alpine: every `GSSAPI*` keyword; Termux: `HostKeyAlgorithms`, `PubkeyAcceptedAlgorithms`, `PubkeyAcceptedKeyTypes`; other OS: those keywords stay active). | Prompt; follow `Include`; apply Termux/Old OpenSSH bundles on add without the operand; drop unowned extra keys; delete an unsupported keyword instead of commenting it; comment `GSSAPI*` on an OS that accepts GSSAPI; comment the algorithm keywords on an OS that accepts them |
| **Write** | Backup via `util_backup` then **atomic replace** (mktemp + `mv`) for **set, add, delete, and unset**. Create `~/.ssh` mode `700` and `config` mode `600` when missing. Keep unrelated stanzas, extra keys, and extra Host aliases after the first pattern (delete drops only the chosen stanza; unset keeps the Host line and HostName). Read `Key value`, `Key=value`, and `Key = value`. **add** inserts the new Host **before** the first wildcard `Host` / `Match` (OpenSSH first-match). Duplicate dns name on rename/add → `out_die`. On **set, add, delete, and unset**, comment every active keyword this OS class rejects, in the whole file (concrete Host, `Host *`, and `Match`). Alpine comments every `GSSAPI*` keyword (`GSSAPIAuthentication` prints `Unsupported option "gssapiauthentication"` when the line is active). Termux comments `HostKeyAlgorithms`, `PubkeyAcceptedAlgorithms`, and `PubkeyAcceptedKeyTypes`. Another OS leaves those keywords active. A comment that only mentions the word stays. | Overwrite the whole file from a stub; print private keys; `>>` after trailing `Host *`; drop extra aliases on an IP-only set; drop the Host stanza on unset; delete an unsupported keyword instead of commenting it; comment `GSSAPI*` on an OS that accepts GSSAPI |

**Guided-input field table (Choice C — TTY walk and operands):**

| Field | Secret? | Prompt label | Default | Skip-if |
|-------|---------|--------------|---------|---------|
| dns | no | dns (SSH Host name you type) | current Host | never; empty after `""` is fail-closed |
| ip | no | ip (HostName to connect to) | current HostName | never |
| user | no | user | current User (display `empty` when unset) | never |
| as Termux | no | as Termux (Y/n) | **add:** yes. **edit:** yes if the Termux client bundle is on the stanza, else no | never on TTY walk |
| port | no | port | current Port (display `22` when unset) | **as Termux is yes** (Port is 8022 from the bundle) |
| identity-file | no | identity-file | current IdentityFile (display `empty` when unset) | never |
| identities-only | no | identities-only | current IdentitiesOnly; **add:** `yes` if identity-file is set, else empty | never |
| Old OpenSSH | no | Old OpenSSH (Y/n) | **add:** yes. **edit:** yes if algorithm lines are present | never on TTY walk |

Intention: the operator is not forced to assemble a long flag list from memory. Dual mention: `requirement-shell-interactive-vs-noninteractive` · `requirement-shell-cli-interface`.

10. **ssh** (OpenSSH **client** using this login’s Host list):

| Mode | MUST | MUST NOT |
|------|------|----------|
| **TTY** / `INTERACTIVE=1` (not quiet/json), no operand | Same numbered concrete Host list as `dns`. Pick `n` (leave with `0` / empty — **not** `9`). Unknown Host **MUST** warn and redisplay that list (**MUST NOT** `out_die`). Then prompt **user [default]**: default is Host `User` if set, else this login (`id -un`). Enter keeps default. Token `""` means empty (no `-l`). Then run OpenSSH `ssh` with that **Host alias** (Port / IdentityFile from the stanza apply) and `-l` when user is non-empty. TTY without a test override: `exec ssh [-l user] <alias>`. | Pass HostName/IP instead of the alias; follow `Include`; hang under `--json` / quiet / no TTY; `$()` a `read` helper; `out_die` on a bad TTY Host number |
| **Operand** `<n\|name>` | Resolve like `dns show`. Missing → `out_die` with Next: `dns list` then `ssh <n\|name>` | Invent a Host |
| **`--json`** | One object (`n`, `dns`, `command`). **MUST NOT** start a session | Mix a live `ssh` session with JSON |
| **Binary** | `command -v ssh`, or `SSHD_CLI_SSH` override (tests inject a fake; **MUST NOT** `exec` when that override is set) | Wrap `sudo`; call `scp` for this verb |
| **Commented algorithms** | Before `ssh` runs, read that Host stanza. If `HostKeyAlgorithms` or `PubkeyAcceptedAlgorithms` (or `PubkeyAcceptedKeyTypes`) is a **comment**, **MUST** pass `-o HostKeyAlgorithms=+ssh-rsa` on the TTY `exec`, the non-TTY batch run, and the `SSHD_CLI_SSH` override, and include it in the JSON `command` string. Menu **12** uses this same verb. | Add that `-o` when the keyword is an active config line; pass `-o GSSAPIAuthentication` or any other `GSSAPI*` option (`download` and `upload` included) |

11. **download** (remote folder → cwd):

| Mode | MUST | MUST NOT |
|------|------|----------|
| **Host pick** | Same concrete Host list as `dns` / `ssh`. TTY with no first operand: pick Host. Non-interactive: require `<n\|name>` | Follow `Include`; list `Host *` |
| **User (TTY)** | After the Host is known, prompt **user [default]** with the same contract as **ssh** (Host `User` if set, else this login; Enter keeps default; `""` means empty / no `-l`). Then `-l` when user is non-empty. | Skip the user prompt on TTY; hang under `--json` / quiet / no TTY; `$()` a `read` helper |
| **Folder pick (TTY)** | After user. If this Host has **no** stored folders: prompt for a remote path (absolute, relative, or **`~/folder`**). If it has stored folders: numbered list (1…), **or** type a non-number path. In-range number → that stored path. Out-of-range number **MUST** warn and redisplay that list (**MUST NOT** treat it as a path; **MUST NOT** `out_die`). Empty → fail closed. | Hang under `--json` / quiet / no TTY; treat an out-of-range number as a path; refuse `~/folder` as if it were `~`; `out_die` on a bad TTY folder number |
| **Folder (non-interactive)** | Second operand is the path. Missing → `out_die` with Next. No user prompt; OpenSSH uses the Host stanza `User` when `-l` is omitted. **`~/folder`** is allowed | Prompt |
| **Transfer** | Remote `test -d` then `tar czf - -C <parent> <basename>` over `ssh -o BatchMode=yes` (and `-l` when TTY user is non-empty). Extract with local `tar xzf` into **this login’s current directory**. Quote the remote path for `sh`. A **`~/folder`** prefix **MUST** become `"$HOME"/'folder'` for the ssh user (do **not** single-quote the whole `~/…` string; do **not** expand `~` against this login). After success, remember the path for that Host | `sudo`; leave a tarball as the only result; extract into `{{HOME}}` instead of cwd; pass HostName instead of the alias |
| **Memory** | File `{{HOME}}/.local/{{APP_NAME}}/download-folders` (mode **600**): `dns<TAB>path`, most recent first, unique pair, cap **20** paths per Host. Same persistent dir as preferred-remote (not `/dev/shm`) | Volatile cache; freeze a session login path as a sample in law |
| **`--json`** | One object (`n`, `dns`, `user`, `folder`, `destination`). Still performs the transfer when operands are complete. `user` is Host `User` (may be `""`) | Two JSON objects; start an interactive `ssh` session |
| **Refuse** | Empty; `.` ; `..` ; `/` ; leading `-` ; **`~` alone**; **`~user`** / **`~user/…`**; shell metacharacters `; \| & $ \` ( ) < > * ? ! # ~` after any allowed `~/` prefix | Remote `rm`; follow `Include`; treat `~/folder` as forbidden `~` |

12. **upload** (local folder → remote login home):

The inverse of **download**. Same Host pick and TTY **user [default]** contract. The folder is **local** (this login). Compression is **`tar.gz`** (same family as download). Dest on the remote is the ssh user’s home, not this login’s `HOME`.

**Guided-input field table (Choice C — TTY walk and operands):**

| Field | Secret? | Prompt label | Default | Skip-if |
|-------|---------|--------------|---------|---------|
| Host | no | numbered Host pick (same list as `dns`) | none | first operand present |
| user | no | user [default] | Host `User` if set, else this login (`id -un`) | non-interactive / `--json` / quiet / no TTY |
| folder | no | local folder (absolute, relative, or `~/folder` on this login) | numbered previous local paths for that Host | never; empty is fail-closed |

Intention: the operator is not forced to assemble Host + user + path from memory. Dual mention: `requirement-shell-interactive-vs-noninteractive` · `requirement-shell-cli-interface`.

| Mode | MUST | MUST NOT |
|------|------|----------|
| **Host pick** | Same concrete Host list as `dns` / `ssh` / `download`. TTY with no first operand: pick Host. Non-interactive: require `<n\|name>` | Follow `Include`; list `Host *` |
| **User (TTY)** | After the Host is known, prompt **user [default]** with the same contract as **ssh** / **download**. Then `-l` when user is non-empty. | Skip the user prompt on TTY; hang under `--json` / quiet / no TTY; `$()` a `read` helper |
| **Folder pick (TTY)** | After user. The path is **local**. If this Host has **no** stored upload folders: prompt for a local path (absolute, relative, or **`~/folder`**). If it has stored folders: numbered list (1…), **or** type a non-number path. In-range number → that stored path. Out-of-range number **MUST** warn and redisplay that list (**MUST NOT** treat it as a path; **MUST NOT** `out_die`). Empty → fail closed. | Hang under `--json` / quiet / no TTY; treat an out-of-range number as a path; refuse `~/folder` as if it were `~`; treat the path as remote; `out_die` on a bad TTY folder number |
| **Folder (non-interactive)** | Second operand is the **local** path. Missing → `out_die` with Next. No user prompt; OpenSSH uses the Host stanza `User` when `-l` is omitted. **`~/folder`** is allowed (this login) | Prompt |
| **Local path** | **MUST** exist as a directory on this login before the transfer. Relative paths are relative to **this login’s current directory**. A **`~/folder`** prefix **MUST** expand against **this login’s** `HOME` for the local `tar` only. **MUST NOT** send that expanded this-login absolute path as the remote dest. **MUST NOT** rewrite local `~/` into remote `"$HOME"` (that rewrite is **download** only) | Upload a file that is not a directory; follow `..` out of the named folder as a dest rewrite |
| **Transfer** | Local `test -d` then `tar czf - -C <parent> <basename>` **piped** to `ssh -o BatchMode=yes` (and `-l` when TTY user is non-empty) running remote `tar xzf - -C "$HOME"`. Quote the remote dest as `"$HOME"` so it expands for the **ssh user**. After success, remember the **typed** path for that Host | `sudo`; `rsync`; leave a tarball as the only result; extract into this login `{{HOME}}`; pass HostName instead of the alias; `scp` a leftover archive as the product result |
| **Memory** | File `{{HOME}}/.local/{{APP_NAME}}/upload-folders` (mode **600**): `dns<TAB>path`, most recent first, unique pair, cap **20** paths per Host. Same persistent dir as download-folders / preferred-remote (not `/dev/shm`) | Share the download-folders file; volatile cache; freeze a session login path as a sample in law |
| **`--json`** | One object (`n`, `dns`, `user`, `folder`, `destination`). Still performs the transfer when operands are complete. `folder` is the typed local path. `destination` names the remote extract (`"$HOME"` / the basename under the ssh user home). `user` is Host `User` (may be `""`) | Two JSON objects; start an interactive `ssh` session |
| **Refuse** | Empty; `.` ; `..` ; `/` ; leading `-` ; **`~` alone**; **`~user`** / **`~user/…`**; shell metacharacters `; \| & $ \` ( ) < > * ? ! # ~` after any allowed `~/` prefix; path that is not a local directory | Remote `rm`; follow `Include`; treat local `~/folder` as forbidden `~` |

**Non-goals:** SSH client `ProxyJump` recipes, ControlMaster session mux, Dropbear-only hosts, changing Linux firewall, wrapping `apt`/`dnf` on POSIX Linux, password-auth policy as a verb (shown on `config` only), auto-running `passwd`, **writing** systemd unit files, `systemctl enable` / `disable` / `mask` as CLI verbs, a routed `systemctl` command, `termux-services` / runit supervision, cron-as-service, a Termux:Boot installer, `/etc/hosts` editing, folder-archive `backup`/`restore`, copying private keys, `rsync`. Termux `pkg install openssh termux-auth` **is** in scope as the install companion (§2.1.1). This login `~/.ssh/config` Host list **is** in scope as **dns**. OpenSSH client `ssh <Host-alias>` **is** in scope as **ssh**. Remote-folder `tar.gz` into cwd **is** in scope as **download**. Local-folder `tar.gz` onto a named Host (extract under that ssh user’s home) **is** in scope as **upload**. POSIX Linux deposit of `~/.ssh/config` **is** in scope as **backup-config** / **sync-config**. POSIX Linux `systemctl start` / `stop` / `restart` of the distro ssh/sshd **unit** **is** in scope (§2.2.1).

**Filename grammar (when this domain allocates files):** host keys use OpenSSH names, not a dated JSON grant.

```text
{{HOSTKEY_DIR}}/ssh_host_ed25519_key
{{HOSTKEY_DIR}}/ssh_host_ed25519_key.pub
```

Example on Termux: `$PREFIX/etc/ssh/ssh_host_ed25519_key`

**ssh_config Host sample (dns-ip; this login `~/.ssh/config`):**

```text
Host phone
    HostName 192.168.1.10
    User termux
    Port 8022
    IdentityFile ~/.ssh/phone
    IdentitiesOnly yes
    Ciphers aes128-ctr,aes256-ctr
    MACs hmac-sha2-256
    ServerAliveInterval 15
    ServerAliveCountMax 12
    TCPKeepAlive yes
    IPQoS none
    HostKeyAlgorithms +ssh-rsa,ssh-dss
    PubkeyAcceptedAlgorithms +ssh-rsa,ssh-dss
```

**authorized_keys sample line:**

```text
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExamplePublicKeyMaterialOnly laptop-user
```

### 2.3 Specialized project help items

`help` **MUST** keep Type 0 rows, then a **Domain commands (OpenSSH sshd):** section:

- `status` — Show whether sshd is running, and the port/paths (Linux systemd: unit name + active)  
- `start` — Start sshd: Termux / no-unit Linux = background daemon (`sshd -f`); Linux with a distro unit = `systemctl start` as root (Termux also acquires Android wake lock)  
- `stop` / `restart` — same launch-path split (`systemctl stop` / `systemctl restart` when a unit exists)  
- `port [N]`  
- `config`  
- `host-keys [list|generate]`  
- `auth-keys [list|add <file>]`  
- `dns [list|show N|edit N|set N …|add …|delete N|unset N field …]` — This login `~/.ssh/config` Host list (numbered dns-ip; TTY as Termux / identity-file / Old OpenSSH; TTY edit/add/delete/unset; unset drops extra settings, not dns or ip)  
- `fix-config [--input-file PATH] [--output-file PATH]` — Comment OpenSSH client keywords this OS does not support in the client config  
- `ssh [N|name]` — OpenSSH client to a Host from this login `~/.ssh/config` (TTY: numbered pick, then user with default). A commented `HostKeyAlgorithms` / `PubkeyAcceptedAlgorithms` on that Host adds `-o HostKeyAlgorithms=+ssh-rsa` |  
- `download [N|name] [folder]` — tar.gz a remote folder over ssh and extract it here (TTY: pick Host, then user with default, then numbered previous folders or type a path)  
- `upload [N|name] [folder]` — tar.gz a **local** folder over ssh and extract it under the remote login home (TTY: pick Host, then user with default, then numbered previous **local** folders or type a path; `~/folder` is this login)  
- `backup-config` — Copy this login `~/.ssh/config` to `/var/sshd-cli/config`  
- `sync-config` — Copy `/var/sshd-cli/config` into this login `~/.ssh/config` (mode 600)  
- `sync-from-remote [SPEC]` — `scp` a remote `/var/sshd-cli/config`; remembers last user@host  
- `print-sudoers` / `generate-sudoer-request` / `submit-sudoer-request` — passwordless `sudo sshd-cli backup-config` grant  
- `menu` — Numbered tree (SSOT `requirement-shell-cli-default-interaction`): front **1** client-side, **2** server-side, **5** sudoers, **6** self-management, **7** language, **9** Exit. Language block **70–89** (not more than 20 languages): **71** English, **72** Simplified Chinese, **73** Traditional Chinese, **74** Spanish, **75** Arabic, **76** French, **77** Portuguese, **78** Russian, **79** German, **80** Japanese, **81** Korean, **82** Dutch, **83** Greek (`requirement-shell-cli-language`). **70** and **84–89** are reserved and are not printed. Front **8** is not a row. Sudoers **51** generate-sudoer-request, **52** submit-sudoer-request, **53** print-sudoers, **54** print-sudoers-install-script, **55** remove-project-sudoers. Client **11** dns, **12** ssh, **13** download, **14** upload; POSIX Linux also **15–16** backup-config/sync-config; Termux class **18** sync-from-remote. Server **21** status, **22–24** start/stop/restart (hidden for non-root POSIX Linux). Submenus **0** Back.

`help` Type 0 `install` row **MUST** mention Termux `pkg install openssh termux-auth` and `~/.bashrc` / `~/.profile` ensure (dual mention: `requirement-shell-cli-interface` · `requirement-shell-path-and-shell-support` · `requirement-shell-termux-ish`).

**MUST NOT** list install / self-update / version / about inside `menu`.  
Help **MUST** list `rc-test` under a heading **apart** from operational verbs (`requirement-shell-path-and-shell-support` · `requirement-shell-cli-interface`).

Interactive empty argv **MUST** show this same list (zero-arguments dual mention).

### 2.4 Specialized project about items

Human `about` **MUST** add after storage lines: sshd platform, binary, port, running yes/no; on a systemd host, unit name (or none) and active yes/no.  
JSON `about` **MUST** add fields: `sshd_platform`, `sshd_bin`, `sshd_port`, `sshd_running`, `sshd_systemd`, `sshd_unit`, `sshd_unit_active`.  
**MUST NOT** put `CHECKSUM` on about.

### 2.5 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Product | `sshd-cli` 1.21.0 |
| Bootstrap origin | `selfmanaged` 1.2.3 (architecture + Type 0 only; A untouched) |
| Domain prefix | `sshd_*` |
| Channel | `https://raw.githubusercontent.com/cloudgen/sshd-cli/main/sshd-cli` |
| Install companion | `sshd_pkg_ensure` then `sshd_start_after_install` on **`install`** / empty-argv. **`self-update`** sets `SKIP_DOMAIN_START=1` (no auto-start, no `sshd -t`) |
| Login rc companion | Owned by `path_*` / `inst_ensure_companion` (`requirement-shell-self-management`) |
| In-tool sudo | **none** — no `requirement-shell-sudo-command` |
| Dest / fence | **none** (class residual: considered — no dest fence conditions) |
| Menu | Verb `menu`/`main`; also interactive empty argv. Tree: front **1/2/5/6/7/9** (**5** sudoers, children **51–55**); client **11** dns, **12** ssh, **13** download, **14** upload; POSIX Linux **15–16** backup/sync; Termux class **18** sync-from-remote; server **21** status, **22–24** daemon (hidden non-root POSIX Linux). TTY `ssh` / `download` / `upload`: Host pick then user with default (download: remote folder; upload: local folder). Unknown TTY numbered choice on **every** layer warns and redisplays that list (does not die). |
| Status connect hint | `ifconfig wlan0` via `sshd_ifconfig_ipv4` / `sshd_lan_ipv4`; live `Connect:` line; **no** placeholder host |
| Start launch | §2.2.1 — systemd host + loaded `ssh.service` / `sshd.service` → `systemctl start/stop/restart` as root; else OpenSSH `sshd -f`. **No** `-D` on fallback. **No** routed `systemctl` verb. **No** `enable`/`disable`. Termux:Boot operator-owned. Termux: auto-acquire Android wake lock. Helpers: `sshd_is_systemd_host` · `sshd_systemd_unit` · `sshd_systemd_is_active` · `sshd_systemd_main_pid`. |
| dns file | `${HOME}/.ssh/config` (OpenSSH client config; this login) |
| dns fields | dns=`Host` · ip=`HostName` · user=`User` · port=`Port` (display 22 if empty) · identity-file=`IdentityFile` · identities-only=`IdentitiesOnly` · as Termux bundle (Port 8022 + keep-alives + IPQoS none) · Old OpenSSH (`HostKeyAlgorithms` / `PubkeyAcceptedAlgorithms` +ssh-rsa,ssh-dss). Alpine comments an active `GSSAPI*` keyword. Termux comments an active algorithm keyword. Another OS leaves both families active |
| dns empty token | `""` or empty operand → empty field |
| ssh / download / upload Host | Concrete `Host` alias from this login `~/.ssh/config` (same list as `dns`) |
| download memory | `{{HOME}}/.local/sshd-cli/download-folders` mode 600 |
| upload memory | `{{HOME}}/.local/sshd-cli/upload-folders` mode 600 |

#### Worked samples (this project)

**Launch-path sketch** (`sshd_cmd_start` — not the full body):

```sh
_unit=$(sshd_systemd_unit || true)
if [ -n "${_unit}" ]; then
    [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ] || \
        out_die "Starting system sshd needs a root login on this host. Re-run as root."
    systemctl start "${_unit}" || out_die "systemctl start ${_unit} failed. Re-run as root."
    sshd_wake_lock_acquire
    return 0
fi
# OpenSSH fallback: sshd -f (MUST NOT -D; MUST NOT & / nohup)
"${SSHD_BIN}" -f "${SSHD_CONFIG}" || out_die "sshd did not start."
sshd_wake_lock_acquire
```

**Menu choice.** The live boards are the functions quoted in `requirement-shell-cli-default-interaction` §2.11: `app_cmd_menu`, `app_cmd_menu_client`, `app_cmd_menu_server`, `app_cmd_menu_self`, and the hide helpers `sshd_os_name`, `sshd_menu_show_daemon_rows`, `sshd_host_normal_user_only_label`. Language **7** / block **70–89** (assigned **71–83**) and the menu-copy helpers are quoted in `requirement-shell-cli-language` (`app_cmd_menu_language`, `app_menu_text`). Worked samples of each language’s front board and the opening of `help` and `about` are that file’s §2.4.1. The translation tables are §2.4.2. Each board reads with `read -r` in the current shell. An unknown choice warns and reprints that layer.

**systemd unit pick:** probe `ssh.service` then `sshd.service`; both exist → prefer the active one, else `ssh.service`. `sshd_is_systemd_host` is false on Termux / Git Bash / Windows cmd.

### 2.6 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Termux vs Linux paths are named, not guessed per call.  
- **CIAO Principle 9 – Type 0/1/2** (https://github.com/cloudgen/ciao): Domain start/stop stay invoker Type 0; Linux root is a **login**, not a hidden sudo wrap.  
- **CIAO Principle 10 – Least privilege** (https://github.com/cloudgen/ciao): No dedicated system user. Sudoers grant is `sshd-cli backup-config` only (`requirement-shell-sudoer`).  
- **CIAO Principle 5 – SSOT of output** (https://github.com/cloudgen/ciao): Domain messages use `out_*`.  
- **CIAO Principle 16 – Interactive vs non-interactive** (https://github.com/cloudgen/ciao): `dns` TTY field walk; `--json` / pipe **list** or **set** without hanging.  
- **CIAO Principle 21 – Dual policies** (https://github.com/cloudgen/ciao): Portable core; filled notes.  
- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Killing a systemd MainPID fights the supervisor; `systemctl stop` is the unit path.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Fail closed on missing sshd, bad port, unreadable pubkey file.  
- **Intentional**: One domain SSOT; dual mention on the CLI-interface file.  
- **Anti-fragile**: Works when systemd is absent (Termux / OpenSSH fallback). When a distro unit exists, start/stop go through `systemctl` so systemd is not fighting a `kill`.  
- **Over-protect**: Never overwrite host private keys; never `$()` a `read` helper for `menu`.

## Under command line for normal user only

When the ship unit detects a **command line for normal user only** (Termux, Git Bash, Windows cmd, or the same class):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** (Type 0) only | Implement or enable **admin privilege** (Type 1) or **dedicated system user privilege** (Type 2) |
| Document Type 1 **unused** and Type 2 **unused** | In-tool `sudo`; wrap `apt` / `dnf` / `yum`; create a dedicated system user |
| Termux: named `pkg` as this login remains Type 0 | Recommend `sudo curl \| sh` as the install path |
| Git Bash / Windows cmd: same privilege ceiling | Invoke Termux `pkg` because Git Bash or Windows cmd was detected |

Helpers (this product): `sshd_is_termux`, `sshd_is_git_bash`, `sshd_is_windows_cmd`, `sshd_is_normal_user_only_cli`. Dual mention: `requirement-shell-cli-interface` · `requirement-shell-termux-ish`.

**This requirement:** On this class, `start` / `stop` / `restart` stay OpenSSH `sshd -f` (this login). **MUST NOT** invoke `systemctl`. **dns** reads and writes **this login’s** `~/.ssh/config` (Type 0). Linux **root login** plus `systemctl` for a distro unit is **not** this class. **MUST NOT** invent a dedicated `sshd-adm` account. **MUST NOT** add a routed `systemctl` / `enable-service` / `termux-services` verb on that class.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Drop Type 0 routes while adding domain verbs.  
2. Open the menu on **non-interactive** empty argv (`curl \| sh` / quiet / json). Interactive empty argv **MUST** open the menu.  
3. Wrap `sudo` without a studied sudo-command requirement.  
4. Overwrite existing host private keys on `generate`.  
5. Put domain law only on the bootstrap origin.  
6. Lead help/about with Type 0/Type 1 jargon as the only words.  
7. Echo secret key **private** material (public key lines on `auth-keys list` are intended).  
8. Skip Termux `pkg install -y openssh termux-auth` on `install` / empty-argv ensure, or wrap `apt` on Linux in its place.  
8b. List wrapping Termux `pkg` as a domain **non-goal**, or empty a stated Termux sshd purpose with a portable “do not wrap package managers” habit.  
9. Auto-run `passwd` or print a password.  
10. Number `port` / `config` / `host-keys` / `auth-keys` as main-menu rows. Omit numbered **`ssh` (12)** / **`download` (13)** / **`upload` (14)** from the client board (typed names remain valid but are not the discoverable TTY path).  
11. Freeze a session Unix login or a literal LAN IP into product law as the connect example.  
12. Print `<this-host>` or any other placeholder as the ssh host on `status` / `start`.  
13. Finish Termux `install` without starting sshd, or fail POSIX CLI **install** / **self-update** because system sshd needs root, `sshd -t` of `/etc/ssh/sshd_config` failed, or `/run/sshd` is missing.  
13b. Auto-start sshd from **`self-update`**, rewrite `/etc/ssh/sshd_config` on CLI update, or treat host sshd config test as CLI-update success.  
14. Strip the **Under command line for normal user only** section, or wrap `sudo` / create `sshd-adm` on that class.  
15. Pass `-D` on the OpenSSH fallback, wrap start in `&` / `nohup`, add routed verbs `systemctl` / `enable-service` / `sv-enable` / `add-crontab` / `termux-services`, or `systemctl enable` / `disable` / `mask` as this CLI’s start/stop/restart.  
16. Treat Termux:Boot as a verb this CLI owns. Distro unit **enable-at-boot** is out of scope; unit **start/stop/restart** is in scope via existing verbs (§2.2.1).  
16c. On a systemd Linux host with a loaded `ssh.service` / `sshd.service`, `sshd -f` beside that unit, or `kill` the unit MainPID instead of `systemctl stop`.  
16d. Invoke `systemctl` on Termux, Git Bash, or Windows cmd.  
16b. Skip Termux Android wake lock auto-acquire on `start`, auto-unlock on `stop`, or treat Termux:Boot / `termux-services` as that lock.  
17. Hang `dns` / `dns edit` / `dns delete` / `dns unset` under `--json` / quiet / no TTY, or `$()` a `read` helper for the action menu, Host pick, field walk, or unset picker.  
18. Follow `Include`, list `Host *`, or rewrite `/etc/hosts` as dns.  
19. Omit `dns` from the numbered client menu (row **11** is the discoverable TTY path; typed `dns` remains valid).  
20. Treat `9` as Exit on the dns Host pick when row 9 is a Host.  
21. Append a new Host after a trailing `Host *` / `Match`.  
22. Drop extra Host aliases, or fail to parse `Key=value` / `Key = value`, on set/edit.  
23. Jump from the TTY Host list straight to field-walk **update** — TTY `dns` **MUST** offer Edit / Add / Delete / Unset first.  
24. Delete `Host *` / `Match`, or skip backup / atomic replace on delete.  
25. Emit two JSON objects on `dns delete` (details + success).  
26. Apply the Termux client bundle or Old OpenSSH algorithm lines on **non-interactive** `add`/`set` unless the operator passed `termux yes` / `old-openssh yes`.  
27. Prompt **port** on the TTY walk when **as Termux** is yes, or skip **identity-file** / **identities-only** / **Old OpenSSH** on that walk.  
28. Treat **as Termux** (per-Host SSH *client* profile for a phone that listens on 8022) as `sshd_is_termux` (this CLI’s runtime platform). They are different questions.  
29. Show numbered start/stop/restart (rows **22** / **23** / **24**) to a **non-root** POSIX Linux login, skip the non-root INFO when those rows are hidden, wrap `sudo` to unhide them, or renumber `dns` off client **11** when hiding 22–24.  
30. Print “use Termux” (or name another platform class) as a **next step** on POSIX Linux `start` / `stop` / not-writable errors (**INC-20260908-001**).  
31. Tell a POSIX Linux operator that an **observed** sshd pid is “not a systemd” service or a “background daemon for this session” when this CLI has not established that it launched that pid (**INC-20260908-002**).  
32. Write the Termux client bundle **without** simpler Ciphers **aes128-ctr,aes256-ctr** and MACs **hmac-sha2-256**, or treat keep-alives-only as **termux yes**. Some Termux OpenSSH `sshd` versions reply too slowly; the client then aborts with **Connection corrupted** / **Bad packet length**.  
33. Treat `dns unset` as deleting the Host stanza, or allow `unset` of **dns** / **ip** (Host name and HostName stay; **delete** drops the stanza).  
34. Hang `ssh` / `download` / `upload` under `--json` / quiet / no TTY, `$()` a `read` helper for the Host, user, or folder pick, skip the TTY **user** prompt on `download` or `upload`, pass HostName/IP instead of the Host alias, `exec` when `SSHD_CLI_SSH` is set, or start a live `ssh` session in JSON mode.  
35. Store download or upload folder history under volatile cache (`/dev/shm`), skip quoting the remote path, extract **download** into `{{HOME}}` instead of the current directory, or extract **upload** into this login `{{HOME}}` instead of the remote ssh user’s home.  
36. Refuse **`~/folder`** as if it were **`~` alone**, single-quote the whole `~/…` string so remote tilde never expands, or expand a **download** `~` against this login and send that local path to the remote host (**INC-20260912-002**).  
37. Treat **upload** `~/folder` as the **remote** ssh user’s home, send this login’s absolute `HOME` as the remote dest, skip the local `test -d`, or use `rsync` / a leftover tarball instead of streamed `tar.gz`.  
38. Share `download-folders` memory with `upload-folders`, or omit numbered **`upload` (14)** from the client TTY menu.  
39. `out_die` (or exit non-zero) solely because a TTY numbered menu received an unknown or out-of-range choice — **MUST** warn and display **that same list** again (main, sudoers, dns action, Host pick, unset picker, download/upload folder pick). Hidden server **22** / **23** / **24** on non-root POSIX Linux are the same class. Hidden front **5** on Termux / Git Bash / Windows cmd is the same class.  
40. On the `termux` OS class, write **active** `HostKeyAlgorithms` / `PubkeyAcceptedAlgorithms` lines (they **MUST** be comments). On `ssh`, skip `-o HostKeyAlgorithms=+ssh-rsa` when that Host's algorithm lines are comments, or add that `-o` when the lines are active.  
41. On Alpine, leave an active `GSSAPI*` line, or delete that line instead of commenting it. On Termux, leave an active `HostKeyAlgorithms` / `PubkeyAcceptedAlgorithms` / `PubkeyAcceptedKeyTypes` line. On another OS, comment those keywords. Skip the automatic `fix-config` pass against `{{HOME}}/.ssh/config`, or print from that pass. Pass `-o GSSAPIAuthentication` from `ssh`, `download`, or `upload`. Number `fix-config` as a menu row.

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-termux-ish.md` | Detect / `pkg` invoke contract; not Type 1 |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention of domain verbs and `install` companion |
| `docs/requirements/requirement-shell-self-management.md` | `inst_ensure_companion` orchestrator; login rc |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Interactive empty argv = this menu; non-interactive = CLI self-install (not payload) |
| `docs/requirements/requirement-shell-output-requirements.md` | `out_*` |
| `docs/requirements/requirement-class-software-dev.md` | Class residual points here |
| `./sshd-cli` | Implementation |

## 6. Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-04**, **TP-CLI-06**, **TP-CLI-14**, **TP-CLI-15** | `tests/test_cli.sh` | have |
| **TP-SSHD-01**, **TP-SSHD-03**, **TP-SSHD-04**, **TP-SSHD-05**, **TP-SSHD-06**, **TP-SSHD-07**, **TP-SSHD-08** | `tests/test_cli.sh` | have |
| **TP-SSHD-09** .. **TP-SSHD-14**, **TP-SSHD-16** | `tests/test_cli.sh` | have |
| **TP-SSHD-15** | `tests/test_local_lifecycle.sh` | have |
| **TP-LC-16**, **TP-LC-17**, **TP-SSHD-02**, **TP-TX-09**, **TP-TX-13**, **TP-TX-16** | `tests/test_local_lifecycle.sh` | have |
| **TP-DNS-01** .. **TP-DNS-52** | `tests/test_dns.sh` | have |
| **TP-FIX-01** .. **TP-FIX-14** | `tests/test_fix_config.sh` | have |
| **TP-SSH-01** .. **TP-SSH-10** | `tests/test_ssh_download.sh` | have |
| **TP-DL-01** .. **TP-DL-17** | `tests/test_ssh_download.sh` | have |
| **TP-CFG-17** | `tests/test_config_backup.sh` | have |
| **TP-UL-01** .. **TP-UL-18** | `tests/test_ssh_download.sh` | **have** |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

**Last Updated**: 2026-10-14 (1.27.4 front **5** sudoers **51–55**, front **6** self-management **61–67**, front **7** language block **70–89** assigned **71–83**. 1.27.3 front **7** prints `sudoers not available for termux` / `gitbash` / `windows-cmd`. 1.27.2 language rows **51–63**. 1.27.1 menu language is front **5**, block **50–69**. 1.27.0 `fix-config` comments unsupported OpenSSH client keywords by OS class, including an automatic pass on `~/.ssh/config`. Add, update, and review share that rule. **TP-FIX-01..14**. **TP-DNS-52**. 1.26.8 Alpine OpenSSH does not support an active `GSSAPIAuthentication`. 1.26.7 menu sample also points at the language requirement’s worked samples and translation tables. 1.26.6 language **67–68**. 1.26.5 language **63–66**. 1.26.4 front **6** language. 1.26.3 menu handler is `app_cmd_menu`. 1.26.2 menu sample points at the live boards in `requirement-shell-cli-default-interaction` §2.11. 1.26.1 menu-hidden message: client and server sentences stay; front **7** hide is its own cause and still Gap. 1.26.0 Termux Old OpenSSH comments and `ssh -o HostKeyAlgorithms=+ssh-rsa`; **TP-DNS-50** · **TP-DNS-51** · **TP-SSH-10**. 1.25.0 sudoers front **7** / **71–75**. Finished TTY leaf redisplays the front board; **TP-CLI-22**)  
**Owner**: Cloudgen Wong  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
