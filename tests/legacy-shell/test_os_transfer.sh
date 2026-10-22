# =============================================================================
# tests/test_os_transfer.sh — MSYS2 / Git Bash file transfer vs streamed pipe
# =============================================================================
# Primary REQs: requirement-shell-windows-git-bash-cli-coding,
# requirement-shell-windows-cmd-cli-coding, requirement-domain-sshd
# TP families: TP-OS-GB-01 .. TP-OS-GB-04, TP-OS-CMD-01
# Host names are minted per run (synthetic-test-fixture).
# Fake ssh and scp. No live Host and no network session.
# TP-UL-* stays the non-MSYS pipe in test_ssh_download.sh.
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

_os_xfer_mint() {
    H_OS=$(t_rand_host)
    IP_OS=$(t_rand_ip)
}

_os_xfer_fixture() {
    mkdir -p "${CI_HOME}/.ssh" "${CI_HOME}/bin"
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_OS}
    HostName ${IP_OS}

Host *
    StrictHostKeyChecking accept-new
EOF
    chmod 700 "${CI_HOME}/.ssh"
    chmod 600 "${CI_HOME}/.ssh/config"
}

_os_xfer_fakes() {
    _fake_ssh="${CI_HOME}/bin/os-ssh"
    _fake_scp="${CI_HOME}/bin/os-scp"
    cat > "${_fake_ssh}" <<'FAKESSH'
#!/bin/sh
log="${SSHD_CLI_SSH_LOG:-}"
if [ -n "${log}" ]; then
    printf '%s\n' "$*" >> "${log}"
fi
host=""
cmd=""
skip=0
for a in "$@"; do
    if [ "${skip}" -eq 1 ]; then
        skip=0
        continue
    fi
    case "${a}" in
        -o|-l)
            skip=1
            continue
            ;;
        -*)
            continue
            ;;
    esac
    if [ -z "${host}" ]; then
        host="${a}"
        continue
    fi
    cmd="${a}"
done
case "${cmd}" in
    *__SSHD_CLI_UNAME__*)
        printf '%s\n' "__SSHD_CLI_UNAME__${SSHD_CLI_FAKE_UNAME:-Linux}"
        printf '%s\n' "__SSHD_CLI_OSTYPE__${SSHD_CLI_FAKE_OSTYPE:-}"
        exit 0
        ;;
esac
case "${cmd}" in
    *'tar xzf -'*)
        ;;
    *'tar xzf'*)
        if [ "${SSHD_CLI_FAKE_TAR_FAIL:-}" = "1" ]; then
            printf '%s\n' "tar: Error is not recoverable: exiting now" >&2
            exit 1
        fi
        ;;
esac
remote="${SSHD_CLI_FAKE_HOME:-}"
if [ -z "${remote}" ]; then
    cat >/dev/null
    exit 0
fi
HOME="${remote}" /bin/sh -c "${cmd}"
exit $?
FAKESSH
    cat > "${_fake_scp}" <<'FAKESCP'
#!/bin/sh
log="${SSHD_CLI_SCP_LOG:-}"
if [ -n "${log}" ]; then
    printf '%s\n' "$*" >> "${log}"
fi
src=""
dst=""
skip=0
for a in "$@"; do
    if [ "${skip}" -eq 1 ]; then
        skip=0
        continue
    fi
    case "${a}" in
        -o)
            skip=1
            continue
            ;;
        -*)
            continue
            ;;
    esac
    if [ -z "${src}" ]; then
        src="${a}"
        continue
    fi
    dst="${a}"
done
remote="${SSHD_CLI_FAKE_HOME:-}"
case "${dst}" in
    *:*)
        base="${dst##*:}"
        cp "${src}" "${remote}/${base}"
        exit $?
        ;;
esac
case "${src}" in
    *:*)
        base="${src##*:}"
        cp "${remote}/${base}" "${dst}"
        exit $?
        ;;
esac
exit 1
FAKESCP
    chmod 0755 "${_fake_ssh}" "${_fake_scp}"
}

_os_tar_left() {
    _left_n=$(find "$1" -name '*.tar.gz' 2>/dev/null | wc -l | tr -d ' ')
    printf '%s' "${_left_n}"
}

_os_env_reset() {
    : > "${_ssh_log}"
    : > "${_scp_log}"
}

