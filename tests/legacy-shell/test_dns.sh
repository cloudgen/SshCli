# =============================================================================
# tests/test_dns.sh — this login ~/.ssh/config Host list (dns-ip)
# =============================================================================
# Primary REQs: requirement-domain-sshd, requirement-shell-interactive-vs-noninteractive,
# requirement-shell-cli-interface
# TP family: TP-DNS-*
# Host names and IPv4 are minted per run (synthetic-test-fixture; PP-A-26 / PP-C-21).
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

_dns_mint_pool() {
    H_A=$(t_rand_host)
    H_B=$(t_rand_host)
    H_C=$(t_rand_host)
    H_ADD=$(t_rand_host)
    H_TX=$(t_rand_host)
    H_OLD=$(t_rand_host)
    H_ID=$(t_rand_host)
    H_WALK_TX=$(t_rand_host)
    H_WALK_LX=$(t_rand_host)
    H_OLDTX=$(t_rand_host)
    H_RENAME=$(t_rand_host)
    H_ALIAS=$(t_rand_host)
    IP_A=$(t_rand_ip)
    IP_B=$(t_rand_ip)
    IP_C=$(t_rand_ip)
    IP_ADD=$(t_rand_ip)
    IP_SET=$(t_rand_ip)
    IP_TX=$(t_rand_ip)
    IP_OLD=$(t_rand_ip)
    IP_ID=$(t_rand_ip)
    IP_WALK_TX=$(t_rand_ip)
    IP_WALK_LX=$(t_rand_ip)
    IP_OLDTX=$(t_rand_ip)
    IP_MATCH=$(t_rand_ip)
    USER_A=$(t_rand_user)
    USER_ADD=$(t_rand_user)
    USER_WALK=$(t_rand_user)
    _i=1
    while [ "${_i}" -le 10 ]; do
        eval "H_N${_i}=\$(t_rand_host)"
        eval "IP_N${_i}=\$(t_rand_ip)"
        _i=$((_i + 1))
    done
    unset _i
}

_dns_fixture() {
    mkdir -p "${CI_HOME}/.ssh"
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_A}
    HostName ${IP_A}
    Port 8022

Host ${H_B}
    HostName ${IP_B}
    User ${USER_A}

Host *
    StrictHostKeyChecking accept-new
EOF
    chmod 700 "${CI_HOME}/.ssh"
    chmod 600 "${CI_HOME}/.ssh/config"
}

