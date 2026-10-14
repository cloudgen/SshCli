**file**: docs/requirements/requirement-shell-exit-condition.md  
**Status**: Active (Version 1.0.1)  
**Area**: shell  
**Key**: `requirement-shell-exit-condition`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the catalog of every condition that ends the sshd-cli process. It names the exit function, the status, and the error message for each condition. Output law owns how a line is printed. This file owns when the process stops.

The shape follows the process-exit catalog used by the sibling product tmpl-to-prj. The rows are this ship unit’s messages. They are not that product’s plan and apply rows.

### 1.1 Human-facing

**In one sentence:** When this program stops because something failed, it prints one `[ERROR]` line and leaves with status 1; a finished command or front-menu Exit leaves with status 0 and no error line.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Person reading the terminal | `sshd-cli nosuch` |
| The other role | A script that checks `$?` | `sshd-cli --json nosuch` |
| Not this file | How colors and JSON are formatted | `requirement-shell-output-requirements` |

| Includes | Excludes |
|----------|----------|
| `out_die` and every `return 1` that becomes the process status | A `[WARN]` that continues the same command |
| Front-menu Exit (status 0) | A bad menu number, which reprints the menu |

| Surface | What you open | What for |
|---------|---------------|----------|
| `src/sshd-cli` | ship unit | `out_die` and the messages below |
| `sshd-cli help` | command | verbs that can end the process |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Pass a name this program does not know | The process prints `[ERROR]` and stops. Status is 1. The next step is in the message. | `sshd-cli nosuch` |

---

## 2. Core Rules / Requirements (Mandatory)

1. The ship unit **MUST** set `set -u` and **MUST NOT** set global `set -e`. A failed command **MUST NOT** end the process unless a row below says so.  
2. The only fatal helper is `out_die`. Its body **MUST** stay: call `out_json_error` with the message, call `out_text` for the error line, then `exit 1`. **MUST NOT** add `exit 2` or a second fatal helper.  
3. `app_main` **MAY** call `exit $?` only on the zero-cli-verb paths (TTY menu, and non-interactive self-install). Every other command returns into `app_main`. `app_main "$@"` is the last command of the script, so that return is the process status unless `out_die` already called `exit 1`.  
4. Human mode (`JSON=0`): `out_die` **MUST** print `[ERROR] <message>` on stderr, then status 1. Quiet mode still prints that line.  
5. JSON mode (`JSON=1`): `out_die` **MUST** print one stderr object `{"type":"out_error","message":"<message>","code":"unknown"}` and **MUST NOT** print the human `[ERROR]` line. Status is still 1. `out_die` does not pass a code, so the code field stays `unknown`.  
6. A direct command (and non-interactive empty argv, which places the CLI) **MUST** end the process with the status of that command. `return 1` after `out_error` or `out_json_error` is status 1. `return 0` is status 0.  
7. The front TTY menu **MUST** end the process with status 0 on choice `9`, `99`, `999`, `exit`, an empty line, or end of input. The token is case-sensitive: `exit` matches; `Exit`, `quit`, and `q` on the front board do not. A bad menu number **MUST** `out_warn` and read again. It **MUST NOT** call `out_die`.  
8. A nested menu layer’s `0`, `q`, `exit`, or empty line returns only to the parent. That is not a process ending.  
9. `out_die` ends the process even when the call comes from the menu. A `return 1` that is not `out_die` does not leave the menu. Menu handlers return 0 after a leaf, so that leaf’s status is not the process status.  
10. Every new `out_die` message and every new `return 1` error message that can become the process status **MUST** add a row to the tables in the same change. A row **MUST** name the condition, the function, the status, and the message text.  
11. A condition this law marks “continue” **MUST NOT** call `out_die` and **MUST NOT** become the process status.  
12. This product does not install a SIGINT trap and does not define status 130.

### 2.1 Implementation Notes (this project)

Ship unit: `src/sshd-cli`. Exit function:

```sh
out_die() { out_json_error "$*"; out_text out_error "$*"; exit 1; }
```

`app_main "$@"` is the last command of the script. Its return status is the process status unless `out_die` already called `exit 1`, or a zero-cli-verb path already called `exit $?`.

#### Exit function rows (`out_die`, status 1)

The message is the human `[ERROR]` text. In JSON mode the same text is the `message` field and `code` is `unknown`. Shell variables stay as the ship unit writes them. The same function and the same text at more than one call site is one row.