run_test_os_transfer() {
    t_header "OS transfer (TP-OS-GB / TP-OS-CMD)"

    require_cmd sh
    require_cmd tar
    require_cmd gzip
    require_cmd find

    ci_isolated_env
    _os_xfer_mint
    _os_xfer_fixture
    _os_xfer_fakes

    _ssh_log="${CI_HOME}/os-ssh.log"
    _scp_log="${CI_HOME}/os-scp.log"
    _fake_home=$(mktemp -d "${TMPDIR:-/tmp}/os-remote.XXXXXX")
    _local=$(mktemp -d "${TMPDIR:-/tmp}/os-local.XXXXXX")
    _tree=$(mktemp -d "${TMPDIR:-/tmp}/os-tree.XXXXXX")
    _wd=$(mktemp -d "${TMPDIR:-/tmp}/os-cwd.XXXXXX")
    mkdir -p "${_local}/box" "${_tree}/app"
    printf 'up\n' > "${_local}/box/ok.txt"
    printf 'down\n' > "${_tree}/app/ok.txt"
    _real_gzip=$(command -v gzip)
    _gzip_dir=$(mktemp -d "${TMPDIR:-/tmp}/os-gzip.XXXXXX")
    cat > "${_gzip_dir}/gzip" <<EOF
#!/bin/sh
if [ "\${1-}" = "-t" ]; then
    printf '%s\n' "gzip: invalid compressed data--format violated" >&2
    exit 1
fi
exec ${_real_gzip} "\$@"
EOF
    chmod 0755 "${_gzip_dir}/gzip"

    # TP-OS-GB-01 upload to an MSYS reader uses a finished file
    _os_env_reset
    _out=$(HOME="${CI_HOME}" \
        SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SCP="${_fake_scp}" \
        SSHD_CLI_SSH_LOG="${_ssh_log}" SSHD_CLI_SCP_LOG="${_scp_log}" \
        SSHD_CLI_FAKE_HOME="${_fake_home}" \
        SSHD_CLI_FAKE_UNAME="MINGW64_NT-10.0" SSHD_CLI_FAKE_OSTYPE="msys" \
        sh "${SCRIPT}" upload "${H_OS}" "${_local}/box" 2>&1)
    _ec=$?
    _log=$(cat "${_ssh_log}")
    _slog=$(cat "${_scp_log}")
    assert_eq "TP-OS-GB-01 upload exit 0" 0 "${_ec}"
    assert_contains "TP-OS-GB-01 remote tar file" "${_log}" 'tar xzf "$HOME"'
    assert_not_contains "TP-OS-GB-01 no stdin tar" "${_log}" "tar xzf -"
    assert_not_contains "TP-OS-GB-01 no sleep" "${_log}" "sleep"
    assert_not_contains "TP-OS-GB-04 no sleep" "${_log}" "sleep"
    assert_not_contains "TP-OS-GB-01 no cat redirect" "${_log}" "cat >"
    assert_not_contains "TP-OS-GB-04 no cat redirect" "${_log}" "cat >"
    assert_contains "TP-OS-GB-01 scp used" "${_slog}" "${H_OS}:"
    assert_file_exists "TP-OS-GB-01 extracted marker" "${_fake_home}/box/ok.txt"
    assert_eq "TP-OS-GB-01 archive removed" "0" "$(_os_tar_left "${_fake_home}")"
    _body=$(cat "${_fake_home}/box/ok.txt")
    assert_eq "TP-OS-GB-01 marker text" "up" "${_body}"

    # TP-OS-GB-02 this login is Git Bash, so download does not stream gzip
    _os_env_reset
    rm -rf "${_fake_home}"
    mkdir -p "${_fake_home}"
    _out=$(
        cd "${_wd}" || exit 1
        MSYSTEM=MINGW64 HOME="${CI_HOME}" \
            SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SCP="${_fake_scp}" \
            SSHD_CLI_SSH_LOG="${_ssh_log}" SSHD_CLI_SCP_LOG="${_scp_log}" \
            SSHD_CLI_FAKE_HOME="${_fake_home}" \
            sh "${SCRIPT}" download "${H_OS}" "${_tree}/app" 2>&1
    )
    _ec=$?
    _log=$(cat "${_ssh_log}")
    _slog=$(cat "${_scp_log}")
    assert_eq "TP-OS-GB-02 download exit 0" 0 "${_ec}"
    assert_contains "TP-OS-GB-02 remote tar file" "${_log}" "tar czf"
    assert_not_contains "TP-OS-GB-02 no stdin tar" "${_log}" "tar czf -"
    assert_not_contains "TP-OS-GB-02 no sleep" "${_log}" "sleep"
    assert_not_contains "TP-OS-GB-02 no cat redirect" "${_log}" "cat >"
    assert_contains "TP-OS-GB-02 scp used" "${_slog}" "${H_OS}:"
    assert_file_exists "TP-OS-GB-02 extracted marker" "${_wd}/app/ok.txt"
    assert_eq "TP-OS-GB-02 archive removed" "0" "$(_os_tar_left "${_fake_home}")"
    _body=$(cat "${_wd}/app/ok.txt")
    assert_eq "TP-OS-GB-02 marker text" "down" "${_body}"

    # TP-OS-GB-03 gzip -t rejection names gzip; tar rejection names tar
    _os_env_reset
    rm -rf "${_fake_home}"
    mkdir -p "${_fake_home}"
    _err=$(PATH="${_gzip_dir}:${PATH}" HOME="${CI_HOME}" \
        SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SCP="${_fake_scp}" \
        SSHD_CLI_SSH_LOG="${_ssh_log}" SSHD_CLI_SCP_LOG="${_scp_log}" \
        SSHD_CLI_FAKE_HOME="${_fake_home}" \
        SSHD_CLI_FAKE_UNAME="MINGW64_NT-10.0" SSHD_CLI_FAKE_OSTYPE="msys" \
        sh "${SCRIPT}" upload "${H_OS}" "${_local}/box" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-OS-GB-03 gzip exit 1" 1 "${_ec}"
    assert_contains "TP-OS-GB-03 names gzip" "${_err}" "gzip"
    assert_not_contains "TP-OS-GB-03 gzip is not only ssh" "${_err}" "ssh ${H_OS} failed"

    _os_env_reset
    rm -rf "${_fake_home}"
    mkdir -p "${_fake_home}"
    _err=$(HOME="${CI_HOME}" \
        SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SCP="${_fake_scp}" \
        SSHD_CLI_SSH_LOG="${_ssh_log}" SSHD_CLI_SCP_LOG="${_scp_log}" \
        SSHD_CLI_FAKE_HOME="${_fake_home}" \
        SSHD_CLI_FAKE_UNAME="MINGW64_NT-10.0" SSHD_CLI_FAKE_OSTYPE="msys" \
        SSHD_CLI_FAKE_TAR_FAIL=1 \
        sh "${SCRIPT}" upload "${H_OS}" "${_local}/box" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-OS-GB-03 tar exit 1" 1 "${_ec}"
    assert_contains "TP-OS-GB-03 names tar" "${_err}" "tar"
    assert_not_contains "TP-OS-GB-03 tar is not only ssh" "${_err}" "ssh ${H_OS} failed"

    # TP-OS-GB-04 local Git Bash uploading to a non-MSYS reader still pipes
    _os_env_reset
    rm -rf "${_fake_home}"
    mkdir -p "${_fake_home}"
    _out=$(MSYSTEM=MINGW64 HOME="${CI_HOME}" \
        SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SCP="${_fake_scp}" \
        SSHD_CLI_SSH_LOG="${_ssh_log}" SSHD_CLI_SCP_LOG="${_scp_log}" \
        SSHD_CLI_FAKE_HOME="${_fake_home}" \
        SSHD_CLI_FAKE_UNAME="Linux" SSHD_CLI_FAKE_OSTYPE="linux-gnu" \
        sh "${SCRIPT}" upload "${H_OS}" "${_local}/box" 2>&1)
    _ec=$?
    _log=$(cat "${_ssh_log}")
    _slog=$(cat "${_scp_log}")
    assert_eq "TP-OS-GB-04 pipe exit 0" 0 "${_ec}"
    assert_contains "TP-OS-GB-04 keeps stdin tar" "${_log}" "tar xzf -"
    assert_eq "TP-OS-GB-04 scp unused" "" "${_slog}"
    assert_file_exists "TP-OS-GB-04 pipe extracted marker" "${_fake_home}/box/ok.txt"

    # TP-OS-CMD-01 Windows_NT alone keeps the streamed pipe
    _os_env_reset
    rm -rf "${_fake_home}"
    mkdir -p "${_fake_home}"
    _out=$(HOME="${CI_HOME}" \
        SSHD_CLI_SSH="${_fake_ssh}" SSHD_CLI_SCP="${_fake_scp}" \
        SSHD_CLI_SSH_LOG="${_ssh_log}" SSHD_CLI_SCP_LOG="${_scp_log}" \
        SSHD_CLI_FAKE_HOME="${_fake_home}" \
        SSHD_CLI_FAKE_UNAME="Windows_NT" SSHD_CLI_FAKE_OSTYPE="" \
        sh "${SCRIPT}" upload "${H_OS}" "${_local}/box" 2>&1)
    _ec=$?
    _log=$(cat "${_ssh_log}")
    _slog=$(cat "${_scp_log}")
    assert_eq "TP-OS-CMD-01 pipe exit 0" 0 "${_ec}"
    assert_contains "TP-OS-CMD-01 keeps stdin tar" "${_log}" "tar xzf -"
    assert_not_contains "TP-OS-CMD-01 no file extract" "${_log}" 'tar xzf "$HOME"'
    assert_eq "TP-OS-CMD-01 scp unused" "" "${_slog}"
    assert_file_exists "TP-OS-CMD-01 pipe extracted marker" "${_fake_home}/box/ok.txt"

    if [ -n "${T_REAL_HOME:-}" ]; then
        HOME="${T_REAL_HOME}"
        export HOME
    fi
    rm -rf "${_fake_home}" "${_local}" "${_tree}" "${_wd}" "${_gzip_dir}"
    ci_cleanup_env
}