run_test_dns() {
    t_header "dns Host list (TP-DNS)"

    require_cmd sh
    require_cmd awk

    ci_isolated_env
    _dns_mint_pool
    _dns_fixture

    # TP-DNS-01 help lists dns
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" help 2>&1)
    assert_contains "TP-DNS-01 help lists dns" "$_out" "dns ["
    assert_contains "TP-DNS-01 help lists delete" "$_out" "delete"
    assert_contains "TP-DNS-01 help lists unset" "$_out" "unset"

    # TP-DNS-02 numbered list; Host * omitted
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns list 2>&1)
    _ec=$?
    assert_eq "TP-DNS-02 dns list exit 0" 0 "$_ec"
    assert_contains "TP-DNS-02 row 1 first host" "$_out" "1. ${H_A}"
    assert_contains "TP-DNS-02 row 2 second host" "$_out" "2. ${H_B}"
    assert_contains "TP-DNS-02 first ip" "$_out" "${IP_A}"
    assert_not_contains "TP-DNS-02 no wildcard Host *" "$_out" "Host *"
    assert_not_contains "TP-DNS-02 no asterisk row" "$_out" "*  "

    # TP-DNS-03 show: user empty → empty; port set
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show 1 2>&1)
    assert_contains "TP-DNS-03 dns first host" "$_out" "dns:  ${H_A}"
    assert_contains "TP-DNS-03 ip" "$_out" "ip:   ${IP_A}"
    assert_contains "TP-DNS-03 user empty" "$_out" "user: empty"
    assert_contains "TP-DNS-03 port 8022" "$_out" "port: 8022"

    # TP-DNS-04 show by name: empty port displays 22
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_B}" 2>&1)
    assert_contains "TP-DNS-04 user minted" "$_out" "user: ${USER_A}"
    assert_contains "TP-DNS-04 port default 22" "$_out" "port: 22"

    # TP-DNS-05 non-interactive set ip
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns set 1 ip "${IP_SET}" 2>&1)
    _ec=$?
    assert_eq "TP-DNS-05 set ip exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-05 config HostName updated" "$_cfg" "HostName ${IP_SET}"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show 1 2>&1)
    assert_contains "TP-DNS-05 show new ip" "$_out" "ip:   ${IP_SET}"

    # TP-DNS-06 "" clears user
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns set "${H_B}" user '""' 2>&1)
    _ec=$?
    assert_eq "TP-DNS-06 clear user exit 0" 0 "$_ec"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_B}" 2>&1)
    assert_contains "TP-DNS-06 user now empty" "$_out" "user: empty"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_not_contains "TP-DNS-06 User line omitted" "$_cfg" "User ${USER_A}"

    # TP-DNS-07 JSON list
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" --json dns list 2>/dev/null)
    _ec=$?
    assert_eq "TP-DNS-07 json list exit 0" 0 "$_ec"
    assert_contains "TP-DNS-07 type dns_list" "$_out" '"type":"dns_list"'
    assert_contains "TP-DNS-07 items array" "$_out" '"items":['
    assert_contains "TP-DNS-07 first host in json" "$_out" "\"dns\":\"${H_A}\""
    assert_contains "TP-DNS-07 user_display" "$_out" '"user_display":"empty"'

    # TP-DNS-08 edit without TTY fails closed
    _err=$(HOME="${CI_HOME}" env -u INTERACTIVE sh "${SCRIPT}" dns edit 1 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DNS-08 edit non-tty exit 1" 1 "$_ec"
    assert_contains "TP-DNS-08 edit Next dns set" "$_err" "Next:"
    assert_contains "TP-DNS-08 edit names dns set" "$_err" "dns set"

    # TP-DNS-09 unknown n fail-closed
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show 99 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DNS-09 missing n exit 1" 1 "$_ec"
    assert_contains "TP-DNS-09 missing Next list" "$_err" "dns list"

    # TP-DNS-10 add non-interactive
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns add dns "${H_ADD}" ip "${IP_ADD}" port 2200 2>&1)
    _ec=$?
    assert_eq "TP-DNS-10 add exit 0" 0 "$_ec"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns list 2>&1)
    assert_contains "TP-DNS-10 add listed" "$_out" "${H_ADD}"
    assert_contains "TP-DNS-10 add ip" "$_out" "${IP_ADD}"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-10 Host add written" "$_cfg" "Host ${H_ADD}"
    assert_contains "TP-DNS-10 Port 2200 written" "$_cfg" "Port 2200"
    assert_not_contains "TP-DNS-10 no Termux bundle without termux yes" "$_cfg" "ServerAliveInterval"

    # TP-DNS-11 non-interactive dns (no subcommand) lists, no hang
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns 2>&1)
    _ec=$?
    assert_eq "TP-DNS-11 bare dns exit 0" 0 "$_ec"
    assert_contains "TP-DNS-11 bare dns lists first" "$_out" "1. ${H_A}"

    # TP-DNS-12 INTERACTIVE field walk: "" clears ip
    _out=$(HOME="${CI_HOME}" INTERACTIVE=1 sh "${SCRIPT}" dns edit 1 <<EOF
${H_A}
""

EOF
)
    _ec=$?
    assert_eq "TP-DNS-12 interactive edit exit 0" 0 "$_ec"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show 1 2>&1)
    assert_contains "TP-DNS-12 ip cleared to empty" "$_out" "ip:   empty"

    # TP-DNS-13 pick 9 is Host row 9 (not Exit)
    {
        _i=1
        while [ "${_i}" -le 10 ]; do
            eval "_hn=\$H_N${_i}"
            eval "_ip=\$IP_N${_i}"
            printf 'Host %s\n    HostName %s\n\n' "${_hn}" "${_ip}"
            _i=$((_i + 1))
        done
        printf 'Host *\n    StrictHostKeyChecking accept-new\n'
        unset _i _hn _ip
    } > "${CI_HOME}/.ssh/config"
    _out=$(HOME="${CI_HOME}" INTERACTIVE=1 sh "${SCRIPT}" dns <<'EOF'
111
9
EOF
)
    _ec=$?
    assert_eq "TP-DNS-13 pick 9 exit 0" 0 "$_ec"
    assert_contains "TP-DNS-13 action menu Edit" "$_out" "111."
    assert_contains "TP-DNS-13 action menu Edit short" "$_out" "Edit"
    assert_contains "TP-DNS-13 action menu Back 0" "$_out" "0. Back"
    assert_contains "TP-DNS-13 pick 9 shows host" "$_out" "dns:  ${H_N9}"
    assert_contains "TP-DNS-13 pick 9 ip" "$_out" "ip:   ${IP_N9}"
    assert_contains "TP-DNS-13 Host pick leave 0" "$_out" "0. Exit"

    # TP-DNS-14 add inserts before trailing Host *
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_A}
    HostName ${IP_A}

Host *
    User ubuntu
    Port 22
EOF
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns add dns "${H_ADD}" ip "${IP_ADD}" user "${USER_ADD}" port 8022 2>&1)
    _ec=$?
    assert_eq "TP-DNS-14 add before Host * exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    _seq=$(awk '{s=$0; sub(/^[[:space:]]+/,"",s); if (s ~ /^[Hh][Oo][Ss][Tt][[:space:]]/) { sub(/^[Hh][Oo][Ss][Tt][[:space:]]+/, "", s); print s }}' "${CI_HOME}/.ssh/config")
    _nas_line=$(printf '%s\n' "$_seq" | awk -v w="${H_ADD}" '$0==w || $0 ~ "^" w " "{print NR; exit}')
    _star_line=$(printf '%s\n' "$_seq" | awk '/^\*/{print NR; exit}')
    _ok=0
    if [ -n "$_nas_line" ] && [ -n "$_star_line" ] && [ "$_nas_line" -lt "$_star_line" ]; then
        _ok=1
    fi
    assert_eq "TP-DNS-14 add Host line before Host *" 1 "$_ok"
    assert_contains "TP-DNS-14 add user written" "$_cfg" "User ${USER_ADD}"
    assert_contains "TP-DNS-14 add port written" "$_cfg" "Port 8022"

    # TP-DNS-15 extra Host aliases kept on set
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_A} ${H_ALIAS}
    IdentityFile ~/.ssh/id_ed25519
    HostName ${IP_A}
