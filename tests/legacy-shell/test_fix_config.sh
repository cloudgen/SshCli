# =============================================================================
# tests/test_fix_config.sh — comment unsupported OpenSSH client keywords
# =============================================================================
# Primary REQs: requirement-domain-sshd, requirement-shell-cli-interface
# TP family: TP-FIX-*
# Host names and IPv4 are minted per run (synthetic-test-fixture).
# SSHD_CLI_OS selects alpine / termux / posix without the live OS.
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

_fix_active() {
    _path="$1"
    _pat="$2"
    grep -iE "^[[:space:]]*${_pat}" "${_path}" 2>/dev/null || true
}

run_test_fix_config() {
    t_header "fix-config (TP-FIX)"

    require_cmd sh
    require_cmd awk
    require_cmd cmp

    ci_isolated_env
    H_FX=$(t_rand_host)
    IP_FX=$(t_rand_ip)
    _side="${CI_HOME}/client-config"
    _copy="${CI_HOME}/client-out"

    # TP-FIX-01 help lists the verb and both flags
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" help 2>&1)
    assert_contains "TP-FIX-01 help lists fix-config" "${_out}" "fix-config [--input-file PATH] [--output-file PATH]"

    # TP-FIX-02 a flag before the verb is unknown
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" --input-file "${_side}" fix-config 2>&1)
    _ec=$?
    assert_eq "TP-FIX-02 flag before verb fails" "1" "${_ec}"
    assert_contains "TP-FIX-02 names the unknown token" "${_out}" "Unknown command or flag"

    # TP-FIX-03 alpine --input-file comments GSSAPI* in place and keeps other keys
    mkdir -p "${CI_HOME}/.ssh"
    cat > "${_side}" <<EOF
Host ${H_FX}
    HostName ${IP_FX}
    GSSAPIAuthentication yes
    ForwardAgent yes
    # GSSAPIAuthentication is unsupported on Alpine

Host *
    GSSAPIAuthentication=no
    GSSAPIDelegateCredentials no
    StrictHostKeyChecking accept-new

Match host ${H_FX}
    GSSAPIKexAlgorithms gss-*
EOF
    chmod 600 "${_side}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=alpine sh "${SCRIPT}" fix-config --input-file "${_side}" 2>&1)
    _ec=$?
    assert_eq "TP-FIX-03 alpine input exit 0" "0" "${_ec}"
    assert_contains "TP-FIX-03 human commented" "${_out}" "Commented unsupported OpenSSH client keywords (alpine)."
    assert_contains "TP-FIX-03 backup noted" "${_out}" "Backup created"
    _cfg=$(cat "${_side}")
    _hit=$(_fix_active "${_side}" 'gssapi')
    assert_eq "TP-FIX-03 no active GSSAPI" "" "${_hit}"
    assert_contains "TP-FIX-03 indented comment" "${_cfg}" "    # GSSAPIAuthentication yes"
    assert_contains "TP-FIX-03 Host * equals form" "${_cfg}" "    # GSSAPIAuthentication=no"
    assert_contains "TP-FIX-03 delegate commented" "${_cfg}" "    # GSSAPIDelegateCredentials no"
    assert_contains "TP-FIX-03 kex commented" "${_cfg}" "    # GSSAPIKexAlgorithms gss-*"
    assert_contains "TP-FIX-03 prior comment stays" "${_cfg}" "# GSSAPIAuthentication is unsupported on Alpine"
    assert_contains "TP-FIX-03 ForwardAgent stays" "${_cfg}" "ForwardAgent yes"
    assert_contains "TP-FIX-03 StrictHostKeyChecking stays" "${_cfg}" "StrictHostKeyChecking accept-new"
    assert_contains "TP-FIX-03 Host line stays" "${_cfg}" "Host ${H_FX}"
    _mode=$(stat -c '%a' "${_side}" 2>/dev/null || stat -f '%OLp' "${_side}")
    assert_eq "TP-FIX-03 mode 600" "600" "${_mode}"
    _dated=$(find "${CI_HOME}" -name '*.20*.bak' 2>/dev/null | wc -l | tr -d ' ')
    assert_eq "TP-FIX-03 one dated backup" "1" "${_dated}"

    # TP-FIX-04 second pass is unchanged and does not add another backup
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=alpine sh "${SCRIPT}" fix-config --input-file "${_side}" 2>&1)
    _ec=$?
    assert_eq "TP-FIX-04 second pass exit 0" "0" "${_ec}"
    assert_contains "TP-FIX-04 already matches" "${_out}" "OpenSSH client config already matches this OS (alpine)."
    _dated2=$(find "${CI_HOME}" -name '*.20*.bak' 2>/dev/null | wc -l | tr -d ' ')
    assert_eq "TP-FIX-04 no extra dated backup" "${_dated}" "${_dated2}"

    # TP-FIX-05 both flags: input stays, output is the commented copy
    cat > "${_side}" <<EOF