| ID | Function | Message |
|----|----------|---------|
| EX-DIE-01 | `inst_perform_install_download_with_checksum` | `Checksum verification failed. The downloaded file does not match the provided CHECKSUM. Installation aborted for security.` |
| EX-DIE-02 | `inst_perform_install_download_without_checksum` (same text at 2 call sites) | `Checksum verification failed (mismatch with ${SCRIPT_URL}.sha256). Installation aborted for security.` |
| EX-DIE-03 | `path_rc_test` | `Unknown rc-test operand: $1. Next: ${APP_NAME} rc-test --root <dir> --file bashrc\|profile --case create\|modify\|noop` |
| EX-DIE-04 | `path_rc_test` | `Unknown rc-test --file ${file}. Next: use bashrc, zshrc, or profile.` |
| EX-DIE-05 | `path_rc_test` | `Unknown rc-test --case ${cas}. Next: use create, modify, or noop.` |
| EX-DIE-06 | `path_rc_test` | `Could not create rc-test root.` |
| EX-DIE-07 | `path_rc_test` | `Could not create rc-test --root ${root}.` |
| EX-DIE-08 | `path_rc_test` | `rc-test create did not write ${dest}.` |
| EX-DIE-09 | `path_rc_test` | `rc-test create must not invent .zshrc.` |
| EX-DIE-10 | `path_rc_test` | `rc-test create did not create ${dest}. Next: check --root is writable.` |
| EX-DIE-11 | `path_rc_test` | `rc-test modify lost the dongle body in ${dest}.` |
| EX-DIE-12 | `path_rc_test` | `rc-test noop changed ${dest}.` |
| EX-DIE-13 | `path_rc_test` | `rc-test ${cas} missing exact PATH line in ${dest}.` |
| EX-DIE-14 | `path_rc_test` | `rc-test ${cas} profile does not source bashrc.` |
| EX-DIE-15 | `util_resolve_storage` | `Cannot create cache folder` |
| EX-DIE-16 | `util_resolve_persistent_storage` | `Persistence storage must not be the install bin directory ${_persist}` |
| EX-DIE-17 | `util_resolve_persistent_storage` | `Cannot create persistence storage ${_persist}` |
| EX-DIE-18 | `sshd_pkg_ensure` | `Termux package tool pkg was not found, so openssh and termux-auth could not be installed. Next: open a Termux session where pkg works, then run: ${APP_NAME} install` |
| EX-DIE-19 | `sshd_pkg_ensure` (same text at 2 call sites) | `Could not install openssh and termux-auth with pkg. Next: run: pkg install openssh termux-auth` |
| EX-DIE-20 | `sshd_cmd_wake_lock` | `Termux wake-lock helper was not found, so the Android wake lock could not be acquired. Next: run: pkg install termux-tools then ${APP_NAME} wake-lock` |
| EX-DIE-21 | `sshd_cmd_wake_lock` | `termux-wake-lock failed. Next: run: termux-wake-lock then ${APP_NAME} wake-lock` |
| EX-DIE-22 | `sshd_cmd_wake_unlock` | `Termux wake-unlock helper was not found, so the Android wake lock could not be released. Next: run: pkg install termux-tools then ${APP_NAME} wake-unlock` |
| EX-DIE-23 | `sshd_cmd_wake_unlock` | `termux-wake-unlock failed. Next: run: termux-wake-unlock` |
| EX-DIE-24 | `sshd_need_bin` | `OpenSSH sshd is not installed. Next: run ${APP_NAME} install (it runs: pkg install openssh termux-auth), then retry ${APP_NAME} start` |
| EX-DIE-25 | `sshd_need_bin` | `OpenSSH sshd is not installed. Next: ` plus `sshd_openssh_server_hint` for POSIX Linux: `install the openssh-server package with this OS package tool (dnf on Fedora and RHEL, apt on Debian and Ubuntu). ${APP_NAME} does not run that command. Then retry ${APP_NAME} start.` |
| EX-DIE-26 | `sshd_need_writable` | `This login cannot write ${_target}. On Termux these paths are usually yours after ${APP_NAME} install.` |
| EX-DIE-27 | `sshd_need_writable` | `This login cannot write ${_target}. Re-run as root.` |
| EX-DIE-28 | `sshd_cmd_start` (same text at 2 call sites) | `Starting system sshd needs a root login on this host. Re-run as root.` |
| EX-DIE-29 | `sshd_cmd_start` | `systemctl start ${_unit} failed. Re-run as root.` |
| EX-DIE-30 | `sshd_cmd_start` | `Could not create host-key folder ${SSHD_HOSTKEY_DIR}.` |
| EX-DIE-31 | `sshd_cmd_start` | `sshd config is missing: ${SSHD_CONFIG}. Install OpenSSH first.` |
| EX-DIE-32 | `sshd_cmd_start` | `sshd refused the config (${SSHD_CONFIG}). ${_err}` |
| EX-DIE-33 | `sshd_cmd_start` | `sshd did not start. Check ${SSHD_CONFIG} and host keys under ${SSHD_HOSTKEY_DIR}.` |
| EX-DIE-34 | `sshd_cmd_stop` (same text at 2 call sites) | `Stopping system sshd needs a root login on this host. Re-run as root.` |
| EX-DIE-35 | `sshd_cmd_stop` | `systemctl stop ${_unit} failed. Re-run as root.` |
| EX-DIE-36 | `sshd_cmd_stop` | `Could not stop sshd (pid ${_pid}).` |
| EX-DIE-37 | `sshd_cmd_restart` | `Restarting system sshd needs a root login on this host. Re-run as root.` |
| EX-DIE-38 | `sshd_cmd_restart` | `systemctl restart ${_unit} failed. Re-run as root.` |
| EX-DIE-39 | `sshd_cmd_port` (same text at 2 call sites) | `Port must be a number from 1 to 65535, not '${_want}'.` |
| EX-DIE-40 | `sshd_cmd_port` | `sshd config is missing: ${SSHD_CONFIG}.` |
| EX-DIE-41 | `sshd_cmd_port` | `Could not create a temp file for the config edit.` |
| EX-DIE-42 | `sshd_cmd_port` | `Could not rewrite ${SSHD_CONFIG}.` |
| EX-DIE-43 | `sshd_cmd_port` | `Could not replace ${SSHD_CONFIG}.` |
| EX-DIE-44 | `sshd_cmd_host_keys_generate` | `ssh-keygen is not installed. Next: run ${APP_NAME} install (Termux installs openssh), then retry ${APP_NAME} host-keys generate` |
| EX-DIE-45 | `sshd_cmd_host_keys_generate` | `Could not create ${SSHD_HOSTKEY_DIR}.` |
| EX-DIE-46 | `sshd_cmd_host_keys_generate` | `Could not generate ed25519 host key under ${SSHD_HOSTKEY_DIR}.` |
| EX-DIE-47 | `sshd_cmd_host_keys` | `Unknown host-keys action '${_sub}'. Use list or generate.` |
| EX-DIE-48 | `sshd_cmd_auth_keys` | `Could not create ${SSHD_USER_SSH_DIR}.` |
| EX-DIE-49 | `sshd_cmd_auth_keys` | `auth-keys add needs a public-key file path. Example: ${APP_NAME} auth-keys add ./id_ed25519.pub` |
| EX-DIE-50 | `sshd_cmd_auth_keys` | `Cannot read public-key file: ${_arg}` |
| EX-DIE-51 | `sshd_cmd_auth_keys` | `No SSH public key line found in ${_arg}.` |
| EX-DIE-52 | `sshd_cmd_auth_keys` | `Could not create ${SSHD_AUTH_KEYS}.` |
| EX-DIE-53 | `sshd_cmd_auth_keys` | `Could not append to ${SSHD_AUTH_KEYS}.` |
| EX-DIE-54 | `sshd_cmd_auth_keys` | `Unknown auth-keys action '${_sub}'. Use list or add <pubkey-file>.` |
| EX-DIE-55 | `sshd_refuse_config_backup_on_nuser` | `backup-config and sync-config are not available for ${_lab}. Next: use a POSIX Linux host, or copy ~/.ssh/config by hand.` |
| EX-DIE-56 | `sshd_sudoers_refuse_forbidden_grant` | `sudoer grant file missing` |
| EX-DIE-57 | `sshd_sudoers_refuse_forbidden_grant` | `refusing sudoer grant with OS-tool commands (need ${GLOBAL_BIN}/${APP_NAME} backup-config only)` |
| EX-DIE-58 | `sshd_sudoers_verify_grant_verbs` | `sudoer file missing (cannot verify backup-config)` |
| EX-DIE-59 | `sshd_sudoers_verify_grant_verbs` | `Sudoer file is incomplete: it does not allow backup-config. Path: ${_gf}` |
| EX-DIE-60 | `sshd_sudoers_require_emit_trust` | `${_cmd} trust tier is ${_tier} (not production). Prefer: sudo ${APP_NAME} install (global ${GLOBAL_BIN}/${APP_NAME}). To emit a test file: ${APP_NAME} ${_cmd} --allow-test-local  or ALLOW_TEST_LOCAL_SUDOERS=1` |
| EX-DIE-61 | `sshd_cmd_backup_config` | `Cannot backup-config: missing ${_src}. Next: create this login's SSH config (for example ${APP_NAME} dns add), then ${APP_NAME} backup-config.` |
| EX-DIE-62 | `sshd_cmd_backup_config` | `Cannot push to ${_dest}: need the global binary ${_bin} (sudo ${APP_NAME} backup-config). Next: sudo sh src/${APP_NAME} install, then ${APP_NAME} generate-sudoer-request and ${APP_NAME} submit-sudoer-request so sudoer-adm can approve passwordless sudo ${APP_NAME} backup-config.` |
| EX-DIE-63 | `sshd_cmd_backup_config` | `sudo not found. Pushing into ${_dest} needs passwordless sudo ${APP_NAME} backup-config after sudoer-adm approval.` |
| EX-DIE-64 | `sshd_cmd_backup_config` | `sudo ${APP_NAME} backup-config was refused. Next: ${APP_NAME} generate-sudoer-request && ${APP_NAME} submit-sudoer-request, then ask sudoer-adm to approve the JSON grant (NOPASSWD ${_bin} backup-config).` |
| EX-DIE-65 | `sshd_cmd_backup_config` | `Cannot create ${_dest} (need allowlisted sudo ${APP_NAME} backup-config). Next: ${APP_NAME} generate-sudoer-request && ${APP_NAME} submit-sudoer-request.` |
| EX-DIE-66 | `sshd_cmd_backup_config` | `Cannot write ${_dest}. Only an approved passwordless sudo ${APP_NAME} backup-config may push files there.` |
| EX-DIE-67 | `sshd_cmd_backup_config` (same text at 2 call sites) | `Failed to copy ${_src} into ${_dest}.` |
| EX-DIE-68 | `sshd_cmd_sync_config` | `Cannot sync-config: store missing (${_src}). Next: someone with an approved sudo ${APP_NAME} backup-config must push ~/.ssh/config first.` |
| EX-DIE-69 | `sshd_cmd_sync_config` | `Cannot read ${_src} without sudo. The store file must be world-readable (backup-config chmod 0644).` |
| EX-DIE-70 | `sshd_cmd_sync_config` | `Cannot create ${_destdir}.` |
| EX-DIE-71 | `sshd_cmd_sync_config` (same text at 2 call sites) | `Failed to write ${_dest}.` |
| EX-DIE-72 | `sshd_cmd_sync_from_remote` | `Cannot sync-from-remote: missing remote. Next: ${APP_NAME} sync-from-remote USER@HOST` |
| EX-DIE-73 | `sshd_cmd_sync_from_remote` | `Cannot sync-from-remote: remote '${_spec}' is not user@host, IPv4, domain, or user@domain. Next: ${APP_NAME} sync-from-remote USER@HOST` |
| EX-DIE-74 | `sshd_cmd_sync_from_remote` | `Cannot sync-from-remote: scp not found. Next: install openssh-client, then ${APP_NAME} sync-from-remote ${_spec}` |
| EX-DIE-75 | `sshd_cmd_sync_from_remote` | `Cannot create ${_destdir}.` |
| EX-DIE-76 | `sshd_cmd_sync_from_remote` | `Could not create a temp file for sync-from-remote.` |
| EX-DIE-77 | `sshd_cmd_sync_from_remote` | `Cannot sync-from-remote: scp from ${_label} failed. Next: ssh ${_label}, then ${APP_NAME} sync-from-remote ${_spec}` |
| EX-DIE-78 | `sshd_cmd_sync_from_remote` | `Cannot sync-from-remote: remote ${_label} has no config under ${SSHD_CLI_REMOTE_ROOT}. Next: on that host run ${APP_NAME} backup-config, then ${APP_NAME} sync-from-remote ${_spec}` |
| EX-DIE-79 | `sshd_cmd_sync_from_remote` (same text at 2 call sites) | `Failed to write ${_dest}.` |
| EX-DIE-80 | `sshd_cmd_print_sudoers` | `print-sudoers trust tier is ${_tier} (not production). Prefer: sudo ${APP_NAME} install (global ${_global_path}). To emit a test fragment anyway: ${APP_NAME} print-sudoers --allow-test-local [path] or ALLOW_TEST_LOCAL_SUDOERS=1` |
| EX-DIE-81 | `sshd_cmd_print_sudoers` | `Cannot create ${_dir}` |
| EX-DIE-82 | `sshd_cmd_print_sudoers` | `Cannot write ${_out_path}` |
| EX-DIE-83 | `sshd_cmd_generate_sudoer_request` | `generate-sudoer-request refuses to write under /etc (Type 0). Use a path under $HOME or /dev/shm.` |
| EX-DIE-84 | `sshd_cmd_generate_sudoer_request` | `generate-sudoer-request does not write inbound. Write a local file, then: ${APP_NAME} submit-sudoer-request <path>` |
| EX-DIE-85 | `sshd_cmd_generate_sudoer_request` | `Cannot create ${_dir}` |
| EX-DIE-86 | `sshd_cmd_generate_sudoer_request` | `Cannot write ${_out_path}` |
| EX-DIE-87 | `sshd_cmd_submit_sudoer_request` | `sudoer-cli not found (set SUDOER_CLI or install sudoer-cli). Submit is Type 0 compose — this CLI does not write /etc. Next: ${APP_NAME} generate-sudoer-request, then install sudoer-cli, then ${APP_NAME} submit-sudoer-request.` |
| EX-DIE-88 | `sshd_cmd_submit_sudoer_request` | `sudoer-adm not found (id ${SUDOER_ADM_USER:-sudoer-adm} failed). Ask an admin to run: sudo sudoer-cli setup` |
| EX-DIE-89 | `sshd_cmd_submit_sudoer_request` | `sudoer inbound queue not found (preferred /var/sudoer-cli/sudoer-request). Ask an admin to run: sudo sudoer-cli setup` |
| EX-DIE-90 | `sshd_cmd_submit_sudoer_request` | `sudoer inbound not writable: ${_inbound}.` |
| EX-DIE-91 | `sshd_cmd_submit_sudoer_request` | `sudoers file not found: ${_src_file}` |
| EX-DIE-92 | `sshd_cmd_submit_sudoer_request` | `Could not create a temp sudoer file.` |
| EX-DIE-93 | `sshd_cmd_submit_sudoer_request` | `cannot write temp sudoer JSON ${_tmp}` |
| EX-DIE-94 | `sshd_cmd_submit_sudoer_request` | `sudoer-cli ${_verb} failed: ${_err}` |
| EX-DIE-95 | `sshd_cmd_submit_sudoer_request` | `sudoer-cli ${_verb} failed (exit ${_rc})` |
| EX-DIE-96 | `sshd_cmd_remove_project_sudoers` | `Refusing to remove paths under /etc as Type 0. This command only deletes the user draft. Host elev is admin-only: ${APP_NAME} print-sudoers-install-script && sudo sh <script> uninstall` |
| EX-DIE-97 | `sshd_cmd_remove_project_sudoers` | `No project-sudoers draft at ${_path}.` |
| EX-DIE-98 | `sshd_cmd_remove_project_sudoers` | `Could not remove ${_path}.` |
| EX-DIE-99 | `sshd_cmd_sudoers_menu` | `sudoers menu needs a terminal. Next: ${APP_NAME} generate-sudoer-request` |
| EX-DIE-100 | `sshd_dns_prompt_yn` | `${_yn_label} needs y or n, not '${_yn_ans}'.` |
| EX-DIE-101 | `sshd_dns_parse_yn_operand` | `${_yn_field} needs yes or no, not '${_yn_raw}'.` |
| EX-DIE-102 | `sshd_dns_validate_idonly` | `identities-only needs yes, no, or empty, not '${_vio}'.` |
| EX-DIE-103 | `sshd_dns_validate_name` | `dns name cannot be empty. Next: ${_vnext}` |
| EX-DIE-104 | `sshd_dns_validate_name` | `dns name '${_vname}' is not a Host alias (use letters, digits, dot, underscore, hyphen). Next: ${_vnext}` |
| EX-DIE-105 | `sshd_dns_validate_port` (same text at 2 call sites) | `Port must be a number from 1 to 65535, not '${_vp}'.` |
| EX-DIE-106 | `sshd_dns_ensure_file` | `Could not create ${_ens_dir}.` |
| EX-DIE-107 | `sshd_dns_ensure_file` | `Could not create ${_ens_cfg}.` |
| EX-DIE-108 | `sshd_dns_ensure_file` | `ssh config is not writable: ${_ens_cfg}.` |
| EX-DIE-109 | `sshd_dns_backup` | `Could not backup ${_bk_cfg}.` |
| EX-DIE-110 | `sshd_dns_commit_tmp` | `Could not replace ${_cm_cfg}.` |
| EX-DIE-111 | `sshd_cmd_fix_config` | `--input-file requires a path. Next: ${APP_NAME} fix-config [--input-file PATH] [--output-file PATH].` |
| EX-DIE-112 | `sshd_cmd_fix_config` | `--output-file requires a path. Next: ${APP_NAME} fix-config [--input-file PATH] [--output-file PATH].` |
| EX-DIE-113 | `sshd_cmd_fix_config` | `Unknown fix-config operand: $1. Next: ${APP_NAME} fix-config [--input-file PATH] [--output-file PATH].` |
| EX-DIE-114 | `sshd_cmd_fix_config` | `Cannot read ssh config: ${_fcc_in}.` |
| EX-DIE-115 | `sshd_cmd_fix_config` | `Could not create a temp file for ssh config.` |
| EX-DIE-116 | `sshd_cmd_fix_config` | `Could not rewrite ${_fcc_in}.` |
| EX-DIE-117 | `sshd_cmd_fix_config` (same text at 2 call sites) | `Cannot write ssh config: ${_fcc_out}.` |
| EX-DIE-118 | `sshd_cmd_fix_config` | `Could not write ${_fcc_out}.` |
| EX-DIE-119 | `sshd_cmd_fix_config` | `ssh config is not writable: ${_fcc_in}.` |
| EX-DIE-120 | `sshd_cmd_fix_config` | `Could not replace ${_fcc_in}.` |
| EX-DIE-121 | `sshd_dns_plain_copy` | `Could not create a temp file for ssh config.` |
| EX-DIE-122 | `sshd_dns_plain_copy` | `Could not rewrite ${_plain_in}.` |
| EX-DIE-123 | `sshd_dns_rewrite` | `Could not create a temp file for ssh config.` |
| EX-DIE-124 | `sshd_dns_rewrite` | `Could not rewrite ${_cfg}.` |
| EX-DIE-125 | `sshd_dns_append` | `Could not create a temp file for ssh config.` |
| EX-DIE-126 | `sshd_dns_append` | `Could not rewrite ${_cfg}.` |
| EX-DIE-127 | `sshd_dns_remove` | `Could not create a temp file for ssh config.` |
| EX-DIE-128 | `sshd_dns_remove` | `Could not rewrite ${_cfg}.` |
| EX-DIE-129 | `sshd_dns_parse_kv` | `dns needs a value. Next: ${APP_NAME} dns set <n> dns <name>` |
| EX-DIE-130 | `sshd_dns_parse_kv` | `ip needs a value. Next: ${APP_NAME} dns set <n> ip <addr>` |
| EX-DIE-131 | `sshd_dns_parse_kv` | `user needs a value (use "" for empty). Next: ${APP_NAME} dns set <n> user ""` |
| EX-DIE-132 | `sshd_dns_parse_kv` | `port needs a value (use "" for default 22). Next: ${APP_NAME} dns set <n> port ""` |
| EX-DIE-133 | `sshd_dns_parse_kv` | `identity-file needs a value (use "" for empty). Next: ${APP_NAME} dns set <n> identity-file ""` |
| EX-DIE-134 | `sshd_dns_parse_kv` | `identities-only needs yes, no, or empty. Next: ${APP_NAME} dns set <n> identities-only yes` |
| EX-DIE-135 | `sshd_dns_parse_kv` | `termux needs yes or no. Next: ${APP_NAME} dns add dns <name> termux yes` |
| EX-DIE-136 | `sshd_dns_parse_kv` | `old-openssh needs yes or no. Next: ${APP_NAME} dns add dns <name> old-openssh yes` |
| EX-DIE-137 | `sshd_dns_parse_kv` | `Unknown dns field '${1}'. Use dns, ip, user, port, identity-file, identities-only, termux, or old-openssh.` |
| EX-DIE-138 | `sshd_dns_apply_set` | `No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list` |
| EX-DIE-139 | `sshd_dns_apply_set` | `dns name '${_dns}' is already a Host entry. Next: ${APP_NAME} dns list` |
| EX-DIE-140 | `sshd_dns_walk_edit` | `No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list` |
| EX-DIE-141 | `sshd_dns_walk_edit` | `dns edit needs a terminal. Next: ${APP_NAME} dns set ${_n} ip <addr> user "" port 22` |
| EX-DIE-142 | `sshd_dns_walk_edit` | `dns name '${_dns}' is already a Host entry. Next: ${APP_NAME} dns list` |
| EX-DIE-143 | `sshd_dns_walk_add` | `dns name '${_dns}' is already a Host entry. Next: ${APP_NAME} dns list` |
| EX-DIE-144 | `sshd_dns_unset_refuse_identity` | `Cannot unset dns or ip (the Host name and address stay). Next: ${APP_NAME} dns unset <n> user` |
| EX-DIE-145 | `sshd_dns_unset_parse_fields` | `Unknown extra setting '${1}'. Use user, port, identity-file, identities-only, termux, or old-openssh (not dns or ip). Next: ${APP_NAME} dns unset <n> user` |
| EX-DIE-146 | `sshd_dns_walk_unset` | `No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list` |
| EX-DIE-147 | `sshd_dns_apply_unset` | `dns unset needs a number or Host name and a field. Next: ${APP_NAME} dns unset <n> user` |
| EX-DIE-148 | `sshd_dns_apply_unset` | `No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list` |
| EX-DIE-149 | `sshd_dns_apply_unset` (same text at 2 call sites) | `dns unset needs a field (user, port, identity-file, identities-only, termux, or old-openssh — not dns or ip). Next: ${APP_NAME} dns unset ${_sel} user` |
| EX-DIE-150 | `sshd_dns_apply_delete` | `No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list` |
| EX-DIE-151 | `sshd_cmd_dns` | `dns show needs a number or Host name. Next: ${APP_NAME} dns list` |
| EX-DIE-152 | `sshd_cmd_dns` | `No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list` |
| EX-DIE-153 | `sshd_cmd_dns` | `dns edit needs a number or Host name. Next: ${APP_NAME} dns list` |
| EX-DIE-154 | `sshd_cmd_dns` | `dns set needs a number or Host name. Next: ${APP_NAME} dns list` |
| EX-DIE-155 | `sshd_cmd_dns` | `dns delete needs a number or Host name. Next: ${APP_NAME} dns list` |
| EX-DIE-156 | `sshd_cmd_dns` | `Unknown dns action '${_sub}'. Use list, show, edit, set, add, delete, or unset.` |
| EX-DIE-157 | `sshd_ssh_validate_user` | `user '${_vu}' is not allowed. Use letters, digits, dot, underscore, or hyphen. Next: ${APP_NAME} ${_vu_next}` |
| EX-DIE-158 | `sshd_download_validate_folder` | `download needs a remote folder. Next: ${APP_NAME} download <n\|name> /path/on/that-host` |
| EX-DIE-159 | `sshd_download_validate_folder` (same text at 2 call sites) | `Remote folder '${_vf}' is not allowed. Use an absolute or relative path, or ~/folder (not ., .., /, or ~ alone). Next: ${APP_NAME} download <n\|name> /path/on/that-host` |
| EX-DIE-160 | `sshd_download_validate_folder` | `Remote folder '${_vf}' is not allowed. Use ~/folder for the remote login home (not ~ alone). Next: ${APP_NAME} download <n\|name> /path/on/that-host` |
| EX-DIE-161 | `sshd_download_validate_folder` | `Remote folder '${_vf}' is not allowed. Use ~/folder for the remote login home (not ~ alone or ~user). Next: ${APP_NAME} download <n\|name> /path/on/that-host` |
| EX-DIE-162 | `sshd_download_validate_folder` | `Remote folder '${_vf}' has a character that is not allowed. Next: ${APP_NAME} download <n\|name> /path/on/that-host` |
| EX-DIE-163 | `sshd_download_walk_folder` | `download needs a remote folder. Next: ${APP_NAME} download ${_dw_name} /path/on/that-host` |
| EX-DIE-164 | `sshd_cmd_ssh` | `ssh needs a number or Host name. Next: ${APP_NAME} dns list, then ${APP_NAME} ssh <n\|name>` |
| EX-DIE-165 | `sshd_cmd_ssh` | `No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list` |
| EX-DIE-166 | `sshd_cmd_ssh` | `Cannot ssh: OpenSSH client not found. Next: install openssh-client, then ${APP_NAME} ssh ${_dns}` |
| EX-DIE-167 | `sshd_cmd_ssh` (same text at 4 call sites) | `ssh ${_dns} failed. Next: ssh -o HostKeyAlgorithms=+ssh-rsa ${_dns}` |
| EX-DIE-168 | `sshd_cmd_ssh` (same text at 4 call sites) | `ssh ${_dns} failed. Next: ssh ${_dns}` |
| EX-DIE-169 | `sshd_cmd_ssh` | `Could not start ssh ${_dns}. Next: ssh ${_dns}` |
| EX-DIE-170 | `sshd_cmd_download` | `download needs a number or Host name and a remote folder. Next: ${APP_NAME} dns list, then ${APP_NAME} download <n\|name> /path/on/that-host` |
| EX-DIE-171 | `sshd_cmd_download` | `No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list` |
| EX-DIE-172 | `sshd_cmd_download` | `download needs a remote folder. Next: ${APP_NAME} download ${_dns} /path/on/that-host` |
| EX-DIE-173 | `sshd_cmd_download` | `Remote folder '${_folder}' is not allowed. Next: ${APP_NAME} download ${_dns} /path/on/that-host` |
| EX-DIE-174 | `sshd_cmd_download` | `Cannot download: OpenSSH client not found. Next: install openssh-client, then ${APP_NAME} download ${_dns} ${_folder}` |
| EX-DIE-175 | `sshd_cmd_download` | `Cannot download: tar not found. Next: install tar, then ${APP_NAME} download ${_dns} ${_folder}` |
| EX-DIE-176 | `sshd_cmd_download` | `Could not create a temp file for download.` |
| EX-DIE-177 | `sshd_cmd_download` (same text at 2 call sites) | `Cannot download: ssh ${_dns} failed. Next: ${_next_ssh}, then ${APP_NAME} download ${_dns} ${_folder}` |
| EX-DIE-178 | `sshd_cmd_download` | `Cannot download: remote ${_dns} returned an empty archive for ${_folder}. Next: ssh ${_dns} and check that folder exists` |
| EX-DIE-179 | `sshd_cmd_download` | `Cannot download: could not extract the archive into ${_cwd}. Next: check this folder is writable, then ${APP_NAME} download ${_dns} ${_folder}` |
| EX-DIE-180 | `sshd_upload_validate_folder` | `upload needs a local folder. Next: ${APP_NAME} upload <n\|name> ./folder` |
| EX-DIE-181 | `sshd_upload_validate_folder` (same text at 2 call sites) | `Local folder '${_vf}' is not allowed. Use an absolute or relative path, or ~/folder (not ., .., /, or ~ alone). Next: ${APP_NAME} upload <n\|name> ./folder` |
| EX-DIE-182 | `sshd_upload_validate_folder` | `Local folder '${_vf}' is not allowed. Use ~/folder for this login home (not ~ alone). Next: ${APP_NAME} upload <n\|name> ./folder` |
| EX-DIE-183 | `sshd_upload_validate_folder` | `Local folder '${_vf}' is not allowed. Use ~/folder for this login home (not ~ alone or ~user). Next: ${APP_NAME} upload <n\|name> ./folder` |
| EX-DIE-184 | `sshd_upload_validate_folder` | `Local folder '${_vf}' has a character that is not allowed. Next: ${APP_NAME} upload <n\|name> ./folder` |
| EX-DIE-185 | `sshd_upload_walk_folder` | `upload needs a local folder. Next: ${APP_NAME} upload ${_uw_name} ./folder` |
| EX-DIE-186 | `sshd_cmd_upload` | `upload needs a number or Host name and a local folder. Next: ${APP_NAME} dns list, then ${APP_NAME} upload <n\|name> ./folder` |
| EX-DIE-187 | `sshd_cmd_upload` | `No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list` |
| EX-DIE-188 | `sshd_cmd_upload` | `upload needs a local folder. Next: ${APP_NAME} upload ${_dns} ./folder` |
| EX-DIE-189 | `sshd_cmd_upload` | `Local folder '${_folder}' is not a directory. Next: ${APP_NAME} upload ${_dns} ./folder` |
| EX-DIE-190 | `sshd_cmd_upload` | `Local folder '${_folder}' is not allowed. Next: ${APP_NAME} upload ${_dns} ./folder` |
| EX-DIE-191 | `sshd_cmd_upload` | `Cannot upload: OpenSSH client not found. Next: install openssh-client, then ${APP_NAME} upload ${_dns} ${_folder}` |
| EX-DIE-192 | `sshd_cmd_upload` | `Cannot upload: tar not found. Next: install tar, then ${APP_NAME} upload ${_dns} ${_folder}` |
| EX-DIE-193 | `sshd_cmd_upload` (same text at 2 call sites) | `Cannot upload: ssh ${_dns} failed. Next: ${_next_ssh}, then ${APP_NAME} upload ${_dns} ${_folder}` |
| EX-DIE-194 | `app_cmd_menu` | `menu needs a terminal. Run a named command instead, for example: ${APP_NAME} status` |
| EX-DIE-195 | `app_main` | `--purpose requires TEXT` |
| EX-DIE-196 | `app_main` | `Unknown command or flag: $1. See '${APP_NAME} help'.` |
| EX-DIE-197 | `sshd_need_bin` via `sshd_openssh_server_hint` | `OpenSSH sshd is not installed. Next: Git Bash does not provide sshd. Install OpenSSH for Windows, then retry ${APP_NAME} start.` |
| EX-DIE-198 | `sshd_need_bin` via `sshd_openssh_server_hint` | `OpenSSH sshd is not installed. Next: Windows cmd does not provide sshd. Install OpenSSH for Windows, then retry ${APP_NAME} start.` |
| EX-DIE-199 | `sshd_need_bin` via `sshd_openssh_server_hint` | `OpenSSH sshd is not installed. Next: install the OpenSSH server on this Mac, then retry ${APP_NAME} start.` |