EOF
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns set 1 ip "${IP_SET}" 2>&1)
    _ec=$?
    assert_eq "TP-DNS-15 set ip extra aliases exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-15 Host aliases kept" "$_cfg" "Host ${H_A} ${H_ALIAS}"
    assert_contains "TP-DNS-15 IdentityFile kept" "$_cfg" "IdentityFile ~/.ssh/id_ed25519"
    assert_contains "TP-DNS-15 new ip" "$_cfg" "HostName ${IP_SET}"

    # TP-DNS-16 Keyword=value / Keyword = value parse; set does not corrupt User
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_A}
    HostName=${IP_A}
    User = ${USER_A}
    Port 8022
EOF
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show 1 2>&1)
    assert_contains "TP-DNS-16 show equals-form ip" "$_out" "ip:   ${IP_A}"
    assert_contains "TP-DNS-16 show equals-form user" "$_out" "user: ${USER_A}"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns set 1 ip "${IP_SET}" 2>&1)
    _ec=$?
    assert_eq "TP-DNS-16 set ip equals-form exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-16 HostName canonical" "$_cfg" "HostName ${IP_SET}"
    assert_contains "TP-DNS-16 User kept" "$_cfg" "User ${USER_A}"
    assert_not_contains "TP-DNS-16 no User equals leftover" "$_cfg" "User ="
    assert_not_contains "TP-DNS-16 old HostName= gone" "$_cfg" "HostName=${IP_A}"

    # TP-DNS-17 Match / Include skipped on list
    cat > "${CI_HOME}/.ssh/config" <<EOF
Include /no/such/config
Match host ${H_C}
    HostName ${IP_MATCH}
Host ${H_A}
    HostName ${IP_A}
Host *
    User ubuntu
EOF
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns list 2>&1)
    assert_contains "TP-DNS-17 lists first host" "$_out" "1. ${H_A}"
    assert_not_contains "TP-DNS-17 no Match host" "$_out" "${H_C}"
    assert_not_contains "TP-DNS-17 no Include path" "$_out" "/no/such"
    assert_not_contains "TP-DNS-17 no Host *" "$_out" "*  "

    # TP-DNS-18 after COMMAND=dns, token dns is a field name
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_A}
    HostName ${IP_A}
EOF
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns set 1 dns "${H_RENAME}" 2>&1)
    _ec=$?
    assert_eq "TP-DNS-18 set dns field exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-18 renamed Host" "$_cfg" "Host ${H_RENAME}"
    _first=$(awk '{k=$1; gsub(/[[:space:]]/,"",k); if (tolower(k)=="host") { print $2; exit }}' "${CI_HOME}/.ssh/config")
    assert_eq "TP-DNS-18 first Host pattern is rename" "${H_RENAME}" "$_first"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_RENAME}" 2>&1)
    assert_contains "TP-DNS-18 show by new name" "$_out" "dns:  ${H_RENAME}"

    # TP-DNS-19 add without dns name Next mentions add
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns add ip "${IP_C}" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DNS-19 add missing name exit 1" 1 "$_ec"
    assert_contains "TP-DNS-19 Next dns add" "$_err" "dns add dns"

    # TP-DNS-20 TTY menu row 5 opens the Host list (discoverable dns)
    _dns_fixture
    _out=$(HOME="${CI_HOME}" TTY=1 INTERACTIVE=1 sh "${SCRIPT}" menu <<'EOF'
1
11
0
9
EOF
)
    _ec=$?
    assert_eq "TP-DNS-20 menu 11 exit 0" 0 "$_ec"
    assert_contains "TP-DNS-20 menu lists dns row" "$_out" "11."
    assert_contains "TP-DNS-20 choice 11 lists first host" "$_out" "${H_A}"
    assert_contains "TP-DNS-20 action Edit" "$_out" "111."
    assert_contains "TP-DNS-20 action Add" "$_out" "112."
    assert_contains "TP-DNS-20 action Delete" "$_out" "113."
    assert_contains "TP-DNS-20 action Unset" "$_out" "114."
    assert_contains "TP-DNS-20 action Back 0" "$_out" "0. Back"
    assert_not_contains "TP-DNS-20 context is not Host pick 1." "$_out" "1. ${H_A}"

    # TP-DNS-21 TTY Edit then Host 1 (action menu, not pick-to-update)
    _dns_fixture
    _out=$(HOME="${CI_HOME}" INTERACTIVE=1 sh "${SCRIPT}" dns <<'EOF'
111
1
EOF
)
    _ec=$?
    assert_eq "TP-DNS-21 edit via action menu exit 0" 0 "$_ec"
    assert_contains "TP-DNS-21 action Edit" "$_out" "111."
    assert_contains "TP-DNS-21 Host pick first" "$_out" "1. ${H_A}"
    assert_contains "TP-DNS-21 shows first details" "$_out" "dns:  ${H_A}"

    # TP-DNS-22 non-interactive delete; Host * kept
    _dns_fixture
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns delete 1 2>&1)
    _ec=$?
    assert_eq "TP-DNS-22 delete exit 0" 0 "$_ec"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns list 2>&1)
    assert_not_contains "TP-DNS-22 first host gone" "$_out" "${H_A}"
    assert_contains "TP-DNS-22 second remains" "$_out" "1. ${H_B}"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-22 Host * kept" "$_cfg" "Host *"
    assert_contains "TP-DNS-22 wildcard body kept" "$_cfg" "StrictHostKeyChecking accept-new"
    assert_not_contains "TP-DNS-22 first Host gone from file" "$_cfg" "Host ${H_A}"

    # TP-DNS-23 TTY delete cancel (n)
    _dns_fixture
    _out=$(HOME="${CI_HOME}" TTY=1 INTERACTIVE=1 sh "${SCRIPT}" dns <<'EOF'
113
1
n
EOF
)
    _ec=$?
    assert_eq "TP-DNS-23 delete cancel exit 0" 0 "$_ec"
    assert_contains "TP-DNS-23 cancelled" "$_out" "Delete cancelled"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns list 2>&1)
    assert_contains "TP-DNS-23 first still listed" "$_out" "1. ${H_A}"

    # TP-DNS-24 TTY delete yes
    _dns_fixture
    _out=$(HOME="${CI_HOME}" TTY=1 INTERACTIVE=1 sh "${SCRIPT}" dns <<'EOF'
113
1
y
EOF
)
    _ec=$?
    assert_eq "TP-DNS-24 delete yes exit 0" 0 "$_ec"
    assert_contains "TP-DNS-24 deleted" "$_out" "Deleted Host ${H_A}"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns list 2>&1)
    assert_not_contains "TP-DNS-24 first gone after yes" "$_out" "${H_A}"
    assert_contains "TP-DNS-24 second remains after yes" "$_out" "1. ${H_B}"

    # TP-DNS-25 delete missing n fail-closed
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns delete 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DNS-25 delete missing n exit 1" 1 "$_ec"
    assert_contains "TP-DNS-25 Next dns list" "$_err" "dns list"

    # TP-DNS-26 JSON delete one object; extra aliases on other Host kept
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_A} ${H_ALIAS}
    HostName ${IP_A}
    IdentityFile ~/.ssh/id_ed25519
