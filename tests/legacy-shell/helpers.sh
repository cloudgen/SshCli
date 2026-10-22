# =============================================================================
# tests/helpers.sh — shared assertions for sshd-cli CI tests
# =============================================================================
# Source from test scripts (POSIX /bin/sh). Does not modify product code.
# =============================================================================

# shellcheck disable=SC2034
: "${TESTS_ROOT:=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)}"
: "${REPO_ROOT:=$(CDPATH= cd -- "${TESTS_ROOT}/.." && pwd)}"
: "${SCRIPT:=${REPO_ROOT}/src/sshd-cli}"
: "${APP_NAME:=sshd-cli}"
: "${PASS:=0}"
: "${FAIL:=0}"
: "${SKIP:=0}"

# Product VERSION SSOT from ship unit (keep tests free of frozen semver literals)
PRODUCT_VERSION=$(grep '^VERSION="' "${SCRIPT}" 2>/dev/null | head -n1 | cut -d'"' -f2)
: "${PRODUCT_VERSION:=unknown}"
PRODUCT_APP=$(grep '^APP_NAME="' "${SCRIPT}" 2>/dev/null | head -n1 | cut -d'"' -f2)
: "${PRODUCT_APP:=${APP_NAME}}"
APP_NAME="${PRODUCT_APP}"

# --- output ---
t_info()  { printf '  · %s\n' "$*"; }
t_pass()  { PASS=$((PASS + 1)); printf '  PASS  %s\n' "$*"; }
t_fail()  { FAIL=$((FAIL + 1)); printf '  FAIL  %s\n' "$*" >&2; }
t_skip()  { SKIP=$((SKIP + 1)); printf '  SKIP  %s\n' "$*"; }
t_header() { printf '\n== %s ==\n' "$*"; }

# --- assertions ---
assert_eq() {
    _lab="$1"; _exp="$2"; _act="$3"
    if [ "$_exp" = "$_act" ]; then
        t_pass "$_lab"
    else
        t_fail "$_lab (expected='$(_trunc "$_exp")' actual='$(_trunc "$_act")')"
    fi
}

assert_contains() {
    _lab="$1"; _hay="$2"; _ndl="$3"
    case "$_hay" in
        *"$_ndl"*) t_pass "$_lab" ;;
        *) t_fail "$_lab (missing '$(_trunc "$_ndl")' in '$(_trunc "$_hay")')" ;;
    esac
}

assert_not_contains() {
    _lab="$1"; _hay="$2"; _ndl="$3"
    case "$_hay" in
        *"$_ndl"*) t_fail "$_lab (unexpected '$(_trunc "$_ndl")')" ;;
        *) t_pass "$_lab" ;;
    esac
}

# Count non-overlapping occurrences of a substring (TTY menu reprint proofs).
t_count_substr() {
    _hay="$1"
    _ndl="$2"
    _c=0
    _rest="${_hay}"
    while :; do
        case "${_rest}" in
            *"${_ndl}"*)
                _c=$((_c + 1))
                _rest="${_rest#*"${_ndl}"}"
                ;;
            *)
                break
                ;;
        esac
    done
    printf '%s' "${_c}"
    unset _hay _ndl _c _rest
}

assert_exit() {
    _lab="$1"; _exp="$2"; shift 2
    "$@" >/dev/null 2>&1
    _act=$?
    assert_eq "$_lab" "$_exp" "$_act"
}

assert_file_exists() {
    _lab="$1"; _path="$2"
    if [ -e "$_path" ]; then
        t_pass "$_lab"
    else
        t_fail "$_lab (missing $_path)"
    fi
}

assert_file_missing() {
    _lab="$1"; _path="$2"
    if [ -e "$_path" ]; then
        t_fail "$_lab (still exists: $_path)"
    else
        t_pass "$_lab"
    fi
}

_trunc() {
    printf '%s' "$1" | tr '\n' ' ' | cut -c1-160
}

# Isolated HOME + USER_BIN + GLOBAL_BIN for install tests.
# GLOBAL_BIN is redirected so a host /usr/local/bin install cannot pollute
# uninstall target selection.
# Sets CI_HOME, CI_USER_BIN, CI_GLOBAL_BIN.
# Clears BASHRC so a prior case cannot leak a redirected rc path.
ci_isolated_env() {
    CI_HOME=$(mktemp -d "${TMPDIR:-/tmp}/hm-home.XXXXXX")
    CI_USER_BIN="${CI_HOME}/.local/bin"
    CI_GLOBAL_BIN="${CI_HOME}/.global-bin"
    mkdir -p "${CI_USER_BIN}" "${CI_GLOBAL_BIN}"
    export HOME="${CI_HOME}"
    export USER_BIN="${CI_USER_BIN}"
    export GLOBAL_BIN="${CI_GLOBAL_BIN}"
    # Offline channel: file:// to the in-repo ship unit (no public network)
    SCRIPT_URL="file://${REPO_ROOT}/sshd-cli"
    export SCRIPT_URL
    unset CHECKSUM 2>/dev/null || true
    unset BASHRC 2>/dev/null || true
    CI_BASHRC=
    CI_BASHRC_DIR=
}

# Redirect BASHRC to a file in a random temp folder (not ${HOME}/.bashrc).
# Sets CI_BASHRC_DIR, CI_BASHRC and exports BASHRC.
ci_isolated_bashrc() {
    CI_BASHRC_DIR=$(mktemp -d "${TMPDIR:-/tmp}/hm-bashrc.XXXXXX")
    CI_BASHRC="${CI_BASHRC_DIR}/.bashrc"
    export BASHRC="${CI_BASHRC}"
}