Host ${H_FX}
    HostName ${IP_FX}
    GSSAPIAuthentication yes
    ForwardAgent yes
EOF
    chmod 600 "${_side}"
    rm -f "${_copy}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=alpine sh "${SCRIPT}" --json fix-config --input-file "${_side}" --output-file "${_copy}" 2>/dev/null)
    _ec=$?
    assert_eq "TP-FIX-05 both flags exit 0" "0" "${_ec}"
    _njson=$(printf '%s\n' "${_out}" | grep -c '^{' || true)
    assert_eq "TP-FIX-05 one JSON object" "1" "${_njson}"
    assert_contains "TP-FIX-05 json type" "${_out}" '"type":"fix-config"'
    assert_contains "TP-FIX-05 json changed" "${_out}" '"changed":"true"'
    assert_contains "TP-FIX-05 json os" "${_out}" '"os":"alpine"'
    _hit=$(_fix_active "${_side}" 'gssapi')
    assert_contains "TP-FIX-05 input stays active" "${_hit}" "GSSAPIAuthentication"
    _hit=$(_fix_active "${_copy}" 'gssapi')
    assert_eq "TP-FIX-05 output has no active GSSAPI" "" "${_hit}"
    assert_contains "TP-FIX-05 output comment" "$(cat "${_copy}")" "    # GSSAPIAuthentication yes"
    assert_contains "TP-FIX-05 output keeps ForwardAgent" "$(cat "${_copy}")" "ForwardAgent yes"
    _mode=$(stat -c '%a' "${_copy}" 2>/dev/null || stat -f '%OLp' "${_copy}")
    assert_eq "TP-FIX-05 output mode 600" "600" "${_mode}"

    # TP-FIX-06 --output-file only reads the default config (auto already commented it)
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_FX}
    HostName ${IP_FX}
    GSSAPIAuthentication yes
    ForwardAgent yes
EOF
    chmod 600 "${CI_HOME}/.ssh/config"
    rm -f "${_copy}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=alpine sh "${SCRIPT}" fix-config --output-file "${_copy}" 2>&1)
    _ec=$?
    assert_eq "TP-FIX-06 output-only exit 0" "0" "${_ec}"
    assert_contains "TP-FIX-06 already matches after auto" "${_out}" "already matches this OS (alpine)."
    _hit=$(_fix_active "${CI_HOME}/.ssh/config" 'gssapi')
    assert_eq "TP-FIX-06 default commented by auto" "" "${_hit}"
    assert_contains "TP-FIX-06 output has the comment" "$(cat "${_copy}")" "# GSSAPIAuthentication yes"
    assert_file_exists "TP-FIX-06 rolling auto backup" "${CI_HOME}/.ssh/config.fix-config.bak"
    _bakhit=$(_fix_active "${CI_HOME}/.ssh/config.fix-config.bak" 'gssapi')
    assert_contains "TP-FIX-06 backup kept the active line" "${_bakhit}" "GSSAPIAuthentication"

    # TP-FIX-07 termux comments algorithm keywords and leaves GSSAPI active
    cat > "${_side}" <<EOF
Host ${H_FX}
    HostName ${IP_FX}
    HostKeyAlgorithms +ssh-rsa
    PubkeyAcceptedAlgorithms +ssh-rsa
    PubkeyAcceptedKeyTypes +ssh-rsa
    GSSAPIAuthentication yes
    ForwardAgent yes