Host ${H_B}
    HostName ${IP_B}
    User ${USER_A}
Host *
    StrictHostKeyChecking accept-new
EOF
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" --json dns delete 1 2>/dev/null)
    _ec=$?
    assert_eq "TP-DNS-26 json delete exit 0" 0 "$_ec"
    assert_contains "TP-DNS-26 json success type" "$_out" '"type":"out_success"'
    assert_contains "TP-DNS-26 json dns first" "$_out" "\"dns\":\"${H_A}\""
    assert_not_contains "TP-DNS-26 json not a second dns_show" "$_out" '"type":"dns_show"'
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_not_contains "TP-DNS-26 first stanza gone" "$_cfg" "Host ${H_A}"
    assert_contains "TP-DNS-26 second kept" "$_cfg" "Host ${H_B}"
    assert_contains "TP-DNS-26 second User kept" "$_cfg" "User ${USER_A}"
    assert_contains "TP-DNS-26 Host * kept" "$_cfg" "Host *"

    # TP-DNS-27 non-interactive add termux yes writes Port 8022 + keep-alive bundle
    _dns_fixture
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns add dns "${H_TX}" ip "${IP_TX}" termux yes 2>&1)
    _ec=$?
    assert_eq "TP-DNS-27 termux add exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-27 Host termux add" "$_cfg" "Host ${H_TX}"
    assert_contains "TP-DNS-27 Port 8022" "$_cfg" "Port 8022"
    assert_contains "TP-DNS-27 ServerAliveInterval 15" "$_cfg" "ServerAliveInterval 15"
    assert_contains "TP-DNS-27 ServerAliveCountMax 12" "$_cfg" "ServerAliveCountMax 12"
    assert_contains "TP-DNS-27 TCPKeepAlive yes" "$_cfg" "TCPKeepAlive yes"
    assert_contains "TP-DNS-27 IPQoS none" "$_cfg" "IPQoS none"
    assert_contains "TP-DNS-27 Ciphers aes128-ctr,aes256-ctr" "$_cfg" "Ciphers aes128-ctr,aes256-ctr"
    assert_contains "TP-DNS-27 MACs hmac-sha2-256" "$_cfg" "MACs hmac-sha2-256"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_TX}" 2>&1)
    assert_contains "TP-DNS-27 show termux yes" "$_out" "termux: yes"

    # TP-DNS-28 old-openssh yes writes rsa/dss algorithm lines
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns add dns "${H_OLD}" ip "${IP_OLD}" old-openssh yes 2>&1)
    _ec=$?
    assert_eq "TP-DNS-28 old-openssh add exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-28 HostKeyAlgorithms" "$_cfg" "HostKeyAlgorithms +ssh-rsa,ssh-dss"
    assert_contains "TP-DNS-28 PubkeyAcceptedAlgorithms" "$_cfg" "PubkeyAcceptedAlgorithms +ssh-rsa,ssh-dss"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_OLD}" 2>&1)
    assert_contains "TP-DNS-28 show old-openssh yes" "$_out" "old-openssh: yes"

    # TP-DNS-29 identity-file + identities-only
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns add dns "${H_ID}" ip "${IP_ID}" identity-file '~/.ssh/id_ed25519' identities-only yes 2>&1)
    _ec=$?
    assert_eq "TP-DNS-29 identity add exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-29 IdentityFile" "$_cfg" "IdentityFile ~/.ssh/id_ed25519"
    assert_contains "TP-DNS-29 IdentitiesOnly yes" "$_cfg" "IdentitiesOnly yes"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_ID}" 2>&1)
    assert_contains "TP-DNS-29 show identity-file" "$_out" "identity-file: ~/.ssh/id_ed25519"
    assert_contains "TP-DNS-29 show identities-only" "$_out" "identities-only: yes"

    # TP-DNS-30 INTERACTIVE add: default as Termux (Y) + default Old OpenSSH (Y)
    _out=$(HOME="${CI_HOME}" INTERACTIVE=1 sh "${SCRIPT}" dns add <<EOF
${H_WALK_TX}
${IP_WALK_TX}
${USER_WALK}

EOF
)
    _ec=$?
    assert_eq "TP-DNS-30 interactive Termux default exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-30 walk Host" "$_cfg" "Host ${H_WALK_TX}"
    assert_contains "TP-DNS-30 walk Port 8022" "$_cfg" "Port 8022"
    assert_contains "TP-DNS-30 walk ServerAliveInterval" "$_cfg" "ServerAliveInterval 15"
    assert_contains "TP-DNS-30 walk Ciphers" "$_cfg" "Ciphers aes128-ctr,aes256-ctr"
    assert_contains "TP-DNS-30 walk MACs" "$_cfg" "MACs hmac-sha2-256"
    assert_contains "TP-DNS-30 walk HostKeyAlgorithms" "$_cfg" "HostKeyAlgorithms +ssh-rsa,ssh-dss"

    # TP-DNS-31 INTERACTIVE add: Termux n prompts Port; Old OpenSSH n omits algorithms
    _out=$(HOME="${CI_HOME}" INTERACTIVE=1 sh "${SCRIPT}" dns add <<EOF
${H_WALK_LX}
${IP_WALK_LX}
${USER_WALK}
n
2200


n
EOF
)
    _ec=$?
    assert_eq "TP-DNS-31 interactive Termux n exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-31 Host walk linux" "$_cfg" "Host ${H_WALK_LX}"
    assert_contains "TP-DNS-31 Port 2200" "$_cfg" "Port 2200"
    _wl=$(awk -v h="${H_WALK_LX}" 'BEGIN{p=0} $0 ~ "^Host " h "( |$)" {p=1; next} /^Host /{p=0} p{print}' "${CI_HOME}/.ssh/config")
    assert_not_contains "TP-DNS-31 no ServerAlive on Termux n" "$_wl" "ServerAliveInterval"
    assert_not_contains "TP-DNS-31 no Ciphers on Termux n" "$_wl" "Ciphers"
    assert_not_contains "TP-DNS-31 no MACs on Termux n" "$_wl" "MACs"
    assert_not_contains "TP-DNS-31 no HostKeyAlgorithms on old n" "$_wl" "HostKeyAlgorithms"

    # TP-DNS-32 set termux no strips keep-alives; Port stays unless set
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns set "${H_TX}" termux no 2>&1)
    _ec=$?
    assert_eq "TP-DNS-32 set termux no exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    _tp=$(awk -v h="${H_TX}" 'BEGIN{p=0} $0 ~ "^Host " h "( |$)" {p=1; next} /^Host /{p=0} p{print}' "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-32 Port 8022 kept" "$_tp" "Port 8022"
    assert_not_contains "TP-DNS-32 ServerAlive stripped" "$_tp" "ServerAliveInterval"
    assert_not_contains "TP-DNS-32 TCPKeepAlive stripped" "$_tp" "TCPKeepAlive"
    assert_not_contains "TP-DNS-32 Ciphers stripped" "$_tp" "Ciphers"
    assert_not_contains "TP-DNS-32 MACs stripped" "$_tp" "MACs"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_TX}" 2>&1)
    assert_contains "TP-DNS-32 show termux no" "$_out" "termux: no"

    # TP-DNS-33 set old-openssh no strips algorithm lines
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns set "${H_OLD}" old-openssh no 2>&1)
    _ec=$?
    assert_eq "TP-DNS-33 old-openssh no exit 0" 0 "$_ec"
    _ob=$(awk -v h="${H_OLD}" 'BEGIN{p=0} $0 ~ "^Host " h "( |$)" {p=1; next} /^Host /{p=0} p{print}' "${CI_HOME}/.ssh/config")
    assert_not_contains "TP-DNS-33 HostKeyAlgorithms stripped" "$_ob" "HostKeyAlgorithms"
    assert_not_contains "TP-DNS-33 PubkeyAcceptedAlgorithms stripped" "$_ob" "PubkeyAcceptedAlgorithms"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_OLD}" 2>&1)
    assert_contains "TP-DNS-33 show old-openssh no" "$_out" "old-openssh: no"

    # TP-DNS-34 show names identity / termux / old-openssh fields
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_ID}" 2>&1)
    assert_contains "TP-DNS-34 identity-file label" "$_out" "identity-file:"
    assert_contains "TP-DNS-34 identities-only label" "$_out" "identities-only:"
    assert_contains "TP-DNS-34 termux label" "$_out" "termux:"
    assert_contains "TP-DNS-34 old-openssh label" "$_out" "old-openssh:"

    # TP-DNS-35 unknown field fail-closed names the allowed list
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns set 1 not-a-field x 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DNS-35 unknown field exit 1" 1 "$_ec"
    assert_contains "TP-DNS-35 names identity-file" "$_err" "identity-file"
    assert_contains "TP-DNS-35 names termux" "$_err" "termux"
    assert_contains "TP-DNS-35 names old-openssh" "$_err" "old-openssh"

    # TP-DNS-36 keep-alive-only stanza (no simpler Ciphers/MACs) is not the Termux bundle
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_OLDTX}
    HostName ${IP_OLDTX}
    Port 8022
    ServerAliveInterval 15
    ServerAliveCountMax 12
    TCPKeepAlive yes
    IPQoS none
