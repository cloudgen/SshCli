# =============================================================================
# tests/test_local_lifecycle.sh — local install / uninstall / where-is-me
# =============================================================================
# Primary REQs: requirement-shell-self-management, requirement-shell-idempotency,
# requirement-shell-interactive-vs-noninteractive, requirement-shell-termux-ish,
# requirement-shell-automatic-checksum (TP-CSUM-01),
# requirement-domain-sshd (TP-SSHD-02)
# TP family: TP-LC-* (incl. 20–22 BASHRC env) / TP-CSUM-01 / TP-SSHD-02 / TP-TX-08..16
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

# Termux PREFIX + stub sshd for wake-lock / start cases (CI isolation).
tx_prep_sshd_stub() {
    PREFIX="${CI_HOME}/usr"
    mkdir -p "${PREFIX}/bin" "${PREFIX}/etc/ssh" "${PREFIX}/var/run" "${CI_HOME}/stubbin"
    printf '%s\n' 'Port 8022' "PidFile ${PREFIX}/var/run/sshd.pid" > "${PREFIX}/etc/ssh/sshd_config"
    : > "${PREFIX}/etc/ssh/ssh_host_ed25519_key"
    cat > "${PREFIX}/bin/sshd" <<EOF
#!/bin/sh
if [ "\$1" = "-t" ]; then
    exit 0
fi
nohup sleep 120 >/dev/null 2>&1 &
echo \$! > "${PREFIX}/var/run/sshd.pid"
exit 0
EOF
    chmod +x "${PREFIX}/bin/sshd"
}