EOF
    chmod 600 "${_side}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=termux sh "${SCRIPT}" fix-config --input-file "${_side}" 2>&1)
    _ec=$?
    assert_eq "TP-FIX-07 termux exit 0" "0" "${_ec}"
    _cfg=$(cat "${_side}")
    _hit=$(_fix_active "${_side}" 'HostKeyAlgorithms')
    assert_eq "TP-FIX-07 no active HostKeyAlgorithms" "" "${_hit}"
    _hit=$(_fix_active "${_side}" 'PubkeyAcceptedAlgorithms')
    assert_eq "TP-FIX-07 no active PubkeyAcceptedAlgorithms" "" "${_hit}"
    _hit=$(_fix_active "${_side}" 'PubkeyAcceptedKeyTypes')
    assert_eq "TP-FIX-07 no active PubkeyAcceptedKeyTypes" "" "${_hit}"
    assert_contains "TP-FIX-07 commented HostKeyAlgorithms" "${_cfg}" "# HostKeyAlgorithms +ssh-rsa"
    assert_contains "TP-FIX-07 commented PubkeyAcceptedAlgorithms" "${_cfg}" "# PubkeyAcceptedAlgorithms +ssh-rsa"
    assert_contains "TP-FIX-07 commented PubkeyAcceptedKeyTypes" "${_cfg}" "# PubkeyAcceptedKeyTypes +ssh-rsa"
    _hit=$(_fix_active "${_side}" 'gssapi')
    assert_contains "TP-FIX-07 GSSAPI stays active on termux" "${_hit}" "GSSAPIAuthentication"
    assert_contains "TP-FIX-07 ForwardAgent stays" "${_cfg}" "ForwardAgent yes"

    # TP-FIX-08 posix comments neither family
    cat > "${_side}" <<EOF
Host ${H_FX}
    HostName ${IP_FX}
    HostKeyAlgorithms +ssh-rsa
    GSSAPIAuthentication yes
    ForwardAgent yes
EOF
    chmod 600 "${_side}"
    _before=$(cat "${_side}")
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=posix sh "${SCRIPT}" fix-config --input-file "${_side}" 2>&1)
    _ec=$?
    assert_eq "TP-FIX-08 posix exit 0" "0" "${_ec}"
    assert_contains "TP-FIX-08 already matches" "${_out}" "already matches this OS (posix)."
    assert_eq "TP-FIX-08 file unchanged" "${_before}" "$(cat "${_side}")"

    # TP-FIX-09 missing file, empty flag, unknown operand
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=posix sh "${SCRIPT}" fix-config --input-file "${CI_HOME}/missing-config" 2>&1)
    _ec=$?
    assert_eq "TP-FIX-09 missing file fails" "1" "${_ec}"
    assert_contains "TP-FIX-09 missing file named" "${_out}" "Cannot read ssh config"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" fix-config --input-file 2>&1)
    _ec=$?
    assert_eq "TP-FIX-09 empty input flag fails" "1" "${_ec}"
    assert_contains "TP-FIX-09 empty input names the flag" "${_out}" "--input-file requires a path"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" fix-config --output-file 2>&1)
    _ec=$?
    assert_eq "TP-FIX-09 empty output flag fails" "1" "${_ec}"
    assert_contains "TP-FIX-09 empty output names the flag" "${_out}" "--output-file requires a path"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" fix-config extra 2>&1)
    _ec=$?
    assert_eq "TP-FIX-09 unknown operand fails" "1" "${_ec}"
    assert_contains "TP-FIX-09 unknown operand named" "${_out}" "Unknown fix-config operand"

    # TP-FIX-10 every run, including version, comments ~/.ssh/config and stays quiet
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_FX}
    HostName ${IP_FX}
    GSSAPIAuthentication yes
    ForwardAgent yes