EOF
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_OLDTX}" 2>&1)
    assert_contains "TP-DNS-36 old keep-alives termux no" "$_out" "termux: no"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns set "${H_OLDTX}" termux yes 2>&1)
    _ec=$?
    assert_eq "TP-DNS-36 set termux yes exit 0" 0 "$_ec"
    _ot=$(awk -v h="${H_OLDTX}" 'BEGIN{p=0} $0 ~ "^Host " h "( |$)" {p=1; next} /^Host /{p=0} p{print}' "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-36 Ciphers written" "$_ot" "Ciphers aes128-ctr,aes256-ctr"
    assert_contains "TP-DNS-36 MACs written" "$_ot" "MACs hmac-sha2-256"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_OLDTX}" 2>&1)
    assert_contains "TP-DNS-36 show termux yes after set" "$_out" "termux: yes"

    # TP-DNS-37 last concrete Host delete; stanza gone; Host * if present kept
    cat > "${CI_HOME}/.ssh/config" <<EOF
# synthetic leading comment (not a this-login device)
Host ${H_A}
    HostName ${IP_A}
    User ${USER_A}
    Port 8022
Host *
    StrictHostKeyChecking accept-new
EOF
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns delete 1 2>&1)
    _ec=$?
    assert_eq "TP-DNS-37 last-host delete exit 0" 0 "$_ec"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns list 2>&1)
    assert_not_contains "TP-DNS-37 last host gone from list" "$_out" "${H_A}"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_not_contains "TP-DNS-37 Host stanza gone" "$_cfg" "Host ${H_A}"
    assert_not_contains "TP-DNS-37 HostName gone" "$_cfg" "HostName ${IP_A}"
    assert_not_contains "TP-DNS-37 User gone" "$_cfg" "User ${USER_A}"
    assert_contains "TP-DNS-37 Host * kept after last delete" "$_cfg" "Host *"

    # TP-DNS-39 help lists unset (also covered in TP-DNS-01; keep a dedicated row)
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" help 2>&1)
    assert_contains "TP-DNS-39 help unset operand" "$_out" "unset N field"

    # TP-DNS-40 non-interactive unset user by name; HostName stays
    _dns_fixture
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns unset "${H_B}" user 2>&1)
    _ec=$?
    assert_eq "TP-DNS-40 unset user exit 0" 0 "$_ec"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_B}" 2>&1)
    assert_contains "TP-DNS-40 user now empty" "$_out" "user: empty"
    assert_contains "TP-DNS-40 ip stays" "$_out" "ip:   ${IP_B}"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-40 Host stays" "$_cfg" "Host ${H_B}"
    assert_contains "TP-DNS-40 HostName stays" "$_cfg" "HostName ${IP_B}"
    assert_not_contains "TP-DNS-40 User line omitted" "$_cfg" "User ${USER_A}"

    # TP-DNS-41 refuse unset dns or ip
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns unset "${H_B}" dns 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DNS-41 unset dns exit 1" 1 "$_ec"
    assert_contains "TP-DNS-41 unset dns Next" "$_err" "dns unset"
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns unset "${H_B}" ip 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DNS-41 unset ip exit 1" 1 "$_ec"
    assert_contains "TP-DNS-41 cannot unset identity" "$_err" "Cannot unset dns or ip"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-41 Host still present" "$_cfg" "Host ${H_B}"
    assert_contains "TP-DNS-41 HostName still present" "$_cfg" "HostName ${IP_B}"

    # TP-DNS-42 missing field fail-closed
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns unset "${H_B}" 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DNS-42 missing field exit 1" 1 "$_ec"
    assert_contains "TP-DNS-42 Next names user" "$_err" "dns unset"
    assert_contains "TP-DNS-42 names a field" "$_err" "user"

    # TP-DNS-43 JSON unset one object; stanza kept
    _dns_fixture
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" --json dns unset "${H_B}" user 2>/dev/null)
    _ec=$?
    assert_eq "TP-DNS-43 json unset exit 0" 0 "$_ec"
    assert_contains "TP-DNS-43 json success type" "$_out" '"type":"out_success"'
    assert_contains "TP-DNS-43 json dns name" "$_out" "\"dns\":\"${H_B}\""
    assert_contains "TP-DNS-43 json cleared user" "$_out" '"cleared":"user"'
    assert_not_contains "TP-DNS-43 json not a second object type" "$_out" '"type":"dns_show"'
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-43 Host kept" "$_cfg" "Host ${H_B}"
    assert_not_contains "TP-DNS-43 User omitted" "$_cfg" "User ${USER_A}"

    # TP-DNS-44 TTY action Unset then field pick; HostName stays
    _dns_fixture
    _out=$(HOME="${CI_HOME}" INTERACTIVE=1 sh "${SCRIPT}" dns <<'EOF'
114
2
1
EOF
)
    _ec=$?
    assert_eq "TP-DNS-44 tty unset walk exit 0" 0 "$_ec"
    assert_contains "TP-DNS-44 action Unset" "$_out" "114."
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_B}" 2>&1)
    assert_contains "TP-DNS-44 user cleared" "$_out" "user: empty"
    assert_contains "TP-DNS-44 ip stays after tty unset" "$_out" "ip:   ${IP_B}"

    # TP-DNS-45 unset termux strips bundle; Port and HostName stay
    _dns_fixture
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns add dns "${H_TX}" ip "${IP_TX}" termux yes 2>&1)
    _ec=$?
    assert_eq "TP-DNS-45 termux add for unset exit 0" 0 "$_ec"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns unset "${H_TX}" termux 2>&1)
    _ec=$?
    assert_eq "TP-DNS-45 unset termux exit 0" 0 "$_ec"
    _tp=$(awk -v h="${H_TX}" 'BEGIN{p=0} $0 ~ "^Host " h "( |$)" {p=1; next} /^Host /{p=0} p{print}' "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-45 Port 8022 kept" "$_tp" "Port 8022"
    assert_contains "TP-DNS-45 HostName kept" "$_tp" "HostName ${IP_TX}"
    assert_not_contains "TP-DNS-45 ServerAlive stripped" "$_tp" "ServerAliveInterval"
    assert_not_contains "TP-DNS-45 Ciphers stripped" "$_tp" "Ciphers"
    assert_not_contains "TP-DNS-45 MACs stripped" "$_tp" "MACs"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_TX}" 2>&1)
    assert_contains "TP-DNS-45 show termux no" "$_out" "termux: no"

    # TP-DNS-46 missing n / unknown field fail-closed
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns unset 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DNS-46 missing n exit 1" 1 "$_ec"
    assert_contains "TP-DNS-46 missing n Next" "$_err" "dns unset"
    _err=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns unset "${H_B}" not-a-field 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-DNS-46 unknown field exit 1" 1 "$_ec"
    assert_contains "TP-DNS-46 unknown names user" "$_err" "user"

    # TP-DNS-47 TTY unknown action warns and redisplays
    _dns_fixture
    _out=$(HOME="${CI_HOME}" INTERACTIVE=1 sh "${SCRIPT}" dns 2>&1 <<'EOF'
88
0
EOF
)
    _ec=$?
    assert_eq "TP-DNS-47 unknown action then Back 0 exit 0" 0 "$_ec"
    assert_contains "TP-DNS-47 unknown action named" "$_out" "Unknown dns action '88'"
    _n=$(t_count_substr "$_out" "111.")
    assert_eq "TP-DNS-47 redisplays action menu" "2" "$_n"

    # TP-DNS-48 TTY unknown Host pick warns and redisplays
    _dns_fixture
    _out=$(HOME="${CI_HOME}" INTERACTIVE=1 sh "${SCRIPT}" dns 2>&1 <<'EOF'
111
99
0
EOF
)
    _ec=$?
    assert_eq "TP-DNS-48 unknown Host then leave exit 0" 0 "$_ec"
    assert_contains "TP-DNS-48 unknown Host named" "$_out" "Unknown Host choice '99'"
    _n=$(t_count_substr "$_out" "0. Exit")
    assert_eq "TP-DNS-48 redisplays Host pick" "2" "$_n"

    # TP-DNS-49 TTY unknown extra-settings pick warns and redisplays
    _dns_fixture
    _out=$(HOME="${CI_HOME}" INTERACTIVE=1 sh "${SCRIPT}" dns 2>&1 <<'EOF'
114
2
99
0
EOF
)
    _ec=$?
    assert_eq "TP-DNS-49 unknown extra-settings then leave exit 0" 0 "$_ec"
    assert_contains "TP-DNS-49 unknown extra-settings named" "$_out" "Unknown extra-settings choice '99'"
    _n=$(t_count_substr "$_out" "Choose a number to clear")
    assert_eq "TP-DNS-49 redisplays extra-settings picker" "2" "$_n"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_B}" 2>&1)
    assert_contains "TP-DNS-49 user still set after leave" "$_out" "user: ${USER_A}"

    # TP-DNS-50 Termux old-openssh yes comments the algorithm lines; show stays yes
    _dns_fixture
    _out=$(HOME="${CI_HOME}" TERMUX_VERSION=1 sh "${SCRIPT}" dns add dns "${H_OLD}" ip "${IP_OLD}" old-openssh yes 2>&1)
    _ec=$?
    assert_eq "TP-DNS-50 termux old-openssh add exit 0" 0 "$_ec"
    _ob=$(awk -v h="${H_OLD}" 'BEGIN{p=0} $0 ~ "^Host " h "( |$)" {p=1; next} /^Host /{p=0} p{print}' "${CI_HOME}/.ssh/config")
    assert_contains "TP-DNS-50 commented HostKeyAlgorithms" "${_ob}" "# HostKeyAlgorithms +ssh-rsa,ssh-dss"
    assert_contains "TP-DNS-50 commented PubkeyAcceptedAlgorithms" "${_ob}" "# PubkeyAcceptedAlgorithms +ssh-rsa,ssh-dss"
    _active=$(printf '%s\n' "${_ob}" | grep -E '^[[:space:]]*HostKeyAlgorithms' || true)
    assert_eq "TP-DNS-50 no active HostKeyAlgorithms" "" "${_active}"
    _active=$(printf '%s\n' "${_ob}" | grep -E '^[[:space:]]*PubkeyAcceptedAlgorithms' || true)
    assert_eq "TP-DNS-50 no active PubkeyAcceptedAlgorithms" "" "${_active}"
    _out=$(HOME="${CI_HOME}" TERMUX_VERSION=1 sh "${SCRIPT}" dns show "${H_OLD}" 2>&1)
    assert_contains "TP-DNS-50 show old-openssh yes" "${_out}" "old-openssh: yes"

    # TP-DNS-51 Termux old-openssh no removes the commented lines
    _out=$(HOME="${CI_HOME}" TERMUX_VERSION=1 sh "${SCRIPT}" dns set "${H_OLD}" old-openssh no 2>&1)
    _ec=$?
    assert_eq "TP-DNS-51 termux old-openssh no exit 0" 0 "$_ec"
    _ob=$(awk -v h="${H_OLD}" 'BEGIN{p=0} $0 ~ "^Host " h "( |$)" {p=1; next} /^Host /{p=0} p{print}' "${CI_HOME}/.ssh/config")
    assert_not_contains "TP-DNS-51 comments stripped" "${_ob}" "HostKeyAlgorithms"
    _out=$(HOME="${CI_HOME}" sh "${SCRIPT}" dns show "${H_OLD}" 2>&1)
    assert_contains "TP-DNS-51 show old-openssh no" "${_out}" "old-openssh: no"

    # TP-DNS-52 unsupported keywords: posix keeps GSSAPI; alpine comments it on set/add
    _dns_fixture
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_A}
    HostName ${IP_A}
    GSSAPIAuthentication yes
    ForwardAgent yes
    # GSSAPIAuthentication is unsupported on Alpine