#### Return status 1 (no `exit` call; the process still ends on a direct command)

Human mode uses `out_error` (`[ERROR]` on stderr). JSON mode uses `out_json_error` with the code in the table. Non-interactive empty argv uses the same rows when `self-install` fails (`app_main` exits with that status). From the TTY menu these rows do not call `exit`; the menu stays up unless the row is an `out_die` row above.

| ID | Condition | Function | JSON code | Message |
|----|-----------|----------|-----------|---------|
| EX-RET-01 | `version-check` cannot read a remote version | `ver_check` | `network_error` | Human: `Failed to fetch remote version (SCRIPT_URL may be unset or unreachable)`. JSON: `Failed to fetch remote version` |
| EX-RET-02 | `self-update` cannot read a remote version | `inst_self_update` | `network_error` | Human: `Failed to fetch latest version (SCRIPT_URL may be unset or unreachable)`. JSON: `Failed to fetch latest version` |
| EX-RET-03 | `self-update` would downgrade and `--force` is off | `inst_self_update` | `downgrade_blocked` | Human: `Refusing silent downgrade: local <local> is newer than remote <remote>.` JSON: `Refusing downgrade from <local> to <remote> (use --force)` |
| EX-RET-04 | Channel download with curl failed | download helpers | `network_error` | `Download failed (curl)` |
| EX-RET-05 | Channel download with wget failed | download helpers | `network_error` | `Download failed (wget)` |
| EX-RET-06 | Neither curl nor wget is on `PATH` | download helpers | `missing_dependency` | `Neither curl nor wget found` |
| EX-RET-07 | JSON mode and `CHECKSUM` does not match (human mode is the checksum `out_die` row) | `inst_perform_install_download_with_checksum` | `checksum_mismatch` | `Checksum verification failed (provided CHECKSUM does not match)` |
| EX-RET-08 | JSON mode and the companion digest does not match (human mode is the companion `out_die` row) | `inst_perform_install_download_without_checksum` | `checksum_mismatch` | `Automatic checksum verification failed` |
| EX-RET-09 | Stage temp file could not be created | `inst_perform_install`, `inst_self_install`, `inst_self_install_copy_from_script` | `io_error` | `Failed to create temporary file` |
| EX-RET-10 | Companion-digest temp file could not be created | `inst_perform_install_download_without_checksum` | `io_error` | `Failed to create temporary file for checksum` |
| EX-RET-11 | Channel place could not create `GLOBAL_BIN` | `inst_perform_install_prepare_target` | `io_error` | `Failed to create <GLOBAL_BIN>` |
| EX-RET-12 | Channel place could not create `USER_BIN` | `inst_perform_install_prepare_target` | `io_error` | `Failed to create <USER_BIN>` |
| EX-RET-13 | Copy of the running script into the stage failed | `inst_self_install_copy_from_script` | `io_error` | `Failed to copy <src>` |
| EX-RET-14 | Move onto the install path failed | `inst_perform_install_atomic_install`, `inst_self_install_copy_from_script` | `io_error` | `Failed to move to <INSTALL_PATH>` |
| EX-RET-15 | `self-uninstall` without `--force` when JSON, quiet, or not a TTY | `inst_self_uninstall_confirm_and_remove` | `confirm_required` | `Uninstall requires --force in non-interactive mode (refusing to remove <path>).` |
| EX-RET-16 | TTY `self-uninstall` confirm answered no | `inst_self_uninstall_confirm_and_remove` | (human only) | `Uninstall cancelled by user.` (plain text, then status 1) |
| EX-RET-17 | `rm` of the install path failed | `inst_self_uninstall_confirm_and_remove` | `permission_denied` | `Failed to remove <path> (permission denied?)` |