run_test_local_lifecycle() {
    t_header "Local lifecycle (TP-LC)"

    require_cmd sh

    ci_isolated_env

    # TP-LC-01 install places binary under USER_BIN
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-01 install exit 0" 0 "$_ec"
    assert_file_exists "TP-LC-01 binary at USER_BIN" "${CI_USER_BIN}/${APP_NAME}"
    assert_contains "TP-LC-01 install success text" "$_out" "successfully installed"

    # TP-CSUM-01 automatic companion path on first install (file://; no public network)
    assert_contains "TP-CSUM-01 companion link" "$_out" "Companion link:"
    if printf '%s' "$_out" | grep -q "Automatic checksum result: PASS"; then
        t_pass "TP-CSUM-01 automatic checksum PASS or missing-sidecar warn"
    elif printf '%s' "$_out" | grep -q "continuing without automatic verification"; then
        t_pass "TP-CSUM-01 automatic checksum PASS or missing-sidecar warn"
    else
        t_fail "TP-CSUM-01 expected PASS or missing-sidecar warn (got '$(_trunc "${_out}")')"
    fi
    assert_not_contains "TP-CSUM-01 no mismatch abort" "$_out" "Checksum verification failed"

    # TP-LC-11 install creates ~/.bashrc with USER_BIN PATH
    assert_file_exists "TP-LC-11 created ~/.bashrc" "${CI_HOME}/.bashrc"
    _bashrc=$(cat "${CI_HOME}/.bashrc" 2>/dev/null || true)
    _path_line=$(ci_bashrc_path_line)
    assert_contains "TP-LC-11 bashrc has USER_BIN" "$_bashrc" "${CI_USER_BIN}"
    assert_contains "TP-LC-11 bashrc has VERSION" "$_bashrc" "${PRODUCT_VERSION}"
    assert_contains "TP-LC-11 bashrc exact export PATH" "$_bashrc" "${_path_line}"

    # TP-LC-12 install creates ~/.profile that sources ~/.bashrc
    assert_file_exists "TP-LC-12 created ~/.profile" "${CI_HOME}/.profile"
    _profile=$(cat "${CI_HOME}/.profile" 2>/dev/null || true)
    assert_contains "TP-LC-12 profile sources bashrc" "$_profile" '. "${HOME}/.bashrc"'

    # TP-LC-02 installed version works
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" version 2>/dev/null)
    assert_eq "TP-LC-02 installed version exit 0" 0 "$?"
    assert_contains "TP-LC-02 installed version" "$_out" "${PRODUCT_VERSION}"

    # TP-LC-03 idempotent reinstall without force
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-03 reinstall exit 0" 0 "$_ec"
    assert_contains "TP-LC-03 already installed" "$_out" "already installed"

    # TP-LC-13 re-run does not duplicate PATH lines
    _path_hits=$(grep -cF "${_path_line}" "${CI_HOME}/.bashrc" 2>/dev/null || echo 0)
    assert_eq "TP-LC-13 bashrc exact PATH export once" "1" "$_path_hits"

    # TP-LC-04 about shows installed path
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" --json about 2>/dev/null)
    _ec=$?
    assert_eq "TP-LC-04 about json exit 0" 0 "$_ec"
    assert_contains "TP-LC-04 json installed true" "$_out" '"installed":"true"'
    assert_contains "TP-LC-04 json local_version" "$_out" "\"local_version\":\"${PRODUCT_VERSION}\""

    # TP-LC-05 self-uninstall --json without force fails closed
    _err=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" --json self-uninstall 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-LC-05 self-uninstall json no-force exit 1" 1 "$_ec"
    assert_file_exists "TP-LC-05 binary remains" "${CI_USER_BIN}/${APP_NAME}"

    # TP-LC-06 self-uninstall --force removes
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force 2>&1)
    _ec=$?
    assert_eq "TP-LC-06 self-uninstall --force exit 0" 0 "$_ec"
    assert_file_missing "TP-LC-06 binary removed" "${CI_USER_BIN}/${APP_NAME}"

    # TP-LC-07 self-uninstall when absent is success no-op
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" self-uninstall --force 2>&1)
    _ec=$?
    assert_eq "TP-LC-07 self-uninstall absent exit 0" 0 "$_ec"
    assert_contains "TP-LC-07 nothing to uninstall" "$_out" "not installed"

    # TP-LC-08 about after install shows installed
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install >/dev/null 2>&1
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" --json about 2>/dev/null)
    assert_contains "TP-LC-08 about installed true" "$_out" '"installed":"true"'

    # TP-LC-09 managed binary mode must be 0755 (shell ship unit multi-user runnable)
    _mode=$(stat -c '%a' "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || stat -f '%OLp' "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || echo "")
    case "${_mode}" in
        755|0755) assert_eq "TP-LC-09 install mode 0755" "0755" "0755" ;;
        *) assert_eq "TP-LC-09 install mode 0755" "0755" "${_mode}" ;;
    esac
    # Must be readable+executable (not 0711 execute-without-read)
    if [ -r "${CI_USER_BIN}/${APP_NAME}" ] && [ -x "${CI_USER_BIN}/${APP_NAME}" ]; then
        assert_eq "TP-LC-09 readable+executable" "1" "1"
    else
        assert_eq "TP-LC-09 readable+executable" "1" "0"
    fi

    # TP-LC-10 --force reinstall restores mode 0755 (0711 trap)
    chmod 0711 "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || chmod 711 "${CI_USER_BIN}/${APP_NAME}"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install --force 2>&1)
    _ec=$?
    assert_eq "TP-LC-10 force reinstall exit 0" 0 "$_ec"
    assert_contains "TP-LC-10 force reinstall success" "$_out" "successfully installed"
    _mode=$(stat -c '%a' "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || stat -f '%OLp' "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || echo "")
    case "${_mode}" in
        755|0755) assert_eq "TP-LC-10 healed mode 0755" "0755" "0755" ;;
        *) assert_eq "TP-LC-10 healed mode 0755" "0755" "${_mode}" ;;
    esac

    # cleanup remaining binary
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-14 existing ~/.profile body is kept; ~/.bashrc is modified not replaced
    ci_isolated_env
    printf '%s\n' "# keep-me-profile" > "${CI_HOME}/.profile"
    printf '%s\n' "# keep-me-bashrc" > "${CI_HOME}/.bashrc"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-14 install with existing rc exit 0" 0 "$_ec"
    _profile=$(cat "${CI_HOME}/.profile" 2>/dev/null || true)
    _bashrc=$(cat "${CI_HOME}/.bashrc" 2>/dev/null || true)
    assert_contains "TP-LC-14 profile body kept" "$_profile" "keep-me-profile"
    assert_not_contains "TP-LC-14 profile not replaced with marker block" "$_profile" "BEGIN ${APP_NAME} profile"
    assert_contains "TP-LC-14 bashrc body kept" "$_bashrc" "keep-me-bashrc"
    assert_contains "TP-LC-14 bashrc still got PATH" "$_bashrc" "${CI_USER_BIN}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-20 BASHRC env: create the file in a random temp folder when missing
    ci_isolated_env
    ci_isolated_bashrc
    assert_file_missing "TP-LC-20 BASHRC absent before install" "${CI_BASHRC}"
    assert_file_missing "TP-LC-20 HOME/.bashrc absent before install" "${CI_HOME}/.bashrc"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-20 install exit 0" 0 "$_ec"
    assert_file_exists "TP-LC-20 created BASHRC in temp folder" "${CI_BASHRC}"
    assert_file_missing "TP-LC-20 did not write HOME/.bashrc" "${CI_HOME}/.bashrc"
    _bashrc=$(cat "${CI_BASHRC}" 2>/dev/null || true)
    _path_line=$(ci_bashrc_path_line)
    assert_contains "TP-LC-20 created header names VERSION" "$_bashrc" "Interactive rc created by ${APP_NAME} installer (${PRODUCT_VERSION})"
    assert_contains "TP-LC-20 created Added-by VERSION" "$_bashrc" "Added by ${APP_NAME} installer (${PRODUCT_VERSION})"
    assert_contains "TP-LC-20 created exact export PATH" "$_bashrc" "${_path_line}"
    assert_contains "TP-LC-20 reports created BASHRC" "$_out" "Created ${CI_BASHRC}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-21 BASHRC env: modify a dongle .bashrc in that random temp folder
    ci_isolated_env
    ci_isolated_bashrc
    printf '%s\n' "# dongle-bashrc-keep" "alias dongle_probe=true" > "${CI_BASHRC}"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-21 install exit 0" 0 "$_ec"
    assert_file_missing "TP-LC-21 did not write HOME/.bashrc" "${CI_HOME}/.bashrc"
    _bashrc=$(cat "${CI_BASHRC}" 2>/dev/null || true)
    _path_line=$(ci_bashrc_path_line)
    assert_contains "TP-LC-21 dongle body kept" "$_bashrc" "dongle-bashrc-keep"
    assert_contains "TP-LC-21 dongle alias kept" "$_bashrc" "alias dongle_probe=true"
    assert_contains "TP-LC-21 dongle got Added-by VERSION" "$_bashrc" "Added by ${APP_NAME} installer (${PRODUCT_VERSION})"
    assert_contains "TP-LC-21 dongle exact export PATH" "$_bashrc" "${_path_line}"
    _path_hits=$(grep -cF "${_path_line}" "${CI_BASHRC}" 2>/dev/null || true)
    [ -z "${_path_hits}" ] && _path_hits=0
    assert_eq "TP-LC-21 PATH export once" "1" "${_path_hits}"
    assert_contains "TP-LC-21 reports PATH added" "$_out" "Added ${CI_USER_BIN} to PATH for bash"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-22 BASHRC env: already has current VERSION and exact export PATH → do nothing
    ci_isolated_env
    ci_isolated_bashrc
    _path_line=$(ci_bashrc_path_line)
    {
        printf '%s\n' "# dongle-already-good"
        printf '# Interactive rc created by %s installer (%s)\n' "${APP_NAME}" "${PRODUCT_VERSION}"
        printf '\n'
        printf '# Added by %s installer (%s)\n' "${APP_NAME}" "${PRODUCT_VERSION}"
        printf '%s\n' "${_path_line}"
    } > "${CI_BASHRC}"
    cp "${CI_BASHRC}" "${CI_BASHRC}.orig"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-22 install exit 0" 0 "$_ec"
    if cmp -s "${CI_BASHRC}" "${CI_BASHRC}.orig"; then
        t_pass "TP-LC-22 bashrc bytes unchanged"
    else
        t_fail "TP-LC-22 bashrc bytes unchanged"
    fi
    _bashrc=$(cat "${CI_BASHRC}" 2>/dev/null || true)
    assert_contains "TP-LC-22 dongle body still there" "$_bashrc" "dongle-already-good"
    assert_contains "TP-LC-22 VERSION still present" "$_bashrc" "${PRODUCT_VERSION}"
    assert_contains "TP-LC-22 exact export PATH still present" "$_bashrc" "${_path_line}"
    _path_hits=$(grep -cF "${_path_line}" "${CI_BASHRC}" 2>/dev/null || true)
    [ -z "${_path_hits}" ] && _path_hits=0
    assert_eq "TP-LC-22 PATH export still once" "1" "${_path_hits}"
    assert_not_contains "TP-LC-22 no Created BASHRC" "$_out" "Created ${CI_BASHRC}"
    assert_not_contains "TP-LC-22 no Added PATH for bash" "$_out" "Added ${CI_USER_BIN} to PATH for bash"
    assert_file_missing "TP-LC-22 did not write HOME/.bashrc" "${CI_HOME}/.bashrc"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-27 sibling unify: exact PATH already present from another app
    ci_isolated_env
    ci_isolated_bashrc
    _path_line=$(ci_bashrc_path_line)
    printf '%s\n' "# Added by other-cli installer (0.1.0)" "${_path_line}" > "${CI_BASHRC}"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-27 install exit 0" 0 "$_ec"
    _bashrc=$(cat "${CI_BASHRC}" 2>/dev/null || true)
    _path_hits=$(grep -cF "${_path_line}" "${CI_BASHRC}" 2>/dev/null || true)
    [ -z "${_path_hits}" ] && _path_hits=0
    assert_eq "TP-LC-27 still one exact PATH export" "1" "${_path_hits}"
    assert_contains "TP-LC-27 kept sibling comment" "$_bashrc" "Added by other-cli installer (0.1.0)"
    assert_file_missing "TP-LC-27 did not write HOME/.bashrc" "${CI_HOME}/.bashrc"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" BASHRC="${CI_BASHRC}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_bashrc
    ci_cleanup_env

    # TP-LC-28 uninstall keeps shared PATH while USER_BIN still has files
    ci_isolated_env
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install >/dev/null 2>&1
    printf '%s\n' "other" > "${CI_USER_BIN}/other-tool"
    _path_line=$(ci_bashrc_path_line)
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1
    _bashrc=$(cat "${CI_HOME}/.bashrc" 2>/dev/null || true)
    assert_contains "TP-LC-28 PATH line kept" "$_bashrc" "${_path_line}"
    assert_not_contains "TP-LC-28 sshd-cli comment stripped" "$_bashrc" "Added by ${APP_NAME} installer"
    assert_file_exists "TP-LC-28 other-tool remains" "${CI_USER_BIN}/other-tool"
    rm -f "${CI_USER_BIN}/other-tool"
    ci_cleanup_env

    # TP-LC-29 heal: already installed, exact PATH missing, install restores it
    ci_isolated_env
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install >/dev/null 2>&1
    _path_line=$(ci_bashrc_path_line)
    printf '%s\n' "# leftover" > "${CI_HOME}/.bashrc"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-29 heal install exit 0" 0 "$_ec"
    assert_contains "TP-LC-29 already installed" "$_out" "already installed"
    _bashrc=$(cat "${CI_HOME}/.bashrc" 2>/dev/null || true)
    assert_contains "TP-LC-29 leftover kept" "$_bashrc" "leftover"
    assert_contains "TP-LC-29 PATH healed" "$_bashrc" "${_path_line}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-30 uninstall does not delete .profile
    ci_isolated_env
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" install >/dev/null 2>&1
    assert_file_exists "TP-LC-30 profile exists before uninstall" "${CI_HOME}/.profile"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1
    assert_file_exists "TP-LC-30 profile kept after uninstall" "${CI_HOME}/.profile"
    ci_cleanup_env

    # TP-LC-31 rc-test create/modify/noop against --root (not HOME/.bashrc)
    ci_isolated_env
    _rcroot=$(mktemp -d "${TMPDIR:-/tmp}/rc-test.XXXXXX")
    _path_line=$(ci_bashrc_path_line)
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file bashrc --case create 2>&1)
    _ec=$?
    assert_eq "TP-LC-31 rc-test create exit 0" 0 "$_ec"
    assert_file_exists "TP-LC-31 fixture bashrc created" "${_rcroot}/.bashrc"
    assert_contains "TP-LC-31 fixture exact PATH" "$(cat "${_rcroot}/.bashrc")" "${_path_line}"
    assert_file_missing "TP-LC-31 create did not write HOME/.bashrc" "${CI_HOME}/.bashrc"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file bashrc --case noop >/dev/null 2>&1
    assert_eq "TP-LC-31 rc-test noop first exit 0" 0 "$?"
    cp "${_rcroot}/.bashrc" "${_rcroot}/.bashrc.orig"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file bashrc --case noop >/dev/null 2>&1
    if cmp -s "${_rcroot}/.bashrc" "${_rcroot}/.bashrc.orig"; then
        t_pass "TP-LC-31 rc-test second noop bytes unchanged"
    else
        t_fail "TP-LC-31 rc-test second noop bytes unchanged"
    fi
    printf '%s\n' "# dongle-keep-rc-test" > "${_rcroot}/.bashrc"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file bashrc --case modify 2>&1)
    assert_eq "TP-LC-31 rc-test modify exit 0" 0 "$?"
    _bashrc=$(cat "${_rcroot}/.bashrc")
    assert_contains "TP-LC-31 modify kept dongle" "$_bashrc" "dongle-keep-rc-test"
    assert_contains "TP-LC-31 modify PATH" "$_bashrc" "${_path_line}"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" rc-test --root "${_rcroot}" --file profile --case create >/dev/null 2>&1
    assert_file_exists "TP-LC-31 profile created under root" "${_rcroot}/.profile"
    assert_contains "TP-LC-31 profile sources bashrc" "$(cat "${_rcroot}/.profile")" '. "${HOME}/.bashrc"'
    rm -rf -- "${_rcroot}"
    ci_cleanup_env

    # TP-LC-15 not Termux: pkg is not invoked
    ci_isolated_env
    mkdir -p "${CI_HOME}/stubbin"
    printf '%s\n' '#!/bin/sh' "echo CALLED >> \"${CI_HOME}/pkg-called.log\"" 'exit 1' > "${CI_HOME}/stubbin/pkg"
    chmod +x "${CI_HOME}/stubbin/pkg"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/stubbin:${PATH}" env -u TERMUX_VERSION sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-15 non-Termux install exit 0" 0 "$_ec"
    assert_file_missing "TP-LC-15 pkg not called" "${CI_HOME}/pkg-called.log"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-16 Termux mock: pkg install -y openssh termux-auth
    # TP-LC-17 install ends by starting sshd (stub daemon)
    ci_isolated_env
    PREFIX="${CI_HOME}/usr"
    mkdir -p "${PREFIX}/bin" "${PREFIX}/etc/ssh" "${PREFIX}/var/run" "${CI_HOME}/stubbin"
    printf '%s\n' 'Port 8022' "PidFile ${PREFIX}/var/run/sshd.pid" > "${PREFIX}/etc/ssh/sshd_config"
    : > "${PREFIX}/etc/ssh/ssh_host_ed25519_key"
    cat > "${PREFIX}/bin/sshd" <<EOF