Host *
    GSSAPIAuthentication=no
    GSSAPIDelegateCredentials no
    StrictHostKeyChecking accept-new
EOF
    chmod 600 "${CI_HOME}/.ssh/config"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=posix sh "${SCRIPT}" dns set 1 user "${USER_ADD}" 2>&1)
    _ec=$?
    assert_eq "TP-DNS-52 posix set exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    _hit=$(printf '%s\n' "${_cfg}" | grep -iE '^[[:space:]]*gssapi' || true)
    assert_contains "TP-DNS-52 posix keeps active GSSAPI" "${_hit}" "GSSAPIAuthentication"
    assert_contains "TP-DNS-52 posix keeps Host * GSSAPI" "${_hit}" "GSSAPIDelegateCredentials"
    assert_contains "TP-DNS-52 posix ForwardAgent kept" "${_cfg}" "ForwardAgent yes"
    assert_contains "TP-DNS-52 posix user written" "${_cfg}" "User ${USER_ADD}"
    _dns_fixture
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_A}
    HostName ${IP_A}
    GSSAPIAuthentication yes
    ForwardAgent yes
    # GSSAPIAuthentication is unsupported on Alpine

Host *
    GSSAPIAuthentication=no
    GSSAPIDelegateCredentials no
    StrictHostKeyChecking accept-new