#### Status 0 (the process ends without an error line)

| ID | Condition | Status |
|----|-----------|--------|
| EX-OK-01 | `version`, `about`, `help`, or a finished routed verb (`status`, `start`, `stop`, `restart`, `port`, `config`, `host-keys`, `auth-keys`, `dns`, `fix-config`, `ssh`, `download`, `upload`, `wake-lock`, `wake-unlock`, `backup-config`, `sync-config`, `sync-from-remote`, `print-sudoers`, `print-sudoers-install-script`, `generate-sudoer-request`, `submit-sudoer-request`, `remove-project-sudoers`, `rc-test`) | 0 |
| EX-OK-02 | `install` or `self-install` placed the file, or it was already installed and `--force` was off | 0 |
| EX-OK-03 | `version-check` fetched a remote version (newer, same, or local newer). A missing remote version is EX-RET-01 | 0 |
| EX-OK-04 | `self-update` is already current, or the replace finished | 0 |
| EX-OK-05 | `self-uninstall` found nothing to remove, or the remove finished. A TTY confirm answered no is EX-RET-16, not this row | 0 |
| EX-OK-06 | Front menu choice `9`, `99`, `999`, or `exit`, or an empty line, or the menu read hit end of input | 0 |
| EX-OK-07 | Non-interactive empty argv, or `--quiet` / `--json` with no verb, and `self-install` succeeded | 0 |
| EX-OK-08 | Direct `menu` or `main` on a terminal, and the operator left the front board (EX-OK-06) | 0 |

