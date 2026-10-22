# =============================================================================
# tests/test_ssh_download.sh — ssh Host pick + download remote folder
# =============================================================================
# Primary REQs: requirement-domain-sshd, requirement-shell-cli-interface,
# requirement-shell-interactive-vs-noninteractive
# TP families: TP-SSH-*, TP-DL-*, TP-UL-*
# Host names are minted per run (synthetic-test-fixture).
# Fake OpenSSH client via SSHD_CLI_SSH (no real SSH session).
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

_ssh_dl_mint() {
    H_SSH=$(t_rand_host)
    H_DL=$(t_rand_host)
    H_TILDE=$(t_rand_host)
    IP_SSH=$(t_rand_ip)
    IP_DL=$(t_rand_ip)
    IP_TILDE=$(t_rand_ip)
}

_ssh_dl_fixture() {
    mkdir -p "${CI_HOME}/.ssh"
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_SSH}
    HostName ${IP_SSH}
    User u1

Host ${H_DL}
    HostName ${IP_DL}

Host ${H_TILDE}
    HostName ${IP_TILDE}

Host *
    StrictHostKeyChecking accept-new
EOF
    chmod 700 "${CI_HOME}/.ssh"
    chmod 600 "${CI_HOME}/.ssh/config"
}

_ssh_dl_fake() {
    mkdir -p "${CI_HOME}/bin"
    _fake_ssh="${CI_HOME}/bin/ssh"
    cat > "${_fake_ssh}" <<'FAKESSH'
#!/bin/sh
log="${SSHD_CLI_SSH_LOG:-}"
if [ -n "${log}" ]; then
    printf '%s\n' "$*" >> "${log}"
fi
_in="${SSHD_CLI_SSH_STDIN:-}"
if [ -n "${_in}" ]; then
    cat > "${_in}"
else
    cat >/dev/null
fi
fix="${SSHD_CLI_TAR_FIXTURE:-}"
base="${SSHD_CLI_TAR_BASE:-}"
if [ -n "${fix}" ] && [ -d "${fix}" ]; then
    if [ -z "${base}" ]; then
        base=$(basename "${fix}")
    fi
    tmp=$(mktemp -d "${TMPDIR:-/tmp}/fake-ssh-tar.XXXXXX") || exit 1
    mkdir -p "${tmp}/${base}"
    (cd "${fix}" && tar cf - .) | (cd "${tmp}/${base}" && tar xf -)
    tar czf - -C "${tmp}" "${base}"
    rm -rf "${tmp}"
    exit 0
fi
exit 0
FAKESSH
    chmod 0755 "${_fake_ssh}"
}