ci_cleanup_bashrc() {
    if [ -n "${CI_BASHRC_DIR:-}" ] && [ -d "${CI_BASHRC_DIR}" ]; then
        rm -rf "${CI_BASHRC_DIR}"
    fi
    CI_BASHRC_DIR=
    CI_BASHRC=
    unset BASHRC 2>/dev/null || true
}

# Exact installer PATH export line written into bashrc.
ci_bashrc_path_line() {
    printf 'export PATH="%s:$PATH"' "${CI_USER_BIN}"
}

ci_cleanup_env() {
    ci_cleanup_bashrc
    if [ -n "${CI_HOME:-}" ] && [ -d "${CI_HOME}" ]; then
        rm -rf "${CI_HOME}"
        CI_HOME=
        CI_USER_BIN=
        CI_GLOBAL_BIN=
    fi
    unset GLOBAL_BIN 2>/dev/null || true
}

# Operator identity captured at source time (before ci_isolated_env).
# Used only to reject minted collisions. MUST NOT print these in assert labels.
: "${T_REAL_HOME:=${HOME}}"
T_REAL_HOSTNAME=$(hostname 2>/dev/null || printf '')

t_byte() {
    _tb=$(od -An -N1 -tu1 /dev/urandom 2>/dev/null | awk '{print $1+0}')
    case "${_tb}" in
        ''|*[!0-9]*) _tb=$(( ($$ + $(date +%s 2>/dev/null || printf '1')) % 256 )) ;;
    esac
    printf '%s' "${_tb}"
}

t_rand_hex8() {
    _hx=$(od -An -N4 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')
    if [ "${#_hx}" -lt 8 ]; then
        _hx=$(printf '%08x' $(( $$ ^ $(date +%s 2>/dev/null || printf '1') )))
    fi
    printf '%s' "${_hx}" | cut -c1-8
}

t_live_ipv4_list() {
    {
        hostname -I 2>/dev/null || true
        ip -4 -o addr show 2>/dev/null | awk '{print $4}' || true
        ifconfig 2>/dev/null | awk '/inet / {print $2}' || true
    } | tr ' ' '\n' | sed 's#/.*##' | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | grep -v '^127\.' || true
}

t_live_ssh_hosts() {
    if [ -n "${T_REAL_HOME}" ] && [ -f "${T_REAL_HOME}/.ssh/config" ]; then
        awk '{
            k=$1
            gsub(/[[:space:]]/,"",k)
            if (tolower(k)=="host") {
                for (i=2; i<=NF; i++) {
                    if ($i !~ /[?*]/) print $i
                }
            }
        }' "${T_REAL_HOME}/.ssh/config" 2>/dev/null || true
    fi
}

t_is_synthetic_host() {
    _syn_h="$1"
    [ -n "${_syn_h}" ] || return 1
    if [ -n "${T_REAL_HOSTNAME}" ] && [ "${_syn_h}" = "${T_REAL_HOSTNAME}" ]; then
        return 1
    fi
    if t_live_ssh_hosts | awk -v w="${_syn_h}" 'BEGIN{f=0} $0==w{f=1} END{exit f?0:1}'; then
        return 1
    fi
    return 0
}

t_is_synthetic_ip() {
    _syn_ip="$1"
    [ -n "${_syn_ip}" ] || return 1
    case "${_syn_ip}" in
        127.*|0.*|255.*) return 1 ;;
    esac
    if t_live_ipv4_list | awk -v w="${_syn_ip}" 'BEGIN{f=0} $0==w{f=1} END{exit f?0:1}'; then
        return 1
    fi
    return 0
}

# Mint a DNS-safe Host pattern (no * / ?). Never this-login hostname or live ssh Host.
t_rand_host() {
    _rh_n=0
    while [ "${_rh_n}" -lt 32 ]; do
        _rh_name="h$(t_rand_hex8)"
        if t_is_synthetic_host "${_rh_name}"; then
            printf '%s' "${_rh_name}"
            return 0
        fi
        _rh_n=$((_rh_n + 1))
    done
    t_fail "t_rand_host could not mint a synthetic Host"
    printf 'hsynth000'
}

# Mint RFC1918 10.a.b.c that is not a live address of this host.
t_rand_ip() {
    _ri_n=0
    while [ "${_ri_n}" -lt 32 ]; do
        _ri_a=$(t_byte); _ri_a=$((_ri_a % 254 + 1))
        _ri_b=$(t_byte); _ri_b=$((_ri_b % 254 + 1))
        _ri_c=$(t_byte); _ri_c=$((_ri_c % 254 + 1))
        _ri_name="10.${_ri_a}.${_ri_b}.${_ri_c}"
        if t_is_synthetic_ip "${_ri_name}"; then
            printf '%s' "${_ri_name}"
            return 0
        fi
        _ri_n=$((_ri_n + 1))
    done
    t_fail "t_rand_ip could not mint a synthetic IPv4"
    printf '%s.%s.%s.%s' 10 254 253 252
}

t_rand_user() {
    printf 'u%s' "$(t_rand_hex8 | cut -c1-6)"
}

ci_run() {
    sh "${SCRIPT}" "$@"
}

ci_capture() {
    _out="$1"; _err="$2"; shift 2
    if [ "$1" = "--" ]; then shift; fi
    "$@" >"$_out" 2>"$_err"
    CI_EXIT=$?
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        t_fail "required command missing: $1"
        return 1
    fi
    return 0
}