#### Does not end the process

| ID | Condition | What happens |
|----|-----------|----------------|
| EX-CONT-01 | Companion `${SCRIPT_URL}.sha256` is missing | `[WARN]` and the install continues without that check |
| EX-CONT-02 | Bad main-menu, language, client, server, self-management, or sudoers number | `[WARN] Unknown menu choice '<pick>'. Choose a number from the list, or type the command name.` The sentence follows the saved language. Reprint this layer and read again. **MUST NOT** call `out_die` |
| EX-CONT-03 | Nested layer choice `0`, `q`, `exit`, or an empty line | Return to the parent menu only. The process stays up |
| EX-CONT-04 | A menu leaf returns 1 and the call is not `out_die` | The menu handler returns 0. The process stays up |
| EX-CONT-05 | Front row **7** is hidden on Termux, Git Bash, or Windows cmd, and the operator still types `7` | `[WARN]` unknown-menu text, reprint, stay up. The hide sentence before the numbers is not an exit |
| EX-CONT-06 | POSIX Linux `sshd_start_after_install` cannot start host sshd | `[WARN]`, install status stays 0. **MUST NOT** `out_die` on that path. Termux calls `sshd_cmd_start`, and that command’s `out_die` rows still end the process |
| EX-CONT-07 | `util_sudo` and `sudo` is not on `PATH` | `return 1`, no `sudo`, no password prompt, no `out_die`. A caller that still needs elevation uses its own `out_die` row |
| EX-CONT-08 | Creating or noting `BASHRC` or `~/.profile` fails | `[WARN]` from the path helper. `path_add_shell` keeps going. Install does not become status 1 for that miss |
| EX-CONT-09 | `fix-config` automatic pass and this login has no `~/.ssh/config` | Silent no-op. The process continues into the command the operator asked for |