run_test_ssh_download() {
    t_header "ssh Host pick + download/upload folder (TP-SSH / TP-DL / TP-UL)"

    require_cmd sh
    require_cmd tar
    require_cmd awk

    ci_isolated_env
    _ssh_dl_mint
    _ssh_dl_fixture
    _ssh_dl_fake
    _ssh_log="${CI_HOME}/ssh.log"
    : > "${_ssh_log}"

    # TP-SSH-01 help lists ssh
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" help 2>&1)
    assert_contains "TP-SSH-01 help lists ssh" "$_out" "ssh ["
    assert_contains "TP-SSH-01 help lists download" "$_out" "download ["

    # TP-SSH-02 non-interactive ssh by name uses Host alias
    : > "${_ssh_log}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
        sh "${SCRIPT}" ssh "${H_SSH}" 2>&1)
    _ec=$?
    assert_eq "TP-SSH-02 ssh by name exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-SSH-02 log has alias" "$_log" "${H_SSH}"
    assert_not_contains "TP-SSH-02 log has no HostName" "$_log" "${IP_SSH}"
    assert_not_contains "TP-SSH-02 no legacy HostKeyAlgorithms" "$_log" "HostKeyAlgorithms"

    # TP-SSH-03 ssh by number
    : > "${_ssh_log}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
        sh "${SCRIPT}" ssh 1 2>&1)
    _ec=$?
    assert_eq "TP-SSH-03 ssh by number exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-SSH-03 log first host" "$_log" "${H_SSH}"

    # TP-SSH-04 missing operand fail-closed
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" ssh 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-SSH-04 missing n exit 1" 1 "$_ec"
    assert_contains "TP-SSH-04 Next dns list" "$_err" "dns list"

    # TP-SSH-05 unknown host fail-closed
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" ssh no-such-host 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-SSH-05 unknown host exit 1" 1 "$_ec"
    assert_contains "TP-SSH-05 Next dns list" "$_err" "dns list"

    # TP-SSH-06 JSON does not start a session
    : > "${_ssh_log}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
        sh "${SCRIPT}" --json ssh "${H_SSH}" 2>/dev/null)
    _ec=$?
    assert_eq "TP-SSH-06 json ssh exit 0" 0 "$_ec"
    assert_contains "TP-SSH-06 json type" "$_out" '"type":"ssh"'
    assert_contains "TP-SSH-06 json dns" "$_out" "\"dns\":\"${H_SSH}\""
    _log=$(cat "${_ssh_log}")
    assert_eq "TP-SSH-06 json did not invoke ssh" "" "${_log}"

    # TP-SSH-07 TTY pick 1
    : > "${_ssh_log}"
    _out=$(HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
        sh "${SCRIPT}" ssh <<'EOF'
1
EOF
)
    _ec=$?
    assert_eq "TP-SSH-07 tty pick exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-SSH-07 tty picked first alias" "$_log" "${H_SSH}"
    assert_contains "TP-SSH-07 tty default user -l" "$_log" "-l u1"

    # TP-SSH-08 TTY user override
    : > "${_ssh_log}"
    _out=$(HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
        sh "${SCRIPT}" ssh <<'EOF'
1
otheruser
EOF
)
    _ec=$?
    assert_eq "TP-SSH-08 tty user override exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-SSH-08 log -l otheruser" "$_log" "-l otheruser"
    assert_contains "TP-SSH-08 log alias" "$_log" "${H_SSH}"

    # TP-SSH-10 commented algorithm lines → -o HostKeyAlgorithms=+ssh-rsa
    _out=$(HOME="${CI_HOME}" TERMUX_VERSION=1 sh "${SCRIPT}" dns set "${H_SSH}" old-openssh yes 2>&1)
    _ec=$?
    assert_eq "TP-SSH-10 termux comment write exit 0" 0 "$_ec"
    : > "${_ssh_log}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
        sh "${SCRIPT}" ssh "${H_SSH}" 2>&1)
    _ec=$?
    assert_eq "TP-SSH-10 ssh with comment exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-SSH-10 passes HostKeyAlgorithms=+ssh-rsa" "${_log}" "HostKeyAlgorithms=+ssh-rsa"
    assert_contains "TP-SSH-10 still uses alias" "${_log}" "${H_SSH}"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" --json ssh "${H_SSH}" 2>/dev/null)
    assert_contains "TP-SSH-10 json command has -o" "${_out}" "HostKeyAlgorithms=+ssh-rsa"

    # TP-SSH-09 TTY menu numbers ssh / download
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 TERMUX_VERSION=1 \
        sh "${SCRIPT}" 2>&1)
    assert_contains "TP-SSH-09 Termux menu ssh row 12" "$_out" "12."
    assert_contains "TP-SSH-09 Termux menu download row 13" "$_out" "13."
    assert_contains "TP-SSH-09 Termux menu user prompt not on main" "$_out" "Choose a number"

    # TP-DL-01 help lists download (also TP-SSH-01)
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" help 2>&1)
    assert_contains "TP-DL-01 help download operand" "$_out" "download [N|name]"
    assert_contains "TP-DL-01 help download user then folder" "$_out" "then user with default, then numbered previous folders"
    assert_contains "TP-DL-01 help tilde folder" "$_out" "~/folder"

    _fix="${CI_HOME}/remote-box"
    mkdir -p "${_fix}"
    printf 'ok\n' > "${_fix}/ok.txt"
    _wd=$(mktemp -d "${TMPDIR:-/tmp}/dl-wd.XXXXXX")

    # TP-DL-02 non-interactive download extracts in cwd
    _out=$(
        cd "${_wd}" || exit 1
        HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_TAR_FIXTURE="${_fix}" SSHD_CLI_TAR_BASE="app" \
            sh "${SCRIPT}" download "${H_DL}" /opt/app 2>&1
    )
    _ec=$?
    assert_eq "TP-DL-02 download exit 0" 0 "$_ec"
    assert_file_exists "TP-DL-02 extracted marker" "${_wd}/app/ok.txt"
    assert_contains "TP-DL-02 success names host" "$_out" "${H_DL}"

    # TP-DL-03 remembers folder for that dns
    _mem="${CI_HOME}/.local/sshd-cli/download-folders"
    assert_file_exists "TP-DL-03 memory file" "${_mem}"
    _mc=$(cat "${_mem}")
    assert_contains "TP-DL-03 memory dns" "$_mc" "${H_DL}"
    assert_contains "TP-DL-03 memory path" "$_mc" "/opt/app"

    # TP-DL-04 TTY numbered previous folder (empty user keeps default)
    _wd2=$(mktemp -d "${TMPDIR:-/tmp}/dl-wd2.XXXXXX")
    : > "${_ssh_log}"
    _out=$(
        cd "${_wd2}" || exit 1
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_TAR_FIXTURE="${_fix}" SSHD_CLI_TAR_BASE="app" \
            sh "${SCRIPT}" download "${H_DL}" <<'EOF'

1
EOF
    )
    _ec=$?
    assert_eq "TP-DL-04 tty previous exit 0" 0 "$_ec"
    assert_contains "TP-DL-04 lists previous path" "$_out" "/opt/app"
    assert_file_exists "TP-DL-04 extracted from previous" "${_wd2}/app/ok.txt"

    # TP-DL-05 TTY type a new folder path (non-number; empty user keeps default)
    _wd3=$(mktemp -d "${TMPDIR:-/tmp}/dl-wd3.XXXXXX")
    _out=$(
        cd "${_wd3}" || exit 1
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_TAR_FIXTURE="${_fix}" SSHD_CLI_TAR_BASE="other" \
            sh "${SCRIPT}" download "${H_DL}" <<'EOF'

/var/data/other
EOF
    )
    _ec=$?
    assert_eq "TP-DL-05 tty new path exit 0" 0 "$_ec"
    assert_file_exists "TP-DL-05 extracted other" "${_wd3}/other/ok.txt"
    _mc=$(cat "${_mem}")
    assert_contains "TP-DL-05 memory new path" "$_mc" "/var/data/other"

    # TP-DL-06 missing folder fail-closed
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" download "${H_DL}" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DL-06 missing folder exit 1" 1 "$_ec"
    assert_contains "TP-DL-06 Next folder" "$_err" "download"

    # TP-DL-07 refuse shell metacharacters
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" download "${H_DL}" '/opt/app;rm' 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DL-07 bad folder exit 1" 1 "$_ec"
    assert_contains "TP-DL-07 not allowed" "$_err" "not allowed"

    # TP-DL-08 JSON download one object
    _wd4=$(mktemp -d "${TMPDIR:-/tmp}/dl-wd4.XXXXXX")
    _out=$(
        cd "${_wd4}" || exit 1
        HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_TAR_FIXTURE="${_fix}" SSHD_CLI_TAR_BASE="app" \
            sh "${SCRIPT}" --json download "${H_DL}" /opt/app 2>/dev/null
    )
    _ec=$?
    assert_eq "TP-DL-08 json download exit 0" 0 "$_ec"
    assert_contains "TP-DL-08 json type" "$_out" '"type":"download"'
    assert_contains "TP-DL-08 json dns" "$_out" "\"dns\":\"${H_DL}\""
    assert_contains "TP-DL-08 json folder" "$_out" '"folder":"/opt/app"'
    assert_contains "TP-DL-08 json user key" "$_out" '"user":'
    assert_file_exists "TP-DL-08 json extracted" "${_wd4}/app/ok.txt"

    # TP-DL-09 Host * is not a download/ssh row
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" ssh '*' 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DL-09 wildcard ssh exit 1" 1 "$_ec"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns list 2>&1)
    assert_not_contains "TP-DL-09 list has no asterisk row" "$_out" "*  "

    # TP-DL-10 TTY download default user uses Host User (-l u1)
    _wd5=$(mktemp -d "${TMPDIR:-/tmp}/dl-wd5.XXXXXX")
    : > "${_ssh_log}"
    _out=$(
        cd "${_wd5}" || exit 1
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_TAR_FIXTURE="${_fix}" SSHD_CLI_TAR_BASE="app" \
            sh "${SCRIPT}" download "${H_SSH}" /opt/app <<'EOF'

EOF
    )
    _ec=$?
    assert_eq "TP-DL-10 tty default user exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-DL-10 log -l u1" "$_log" "-l u1"
    assert_contains "TP-DL-10 log alias" "$_log" "${H_SSH}"
    assert_file_exists "TP-DL-10 extracted" "${_wd5}/app/ok.txt"
    assert_contains "TP-DL-10 prompt user" "$_out" "user ["

    # TP-DL-11 TTY download user override
    _wd6=$(mktemp -d "${TMPDIR:-/tmp}/dl-wd6.XXXXXX")
    : > "${_ssh_log}"
    _out=$(
        cd "${_wd6}" || exit 1
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_TAR_FIXTURE="${_fix}" SSHD_CLI_TAR_BASE="app" \
            sh "${SCRIPT}" download "${H_SSH}" /opt/app <<'EOF'
otheruser
EOF
    )
    _ec=$?
    assert_eq "TP-DL-11 tty user override exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-DL-11 log -l otheruser" "$_log" "-l otheruser"
    assert_contains "TP-DL-11 log alias" "$_log" "${H_SSH}"
    assert_file_exists "TP-DL-11 extracted" "${_wd6}/app/ok.txt"

    # TP-DL-12 TTY invalid user fail-closed; Next names download
    _err=$(
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" \
            sh "${SCRIPT}" download "${H_SSH}" /opt/app 2>&1 >/dev/null <<'EOF'
bad!user
EOF
    )
    _ec=$?
    assert_eq "TP-DL-12 bad user exit 1" 1 "$_ec"
    assert_contains "TP-DL-12 not allowed" "$_err" "not allowed"
    assert_contains "TP-DL-12 Next download" "$_err" "download"

    # TP-DL-13 TTY "" omits -l
    _wd7=$(mktemp -d "${TMPDIR:-/tmp}/dl-wd7.XXXXXX")
    : > "${_ssh_log}"
    _out=$(
        cd "${_wd7}" || exit 1
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_TAR_FIXTURE="${_fix}" SSHD_CLI_TAR_BASE="app" \
            sh "${SCRIPT}" download "${H_SSH}" /opt/app <<'EOF'
""
EOF
    )
    _ec=$?
    assert_eq "TP-DL-13 empty user token exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_not_contains "TP-DL-13 log has no -l" "$_log" "-l "
    assert_contains "TP-DL-13 log alias" "$_log" "${H_SSH}"
    assert_file_exists "TP-DL-13 extracted" "${_wd7}/app/ok.txt"

    # TP-DL-14 ~/folder is allowed; remote command expands "$HOME" (not a quoted ~)
    _wd8=$(mktemp -d "${TMPDIR:-/tmp}/dl-wd8.XXXXXX")
    : > "${_ssh_log}"
    _out=$(
        cd "${_wd8}" || exit 1
        HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_TAR_FIXTURE="${_fix}" SSHD_CLI_TAR_BASE="app" \
            sh "${SCRIPT}" download "${H_DL}" '~/box/app' 2>&1
    )
    _ec=$?
    assert_eq "TP-DL-14 tilde folder exit 0" 0 "$_ec"
    assert_file_exists "TP-DL-14 extracted" "${_wd8}/app/ok.txt"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-DL-14 remote uses HOME" "$_log" '"$HOME"'
    assert_not_contains "TP-DL-14 remote not quoted tilde" "$_log" "'~/box/app'"
    assert_not_contains "TP-DL-14 remote not this-login HOME" "$_log" "${CI_HOME}"
    _mc=$(cat "${_mem}")
    assert_contains "TP-DL-14 memory tilde path" "$_mc" "~/box/app"

    # TP-DL-14 TTY walk (incident path): first-time prompt names ~/folder; read -r keeps ~
    _wd9=$(mktemp -d "${TMPDIR:-/tmp}/dl-wd9.XXXXXX")
    : > "${_ssh_log}"
    _out=$(
        cd "${_wd9}" || exit 1
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_TAR_FIXTURE="${_fix}" SSHD_CLI_TAR_BASE="app" \
            sh "${SCRIPT}" download "${H_TILDE}" <<'EOF'

~/box/app
EOF
    )
    _ec=$?
    assert_eq "TP-DL-14 tty tilde exit 0" 0 "$_ec"
    assert_contains "TP-DL-14 tty prompt names tilde" "$_out" "~/folder"
    assert_file_exists "TP-DL-14 tty extracted" "${_wd9}/app/ok.txt"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-DL-14 tty remote uses HOME" "$_log" '"$HOME"'
    assert_not_contains "TP-DL-14 tty remote not quoted tilde" "$_log" "'~/box/app'"
    assert_not_contains "TP-DL-14 tty remote not this-login HOME" "$_log" "${CI_HOME}"

    # TP-DL-15 ~ alone is still refused
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" download "${H_DL}" '~' 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DL-15 tilde-only exit 1" 1 "$_ec"
    assert_contains "TP-DL-15 not allowed" "$_err" "not allowed"
    assert_contains "TP-DL-15 Next download" "$_err" "download"

    # TP-DL-16 ~user/path is refused (only ~/folder is the home prefix)
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" download "${H_DL}" '~other/box' 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DL-16 tilde-user exit 1" 1 "$_ec"
    assert_contains "TP-DL-16 not allowed" "$_err" "not allowed"
    assert_contains "TP-DL-16 Next download" "$_err" "download"

    # TP-DL-17 TTY out-of-range folder number warns and redisplays; then pick 1
    _wd10=$(mktemp -d "${TMPDIR:-/tmp}/dl-wd10.XXXXXX")
    : > "${_ssh_log}"
    _out=$(
        cd "${_wd10}" || exit 1
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_TAR_FIXTURE="${_fix}" SSHD_CLI_TAR_BASE="app" \
            sh "${SCRIPT}" download "${H_DL}" 2>&1 <<'EOF'

99
1
EOF
    )
    _ec=$?
    assert_eq "TP-DL-17 out-of-range then pick 1 exit 0" 0 "$_ec"
    assert_contains "TP-DL-17 unknown folder named" "$_out" "Unknown folder choice '99'"
    _n=$(t_count_substr "$_out" "Previous folders for")
    assert_eq "TP-DL-17 redisplays folder list" "2" "$_n"
    assert_file_exists "TP-DL-17 extracted after retry" "${_wd10}/app/ok.txt"

    # --- TP-UL local folder upload (inverse of download) ---
    _ul="${CI_HOME}/box/app"
    mkdir -p "${_ul}"
    printf 'up\n' > "${_ul}/ok.txt"
    _ul_stdin="${CI_HOME}/upload.stdin"
    _ul_mem="${CI_HOME}/.local/sshd-cli/upload-folders"

    # TP-UL-01 help lists upload
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" help 2>&1)
    assert_contains "TP-UL-01 help lists upload" "$_out" "upload [N|name]"
    assert_contains "TP-UL-01 help local folders" "$_out" "previous local folders"
    assert_contains "TP-UL-01 help tilde this login" "$_out" "~/folder is this login"

    # TP-UL-02 non-interactive upload streams tar; remote extracts under "$HOME"
    : > "${_ssh_log}"
    rm -f "${_ul_stdin}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
        SSHD_CLI_SSH_STDIN="${_ul_stdin}" \
        sh "${SCRIPT}" upload "${H_DL}" "${_ul}" 2>&1)
    _ec=$?
    assert_eq "TP-UL-02 upload exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-UL-02 remote tar xzf" "$_log" "tar xzf - -C"
    assert_contains "TP-UL-02 remote uses HOME" "$_log" '"$HOME"'
    assert_not_contains "TP-UL-02 remote not this-login HOME" "$_log" "${CI_HOME}"
    assert_file_exists "TP-UL-02 stdin archive" "${_ul_stdin}"
    if tar tzf "${_ul_stdin}" 2>/dev/null | grep -q 'ok.txt'; then
        t_pass "TP-UL-02 stdin is tar with ok.txt"
    else
        t_fail "TP-UL-02 stdin is tar with ok.txt"
    fi

    # TP-UL-03 remembers local folder for that Host
    assert_file_exists "TP-UL-03 memory file" "${_ul_mem}"
    _mc=$(cat "${_ul_mem}")
    assert_contains "TP-UL-03 memory dns" "$_mc" "${H_DL}"
    assert_contains "TP-UL-03 memory path" "$_mc" "${_ul}"

    # TP-UL-04 TTY numbered previous local folder
    : > "${_ssh_log}"
    _out=$(
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_SSH_STDIN="${_ul_stdin}" \
            sh "${SCRIPT}" upload "${H_DL}" <<'EOF'

1
EOF
    )
    _ec=$?
    assert_eq "TP-UL-04 tty previous exit 0" 0 "$_ec"
    assert_contains "TP-UL-04 lists previous path" "$_out" "${_ul}"

    # TP-UL-05 TTY type a new local path
    _ul2="${CI_HOME}/box/other"
    mkdir -p "${_ul2}"
    printf 'up2\n' > "${_ul2}/ok.txt"
    : > "${_ssh_log}"
    _out=$(
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_SSH_STDIN="${_ul_stdin}" \
            sh "${SCRIPT}" upload "${H_DL}" <<EOF

${_ul2}
EOF
    )
    _ec=$?
    assert_eq "TP-UL-05 tty new path exit 0" 0 "$_ec"
    _mc=$(cat "${_ul_mem}")
    assert_contains "TP-UL-05 memory new path" "$_mc" "${_ul2}"

    # TP-UL-06 missing folder operand fail-closed
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" upload "${H_DL}" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-UL-06 missing folder exit 1" 1 "$_ec"
    assert_contains "TP-UL-06 Next upload" "$_err" "upload"

    # TP-UL-07 refuse shell metacharacters
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" upload "${H_DL}" '/opt/app;rm' 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-UL-07 bad folder exit 1" 1 "$_ec"
    assert_contains "TP-UL-07 not allowed" "$_err" "not allowed"

    # TP-UL-08 JSON upload one object
    : > "${_ssh_log}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
        SSHD_CLI_SSH_STDIN="${_ul_stdin}" \
        sh "${SCRIPT}" --json upload "${H_DL}" "${_ul}" 2>/dev/null)
    _ec=$?
    assert_eq "TP-UL-08 json upload exit 0" 0 "$_ec"
    assert_contains "TP-UL-08 json type" "$_out" '"type":"upload"'
    assert_contains "TP-UL-08 json dns" "$_out" "\"dns\":\"${H_DL}\""
    assert_contains "TP-UL-08 json folder" "$_out" "\"folder\":\"${_ul}\""
    assert_contains "TP-UL-08 json user key" "$_out" '"user":'
    assert_contains "TP-UL-08 json destination HOME" "$_out" '$HOME/'

    # TP-UL-09 Host * is not an upload row
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" upload '*' "${_ul}" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-UL-09 wildcard upload exit 1" 1 "$_ec"

    # TP-UL-10 TTY upload default user uses Host User (-l u1)
    : > "${_ssh_log}"
    _out=$(
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_SSH_STDIN="${_ul_stdin}" \
            sh "${SCRIPT}" upload "${H_SSH}" "${_ul}" <<'EOF'

EOF
    )
    _ec=$?
    assert_eq "TP-UL-10 tty default user exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-UL-10 log -l u1" "$_log" "-l u1"
    assert_contains "TP-UL-10 log alias" "$_log" "${H_SSH}"
    assert_contains "TP-UL-10 prompt user" "$_out" "user ["

    # TP-UL-11 TTY upload user override
    : > "${_ssh_log}"
    _out=$(
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_SSH_STDIN="${_ul_stdin}" \
            sh "${SCRIPT}" upload "${H_SSH}" "${_ul}" <<'EOF'
otheruser
EOF
    )
    _ec=$?
    assert_eq "TP-UL-11 tty user override exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-UL-11 log -l otheruser" "$_log" "-l otheruser"
    assert_contains "TP-UL-11 log alias" "$_log" "${H_SSH}"

    # TP-UL-12 TTY invalid user fail-closed; Next names upload
    _err=$(
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" \
            sh "${SCRIPT}" upload "${H_SSH}" "${_ul}" 2>&1 >/dev/null <<'EOF'
bad!user
EOF
    )
    _ec=$?
    assert_eq "TP-UL-12 bad user exit 1" 1 "$_ec"
    assert_contains "TP-UL-12 not allowed" "$_err" "not allowed"
    assert_contains "TP-UL-12 Next upload" "$_err" "upload"

    # TP-UL-13 TTY "" omits -l
    : > "${_ssh_log}"
    _out=$(
        HOME="${CI_HOME}" INTERACTIVE=1 SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
            SSHD_CLI_SSH_STDIN="${_ul_stdin}" \
            sh "${SCRIPT}" upload "${H_SSH}" "${_ul}" <<'EOF'
""
EOF
    )
    _ec=$?
    assert_eq "TP-UL-13 empty user token exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_not_contains "TP-UL-13 log has no -l" "$_log" "-l "
    assert_contains "TP-UL-13 log alias" "$_log" "${H_SSH}"

    # TP-UL-14 local ~/folder; this-login HOME for tar; remote dest "$HOME"
    mkdir -p "${CI_HOME}/box/app"
    printf 'up\n' > "${CI_HOME}/box/app/ok.txt"
    : > "${_ssh_log}"
    rm -f "${_ul_stdin}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SSH_LOG="${_ssh_log}" \
        SSHD_CLI_SSH_STDIN="${_ul_stdin}" \
        sh "${SCRIPT}" upload "${H_DL}" '~/box/app' 2>&1)
    _ec=$?
    assert_eq "TP-UL-14 tilde folder exit 0" 0 "$_ec"
    _log=$(cat "${_ssh_log}")
    assert_contains "TP-UL-14 remote uses HOME" "$_log" '"$HOME"'
    assert_not_contains "TP-UL-14 remote not this-login HOME" "$_log" "${CI_HOME}"
    assert_file_exists "TP-UL-14 stdin archive" "${_ul_stdin}"
    _mc=$(cat "${_ul_mem}")
    assert_contains "TP-UL-14 memory tilde path" "$_mc" "~/box/app"

    # TP-UL-15 ~ alone fail-closed
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" upload "${H_DL}" '~' 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-UL-15 tilde-only exit 1" 1 "$_ec"
    assert_contains "TP-UL-15 not allowed" "$_err" "not allowed"
    assert_contains "TP-UL-15 Next upload" "$_err" "upload"

    # TP-UL-16 ~user/path fail-closed
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" upload "${H_DL}" '~other/box' 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-UL-16 tilde-user exit 1" 1 "$_ec"
    assert_contains "TP-UL-16 not allowed" "$_err" "not allowed"
    assert_contains "TP-UL-16 Next upload" "$_err" "upload"

    # TP-UL-17 missing local directory fail-closed
    _err=$(HOME="${CI_HOME}" SSHD_CLI_SSH="${_fake_ssh}" sh "${SCRIPT}" upload "${H_DL}" "${CI_HOME}/no-such-upload-dir" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-UL-17 missing dir exit 1" 1 "$_ec"
    assert_contains "TP-UL-17 not a directory" "$_err" "not a directory"
    assert_contains "TP-UL-17 Next upload" "$_err" "upload"

    # TP-UL-18 TTY client menu numbers upload 14
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 TERMUX_VERSION=1 \
        sh "${SCRIPT}" 2>&1)
    assert_contains "TP-UL-18 Termux menu upload row 14" "$_out" "14."
    assert_contains "TP-UL-18 Termux menu upload short" "$_out" "upload"

    rm -rf "${_wd}" "${_wd2}" "${_wd3}" "${_wd4}" "${_wd5}" "${_wd6}" "${_wd7}" "${_wd8}" "${_wd9}" "${_wd10}" "${_fix}" "${_ul}" "${_ul2}"
    ci_cleanup_env
}