EOF
    chmod 600 "${CI_HOME}/.ssh/config"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=alpine sh "${SCRIPT}" dns set 1 user "${USER_ADD}" 2>&1)
    _ec=$?
    assert_eq "TP-DNS-52 alpine set exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    _hit=$(printf '%s\n' "${_cfg}" | grep -iE '^[[:space:]]*gssapi' || true)
    assert_eq "TP-DNS-52 alpine set has no active GSSAPI" "" "${_hit}"
    assert_contains "TP-DNS-52 alpine set comments the keyword" "${_cfg}" "# GSSAPIAuthentication yes"
    assert_contains "TP-DNS-52 alpine prior comment stays" "${_cfg}" "# GSSAPIAuthentication is unsupported on Alpine"
    assert_contains "TP-DNS-52 alpine ForwardAgent kept" "${_cfg}" "ForwardAgent yes"
    assert_contains "TP-DNS-52 alpine Host * kept" "${_cfg}" "StrictHostKeyChecking accept-new"
    assert_contains "TP-DNS-52 alpine user written" "${_cfg}" "User ${USER_ADD}"
    _dns_fixture
    cat > "${CI_HOME}/.ssh/config" <<EOF
Host ${H_A}
    HostName ${IP_A}
    GSSAPIAuthentication yes