### 2.2 Why This Requirement Exists (CIAO)

- **Principle 1 – Caution:** a failure names itself and stops, or a warning says the work continues.  
- **Principle 2 – Intentional:** one table is the list of endings, taken from `out_die` and the `return 1` messages.  
- **Principle 5 – Single source of output:** this file does not invent a second printer.  
- **Principle 15 – Helpful usage:** fatal messages include a next step when the ship unit already prints one.

---

## Under command line for normal user only

When the ship unit detects Termux, Git Bash, Windows cmd, or the same class, admin privilege and a dedicated system user stay unused.

**This requirement:** EX-DIE-55 is the `backup-config` / `sync-config` exit on that class. It names the class (`termux`, `gitbash`, or `windows-cmd`) and does not run `sudo`. The `pkg` exits in `sshd_pkg_ensure` run only after Termux was detected. EX-CONT-05 keeps a typed `7` on the front board. EX-CONT-07 returns without `sudo` and without `out_die`. **MUST NOT** add an exit that runs `sudo`, wraps `apt`, or recommends `sudo curl | sh`. Git Bash and Windows cmd **MUST NOT** call Termux `pkg`.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Status 1 always has a message. Status 0 does not pretend a warning was fatal.  
- **Intentional:** The tables match the ship unit’s strings.  
- **Anti-fragile:** JSON and human mode both end with the same status.  
- **Over-protect:** Do not replace `out_die` with a bare `exit` in a new command, and do not turn EX-CONT rows into exits.