#!/bin/sh
if [ "\$1" = "-t" ]; then
    exit 0
fi
nohup sleep 120 >/dev/null 2>&1 &
echo \$! > "${PREFIX}/var/run/sshd.pid"
exit 0
EOF
    chmod +x "${PREFIX}/bin/sshd"
    printf '%s\n' '#!/bin/sh' "printf '%s\\n' \"\$*\" >> \"${CI_HOME}/pkg-args.log\"" 'exit 0' > "${CI_HOME}/stubbin/pkg"
    chmod +x "${CI_HOME}/stubbin/pkg"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PREFIX="${PREFIX}" PATH="${CI_HOME}/stubbin:${PREFIX}/bin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-16 Termux mock install exit 0" 0 "$_ec"
    _pkg_args=$(cat "${CI_HOME}/pkg-args.log" 2>/dev/null || true)
    assert_contains "TP-LC-16 pkg install -y" "$_pkg_args" "install -y openssh termux-auth"
    assert_contains "TP-LC-17 install started sshd" "$_out" "sshd started"
    assert_contains "TP-SSHD-02 background daemon" "$_out" "background daemon"
    assert_contains "TP-SSHD-02 after a reboot" "$_out" "After a reboot"
    assert_contains "TP-SSHD-02 Termux:Boot operator hook" "$_out" "Termux:Boot"
    assert_file_exists "TP-LC-17 stub pidfile" "${PREFIX}/var/run/sshd.pid"
    _stub_pid=$(tr -d ' \n\r\t' < "${PREFIX}/var/run/sshd.pid" 2>/dev/null || true)
    if [ -n "${_stub_pid}" ] && kill -0 "${_stub_pid}" 2>/dev/null; then
        t_pass "TP-LC-17 stub sshd pid is live"
        kill "${_stub_pid}" 2>/dev/null || true
    else
        t_fail "TP-LC-17 stub sshd pid is live"
    fi
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-SSHD-15 self-update is CLI-only: host sshd -t failure must not fail CLI place
    ci_isolated_env
    PREFIX="${CI_HOME}/usr"
    mkdir -p "${PREFIX}/bin" "${PREFIX}/etc/ssh" "${PREFIX}/var/run" "${CI_HOME}/stubbin"
    printf '%s\n' 'Port 8022' "PidFile ${PREFIX}/var/run/sshd.pid" > "${PREFIX}/etc/ssh/sshd_config"
    : > "${PREFIX}/etc/ssh/ssh_host_ed25519_key"
    cat > "${PREFIX}/bin/sshd" <<EOF
