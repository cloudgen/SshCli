# =============================================================================
# tests/test_config_backup.sh — backup-config / sync-config / sudoers (local)
# =============================================================================
# Primary REQs: requirement-sshd-config-backup, requirement-sudoer-json-file,
# requirement-shell-sudo-command, requirement-domain-sshd
# TP family: TP-CFG-*
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_config_backup() {
    t_header "SSH config deposit (TP-CFG)"

    require_cmd sh
    require_cmd grep

    # TP-CFG-01 Type 0 backup-config into SSHD_CLI_ROOT (no sudo)
    ci_isolated_env
    mkdir -p "${CI_HOME}/.ssh"
    printf 'Host cfghost\n  HostName example.test\n' > "${CI_HOME}/.ssh/config"
    chmod 600 "${CI_HOME}/.ssh/config"
    _store=$(mktemp -d "${TMPDIR:-/tmp}/sshd-store.XXXXXX")
    _out=$(HOME="${CI_HOME}" SSHD_CLI_ROOT="${_store}" sh "${SCRIPT}" backup-config 2>&1)
    _ec=$?
    assert_eq "TP-CFG-01 backup-config exit 0" 0 "$_ec"
    assert_file_exists "TP-CFG-01 store config exists" "${_store}/config"
    assert_contains "TP-CFG-01 backup-config complete" "$_out" "backup-config complete"
    ci_cleanup_env

    # TP-CFG-02 sync-config writes ~/.ssh/config mode 600
    ci_isolated_env
    mkdir -p "${_store}"
    printf 'Host synchost\n  HostName example.test\n' > "${_store}/config"
    chmod 644 "${_store}/config"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_ROOT="${_store}" sh "${SCRIPT}" sync-config 2>&1)
    _ec=$?
    assert_eq "TP-CFG-02 sync-config exit 0" 0 "$_ec"
    assert_file_exists "TP-CFG-02 dest config exists" "${CI_HOME}/.ssh/config"
    assert_contains "TP-CFG-02 sync-config complete" "$_out" "sync-config complete"
    _mode=$(stat -c '%a' "${CI_HOME}/.ssh/config" 2>/dev/null || stat -f '%OLp' "${CI_HOME}/.ssh/config")
    assert_eq "TP-CFG-02 dest mode 600" "600" "${_mode}"
    ci_cleanup_env

    # TP-CFG-03 missing source fail-closed + Next
    ci_isolated_env
    _err=$(HOME="${CI_HOME}" SSHD_CLI_ROOT="${_store}" sh "${SCRIPT}" backup-config 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-03 missing source exit 1" 1 "$_ec"
    assert_contains "TP-CFG-03 missing source Next" "$_err" "Next:"
    ci_cleanup_env

    # TP-CFG-04 Termux: backup-config fail-closed; INFO on menu
    ci_isolated_env
    _err=$(HOME="${CI_HOME}" TERMUX_VERSION=1 sh "${SCRIPT}" backup-config 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-04 Termux backup-config exit 1" 1 "$_ec"
    assert_contains "TP-CFG-04 Termux not available" "$_err" "not available for termux"
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 TERMUX_VERSION=1 sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CFG-04 Termux menu INFO" "$_out" "backup-config and sync-config not available for termux"
    assert_contains "TP-CFG-04 Termux front sudoers INFO" "$_out" "sudoers not available for termux"
    assert_not_contains "TP-CFG-04 Termux omits sudoers row" "$_out" "5. "
    assert_not_contains "TP-CFG-04 Termux no backup-config row 15" "$_out" "15."
    assert_contains "TP-CFG-04 Termux ssh row 12" "$_out" "12."
    assert_contains "TP-CFG-04 Termux sync-from-remote row 18" "$_out" "18."
    ci_cleanup_env

    # TP-CFG-05 Git Bash menu INFO
    ci_isolated_env
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 MSYSTEM=MINGW64 env -u TERMUX_VERSION sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CFG-05 Git Bash menu INFO" "$_out" "backup-config and sync-config not available for gitbash"
    assert_contains "TP-CFG-05 Git Bash front sudoers INFO" "$_out" "sudoers not available for gitbash"
    assert_not_contains "TP-CFG-05 Git Bash omits sudoers row" "$_out" "5. "
    assert_not_contains "TP-CFG-05 Git Bash no backup-config row 15" "$_out" "15."
    assert_contains "TP-CFG-05 Git Bash ssh row 12" "$_out" "12."
    assert_contains "TP-CFG-05 Git Bash sync-from-remote row 18" "$_out" "18."
    _err=$(HOME="${CI_HOME}" MSYSTEM=MINGW64 env -u TERMUX_VERSION sh "${SCRIPT}" sync-config 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-05 Git Bash sync-config exit 1" 1 "$_ec"
    ci_cleanup_env

    # TP-CFG-06 print-sudoers --allow-test-local names backup-config only
    ci_isolated_env
    _draft="${CI_HOME}/sudoers.fragment"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" --allow-test-local print-sudoers "${_draft}" 2>&1)
    _ec=$?
    assert_eq "TP-CFG-06 print-sudoers test-local exit 0" 0 "$_ec"
    assert_file_exists "TP-CFG-06 fragment written" "${_draft}"
    assert_contains "TP-CFG-06 fragment backup-config" "$(cat "${_draft}")" "backup-config"
    assert_not_contains "TP-CFG-06 no /bin/cp" "$(cat "${_draft}")" "/bin/cp"
    assert_not_contains "TP-CFG-06 no /bin/chmod" "$(cat "${_draft}")" "/bin/chmod"
    ci_cleanup_env

    # TP-CFG-07 generate-sudoer-request JSON grant
    ci_isolated_env
    _jsonf="${CI_HOME}/grant.json"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" --allow-test-local generate-sudoer-request "${_jsonf}" 2>&1)
    _ec=$?
    assert_eq "TP-CFG-07 generate-sudoer-request exit 0" 0 "$_ec"
    assert_file_exists "TP-CFG-07 json written" "${_jsonf}"
    assert_contains "TP-CFG-07 json backup-config" "$(cat "${_jsonf}")" '"backup-config"'
    assert_contains "TP-CFG-07 json service" "$(cat "${_jsonf}")" "\"service\":\"${APP_NAME}\""
    ci_cleanup_env

    # TP-CFG-08 restore-config is not a verb
    _err=$(sh "${SCRIPT}" restore-config 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CFG-08 restore-config exit 1" 1 "$_ec"
    assert_contains "TP-CFG-08 restore-config unknown" "$_err" "Unknown command"

    # TP-CFG-09 Windows cmd menu INFO
    ci_isolated_env
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 OS=Windows_NT COMSPEC='C:\\Windows\\system32\\cmd.exe' env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CFG-09 Windows cmd menu INFO" "$_out" "backup-config and sync-config not available for windows-cmd"
    assert_contains "TP-CFG-09 Windows cmd front sudoers INFO" "$_out" "sudoers not available for windows-cmd"
    assert_not_contains "TP-CFG-09 Windows cmd omits sudoers row" "$_out" "5. "
    assert_contains "TP-CFG-09 Windows cmd ssh row 12" "$_out" "12."
    assert_contains "TP-CFG-09 Windows cmd sync-from-remote row 18" "$_out" "18."
    ci_cleanup_env

    # TP-CFG-10..15 sync-from-remote (fake scp; never a real SSH session)
    ci_isolated_env
    mkdir -p "${CI_HOME}/bin" "${CI_HOME}/remote-store"
    printf 'Host remotehost\n  HostName example.test\n' > "${CI_HOME}/remote-store/config"
    _fake_scp="${CI_HOME}/bin/scp"
    _scp_log="${CI_HOME}/scp.log"
    : > "${_scp_log}"
    cat > "${_fake_scp}" <<'FAKESCP'
#!/bin/sh
fix="${SSHD_CLI_REMOTE_FIXTURE:-}"
log="${SSHD_CLI_SCP_LOG:-}"
while [ $# -gt 0 ]; do
    case "$1" in
        -o) shift 2; continue ;;
        -*) shift; continue ;;
        *) break ;;
    esac
done
src="${1:-}"
dest="${2:-}"
[ -n "${src}" ] && [ -n "${dest}" ] || exit 1
if [ -n "${log}" ]; then
    printf '%s\n' "${src}" >> "${log}"
fi
base="${src##*:}"
base="${base##*/}"
if [ -z "${fix}" ] || [ ! -f "${fix}/${base}" ]; then
    exit 1
fi
cp "${fix}/${base}" "${dest}" || exit 1
exit 0
FAKESCP
    chmod 0755 "${_fake_scp}"

    _err=$(HOME="${CI_HOME}" SSHD_CLI_SCP="${_fake_scp}" SSHD_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        sh "${SCRIPT}" sync-from-remote 2>&1 >/dev/null)
    assert_eq "TP-CFG-10 missing spec exit 1" 1 "$?"
    assert_contains "TP-CFG-10 Next USER@HOST" "${_err}" "sync-from-remote USER@HOST"

    _err=$(HOME="${CI_HOME}" SSHD_CLI_SCP="${_fake_scp}" SSHD_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        sh "${SCRIPT}" sync-from-remote 'bad;rm' 2>&1 >/dev/null)
    assert_eq "TP-CFG-11 invalid spec exit 1" 1 "$?"
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SCP="${_fake_scp}" SSHD_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        sh "${SCRIPT}" sync-from-remote 'a@b@c' 2>&1 >/dev/null)
    assert_eq "TP-CFG-11 extra @ exit 1" 1 "$?"

    : > "${_scp_log}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_SCP="${_fake_scp}" SSHD_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        SSHD_CLI_SCP_LOG="${_scp_log}" SSHD_CLI_REMOTE_ROOT="/var/sshd-cli" \
        sh "${SCRIPT}" sync-from-remote operator@host.example.test 2>/dev/null)
    assert_eq "TP-CFG-12 user@host exit 0" 0 "$?"
    assert_contains "TP-CFG-12 complete" "${_out}" "sync-from-remote complete"
    assert_file_exists "TP-CFG-12 dest config" "${CI_HOME}/.ssh/config"
    assert_contains "TP-CFG-12 scp src" "$(cat "${_scp_log}")" "operator@host.example.test:/var/sshd-cli/config"
    _mode=$(stat -c '%a' "${CI_HOME}/.ssh/config" 2>/dev/null || stat -f '%OLp' "${CI_HOME}/.ssh/config")
    assert_eq "TP-CFG-13 dest mode 600" "600" "${_mode}"

    _pref="${CI_HOME}/.local/sshd-cli/preferred-remote"
    assert_file_exists "TP-CFG-14 preferred-remote leaf" "${_pref}"
    assert_eq "TP-CFG-14 stored SPEC" "operator@host.example.test" "$(tr -d '\r\n' < "${_pref}")"
    _pmode=$(stat -c '%a' "${_pref}" 2>/dev/null || stat -f '%OLp' "${_pref}")
    assert_eq "TP-CFG-14 preferred-remote mode 600" "600" "${_pmode}"

    rm -f "${CI_HOME}/.ssh/config"
    : > "${_scp_log}"
    _out=$(printf '\n' | HOME="${CI_HOME}" SSHD_CLI_SCP="${_fake_scp}" SSHD_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        SSHD_CLI_SCP_LOG="${_scp_log}" SSHD_CLI_REMOTE_ROOT="/var/sshd-cli" \
        TTY=1 INTERACTIVE=1 sh "${SCRIPT}" sync-from-remote 2>/dev/null)
    assert_eq "TP-CFG-15 TTY empty uses stored default exit 0" 0 "$?"
    assert_contains "TP-CFG-15 reused stored SPEC in scp" "$(cat "${_scp_log}")" "operator@host.example.test:/var/sshd-cli/config"
    assert_file_exists "TP-CFG-15 dest config from default" "${CI_HOME}/.ssh/config"

    _j=$(HOME="${CI_HOME}" SSHD_CLI_SCP="${_fake_scp}" SSHD_CLI_REMOTE_FIXTURE="${CI_HOME}/remote-store" \
        SSHD_CLI_REMOTE_ROOT="/var/sshd-cli" \
        sh "${SCRIPT}" --json sync-from-remote host.example.test 2>/dev/null)
    assert_contains "TP-CFG-16 json type" "${_j}" '"type":"sync-from-remote"'
    assert_contains "TP-CFG-16 json host" "${_j}" '"host":"host.example.test"'

    # TP-CFG-17 TTY sudoers submenu unknown choice redisplays (front 5; verbs 51-55)
    _out=$(printf '%s\n' '5' '88' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CFG-17 sudoers unknown then Back then Exit 9 exit 0" 0 "$_ec"
    assert_contains "TP-CFG-17 unknown sudoers named" "${_out}" "Unknown sudoers choice '88'"
    _n=$(t_count_substr "${_out}" "sudoers (grant and drafts)")
    assert_eq "TP-CFG-17 redisplays sudoers menu" "2" "$_n"
    _n=$(printf '%s\n' "${_out}" | grep -cE '(^|[^0-9])51[.]' || true)
    assert_eq "TP-CFG-17 prints verb 51" "2" "${_n}"
    _n=$(printf '%s\n' "${_out}" | grep -cE '(^|[^0-9])55[.]' || true)
    assert_eq "TP-CFG-17 prints verb 55" "2" "${_n}"
    _n=$(printf '%s\n' "${_out}" | grep -cE '(^|[^0-9])151[.]' || true)
    assert_eq "TP-CFG-17 does not print 171" "0" "${_n}"
    _out=$(printf '%s\n' '1' '17' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CFG-17 client 17 is not sudoers exit 0" 0 "$_ec"
    assert_contains "TP-CFG-17 client 17 unknown" "${_out}" "Unknown menu choice '17'"
    assert_not_contains "TP-CFG-17 client 17 did not open sudoers" "${_out}" "sudoers (grant and drafts)"

    ci_cleanup_env

    if [ -n "${_store:-}" ] && [ -d "${_store}" ]; then
        rm -rf "${_store}"
    fi
    unset _store _out _ec _err _mode _draft _jsonf _fake_scp _scp_log _pref _pmode _j _n
}