---

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Add a second fatal helper, or call `exit` outside `out_die` and the two zero-cli-verb `exit $?` sites in `app_main`.  
2. Make a missing companion digest into an `out_die` (EX-CONT-01).  
3. Exit the process on a bad menu number (EX-CONT-02).  
4. Treat nested `0` / `q` / `exit` / empty line as a process ending (EX-CONT-03).  
5. Make a POSIX Linux install fail because host sshd did not start (EX-CONT-06).  
6. Drop a new error message from these tables.  
7. Print a sudo password prompt as an exit path. `util_sudo` stays `sudo -n`.  
8. On Termux, Git Bash, or Windows cmd, add an exit that runs `sudo`, wraps `apt`, or recommends `sudo curl | sh`.

---

## 5. Related artifacts (versioned surface only)

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry |
| `docs/requirements/requirement-shell-output-requirements.md` | `out_die` printing |
| `docs/requirements/requirement-shell-cli-interface.md` | Unknown token (EX-DIE-196) |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Front-menu Exit and bad-pick retry |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv |
| `docs/requirements/requirement-shell-self-management.md` | version-check, self-update, self-uninstall |
| `docs/requirements/requirement-shell-cli-self-install.md` | self-install failures |
| `docs/requirements/requirement-shell-automatic-checksum.md` | Companion digest mismatch |
| `docs/requirements/requirement-shell-cli-storage.md` | Cache and persistence exits (EX-DIE-15 and the persistence rows) |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | Confirm versus `--force` |
| `docs/requirements/requirement-shell-sudo-command.md` | When `util_sudo` may run |
| `docs/requirements/requirement-domain-sshd.md` | Domain command exits |
| `src/sshd-cli` | Implementation |

## Design-time verification

| TP-ID | Suite | Status | Note |
|-------|-------|--------|------|
| TP-EXIT-01 | `tests/test_cli.sh` | todo | Unknown token is EX-DIE-196, status 1, `[ERROR]`, and the help pointer |
| TP-EXIT-02 | `tests/test_cli.sh` | todo | `--json` unknown token is status 1, stderr JSON `type` `out_error`, `code` `unknown`, no `[ERROR]` line |
| TP-EXIT-03 | `tests/test_cli.sh` | todo | Front menu choice `9` is EX-OK-06. A bad menu number is EX-CONT-02 and the process stays up |
| TP-EXIT-04 | `tests/test_cli.sh` | todo | `--purpose` with no text is EX-DIE-195, status 1 |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

## Terminologies

### Error-handling

**Definition:** Error-handling is the deliberate design for when something goes wrong: how a system detects failure, classifies severity, reports it on the correct channel, contains damage, recovers or exits, and leaves the system in a known, safe state.

**Human daily-life explanation:** Error-handling is the household plan for when something breaks: notice it, say how bad it is, tell the right person, stop the mess spreading, and leave the kitchen in a known state. A silent fail is not a plan.

**Daily-life example:** The oven beeps and you pull the tray, open a window, and write “do not use until cool” on a sticky note. That is error-handling, not pretending dinner is fine.

### Graceful exit

**Definition:** Graceful exit is the outcome when the operator sends Ctrl-C while a long child is still running: stop that child, do not publish the unfinished result, and return status 130. It is not this product’s failure catalog, and it is not a tool’s ordinary non-zero exit.

**Human daily-life explanation:** A graceful exit is what you do when you hit the stop button on a blender before the smoothie is finished. You turn the machine off and you do not pour the half-blend into the glass.

**Daily-life example:** The oven timer is still running and you press cancel. You take the tray out and you do not set it on the table as the meal. This program does not define that Ctrl-C path. Its endings are the tables above.

### Well-known exit condition

**Definition:** A well-known exit condition is one row of a closed catalog of conditions that end the process. The catalog has two families. A non-zero ending prints a fatal message and leaves with a status other than 0. A clean ending leaves with status 0 and no fatal line. Exit, quit, an empty line, or end of input on a nested menu layer returns only to the parent and is not a process ending. The same controls on the front menu are a clean ending when this product’s front board lists them. A direct command's non-zero return is a non-zero ending. That same return does not end the process when a menu is still the caller and the call is not the fatal-exit helper. A product requirement fills the message text for its rows. Each kind is its own term named exit-condition- plus the kind slug. This term does not freeze one product's sentences, function names, or host paths.

**Human daily-life explanation:** A well-known exit condition is a reason the visit is over. Either something required went wrong and the host says so as you leave, or you are finished and the door closes quietly. Walking out of a side room only puts you back in the front room. That is not the end of the visit.

**Daily-life example:** You order a meal and the kitchen has no pot it must use. They stop and tell you why. If you say goodbye at the front door, the visit ends with no alarm. A missing spare napkin is not this term. That miss is a well-known don't-exit condition.

### Well-known don't-exit condition

**Definition:** A well-known don't-exit condition is one row of a closed catalog of misses that look like a stop and must not end the process. The program warns or reprints, names the miss, and continues the work the operator asked for. A check the operator named as the job still ends the process and is a well-known exit condition: a refused path, a missing required name, and a required side command that was started and exited non-zero. Do not ask for a password to hide a missing grant. Each continue kind is its own term named no-exit-condition- plus the kind slug.

**Human daily-life explanation:** A well-known don't-exit condition is a miss that looks like a reason to close, while the visit continues. The host names the miss and still brings the thing you asked for.

**Daily-life example:** The coat check is closed. They say so and still serve the meal. If you call a dish number that is not on the board, they show the board again. If the stove they already lit then fails, that is a well-known exit condition. If you say goodbye at the front door, that is also an exit, not this term.

### Exit condition: already desired state

**Definition:** exit-condition-already-desired-state is the well-known exit condition in which the file is already installed, already current, or already absent, and the command defines that as success. The process ends with status 0 and no fatal line. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-already-desired-state means the thing you asked for is already the way you wanted, so nothing changes.

**Daily-life example:** You ask for the tool to be put on its hook and it is already hanging there. The visit ends quietly.

### Exit condition: digest mismatch

**Definition:** exit-condition-digest-mismatch is the well-known exit condition in which a declared checksum, or a companion digest that was fetched, does not match the bytes. The process ends with a fatal message and a status other than 0. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-digest-mismatch means the seal number on the jar does not match the wax on the lid.

**Daily-life example:** The downloaded file’s hash is not the hash that was promised. The host stops.

### Exit condition: direct fetch or channel failed

**Definition:** exit-condition-direct-fetch-or-channel-failed is the well-known exit condition in which, on a direct command, the remote version is unreadable, the download failed, the fetch tool is missing, a downgrade is refused, or a temp file or channel place failed. On that direct command the process ends with a fatal message and a status other than 0. From a menu, these stay up unless the product uses the fatal-exit helper. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-direct-fetch-or-channel-failed means you asked directly for the remote copy and the fetch, the tools, or the place-down failed.

**Daily-life example:** You ask for the newer copy and the road to the warehouse is closed. The host says so and the visit ends.

### Exit condition: empty argv place succeeded

**Definition:** exit-condition-empty-argv-place-succeeded is the well-known exit condition in which non-interactive empty argv placed the program. The process ends with status 0 and no fatal line. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-empty-argv-place-succeeded means you start the program with no extra words, nobody is at the keyboard, and the place-down works.

**Daily-life example:** A script starts the program with no extra words and the tool lands on its hook.

### Exit condition: flag missing value

