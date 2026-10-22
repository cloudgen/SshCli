# =============================================================================
# tests/test_cli.sh — CLI surface (local-only; no network)
# =============================================================================
# Primary REQs: requirement-shell-cli-interface, requirement-shell-cli-zero-arguments,
# requirement-shell-cli-self-install, requirement-shell-cli-default-interaction,
# requirement-shell-cli-language, requirement-shell-output-requirements,
# requirement-shell-cli-storage, requirement-domain-sshd (TP-SSHD-01, TP-SSHD-03..08)
# TP family: TP-CLI-* · TP-SI-01..06 · TP-SSHD-01 · TP-SSHD-03..08 · TP-CLI-22 · TP-CLI-23 · TP-CLI-24
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_cli() {
    t_header "CLI surface (TP-CLI)"

    require_cmd sh
    require_cmd grep

    # TP-CLI-01 syntax
    sh -n "${SCRIPT}"
    assert_eq "TP-CLI-01 sh -n ship unit" 0 "$?"

    # TP-CLI-02 version human
    _out=$(sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-02 version exit 0" 0 "$_ec"
    assert_contains "TP-CLI-02 version mentions app" "$_out" "${APP_NAME}"
    assert_contains "TP-CLI-02 version mentions VERSION" "$_out" "${PRODUCT_VERSION}"

    # TP-CLI-03 version json
    _out=$(sh "${SCRIPT}" --json version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-03 version --json exit 0" 0 "$_ec"
    assert_contains "TP-CLI-03 type version" "$_out" '"type":"version"'
    assert_contains "TP-CLI-03 app field" "$_out" "\"app\":\"${APP_NAME}\""
    assert_contains "TP-CLI-03 version field" "$_out" "\"version\":\"${PRODUCT_VERSION}\""

    # TP-CLI-04 help lists this-login lifecycle + sshd domain; not checksum pin; not trimmed parent domain
    _out=$(SSHD_CLI_LANG=en sh "${SCRIPT}" help 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-04 help exit 0" 0 "$_ec"
    assert_contains "TP-CLI-04 help install" "$_out" "install"
    assert_contains "TP-CLI-04 help self-install" "$_out" "self-install"
    assert_contains "TP-CLI-04 help self-update" "$_out" "self-update"
    assert_contains "TP-CLI-04 help self-uninstall" "$_out" "self-uninstall"
    assert_contains "TP-CLI-04 help version-check" "$_out" "version-check"
    assert_contains "TP-CLI-04 help status" "$_out" "status"
    assert_contains "TP-CLI-04 help start" "$_out" "start"
    assert_contains "TP-CLI-04 help stop" "$_out" "stop"
    assert_contains "TP-CLI-04 help restart" "$_out" "restart"
    assert_contains "TP-CLI-04 help port" "$_out" "port"
    assert_contains "TP-CLI-04 help config" "$_out" "config"
    assert_contains "TP-CLI-04 help host-keys" "$_out" "host-keys"
    assert_contains "TP-CLI-04 help auth-keys" "$_out" "auth-keys"
    assert_contains "TP-CLI-04 help dns" "$_out" "dns"
    assert_contains "TP-CLI-04 help ssh" "$_out" "ssh ["
    assert_contains "TP-CLI-04 help download" "$_out" "download ["
    assert_contains "TP-CLI-04 help upload" "$_out" "upload ["
    assert_contains "TP-CLI-04 help backup-config" "$_out" "backup-config"
    assert_contains "TP-CLI-04 help sync-config" "$_out" "sync-config"
    assert_contains "TP-CLI-04 help sync-from-remote" "$_out" "sync-from-remote"
    assert_contains "TP-CLI-04 help print-sudoers" "$_out" "print-sudoers"
    assert_contains "TP-CLI-04 help generate-sudoer-request" "$_out" "generate-sudoer-request"
    assert_contains "TP-CLI-04 help submit-sudoer-request" "$_out" "submit-sudoer-request"
    assert_contains "TP-CLI-04 help menu" "$_out" "menu"
    assert_contains "TP-CLI-04 help wake-lock" "$_out" "wake-lock"
    assert_contains "TP-CLI-04 help wake-unlock" "$_out" "wake-unlock"
    assert_contains "TP-CLI-04 help --json" "$_out" "--json"
    assert_not_contains "TP-CLI-04 no backup verb" "$_out" "backup <"
    assert_not_contains "TP-CLI-04 no restore verb" "$_out" "restore <"
    assert_not_contains "TP-CLI-04 no CHECKSUM" "$_out" "CHECKSUM"
    assert_contains "TP-CLI-04 help lists BASHRC" "$_out" "BASHRC"
    assert_contains "TP-CLI-18 help testers heading" "$_out" "Tests (local folder; not install):"
    assert_contains "TP-CLI-18 help lists rc-test" "$_out" "rc-test"
    assert_not_contains "TP-CLI-18 rc-test not under Self-management block only" "$_out" "  rc-test              Place"

    # TP-CLI-05 help json
    _out=$(sh "${SCRIPT}" --json help 2>/dev/null)
    assert_eq "TP-CLI-05 help --json exit 0" 0 "$?"
    assert_contains "TP-CLI-05 help json success" "$_out" '"type":"success"'

    # TP-CLI-06 about json storage, no channel, no domain backup fields
    _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-06 about --json exit 0" 0 "$_ec"
    assert_contains "TP-CLI-06 type about" "$_out" '"type":"about"'
    assert_contains "TP-CLI-06 cache_used" "$_out" '"cache_used"'
    assert_contains "TP-CLI-06 cache_preferred" "$_out" '"cache_preferred"'
    assert_contains "TP-CLI-06 cache_fallback" "$_out" '"cache_fallback"'
    assert_contains "TP-CLI-06 cache_fallback_2" "$_out" '"cache_fallback_2"'
    assert_contains "TP-CLI-06 persistence_storage" "$_out" '"persistence_storage"'
    assert_contains "TP-CLI-06 effective_storage" "$_out" '"effective_storage"'
    _hum=$(SSHD_CLI_LANG=en sh "${SCRIPT}" about 2>/dev/null)
    assert_contains "TP-CLI-06 human Cache folder used" "$_hum" "Cache folder used:"
    assert_contains "TP-CLI-06 human Cache folder preferred" "$_hum" "Cache folder (preferred):"
    assert_contains "TP-CLI-06 human Cache folder 1st fallback" "$_hum" "Cache folder (1st fallback):"
    assert_contains "TP-CLI-06 human Cache folder 2nd fallback" "$_hum" "Cache folder (2nd fallback):"
    assert_contains "TP-CLI-06 human Persistence storage" "$_hum" "Persistence storage:"
    assert_not_contains "TP-CLI-06 no Storage (effective) label" "$_hum" "Storage (effective)"
    assert_not_contains "TP-CLI-06 no Storage (fallback) label" "$_hum" "Storage (fallback)"
    assert_not_contains "TP-CLI-06 no backup_notation" "$_out" '"backup_notation"'
    assert_not_contains "TP-CLI-06 no deposit_dir" "$_out" '"deposit_dir"'
    assert_not_contains "TP-CLI-06 no restore_host_default" "$_out" '"restore_host_default"'
    assert_not_contains "TP-CLI-06 no CHECKSUM" "$_out" "CHECKSUM"
    assert_contains "TP-CLI-06 sshd_platform" "$_out" '"sshd_platform"'

    # TP-CLI-07 empty argv non-interactive = Type O CLI self-install (not help, not menu)
    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-07 empty argv exit 0" 0 "$_ec"
    assert_file_exists "TP-CLI-07 empty argv installed binary" "${CI_USER_BIN}/${APP_NAME}"
    assert_not_contains "TP-CLI-07 empty argv is not help" "$_out" "Usage:"
    assert_not_contains "TP-CLI-07 empty argv is not menu" "$_out" "Choose a number"
    ci_cleanup_env

    # TP-SI-01 script $0 copies without download (dead SCRIPT_URL)
    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" SCRIPT_URL="http://127.0.0.1:1/no-such-${APP_NAME}" sh "${SCRIPT}" self-install 2>&1)
    _ec=$?
    assert_eq "TP-SI-01 self-install copy exit 0" 0 "$_ec"
    assert_file_exists "TP-SI-01 binary at USER_BIN" "${CI_USER_BIN}/${APP_NAME}"
    assert_contains "TP-SI-01 copy from local script" "$_out" "Installing from local script"
    assert_not_contains "TP-SI-01 no companion download" "$_out" "Companion link:"
    assert_not_contains "TP-SI-01 no payload start message" "$_out" "Starting installation of"

    # TP-SI-02 local dest mode 0700
    _mode=$(stat -c '%a' "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || stat -f '%OLp' "${CI_USER_BIN}/${APP_NAME}" 2>/dev/null || echo "")
    case "${_mode}" in
        700|0700) assert_eq "TP-SI-02 local dest mode 0700" "0700" "0700" ;;
        *) assert_eq "TP-SI-02 local dest mode 0700" "0700" "${_mode}" ;;
    esac

    # TP-SI-05 already-installed no-op
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" sh "${SCRIPT}" self-install 2>&1)
    _ec=$?
    assert_eq "TP-SI-05 second self-install exit 0" 0 "$_ec"
    assert_contains "TP-SI-05 already installed" "$_out" "already installed"
    ci_cleanup_env

    # TP-SI-03 NI empty argv is self-install (copy), not payload install
    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" SCRIPT_URL="http://127.0.0.1:1/no-such-${APP_NAME}" sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-SI-03 empty argv copy exit 0" 0 "$_ec"
    assert_file_exists "TP-SI-03 empty argv placed binary" "${CI_USER_BIN}/${APP_NAME}"
    assert_contains "TP-SI-03 empty argv self-install banner" "$_out" "Starting self-install"
    assert_not_contains "TP-SI-03 empty argv is not payload install banner" "$_out" "Starting installation of"
    assert_not_contains "TP-SI-03 empty argv is not menu" "$_out" "Choose a number"
    ci_cleanup_env

    # TP-SI-04 interpreter $0 (stdin pipe) uses channel download
    ci_isolated_env
    _out=$(cat "${SCRIPT}" | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" SCRIPT_URL="file://${REPO_ROOT}/sshd-cli" sh 2>&1)
    _ec=$?
    assert_eq "TP-SI-04 pipe self-install exit 0" 0 "$_ec"
    assert_file_exists "TP-SI-04 pipe placed binary" "${CI_USER_BIN}/${APP_NAME}"
    assert_contains "TP-SI-04 pipe uses companion download" "$_out" "Companion link:"
    ci_cleanup_env

    # TP-SI-06 help lists self-install (also TP-CLI-04)
    _out=$(SSHD_CLI_LANG=en sh "${SCRIPT}" help 2>/dev/null)
    assert_contains "TP-SI-06 help lists self-install" "$_out" "self-install"

    # TP-CLI-14 empty argv interactive (TTY=1) = domain menu, not install
    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" </dev/null 2>&1)
    _ec=$?
    assert_eq "TP-CLI-14 interactive empty argv exit 0" 0 "$_ec"
    assert_contains "TP-CLI-14 interactive empty argv shows menu" "$_out" "Choose a number"
    assert_contains "TP-CLI-14 interactive empty argv client-side" "$_out" "client-side"
    assert_contains "TP-CLI-14 interactive empty argv server-side" "$_out" "server-side"
    assert_contains "TP-CLI-14 interactive empty argv self-management" "$_out" "self-management"
    assert_contains "TP-CLI-14 interactive empty argv Exit 9" "$_out" "9. Exit"
    assert_contains "TP-CLI-14 front language row" "$_out" "language"
    assert_contains "TP-CLI-14 front language long" "$_out" "display language for this menu"
    assert_contains "TP-CLI-14 front sudoers row 5" "$_out" "5."
    assert_contains "TP-CLI-14 front self row 6" "$_out" "6."
    assert_contains "TP-CLI-14 front language row 7" "$_out" "7."
    assert_not_contains "TP-CLI-14 front board has no row 8" "$_out" "8."
    assert_contains "TP-CLI-14 front sudoers short" "$_out" "sudoers"
    assert_not_contains "TP-CLI-14 POSIX front has no sudoers hide line" "$_out" "sudoers not available"
    assert_not_contains "TP-CLI-14 front board has no dns row 5" "$_out" "5. SSH names"
    assert_not_contains "TP-CLI-14 front board has no backup-config row" "$_out" "backup-config"
    _out=$(printf '%s\n' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-14 client dns row 11" "$_out" "11."
    assert_contains "TP-CLI-14 client dns short" "$_out" "dns"
    assert_contains "TP-CLI-14 client ssh row 12" "$_out" "12."
    assert_contains "TP-CLI-14 client download row 13" "$_out" "13."
    assert_contains "TP-CLI-14 client upload row 14" "$_out" "14."
    assert_contains "TP-CLI-14 client upload short" "$_out" "upload"
    assert_contains "TP-CLI-14 client backup-config row 15" "$_out" "15."
    assert_contains "TP-CLI-14 client sync-config row 16" "$_out" "16."
    assert_not_contains "TP-CLI-14 client has no sudoers row 17" "$_out" "17."
    assert_contains "TP-CLI-14 client Back 0" "$_out" "0. Back"
    assert_not_contains "TP-CLI-14 no numbered port row" "$_out" "Show listen port"
    assert_not_contains "TP-CLI-14 no numbered config row" "$_out" "Show sshd config"
    assert_not_contains "TP-CLI-14 no numbered host-keys row" "$_out" "List host keys"
    assert_not_contains "TP-CLI-14 no numbered auth-keys row" "$_out" "List login keys"
    assert_file_missing "TP-CLI-14 interactive empty argv does not install" "${CI_USER_BIN}/${APP_NAME}"
    assert_not_contains "TP-CLI-14 interactive empty argv is not help Usage" "$_out" "Usage:"
    ci_cleanup_env

    # TP-CLI-23 zero-cli-verb: a switch is not a verb
    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" --debug </dev/null 2>&1)
    _ec=$?
    assert_eq "TP-CLI-23 TTY --debug exit 0" 0 "$_ec"
    assert_contains "TP-CLI-23 TTY --debug shows menu" "$_out" "Choose a number"
    assert_contains "TP-CLI-23 TTY --debug client-side" "$_out" "client-side"
    assert_file_missing "TP-CLI-23 TTY --debug does not install" "${CI_USER_BIN}/${APP_NAME}"
    assert_not_contains "TP-CLI-23 TTY --debug is not help" "$_out" "Usage:"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" --force </dev/null 2>&1)
    _ec=$?
    assert_eq "TP-CLI-23 TTY --force exit 0" 0 "$_ec"
    assert_contains "TP-CLI-23 TTY --force shows menu" "$_out" "Choose a number"
    assert_file_missing "TP-CLI-23 TTY --force does not install" "${CI_USER_BIN}/${APP_NAME}"
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" SCRIPT_URL="http://127.0.0.1:1/no-such-${APP_NAME}" sh "${SCRIPT}" --quiet 2>&1)
    _ec=$?
    assert_eq "TP-CLI-23 --quiet exit 0" 0 "$_ec"
    assert_file_exists "TP-CLI-23 --quiet placed binary" "${CI_USER_BIN}/${APP_NAME}"
    assert_not_contains "TP-CLI-23 --quiet is not help" "$_out" "Usage:"
    assert_not_contains "TP-CLI-23 --quiet is not menu" "$_out" "Choose a number"
    ci_cleanup_env

    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" SCRIPT_URL="http://127.0.0.1:1/no-such-${APP_NAME}" sh "${SCRIPT}" --json 2>&1)
    _ec=$?
    assert_eq "TP-CLI-23 --json exit 0" 0 "$_ec"
    assert_file_exists "TP-CLI-23 --json placed binary" "${CI_USER_BIN}/${APP_NAME}"
    assert_contains "TP-CLI-23 --json success" "$_out" '"type":"out_success"'
    assert_not_contains "TP-CLI-23 --json is not help" "$_out" "Usage:"
    assert_not_contains "TP-CLI-23 --json is not menu" "$_out" "Choose a number"
    ci_cleanup_env

    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" SCRIPT_URL="http://127.0.0.1:1/no-such-${APP_NAME}" TTY=1 sh "${SCRIPT}" --json </dev/null 2>&1)
    _ec=$?
    assert_eq "TP-CLI-23 TTY --json exit 0" 0 "$_ec"
    assert_file_exists "TP-CLI-23 TTY --json placed binary" "${CI_USER_BIN}/${APP_NAME}"
    assert_not_contains "TP-CLI-23 TTY --json is not menu" "$_out" "Choose a number"
    ci_cleanup_env

    ci_isolated_env
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" SCRIPT_URL="http://127.0.0.1:1/no-such-${APP_NAME}" sh "${SCRIPT}" --debug 2>&1)
    _ec=$?
    assert_eq "TP-CLI-23 non-TTY --debug exit 0" 0 "$_ec"
    assert_file_exists "TP-CLI-23 non-TTY --debug placed binary" "${CI_USER_BIN}/${APP_NAME}"
    assert_contains "TP-CLI-23 non-TTY --debug self-install banner" "$_out" "Starting self-install"
    assert_not_contains "TP-CLI-23 non-TTY --debug is not help" "$_out" "Usage:"
    assert_not_contains "TP-CLI-23 non-TTY --debug is not menu" "$_out" "Choose a number"
    ci_cleanup_env

    _out=$(sh "${SCRIPT}" --debug status 2>&1)
    assert_contains "TP-CLI-23 --debug status is status" "$_out" "Connect:"
    assert_not_contains "TP-CLI-23 --debug status is not menu" "$_out" "Choose a number"

    # TP-CLI-21 TTY 62 / typed version run about; argv version stays thin (INC-20260914-001)
    ci_isolated_env
    _out=$(printf '%s\n' '6' '62' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-21 TTY 62 exit 0" 0 "$_ec"
    assert_contains "TP-CLI-21 TTY 62 about title" "$_out" "About / Diagnostics"
    assert_contains "TP-CLI-21 TTY 62 current user" "$_out" "Current user:"
    assert_contains "TP-CLI-21 TTY 62 useful commands" "$_out" "Useful commands:"
    assert_not_contains "TP-CLI-21 TTY 62 is not thin version banner" "$_out" "${APP_NAME} version ${PRODUCT_VERSION}"
    _out=$(printf '%s\n' '6' 'version' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-21 typed version exit 0" 0 "$_ec"
    assert_contains "TP-CLI-21 typed version about title" "$_out" "About / Diagnostics"
    assert_contains "TP-CLI-21 typed version current user" "$_out" "Current user:"
    _out=$(sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-21 argv version exit 0" 0 "$_ec"
    assert_contains "TP-CLI-21 argv version mentions VERSION" "$_out" "${PRODUCT_VERSION}"
    assert_not_contains "TP-CLI-21 argv version is not about title" "$_out" "About / Diagnostics"
    _out=$(sh "${SCRIPT}" --json version 2>/dev/null)
    assert_contains "TP-CLI-21 argv version json type" "$_out" '"type":"version"'
    _src=$(cat "${SCRIPT}")
    assert_contains "TP-CLI-21 menu 62 routes about" "${_src}" '62|version)'
    assert_contains "TP-CLI-21 typed version routes about" "${_src}" 'version) app_about'
    unset _src
    ci_cleanup_env

    # TP-CLI-22 finished TTY leaf redisplays the front board (not the submenu)
    ci_isolated_env
    _out=$(printf '%s\n' '6' '62' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-22 6 then 62 then Exit 9 exit 0" 0 "$_ec"
    assert_contains "TP-CLI-22 62 ran about" "$_out" "About / Diagnostics"
    _n=$(t_count_substr "$_out" " — self-management")
    assert_eq "TP-CLI-22 self-management board once" "1" "$_n"
    _n=$(t_count_substr "$_out" "client-side")
    assert_eq "TP-CLI-22 front board after 62" "2" "$_n"
    _out=$(printf '%s\n' '2' '21' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-22 2 then 21 then Exit 9 exit 0" 0 "$_ec"
    assert_contains "TP-CLI-22 21 ran status" "$_out" "Connect:"
    _n=$(t_count_substr "$_out" " — server-side")
    assert_eq "TP-CLI-22 server-side board once" "1" "$_n"
    _n=$(t_count_substr "$_out" "client-side")
    assert_eq "TP-CLI-22 front board after 21" "2" "$_n"
    _out=$(printf '%s\n' 'about' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-22 typed about then Exit 9 exit 0" 0 "$_ec"
    assert_contains "TP-CLI-22 typed about ran" "$_out" "About / Diagnostics"
    _n=$(t_count_substr "$_out" "client-side")
    assert_eq "TP-CLI-22 front board after typed about" "2" "$_n"
    unset _out _ec _n
    ci_cleanup_env

    # TP-CLI-24 menu 7 language: English first, then speaker order, file, restore
    ci_isolated_env
    _out=$(printf '%s\n' '7' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 open language then Back exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 front language long" "$_out" "display language for this menu"
    assert_contains "TP-CLI-24 language row 71" "$_out" "71."
    assert_contains "TP-CLI-24 language English" "$_out" "English"
    assert_contains "TP-CLI-24 language row 72" "$_out" "72."
    assert_contains "TP-CLI-24 language Simplified Chinese" "$_out" "简体中文"
    assert_contains "TP-CLI-24 language Simplified Chinese long" "$_out" "use Simplified Chinese for this menu"
    assert_contains "TP-CLI-24 language row 73" "$_out" "73."
    assert_contains "TP-CLI-24 language Traditional Chinese" "$_out" "繁體中文"
    assert_contains "TP-CLI-24 language Traditional Chinese long" "$_out" "use Traditional Chinese for this menu"
    assert_contains "TP-CLI-24 language row 74" "$_out" "74."
    assert_contains "TP-CLI-24 language Spanish" "$_out" "Español"
    assert_contains "TP-CLI-24 language row 75" "$_out" "75."
    assert_contains "TP-CLI-24 language Arabic" "$_out" "العربية"
    assert_contains "TP-CLI-24 language row 76" "$_out" "76."
    assert_contains "TP-CLI-24 language French" "$_out" "Français"
    assert_contains "TP-CLI-24 language row 77" "$_out" "77."
    assert_contains "TP-CLI-24 language Portuguese" "$_out" "Português"
    assert_contains "TP-CLI-24 language row 78" "$_out" "78."
    assert_contains "TP-CLI-24 language Russian" "$_out" "Русский"
    assert_contains "TP-CLI-24 language row 79" "$_out" "79."
    assert_contains "TP-CLI-24 language German" "$_out" "Deutsch"
    assert_contains "TP-CLI-24 language row 80" "$_out" "80."
    assert_contains "TP-CLI-24 language Japanese" "$_out" "日本語"
    assert_contains "TP-CLI-24 language row 81" "$_out" "81."
    assert_contains "TP-CLI-24 language Korean" "$_out" "한국어"
    assert_contains "TP-CLI-24 language row 82" "$_out" "82."
    assert_contains "TP-CLI-24 language Dutch" "$_out" "Nederlands"
    assert_contains "TP-CLI-24 language row 83" "$_out" "83."
    assert_contains "TP-CLI-24 language Greek" "$_out" "Ελληνικά"
    assert_contains "TP-CLI-24 front language row 7" "$_out" "7."
    assert_not_contains "TP-CLI-24 no reserved row 70" "$_out" "70."
    assert_not_contains "TP-CLI-24 no reserved row 84" "$_out" "84."
    assert_not_contains "TP-CLI-24 no reserved row 89" "$_out" "89."
    assert_contains "TP-CLI-24 language Back" "$_out" "0. Back"
    assert_file_missing "TP-CLI-24 Back does not write language" "${CI_HOME}/.local/${APP_NAME}/language"
    _out=$(printf '%s\n' '7' '70' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-24 reserved 70 warns" "$_out" "Unknown menu choice '70'"
    assert_file_missing "TP-CLI-24 reserved 70 does not write language" "${CI_HOME}/.local/${APP_NAME}/language"
    _out=$(printf '%s\n' '7' '84' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-24 reserved 84 warns" "$_out" "Unknown menu choice '84'"
    assert_file_missing "TP-CLI-24 reserved 84 does not write language" "${CI_HOME}/.local/${APP_NAME}/language"
    _out=$(printf '%s\n' '7' '89' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-24 reserved 89 warns" "$_out" "Unknown menu choice '89'"
    assert_file_missing "TP-CLI-24 reserved 89 does not write language" "${CI_HOME}/.local/${APP_NAME}/language"
    _out=$(printf '%s\n' '8' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-24 front 8 warns" "$_out" "Unknown menu choice '8'"
    assert_not_contains "TP-CLI-24 front 8 does not open language rows" "$_out" "71."
    assert_file_missing "TP-CLI-24 front 8 does not write language" "${CI_HOME}/.local/${APP_NAME}/language"
    _out=$(printf '%s\n' '7' '72' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose Simplified Chinese exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 Simplified Chinese saved" "$_out" "菜单语言是简体中文"
    assert_contains "TP-CLI-24 front redraws in Simplified Chinese" "$_out" "客户端"
    assert_contains "TP-CLI-24 Simplified Chinese Exit" "$_out" "9. 离开"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is zh-Hans" "zh-Hans" "${_lang}"
    _out=$(printf '%s\n' '7' '73' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose Traditional Chinese exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 Traditional Chinese saved" "$_out" "選單語言是繁體中文"
    assert_contains "TP-CLI-24 front redraws in Traditional Chinese" "$_out" "用戶端"
    assert_contains "TP-CLI-24 Traditional Chinese Exit" "$_out" "9. 離開"
    assert_contains "TP-CLI-24 Traditional Chinese prompt" "$_out" "請輸入編號，或輸入指令名稱："
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is zh-Hant" "zh-Hant" "${_lang}"
    _mode=$(stat -c '%a' "${CI_HOME}/.local/${APP_NAME}/language" 2>/dev/null || stat -f '%OLp' "${CI_HOME}/.local/${APP_NAME}/language")
    assert_eq "TP-CLI-24 language file mode 600" "600" "${_mode}"
    _out=$(printf '%s\n' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-24 next run stays Traditional Chinese" "$_out" "用戶端"
    assert_not_contains "TP-CLI-24 next run is not English client-side" "$_out" "client-side"
    _out=$(printf '%s\n' '7' '71' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose English exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 English saved" "$_out" "Menu language is English"
    assert_contains "TP-CLI-24 front redraws in English" "$_out" "client-side"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is en" "en" "${_lang}"
    _out=$(printf '%s\n' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-24 next run stays English" "$_out" "client-side"
    assert_not_contains "TP-CLI-24 next run is not Traditional Chinese client" "$_out" "用戶端"
    _out=$(printf '%s\n' '7' '74' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose Spanish exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 Spanish saved" "$_out" "El idioma del menú es español"
    assert_contains "TP-CLI-24 Spanish Exit" "$_out" "9. Salir"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is es" "es" "${_lang}"
    _out=$(printf '%s\n' '7' '75' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose Arabic exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 Arabic saved" "$_out" "لغة القائمة هي العربية"
    assert_contains "TP-CLI-24 Arabic Exit" "$_out" "9. خروج"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is ar" "ar" "${_lang}"
    _out=$(printf '%s\n' '7' '76' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose French exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 French saved" "$_out" "La langue du menu est le français"
    assert_contains "TP-CLI-24 French Exit" "$_out" "9. Quitter"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is fr" "fr" "${_lang}"
    _out=$(printf '%s\n' '7' '77' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose Portuguese exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 Portuguese saved" "$_out" "O idioma do menu é português"
    assert_contains "TP-CLI-24 Portuguese Exit" "$_out" "9. Sair"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is pt" "pt" "${_lang}"
    _out=$(printf '%s\n' '7' '78' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose Russian exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 Russian saved" "$_out" "Язык меню — русский"
    assert_contains "TP-CLI-24 Russian Exit" "$_out" "9. Выход"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is ru" "ru" "${_lang}"
    _out=$(printf '%s\n' '7' '79' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose German exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 German saved" "$_out" "Die Menüsprache ist Deutsch"
    assert_contains "TP-CLI-24 German Exit" "$_out" "9. Beenden"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is de" "de" "${_lang}"
    _out=$(printf '%s\n' '7' '80' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose Japanese exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 Japanese saved" "$_out" "メニューの言語は日本語"
    assert_contains "TP-CLI-24 Japanese Exit" "$_out" "9. 終了"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is ja" "ja" "${_lang}"
    _out=$(printf '%s\n' '7' '81' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose Korean exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 Korean saved" "$_out" "메뉴 언어는 한국어"
    assert_contains "TP-CLI-24 Korean Exit" "$_out" "9. 종료"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is ko" "ko" "${_lang}"
    _out=$(printf '%s\n' '7' '82' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose Dutch exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 Dutch saved" "$_out" "De menutaal is Nederlands"
    assert_contains "TP-CLI-24 Dutch Exit" "$_out" "9. Afsluiten"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is nl" "nl" "${_lang}"
    _out=$(printf '%s\n' '7' '83' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-CLI-24 choose Greek exit 0" 0 "$_ec"
    assert_contains "TP-CLI-24 Greek saved" "$_out" "Η γλώσσα του μενού είναι ελληνικά"
    assert_contains "TP-CLI-24 Greek Exit" "$_out" "9. Έξοδος"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 file is el" "el" "${_lang}"
    printf '%s\n' 'nope' > "${CI_HOME}/.local/${APP_NAME}/language"
    _out=$(printf '%s\n' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u SSHD_CLI_LANG sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-24 unrecognized file is English" "$_out" "client-side"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 unrecognized file is left as written" "nope" "${_lang}"
    printf '%s\n' 'en' > "${CI_HOME}/.local/${APP_NAME}/language"
    _out=$(printf '%s\n' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 SSHD_CLI_LANG=zh-Hant sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-24 SSHD_CLI_LANG overrides the file" "$_out" "用戶端"
    printf '%s\n' 'en' > "${CI_HOME}/.local/${APP_NAME}/language"
    _out=$(printf '%s\n' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 SSHD_CLI_LANG=es sh "${SCRIPT}" 2>&1)
    assert_contains "TP-CLI-24 SSHD_CLI_LANG=es overrides the file" "$_out" "idioma"
    _lang=$(head -n 1 "${CI_HOME}/.local/${APP_NAME}/language" | tr -d '\r')
    assert_eq "TP-CLI-24 SSHD_CLI_LANG does not rewrite the file" "en" "${_lang}"
    _out=$(SSHD_CLI_LANG=ja sh "${SCRIPT}" help 2>&1)
    assert_contains "TP-CLI-24 Japanese help heading" "$_out" "使い方:"
    assert_not_contains "TP-CLI-24 Japanese help is not Usage" "$_out" "Usage:"
    assert_contains "TP-CLI-24 Japanese help keeps status" "$_out" "status"
    _out=$(SSHD_CLI_LANG=ko sh "${SCRIPT}" help 2>&1)
    assert_contains "TP-CLI-24 Korean help heading" "$_out" "사용법:"
    assert_not_contains "TP-CLI-24 Korean help is not Usage" "$_out" "Usage:"
    _out=$(SSHD_CLI_LANG=ja sh "${SCRIPT}" about 2>/dev/null)
    assert_contains "TP-CLI-24 Japanese about title" "$_out" "概要 / 診断"
    assert_contains "TP-CLI-24 Japanese about cache" "$_out" "使用中のキャッシュフォルダ"
    assert_not_contains "TP-CLI-24 Japanese about is not About / Diagnostics" "$_out" "About / Diagnostics"
    _out=$(SSHD_CLI_LANG=ko sh "${SCRIPT}" about 2>/dev/null)
    assert_contains "TP-CLI-24 Korean about title" "$_out" "개요 / 진단"
    assert_contains "TP-CLI-24 Korean about cache" "$_out" "사용 중인 캐시 폴더"
    assert_not_contains "TP-CLI-24 Korean about is not About / Diagnostics" "$_out" "About / Diagnostics"
    _out=$(SSHD_CLI_LANG=en sh "${SCRIPT}" help 2>/dev/null)
    assert_contains "TP-CLI-24 English help still says Usage" "$_out" "Usage:"
    assert_contains "TP-CLI-24 English help names Japanese" "$_out" "80 Japanese"
    assert_contains "TP-CLI-24 English help names Korean" "$_out" "81 Korean"
    assert_contains "TP-CLI-24 English help names Simplified Chinese" "$_out" "72 Simplified Chinese"
    assert_contains "TP-CLI-24 English help tests heading" "$_out" "Tests (local folder; not install):"
    unset _out _ec _lang _mode
    ci_cleanup_env

    # TP-CLI-15 status ends with a recommended ssh connect line
    _out=$(sh "${SCRIPT}" status 2>&1)
    _ec=$?
    assert_eq "TP-CLI-15 status exit 0" 0 "$_ec"
    assert_contains "TP-CLI-15 status Connect line" "$_out" "Connect:"
    assert_contains "TP-CLI-15 status ssh -p" "$_out" "ssh -p"
    assert_not_contains "TP-CLI-15 no placeholder host" "$_out" "<this-host>"
    case "${_out}" in
        *@*.*.*.*) t_pass "TP-CLI-15 connect uses dotted-quad IPv4" ;;
        *) t_fail "TP-CLI-15 connect uses dotted-quad IPv4 (got '$(_trunc "${_out}")')" ;;
    esac
    _json=$(sh "${SCRIPT}" --json status 2>/dev/null)
    assert_contains "TP-CLI-15 json connect field" "$_json" '"connect":"ssh -p'

    # TP-CLI-08 unknown command fail-closed
    _err=$(sh "${SCRIPT}" no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CLI-08 unknown exit 1" 1 "$_ec"
    assert_contains "TP-CLI-08 unknown error text" "$_err" "Unknown command"

    _err=$(sh "${SCRIPT}" --json no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-CLI-08 unknown --json exit 1" 1 "$_ec"
    assert_contains "TP-CLI-08 unknown --json type" "$_err" '"type":"out_error"'

    # TP-CLI-09 quiet suppresses version info
    _out=$(sh "${SCRIPT}" --quiet version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-09 quiet version exit 0" 0 "$_ec"
    _trim=$(printf '%s' "$_out" | tr -d ' \t\n\r')
    if [ -z "$_trim" ]; then
        t_pass "TP-CLI-09 quiet suppresses human version"
    else
        t_fail "TP-CLI-09 quiet expected empty stdout, got '$(_trunc "$_out")'"
    fi

    # TP-CLI-10 self-update / version-check are routed (known commands); skip network
    _err=$(sh "${SCRIPT}" self-update 2>&1 >/dev/null)
    _ec=$?
    if printf '%s' "$_err" | grep -q "Unknown command"; then
        t_fail "TP-CLI-10 self-update must be a known command"
    else
        t_pass "TP-CLI-10 self-update is a known command (exit ${_ec})"
    fi
    _err=$(sh "${SCRIPT}" version-check 2>&1 >/dev/null)
    _ec=$?
    if printf '%s' "$_err" | grep -q "Unknown command"; then
        t_fail "TP-CLI-10 version-check must be a known command"
    else
        t_pass "TP-CLI-10 version-check is a known command (exit ${_ec})"
    fi

    # TP-CLI-11 set -u HOME unset still works for version
    _out=$(env -u HOME sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-11 env -u HOME version exit 0" 0 "$_ec"
    assert_contains "TP-CLI-11 env -u HOME version text" "$_out" "${PRODUCT_VERSION}"

    # TP-CLI-12 cache isolation under temp HOME (per login + process id)
    ci_isolated_env
    _login=$(id -un 2>/dev/null || echo "unknown")
    _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" sh "${SCRIPT}" --json about 2>/dev/null)
    assert_contains "TP-CLI-12 isolated about has app in cache" "$_out" "${APP_NAME}"
    _pref=$(printf '%s' "$_out" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
    _pid="${_pref##*-}"
    case "${_pref}" in
        /dev/shm/cache/cache-"${APP_NAME}"-"${_login}"-[0-9]*)
            t_pass "TP-CLI-12 cache_preferred is shm login process leaf"
            ;;
        *) t_fail "TP-CLI-12 cache_preferred unexpected: '${_pref:-empty}'" ;;
    esac
    _fb=$(printf '%s' "$_out" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
    assert_eq "TP-CLI-12 cache_fallback 1st" "/tmp/cache/cache-${APP_NAME}-${_login}-${_pid}" "${_fb}"
    _fb2=$(printf '%s' "$_out" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
    assert_eq "TP-CLI-12 cache_fallback 2nd" "${CI_HOME}/.cache/cache-${APP_NAME}-${_pid}" "${_fb2}"
    _used=$(printf '%s' "$_out" | sed -n 's/.*"cache_used":"\([^"]*\)".*/\1/p' | head -n1)
    _eff=$(printf '%s' "$_out" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
    assert_eq "TP-CLI-12 cache_used matches effective" "${_eff}" "${_used}"
    if [ -n "$_eff" ] && [ -d "$_eff" ]; then
        t_pass "TP-CLI-12 effective cache directory exists"
    else
        t_fail "TP-CLI-12 effective cache missing: '${_eff:-empty}'"
    fi
    case "${_eff}" in
        /dev/shm/"${APP_NAME}"|/dev/shm/"${APP_NAME}"-*)
            t_fail "TP-CLI-12 effective cache must not be ram-drive project shape: '${_eff}'"
            ;;
        *) t_pass "TP-CLI-12 effective cache is not a ram-drive project shape" ;;
    esac
    _err=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" SSHD_CLI_CACHE_SKIP=preferred \
        sh "${SCRIPT}" about 2>&1 >/dev/null)
    assert_not_contains "TP-CLI-12 silent cache fallback" "${_err}" "fallback"
    assert_not_contains "TP-CLI-12 silent cache fallback error" "${_err}" "Cannot create cache"
    _skip=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" SSHD_CLI_CACHE_SKIP=preferred \
        sh "${SCRIPT}" --json about 2>/dev/null)
    _skip_eff=$(printf '%s' "$_skip" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
    _skip_fb=$(printf '%s' "$_skip" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
    assert_eq "TP-CLI-12 skipped preferred uses 1st fallback" "${_skip_fb}" "${_skip_eff}"
    _gb=$(HOME="${CI_HOME}" SSHD_CLI_CACHE_HOST=gitbash sh "${SCRIPT}" --json about 2>/dev/null)
    _gb_pref=$(printf '%s' "$_gb" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
    _gb_pid="${_gb_pref##*-}"
    assert_eq "TP-CLI-12 gitbash preferred" "/tmp/cache/cache-${APP_NAME}-${_login}-${_gb_pid}" "${_gb_pref}"
    _gb_fb=$(printf '%s' "$_gb" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
    assert_eq "TP-CLI-12 gitbash 1st fallback" "${CI_HOME}/AppData/Local/Temp/cache-${APP_NAME}-${_gb_pid}" "${_gb_fb}"
    assert_contains "TP-CLI-12 gitbash json has cache_fallback_2" "${_gb}" '"cache_fallback_2":""'
    _gb_fb2=$(printf '%s' "$_gb" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
    assert_eq "TP-CLI-12 gitbash no 2nd fallback" "" "${_gb_fb2}"
    _mac=$(HOME="${CI_HOME}" SSHD_CLI_CACHE_HOST=mac sh "${SCRIPT}" --json about 2>/dev/null)
    _mac_pref=$(printf '%s' "$_mac" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
    _mac_pid="${_mac_pref##*-}"
    assert_eq "TP-CLI-12 mac preferred" "/tmp/cache/cache-${APP_NAME}-${_login}-${_mac_pid}" "${_mac_pref}"
    _mac_fb=$(printf '%s' "$_mac" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
    assert_eq "TP-CLI-12 mac 1st fallback" "${CI_HOME}/Library/Caches/cache-${APP_NAME}-${_mac_pid}" "${_mac_fb}"
    _mac_fb2=$(printf '%s' "$_mac" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
    assert_eq "TP-CLI-12 mac 2nd fallback" "${CI_HOME}/cache/cache-${APP_NAME}-${_mac_pid}" "${_mac_fb2}"
    _mode=$(stat -c %a "${_eff}" 2>/dev/null || echo "")
    assert_eq "TP-CLI-12 effective cache mode 0700" "700" "${_mode}"
    _hum_l=$(HOME="${CI_HOME}" sh "${SCRIPT}" about 2>/dev/null)
    assert_contains "TP-CLI-12 linux about used" "${_hum_l}" "Cache folder used:"
    assert_contains "TP-CLI-12 linux about preferred path" "${_hum_l}" "/dev/shm/cache/cache-${APP_NAME}-${_login}-"
    assert_contains "TP-CLI-12 linux about 2nd path" "${_hum_l}" "/.cache/cache-${APP_NAME}-"
    _hum_gb=$(HOME="${CI_HOME}" SSHD_CLI_CACHE_HOST=gitbash sh "${SCRIPT}" about 2>/dev/null)
    assert_contains "TP-CLI-12 gitbash about 1st" "${_hum_gb}" "AppData/Local/Temp/cache-${APP_NAME}-"
    assert_not_contains "TP-CLI-12 gitbash about omits 2nd" "${_hum_gb}" "Cache folder (2nd fallback)"
    _hum_mac=$(HOME="${CI_HOME}" SSHD_CLI_CACHE_HOST=mac sh "${SCRIPT}" about 2>/dev/null)
    assert_contains "TP-CLI-12 mac about 1st" "${_hum_mac}" "Library/Caches/cache-${APP_NAME}-"
    assert_contains "TP-CLI-12 mac about 2nd path" "${_hum_mac}" "Cache folder (2nd fallback): ${CI_HOME}/cache/cache-${APP_NAME}-"
    _persist=$(printf '%s' "$_out" | sed -n 's/.*"persistence_storage":"\([^"]*\)".*/\1/p' | head -n1)
    assert_eq "TP-CLI-12 persistence_storage path" "${CI_HOME}/.local/${APP_NAME}" "$_persist"
    if [ -n "$_persist" ] && [ -d "$_persist" ]; then
        t_pass "TP-CLI-12 persistence storage directory exists"
    else
        t_fail "TP-CLI-12 persistence storage missing: '${_persist:-empty}'"
    fi
    case "${_persist}" in
        */.local/bin|*/.local/bin/) t_fail "TP-CLI-12 persistence must not be USER_BIN: '${_persist}'" ;;
        *) t_pass "TP-CLI-12 persistence is not the install bin directory" ;;
    esac
    ci_cleanup_env

    # TP-CLI-19 Git Bash: preferred /tmp/cache mkdir fail-soft → AppData leaf; no ERROR
    ci_isolated_env
    mkdir -p "${CI_HOME}/AppData/Local/Temp"
    _stub="${CI_HOME}/stubbin"
    mkdir -p "${_stub}"
    _real_mkdir=$(command -v mkdir)
    printf '%s\n' '#!/bin/sh' \
        "REAL_MKDIR='${_real_mkdir}'" \
        'for _a in "$@"; do' \
        '  case "${_a}" in' \
        '    /tmp/cache|/tmp/cache/*) exit 1 ;;' \
        '  esac' \
        'done' \
        'exec "${REAL_MKDIR}" "$@"' > "${_stub}/mkdir"
    chmod +x "${_stub}/mkdir"
    _combined=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${_stub}:${PATH}" MSYSTEM=MINGW54 env -u TERMUX_VERSION sh "${SCRIPT}" --json about 2>&1)
    _ec=$?
    assert_eq "TP-CLI-19 git-bash tmp fail-soft exit 0" 0 "$_ec"
    assert_not_contains "TP-CLI-19 no cache ERROR" "${_combined}" "Cannot create cache"
    assert_not_contains "TP-CLI-19 no WARN on skipped tier" "${_combined}" "[WARN]"
    assert_not_contains "TP-CLI-19 no ERROR tag on skipped tier" "${_combined}" "[ERROR]"
    assert_contains "TP-CLI-19 uses AppData Local Temp leaf" "${_combined}" "AppData/Local/Temp/cache-${APP_NAME}-"
    _eff=$(printf '%s' "${_combined}" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
    if [ -n "${_eff}" ] && [ -d "${_eff}" ]; then
        t_pass "TP-CLI-19 git-bash effective_storage directory exists"
    else
        t_fail "TP-CLI-19 git-bash effective_storage missing: '${_eff:-empty}'"
    fi
    case "${_eff}" in
        "${CI_HOME}/AppData/Local/Temp/cache-${APP_NAME}-"[0-9]*)
            t_pass "TP-CLI-19 git-bash effective is AppData home leaf"
            ;;
        *) t_fail "TP-CLI-19 git-bash effective is AppData home leaf (got '${_eff:-empty}')" ;;
    esac
    unset _stub _real_mkdir _combined _ec _eff
    ci_cleanup_env

    # TP-CLI-20 static: resolver names the new chains; no mid-chain mkdir die
    _src=$(cat "${SCRIPT}")
    assert_contains "TP-CLI-20 resolver names Git Bash Temp" "${_src}" 'AppData/Local/Temp'
    assert_contains "TP-CLI-20 resolver names /dev/shm/cache" "${_src}" '/dev/shm/cache/'
    assert_contains "TP-CLI-20 resolver names Mac Library Caches" "${_src}" 'Library/Caches'
    assert_contains "TP-CLI-20 volatile leaf names cache-app-login" "${_src}" 'cache-${APP_NAME}-'
    assert_contains "TP-CLI-20 fail-soft helper present" "${_src}" 'util_cache_try_dir'
    assert_contains "TP-CLI-20 closed failure names cache folder" "${_src}" 'Cannot create cache folder'
    assert_not_contains "TP-CLI-20 no mid-chain mkdir die" "${_src}" 'out_die "Cannot create storage directory ${_storage_candidate}"'
    assert_not_contains "TP-CLI-20 no STORAGE_DIR next step" "${_src}" 'set STORAGE_DIR to a writable folder'
    assert_not_contains "TP-CLI-20 old fail-soft helper gone" "${_src}" 'util_try_mkdir_storage'
    unset _src

    # TP-CLI-13 trimmed parent folder-archive / setup verbs fail closed
    for _verb in backup restore setup; do
        _err=$(sh "${SCRIPT}" "${_verb}" 2>&1 >/dev/null)
        _ec=$?
        assert_eq "TP-CLI-13 ${_verb} exit 1" 1 "$_ec"
        assert_contains "TP-CLI-13 ${_verb} unknown" "$_err" "Unknown command"
    done

    # TP-SSHD-01 start is OpenSSH daemonize; no service-manager verbs
    _src=$(cat "${SCRIPT}")
    assert_contains "TP-SSHD-01 launch is sshd -f config" "$_src" '"${SSHD_BIN}" -f "${SSHD_CONFIG}"'
    assert_not_contains "TP-SSHD-01 no foreground -D launch" "$_src" '"${SSHD_BIN}" -D'
    assert_not_contains "TP-SSHD-01 no -f -D launch" "$_src" '"${SSHD_BIN}" -f "${SSHD_CONFIG}" -D'
    _out=$(SSHD_CLI_LANG=en sh "${SCRIPT}" help 2>&1)
    assert_eq "TP-SSHD-01 help exit 0" 0 "$?"
    assert_contains "TP-SSHD-01 help start is background daemon" "$_out" "background daemon"
    assert_contains "TP-SSHD-01 help names systemctl on Linux unit path" "$_out" "systemctl start"
    assert_not_contains "TP-SSHD-01 help no termux-services" "$_out" "termux-services"
    assert_not_contains "TP-SSHD-01 help no sv-enable" "$_out" "sv-enable"
    assert_not_contains "TP-SSHD-01 help no add-crontab" "$_out" "add-crontab"
    assert_not_contains "TP-SSHD-01 help no enable-service" "$_out" "enable-service"
    unset _src _out
    # TP-SSHD-03 POSIX Linux non-root TTY server submenu hides 22/23/24; INFO names OS; status stays 21
    ci_isolated_env
    _uid=$(id -u 2>/dev/null || echo 1)
    if [ "${_uid}" -eq 0 ]; then
        t_skip "TP-SSHD-03 non-root POSIX hide (suite running as root)"
        t_skip "TP-SSHD-05 hidden choice 2 unknown retry (suite running as root)"
    else
        _out=$(printf '%s\n' '2' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME sh "${SCRIPT}" 2>&1)
        _ec=$?
        assert_eq "TP-SSHD-03 non-root POSIX menu exit 0" 0 "$_ec"
        assert_contains "TP-SSHD-03 non-root INFO" "$_out" "start/stop/restart sshd features are not available for non-root in "
        assert_contains "TP-SSHD-03 status row 21" "$_out" "21."
        assert_contains "TP-SSHD-03 status short" "$_out" "status"
        assert_not_contains "TP-SSHD-03 no start row 22" "$_out" "22. "
        assert_contains "TP-SSHD-03 server Back 0" "$_out" "0. Back"
        _out=$(printf '%s\n' '2' '22' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME sh "${SCRIPT}" 2>&1)
        _ec=$?
        assert_eq "TP-SSHD-05 hidden 22 then Back then Exit 9 exit 0" 0 "$_ec"
        assert_contains "TP-SSHD-05 hidden 22 unknown" "$_out" "Unknown menu choice '22'"
        _n=$(t_count_substr "$_out" "Choose a number, or type the command name:")
        if [ "${_n}" -ge 2 ]; then
            t_pass "TP-SSHD-05 hidden 22 redisplays menu"
        else
            t_fail "TP-SSHD-05 hidden 22 redisplays menu (prompts=${_n})"
        fi
        assert_not_contains "TP-SSHD-05 hidden 22 did not start" "$_out" "Re-run as root"
    fi
    ci_cleanup_env
    unset _uid _out _ec _n

    # TP-SSHD-16 TTY unknown token warns and redisplays; then Exit
    ci_isolated_env
    _out=$(printf '%s\n' 'xyz' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 env -u TERMUX_VERSION -u MSYSTEM -u WSL_DISTRO_NAME sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-SSHD-16 unknown then Exit 9 exit 0" 0 "$_ec"
    assert_contains "TP-SSHD-16 unknown token named" "$_out" "Unknown menu choice 'xyz'"
    _n=$(t_count_substr "$_out" "Choose a number, or type the command name:")
    assert_eq "TP-SSHD-16 redisplays menu" "2" "$_n"
    assert_contains "TP-SSHD-16 still lists client-side" "$_out" "client-side"
    ci_cleanup_env
    unset _out _ec _n

    # TP-SSHD-04 Termux mock TTY menu still shows 2/3/4; no non-root INFO
    ci_isolated_env
    _out=$(printf '%s\n' '2' '0' '1' '0' '9' | HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" TTY=1 TERMUX_VERSION=1 sh "${SCRIPT}" 2>&1)
    _ec=$?
    assert_eq "TP-SSHD-04 Termux menu exit 0" 0 "$_ec"
    assert_contains "TP-SSHD-04 start row 22" "$_out" "22."
    assert_contains "TP-SSHD-04 stop row 23" "$_out" "23."
    assert_contains "TP-SSHD-04 restart row 24" "$_out" "24."
    assert_contains "TP-SSHD-04 dns row 11" "$_out" "11."
    assert_contains "TP-SSHD-04 backup-config INFO" "$_out" "backup-config and sync-config not available for termux"
    assert_contains "TP-SSHD-04 Termux sudoers INFO" "$_out" "sudoers not available for termux"
    assert_not_contains "TP-SSHD-04 Termux omits sudoers row" "$_out" "5. "
    assert_contains "TP-SSHD-04 Termux sync-from-remote row 18" "$_out" "18."
    assert_contains "TP-SSHD-04 Termux Exit 9" "$_out" "9. Exit"
    assert_contains "TP-SSHD-04 Termux still shows language" "$_out" "language"
    assert_not_contains "TP-SSHD-04 no non-root INFO" "$_out" "not available for non-root"
    ci_cleanup_env
    unset _out _ec

    for _verb in systemctl sv-enable enable-service add-crontab; do
        _err=$(sh "${SCRIPT}" "${_verb}" 2>&1 >/dev/null)
        _ec=$?
        assert_eq "TP-SSHD-14 ${_verb} exit 1" 1 "$_ec"
        assert_contains "TP-SSHD-14 ${_verb} unknown" "$_err" "Unknown command"
    done
    unset _verb _err _ec

    # TP-SSHD-06 / TP-SSHD-07 INC-20260908-001: Linux fail-closed copy is host-local
    _src=$(cat "${SCRIPT}")
    assert_not_contains "TP-SSHD-07 no use-Termux on start die" "$_src" "use Termux where sshd runs"
    assert_not_contains "TP-SSHD-07 no use-Termux on stop die" "$_src" "use Termux where sshd belongs"
    assert_not_contains "TP-SSHD-07 writable die is not both platforms" "$_src" "On Linux re-run as root. On Termux"
    assert_contains "TP-SSHD-07 start die names re-run as root" "$_src" "Starting system sshd needs a root login on this host. Re-run as root."
    assert_contains "TP-SSHD-07 stop die names re-run as root" "$_src" "Stopping system sshd needs a root login on this host. Re-run as root."
    # TP-SSHD-17 missing sshd names the family next step and does not run a package tool
    assert_not_contains "TP-SSHD-17 no Debian-only apt hint" "$_src" "On Debian/Ubuntu: apt install openssh-server"
    assert_contains "TP-SSHD-17 linux hint names dnf and apt" "$_src" "dnf on Fedora and RHEL, apt on Debian and Ubuntu"
    assert_contains "TP-SSHD-17 linux hint does not run the tool" "$_src" "does not run that command"
    assert_contains "TP-SSHD-17 Git Bash hint" "$_src" "Git Bash does not provide sshd"
    assert_contains "TP-SSHD-17 Windows cmd hint" "$_src" "Windows cmd does not provide sshd"
    assert_contains "TP-SSHD-17 Mac hint" "$_src" "install the OpenSSH server on this Mac"
    assert_not_contains "TP-SSHD-17 no brew invoke" "$_src" "brew "
    unset _src
    _uid=$(id -u 2>/dev/null || echo 1)
    if [ "${_uid}" -eq 0 ]; then
        t_skip "TP-SSHD-06 non-root POSIX stop error (suite running as root)"
        t_skip "TP-SSHD-08 POSIX start already-running honesty (suite running as root)"
    else
        _err=$(env -u TERMUX_VERSION -u MSYSTEM sh "${SCRIPT}" stop 2>&1)
        _ec=$?
        case "${_err}" in
            *"already stopped"*)
                t_skip "TP-SSHD-06 stop error (sshd already stopped)"
                ;;
            *)
                assert_eq "TP-SSHD-06 non-root stop exit 1" 1 "$_ec"
                assert_contains "TP-SSHD-06 stop names re-run as root" "$_err" "Re-run as root"
                assert_not_contains "TP-SSHD-06 stop error has no Termux" "$_err" "Termux"
                ;;
        esac
        # TP-SSHD-08 INC-20260908-002: POSIX start must not deny systemd for the live pid
        _out=$(env -u TERMUX_VERSION -u MSYSTEM sh "${SCRIPT}" start 2>&1)
        _ec=$?
        case "${_out}" in
            *"already running"*)
                assert_eq "TP-SSHD-08 already-running start exit 0" 0 "$_ec"
                assert_not_contains "TP-SSHD-08 no not-a-systemd" "$_out" "not a systemd"
                assert_not_contains "TP-SSHD-08 no session-daemon claim" "$_out" "for this session"
                assert_not_contains "TP-SSHD-08 no OpenSSH forks itself" "$_out" "OpenSSH forks itself"
                assert_not_contains "TP-SSHD-08 no reboot sshd-cli start" "$_out" "After a reboot, run:"
                assert_contains "TP-SSHD-08 names systemctl" "$_out" "systemctl"
                assert_contains "TP-SSHD-08 names distro unit" "$_out" ".service"
                ;;
            *"needs a root login"*)
                assert_eq "TP-SSHD-08 start fail-closed exit 1" 1 "$_ec"
                assert_contains "TP-SSHD-08 start names re-run as root" "$_out" "Re-run as root"
                assert_not_contains "TP-SSHD-08 start error has no Termux" "$_out" "Termux"
                ;;
            *)
                t_fail "TP-SSHD-08 expected already-running or root fail-closed (got '$(_trunc "${_out}")')"
                ;;
        esac
        unset _err _out _ec
    fi
    unset _uid

    # TP-SSHD-09 / TP-SSHD-10 systemd detect + unit name (read-only)
    _json=$(sh "${SCRIPT}" --json about 2>/dev/null)
    if [ -d /run/systemd/system ] && command -v systemctl >/dev/null 2>&1; then
        assert_contains "TP-SSHD-09 posix about sshd_systemd true" "$_json" '"sshd_systemd":"true"'
        case "${_json}" in
            *"\"sshd_unit\":\"ssh.service\""*|*"\"sshd_unit\":\"sshd.service\""*)
                t_pass "TP-SSHD-10 about names ssh.service or sshd.service"
                ;;
            *)
                t_fail "TP-SSHD-10 about names ssh.service or sshd.service (got '$(_trunc "${_json}")')"
                ;;
        esac
    else
        assert_contains "TP-SSHD-09 posix about sshd_systemd false (no systemd runtime)" "$_json" '"sshd_systemd":"false"'
        t_skip "TP-SSHD-10 unit name (no systemd runtime)"
    fi
    _json=$(TERMUX_VERSION=1 sh "${SCRIPT}" --json about 2>/dev/null)
    assert_contains "TP-SSHD-09 Termux about sshd_systemd false" "$_json" '"sshd_systemd":"false"'
    unset _json

    _src=$(cat "${SCRIPT}")
    assert_contains "TP-SSHD-11 source systemctl start" "$_src" 'systemctl start "${_unit}"'
    assert_contains "TP-SSHD-12 source systemctl stop" "$_src" 'systemctl stop "${_unit}"'
    assert_contains "TP-SSHD-12 source systemctl restart" "$_src" 'systemctl restart "${_unit}"'
    unset _src

    # TP-SSHD-13 Termux start never invokes systemctl
    ci_isolated_env
    mkdir -p "${CI_HOME}/stubbin"
    printf '%s\n' '#!/bin/sh' "echo \"\$*\" >> \"${CI_HOME}/systemctl-args.log\"" 'exit 0' > "${CI_HOME}/stubbin/systemctl"
    chmod +x "${CI_HOME}/stubbin/systemctl"
    HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" PATH="${CI_HOME}/stubbin:${PATH}" TERMUX_VERSION=1 sh "${SCRIPT}" start >/dev/null 2>&1 || true
    if [ -f "${CI_HOME}/systemctl-args.log" ]; then
        t_fail "TP-SSHD-13 Termux start must not invoke systemctl"
    else
        t_pass "TP-SSHD-13 Termux start must not invoke systemctl"
    fi
    ci_cleanup_env
}