Host *
    StrictHostKeyChecking accept-new
EOF
    chmod 600 "${CI_HOME}/.ssh/config"
    _out=$(HOME="${CI_HOME}" SSHD_CLI_OS=alpine sh "${SCRIPT}" dns add dns "${H_ADD}" ip "${IP_ADD}" 2>&1)
    _ec=$?
    assert_eq "TP-DNS-52 alpine add exit 0" 0 "$_ec"
    _cfg=$(cat "${CI_HOME}/.ssh/config")
    _hit=$(printf '%s\n' "${_cfg}" | grep -iE '^[[:space:]]*gssapi' || true)
    assert_eq "TP-DNS-52 alpine add has no active GSSAPI" "" "${_hit}"
    assert_contains "TP-DNS-52 alpine add keeps the word in a comment" "${_cfg}" "# GSSAPIAuthentication yes"
    assert_contains "TP-DNS-52 new Host present" "${_cfg}" "Host ${H_ADD}"
    assert_contains "TP-DNS-52 new HostName present" "${_cfg}" "HostName ${IP_ADD}"

    # TP-DNS-38 suite source has no dotted IPv4 (mint at run time; PP-C-21)
    _hits=$(grep -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "${TESTS_ROOT}/test_dns.sh" | grep -v '127\.0\.0\.1' || true)
    assert_eq "TP-DNS-38 no IPv4 literals in suite source" "" "${_hits}"

    ci_cleanup_env
}