**Definition:** exit-condition-flag-missing-value is the well-known exit condition in which a flag that needs a value has none. The process ends with a fatal message and a status other than 0. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-flag-missing-value means you said with and did not say with what.

**Daily-life example:** You pass `--purpose` and do not pass the text. The host stops.

### Exit condition: front menu leave

**Definition:** exit-condition-front-menu-leave is the well-known exit condition in which the front menu receives the leave controls this product lists (`9`, `99`, `999`, `exit`, an empty line, or end of input). The process ends with status 0 and no fatal line. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-front-menu-leave means you say goodbye at the front door, you say nothing, or you walk away from the front board.

**Daily-life example:** You choose 9 on the front board. The visit ends with no alarm.

### Exit condition: install place failed

**Definition:** exit-condition-install-place-failed is the well-known exit condition in which the install directory cannot be created or written, or stage, mode, move, or the readable-and-executable heal failed. The process ends with a fatal message and a status other than 0. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-install-place-failed means the tool will not sit on its hook: the hook cannot be made, the tool will not move onto it, or it is not both readable and runnable afterward.

**Daily-life example:** The shelf cannot be built, so the tool is not put away. The host stops.

### Exit condition: storage unusable

**Definition:** exit-condition-storage-unusable is the well-known exit condition in which persistence or cache cannot be created or is not writable, or persistence resolved to the install bin directory. The process ends with a fatal message and a status other than 0. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-storage-unusable means there is nowhere safe to put the notepad, or the only shelf offered is the shelf where the tools themselves live.

**Daily-life example:** Every scratch drawer is locked. The host stops before the job starts.

### Exit condition: uninstall unconfirmed

**Definition:** exit-condition-uninstall-unconfirmed is the well-known exit condition in which remove is asked when there is no terminal, or when machine output or quiet mode is on, and force is off. The process ends with a fatal message and a status other than 0. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-uninstall-unconfirmed means nobody is at the counter to say yes, so the host will not throw the tool away.

**Daily-life example:** A script asks to remove the tool and does not pass `--force`. The host refuses.

### Exit condition: unknown token

**Definition:** exit-condition-unknown-token is the well-known exit condition in which the token is not a known command or flag. The process ends with a fatal message and a status other than 0. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-unknown-token means you asked, on a direct order, for a dish the house does not serve.

**Daily-life example:** You type a word that is not on the command list. The host stops and points at help.

### Exit condition: verb finished

**Definition:** exit-condition-verb-finished is the well-known exit condition in which the command completed the work it was asked to do. The process ends with status 0 and no fatal line. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-verb-finished means the meal is on the table and the visit is over.

**Daily-life example:** You asked for status and the answer was printed. The visit ends quietly.

### Exit condition: started required command failed

**Definition:** exit-condition-started-required-command-failed is the well-known exit condition in which a required side command was started and exited non-zero. An optional tool that was never started is not this row. The process ends with a fatal message and a status other than 0. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-started-required-command-failed means the helper you already sent into the kitchen comes back and says the job failed.

**Daily-life example:** `pkg`, `ssh`, `scp`, `systemctl`, or `sudoer-cli` was started and came back failed. The host stops.

### Exit condition: required name missing

**Definition:** exit-condition-required-name-missing is the well-known exit condition in which a required name is still empty and no terminal picker will fill it. The process ends with a fatal message and a status other than 0. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-required-name-missing means you cannot hand in a blank order when nobody is standing there to point at the board.

**Daily-life example:** `ssh` or `dns show` is asked with no Host and no terminal walk. The host stops.

### Exit condition: path not found

**Definition:** exit-condition-path-not-found is the well-known exit condition in which a named path does not resolve to a folder or file the command can use. The process ends with a fatal message and a status other than 0. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-path-not-found means you named a room and that room is not in the building.

**Daily-life example:** You name a Host that is not in this login’s SSH config. The host stops.

### Exit condition: dest not directory

**Definition:** exit-condition-dest-not-directory is the well-known exit condition in which the destination path is not a directory. The process ends with a fatal message and a status other than 0. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-dest-not-directory means you asked to set the table on a single spoon instead of in a room.

**Daily-life example:** `upload` is given a path that is not a folder. The host stops.

### Exit condition: extra argument

**Definition:** exit-condition-extra-argument is the well-known exit condition in which the command already has its operands and another token remains. The process ends with a fatal message and a status other than 0. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** exit-condition-extra-argument means the order already has both names and you added another word.

**Daily-life example:** `rc-test` or `fix-config` is given a flag it does not know. The host stops.

### No-exit condition: bad menu choice

**Definition:** no-exit-condition-bad-menu-choice is the well-known don't-exit condition in which the pick is not on this list. Print the loud line, reprint this layer, and read again. The process stays up. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** no-exit-condition-bad-menu-choice means you call a number that is not on this board, and the host shows the board again.

**Daily-life example:** You say 3 and the board has 1, 2, and 9. The process stays up.

### No-exit condition: menu nonfatal return

**Definition:** no-exit-condition-menu-nonfatal-return is the well-known don't-exit condition in which a non-zero return while a menu is still the caller, and the call is not the fatal-exit helper. The menu stays up. The process stays up. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** no-exit-condition-menu-nonfatal-return means a side errand from the front desk comes back unhappy, and you are still at the desk.

**Daily-life example:** A failure that would end a direct command comes back to the menu without the fatal helper. The menu stays.

### No-exit condition: normal-user-only elevation

**Definition:** no-exit-condition-normal-user-only-elevation is the well-known don't-exit condition in which the elevation wrapper returns without sudo and without the fatal exit. The process stays up. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** no-exit-condition-normal-user-only-elevation means this counter has no manager's bell. The wrapper comes back without calling one and without throwing you out.

**Daily-life example:** `sudo` is not installed, so `util_sudo` returns. That return is not itself a process exit. On Termux, Git Bash, and Windows cmd, `backup-config` stops earlier with its own fatal row and does not call the wrapper.

### No-exit condition: optional digest absent

**Definition:** no-exit-condition-optional-digest-absent is the well-known don't-exit condition in which the companion digest is missing. Warn and continue the install. The process stays up. A digest that was fetched and does not match is exit-condition-digest-mismatch, not this row. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** no-exit-condition-optional-digest-absent means the seal slip was never in the envelope. The host says so and still accepts the jar.

**Daily-life example:** The companion checksum file is missing. The install continues after a warning.

### No-exit condition: submenu leave

**Definition:** no-exit-condition-submenu-leave is the well-known don't-exit condition in which exit, quit, an empty line, or end of input on a nested layer returns to the parent only. The process stays up. It is one row of that catalog, not the whole catalog.

**Human daily-life explanation:** no-exit-condition-submenu-leave means you leave the side room and you are back at the front board.

**Daily-life example:** You choose Exit on a nested list. The process is still running on the parent list.

## 6. Status history

| Date | Status | Notes |
|------|--------|-------|
| 2026-10-10 | Active 1.0.0 | Exit catalog from `out_die` and the direct-command `return 1` messages in `src/sshd-cli`. Shape referenced from sibling tmpl-to-prj. Rows are this ship unit |
| 2026-10-14 | Active 1.0.1 | EX-DIE-25 is the POSIX Linux missing-sshd hint. EX-DIE-197 Git Bash, EX-DIE-198 Windows cmd, EX-DIE-199 macOS. The program does not run `apt` or `dnf` |

**Last Updated**: 2026-10-14 (1.0.1 missing-sshd next step by family. 2026-10-10)  
**Owner**: project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