EOF
    chmod 600 "${CI_HOME}/.ssh/config"
    rm -f "${CI_HOME}/.ssh/config.fix-config.bak"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=alpine sh "${SCRIPT}" version 2>&1)
    _ec=$?
    assert_eq "TP-FIX-10 version exit 0" "0" "${_ec}"
    assert_contains "TP-FIX-10 version text" "${_out}" "${APP_NAME}"
    assert_not_contains "TP-FIX-10 version stays quiet about the comment" "${_out}" "Commented unsupported"
    _hit=$(_fix_active "${CI_HOME}/.ssh/config" 'gssapi')
    assert_eq "TP-FIX-10 version commented GSSAPI" "" "${_hit}"
    assert_contains "TP-FIX-10 ForwardAgent stays" "$(cat "${CI_HOME}/.ssh/config")" "ForwardAgent yes"
    assert_file_exists "TP-FIX-10 auto backup" "${CI_HOME}/.ssh/config.fix-config.bak"
    _stamp=$(stat -c '%Y' "${CI_HOME}/.ssh/config" 2>/dev/null || stat -f '%m' "${CI_HOME}/.ssh/config")
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=alpine sh "${SCRIPT}" version 2>&1)
    assert_eq "TP-FIX-10 second version exit 0" "0" "$?"
    _stamp2=$(stat -c '%Y' "${CI_HOME}/.ssh/config" 2>/dev/null || stat -f '%m' "${CI_HOME}/.ssh/config")
    assert_eq "TP-FIX-10 second version does not rewrite" "${_stamp}" "${_stamp2}"

    # TP-FIX-11 --json version stays one object while the file is commented
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_FX}
    HostName ${IP_FX}
    GSSAPIAuthentication yes
EOF
    chmod 600 "${CI_HOME}/.ssh/config"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=alpine sh "${SCRIPT}" --json version 2>/dev/null)
    _ec=$?
    assert_eq "TP-FIX-11 json version exit 0" "0" "${_ec}"
    _njson=$(printf '%s\n' "${_out}" | grep -c '^{' || true)
    assert_eq "TP-FIX-11 one JSON object" "1" "${_njson}"
    assert_contains "TP-FIX-11 type version" "${_out}" '"type":"version"'
    assert_not_contains "TP-FIX-11 no fix-config object" "${_out}" '"type":"fix-config"'
    _hit=$(_fix_active "${CI_HOME}/.ssh/config" 'gssapi')
    assert_eq "TP-FIX-11 json version still commented" "" "${_hit}"

    # TP-FIX-12 quiet explicit pass still comments and prints no human OK line
    cat > "${_side}" <<EOF
Host ${H_FX}
    HostName ${IP_FX}
    GSSAPIAuthentication yes
EOF
    chmod 600 "${_side}"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=alpine sh "${SCRIPT}" --quiet fix-config --input-file "${_side}" 2>&1)
    _ec=$?
    assert_eq "TP-FIX-12 quiet exit 0" "0" "${_ec}"
    assert_eq "TP-FIX-12 quiet has no human text" "" "${_out}"
    _hit=$(_fix_active "${_side}" 'gssapi')
    assert_eq "TP-FIX-12 quiet still commented" "" "${_hit}"

    # TP-FIX-13 review: termux class comments algorithm lines, dns show stays old-openssh yes
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_FX}
    HostName ${IP_FX}
    HostKeyAlgorithms +ssh-rsa,ssh-dss
    PubkeyAcceptedAlgorithms +ssh-rsa,ssh-dss
EOF
    chmod 600 "${CI_HOME}/.ssh/config"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=termux sh "${SCRIPT}" dns show "${H_FX}" 2>&1)
    _ec=$?
    assert_eq "TP-FIX-13 show exit 0" "0" "${_ec}"
    assert_contains "TP-FIX-13 show old-openssh yes" "${_out}" "old-openssh: yes"
    _hit=$(_fix_active "${CI_HOME}/.ssh/config" 'HostKeyAlgorithms')
    assert_eq "TP-FIX-13 review commented HostKeyAlgorithms" "" "${_hit}"
    assert_contains "TP-FIX-13 comment text remains" "$(cat "${CI_HOME}/.ssh/config")" "# HostKeyAlgorithms +ssh-rsa,ssh-dss"

    # TP-FIX-14 suite source has no dotted IPv4
    _hits=$(grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "${TESTS_ROOT}/test_fix_config.sh" | grep -v '127\.0\.0\.1' || true)
    assert_eq "TP-FIX-14 no IPv4 literals in suite source" "" "${_hits}"

    ci_cleanup_env
}