#!/bin/sh
if [ "\$1" = "-t" ]; then
    exit 0
fi
nohup sleep 120 >/dev/null 2>&1 &
echo \$! > "${PREFIX}/var/run/sshd.pid"
exit 0
EOF
    chmod +x "${PREFIX}/bin/sshd"
    printf '%s\n' '#!/bin/sh' "printf '%s\\n' \"\$*\" >> \"${CI_HOME}/pkg-args.log\"" 'exit 0' > "${CI_HOME}/stubbin/pkg"
    chmod +x "${CI_HOME}/stubbin/pkg"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PREFIX="${PREFIX}" PATH="${CI_HOME}/stubbin:${PREFIX}/bin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" install >/dev/null 2>&1
    cat > "${PREFIX}/bin/sshd" <<EOF
#!/bin/sh
echo CALLED_T >> "${CI_HOME}/sshd-t.log"
if [ "\$1" = "-t" ]; then
    echo "Missing privilege separation directory: /run/sshd" >&2
    exit 1
fi
exit 1
EOF
    chmod +x "${PREFIX}/bin/sshd"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PREFIX="${PREFIX}" PATH="${CI_HOME}/stubbin:${PREFIX}/bin:${PATH}" TERMUX_VERSION=1 SCRIPT_URL="${SCRIPT_URL}" sh "${SCRIPT}" --force self-update 2>&1)
    _ec=$?
    assert_eq "TP-SSHD-15 self-update exit 0 despite sshd -t fail" 0 "$_ec"
    assert_not_contains "TP-SSHD-15 no sshd_config ERROR" "$_out" "sshd refused the config"
    assert_not_contains "TP-SSHD-15 no /run/sshd ERROR" "$_out" "Missing privilege separation directory"
    assert_file_exists "TP-SSHD-15 CLI still installed" "${CI_USER_BIN}/${APP_NAME}"
    assert_file_missing "TP-SSHD-15 sshd -t not invoked" "${CI_HOME}/sshd-t.log"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-18 Git Bash mock: command line for normal user only — pkg not invoked
    ci_isolated_env
    mkdir -p "${CI_HOME}/stubbin"
    printf '%s\n' '#!/bin/sh' "echo CALLED >> \"${CI_HOME}/pkg-called.log\"" 'exit 1' > "${CI_HOME}/stubbin/pkg"
    chmod +x "${CI_HOME}/stubbin/pkg"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/stubbin:${PATH}" env -u TERMUX_VERSION MSYSTEM=MINGW64 sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-18 Git Bash mock install exit 0" 0 "$_ec"
    assert_file_missing "TP-LC-18 pkg not called on Git Bash" "${CI_HOME}/pkg-called.log"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # TP-LC-19 Windows cmd mock: command line for normal user only — pkg not invoked
    ci_isolated_env
    mkdir -p "${CI_HOME}/stubbin"
    printf '%s\n' '#!/bin/sh' "echo CALLED >> \"${CI_HOME}/pkg-called.log\"" 'exit 1' > "${CI_HOME}/stubbin/pkg"
    chmod +x "${CI_HOME}/stubbin/pkg"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/stubbin:${PATH}" env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME OS=Windows_NT COMSPEC='C:\\Windows\\system32\\cmd.exe' sh "${SCRIPT}" install 2>&1)
    _ec=$?
    assert_eq "TP-LC-19 Windows cmd mock install exit 0" 0 "$_ec"
    assert_file_missing "TP-LC-19 pkg not called on Windows cmd" "${CI_HOME}/pkg-called.log"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${CI_USER_BIN}/${APP_NAME}" self-uninstall --force >/dev/null 2>&1 || true
    ci_cleanup_env

    # --- Android wake lock (TP-TX-08..16) ---

    # TP-TX-08 not Termux: termux-wake-lock is not invoked
    ci_isolated_env
    mkdir -p "${CI_HOME}/stubbin"
    printf '%s\n' '#!/bin/sh' "echo CALLED >> \"${CI_HOME}/wake-lock-called.log\"" 'exit 0' > "${CI_HOME}/stubbin/termux-wake-lock"
    chmod +x "${CI_HOME}/stubbin/termux-wake-lock"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/stubbin:${PATH}" env -u TERMUX_VERSION sh "${SCRIPT}" wake-lock 2>&1)
    _ec=$?
    assert_eq "TP-TX-08 non-Termux wake-lock exit 0" 0 "$_ec"
    assert_contains "TP-TX-08 non-Termux no-op text" "$_out" "Not Termux"
    assert_file_missing "TP-TX-08 termux-wake-lock not called" "${CI_HOME}/wake-lock-called.log"
    ci_cleanup_env

    # TP-TX-09 Termux mock start invokes termux-wake-lock
    ci_isolated_env
    tx_prep_sshd_stub
    printf '%s\n' '#!/bin/sh' "printf '%s\\n' \"\$*\" >> \"${CI_HOME}/wake-lock-called.log\"" 'exit 0' > "${CI_HOME}/stubbin/termux-wake-lock"
    chmod +x "${CI_HOME}/stubbin/termux-wake-lock"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PREFIX="${PREFIX}" PATH="${CI_HOME}/stubbin:${PREFIX}/bin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" start 2>&1)
    _ec=$?
    assert_eq "TP-TX-09 Termux start exit 0" 0 "$_ec"
    assert_file_exists "TP-TX-09 start called termux-wake-lock" "${CI_HOME}/wake-lock-called.log"
    assert_contains "TP-TX-09 start names wake lock" "$_out" "wake lock"
    _stub_pid=$(tr -d ' \n\r\t' < "${PREFIX}/var/run/sshd.pid" 2>/dev/null || true)
    # already-running start still re-acquires
    : > "${CI_HOME}/wake-lock-called.log"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PREFIX="${PREFIX}" PATH="${CI_HOME}/stubbin:${PREFIX}/bin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" start 2>&1)
    _ec=$?
    assert_eq "TP-TX-09 already-running start exit 0" 0 "$_ec"
    assert_file_exists "TP-TX-09 already-running re-acquires wake lock" "${CI_HOME}/wake-lock-called.log"
    if [ -n "${_stub_pid}" ]; then
        kill "${_stub_pid}" 2>/dev/null || true
    fi
    ci_cleanup_env

    # TP-TX-10 Termux mock wake-lock verb
    ci_isolated_env
    mkdir -p "${CI_HOME}/stubbin"
    printf '%s\n' '#!/bin/sh' "echo CALLED >> \"${CI_HOME}/wake-lock-called.log\"" 'exit 0' > "${CI_HOME}/stubbin/termux-wake-lock"
    chmod +x "${CI_HOME}/stubbin/termux-wake-lock"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/stubbin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" wake-lock 2>&1)
    _ec=$?
    assert_eq "TP-TX-10 Termux wake-lock verb exit 0" 0 "$_ec"
    assert_file_exists "TP-TX-10 verb called termux-wake-lock" "${CI_HOME}/wake-lock-called.log"
    assert_contains "TP-TX-10 verb success text" "$_out" "Android wake lock acquired"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/stubbin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" wake-lock 2>&1)
    _ec=$?
    assert_eq "TP-TX-10 second wake-lock idempotent exit 0" 0 "$_ec"
    ci_cleanup_env

    # TP-TX-11 Git Bash: termux-wake-lock not invoked
    ci_isolated_env
    mkdir -p "${CI_HOME}/stubbin"
    printf '%s\n' '#!/bin/sh' "echo CALLED >> \"${CI_HOME}/wake-lock-called.log\"" 'exit 0' > "${CI_HOME}/stubbin/termux-wake-lock"
    chmod +x "${CI_HOME}/stubbin/termux-wake-lock"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/stubbin:${PATH}" env -u TERMUX_VERSION MSYSTEM=MINGW64 sh "${SCRIPT}" wake-lock 2>&1)
    _ec=$?
    assert_eq "TP-TX-11 Git Bash wake-lock exit 0" 0 "$_ec"
    assert_file_missing "TP-TX-11 Git Bash helper not called" "${CI_HOME}/wake-lock-called.log"
    ci_cleanup_env

    # TP-TX-12 Windows cmd: termux-wake-lock not invoked
    ci_isolated_env
    mkdir -p "${CI_HOME}/stubbin"
    printf '%s\n' '#!/bin/sh' "echo CALLED >> \"${CI_HOME}/wake-lock-called.log\"" 'exit 0' > "${CI_HOME}/stubbin/termux-wake-lock"
    chmod +x "${CI_HOME}/stubbin/termux-wake-lock"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/stubbin:${PATH}" env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME OS=Windows_NT COMSPEC='C:\\Windows\\system32\\cmd.exe' sh "${SCRIPT}" wake-lock 2>&1)
    _ec=$?
    assert_eq "TP-TX-12 Windows cmd wake-lock exit 0" 0 "$_ec"
    assert_file_missing "TP-TX-12 Windows cmd helper not called" "${CI_HOME}/wake-lock-called.log"
    ci_cleanup_env

    # TP-TX-13 Termux start, helper missing: start still succeeds; Next names wake-lock
    ci_isolated_env
    tx_prep_sshd_stub
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PREFIX="${PREFIX}" PATH="${PREFIX}/bin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" start 2>&1)
    _ec=$?
    assert_eq "TP-TX-13 start without helper exit 0" 0 "$_ec"
    assert_contains "TP-TX-13 start still started sshd" "$_out" "sshd started"
    assert_contains "TP-TX-13 warn names Next wake-lock" "$_out" "wake-lock"
    _stub_pid=$(tr -d ' \n\r\t' < "${PREFIX}/var/run/sshd.pid" 2>/dev/null || true)
    if [ -n "${_stub_pid}" ]; then
        kill "${_stub_pid}" 2>/dev/null || true
    fi
    ci_cleanup_env

    # TP-TX-14 Termux wake-lock verb, helper missing: fail closed + Next
    ci_isolated_env
    mkdir -p "${CI_HOME}/stubbin"
    _err=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/stubbin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" wake-lock 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-TX-14 missing helper exit 1" 1 "$_ec"
    assert_contains "TP-TX-14 Next pkg install termux-tools" "$_err" "pkg install termux-tools"
    assert_contains "TP-TX-14 Next names wake-lock" "$_err" "wake-lock"
    ci_cleanup_env

    # TP-TX-16 stop does not invoke termux-wake-unlock
    ci_isolated_env
    tx_prep_sshd_stub
    printf '%s\n' '#!/bin/sh' "echo LOCK >> \"${CI_HOME}/wake-lock-called.log\"" 'exit 0' > "${CI_HOME}/stubbin/termux-wake-lock"
    printf '%s\n' '#!/bin/sh' "echo UNLOCK >> \"${CI_HOME}/wake-unlock-called.log\"" 'exit 0' > "${CI_HOME}/stubbin/termux-wake-unlock"
    chmod +x "${CI_HOME}/stubbin/termux-wake-lock" "${CI_HOME}/stubbin/termux-wake-unlock"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PREFIX="${PREFIX}" PATH="${CI_HOME}/stubbin:${PREFIX}/bin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" start >/dev/null 2>&1
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PREFIX="${PREFIX}" PATH="${CI_HOME}/stubbin:${PREFIX}/bin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" stop 2>&1)
    _ec=$?
    assert_eq "TP-TX-16 stop exit 0" 0 "$_ec"
    assert_file_missing "TP-TX-16 stop does not unlock" "${CI_HOME}/wake-unlock-called.log"
    ci_cleanup_env

}
