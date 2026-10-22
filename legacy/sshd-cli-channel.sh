#!/bin/sh
# =============================================================================
# sshd-cli - Simplify Termux to install sshd
# =============================================================================
#
# Specialized from bootstrap origin selfmanaged (A → B only). Type 0
# install/self-update/self-uninstall inherited; domain prefix sshd_*.
#
# FULL FEATURED SELF-MANAGED PROGRAM (CIAO / CIAO-Lite Compliant)
#
# This is the single executable POSIX /bin/sh implementation of sshd-cli
# (Type 0 lifecycle plus OpenSSH sshd domain: status/start/stop/port/keys).
# Project requirements (docs/requirements/ only — never cite templates here):
# - requirement-shell-cli-interface.md
# - requirement-shell-cli-default-interaction.md (TTY numbered tree 1/2/5/7/8/9)
# - requirement-shell-cli-language.md (menu language: English and Traditional Chinese)
# - requirement-shell-cli-zero-arguments.md  (zero-cli-verb: interactive menu / non-interactive self-install)
# - requirement-shell-cli-self-install.md    (CLI place; copy from script $0; dest 0700/0755)
# - requirement-shell-cli-storage.md         (util_resolve_storage + about fields)
# - requirement-shell-idempotency.md
# - requirement-shell-self-management.md
# - requirement-shell-modular-function-design.md
# - requirement-shell-output-requirements.md
# - requirement-shell-interactive-vs-noninteractive.md
# - requirement-shell-automatic-checksum.md
# - requirement-domain-sshd.md
# - requirement-sshd-config-backup.md
# - requirement-sudoer-json-file.md
# - requirement-three-layer-privilege-model.md
# - requirement-shell-sudo-command.md
# - requirement-shell-script-coding.md
# - requirement-shell-termux-ish.md
# Plus CIAO Protection Zones and "DO NOT MODIFY" rules.
#
# Philosophy: CIAO (Caution • Intentional • Anti-fragile • Over-engineered)
# Single file for curl | sh compatibility.
#
# APP NAME: hard-assign APP_NAME="sshd-cli" (extractor parity with VERSION); optional := default after.
# REPO_USER / REPO_NAME: GitHub owner/repo identity for the install channel.
# SCRIPT_URL: product channel SSOT — composed from repo identity + APP_NAME (raw content URL).
#   Override SCRIPT_URL with env for a full custom channel; or override REPO_* before first use
#   so the composed default follows a fork. Empty SCRIPT_URL disables version-check / self-update network steps.
# BASHRC: interactive rc write path for PATH ensure (default ${HOME}/.bashrc). Override for tests/CI
#   so install can target a temp file instead of this login's real ~/.bashrc.
#
# =============================================================================

set -u  # Treat unset variables as error (defensive)
# Note: We do NOT use set -e globally. We use explicit error handling via out_die.

# =============================================================================
# GLOBAL SAFE DEFAULTS (Single Source of Truth for configuration)
# =============================================================================
# Product identity SSOT (extractors use: grep '^APP_NAME="' / '^VERSION="').
APP_NAME="sshd-cli"
: "${APP_NAME:=sshd-cli}"
: "${APP_DESC:=Simplify Termux to install sshd}"
: "${SHORT_DESCRIPTION:=${APP_DESC}}"
: "${DESCRIPTION:=POSIX /bin/sh CLI: simplify Termux to install and run OpenSSH sshd (status/start/stop/port/keys/dns) plus self-install; Linux host deposit of ~/.ssh/config (backup-config / sync-config / sync-from-remote).}"
# Product version SSOT (semver). Extractors use: grep '^VERSION="'
VERSION="1.35.1"
: "${VERSION:=1.29.0}"

# Runtime flags (safe defaults)
: "${QUIET:=0}"
: "${JSON:=0}"
: "${INTERACTIVE:=0}"
: "${FORCE:=0}"
: "${FORCE_REINSTALL:=0}"
: "${DEBUG:=0}"
: "${TTY:=0}"

# ----------------------------- Safe Variable Defaults ------------------------
if [ -n "${PREFIX-}" ] && [ -d "${PREFIX}/bin" ]; then
    : "${GLOBAL_BIN:=${PREFIX}/bin}"
else
    : "${GLOBAL_BIN:=/usr/local/bin}"
fi
# INC-20260713-001: under set -u, never expand bare ${HOME} before it is set.
# Order: resolve HOME (safe ${HOME-} probes) → then USER_BIN from HOME.
# Prefer existing non-empty HOME; else passwd home (getent / USER); else /tmp.
if [ -z "${HOME-}" ]; then
    _home_resolved=""
    if command -v getent >/dev/null 2>&1; then
        if [ -n "${USER-}" ]; then
            _home_resolved=$(getent passwd "${USER}" 2>/dev/null | cut -d: -f6)
        fi
        if [ -z "${_home_resolved}" ]; then
            _home_resolved=$(getent passwd "$(id -un 2>/dev/null || echo "")" 2>/dev/null | cut -d: -f6)
        fi
    fi
    if [ -z "${_home_resolved}" ] && [ -n "${USER-}" ] && [ -r /etc/passwd ]; then
        _home_resolved=$(awk -F: -v u="${USER}" '$1==u {print $6; exit}' /etc/passwd 2>/dev/null)
    fi
    if [ -n "${_home_resolved}" ] && [ -d "${_home_resolved}" ]; then
        HOME="${_home_resolved}"
    else
        HOME="/tmp"
    fi
    export HOME
    unset _home_resolved
fi
: "${HOME:=/tmp}"
: "${USER_BIN:=${HOME}/.local/bin}"
# Interactive rc write path (PATH ensure). Empty/unset → ${HOME}/.bashrc.
: "${BASHRC:=${HOME}/.bashrc}"
: "${INSTALL_PATH:=${GLOBAL_BIN}/${APP_NAME}}"
# Repository identity → install channel (Option B: raw.githubusercontent.com)
: "${REPO_USER:=cloudgen}"
: "${REPO_NAME:=sshd-cli}"
: "${SCRIPT_URL:=https://raw.githubusercontent.com/${REPO_USER}/${REPO_NAME}/main/${APP_NAME}}"
: "${CHECKSUM:=}"
: "${SSHD_CLI_ROOT:=/var/sshd-cli}"
: "${SSHD_CLI_REMOTE_ROOT:=/var/sshd-cli}"
: "${SSHD_CLI_SCP:=}"
: "${SSHD_CLI_SSH:=}"
: "${ALLOW_TEST_LOCAL_SUDOERS:=0}"
: "${SUBMIT_ACTION:=add}"
: "${SUBMIT_ACTION_EXPLICIT:=0}"
: "${SUBMIT_PURPOSE:=}"
: "${SUDOER_ADM_USER:=sudoer-adm}"
: "${SUDOER_CLI:=}"

[ -t 0 ] && [ -t 1 ] && TTY=1
USERNAME="$(id -un 2>/dev/null || echo "unknown")"
# Privilege SSOT for recommended install path / bin choice (set -u safe).
# Re-detected inside inst_perform_install before mutating INSTALL_PATH.
if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
    IS_ROOT=1
else
    IS_ROOT=0
fi
: "${IS_ROOT:=0}"
: "${SH:=sh}"
# =============================================================================
# out_text() - SINGLE SOURCE OF TRUTH FOR ALL OUTPUT
# =============================================================================
#
# GENERAL PURPOSE:
# Centralized output handler for all human-readable messages.
# Respects --quiet, --json, and TTY detection for colors.
# All user-facing text (out_info, out_success, out_warn, out_error, etc.) MUST go through this
# function to maintain consistency and JSON-mode compatibility.
#
# INTENTIONAL DESIGN:
# This is the single source of truth for all terminal output in the project.
# Never use raw echo/printf for product user messages elsewhere.
#
# PRINTF EXCEPTION (class A – inside output SSOT):
# This function MAY call printf to fd 1/2 for product human messages.
# That is intentional: out_text is the authorized human emitter.
# Other code must not copy these printf lines for banners/status; call out_* instead.
# See requirement-shell-output-requirements.md §2.1.1 (printf exceptions).
#
# Applied exactly as required by requirement-shell-output-requirements.md
# Last reviewed: 2026-07-12
# Lessons Learned (CIAO Reflection):
# 2026-07-12: Quiet mode previously suppressed warnings; requirement says
#             quiet MUST show errors and SHOULD show warnings on stderr.
#             Added out_debug (stderr, DEBUG=1 only, suppressed under JSON).
# 2026-07-12: Documented that not every printf is banned — only product messaging
#             that bypasses this SSOT (return-via-stdout, file I/O, tool pipes allowed).
# =============================================================================
out_text() {
    local level="$1" msg="$2"
    : "${JSON:=0}" : "${QUIET:=0}" : "${DEBUG:=0}"
    # JSON mode: never emit human-readable lines (machines use out_json*)
    [ "${JSON}" -eq 1 ] && return 0

    case "${level}" in
        out_error)
            # Always shown (even under --quiet)
            ;;
        out_warn)
            # Shown under --quiet (diagnostics stay on stderr)
            ;;
        out_debug)
            [ "${DEBUG}" -eq 1 ] || return 0
            ;;
        *)
            [ "${QUIET}" -eq 1 ] && return 0
            ;;
    esac

    local RED='' GREEN='' YELLOW='' BLUE='' NC=''
    [ "${TTY:-0}" -eq 1 ] && [ "${QUIET}" -eq 0 ] && [ "${JSON}" -eq 0 ] && {
        RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
    }

    case "${level}" in
        out_error)   printf >&2 "${RED}[ERROR]${NC} %s\n" "${msg}" ;;
        out_warn)    printf >&2 "${YELLOW}[WARN]${NC} %s\n" "${msg}" ;;
        out_debug)   printf >&2 "${BLUE}[DEBUG]${NC} %s\n" "${msg}" ;;
        out_info)    printf "${GREEN}[INFO]${NC} %s\n" "${msg}" ;;
        out_success) printf "${GREEN}[OK]${NC} %s\n" "${msg}" ;;
        plain)       printf "%s\n" "${msg}" ;;
        plain_n)     printf "%s" "${msg}" ;;
        *)           printf "%s\n" "${msg}" ;;
    esac
}

# =============================================================================
# out_debug() - Debug diagnostics on stderr (DEBUG=1 only; never under --json)
# =============================================================================
out_debug() { out_text out_debug "$*"; }

# =============================================================================
# out_success()
# =============================================================================
#
# GENERAL PURPOSE:
# Convenience wrappers around out_text() for common message types.
# 
# - out_success()   → green [OK]
#
# CRITICAL RULE:
# These are the ONLY allowed ways to produce product user-visible messages
# (see §2.1.1 for non-product printf exceptions: return values, file I/O, pipes).
# All product output must respect --quiet and --json via out_text.
#
# INTENTIONAL DESIGN:
# Short, readable calls throughout the script while keeping all real logic
# inside out_text() as Single Source of Truth.
#
# Last reviewed: 2026-07-12
# =============================================================================
out_success() { out_text out_success "$*"; }

# =============================================================================
# out_info()
# =============================================================================
#
# GENERAL PURPOSE:
# Convenience wrappers around out_text() for common message types.
# 
# - out_info()      → green [INFO]
#
# CRITICAL RULE:
# These are the ONLY allowed ways to produce product user-visible messages
# (see §2.1.1 for non-product printf exceptions: return values, file I/O, pipes).
# All product output must respect --quiet and --json via out_text.
#
# INTENTIONAL DESIGN:
# Short, readable calls throughout the script while keeping all real logic
# inside out_text() as Single Source of Truth.
#
# Last reviewed: 2026-07-12
# =============================================================================
out_info() { out_text out_info "$*"; }

# =============================================================================
# out_warn()
# =============================================================================
#
# GENERAL PURPOSE:
# Convenience wrappers around out_text() for common message types.
# 
# - out_warn()      → yellow [WARN]
#
# CRITICAL RULE:
# These are the ONLY allowed ways to produce product user-visible messages
# (see §2.1.1 for non-product printf exceptions: return values, file I/O, pipes).
# All product output must respect --quiet and --json via out_text.
#
# INTENTIONAL DESIGN:
# Short, readable calls throughout the script while keeping all real logic
# inside out_text() as Single Source of Truth.
#
# Last reviewed: 29 April 2026
# =============================================================================
out_warn() { out_text out_warn "$*"; }

out_error()   { out_text "out_error"   "$*"; }
# =============================================================================
# out_die()
# =============================================================================
#
# GENERAL PURPOSE:
# Convenience wrappers around out_text() for common message types.
# 
# - out_die()       → out_error + exit(1)  (also triggers JSON out_error)
#
# CRITICAL RULE:
# These are the ONLY allowed ways to produce product user-visible messages
# (see §2.1.1 for non-product printf exceptions: return values, file I/O, pipes).
# All product output must respect --quiet and --json via out_text.
#
# INTENTIONAL DESIGN:
# Short, readable calls throughout the script while keeping all real logic
# inside out_text() as Single Source of Truth.
#
# Last reviewed: 29 April 2026
# =============================================================================
out_die() { out_json_error "$*"; out_text out_error "$*"; exit 1; }

# =============================================================================
# out_plain() - Output plain text
# =============================================================================
#
# GENERAL PURPOSE:
# Convenience function to output plain text (no prefix, no color).
# Part of the standardized out_* output system.
#
# CRITICAL RULE:
# All product user-facing text MUST go through the output system.
# (see §2.1.1 for non-product printf exceptions: return values, file I/O, pipes).
#
# INTENTIONAL DESIGN:
# Short, readable call while keeping real logic in out_text().
#
# Last reviewed: 2026-07-12
# =============================================================================

out_plain() {
    out_text plain "$*"
}

# Last updated: 2026-09-14
# Numbered menu row: number + bold short + italic long (TTY SGR 1 / 3;37).
# ALIGNMENT: requirement-shell-cli-default-interaction · requirement-shell-output-requirements
out_menu_choice() {
    _mc_n="${1-}"
    _mc_short="${2-}"
    _mc_long="${3-}"
    : "${JSON:=0}" : "${QUIET:=0}" : "${TTY:=0}"
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        unset _mc_n _mc_short _mc_long
        return 0
    fi
    if [ "${TTY}" -eq 1 ]; then
        printf '%s. \033[1m%s\033[0m: \033[3;37m%s\033[0m\n' "${_mc_n}" "${_mc_short}" "${_mc_long}"
    else
        printf '%s. %s: %s\n' "${_mc_n}" "${_mc_short}" "${_mc_long}"
    fi
    unset _mc_n _mc_short _mc_long
}

# =============================================================================
# out_msg_n() - Output message WITHOUT trailing newline (for interactive prompts)
# =============================================================================
#
# GENERAL PURPOSE:
# Convenience wrapper around out_text() for printing prompts that require
# user input on the SAME line (e.g. "Continue? (y/N)? ").
# Used exclusively by prompt_yes_no() and any future interactive prompts.
#
# CRITICAL RULE:
# This is the ONLY allowed way to produce non-newline product prompt text.
# Return values from prompt_ask use class-B printf (data return), not this helper.
# All product output must respect --quiet and --json (never shown in those modes).
#
# INTENTIONAL DESIGN:
# Short, readable call while keeping real logic in out_text() as Single
# Source of Truth. Uses the existing 'plain_n' level already supported
# by out_text().
#
# CIAO PRINCIPLES APPLIED:
# - Caution: Never breaks prompt flow in non-interactive/curl | sh mode
# - Intentional: Explicitly named for prompt usage (not generic plain_n)
# - Anti-fragile: Works with TTY detection, colors, and JSON/quiet guards
# - Over-protect: Follows exact same pattern as out_plain/out_info/etc.
#
# ALIGNMENT (live requirements only):
# - requirement-shell-output-requirements.md (out_* SSOT, plain_n)
# - requirement-shell-interactive-vs-noninteractive.md (prompt fragments)
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# Designed to be reusable in other CIAO-Lite projects.
#
# Lessons Learned (CIAO Reflection):
# 2026-05-31: Added this missing convenience wrapper after prompt_yes_no()
#             was referencing a non-existent helper. Prevents regression
#             in interactive confirmation flow.
# 2026-07-12: ALIGNMENT corrected to live docs/requirements/ paths only.
#
# Last reviewed: 2026-07-12
# =============================================================================
out_msg_n() { out_text plain_n "$*"; }

# =============================================================================
# out_empty_line()
# =============================================================================
#
# GENERAL PURPOSE:
# Convenience wrappers around out_text() for common message types.
# 
# - out_empty_line() → visual separators
#
# CRITICAL RULE:
# These are the ONLY allowed ways to produce product user-visible messages
# (see §2.1.1 for non-product printf exceptions: return values, file I/O, pipes).
# All product output must respect --quiet and --json via out_text.
#
# INTENTIONAL DESIGN:
# Short, readable calls throughout the script while keeping all real logic
# inside out_text() as Single Source of Truth.
#
# Last reviewed: 29 April 2026
# =============================================================================
out_empty_line() { out_text plain ""; }


# =============================================================================
# out_double_line()
# =============================================================================
#
# GENERAL PURPOSE:
# Convenience wrappers around out_text() for common message types.
# 
# - out_double_line() → visual separators
#
# CRITICAL RULE:
# These are the ONLY allowed ways to produce product user-visible messages
# (see §2.1.1 for non-product printf exceptions: return values, file I/O, pipes).
# All product output must respect --quiet and --json via out_text.
#
# INTENTIONAL DESIGN:
# Short, readable calls throughout the script while keeping all real logic
# inside out_text() as Single Source of Truth.
#
# Last reviewed: 29 April 2026
# =============================================================================
out_double_line() { out_text plain "=================================================="; }

# =============================================================================
# out_json() - JSON output helper
# =============================================================================
#
# GENERAL PURPOSE:
# Emits clean, machine-readable JSON when --json flag is used.
# Used by all command modes that support structured output.
#
# INTENTIONAL DESIGN:
# Keeps JSON output minimal, consistent, and escaped safely.
# Must be used together with out_json_error() for errors.
#
# PRINTF EXCEPTION (class A – inside output SSOT):
# This function MAY printf product JSON to stdout. Nested
# printf|sed is only for field escaping (tool pipe, still SSOT-owned).
# Command logic must not emit JSON with raw printf; call out_json instead.
# See requirement-shell-output-requirements.md §2.1.1.
#
# Last reviewed: 2026-07-12
# =============================================================================

# util_json_escape() - Escape a string for inclusion in a JSON double-quoted value
# GENERAL PURPOSE: Prevent broken machine JSON when values contain " or \.
# Class B helper used only by out_json / out_json_error (not a product message).
util_json_escape() {
    # Escape \, ", and common controls so JSON cannot be broken by newlines/tabs (L-06).
    # awk is POSIX; multi-line values become \n between physical lines.
    printf '%s' "${1-}" | awk '
    {
      line = $0
      gsub(/\\/, "\\\\", line)
      gsub(/"/, "\\\"", line)
      gsub(/\t/, "\\t", line)
      gsub(/\r/, "\\r", line)
      if (NR > 1) printf "\\n"
      printf "%s", line
    }'
}

out_json() {
    [ "${JSON}" -eq 0 ] && return 0
    local type="$1" message="$2" key raw_key; shift 2
    # Success/status JSON on stdout (SSOT-of-stdout; pure for pipes)
    # Escape type, message, and string key/value pairs (M7 / machine contract).
    # Raw nested JSON: key prefixed with "@" → value inserted unquoted (caller builds
    # a complete JSON array/object; key name is without the "@"). Portable SSOT for
    # specialized products that need nested structures (requirement-shell-output-requirements).
    printf '{'
    printf '"type":"%s"' "$(util_json_escape "$type")"
    [ -n "$message" ] && printf ',"message":"%s"' "$(util_json_escape "$message")"
    while [ $# -ge 2 ]; do
        key="$1"
        case "$key" in
            @*)
                raw_key="${key#@}"
                printf ',"%s":%s' "$(util_json_escape "$raw_key")" "$2"
                ;;
            *)
                printf ',"%s":"%s"' "$(util_json_escape "$key")" "$(util_json_escape "$2")"
                ;;
        esac
        shift 2
    done
    printf '}\n'
}

# =============================================================================
# out_json_error() - JSON error on stderr (SSOT-of-stderr)
# =============================================================================
#
# GENERAL PURPOSE:
# Emit a structured error object in JSON mode on **stderr** so success
# consumers can use:  tool --json … > out.json 2> err.log
#
# PRINTF EXCEPTION (class A – inside output SSOT):
# This function MAY printf structured error JSON to stderr (product machine
# channel). Nested printf|sed is escape-only. Callers use out_json_error /
# out_die — never hand-roll JSON with printf in command logic.
# See requirement-shell-output-requirements.md §2.1.1.
#
# Lessons Learned (CIAO Reflection):
# 2026-07-12: Previously delegated to out_json (stdout), which mixed errors
#             into the success channel. Errors now always go to stderr.
#
# Last reviewed: 2026-07-12
# =============================================================================

out_json_error() {
    [ "${JSON}" -eq 0 ] && return 0
    local message="$1" code="${2:-unknown}"
    printf >&2 '{'
    printf >&2 '"type":"%s"' "out_error"
    [ -n "$message" ] && printf >&2 ',"message":"%s"' "$(util_json_escape "$message")"
    printf >&2 ',"code":"%s"' "$(util_json_escape "$code")"
    printf >&2 '}\n'
}

# =============================================================================
# inst_perform_install() - Perform the actual installation (v2 with checksum)
# =============================================================================
#
# GENERAL PURPOSE:
# Orchestrates the complete installation flow:
#   0. Companion ensure (always): create/modify BASHRC (default ~/.bashrc) PATH,
#      create ~/.profile if absent, Termux `pkg install -y openssh termux-auth`
#      (requirement-domain-sshd, requirement-shell-self-management)
#   1. Privilege-aware path setup (root → /usr/local/bin, normal user → ~/.local/bin)
#   2. Early exit if already installed (unless --force / FORCE_REINSTALL=1)
#   3. Target directory preparation
#   4. Secure download with layered checksum verification:
#        - If CHECKSUM env var is set → strict verification (user/CI pinned version)
#        - Otherwise → best-effort verification via ${SCRIPT_URL}.sha256 (if present)
#   5. Atomic move + chmod via inst_perform_install_atomic_install()
#
# This is the SINGLE SOURCE OF TRUTH for all installation operations
# (initial install, self-update, and forced reinstall).
#
# CIAO PRINCIPLES APPLIED:
# - Caution (Principle 1): Never trust network download without verification when possible.
#   Always use mktemp, explicit error checks, and atomic mv.
# - Intentional (Principle 2): Clear step-by-step flow with explicit if/then blocks.
#   Behavior is fully predictable in interactive, quiet, JSON, and non-TTY modes.
# - Anti-fragile (Principle 3): Works for both root and normal users, survives partial
#   failures, and maintains backward compatibility when no CHECKSUM is provided.
# - Over-protect (Principle 18): Strong Protection Zone, safe defaults, checksum layers,
#   and cleanup on every error path. Designed to be reusable across CIAO-Lite projects.
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# This is the central installation orchestrator. Any change must preserve the
# checksum decision logic, atomic install step, and variable scoping for helpers.
#
# Lessons Learned (CIAO Reflection):
# 2026-06-26:
#   - Original implementation was a stub (created tmp_file then returned 0).
#     This made self-update and the core install path completely non-functional.
#   - Updated to wire the existing v2 download helpers + atomic install helper.
#   - Changed mktemp error handling to explicit if (matching the style enforced
#     in inst_perform_install_download_without_checksum).
#   - Added safe defaults for FORCE_REINSTALL and CHECKSUM.
#   - Ensured tmp_file is always cleaned on failure paths.
#   - Preserved full original defensive header and only appended this Lessons Learned section.
#
# Last reviewed: 2026-09-05
# =============================================================================

inst_perform_install() {
    # --- Safe Variable Defaults ---
    if [ -n "${PREFIX-}" ] && [ -d "${PREFIX}/bin" ]; then
    : "${GLOBAL_BIN:=${PREFIX}/bin}"
else
    : "${GLOBAL_BIN:=/usr/local/bin}"
fi
    : "${USER_BIN:=${HOME}/.local/bin}"
    : "${INSTALL_PATH:=${GLOBAL_BIN}/${APP_NAME}}"
    : "${FORCE_REINSTALL:=0}"
    : "${SKIP_DOMAIN_START:=0}"
    : "${CHECKSUM:=}"
    : "${SCRIPT_URL:=}"
    : "${REMOTE_VERSION:=}"

    if [ "$(id -u)" -eq 0 ]; then
        IS_ROOT=1
        INSTALL_PATH="${GLOBAL_BIN}/${APP_NAME}"
    else
        IS_ROOT=0
        INSTALL_PATH="${USER_BIN}/${APP_NAME}"
    fi

    if [ -z "$REMOTE_VERSION" ]; then
        REMOTE_VERSION=${VERSION}
    fi

    if [ "${JSON}" -eq 0 ]; then
        out_info "Starting installation of ${APP_NAME} ${REMOTE_VERSION}..."
    fi

    # Companion ensure runs even when the CLI binary is already installed so
    # a second `install` still heals missing rc files / Termux packages.
    inst_ensure_companion

    if inst_is_installed && [ "${FORCE_REINSTALL}" -eq 0 ]; then
        if [ "${JSON}" -eq 1 ]; then
            out_json "out_success" "${APP_NAME} is already installed."
        else
            # Success no-op: re-running curl | sh / install does not require --force.
            # --force is only for deliberate re-download/replace (see self-update).
            out_success "${APP_NAME} is already installed."
            out_info "Use --force only to reinstall deliberately (or run: ${APP_NAME} self-update)."
        fi
        if [ "${SKIP_DOMAIN_START}" -ne 1 ]; then
            sshd_start_after_install
        fi
        return 0
    fi

    # Step 1: Prepare target folder
    if ! inst_perform_install_prepare_target; then
        return 1
    fi

    local tmp_file
    tmp_file=$(mktemp -t "${APP_NAME}.XXXXXX")
    if [ -z "${tmp_file}" ]; then
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Failed to create temporary file" "io_error"
        else
            out_error "Failed to create temporary file"
        fi
        return 1
    fi

    local downloaded_checksum_ok=0
    : "${INST_AUTO_CHECKSUM_OK:=0}"

    if [ -n "${CHECKSUM}" ]; then
        # Strict user/CI-provided checksum (highest security)
        if inst_perform_install_download_with_checksum "${tmp_file}"; then
            downloaded_checksum_ok=1
        else
            rm -f "${tmp_file}" 2>/dev/null || true
            return 1
        fi
    else
        # Automatic verification via ${SCRIPT_URL}.sha256 (primary integrity path)
        INST_AUTO_CHECKSUM_OK=0
        if ! inst_perform_install_download_without_checksum "${tmp_file}"; then
            rm -f "${tmp_file}" 2>/dev/null || true
            return 1
        fi
        # Set only when companion matched (not on missing-sidecar continue)
        downloaded_checksum_ok=${INST_AUTO_CHECKSUM_OK:-0}
    fi

    # Step 4: Atomic move to final location + PATH update + success message
    if ! inst_perform_install_atomic_install "${tmp_file}" "${downloaded_checksum_ok}"; then
        rm -f "${tmp_file}" 2>/dev/null || true
        return 1
    fi

    if [ "${SKIP_DOMAIN_START}" -ne 1 ]; then
        sshd_start_after_install
    fi
    return 0
}

# =============================================================================
# inst_perform_install_prepare_target() - Step 1: Target folder preparation
# =============================================================================
#
# GENERAL PURPOSE:
# Creates the correct installation directory (global or user) with proper
# permissions check.
#
# Last reviewed: 29 April 2026
# =============================================================================

inst_perform_install_prepare_target() {
    if [ "$IS_ROOT" -eq 1 ]; then
        if ! mkdir -p "${GLOBAL_BIN}" 2>/dev/null; then
            if [ "${JSON}" -eq 1 ]; then
                out_json_error "Failed to create ${GLOBAL_BIN}" "io_error"
            else
                out_error "Failed to create ${GLOBAL_BIN}"
            fi
            return 1
        fi
    else
        if ! mkdir -p "${USER_BIN}" 2>/dev/null; then
            if [ "${JSON}" -eq 1 ]; then
                out_json_error "Failed to create ${USER_BIN}" "io_error"
            else
                out_error "Failed to create ${USER_BIN}"
            fi
            return 1
        fi
    fi
    return 0
}

# =============================================================================
# inst_perform_install_download_with_checksum() - Step 2: Download with explicit CHECKSUM
# =============================================================================
#
# GENERAL PURPOSE:
# Downloads the script and verifies it against user-provided CHECKSUM (strict).
#
# PRINTF EXCEPTION (class D – tool protocol / computation pipe):
# printf '%s  %s\n' … | sha256sum -c feeds the verifier only (not product UI).
# Status/errors still go through out_* / out_json_error / out_die.
# See requirement-shell-output-requirements.md §2.1.1.
#
# Last reviewed: 2026-07-12
# =============================================================================

inst_perform_install_download_with_checksum() {
    local tmp_file="$1"

    if [ "${JSON}" -eq 0 ]; then
        out_info "Verifying download against provided CHECKSUM..."
    fi

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "${SCRIPT_URL}" -o "${tmp_file}" || {
            if [ "${JSON}" -eq 1 ]; then
                out_json_error "Download failed (curl)" "network_error"
            else
                out_error "Download failed (curl)"
            fi
            return 1
        }
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "${tmp_file}" "${SCRIPT_URL}" || {
            if [ "${JSON}" -eq 1 ]; then
                out_json_error "Download failed (wget)" "network_error"
            else
                out_error "Download failed (wget)"
            fi
            return 1
        }
    else
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Neither curl nor wget found" "missing_dependency"
        else
            out_error "Neither curl nor wget found"
        fi
        return 1
    fi

    # Verify provided CHECKSUM (sha256sum | shasum | openssl — util_sha256_file)
    local actual
    actual=$(util_sha256_file "${tmp_file}") || actual=""
    if [ -n "${actual}" ] && [ "${CHECKSUM}" = "${actual}" ]; then
        if [ "${JSON}" -eq 0 ]; then
            out_success "Checksum verification passed (user-provided CHECKSUM)."
        fi
        return 0
    else
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Checksum verification failed (provided CHECKSUM does not match)" "checksum_mismatch"
        else
            out_die "Checksum verification failed. The downloaded file does not match the provided CHECKSUM. Installation aborted for security."
        fi
        return 1
    fi
}

# =============================================================================
# inst_perform_install_download_without_checksum() - Step 3: Download with automatic .sha256
# =============================================================================
#
# GENERAL PURPOSE:
# Downloads the script and attempts best-effort verification via ${SCRIPT_URL}.sha256.
# Falls back gracefully if no .sha256 file exists (backward compatible).
# Uses robust, auditable hash comparison that actually works.
#
# CIAO PRINCIPLES APPLIED:
# - Caution (Principle 1): Never trust download without verification when possible.
# - Intentional (Principle 2): Explicit HTTP code capture and clear hash comparison.
#   All error handling uses explicit if/then blocks (no || {} or compact || return).
# - Anti-fragile (Principle 3): Tolerates minor whitespace in .sha256 file.
# - Over-protect (Principle 18): Security-critical install path now has working
#   verification and follows current coding standards.
#
# ALIGNMENT (live requirements only):
# - requirement-shell-self-management.md (install download / integrity path)
# - requirement-shell-output-requirements.md (out_* status and errors)
# - requirement-shell-modular-function-design.md (inst_* ownership, headers)
# Source comments cite only files under docs/requirements/ that exist on disk.
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# Designed to be reusable in other CIAO-Lite projects.
#
# Lessons Learned (CIAO Reflection):
# 2026-06-07:
#   - Fixed fundamentally broken verification: `sha256sum -c ... < "${tmp_file}"`
#     does not work as intended.
#   - Removed all `|| {}` and `|| return 1` patterns in this function to comply
#     with updated coding standard.
#   - Both curl and wget paths now use consistent, explicit error handling.
# 2026-07-12: ALIGNMENT retargeted to live docs/requirements/ files only;
#             removed citations to non-existent requirements / templates.
# 2026-07-14: requirement-shell-automatic-checksum transparency (link/value/result);
#             first-field digest parse (sha256sum "hash  file" lines); set
#             INST_AUTO_CHECKSUM_OK=1 on companion match so atomic install can
#             report verified success (was always 0 on automatic path).
#
# Last reviewed: 2026-07-14
# =============================================================================

inst_perform_install_download_without_checksum() {
    local tmp_file="$1"
    # Caller (inst_perform_install) reads this after return 0.
    # 1 = companion present and digests match; 0 = missing sidecar (warn+continue) or unset.
    INST_AUTO_CHECKSUM_OK=0
    : "${SCRIPT_URL:=}"

    if [ "${JSON}" -eq 0 ]; then
        out_info "No CHECKSUM pin → automatic integrity via companion ${SCRIPT_URL}.sha256"
        out_info "Companion link: ${SCRIPT_URL}.sha256"
    fi

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "${SCRIPT_URL}" -o "${tmp_file}"; then
            if [ "${JSON}" -eq 1 ]; then
                out_json_error "Download failed (curl)" "network_error"
            else
                out_error "Download failed (curl)"
            fi
            return 1
        fi

        local sha_file
        sha_file=$(mktemp -t "${APP_NAME}.sha256.XXXXXX")
        if [ -z "${sha_file}" ]; then
            if [ "${JSON}" -eq 1 ]; then
                out_json_error "Failed to create temporary file for checksum" "io_error"
            else
                out_error "Failed to create temporary file for checksum"
            fi
            return 1
        fi

        # Capture HTTP code cleanly
        local http_code
        http_code=$(curl -fsSL -w "%{http_code}" "${SCRIPT_URL}.sha256" -o "${sha_file}" 2>/dev/null)

        if [ "${http_code}" = "200" ]; then
            # First field only: bare hex or standard "hash  filename" lines
            local expected actual
            expected=$(awk 'NF { print $1; exit }' "${sha_file}" 2>/dev/null)
            actual=$(util_sha256_file "${tmp_file}") || actual=""

            if [ -n "${expected}" ] && [ -n "${actual}" ] && [ "${expected}" = "${actual}" ]; then
                INST_AUTO_CHECKSUM_OK=1
                if [ "${JSON}" -eq 0 ]; then
                    out_info "Expected SHA-256: ${expected}"
                    out_info "Actual SHA-256:   ${actual}"
                    out_success "Automatic checksum result: PASS (match ${SCRIPT_URL}.sha256)."
                fi
            else
                rm -f "${sha_file}"
                if [ "${JSON}" -eq 1 ]; then
                    out_json_error "Automatic checksum verification failed" "checksum_mismatch"
                else
                    out_info "Expected SHA-256: ${expected:-"(empty)"}"
                    out_info "Actual SHA-256:   ${actual:-"(empty)"}"
                    out_die "Checksum verification failed (mismatch with ${SCRIPT_URL}.sha256). Installation aborted for security."
                fi
                return 1
            fi
        else
            if [ "${JSON}" -eq 0 ]; then
                out_warn "No .sha256 companion at ${SCRIPT_URL}.sha256 → continuing without automatic verification."
            fi
        fi
        rm -f "${sha_file}" 2>/dev/null || true

    elif command -v wget >/dev/null 2>&1; then
        if ! wget -qO "${tmp_file}" "${SCRIPT_URL}"; then
            if [ "${JSON}" -eq 1 ]; then
                out_json_error "Download failed (wget)" "network_error"
            else
                out_error "Download failed (wget)"
            fi
            return 1
        fi

        local sha_file
        sha_file=$(mktemp -t "${APP_NAME}.sha256.XXXXXX")
        if [ -z "${sha_file}" ]; then
            if [ "${JSON}" -eq 1 ]; then
                out_json_error "Failed to create temporary file for checksum" "io_error"
            else
                out_error "Failed to create temporary file for checksum"
            fi
            return 1
        fi

        if wget -q --server-response "${SCRIPT_URL}.sha256" -O "${sha_file}" 2>&1 | grep -qE "HTTP/[0-9.]+ 200"; then
            local expected actual
            expected=$(awk 'NF { print $1; exit }' "${sha_file}" 2>/dev/null)
            actual=$(util_sha256_file "${tmp_file}") || actual=""

            if [ -n "${expected}" ] && [ -n "${actual}" ] && [ "${expected}" = "${actual}" ]; then
                INST_AUTO_CHECKSUM_OK=1
                if [ "${JSON}" -eq 0 ]; then
                    out_info "Companion link: ${SCRIPT_URL}.sha256"
                    out_info "Expected SHA-256: ${expected}"
                    out_info "Actual SHA-256:   ${actual}"
                    out_success "Automatic checksum result: PASS (match ${SCRIPT_URL}.sha256)."
                fi
            else
                rm -f "${sha_file}"
                if [ "${JSON}" -eq 1 ]; then
                    out_json_error "Automatic checksum verification failed" "checksum_mismatch"
                else
                    out_info "Expected SHA-256: ${expected:-"(empty)"}"
                    out_info "Actual SHA-256:   ${actual:-"(empty)"}"
                    out_die "Checksum verification failed (mismatch with ${SCRIPT_URL}.sha256). Installation aborted for security."
                fi
                return 1
            fi
        else
            if [ "${JSON}" -eq 0 ]; then
                out_warn "No .sha256 companion at ${SCRIPT_URL}.sha256 → continuing without automatic verification."
            fi
        fi
        rm -f "${sha_file}" 2>/dev/null || true

    else
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Neither curl nor wget found" "missing_dependency"
        else
            out_error "Neither curl nor wget found"
        fi
        return 1
    fi

    return 0
}

# =============================================================================
# inst_perform_install_atomic_install() - Step 4: Atomic copy to target location
# =============================================================================
#
# GENERAL PURPOSE:
# Makes the downloaded file executable and atomically moves it to the final
# INSTALL_PATH. PATH / rc files are owned by inst_ensure_companion.
#
# Last reviewed: 29 April 2026
# =============================================================================

inst_perform_install_atomic_install() {
    local tmp_file="$1"
    local downloaded_checksum_ok="$2"

    chmod 0755 "${tmp_file}" 2>/dev/null || chmod +x "${tmp_file}" 2>/dev/null || true

    rm -f "${INSTALL_PATH}" 2>/dev/null
    if ! mv "${tmp_file}" "${INSTALL_PATH}" 2>/dev/null; then
        rm -f "${tmp_file}"
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Failed to move to ${INSTALL_PATH}" "io_error"
        else
            out_error "Failed to move to ${INSTALL_PATH}"
        fi
        return 1
    fi
    chmod 0755 "${INSTALL_PATH}" 2>/dev/null || true

    # PATH / rc files are ensured in inst_ensure_companion (before binary place
    # and on already-installed re-runs). Do not duplicate here.

    if [ "${JSON}" -eq 1 ]; then
        out_json "out_success" "${APP_NAME} ${REMOTE_VERSION} successfully installed to ${INSTALL_PATH}" "path" "${INSTALL_PATH}"
    else
        out_success "${APP_NAME} ${REMOTE_VERSION} successfully installed to ${INSTALL_PATH}"
        if [ "${downloaded_checksum_ok}" -eq 1 ]; then
            out_success "✓ Download was cryptographically verified."
        fi
    fi
    return 0
}

# =============================================================================
# inst_argv0_is_shell_interpreter() - $0 is sh/bash/zsh/… (pipe), not the ship unit
# =============================================================================
#
# GENERAL PURPOSE:
# Return 0 when process $0 is a shell interpreter (curl | sh). Return 1 when
# $0 is the running script (./app self-install, sh /path/to/app).
#
# ALIGNMENT: requirement-shell-cli-self-install.md
#
# Last updated: 2026-09-17
# =============================================================================
inst_argv0_is_shell_interpreter() {
    local _a0="${1:-}"
    local _base="${_a0##*/}"
    case "${_base}" in
        -*) _base="${_base#-}" ;;
    esac
    case "${_base}" in
        sh|bash|dash|ash|zsh|ksh|mksh|yash|posh|csh|tcsh|fish|busybox)
            return 0
            ;;
    esac
    return 1
}

# =============================================================================
# inst_resolve_self_script() - Absolute path of the running script, or empty
# =============================================================================
#
# GENERAL PURPOSE:
# If $0 is a readable regular file (not an interpreter), print its absolute
# path. Basename-only invocations use command -v.
#
# PRINTF EXCEPTION (class B – function return-via-stdout): path or nothing.
#
# ALIGNMENT: requirement-shell-cli-self-install.md
#
# Last updated: 2026-09-17
# =============================================================================
inst_resolve_self_script() {
    local _a0="${1:-}"
    local _dir _found
    if [ -z "${_a0}" ]; then
        return 1
    fi
    if inst_argv0_is_shell_interpreter "${_a0}"; then
        return 1
    fi
    if [ -f "${_a0}" ] && [ -r "${_a0}" ]; then
        _dir=$(CDPATH= cd -- "$(dirname -- "${_a0}")" && pwd) || return 1
        printf '%s\n' "${_dir}/${_a0##*/}"
        return 0
    fi
    case "${_a0}" in
        */*) return 1 ;;
    esac
    _found=$(command -v "${_a0}" 2>/dev/null) || return 1
    if [ -f "${_found}" ] && [ -r "${_found}" ]; then
        printf '%s\n' "${_found}"
        return 0
    fi
    return 1
}

# =============================================================================
# inst_cli_dest_mode() - 0755 global / 0700 local for self-install dest
# =============================================================================
#
# ALIGNMENT: requirement-shell-cli-self-install.md
#
# Last updated: 2026-09-17
# =============================================================================
inst_cli_dest_mode() {
    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        printf '%s\n' "0755"
    else
        printf '%s\n' "0700"
    fi
}

# =============================================================================
# inst_self_install_copy_from_script() - Copy $0 to dest without download
# =============================================================================
#
# GENERAL PURPOSE:
# Stage as ${APP_NAME}-XXXXXX under TMPDIR/cache, chmod dest mode, atomic mv.
#
# ALIGNMENT: requirement-shell-cli-self-install.md
#
# Last updated: 2026-09-17
# =============================================================================
inst_self_install_copy_from_script() {
    local _src="$1"
    local _mode="$2"
    local _tmp
    : "${APP_NAME:=app}"
    : "${JSON:=0}"
    : "${INSTALL_PATH:=}"

    _tmp=$(mktemp -t "${APP_NAME}-XXXXXX")
    if [ -z "${_tmp}" ]; then
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Failed to create temporary file" "io_error"
        else
            out_error "Failed to create temporary file"
        fi
        return 1
    fi
    if ! cp "${_src}" "${_tmp}"; then
        rm -f "${_tmp}" 2>/dev/null || true
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Failed to copy ${_src}" "io_error"
        else
            out_error "Failed to copy ${_src}"
        fi
        return 1
    fi
    chmod "${_mode}" "${_tmp}" 2>/dev/null || true
    rm -f "${INSTALL_PATH}" 2>/dev/null
    if ! mv "${_tmp}" "${INSTALL_PATH}" 2>/dev/null; then
        rm -f "${_tmp}" 2>/dev/null || true
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Failed to move to ${INSTALL_PATH}" "io_error"
        else
            out_error "Failed to move to ${INSTALL_PATH}"
        fi
        return 1
    fi
    chmod "${_mode}" "${INSTALL_PATH}" 2>/dev/null || true
    return 0
}

# =============================================================================
# inst_self_install() - Place the CLI only (not payload)
# =============================================================================
#
# GENERAL PURPOSE:
# Type O-S CLI place/ensure. Non-interactive empty argv and the self-install
# verb. Script $0 → copy without download. Interpreter $0 → channel download.
# Dest mode 0755 global / 0700 local. PATH rc MAY. MUST NOT pkg or start sshd.
#
# ALIGNMENT: requirement-shell-cli-self-install.md
#
# Last updated: 2026-09-17
# =============================================================================
inst_self_install() {
    : "${JSON:=0}"
    : "${FORCE_REINSTALL:=0}"
    : "${APP_NAME:=sshd-cli}"
    : "${VERSION:=}"
    : "${HOME:=/tmp}"
    if [ -n "${PREFIX-}" ] && [ -d "${PREFIX}/bin" ]; then
        : "${GLOBAL_BIN:=${PREFIX}/bin}"
    else
        : "${GLOBAL_BIN:=/usr/local/bin}"
    fi
    : "${USER_BIN:=${HOME}/.local/bin}"
    : "${REMOTE_VERSION:=${VERSION}}"
    : "${CHECKSUM:=}"
    : "${SCRIPT_URL:=}"

    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        IS_ROOT=1
        INSTALL_PATH="${GLOBAL_BIN}/${APP_NAME}"
    else
        IS_ROOT=0
        INSTALL_PATH="${USER_BIN}/${APP_NAME}"
    fi
    local _mode _src _tmp _ck
    _mode=$(inst_cli_dest_mode)

    if [ "${JSON}" -eq 0 ]; then
        out_info "Starting self-install of ${APP_NAME} ${REMOTE_VERSION}..."
    fi

    path_add_shell

    if inst_is_installed && [ "${FORCE_REINSTALL}" -eq 0 ]; then
        if [ "${JSON}" -eq 1 ]; then
            out_json "out_success" "${APP_NAME} is already installed."
        else
            out_success "${APP_NAME} is already installed."
            out_info "Use --force only to replace deliberately (or run: ${APP_NAME} self-update)."
        fi
        return 0
    fi

    if ! inst_perform_install_prepare_target; then
        return 1
    fi

    _src=$(inst_resolve_self_script "$0") || _src=""
    if [ -n "${_src}" ]; then
        if [ "${JSON}" -eq 0 ]; then
            out_info "Installing from local script ${_src} (no download)."
        fi
        if ! inst_self_install_copy_from_script "${_src}" "${_mode}"; then
            return 1
        fi
        if [ "${JSON}" -eq 1 ]; then
            out_json "out_success" "${APP_NAME} ${REMOTE_VERSION} successfully installed to ${INSTALL_PATH}" "path" "${INSTALL_PATH}"
        else
            out_success "${APP_NAME} ${REMOTE_VERSION} successfully installed to ${INSTALL_PATH}"
        fi
        return 0
    fi

    _tmp=$(mktemp -t "${APP_NAME}-XXXXXX")
    if [ -z "${_tmp}" ]; then
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Failed to create temporary file" "io_error"
        else
            out_error "Failed to create temporary file"
        fi
        return 1
    fi
    _ck=0
    : "${INST_AUTO_CHECKSUM_OK:=0}"
    if [ -n "${CHECKSUM}" ]; then
        if inst_perform_install_download_with_checksum "${_tmp}"; then
            _ck=1
        else
            rm -f "${_tmp}" 2>/dev/null || true
            return 1
        fi
    else
        INST_AUTO_CHECKSUM_OK=0
        if ! inst_perform_install_download_without_checksum "${_tmp}"; then
            rm -f "${_tmp}" 2>/dev/null || true
            return 1
        fi
        _ck=${INST_AUTO_CHECKSUM_OK:-0}
    fi
    if ! inst_perform_install_atomic_install "${_tmp}" "${_ck}"; then
        rm -f "${_tmp}" 2>/dev/null || true
        return 1
    fi
    chmod "${_mode}" "${INSTALL_PATH}" 2>/dev/null || true
    return 0
}

# =============================================================================
# inst_ensure_companion() - Login rc + Termux packages (install companion)
# =============================================================================
#
# GENERAL PURPOSE:
# Always-on companion of `install` (payload). Creates or
# modifies BASHRC (default this login's ~/.bashrc) PATH, creates ~/.profile
# if missing, and on Termux runs `pkg install -y openssh termux-auth`.
# Idempotent. Runs even when the CLI binary is already installed.
#
# CIAO PRINCIPLES APPLIED:
# - Caution (Principle 1): Termux pkg only when this is Termux; never apt on
#   Linux. Missing pkg on Termux fails closed.
# - Intentional (Principle 2): rc files vs packages named and separated.
# - Anti-fragile (Principle 3): create-if-missing; never overwrite .profile.
# - Over-protect (Principle 4 / 20): duplicate PATH guard; JSON/quiet silent.
#
# Product law: requirement-shell-self-management.md · requirement-domain-sshd.md
#
# Last reviewed: 2026-09-05
# =============================================================================

inst_ensure_companion() {
    : "${JSON:=0}"
    path_add_shell
    sshd_pkg_ensure
    return 0
}

# =============================================================================
# sshd_start_after_install() - Start sshd at the end of install
# =============================================================================
#
# GENERAL PURPOSE:
# After the CLI is placed (or already-installed no-op), start OpenSSH sshd.
# Termux: same as `start` (fail closed). POSIX Linux: warn and keep install
# success when this login cannot start system sshd (not root / no binary).
# When JSON=1, suppress a second JSON object from sshd_cmd_start (parent
# install already emitted JSON).
#
# Product law: requirement-domain-sshd.md
#
# Last reviewed: 2026-09-05
# =============================================================================

sshd_start_after_install() {
    : "${JSON:=0}"
    : "${APP_NAME:=sshd-cli}"
    : "${SSHD_NESTED_START:=0}"
    : "${SKIP_DOMAIN_START:=0}"
    [ "${SKIP_DOMAIN_START}" -eq 1 ] && return 0
    sshd_resolve
    if sshd_is_termux; then
        SSHD_NESTED_START=1
        sshd_cmd_start
        SSHD_NESTED_START=0
        return $?
    fi
    if [ -z "${SSHD_BIN}" ] || [ ! -x "${SSHD_BIN}" ]; then
        if [ "${JSON}" -eq 0 ]; then
            _hint=$(sshd_openssh_server_hint)
            out_warn "OpenSSH sshd is not on this login PATH. ${APP_NAME} is installed. Next: ${_hint}"
            unset _hint
        fi
        return 0
    fi
    if [ "$(id -u 2>/dev/null || echo 1)" -ne 0 ]; then
        if [ ! -e "${SSHD_CONFIG}" ] || [ ! -w "${SSHD_CONFIG}" ]; then
            if [ "${JSON}" -eq 0 ]; then
                out_warn "System sshd start needs a root login. ${APP_NAME} is installed. Next: ${APP_NAME} start as root."
            fi
            return 0
        fi
    fi
    # POSIX Linux: attempt start; MUST NOT fail CLI place.
    # MUST NOT rewrite /etc/ssh/sshd_config. MUST NOT create /run/sshd here.
    # MUST NOT out_die — sshd -t / missing privilege-separation dir is host sshd.
    if sshd_try_start_linux; then
        return 0
    fi
    if [ "${JSON}" -eq 0 ]; then
        out_warn "${APP_NAME} is installed. System sshd was not started. Next: ${APP_NAME} start as root (or start the distro ssh/sshd unit)."
    fi
    return 0
}

# =============================================================================
# sshd_try_start_linux() - Non-fatal Linux auto-start after CLI place
# =============================================================================
#
# GENERAL PURPOSE:
# Best-effort start of system sshd after install. Return 0 if already running
# or start succeeded. Return 1 on any host sshd failure. Never out_die.
# Never rewrite sshd_config. Never mkdir /run/sshd. Never generate host keys
# as a side effect of CLI install.
#
# ALIGNMENT (live requirements only):
# - requirement-domain-sshd.md
#
# Last updated: 2026-09-09
# =============================================================================
sshd_try_start_linux() {
    sshd_resolve
    _unit=$(sshd_systemd_unit || true)
    if [ -n "${_unit}" ]; then
        if sshd_systemd_is_active "${_unit}"; then
            unset _unit
            return 0
        fi
        if [ "$(id -u 2>/dev/null || echo 1)" -ne 0 ]; then
            unset _unit
            return 1
        fi
        if systemctl start "${_unit}" >/dev/null 2>&1; then
            unset _unit
            return 0
        fi
        unset _unit
        return 1
    fi
    unset _unit
    if sshd_running_pid >/dev/null 2>&1; then
        return 0
    fi
    [ -n "${SSHD_BIN}" ] && [ -x "${SSHD_BIN}" ] || return 1
    [ -n "${SSHD_CONFIG}" ] && [ -r "${SSHD_CONFIG}" ] || return 1
    if ! "${SSHD_BIN}" -t -f "${SSHD_CONFIG}" >/dev/null 2>&1; then
        return 1
    fi
    if ! "${SSHD_BIN}" -f "${SSHD_CONFIG}"; then
        return 1
    fi
    return 0
}

# =============================================================================
# inst_maybe_install() - Friendly installation prompt
# =============================================================================
#
# Respects both --quiet and --json modes.
# Quiet/JSON: no prompt — MUST call inst_self_install (CLI place, not payload).
# Interactive gate consumes process TTY (set once at startup), not a second [ -t.
# Uses prompt_yes_no() as single source of truth for confirmation.
#
# !!! DO NOT MODIFY OR SIMPLIFY !!!
# Designed to be reusable in other projects.
#
# Lessons Learned (CIAO Reflection):
# 2026-07-13:
#   - Under set -u, recommended-install branch used IS_ROOT / SH before any
#     assignment (those were only set inside inst_perform_install). Crash:
#     "IS_ROOT: parameter not set" after printing "Recommended installation
#     command:". Fixed with local privilege detection + SH/SCRIPT_URL defaults.
# 2026-09-02:
#   - JSON/QUIET returned 0 without placing (SM-BUG-01). Specializees that
#     copy this helper as Case A SSOT inherited silent success. Now calls
#     inst_perform_install and returns its status. Prompt gate reads TTY.
#
# Last updated: 2026-09-02
# =============================================================================

inst_maybe_install() {
    : "${QUIET:=0}"
    : "${JSON:=0}"
    : "${TTY:=0}"
    : "${FORCE_REINSTALL:=0}"
    : "${SCRIPT_URL:=}"
    : "${SH:=sh}"
    # Privilege for recommended install command (set -u safe; same rule as inst_perform_install)
    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        IS_ROOT=1
    else
        IS_ROOT=0
    fi

    if inst_is_installed && [ "${FORCE_REINSTALL}" -eq 0 ]; then
        return 0
    fi
    # Quiet or JSON: CLI place with no prompt (requirement-shell-cli-self-install).
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        inst_self_install
        return $?
    fi
    out_empty_line
    out_plain "Note: '${APP_NAME}' is not installed yet."
    out_plain "     Version: ${VERSION}"
    out_empty_line
    out_plain "Recommended installation command:"
    out_empty_line

    if sshd_is_normal_user_only_cli; then
        out_plain "     curl -fsSL ${SCRIPT_URL} | ${SH}"
    elif [ "$IS_ROOT" -eq 1 ]; then
        out_plain "     sudo curl -fsSL ${SCRIPT_URL} | sudo ${SH}"
    else
        out_plain "     curl -fsSL ${SCRIPT_URL} | ${SH}"
    fi
    out_empty_line

    _maybe_should_install=0

    if [ "${TTY}" -eq 1 ]; then
        if prompt_yes_no "Install ${APP_NAME} ${VERSION} now?"; then
            _maybe_should_install=1
        else
            out_plain "Installation skipped by user."
            return 0
        fi
    else
        out_plain "Non-interactive mode detected → installing automatically..."
        _maybe_should_install=1
    fi

    if [ "${_maybe_should_install}" -eq 1 ]; then
        inst_self_install
        return $?
    fi
    return 0
}

# =============================================================================
# inst_self_update() - Perform atomic self-update to latest version
# =============================================================================
#
# GENERAL PURPOSE:
# Orchestrates self-update for the installed ${APP_NAME} binary.
# Fetches the remote VERSION string, compares it with the locally installed
# version, and (if different or --force) delegates to inst_perform_install
# with FORCE_REINSTALL=1. Designed to be safe, idempotent-friendly, and
# respectful of the current installation type (user vs global).
#
# CIAO PRINCIPLES APPLIED:
# - Caution (Principle 1): Never downgrades without explicit FORCE; always
#   verifies remote version before proceeding; uses centralized output.
# - Intentional (Principle 2): Clear separation between version check and
#   actual install; explicit variable handling and error paths.
# - Anti-fragile (Principle 3): Works for both root and normal users;
#   survives missing SCRIPT_URL (graceful error) and network failures.
# - Over-protect (Principle 18): Full CIAO header, safe defaults, Protection
#   Zone comment, and Lessons Learned traceability. Reusable pattern for
#   other CIAO-Lite self-managed tools.
#
# ALIGNMENT (live requirements only):
# - requirement-shell-self-management.md
# - requirement-shell-cli-interface.md
# - requirement-shell-output-requirements.md
# - requirement-shell-idempotency.md
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# This is the canonical self-update entry point. Any change must preserve
# the REMOTE_VERSION visibility contract with inst_perform_install and
# the centralized output discipline.
#
# Lessons Learned (CIAO Reflection):
# 2026-06-26: Original implementation was a stub. Updated to call the v2
#             inst_perform_install path with checksum support.
# 2026-06-26 (correction): Removed accidental `local` on REMOTE_VERSION
#             (was invisible to inst_perform_install). Added safe default
#             for SCRIPT_URL and explicit comment about distribution URL
#             requirement. No hard-coded project-specific values introduced.
#
# Last updated: 2026-09-09
# =============================================================================

inst_self_update() {
    # --- Safe Variable Defaults ---
    : "${APP_NAME:=sshd-cli}"
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${FORCE:=0}"
    : "${FORCE_REINSTALL:=0}"
    : "${SKIP_DOMAIN_START:=0}"
    : "${SCRIPT_URL:=}"

    # Align force aliases (CLI --force sets both)
    if [ "${FORCE}" -eq 1 ]; then
        FORCE_REINSTALL=1
    fi

    if [ "${JSON}" -eq 0 ]; then
        out_info "Starting self-update of ${APP_NAME}..."
    fi

    # SCRIPT_URL is Config SSOT (composed default from REPO_* / APP_NAME).
    # Override via env for forks or offline channels. Empty → fail loud below.

    REMOTE_VERSION=$(util_fetch_remote_version "${SCRIPT_URL}")

    if [ -z "$REMOTE_VERSION" ]; then
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Failed to fetch latest version" "network_error"
        else
            out_error "Failed to fetch latest version (SCRIPT_URL may be unset or unreachable)"
        fi
        return 1
    fi

    local local_version
    local_version=$(inst_get_version)

    if [ "$local_version" = "$REMOTE_VERSION" ] && [ "${FORCE_REINSTALL}" -eq 0 ]; then
        if [ "${JSON}" -eq 1 ]; then
            out_json "out_success" "Already running the latest version (${REMOTE_VERSION})."
        else
            out_success "Already running the latest version (${REMOTE_VERSION})."
        fi
        return 0
    fi

    # No silent downgrade: remote older than local requires --force
    # (requirement-shell-self-management.md)
    if [ "$local_version" != "not installed" ] && \
       [ "$local_version" != "unknown" ] && \
       ver_gt "$local_version" "$REMOTE_VERSION" && \
       [ "${FORCE_REINSTALL}" -eq 0 ]; then
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Refusing downgrade from ${local_version} to ${REMOTE_VERSION} (use --force)" "downgrade_blocked"
        else
            out_error "Refusing silent downgrade: local ${local_version} is newer than remote ${REMOTE_VERSION}."
            out_info "Re-run with --force to reinstall/downgrade deliberately."
        fi
        return 1
    fi

    if [ "$local_version" != "$REMOTE_VERSION" ] && [ "${JSON}" -eq 0 ]; then
        if ver_gt "$REMOTE_VERSION" "$local_version" 2>/dev/null || [ "$local_version" = "not installed" ]; then
            out_info "Updating from ${local_version} → ${REMOTE_VERSION}"
        else
            out_warn "Force reinstall/downgrade: ${local_version} → ${REMOTE_VERSION}"
        fi
    fi

    FORCE_REINSTALL=1
    # CLI-only: do not auto-start host sshd or sshd -t /etc/ssh/sshd_config.
    SKIP_DOMAIN_START=1
    inst_perform_install
    SKIP_DOMAIN_START=0
}

# =============================================================================
# inst_self_uninstall() - Main orchestrator for uninstallation
# =============================================================================
#
# GENERAL PURPOSE:
# Removes the installed ${APP_NAME} binary (global or user) and optionally
# cleans up PATH entries.
#
# Respects --force, --quiet, and --json.
# Works for both root and user installations.
#
# DESIGN:
# Split into three clear steps for readability while preserving original
# behavior and safety.
#
# Last reviewed: 29 April 2026
# =============================================================================

inst_self_uninstall() {
    # Align force aliases (CLI --force)
    : "${FORCE:=0}"
    : "${FORCE_REINSTALL:=0}"
    if [ "${FORCE}" -eq 1 ]; then
        FORCE_REINSTALL=1
    fi

    if [ "${JSON}" -eq 0 ]; then
        out_info "Starting self-uninstall of ${APP_NAME}..."
    fi

    # Step 1: Determine which installation to remove
    local bin_path
    bin_path=$(inst_self_uninstall_determine_bin)
    if [ -z "$bin_path" ]; then
        if [ "${JSON}" -eq 1 ]; then
            out_json "out_success" "${APP_NAME} is not installed. Nothing to uninstall."
        else
            out_warn "${APP_NAME} is not installed. Nothing to uninstall."
        fi
        return 0
    fi

    # Step 2: Confirm (if needed) and perform removal
    if ! inst_self_uninstall_confirm_and_remove "$bin_path"; then
        return 1
    fi

    # Step 3: Clean up PATH entries (user installs only)
    inst_self_uninstall_cleanup_path

    if [ "${JSON}" -eq 1 ]; then
        out_json "out_success" "${APP_NAME} has been uninstalled."
    else
        out_success "${APP_NAME} has been uninstalled."
    fi
    return 0
}

# =============================================================================
# inst_self_uninstall_determine_bin() - Step 1: Determine which installation to remove
# =============================================================================
#
# GENERAL PURPOSE:
# Decides the correct binary path to remove based on current user,
# FORCE_GLOBAL, and actual file presence.
#
# Returns the full path to remove, or empty string if nothing to uninstall.
#
# PRINTF EXCEPTION (class B – function return-via-stdout):
# Final printf '%s' "$bin_path" is a data return for $(…) capture by the
# uninstall orchestrator — not a product user message. User-facing text in
# this helper uses out_warn. Callers must capture the path; do not treat
# this printf as a substitute for out_*.
# See requirement-shell-output-requirements.md §2.1.1.
#
# CRITICAL: Respects root vs user logic exactly as before.
#
# Last reviewed: 2026-07-12
# =============================================================================

inst_self_uninstall_determine_bin() {
    # Prefer shared path SSOT (util_get_install_bin_path); only return if file exists.
    : "${APP_NAME:=sshd-cli}"
    if [ -n "${PREFIX-}" ] && [ -d "${PREFIX}/bin" ]; then
    : "${GLOBAL_BIN:=${PREFIX}/bin}"
else
    : "${GLOBAL_BIN:=/usr/local/bin}"
fi
    : "${HOME:=/tmp}"
    : "${USER_BIN:=${HOME}/.local/bin}"

    local bin_path=""
    bin_path=$(util_get_install_bin_path)
    if [ -n "${bin_path}" ] && [ -f "${bin_path}" ]; then
        printf '%s' "${bin_path}"
        return 0
    fi
    # Empty → not installed (caller treats as nothing to uninstall)
    printf '%s' ""
}

# =============================================================================
# inst_self_uninstall_confirm_and_remove() - Step 2: Confirm and remove binary
# =============================================================================
#
# GENERAL PURPOSE:
# Handles confirmation (unless --force) and actual file removal.
# Interactive TTY uses prompt_yes_no(); non-interactive / --json / --quiet
# fail closed with an explicit --force requirement (never auto-delete).
#
# Returns 0 on out_success, non-zero on failure/cancel.
#
# Last reviewed: 2026-07-13
# =============================================================================

inst_self_uninstall_confirm_and_remove() {
    local bin_path="$1"

    # Confirm before removal (unless --force / FORCE_REINSTALL).
    # Non-interactive / --json / --quiet: fail closed — never auto-delete.
    # Do not report that as "cancelled by user" (user never answered a prompt).
    if [ "${FORCE_REINSTALL:-0}" -eq 0 ] && [ "${FORCE:-0}" -eq 0 ]; then
        : "${JSON:=0}"
        : "${QUIET:=0}"

        if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ] || ! [ -t 0 ] || ! [ -t 1 ]; then
            # requirement-shell-interactive-vs-noninteractive.md: destructive ops need --force
            if [ "${JSON}" -eq 1 ]; then
                out_json_error "Uninstall requires --force in non-interactive mode (refusing to remove ${bin_path})." "confirm_required"
            else
                out_error "Uninstall requires --force in non-interactive mode (refusing to remove ${bin_path})."
                out_info "Re-run with: ${APP_NAME} self-uninstall --force"
            fi
            return 1
        fi

        if prompt_yes_no "This will remove: ${bin_path}"; then
            :  # confirmed on TTY
        else
            # Interactive TTY: user answered no / empty (default N)
            out_plain "Uninstall cancelled by user."
            return 1
        fi
    fi

    # Remove the binary
    if rm -f "$bin_path" 2>/dev/null; then
        return 0
    else
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Failed to remove ${bin_path} (permission denied?)" "permission_denied"
        else
            out_error "Failed to remove ${bin_path} (permission denied?)"
        fi
        return 1
    fi
}

# =============================================================================
# inst_self_uninstall_cleanup_path() - Step 3: Clean up PATH entries
# =============================================================================
#
# GENERAL PURPOSE:
# Removes installer-added PATH entries from shell config files
# (bash, zsh, fish) for user-level installations **only if** USER_BIN
# is empty or does not exist.
#
# SAFETY RULE:
# If USER_BIN still contains other files (other tools, scripts, etc.),
# we deliberately keep the PATH entry to avoid breaking the user's environment.
# This follows CIAO-Lite "Caution" and "Anti-fragile" principles.
#
# Last reviewed: 2026-07-14
# =============================================================================

inst_self_uninstall_cleanup_path() {
    # Only attempt cleanup for non-root installs
    if [ "$(id -u)" -eq 0 ]; then
        return 0
    fi

    : "${HOME:=/tmp}"
    : "${USER_BIN:=${HOME}/.local/bin}"
    : "${BASHRC:=${HOME}/.bashrc}"
    local bin_dir="${USER_BIN}"
    local should_clean_path=1

    # === SAFETY CHECK: Only clean PATH if USER_BIN is empty ===
    if [ -d "$bin_dir" ]; then
        if [ -n "$(ls -A "$bin_dir" 2>/dev/null)" ]; then
            # Directory exists and is not empty → keep PATH for other tools
            should_clean_path=0
            if [ "${JSON}" -eq 0 ]; then
                out_warn "Keeping ${bin_dir} in PATH because it still contains files."
            fi
        fi
    fi

    # Always strip this product's installer comments. Strip the shared PATH
    # line only when USER_BIN is empty (sibling unify).
    local cleaned=0
    local escaped_bin
    local escaped_name
    escaped_bin=$(printf '%s' "${bin_dir}" | sed 's/[\\/&|]/\\&/g')
    escaped_name=$(printf '%s' "${APP_NAME}" | sed 's/[\\/&|]/\\&/g')
    : "${ZSHRC:=${HOME}/.zshrc}"
    : "${FISH_CONFIG:=${HOME}/.config/fish/config.fish}"

    for config in "${BASHRC}" "${ZSHRC}" "${FISH_CONFIG}"; do
        if [ -f "$config" ]; then
            if [ "$should_clean_path" -eq 1 ]; then
                if sed -i.bak \
                    -e "/# Added by ${escaped_name} installer/d" \
                    -e "\|${escaped_bin}|d" \
                    "$config" 2>/dev/null; then
                    cleaned=1
                fi
            else
                if sed -i.bak \
                    -e "/# Added by ${escaped_name} installer/d" \
                    "$config" 2>/dev/null; then
                    cleaned=1
                fi
            fi
            rm -f "${config}.bak" 2>/dev/null || true
        fi
    done

    if [ "$cleaned" -eq 1 ] && [ "${JSON}" -eq 0 ]; then
        out_plain "→ Cleaned ${APP_NAME} PATH entries from shell config files"
        out_plain "→ You may want to restart your terminal"
    fi
}

# =============================================================================
# inst_is_installed() - Robust installation check
# =============================================================================
#
# GENERAL PURPOSE:
# Checks whether the program is already installed, supporting both root
# and normal user installations with safe fallbacks.
#
# Please don't modify this code for root-only installed
# You can check [ "$(id -u)" -eq 0 ] before calling / excuting 
#   this function
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# Designed to be reusable in other projects.
#
# Last reviewed: 29 April 2026
# =============================================================================

inst_is_installed() {
    version=$(inst_get_version)
    if [ "${version}" = "not installed"  ]; then 
        return 1
    else
        return 0
    fi
}

# =============================================================================
# inst_get_version() - Extract version from installed binary
# =============================================================================
#
# GENERAL PURPOSE:
# Safely reads the VERSION constant from the installed script.
# Used by --version-check and --self-update.
#
# Safe Variable Defaults
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# Designed to be reusable in other projects.
#
# CRITICAL WARNING - VERSION EXTRACTION IS ESSENTIAL FOR SELF-UPDATE:
# Knowing the exact installed version is not optional — it is the foundation
# of safe self-update and version-check logic.
#
# Without a reliable inst_get_version(), self-update cannot properly
# compare local version against remote, leading to:
# - Unnecessary re-downloads
# - Failed updates
# - Silent failures
# - Potential downgrade or broken installation
#
# AI assistants frequently fail to respect this importance. They often
# overlook, simplify, or remove version extraction logic because they
# consider it "minor" or try to replace the entire self-update flow with
# a simpler approach. This always breaks the self-update mechanism.
#
# This function is battle-field tested and intentionally simple/robust
# (grep + cut on the VERSION= line). Any attempt to rewrite or bypass it
# risks destroying the self-update safety net.
#
# We must intentionally preserve and reuse this exact function instead of
# replacing it. Respecting version awareness is a core part of CIAO
# Caution and Anti-fragility.
#
# PRINTF/ECHO EXCEPTION (class B – function return-via-stdout):
# echo "unknown" / echo "not installed" / grep|cut pipeline output are data
# returns for $(inst_get_version) capture — not product banners. Callers
# pass the string into out_* / out_json when displaying to the user.
# See requirement-shell-output-requirements.md §2.1.1.
#
# Last reviewed: 2026-07-12
# =============================================================================

inst_get_version() {
    # --- Safe Variable Defaults ----
    # Align with util_get_install_bin_path: non-root prefers user-local when present (L-03).
    : "${APP_NAME:=app}"
    : "${IS_ROOT:=0}"
    : "${HOME:=/tmp}"
    if [ -n "${PREFIX-}" ] && [ -d "${PREFIX}/bin" ]; then
    : "${GLOBAL_BIN:=${PREFIX}/bin}"
else
    : "${GLOBAL_BIN:=/usr/local/bin}"
fi
    : "${USER_BIN:=${HOME}/.local/bin}"
    : "${FORCE_USER:=0}"
    : "${FORCE_GLOBAL:=0}"

    local bin_path=""
    if [ "${FORCE_USER}" -eq 1 ]; then
        bin_path="${USER_BIN}/${APP_NAME}"
    elif [ "${FORCE_GLOBAL}" -eq 1 ] || [ "${IS_ROOT}" -eq 1 ] || [ "$(id -u)" -eq 0 ]; then
        bin_path="${GLOBAL_BIN}/${APP_NAME}"
    else
        if [ -x "${USER_BIN}/${APP_NAME}" ]; then
            bin_path="${USER_BIN}/${APP_NAME}"
        elif [ -x "${GLOBAL_BIN}/${APP_NAME}" ]; then
            bin_path="${GLOBAL_BIN}/${APP_NAME}"
        else
            bin_path="${USER_BIN}/${APP_NAME}"
        fi
    fi

    if [ -x "$bin_path" ]; then
        grep '^VERSION="' "$bin_path" 2>/dev/null | cut -d'"' -f2 || echo "unknown"
    else
        echo "not installed"
    fi
}

# =============================================================================
# ver_gt() - Pure POSIX semantic version comparison
# =============================================================================
#
# GENERAL PURPOSE:
# Returns 0 (true) if ver1 > ver2, otherwise returns 1 (false).
# Used by ver_check() and inst_self_update() to prevent incorrect downgrades.
#
# Safe Variable Defaults
# Respects CIAO zero-dependency rule — no external tools (no sort -V).
#
# CRITICAL DESIGN CHOICE:
# This function was added because previous AI suggestions using `sort -V`
# were not portable enough for harsh environments (Alpine ash, busybox,
# minimal containers, Git Bash, etc.).
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# Past AI assistants have repeatedly tried to replace this with:
#   - `sort -V` one-liners
#   - Inline string comparisons
#   - "Cleaner" but less robust logic
#
# Any such change re-introduces downgrade bugs and breaks portability.
# This function must remain pure POSIX and self-contained.
#
# AI assistants are explicitly required to:
# - Never remove or inline this function
# - Always use it for all version comparisons in grokrec
# - Preserve all defensive comments
# - Study the test script provided by the user before suggesting changes
#
# This is part of the battle-field-tested defensive layer.
#
# Last reviewed: 29 April 2026
# =============================================================================

ver_gt() {
    # --- Safe Variable Defaults ----
    v1=$1
    v2=$2

    while [ -n "$v1" ] || [ -n "$v2" ]; do
        p1=${v1%%.*}
        p2=${v2%%.*}

        [ -z "$p1" ] && p1=0
        [ -z "$p2" ] && p2=0

        if [ "$p1" -gt "$p2" ]; then
            return 0
        fi
        if [ "$p1" -lt "$p2" ]; then
            return 1
        fi

        if [ "$v1" = "${v1#*.}" ]; then
            v1=""
        else
            v1=${v1#*.}
        fi

        if [ "$v2" = "${v2#*.}" ]; then
            v2=""
        else
            v2=${v2#*.}
        fi
    done

    return 1    # versions are equal
}

# =============================================================================
# ver_check() - Check for newer version from remote source
# =============================================================================
#
# GENERAL PURPOSE:
# Compares the locally installed version of ${APP_NAME} against the remote
# version available at SCRIPT_URL. Supports both human-readable output and
# clean JSON mode. Used by the `version-check` command and as a helper for
# self-update decision logic.
#
# CIAO PRINCIPLES APPLIED:
# - Caution (Principle 1): Never assumes SCRIPT_URL is set; graceful failure
#   with actionable error when remote version cannot be fetched.
# - Intentional (Principle 2): Explicit safe defaults, clear separation of
#   version fetching vs comparison, and consistent behavior in JSON/quiet modes.
# - Anti-fragile (Principle 3): Works whether the tool is installed globally,
#   per-user, or not yet installed; survives network or parsing failures.
# - Over-protect (Principle 18): Full defensive header, Protection Zone,
#   Lessons Learned traceability, and strict avoidance of hard-coded
#   project-specific URLs or repository paths.
#
# ALIGNMENT (live requirements only):
# - requirement-shell-self-management.md
# - requirement-shell-cli-interface.md
# - requirement-shell-output-requirements.md
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# This function is the single source of truth for remote version comparison.
# Any change must preserve the SCRIPT_URL handling contract and the exact
# JSON output shape expected by consumers.
#
# Lessons Learned (CIAO Reflection):
# 2026-06-26: Original version contained a hardcoded project-specific default
#             URL pointing to an unrelated repository (porting artifact).
#             Corrected to empty safe default + explicit comment. Removed
#             all hard-coded distribution details to comply with generalization
#             and hardcoding-prevention rules.
#
# Last reviewed: 2026-06-26
# =============================================================================

ver_check() {
    # --- Safe Variable Defaults ----
    # Defensive defaults - never assume globals are set
    : "${APP_NAME:=sshd-cli}"
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${SCRIPT_URL:=}"

    # SCRIPT_URL is Config SSOT (composed default from REPO_USER/REPO_NAME/APP_NAME).
    # Override via env for forks or offline channels. Empty → network steps fail loud.

    # Fetch remote version (curl or wget)
    REMOTE_VERSION=$(util_fetch_remote_version "${SCRIPT_URL}")

    if [ -z "$REMOTE_VERSION" ]; then
        if [ "${JSON}" -eq 1 ]; then
            out_json_error "Failed to fetch remote version" "network_error"
        else
            out_error "Failed to fetch remote version (SCRIPT_URL may be unset or unreachable)"
        fi
        return 1
    fi

    local local_version
    local_version=$(inst_get_version)

    if [ "${JSON}" -eq 1 ]; then
        # out_json type message key value … — empty message so fields stay key/value pairs
        local _is_latest="false"
        if [ "$local_version" = "$REMOTE_VERSION" ]; then
            _is_latest="true"
        elif ver_gt "$local_version" "$REMOTE_VERSION" 2>/dev/null; then
            _is_latest="true"
        fi
        out_json "ver_check" "" \
            "local_version" "$local_version" \
            "remote_version" "$REMOTE_VERSION" \
            "is_latest" "${_is_latest}"
    else
        if [ "${QUIET}" -eq 0 ]; then
            out_info "Checking latest version of ${APP_NAME}..."
            out_plain "Local version : ${local_version}"
            out_plain "Latest version: ${REMOTE_VERSION}"
            out_empty_line

            if [ "$local_version" = "$REMOTE_VERSION" ]; then
                out_success "You are running the latest version."
            elif ver_gt "$local_version" "$REMOTE_VERSION"; then
                out_success "You are running a newer development version (${local_version} > ${REMOTE_VERSION})"
            elif [ "$local_version" = "not installed" ]; then
                out_warn "${APP_NAME} is not installed yet."
            else
                out_warn "A newer version is available (${REMOTE_VERSION})"
            fi
        fi
    fi
}


# =============================================================================
# path_add_bashrc() - Add USER_BIN to BASHRC (default ~/.bashrc)
# =============================================================================
#
# GENERAL PURPOSE:
# Appends the PATH export to BASHRC only if the exact export line is absent.
#
# BASHRC defaults to ${HOME}/.bashrc. Tests/CI may override BASHRC to a file
# in a temp folder so this login's real interactive rc is not touched.
#
# Creates the file if missing, then appends the PATH export only if the exact
# `export PATH="<USER_BIN>:$PATH"` line is not already present. Returns 0 if
# created or PATH was added, 1 if the exact line is already present or
# create/write failed.
#
# PRINTF EXCEPTION (class C – file I/O redirect):
# printf … >> "$bashrc" writes shell config content to a file, not product
# stdout/stderr. User-visible “→ Added …” lines use out_plain.
# See requirement-shell-output-requirements.md §2.1.1.
#
# Last reviewed: 2026-09-09
# =============================================================================

path_add_bashrc() {
    : "${HOME:=/tmp}"
    : "${USER_BIN:=${HOME}/.local/bin}"
    : "${BASHRC:=${HOME}/.bashrc}"
    : "${APP_NAME:=sshd-cli}"
    : "${VERSION:=0}"
    : "${JSON:=0}"
    local bashrc="${BASHRC}"
    local path_line
    local created=0
    path_line=$(printf 'export PATH="%s:$PATH"' "${USER_BIN}")

    if [ ! -f "$bashrc" ]; then
        if ! printf '# Interactive rc created by %s installer (%s)\n' "$APP_NAME" "$VERSION" > "$bashrc"; then
            if [ "${JSON}" -eq 0 ]; then
                out_warn "Could not create ${bashrc}. Next: create that file as this login, then re-run ${APP_NAME} install."
            fi
            return 1
        fi
        chmod 0644 "$bashrc" 2>/dev/null || true
        created=1
        if [ "${JSON}" -eq 0 ]; then
            out_plain "→ Created ${bashrc}"
        fi
    fi

    if ! grep -qF "${path_line}" "$bashrc" 2>/dev/null; then
        printf "\n# Added by %s installer (%s)\n" "$APP_NAME" "$VERSION" >> "$bashrc"
        printf '%s\n' "${path_line}" >> "$bashrc"
        if [ "${JSON}" -eq 0 ]; then
            out_plain "→ Added ${USER_BIN} to PATH for bash"
        fi
        return 0
    fi
    # Sibling unify: exact PATH already present (this product or another).
    # MAY append only this product's comment; MUST NOT a second export.
    _comment=$(printf '# Added by %s installer (%s)' "$APP_NAME" "$VERSION")
    if ! grep -qF "${_comment}" "$bashrc" 2>/dev/null; then
        printf '\n%s\n' "${_comment}" >> "$bashrc"
        unset _comment
        if [ "$created" -eq 1 ]; then
            return 0
        fi
        if [ "${JSON}" -eq 0 ]; then
            out_plain "→ Noted ${APP_NAME} on existing PATH line"
        fi
        return 0
    fi
    unset _comment
    if [ "$created" -eq 1 ]; then
        return 0
    fi
    return 1  # already present
}

# =============================================================================
# path_ensure_profile() - Create ~/.profile if absent (never overwrite)
# =============================================================================
#
# GENERAL PURPOSE:
# A login shell (SSH) reads ~/.profile, not ~/.bashrc. If .profile is missing,
# PATH and interactive rc never run after SSH. Create a short file that sources
# ~/.bashrc. If the file already exists, leave the body unchanged.
#
# Returns 0 if created, 1 if already present or create failed.
#
# PRINTF EXCEPTION (class C – file I/O redirect):
# printf … > "$profile" writes shell config content to a file, not product
# stdout/stderr. User-visible “→ Created …” lines use out_plain.
# See requirement-shell-output-requirements.md §2.1.1.
#
# Last reviewed: 2026-09-05
# =============================================================================

path_ensure_profile() {
    : "${HOME:=/tmp}"
    : "${APP_NAME:=sshd-cli}"
    : "${JSON:=0}"
    : "${PROFILE:=${HOME}/.profile}"
    local profile="${PROFILE}"

    if [ -f "$profile" ]; then
        return 1
    fi

    if ! {
        printf '# BEGIN %s profile source-bashrc\n' "$APP_NAME"
        printf '# Created so a bash login shell sources interactive rc.\n'
        printf 'if [ -n "${BASH_VERSION:-}" ]; then\n'
        printf '    if [ -f "${HOME}/.bashrc" ]; then\n'
        printf '        . "${HOME}/.bashrc"\n'
        printf '    fi\n'
        printf 'fi\n'
        printf '# END %s profile source-bashrc\n' "$APP_NAME"
    } > "$profile"; then
        if [ "${JSON}" -eq 0 ]; then
            out_warn "Could not create ${profile}. Next: create that file as this login so SSH login reads ~/.bashrc, then re-run ${APP_NAME} install."
        fi
        return 1
    fi
    chmod 0644 "$profile" 2>/dev/null || true
    if [ "${JSON}" -eq 0 ]; then
        out_plain "→ Created ${profile} (login shell sources ~/.bashrc)"
    fi
    return 0
}

# =============================================================================
# path_add_zshrc() - Add ~/.local/bin to ~/.zshrc
# =============================================================================
#
# GENERAL PURPOSE:
# Appends the PATH export to ~/.zshrc only if not already present.
#
# Returns 0 if added (or was already present), 1 if file missing or failed.
#
# PRINTF EXCEPTION (class C – file I/O redirect):
# printf … >> "$zshrc" writes shell config content to a file, not product
# stdout/stderr. User-visible “→ Added …” lines use out_plain.
# See requirement-shell-output-requirements.md §2.1.1.
#
# Last reviewed: 2026-07-12
# =============================================================================

path_add_zshrc() {
    : "${HOME:=/tmp}"
    : "${USER_BIN:=${HOME}/.local/bin}"
    : "${ZSHRC:=${HOME}/.zshrc}"
    local zshrc="${ZSHRC}"
    local path_line
    path_line=$(printf 'export PATH="%s:$PATH"' "${USER_BIN}")
    if [ ! -f "$zshrc" ]; then
        return 1
    fi

    if ! grep -qF "${path_line}" "$zshrc" 2>/dev/null; then
        printf "\n# Added by %s installer (%s)\n" "$APP_NAME" "$VERSION" >> "$zshrc"
        printf '%s\n' "${path_line}" >> "$zshrc"
        if [ "${JSON}" -eq 0 ]; then
            out_plain "→ Added ${USER_BIN} to PATH for zsh"
        fi
        return 0
    fi
    return 1  # already present
}

# =============================================================================
# path_add_fish() - Add ~/.local/bin to Fish config
# =============================================================================
#
# GENERAL PURPOSE:
# Creates ~/.config/fish directory if needed and appends the PATH setting
# to config.fish only if not already present.
#
# Returns 0 if added (or was already present), 1 if failed.
#
# PRINTF EXCEPTION (class C – file I/O redirect):
# printf … >> "$fish_config" writes shell config content to a file, not
# product stdout/stderr. User-visible “→ Added …” lines use out_plain.
# See requirement-shell-output-requirements.md §2.1.1.
#
# Last reviewed: 2026-07-12
# =============================================================================

path_add_fish() {
    : "${HOME:=/tmp}"
    : "${USER_BIN:=${HOME}/.local/bin}"
    : "${FISH_CONFIG:=${HOME}/.config/fish/config.fish}"
    local fish_config="${FISH_CONFIG}"
    local path_line
    path_line=$(printf 'set -gx PATH %s $PATH' "${USER_BIN}")

    # Ensure parent directory exists (default ~/.config/fish; fixture may retarget)
    _fish_dir=$(dirname "${fish_config}")
    if [ ! -d "${_fish_dir}" ] && ! mkdir -p "${_fish_dir}" 2>/dev/null; then
        unset _fish_dir
        return 1
    fi
    unset _fish_dir

    if [ -f "$fish_config" ] && grep -qF "${path_line}" "$fish_config" 2>/dev/null; then
        return 1  # already present
    fi

    printf "\n# Added by %s installer (%s)\n" "$APP_NAME" "$VERSION" >> "$fish_config"
    printf '%s\n' "${path_line}" >> "$fish_config"

    if [ "${JSON}" -eq 0 ]; then
        out_plain "→ Added ${USER_BIN} to PATH for fish shell"
    fi
    return 0
}

# =============================================================================
# path_add_shell() - Main orchestrator: Add USER_BIN to shell PATHs
# =============================================================================
#
# GENERAL PURPOSE:
# Adds ${USER_BIN} (default ${HOME}/.local/bin) to bash, zsh, and fish
# configuration files if not already present. Creates BASHRC (default
# ~/.bashrc) when missing. Creates ~/.profile when missing so a login shell
# sources ~/.bashrc. Thin orchestrator for path_add_* / path_ensure_profile.
#
# Respects --json mode (silent in JSON).
#
# Last reviewed: 2026-09-09
# =============================================================================

path_add_shell() {
    local added=0
    local shell_config="N/A"
    : "${HOME:=/tmp}"
    : "${BASHRC:=${HOME}/.bashrc}"

    # Bash (create BASHRC if missing, then PATH)
    if path_add_bashrc; then
        added=1
        shell_config="${BASHRC}"
    fi

    # Zsh
    if path_add_zshrc; then
        added=1
        if [ "$shell_config" = "N/A" ]; then
            shell_config="${HOME}/.zshrc"
        else
            shell_config="${shell_config} ${HOME}/.zshrc"
        fi
    fi

    # Fish
    if path_add_fish; then
        added=1
        if [ "$shell_config" = "N/A" ]; then
            shell_config="${HOME}/.config/fish/config.fish"
        else
            shell_config="${shell_config} ${HOME}/.config/fish/config.fish"
        fi
    fi

    # Login rc: create ~/.profile if absent; never overwrite an existing body
    if path_ensure_profile; then
        added=1
        if [ "$shell_config" = "N/A" ]; then
            shell_config="${HOME}/.profile"
        fi
    fi

    if [ "$added" -eq 1 ] && [ "${JSON}" -eq 0 ]; then
        out_plain "→ Restart your terminal or run: source ${shell_config}"
    fi
}

# =============================================================================
# path_rc_test() - Type 0 test-purpose: PATH / profile ensure against --root
# =============================================================================
#
# GENERAL PURPOSE:
# Prove path-ensure / profile-ensure create|modify|noop on files under a
# caller --root tmp folder. Does not write this login's real ~/.bashrc.
# Law: requirement-shell-path-and-shell-support (rc-test).
#
# Last reviewed: 2026-09-09
# =============================================================================

path_rc_test() {
    : "${HOME:=/tmp}"
    : "${USER_BIN:=${HOME}/.local/bin}"
    : "${APP_NAME:=sshd-cli}"
    : "${VERSION:=0}"
    : "${JSON:=0}"
    local root="" file="bashrc" cas="create" created_root=0
    local real_bashrc="${HOME}/.bashrc"
    local real_profile="${HOME}/.profile"
    local dest="" before="" after="" path_line
    path_line=$(printf 'export PATH="%s:$PATH"' "${USER_BIN}")

    while [ $# -gt 0 ]; do
        case "$1" in
            --root)
                shift
                root="${1-}"
                ;;
            --file)
                shift
                file="${1-}"
                ;;
            --case)
                shift
                cas="${1-}"
                ;;
            --feature)
                shift
                ;;
            *)
                out_die "Unknown rc-test operand: $1. Next: ${APP_NAME} rc-test --root <dir> --file bashrc|profile --case create|modify|noop"
                ;;
        esac
        shift
    done

    case "${file}" in
        bashrc|zshrc|profile) ;;
        *)
            out_die "Unknown rc-test --file ${file}. Next: use bashrc, zshrc, or profile."
            ;;
    esac
    case "${cas}" in
        create|modify|noop) ;;
        *)
            out_die "Unknown rc-test --case ${cas}. Next: use create, modify, or noop."
            ;;
    esac

    if [ -z "${root}" ]; then
        root=$(mktemp -d "${TMPDIR:-/tmp}/rc-test.XXXXXX") || out_die "Could not create rc-test root."
        created_root=1
    fi
    if [ ! -d "${root}" ]; then
        mkdir -p "${root}" || out_die "Could not create rc-test --root ${root}."
    fi

    case "${file}" in
        bashrc) dest="${root}/.bashrc"; export BASHRC="${dest}" ;;
        zshrc) dest="${root}/.zshrc"; export ZSHRC="${dest}" ;;
        profile) dest="${root}/.profile"; export PROFILE="${dest}" ;;
    esac

    case "${cas}" in
        create)
            rm -f -- "${dest}"
            ;;
        modify)
            printf '%s\n' "# dongle-keep-rc-test" > "${dest}"
            ;;
        noop)
            if [ "${file}" = "profile" ]; then
                {
                    printf '# BEGIN %s profile source-bashrc\n' "$APP_NAME"
                    printf 'if [ -n "${BASH_VERSION:-}" ]; then\n'
                    printf '    if [ -f "${HOME}/.bashrc" ]; then\n'
                    printf '        . "${HOME}/.bashrc"\n'
                    printf '    fi\n'
                    printf 'fi\n'
                    printf '# END %s profile source-bashrc\n' "$APP_NAME"
                } > "${dest}"
            else
                {
                    printf '# Interactive rc created by %s installer (%s)\n' "$APP_NAME" "$VERSION"
                    printf '# Added by %s installer (%s)\n' "$APP_NAME" "$VERSION"
                    printf '%s\n' "${path_line}"
                } > "${dest}"
            fi
            ;;
    esac

    before=$(cat "${dest}" 2>/dev/null || true)
    case "${file}" in
        bashrc) path_add_bashrc || true ;;
        zshrc)
            [ -f "${dest}" ] || : > "${dest}"
            path_add_zshrc || true
            ;;
        profile) path_ensure_profile || true ;;
    esac
    after=$(cat "${dest}" 2>/dev/null || true)

    if [ -f "${real_bashrc}" ] && [ "${dest}" != "${real_bashrc}" ]; then
        :
    fi
    if [ "${file}" = "bashrc" ] && [ -e "${real_bashrc}" ] && [ "${BASHRC}" != "${real_bashrc}" ]; then
        if [ "${cas}" = "create" ] && [ ! -f "${dest}" ]; then
            out_die "rc-test create did not write ${dest}."
        fi
    fi

    if [ "${file}" = "zshrc" ] && [ "${cas}" = "create" ]; then
        if [ -f "${dest}" ]; then
            out_die "rc-test create must not invent .zshrc."
        fi
        if [ "${JSON}" -eq 1 ]; then
            out_json "out_success" "rc-test create zshrc skipped (do not invent)" \
                "command" "rc-test" "file" "zshrc" "case" "create" "root" "${root}"
            return 0
        fi
        out_plain "→ rc-test create zshrc skipped (do not invent) under ${root}"
        return 0
    fi
    if [ "${cas}" = "create" ] && [ ! -f "${dest}" ]; then
        out_die "rc-test create did not create ${dest}. Next: check --root is writable."
    fi
    if [ "${cas}" = "modify" ]; then
        case "${after}" in
            *dongle-keep-rc-test*) ;;
            *)
                out_die "rc-test modify lost the dongle body in ${dest}."
                ;;
        esac
    fi
    if [ "${cas}" = "noop" ] && [ "${before}" != "${after}" ]; then
        out_die "rc-test noop changed ${dest}."
    fi
    if [ "${file}" != "profile" ]; then
        case "${after}" in
            *"${path_line}"*) ;;
            *)
                out_die "rc-test ${cas} missing exact PATH line in ${dest}."
                ;;
        esac
    else
        case "${after}" in
            *'. "${HOME}/.bashrc"'*) ;;
            *)
                out_die "rc-test ${cas} profile does not source bashrc."
                ;;
        esac
    fi

    if [ "${JSON}" -eq 1 ]; then
        out_json "out_success" "rc-test ${cas} ${file}" \
            "command" "rc-test" \
            "file" "${file}" \
            "case" "${cas}" \
            "root" "${root}"
        return 0
    fi
    out_plain "→ rc-test ${cas} ${file} under ${root}"
    if [ "${created_root}" -eq 1 ]; then
        out_plain "→ Created fixture root ${root} (caller may remove)"
    fi
    return 0
}

# =============================================================================
# util_sha256_file() - SHA-256 hex digest of a file (portable tool chain)
# =============================================================================
#
# GENERAL PURPOSE:
# Print the SHA-256 hex digest of file $1 to stdout for capture.
# Tries sha256sum (GNU/Linux) → shasum -a 256 (macOS) → openssl dgst.
# Return 1 if no tool or file unreadable.
#
# PRINTF/ECHO EXCEPTION (class B – return-via-stdout):
# Digests are data returns for $(util_sha256_file …), not product UI.
# =============================================================================

util_sha256_file() {
    local file="${1-}" dig=""
    if [ -z "${file}" ] || [ ! -f "${file}" ]; then
        return 1
    fi
    if command -v sha256sum >/dev/null 2>&1; then
        dig=$(sha256sum "${file}" 2>/dev/null | awk '{ print $1; exit }')
    elif command -v shasum >/dev/null 2>&1; then
        dig=$(shasum -a 256 "${file}" 2>/dev/null | awk '{ print $1; exit }')
    elif command -v openssl >/dev/null 2>&1; then
        # openssl dgst -sha256 → "SHA256(file)= hex" or "SHA2-256(file)= hex"
        dig=$(openssl dgst -sha256 "${file}" 2>/dev/null | awk '{ print $NF; exit }')
    else
        return 1
    fi
    if [ -z "${dig}" ]; then
        return 1
    fi
    printf '%s\n' "${dig}"
    return 0
}

# =============================================================================
# util_fetch_remote_version() - Extract VERSION="…" from remote SCRIPT_URL body
# =============================================================================
#
# GENERAL PURPOSE:
# Download SCRIPT_URL with curl or wget and print the remote VERSION value.
# Empty stdout on failure (caller fails loud). Class B return-via-stdout.
# =============================================================================

util_fetch_remote_version() {
    local url="${1-}"
    local body=""
    if [ -z "${url}" ]; then
        return 1
    fi
    if command -v curl >/dev/null 2>&1; then
        body=$(curl -fsSL "${url}" 2>/dev/null) || body=""
    elif command -v wget >/dev/null 2>&1; then
        body=$(wget -qO- "${url}" 2>/dev/null) || body=""
    else
        return 1
    fi
    if [ -z "${body}" ]; then
        return 1
    fi
    printf '%s\n' "${body}" | grep '^VERSION="' | head -n1 | cut -d'"' -f2
    return 0
}

# =============================================================================
# util_get_install_bin_path() - Return the correct binary path to operate on
# =============================================================================
#
# GENERAL PURPOSE:
# Returns the full path to the ${APP_NAME} binary that should be used for
# install/uninstall/update operations.
#
# Safe Variable Defaults
#
# Respects --force and --json.
# Respects root vs non-root isolation, --force-user, --force-global.
#
# For non-root: prefers ~/.local/bin, falls back to /usr/local/bin if present.
# For root: always uses /usr/local/bin.
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# This is a minimal defensive helper to reduce repetition while preserving
# the strict root/non-root separation that has been battle-field tested.
#
# CRITICAL: Any change here must maintain zero cross-contamination between
# user and global installations.
#
# PRINTF EXCEPTION (class B – function return-via-stdout):
# Final printf '%s' "${bin_path}" is a data return for $(…) capture — not
# product UI. Warnings use out_warn. Callers must capture the path.
# See requirement-shell-output-requirements.md §2.1.1.
#
# Last reviewed: 2026-07-12
# =============================================================================

util_get_install_bin_path() {
    # --- Safe Variable Defaults ----
    # Defensive defaults - never assume globals are set
    # HOME before any ${HOME}/… path (INC-20260713-001 / set -u order)
    : "${APP_NAME:=app}"
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${FORCE_USER:=0}"
    : "${FORCE_GLOBAL:=0}"
    if [ -n "${PREFIX-}" ] && [ -d "${PREFIX}/bin" ]; then
    : "${GLOBAL_BIN:=${PREFIX}/bin}"
else
    : "${GLOBAL_BIN:=/usr/local/bin}"
fi
    : "${HOME:=/tmp}"
    : "${USER_BIN:=${HOME}/.local/bin}"

    local bin_path=""

    # Explicit force flags take precedence
    if [ "${FORCE_USER}" -eq 1 ]; then
        bin_path="${USER_BIN}/${APP_NAME}"
    elif [ "${FORCE_GLOBAL}" -eq 1 ] || [ "$(id -u)" -eq 0 ]; then
        bin_path="${GLOBAL_BIN}/${APP_NAME}"
    else
        # Normal non-root behavior: prefer user-local, fallback to global
        if [ -f "${USER_BIN}/${APP_NAME}" ]; then
            bin_path="${USER_BIN}/${APP_NAME}"
        elif [ -f "${GLOBAL_BIN}/${APP_NAME}" ]; then
            bin_path="${GLOBAL_BIN}/${APP_NAME}"
            if [ "${JSON}" -eq 0 ] && [ "${QUIET}" -eq 0 ]; then
                out_warn "Global installation found. Operating on it (you may need sudo for uninstall)."
            fi
        else
            bin_path="${USER_BIN}/${APP_NAME}"
        fi
    fi

    printf '%s' "${bin_path}"
}

# =============================================================================
# util_backup() - Create dated backup before any modification
# =============================================================================
#
# GENERAL PURPOSE:
# Creates a dated backup of a file or directory before destructive or
# modifying operations (rm -rf, sed, config changes).
#
# This implements CIAO Principle 10 (Right Backup & Restore Strategy).
#
# ────────────────────────────────────────────────
# CIAO PRINCIPLES APPLIED (v2.9.1)
# ────────────────────────────────────────────────
# Principle 1  (Caution)               - Safe path validation
# Principle 2  (Intentional Verbosity) - Full header + comments
# Principle 3  (Anti-fragile)          - Survives missing files gracefully
# Principle 7  (Reusable)              - Designed for reuse in other projects
# Principle 9  (Safe Temporary Files)  - Uses mktemp where needed
# Principle 10 (Backup Strategy)       - Dated backup with counter
#
# CRITICAL DEFENSIVE RULES:
# - Never modify files without creating backup first.
# - Refuse dangerous paths (/, $HOME, empty).
# - Backup name format: <name>.YYYYMMDD-N.bak
# - All messages go through out_text helpers only.
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# This is the central backup mechanism. Any change must preserve dated backup
# naming and safety checks to prevent accidental data loss.
#
# Last reviewed: 29 April 2026
# =============================================================================

util_backup() {
    # --- Safe Variable Defaults ---
    : "${APP_NAME:=app}"
    : "${HOME:=/tmp}"
    : "${PROJECT_NAME:=${APP_NAME}-demo}"
    : "${PROJECT_DIR:=${HOME}/${PROJECT_NAME}}"
    : "${JSON:=0}"
    : "${QUIET:=0}"

    local target="${1-}"
    local reason="${2:-pre-change}"

    if [ -z "$target" ]; then
        return 1
    fi

    # Safety check
    if [ "$target" = "/" ] || [ "$target" = "${HOME}" ] || [ -z "$target" ]; then
        out_warn "Refusing to backup dangerous path: $target"
        return 1
    fi

    local timestamp
    timestamp=$(date +%Y%m%d)
    local counter=1
    local backup_path

    if [ -d "$target" ]; then
        backup_path="${target}.${timestamp}-${counter}.bak"
        while [ -e "$backup_path" ]; do
            counter=$((counter + 1))
            backup_path="${target}.${timestamp}-${counter}.bak"
        done
        cp -a "$target" "$backup_path" 2>/dev/null && \
            out_info "Backup created: $backup_path (reason: $reason)" || \
            out_warn "Failed to create backup of directory $target"
    elif [ -f "$target" ]; then
        backup_path="${target}.${timestamp}-${counter}.bak"
        while [ -e "$backup_path" ]; do
            counter=$((counter + 1))
            backup_path="${target}.${timestamp}-${counter}.bak"
        done
        cp "$target" "$backup_path" 2>/dev/null && \
            out_info "Backup created: $backup_path (reason: $reason)" || \
            out_warn "Failed to create backup of file $target"
    fi
}

# =============================================================================
# Cache folder paths — per login, per process, under cache/
# =============================================================================
#
# Linux (also Termux, and any host that is not Git Bash and not Mac):
#   /dev/shm/cache/cache-${APP_NAME}-${login}-$$
#   then /tmp/cache/cache-${APP_NAME}-${login}-$$
#   then ${HOME}/.cache/cache-${APP_NAME}-$$
# Git Bash:
#   /tmp/cache/cache-${APP_NAME}-${login}-$$
#   then ${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$
# Mac:
#   /tmp/cache/cache-${APP_NAME}-${login}-$$
#   then ${HOME}/Library/Caches/cache-${APP_NAME}-$$
#   then ${HOME}/cache/cache-${APP_NAME}-$$
# $$ is this process id. Home tiers omit the login (HOME already isolates).
# A missed tier is silent. On Termux the chosen folder is scratch only
# (it may be noexec).
# MUST NOT use /dev/shm/${APP_NAME} or /dev/shm/${APP_NAME}-${USERNAME}.
#
# ALIGNMENT: requirement-shell-cli-storage.md
# Test-purpose: SSHD_CLI_CACHE_HOST=linux|gitbash|mac
#               SSHD_CLI_CACHE_SKIP=preferred skips tier 1 with no message
#
# Last updated: 2026-09-27
# =============================================================================
util_cache_host_kind() {
    case "${SSHD_CLI_CACHE_HOST:-}" in
        linux|gitbash|mac)
            printf '%s' "${SSHD_CLI_CACHE_HOST}"
            return 0
            ;;
    esac
    if [ -n "${MSYSTEM:-}" ]; then
        printf '%s' "gitbash"
        return 0
    fi
    case "$(uname -s 2>/dev/null)" in
        MINGW*|MSYS*) printf '%s' "gitbash" ;;
        Darwin) printf '%s' "mac" ;;
        *) printf '%s' "linux" ;;
    esac
}

util_cache_login() {
    _clogin="${USERNAME:-unknown}"
    case "${_clogin}" in
        *[!A-Za-z0-9._-]*)
            _clogin=$(printf '%s' "${_clogin}" | tr -c 'A-Za-z0-9._-' '_')
            ;;
    esac
    [ -n "${_clogin}" ] || _clogin="unknown"
    printf '%s' "${_clogin}"
    unset _clogin
}

util_cache_volatile_leaf() {
    : "${APP_NAME:=app}"
    printf '%s' "cache-${APP_NAME}-$(util_cache_login)-$$"
}

util_cache_home_leaf() {
    : "${APP_NAME:=app}"
    printf '%s' "cache-${APP_NAME}-$$"
}

util_preferred_cache_dir() {
    : "${APP_NAME:=app}"
    : "${HOME:=/tmp}"
    case "$(util_cache_host_kind)" in
        gitbash|mac)
            printf '%s' "/tmp/cache/$(util_cache_volatile_leaf)"
            ;;
        *)
            printf '%s' "/dev/shm/cache/$(util_cache_volatile_leaf)"
            ;;
    esac
}

util_fallback_cache_dir() {
    : "${APP_NAME:=app}"
    : "${HOME:=/tmp}"
    case "$(util_cache_host_kind)" in
        gitbash)
            printf '%s' "${HOME}/AppData/Local/Temp/$(util_cache_home_leaf)"
            ;;
        mac)
            printf '%s' "${HOME}/Library/Caches/$(util_cache_home_leaf)"
            ;;
        *)
            printf '%s' "/tmp/cache/$(util_cache_volatile_leaf)"
            ;;
    esac
}

util_fallback2_cache_dir() {
    : "${APP_NAME:=app}"
    : "${HOME:=/tmp}"
    case "$(util_cache_host_kind)" in
        gitbash)
            printf '%s' ""
            ;;
        mac)
            printf '%s' "${HOME}/cache/$(util_cache_home_leaf)"
            ;;
        *)
            printf '%s' "${HOME}/.cache/$(util_cache_home_leaf)"
            ;;
    esac
}

# Create one cache tier. Silent on failure (caller tries the next tier).
# Last updated: 2026-09-27
util_cache_try_dir() {
    _cdir="${1:-}"
    if [ -z "${_cdir}" ]; then
        unset _cdir
        return 1
    fi
    _cparent=$(dirname "${_cdir}")
    case "${_cparent}" in
        /dev/shm/cache|/tmp/cache)
            mkdir -m 1777 -p "${_cparent}" 2>/dev/null || mkdir -p "${_cparent}" 2>/dev/null || {
                unset _cdir _cparent
                return 1
            }
            ;;
        *)
            mkdir -p "${_cparent}" 2>/dev/null || {
                unset _cdir _cparent
                return 1
            }
            ;;
    esac
    mkdir -m 0700 -p "${_cdir}" 2>/dev/null || mkdir -p "${_cdir}" 2>/dev/null || {
        unset _cdir _cparent
        return 1
    }
    if [ ! -d "${_cdir}" ] || [ ! -w "${_cdir}" ]; then
        unset _cdir _cparent
        return 1
    fi
    unset _cdir _cparent
    return 0
}

# =============================================================================
# util_resolve_storage() - Cache folder resolver
# =============================================================================
#
# GENERAL PURPOSE:
# Returns the best available cache directory for scratch files.
# Linux: shm leaf, then /tmp leaf, then ${HOME}/.cache leaf.
# Git Bash: /tmp leaf, then AppData Local Temp leaf.
# Mac: /tmp leaf, then Library/Caches leaf, then ${HOME}/cache leaf.
# Volatile leaves are cache-${APP_NAME}-${login}-$$. Home leaves omit login.
# A missed tier is silent (no warning, no error). Error only if every tier fails.
# MUST NOT restore /dev/shm/${APP_NAME} or /dev/shm/${APP_NAME}-${USERNAME}.
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# Dropping ${login} or $$ from a volatile leaf, or warning on a skipped tier,
# is a cache isolation regression.
#
# ECHO EXCEPTION (class B – function return-via-stdout):
# echo of cache paths is a data return for $(util_resolve_storage) capture,
# not a product user message. Failures use out_die.
# See requirement-shell-output-requirements.md §2.1.1.
#
# Lessons Learned (CIAO Reflection):
# 2026-07-13: STORAGE_DIR was bare/unset on third fallback (INC-20260713-001 P1).
# 2026-07-16: Create chosen tier root before echo (fail-closed) for all tiers.
# 2026-09-11: Git Bash /dev/shm mkdir must not abort the chain (INC-20260911-001).
# 2026-09-17: Preferred leaf moved under /dev/shm/cache/.
# 2026-09-27: Leaf is cache-${APP_NAME}-${login}-$$ so logins do not share
#             one directory. Tier misses stay silent.
#
# Last updated: 2026-09-27
# SSOT: requirement-shell-cli-storage.md
# =============================================================================
util_resolve_storage() {
    : "${USERNAME:=unknown}"
    : "${APP_NAME:=app}"
    : "${HOME:=/tmp}"

    _storage_candidate=""
    _pref=""
    _fb1=""
    _fb2=""
    if [ "${SSHD_CLI_CACHE_SKIP:-}" != "preferred" ]; then
        _pref=$(util_preferred_cache_dir)
        if util_cache_try_dir "${_pref}"; then
            _storage_candidate="${_pref}"
        fi
    fi
    if [ -z "${_storage_candidate}" ]; then
        _fb1=$(util_fallback_cache_dir)
        if util_cache_try_dir "${_fb1}"; then
            _storage_candidate="${_fb1}"
        fi
    fi
    if [ -z "${_storage_candidate}" ]; then
        _fb2=$(util_fallback2_cache_dir)
        if [ -n "${_fb2}" ] && util_cache_try_dir "${_fb2}"; then
            _storage_candidate="${_fb2}"
        fi
    fi
    if [ -z "${_storage_candidate}" ]; then
        out_die "Cannot create cache folder"
    fi
    echo "${_storage_candidate}"
    unset _storage_candidate _pref _fb1 _fb2
    return 0
}

# =============================================================================
# util_resolve_persistent_storage() - Durable this-login folder (not /dev/shm)
# =============================================================================
#
# GENERAL PURPOSE:
# preferred-remote, download-folders, and other leaves that must survive
# reboot live under ${HOME}/.local/${APP_NAME}, not the volatile cache chain.
#
# ALIGNMENT: requirement-shell-config-backup.md · requirement-shell-cli-storage.md
# Last updated: 2026-09-11
# =============================================================================
util_persistent_storage_dir() {
    : "${APP_NAME:=sshd-cli}"
    : "${HOME:=/tmp}"
    printf '%s' "${HOME}/.local/${APP_NAME}"
}

util_resolve_persistent_storage() {
    : "${APP_NAME:=sshd-cli}"
    : "${HOME:=/tmp}"
    _persist=$(util_persistent_storage_dir)
    case "${_persist}" in
        */.local/bin|*/.local/bin/)
            out_die "Persistence storage must not be the install bin directory ${_persist}"
            ;;
    esac
    if ! mkdir -p "${_persist}" 2>/dev/null || [ ! -w "${_persist}" ]; then
        out_die "Cannot create persistence storage ${_persist}"
    fi
    echo "${_persist}"
    unset _persist
    return 0
}

# =============================================================================
# prompt_ask() - Defensive general-purpose interactive prompt with default
# =============================================================================
#
# GENERAL PURPOSE:
# Displays a message, shows current/default values if available, and waits
# for user input. Returns the answer (or the default if user presses Enter).
# Fully respects --quiet, --json, and non-TTY environments.
# Uses the centralized output system (out_info / out_msg_n).
#
# This is the **Single Source of Truth** for all simple value prompts in the project.
#
# CIAO PRINCIPLES APPLIED:
# - Caution (Principle 1): Multiple guards prevent prompting in non-interactive contexts.
# - Intentional (Principle 2): Clear behavior for TTY vs non-TTY and quiet/JSON modes.
# - Anti-fragile (Principle 3): Works reliably across different terminals and invocation methods.
# - Over-protect (Principle 18): Trusts explicit INTERACTIVE=1 from caller when low-level TTY check is flaky.
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# Past AI assistants have repeatedly broken this by using raw printf/echo + read,
# which violates the single output system, quiet/json handling, and TTY detection.
#
# PRINTF EXCEPTION (class B – function return-via-stdout only):
# printf '%s' "${default|answer}" returns the chosen value for $(prompt_ask …)
# capture. It is NOT the prompt UI. User-visible prompt text MUST stay on
# out_info / out_msg_n. Do not replace those with raw printf + read.
# See requirement-shell-output-requirements.md §2.1.1.
#
# Last updated: 2026-09-02
# =============================================================================

prompt_ask() {
    # --- Safe Variable Defaults ---
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${TTY:=0}"
    : "${INTERACTIVE:=0}"

    # set -u safe: missing args become empty defaults (INC-20260713-001 class)
    local message="${1-}"
    local default="${2-}"
    local current="${3-}"

    # Never prompt in non-interactive modes
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        printf '%s' "${default}"
        return 0
    fi

    # Consume process TTY (measured once at startup). INTERACTIVE=1 is the
    # documented override when low-level TTY checks are flaky.
    if [ "${TTY}" -ne 1 ] && [ "${INTERACTIVE}" -ne 1 ]; then
        printf '%s' "${default}"
        return 0
    fi

    # Show current value if present
    if [ -n "${current}" ]; then
        out_info "Current: ${current}"
    fi

    # Show default
    if [ -n "${default}" ]; then
        out_info "Default: ${default}"
    fi

    out_msg_n "${message}: "

    local answer=""
    read -r answer || true

    if [ -z "${answer}" ]; then
        printf '%s' "${default}"
    else
        printf '%s' "${answer}"
    fi
}

# =============================================================================
# prompt_yes_no() - Defensive interactive yes/no confirmation prompt
# =============================================================================
#
# GENERAL PURPOSE:
# Displays a message and waits for (y/N) confirmation.
# Returns 0 if user says yes, returns 1 (non-zero) if user says no or cancels.
#
# CRITICAL DEFENSIVE RULES (DO NOT VIOLATE):
# 1. Must ALWAYS go through single source of truth (out_msg_n + out_text)
# 2. Must respect --quiet and --json (never show prompt in those modes)
# 3. Must NEVER use raw printf/echo for user-visible prompt text (product UI)
#    (class-B return-via-stdout does not apply here — this helper uses exit status)
# 4. Must work correctly in non-interactive / curl | sh environments
# 5. Must preserve TTY detection and color handling via out_text
# 6. This is the SINGLE SOURCE OF TRUTH for all yes/no confirmations in the project.
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# Past AI assistants have repeatedly replaced this kind of prompt with
# raw printf + read, breaking consistency with out_text(), --quiet,
# --json, TTY detection, and the overall defensive design.
#
# This helper exists specifically to prevent that regression and to enforce
# CIAO-Lite principles of Caution, Intentionality, and Over-protect.
#
# Last updated: 2026-09-02
# =============================================================================

prompt_yes_no() {
    # --- Safe Variable Defaults ----
    # Defensive defaults - never assume globals are set
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${TTY:=0}"

    local message="$1"

    # Never show prompt in quiet or json mode
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        return 1   # treat as "no" in non-interactive modes
    fi

    # Consume process TTY (measured once at startup; no second [ -t).
    if [ "${TTY}" -ne 1 ]; then
        return 1
    fi

    out_msg_n "${message} (y/N)? "

    local answer=""
    read -r answer || true

    case "$answer" in
        [Yy]*|[Yy][Ee][Ss]*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}


# =============================================================================
# app_about() - Display diagnostic information about the current environment
# =============================================================================
#
# GENERAL PURPOSE:
# Shows detailed diagnostic information: version, installation status (global + local),
# current shell, TTY/interactive status, user, and helpful next steps.
#
# Fully respects --quiet and --json modes.
# In JSON mode: outputs exactly ONE clean, machine-readable JSON object.
# In quiet mode: prints nothing.
#
# This function provides real value to users (unlike the previous overly simple version)
# and should be kept in sync with the overall CIAO design and README.md.
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# Designed to be reusable in other CIAO projects.
# Last updated: 2026-09-27
# Cache lines: used, preferred, 1st fallback, 2nd fallback when this host has one,
# plus Persistence storage. A skipped cache tier prints no warning.
# =============================================================================

# =============================================================================
# util_get_current_shell() - Detect current / parent shell name
# =============================================================================
#
# GENERAL PURPOSE:
# Returns a best-effort shell command name for diagnostics (about).
# Prefer parent shell when the current process is sh/dash/ash/the app itself.
#
# PRINTF EXCEPTION (class B – function return-via-stdout):
# Final printf '%s' "$shell" (and echo fallbacks inside $(…)) are data
# returns for capture by app_about — not product messages. Display uses out_*.
# See requirement-shell-output-requirements.md §2.1.1.
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# Nested functions are not portable POSIX; this must stay top-level.
#
# Last reviewed: 2026-07-12
# =============================================================================
util_get_current_shell() {
    local shell="unknown"
    shell=$(ps -p $$ -o comm= 2>/dev/null | tr -d '()' || echo "unknown")

    if [ "$shell" = "${APP_NAME}" ] || [ "$shell" = "sh" ] || \
       [ "$shell" = "dash" ] || [ "$shell" = "ash" ]; then
        local parent_pid
        parent_pid=$(ps -p $$ -o ppid= 2>/dev/null | tr -d ' ')
        if [ -n "$parent_pid" ]; then
            shell=$(ps -p "$parent_pid" -o comm= 2>/dev/null | tr -d '()' || echo "$shell")
        fi
    fi
    printf '%s' "$shell"
}



# =============================================================================
# Domain: OpenSSH sshd helper (prefix sshd_*)
# Specialized from bootstrap origin selfmanaged (A → B only).
# Product law: requirement-domain-sshd.md
# Host writes fail closed without in-tool sudo: re-run as root on Linux, or
# use Termux where PREFIX paths belong to this login.
# Last updated: 2026-09-04
# =============================================================================

sshd_is_termux() {
    : "${PREFIX:=}"
    if [ -n "${PREFIX}" ] && [ -d "${PREFIX}/bin" ]; then
        case "${PREFIX}" in
            */com.termux/*) return 0 ;;
        esac
    fi
    if [ -n "${TERMUX_VERSION-}" ] || [ -d /data/data/com.termux/files/usr ]; then
        return 0
    fi
    return 1
}

# =============================================================================
# sshd_is_git_bash() / sshd_is_windows_cmd() / sshd_is_normal_user_only_cli()
# =============================================================================
#
# GENERAL PURPOSE:
# Termux, Git Bash (Git for Windows MSYS/MINGW), and Windows cmd (Command
# Prompt / Windows command-line) are a command line for normal user only:
# Type 1 (admin privilege) and Type 2 (dedicated system user privilege)
# stay unused. Union helper covers all three instances.
#
# ALIGNMENT (live requirements only):
# - requirement-shell-cli-interface.md
# - requirement-shell-termux-ish.md
#
# Last updated: 2026-09-05
# =============================================================================

sshd_is_git_bash() {
    case "${MSYSTEM-}" in
        MINGW*|MSYS*|UCRT*|CLANG*) return 0 ;;
    esac
    _uname=$(uname -s 2>/dev/null || true)
    case "${_uname}" in
        MINGW*|MSYS*) return 0 ;;
    esac
    return 1
}

sshd_is_windows_cmd() {
    if sshd_is_git_bash; then
        return 1
    fi
    if [ -n "${WSL_DISTRO_NAME-}" ]; then
        return 1
    fi
    _uname=$(uname -s 2>/dev/null || true)
    case "${_uname}" in
        CYGWIN*) return 1 ;;
    esac
    case "${OS-}" in
        Windows_NT) return 0 ;;
    esac
    case "${ComSpec-}${COMSPEC-}" in
        *[Cc][Mm][Dd].[Ee][Xx][Ee]*) return 0 ;;
    esac
    case "${_uname}" in
        Linux) return 1 ;;
    esac
    return 1
}

sshd_is_normal_user_only_cli() {
    if sshd_is_termux; then
        return 0
    fi
    if sshd_is_git_bash; then
        return 0
    fi
    if sshd_is_windows_cmd; then
        return 0
    fi
    return 1
}

# Host OS display name for operator copy (not a platform class).
# /etc/os-release NAME= first; else uname -s; else Linux.
sshd_os_name() {
    _name=""
    if [ -r /etc/os-release ]; then
        _name=$(grep -E '^NAME=' /etc/os-release 2>/dev/null | head -n 1 || true)
        _name=${_name#NAME=}
        _name=${_name#\"}
        _name=${_name%\"}
        _name=${_name#\'}
        _name=${_name%\'}
    fi
    if [ -z "${_name}" ]; then
        _name=$(uname -s 2>/dev/null || true)
    fi
    if [ -z "${_name}" ]; then
        _name="Linux"
    fi
    printf '%s' "${_name}"
    unset _name
}

# Numbered menu rows 2/3/4 (start/stop/restart): this login on a
# command-line-for-normal-user-only host, or a root login on POSIX Linux.
sshd_menu_show_daemon_rows() {
    if sshd_is_normal_user_only_cli; then
        return 0
    fi
    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        return 0
    fi
    return 1
}

# POSIX Linux systemd host: not Termux/Git Bash/Windows cmd, runtime is
# systemd, and systemctl exists. requirement-domain-sshd §2.2.1.
sshd_is_systemd_host() {
    if sshd_is_normal_user_only_cli; then
        return 1
    fi
    if [ ! -d /run/systemd/system ]; then
        return 1
    fi
    command -v systemctl >/dev/null 2>&1 || return 1
    return 0
}

sshd_systemd_load_state() {
    _su="${1-}"
    if [ -z "${_su}" ]; then
        printf '%s' "not-found"
        unset _su
        return 0
    fi
    _st=$(systemctl show -p LoadState --value "${_su}" 2>/dev/null || true)
    _st=$(printf '%s' "${_st}" | tr -d '\n\r')
    if [ -z "${_st}" ]; then
        _st="not-found"
    fi
    printf '%s' "${_st}"
    unset _su _st
}

sshd_systemd_unit_exists() {
    _st=$(sshd_systemd_load_state "${1-}")
    if [ "${_st}" = "not-found" ]; then
        unset _st
        return 1
    fi
    unset _st
    return 0
}

sshd_systemd_is_active() {
    _su="${1-}"
    if [ -z "${_su}" ]; then
        return 1
    fi
    _act=$(systemctl is-active "${_su}" 2>/dev/null || true)
    _act=$(printf '%s' "${_act}" | tr -d '\n\r')
    if [ "${_act}" = "active" ]; then
        unset _su _act
        return 0
    fi
    unset _su _act
    return 1
}

sshd_systemd_main_pid() {
    _su="${1-}"
    if [ -z "${_su}" ]; then
        return 1
    fi
    _mp=$(systemctl show -p MainPID --value "${_su}" 2>/dev/null || true)
    _mp=$(printf '%s' "${_mp}" | tr -d '\n\r')
    case "${_mp}" in
        ""|0)
            unset _su _mp
            return 1
            ;;
    esac
    printf '%s' "${_mp}"
    unset _su _mp
    return 0
}

sshd_systemd_triggered_by() {
    _su="${1-}"
    if [ -z "${_su}" ]; then
        return 1
    fi
    _tb=$(systemctl show -p TriggeredBy --value "${_su}" 2>/dev/null || true)
    _tb=$(printf '%s' "${_tb}" | tr -d '\n\r')
    if [ -z "${_tb}" ]; then
        unset _su _tb
        return 1
    fi
    printf '%s' "${_tb}"
    unset _su _tb
    return 0
}

# Prints ssh.service or sshd.service, or returns 1 when none.
sshd_systemd_unit() {
    if ! sshd_is_systemd_host; then
        return 1
    fi
    _ssh_ex=1
    _sshd_ex=1
    if sshd_systemd_unit_exists "ssh.service"; then
        _ssh_ex=0
    fi
    if sshd_systemd_unit_exists "sshd.service"; then
        _sshd_ex=0
    fi
    if [ "${_ssh_ex}" -eq 0 ] && [ "${_sshd_ex}" -eq 0 ]; then
        if sshd_systemd_is_active "sshd.service" && ! sshd_systemd_is_active "ssh.service"; then
            printf '%s' "sshd.service"
        else
            printf '%s' "ssh.service"
        fi
        unset _ssh_ex _sshd_ex
        return 0
    fi
    if [ "${_ssh_ex}" -eq 0 ]; then
        printf '%s' "ssh.service"
        unset _ssh_ex _sshd_ex
        return 0
    fi
    if [ "${_sshd_ex}" -eq 0 ]; then
        printf '%s' "sshd.service"
        unset _ssh_ex _sshd_ex
        return 0
    fi
    unset _ssh_ex _sshd_ex
    return 1
}

# =============================================================================
# sshd_pkg_ensure() - Termux: pkg install openssh and termux-auth
# =============================================================================
#
# GENERAL PURPOSE:
# On Termux, ensure OpenSSH sshd and termux-auth (passwd for SSH login) are
# installed via `pkg install -y openssh termux-auth`. No-op on POSIX Linux
# (operator uses the distro package manager; this CLI does not wrap apt).
# Idempotent: already-installed packages succeed. Non-interactive: `-y`.
#
# Product law: requirement-shell-termux-ish.md (invoke) · requirement-domain-sshd.md (package names)
#
# Last reviewed: 2026-09-05
# =============================================================================

sshd_pkg_ensure() {
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${APP_NAME:=sshd-cli}"

    if ! sshd_is_termux; then
        return 0
    fi

    if ! command -v pkg >/dev/null 2>&1; then
        out_die "Termux package tool pkg was not found, so openssh and termux-auth could not be installed. Next: open a Termux session where pkg works, then run: ${APP_NAME} install"
    fi

    if [ "${JSON}" -eq 0 ] && [ "${QUIET}" -eq 0 ]; then
        out_info "Ensuring Termux packages: openssh termux-auth"
    fi

    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        if ! pkg install -y openssh termux-auth >/dev/null 2>&1; then
            out_die "Could not install openssh and termux-auth with pkg. Next: run: pkg install openssh termux-auth"
        fi
    else
        if ! pkg install -y openssh termux-auth; then
            out_die "Could not install openssh and termux-auth with pkg. Next: run: pkg install openssh termux-auth"
        fi
    fi

    if [ "${JSON}" -eq 0 ] && [ "${QUIET}" -eq 0 ]; then
        out_success "Termux packages openssh and termux-auth are installed."
        out_info "If you will use a password to SSH in, set one with: passwd"
    fi
    return 0
}

# =============================================================================
# sshd_wake_lock_*() - Termux Android wake lock
# =============================================================================
#
# GENERAL PURPOSE:
# On Termux, ask Android to keep the CPU awake so sshd can listen with the
# screen off (termux-wake-lock). Off Termux: no-op. The lock is Termux-app-wide:
# MUST NOT auto-unlock on sshd stop.
#
# Product law: requirement-shell-termux-ish.md · requirement-domain-sshd.md
#
# Last reviewed: 2026-09-07
# =============================================================================

# Returns: 0 acquired · 1 not Termux · 2 helper missing · 3 helper failed
sshd_termux_wake_lock_invoke() {
    if ! sshd_is_termux; then
        return 1
    fi
    if ! command -v termux-wake-lock >/dev/null 2>&1; then
        return 2
    fi
    if ! termux-wake-lock >/dev/null 2>&1; then
        return 3
    fi
    return 0
}

sshd_termux_wake_unlock_invoke() {
    if ! sshd_is_termux; then
        return 1
    fi
    if ! command -v termux-wake-unlock >/dev/null 2>&1; then
        return 2
    fi
    if ! termux-wake-unlock >/dev/null 2>&1; then
        return 3
    fi
    return 0
}

sshd_wake_lock_acquire() {
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${APP_NAME:=sshd-cli}"
    _wl_rc=0
    sshd_termux_wake_lock_invoke || _wl_rc=$?
    if [ "${_wl_rc}" -eq 1 ]; then
        unset _wl_rc
        return 0
    fi
    if [ "${_wl_rc}" -eq 0 ]; then
        if [ "${JSON}" -eq 0 ] && [ "${QUIET}" -eq 0 ]; then
            out_info "Android wake lock acquired (Termux keeps the CPU awake so sshd can listen with the screen off). Re-acquire: ${APP_NAME} wake-lock"
        fi
        unset _wl_rc
        return 0
    fi
    if [ "${JSON}" -eq 0 ] && [ "${QUIET}" -eq 0 ]; then
        out_warn "Could not acquire the Android wake lock (termux-wake-lock missing or failed). sshd may stop when the screen is off. Next: run: pkg install termux-tools then ${APP_NAME} wake-lock"
    fi
    unset _wl_rc
    return 0
}

sshd_cmd_wake_lock() {
    : "${JSON:=0}"
    : "${APP_NAME:=sshd-cli}"
    if ! sshd_is_termux; then
        if [ "${JSON}" -eq 1 ]; then
            out_json "out_success" "Not Termux; Android wake lock is a no-op." "held" "n/a"
        else
            out_success "Not Termux; Android wake lock is a Termux helper — nothing to acquire on this host."
        fi
        return 0
    fi
    _wl_rc=0
    sshd_termux_wake_lock_invoke || _wl_rc=$?
    if [ "${_wl_rc}" -eq 2 ]; then
        out_die "Termux wake-lock helper was not found, so the Android wake lock could not be acquired. Next: run: pkg install termux-tools then ${APP_NAME} wake-lock"
    fi
    if [ "${_wl_rc}" -eq 3 ]; then
        out_die "termux-wake-lock failed. Next: run: termux-wake-lock then ${APP_NAME} wake-lock"
    fi
    unset _wl_rc
    if [ "${JSON}" -eq 1 ]; then
        out_json "out_success" "Android wake lock acquired." "held" "yes"
    else
        out_success "Android wake lock acquired. Termux will keep the CPU awake so sshd can listen with the screen off."
        out_info "If Android drops it, run: ${APP_NAME} wake-lock"
    fi
}

sshd_cmd_wake_unlock() {
    : "${JSON:=0}"
    : "${APP_NAME:=sshd-cli}"
    if ! sshd_is_termux; then
        if [ "${JSON}" -eq 1 ]; then
            out_json "out_success" "Not Termux; Android wake lock is a no-op." "held" "n/a"
        else
            out_success "Not Termux; Android wake unlock is a Termux helper — nothing to release on this host."
        fi
        return 0
    fi
    _wl_rc=0
    sshd_termux_wake_unlock_invoke || _wl_rc=$?
    if [ "${_wl_rc}" -eq 2 ]; then
        out_die "Termux wake-unlock helper was not found, so the Android wake lock could not be released. Next: run: pkg install termux-tools then ${APP_NAME} wake-unlock"
    fi
    if [ "${_wl_rc}" -eq 3 ]; then
        out_die "termux-wake-unlock failed. Next: run: termux-wake-unlock"
    fi
    unset _wl_rc
    if [ "${JSON}" -eq 1 ]; then
        out_json "out_success" "Android wake lock released." "held" "no"
    else
        out_success "Android wake lock released. Android may sleep Termux when the screen is off."
    fi
}

sshd_resolve() {
    : "${HOME:=/tmp}"
    SSHD_PLATFORM="posix"
    SSHD_BIN=""
    SSHD_CONFIG=""
    SSHD_HOSTKEY_DIR=""
    SSHD_PIDFILE=""
    SSHD_DEFAULT_PORT="22"
    SSHD_AUTH_KEYS="${HOME}/.ssh/authorized_keys"
    SSHD_USER_SSH_DIR="${HOME}/.ssh"

    if sshd_is_termux; then
        SSHD_PLATFORM="termux"
        : "${PREFIX:=/data/data/com.termux/files/usr}"
        SSHD_DEFAULT_PORT="8022"
        if [ -x "${PREFIX}/bin/sshd" ]; then
            SSHD_BIN="${PREFIX}/bin/sshd"
        fi
        SSHD_CONFIG="${PREFIX}/etc/ssh/sshd_config"
        SSHD_HOSTKEY_DIR="${PREFIX}/etc/ssh"
        SSHD_PIDFILE="${PREFIX}/var/run/sshd.pid"
    else
        SSHD_CONFIG="/etc/ssh/sshd_config"
        SSHD_HOSTKEY_DIR="/etc/ssh"
        if [ -d /run ]; then
            SSHD_PIDFILE="/run/sshd.pid"
        else
            SSHD_PIDFILE="/var/run/sshd.pid"
        fi
    fi

    if [ -z "${SSHD_BIN}" ] && [ "${SSHD_PLATFORM}" != "termux" ]; then
        if command -v sshd >/dev/null 2>&1; then
            SSHD_BIN=$(command -v sshd)
        elif [ -x /usr/sbin/sshd ]; then
            SSHD_BIN="/usr/sbin/sshd"
        fi
    fi

    SSHD_PORT="${SSHD_DEFAULT_PORT}"
    if [ -n "${SSHD_CONFIG}" ] && [ -r "${SSHD_CONFIG}" ]; then
        _port_line=$(grep -E '^[[:space:]]*Port[[:space:]]+[0-9]+' "${SSHD_CONFIG}" 2>/dev/null | tail -n 1 || true)
        if [ -n "${_port_line}" ]; then
            SSHD_PORT=$(printf '%s' "${_port_line}" | awk '{print $2}')
        fi
        unset _port_line
    fi
}

sshd_running_pid() {
    sshd_resolve
    if _unit=$(sshd_systemd_unit); then
        if sshd_systemd_is_active "${_unit}"; then
            if _pid=$(sshd_systemd_main_pid "${_unit}"); then
                printf '%s' "${_pid}"
                unset _unit _pid
                return 0
            fi
            printf '%s' "0"
            unset _unit _pid
            return 0
        fi
        unset _unit
        return 1
    fi
    unset _unit
    if [ -n "${SSHD_PIDFILE}" ] && [ -r "${SSHD_PIDFILE}" ]; then
        _pid=$(tr -d ' \n\r\t' < "${SSHD_PIDFILE}" 2>/dev/null || true)
        if [ -n "${_pid}" ] && kill -0 "${_pid}" 2>/dev/null; then
            printf '%s' "${_pid}"
            unset _pid
            return 0
        fi
        unset _pid
    fi
    # Termux: never treat a host Linux sshd (pgrep -x sshd) as this login's daemon.
    if [ "${SSHD_PLATFORM}" = "termux" ]; then
        if [ -n "${SSHD_BIN}" ] && [ -x "${SSHD_BIN}" ] && command -v pgrep >/dev/null 2>&1; then
            _pid=$(pgrep -f "${SSHD_BIN}" 2>/dev/null | head -n 1 || true)
            if [ -n "${_pid}" ] && kill -0 "${_pid}" 2>/dev/null; then
                printf '%s' "${_pid}"
                unset _pid
                return 0
            fi
            unset _pid
        fi
        return 1
    fi
    if command -v pgrep >/dev/null 2>&1; then
        _pid=$(pgrep -x sshd 2>/dev/null | head -n 1 || true)
        if [ -n "${_pid}" ]; then
            printf '%s' "${_pid}"
            unset _pid
            return 0
        fi
        unset _pid
    fi
    _pid=$(ps -e -o pid= -o comm= 2>/dev/null | awk '$2=="sshd" {print $1; exit}' || true)
    if [ -n "${_pid}" ]; then
        printf '%s' "${_pid}"
        unset _pid
        return 0
    fi
    unset _pid
    return 1
}

# sshd_openssh_server_hint() - operator next step when sshd is missing
#
# Does not run dnf, apt, brew, or pkg. Termux uses sshd-cli install instead.
# POSIX Linux names both package tools in one sentence (no os-release branch).
# Product law: requirement-shell-fedora-redhat-cli-coding.md
#              requirement-shell-debian-cli-coding.md
#              requirement-shell-macos-cli-coding.md
#              requirement-shell-windows-git-bash-cli-coding.md
#              requirement-shell-exit-condition.md
# Last updated: 2026-10-14
sshd_openssh_server_hint() {
    : "${APP_NAME:=sshd-cli}"
    if sshd_is_git_bash; then
        printf '%s' "Git Bash does not provide sshd. Install OpenSSH for Windows, then retry ${APP_NAME} start."
        return 0
    fi
    if sshd_is_windows_cmd; then
        printf '%s' "Windows cmd does not provide sshd. Install OpenSSH for Windows, then retry ${APP_NAME} start."
        return 0
    fi
    _hint_uname=$(uname -s 2>/dev/null || true)
    if [ "${_hint_uname}" = "Darwin" ]; then
        unset _hint_uname
        printf '%s' "install the OpenSSH server on this Mac, then retry ${APP_NAME} start."
        return 0
    fi
    unset _hint_uname
    printf '%s' "install the openssh-server package with this OS package tool (dnf on Fedora and RHEL, apt on Debian and Ubuntu). ${APP_NAME} does not run that command. Then retry ${APP_NAME} start."
}

sshd_need_bin() {
    sshd_resolve
    if [ -z "${SSHD_BIN}" ] || [ ! -x "${SSHD_BIN}" ]; then
        if [ "${SSHD_PLATFORM}" = "termux" ]; then
            out_die "OpenSSH sshd is not installed. Next: run ${APP_NAME} install (it runs: pkg install openssh termux-auth), then retry ${APP_NAME} start"
        fi
        _hint=$(sshd_openssh_server_hint)
        out_die "OpenSSH sshd is not installed. Next: ${_hint}"
    fi
}

sshd_need_writable() {
    _target="$1"
    _dir=$(dirname "${_target}")
    if [ -e "${_target}" ]; then
        if [ -w "${_target}" ]; then
            unset _target _dir
            return 0
        fi
    elif [ -d "${_dir}" ] && [ -w "${_dir}" ]; then
        unset _target _dir
        return 0
    fi
    if sshd_is_termux; then
        out_die "This login cannot write ${_target}. On Termux these paths are usually yours after ${APP_NAME} install."
    fi
    out_die "This login cannot write ${_target}. Re-run as root."
}

# =============================================================================
# sshd_ipv4_usable() - Reject loopback / link-local / empty
# =============================================================================

sshd_ipv4_usable() {
    case "${1-}" in
        ""|127.*|0.*|255.255.255.255|169.254.*) return 1 ;;
        *.*.*.*)
            case "${1}" in
                *[!0-9.]*) return 1 ;;
                *) return 0 ;;
            esac
            ;;
        *) return 1 ;;
    esac
}

# =============================================================================
# sshd_ifconfig_ipv4() - inet IPv4 from ifconfig [iface]
# =============================================================================
#
# GENERAL PURPOSE:
# Parse `ifconfig` output for a usable inet address. With an operand, run
# `ifconfig <iface>` (Termux Wi-Fi is wlan0). With no operand, parse full
# `ifconfig`. Handles `inet 192.0.2.1` and `inet addr:192.0.2.1`.
# Return-via-stdout (class B). Empty if none.
#
# Product law: requirement-domain-sshd.md
#
# Last reviewed: 2026-09-05
# =============================================================================

sshd_ifconfig_ipv4() {
    _ifc_out=""
    if command -v ifconfig >/dev/null 2>&1; then
        if [ -n "${1-}" ]; then
            _ifc_out=$(ifconfig "$1" 2>/dev/null || true)
        else
            _ifc_out=$(ifconfig 2>/dev/null || true)
        fi
    elif command -v busybox >/dev/null 2>&1; then
        if [ -n "${1-}" ]; then
            _ifc_out=$(busybox ifconfig "$1" 2>/dev/null || true)
        else
            _ifc_out=$(busybox ifconfig 2>/dev/null || true)
        fi
    else
        unset _ifc_out
        return 0
    fi
    printf '%s\n' "${_ifc_out}" | awk '
        /inet / {
            ip = ""
            for (i = 1; i <= NF; i++) {
                if ($i == "inet") {
                    ip = $(i + 1)
                    sub(/^addr:/, "", ip)
                    break
                }
            }
            split(ip, a, "/")
            ip = a[1]
            if (ip ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ && ip !~ /^127\./ && ip !~ /^169\.254\./ && ip !~ /^0\./) {
                print ip
                exit
            }
        }
    '
    unset _ifc_out
}

# =============================================================================
# sshd_lan_ipv4() - Live LAN IPv4 for an ssh connect hint
# =============================================================================
#
# GENERAL PURPOSE:
# Termux-first: `ifconfig wlan0` inet address. Then wlan1, then any ifconfig
# inet. Then `ip route get` src / `ip addr`. Never invent a host token.
# Return-via-stdout (class B). Empty string if none found.
#
# Product law: requirement-domain-sshd.md
#
# Last reviewed: 2026-09-05
# =============================================================================

sshd_lan_ipv4() {
    _ip=""
    if command -v ifconfig >/dev/null 2>&1 || command -v busybox >/dev/null 2>&1; then
        _ip=$(sshd_ifconfig_ipv4 wlan0)
        if ! sshd_ipv4_usable "${_ip}"; then
            _ip=$(sshd_ifconfig_ipv4 wlan1)
        fi
        if ! sshd_ipv4_usable "${_ip}"; then
            _ip=$(sshd_ifconfig_ipv4)
        fi
    fi
    if ! sshd_ipv4_usable "${_ip}" && command -v ip >/dev/null 2>&1; then
        _line=$(ip route get 1.1.1.1 2>/dev/null || ip route get 8.8.8.8 2>/dev/null || true)
        _ip=$(printf '%s\n' "${_line}" | awk '{
            for (i = 1; i <= NF; i++) {
                if ($i == "src") { print $(i + 1); exit }
            }
        }')
        unset _line
        if ! sshd_ipv4_usable "${_ip}"; then
            _ip=$(ip addr 2>/dev/null | awk '/inet / {
                split($2, a, "/")
                ip = a[1]
                if (ip ~ /^127\./) next
                if (ip ~ /^169\.254\./) next
                if (ip ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/) { print ip; exit }
            }')
        fi
    fi
    if sshd_ipv4_usable "${_ip}"; then
        printf '%s' "${_ip}"
    fi
    unset _ip
}

# =============================================================================
# sshd_connect_cmd() - Recommended ssh client line (stdout)
# =============================================================================
#
# GENERAL PURPOSE:
# Build `ssh -p <port> <user>@<lan-ipv4>` from live port, id -un, and
# sshd_lan_ipv4. Empty stdout if no live IPv4 — never a placeholder host.
# Return-via-stdout (class B).
#
# Product law: requirement-domain-sshd.md
#
# Last reviewed: 2026-09-05
# =============================================================================

sshd_connect_cmd() {
    : "${SSHD_PORT:=22}"
    : "${USERNAME:=unknown}"
    _user="${USERNAME}"
    if [ -z "${_user}" ] || [ "${_user}" = "unknown" ]; then
        _user=$(id -un 2>/dev/null || echo "user")
    fi
    _lan=$(sshd_lan_ipv4)
    if sshd_ipv4_usable "${_lan}"; then
        printf 'ssh -p %s %s@%s' "${SSHD_PORT}" "${_user}" "${_lan}"
    fi
    unset _user _lan
}

sshd_cmd_status() {
    sshd_resolve
    _pid=""
    _running="false"
    if _pid=$(sshd_running_pid); then
        _running="true"
    else
        _pid=""
    fi
    : "${_pid:=}"
    _connect=$(sshd_connect_cmd)
    _sysd="false"
    _unit=""
    _uact="false"
    if sshd_is_systemd_host; then
        _sysd="true"
        _unit=$(sshd_systemd_unit || true)
        if [ -n "${_unit}" ] && sshd_systemd_is_active "${_unit}"; then
            _uact="true"
        fi
    fi
    if [ "${JSON}" -eq 1 ]; then
        out_json "status" "" \
            "app" "${APP_NAME}" \
            "platform" "${SSHD_PLATFORM}" \
            "sshd_bin" "${SSHD_BIN:-}" \
            "sshd_config" "${SSHD_CONFIG}" \
            "hostkey_dir" "${SSHD_HOSTKEY_DIR}" \
            "pidfile" "${SSHD_PIDFILE}" \
            "port" "${SSHD_PORT}" \
            "running" "${_running}" \
            "pid" "${_pid}" \
            "auth_keys" "${SSHD_AUTH_KEYS}" \
            "connect" "${_connect}" \
            "sshd_systemd" "${_sysd}" \
            "sshd_unit" "${_unit}" \
            "sshd_unit_active" "${_uact}"
        unset _pid _running _connect _sysd _unit _uact
        return 0
    fi
    out_info "=== ${APP_NAME} sshd status ==="
    out_info "Platform:     ${SSHD_PLATFORM}"
    if [ -n "${SSHD_BIN}" ] && [ -x "${SSHD_BIN}" ]; then
        out_info "sshd binary:  ${SSHD_BIN}"
    else
        out_warn "sshd binary:  not found"
    fi
    out_info "Config:       ${SSHD_CONFIG}"
    out_info "Host keys:    ${SSHD_HOSTKEY_DIR}"
    out_info "Listen port:  ${SSHD_PORT}"
    out_info "Auth keys:    ${SSHD_AUTH_KEYS}"
    if [ "${_sysd}" = "true" ]; then
        if [ -n "${_unit}" ]; then
            if [ "${_uact}" = "true" ]; then
                out_info "systemd unit: ${_unit} (active)"
            else
                out_info "systemd unit: ${_unit} (inactive)"
            fi
            _tb=$(sshd_systemd_triggered_by "${_unit}" || true)
            if [ -n "${_tb}" ]; then
                out_info "TriggeredBy:  ${_tb}"
            fi
            unset _tb
        else
            out_info "systemd unit: none"
        fi
    fi
    if [ "${_running}" = "true" ]; then
        out_success "sshd is running (pid ${_pid})."
    else
        out_warn "sshd is not running."
    fi
    if [ -n "${_connect}" ]; then
        out_info "Connect:      ${_connect}"
    else
        out_warn "No LAN IPv4 found (ifconfig wlan0 had no inet). Next: turn on Wi-Fi, then ${APP_NAME} status."
    fi
    unset _pid _running _connect _sysd _unit _uact
}

sshd_cmd_config() {
    sshd_resolve
    if [ "${JSON}" -eq 1 ]; then
        sshd_cmd_status
        return 0
    fi
    sshd_cmd_status
    out_empty_line
    if [ -r "${SSHD_CONFIG}" ]; then
        out_info "Key settings from ${SSHD_CONFIG}:"
        grep -E '^[[:space:]]*(Port|ListenAddress|PasswordAuthentication|PubkeyAuthentication|PermitRootLogin|ChallengeResponseAuthentication)[[:space:]]' \
            "${SSHD_CONFIG}" 2>/dev/null | while IFS= read -r _line; do
            out_plain "  ${_line}"
        done
    else
        out_warn "Config is not readable: ${SSHD_CONFIG}"
    fi
}

# sshd_hint_daemon() - Human-only: session daemon vs boot service
# requirement-domain-sshd: OpenSSH daemonizes on this CLI's launch path.
# This CLI is not a service manager. POSIX Linux already-running pid may be
# the distro unit — MUST NOT deny systemd for that process (INC-20260908-002).
sshd_hint_daemon() {
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        return 0
    fi
    _hint_unit=$(sshd_systemd_unit || true)
    if [ -n "${_hint_unit}" ]; then
        out_info "This CLI used systemctl on ${_hint_unit}."
        out_info "Listen-after-reboot is this distro unit, not a session daemon."
        unset _hint_unit
        return 0
    fi
    unset _hint_unit
    if [ "${SSHD_PLATFORM}" = "termux" ]; then
        out_info "sshd is a background daemon for this session (OpenSSH forks itself). This CLI does not manage systemd, termux-services, or cron."
        out_info "After a reboot, run: ${APP_NAME} start"
        out_info "Listen-after-reboot on Termux is Termux:Boot (you own that hook): put ${APP_NAME} start in ~/.termux/boot/"
        out_info "Android may sleep Termux when the screen is off; this CLI acquires a wake lock on start. Re-acquire: ${APP_NAME} wake-lock"
    else
        out_info "This CLI does not manage systemd, termux-services, or cron."
        out_info "On POSIX Linux, listen-after-reboot is the distro sshd unit, not this CLI."
    fi
}

sshd_cmd_start() {
    : "${SSHD_NESTED_START:=0}"
    sshd_need_bin
    sshd_resolve
    _unit=$(sshd_systemd_unit || true)
    if [ -n "${_unit}" ]; then
        if sshd_systemd_is_active "${_unit}"; then
            sshd_wake_lock_acquire
            _pid=$(sshd_systemd_main_pid "${_unit}" || true)
            if [ "${JSON}" -eq 1 ] && [ "${SSHD_NESTED_START}" -eq 0 ]; then
                out_json "out_success" "sshd is already running." "pid" "${_pid}" "port" "${SSHD_PORT}" "sshd_unit" "${_unit}"
            elif [ "${JSON}" -eq 0 ]; then
                out_success "sshd is already running (pid ${_pid:-none}) on port ${SSHD_PORT} via ${_unit}."
                sshd_hint_daemon
            fi
            unset _pid _unit
            return 0
        fi
        if [ "$(id -u 2>/dev/null || echo 1)" -ne 0 ]; then
            out_die "Starting system sshd needs a root login on this host. Re-run as root."
        fi
        if ! systemctl start "${_unit}"; then
            out_die "systemctl start ${_unit} failed. Re-run as root."
        fi
        _pid=$(sshd_systemd_main_pid "${_unit}" || true)
        sshd_wake_lock_acquire
        if [ "${JSON}" -eq 1 ] && [ "${SSHD_NESTED_START}" -eq 0 ]; then
            out_json "out_success" "sshd started." "pid" "${_pid}" "port" "${SSHD_PORT}" "sshd_unit" "${_unit}"
        elif [ "${JSON}" -eq 0 ]; then
            out_success "sshd started on port ${SSHD_PORT} via systemctl ${_unit}${_pid:+ (pid ${_pid})}."
            _c=$(sshd_connect_cmd)
            if [ -n "${_c}" ]; then
                out_info "Connect:      ${_c}"
            fi
            unset _c
            sshd_hint_daemon
        fi
        unset _pid _unit
        return 0
    fi
    unset _unit
    if _pid=$(sshd_running_pid); then
        sshd_wake_lock_acquire
        if [ "${JSON}" -eq 1 ] && [ "${SSHD_NESTED_START}" -eq 0 ]; then
            out_json "out_success" "sshd is already running." "pid" "${_pid}" "port" "${SSHD_PORT}"
        elif [ "${JSON}" -eq 0 ]; then
            out_success "sshd is already running (pid ${_pid}) on port ${SSHD_PORT}."
            sshd_hint_daemon
        fi
        unset _pid
        return 0
    fi
    unset _pid
    if [ ! -d "${SSHD_HOSTKEY_DIR}" ]; then
        sshd_need_writable "${SSHD_HOSTKEY_DIR}/.keep"
        mkdir -p "${SSHD_HOSTKEY_DIR}" || out_die "Could not create host-key folder ${SSHD_HOSTKEY_DIR}."
    fi
    if ! ls "${SSHD_HOSTKEY_DIR}"/ssh_host_*_key >/dev/null 2>&1; then
        out_info "No host keys yet — generating ed25519 (and rsa if ssh-keygen allows)."
        sshd_cmd_host_keys_generate
    fi
    if [ ! -r "${SSHD_CONFIG}" ]; then
        out_die "sshd config is missing: ${SSHD_CONFIG}. Install OpenSSH first."
    fi
    if [ "${SSHD_PLATFORM}" != "termux" ] && [ "$(id -u 2>/dev/null || echo 1)" -ne 0 ]; then
        if [ ! -w "${SSHD_CONFIG}" ]; then
            out_die "Starting system sshd needs a root login on this host. Re-run as root."
        fi
    fi
    if ! "${SSHD_BIN}" -t -f "${SSHD_CONFIG}" >/dev/null 2>&1; then
        _err=$("${SSHD_BIN}" -t -f "${SSHD_CONFIG}" 2>&1 || true)
        out_die "sshd refused the config (${SSHD_CONFIG}). ${_err}"
    fi
    # OpenSSH fallback daemonizes unless -D. Do not pass -D; do not wrap in & / nohup.
    # systemd unit path is handled above (requirement-domain-sshd §2.2.1).
    if ! "${SSHD_BIN}" -f "${SSHD_CONFIG}"; then
        out_die "sshd did not start. Check ${SSHD_CONFIG} and host keys under ${SSHD_HOSTKEY_DIR}."
    fi
    _pid=""
    _pid=$(sshd_running_pid || true)
    sshd_wake_lock_acquire
    if [ "${JSON}" -eq 1 ] && [ "${SSHD_NESTED_START}" -eq 0 ]; then
        out_json "out_success" "sshd started." "pid" "${_pid}" "port" "${SSHD_PORT}"
    elif [ "${JSON}" -eq 0 ]; then
        out_success "sshd started on port ${SSHD_PORT}${_pid:+ (pid ${_pid})}."
        _c=$(sshd_connect_cmd)
        if [ -n "${_c}" ]; then
            out_info "Connect:      ${_c}"
        fi
        unset _c
        sshd_hint_daemon
    fi
    unset _pid
}

sshd_cmd_stop() {
    sshd_resolve
    _unit=$(sshd_systemd_unit || true)
    if [ -n "${_unit}" ]; then
        if ! sshd_systemd_is_active "${_unit}"; then
            if [ "${JSON}" -eq 1 ]; then
                out_json "out_success" "sshd is already stopped." "sshd_unit" "${_unit}"
            else
                out_success "sshd is already stopped."
            fi
            unset _unit
            return 0
        fi
        if [ "$(id -u 2>/dev/null || echo 1)" -ne 0 ]; then
            out_die "Stopping system sshd needs a root login on this host. Re-run as root."
        fi
        _pid=$(sshd_systemd_main_pid "${_unit}" || true)
        if ! systemctl stop "${_unit}"; then
            out_die "systemctl stop ${_unit} failed. Re-run as root."
        fi
        if [ "${JSON}" -eq 1 ]; then
            out_json "out_success" "sshd stopped." "pid" "${_pid}" "sshd_unit" "${_unit}"
        else
            out_success "sshd stopped via systemctl ${_unit}${_pid:+ (was pid ${_pid})}."
        fi
        unset _pid _unit
        return 0
    fi
    unset _unit
    if ! _pid=$(sshd_running_pid); then
        if [ "${JSON}" -eq 1 ]; then
            out_json "out_success" "sshd is already stopped."
        else
            out_success "sshd is already stopped."
        fi
        unset _pid
        return 0
    fi
    if [ "${SSHD_PLATFORM}" != "termux" ] && [ "$(id -u 2>/dev/null || echo 1)" -ne 0 ]; then
        out_die "Stopping system sshd needs a root login on this host. Re-run as root."
    fi
    if ! kill "${_pid}" 2>/dev/null; then
        out_die "Could not stop sshd (pid ${_pid})."
    fi
    _i=0
    while [ "${_i}" -lt 20 ]; do
        if ! kill -0 "${_pid}" 2>/dev/null; then
            break
        fi
        _i=$((_i + 1))
        sleep 0.1 2>/dev/null || sleep 1
    done
    if kill -0 "${_pid}" 2>/dev/null; then
        kill -9 "${_pid}" 2>/dev/null || true
    fi
    if [ "${JSON}" -eq 1 ]; then
        out_json "out_success" "sshd stopped." "pid" "${_pid}"
    else
        out_success "sshd stopped (was pid ${_pid})."
    fi
    unset _pid _i
}

sshd_cmd_restart() {
    sshd_resolve
    _unit=$(sshd_systemd_unit || true)
    if [ -n "${_unit}" ]; then
        if [ "$(id -u 2>/dev/null || echo 1)" -ne 0 ]; then
            out_die "Restarting system sshd needs a root login on this host. Re-run as root."
        fi
        if ! systemctl restart "${_unit}"; then
            out_die "systemctl restart ${_unit} failed. Re-run as root."
        fi
        _pid=$(sshd_systemd_main_pid "${_unit}" || true)
        sshd_wake_lock_acquire
        if [ "${JSON}" -eq 1 ]; then
            out_json "out_success" "sshd restarted." "pid" "${_pid}" "port" "${SSHD_PORT}" "sshd_unit" "${_unit}"
        else
            out_success "sshd restarted on port ${SSHD_PORT} via systemctl ${_unit}${_pid:+ (pid ${_pid})}."
            sshd_hint_daemon
        fi
        unset _pid _unit
        return 0
    fi
    unset _unit
    sshd_cmd_stop
    sshd_cmd_start
}

sshd_cmd_port() {
    sshd_resolve
    _want="${1-}"
    if [ -z "${_want}" ]; then
        if [ "${JSON}" -eq 1 ]; then
            out_json "port" "" "port" "${SSHD_PORT}" "config" "${SSHD_CONFIG}"
        else
            out_info "sshd listen port: ${SSHD_PORT} (from ${SSHD_CONFIG})"
        fi
        unset _want
        return 0
    fi
    case "${_want}" in
        *[!0-9]*|"") out_die "Port must be a number from 1 to 65535, not '${_want}'." ;;
    esac
    if [ "${_want}" -lt 1 ] || [ "${_want}" -gt 65535 ]; then
        out_die "Port must be a number from 1 to 65535, not '${_want}'."
    fi
    sshd_need_writable "${SSHD_CONFIG}"
    if [ ! -f "${SSHD_CONFIG}" ]; then
        out_die "sshd config is missing: ${SSHD_CONFIG}."
    fi
    _tmp=$(mktemp -t "${APP_NAME}.sshd_config.XXXXXX") || out_die "Could not create a temp file for the config edit."
    awk -v p="${_want}" '
        BEGIN { done=0 }
        /^[[:space:]]*Port[[:space:]]+/ {
            if (!done) { print "Port " p; done=1 }
            next
        }
        { print }
        END { if (!done) print "Port " p }
    ' "${SSHD_CONFIG}" > "${_tmp}" || {
        rm -f "${_tmp}"
        out_die "Could not rewrite ${SSHD_CONFIG}."
    }
    mv "${_tmp}" "${SSHD_CONFIG}" || out_die "Could not replace ${SSHD_CONFIG}."
    SSHD_PORT="${_want}"
    if [ "${JSON}" -eq 1 ]; then
        out_json "out_success" "Listen port set." "port" "${SSHD_PORT}" "config" "${SSHD_CONFIG}"
    else
        out_success "Listen port is now ${SSHD_PORT} in ${SSHD_CONFIG}."
        if sshd_running_pid >/dev/null 2>&1; then
            out_info "sshd is running — run: ${APP_NAME} restart"
        fi
    fi
    unset _want _tmp
}

sshd_cmd_host_keys_generate() {
    sshd_resolve
    if ! command -v ssh-keygen >/dev/null 2>&1; then
        out_die "ssh-keygen is not installed. Next: run ${APP_NAME} install (Termux installs openssh), then retry ${APP_NAME} host-keys generate"
    fi
    sshd_need_writable "${SSHD_HOSTKEY_DIR}/ssh_host_ed25519_key"
    mkdir -p "${SSHD_HOSTKEY_DIR}" || out_die "Could not create ${SSHD_HOSTKEY_DIR}."
    if [ ! -f "${SSHD_HOSTKEY_DIR}/ssh_host_ed25519_key" ]; then
        ssh-keygen -t ed25519 -f "${SSHD_HOSTKEY_DIR}/ssh_host_ed25519_key" -N "" >/dev/null 2>&1 \
            || out_die "Could not generate ed25519 host key under ${SSHD_HOSTKEY_DIR}."
        out_success "Created ${SSHD_HOSTKEY_DIR}/ssh_host_ed25519_key"
    else
        out_info "Already present: ${SSHD_HOSTKEY_DIR}/ssh_host_ed25519_key"
    fi
    if [ ! -f "${SSHD_HOSTKEY_DIR}/ssh_host_rsa_key" ]; then
        if ssh-keygen -t rsa -b 4096 -f "${SSHD_HOSTKEY_DIR}/ssh_host_rsa_key" -N "" >/dev/null 2>&1; then
            out_success "Created ${SSHD_HOSTKEY_DIR}/ssh_host_rsa_key"
        else
            out_warn "RSA host key not created (ssh-keygen declined). ed25519 is enough."
        fi
    else
        out_info "Already present: ${SSHD_HOSTKEY_DIR}/ssh_host_rsa_key"
    fi
}

sshd_cmd_host_keys() {
    sshd_resolve
    _sub="${1:-list}"
    case "${_sub}" in
        list|"")
            if [ "${JSON}" -eq 1 ]; then
                _list=""
                for _k in "${SSHD_HOSTKEY_DIR}"/ssh_host_*_key; do
                    [ -f "${_k}" ] || continue
                    _list="${_list:+${_list},}${_k}"
                done
                out_json "host-keys" "" "dir" "${SSHD_HOSTKEY_DIR}" "keys" "${_list}"
                unset _list _k _sub
                return 0
            fi
            out_info "Host keys in ${SSHD_HOSTKEY_DIR}:"
            _found=0
            for _k in "${SSHD_HOSTKEY_DIR}"/ssh_host_*_key; do
                [ -f "${_k}" ] || continue
                _found=1
                out_plain "  ${_k}"
            done
            if [ "${_found}" -eq 0 ]; then
                out_warn "No host keys yet. Generate with: ${APP_NAME} host-keys generate"
            fi
            unset _found _k
            ;;
        generate)
            sshd_cmd_host_keys_generate
            ;;
        *)
            out_die "Unknown host-keys action '${_sub}'. Use list or generate."
            ;;
    esac
    unset _sub
}

sshd_cmd_auth_keys() {
    sshd_resolve
    _sub="${1:-list}"
    _arg="${2-}"
    mkdir -p "${SSHD_USER_SSH_DIR}" || out_die "Could not create ${SSHD_USER_SSH_DIR}."
    chmod 700 "${SSHD_USER_SSH_DIR}" 2>/dev/null || true
    case "${_sub}" in
        list|"")
            if [ ! -f "${SSHD_AUTH_KEYS}" ]; then
                if [ "${JSON}" -eq 1 ]; then
                    out_json "auth-keys" "" "path" "${SSHD_AUTH_KEYS}" "count" "0"
                else
                    out_info "No authorized_keys file yet at ${SSHD_AUTH_KEYS}."
                    out_info "Add one with: ${APP_NAME} auth-keys add /path/to/id_ed25519.pub"
                fi
                unset _sub _arg
                return 0
            fi
            _count=$(grep -cve '^[[:space:]]*$' "${SSHD_AUTH_KEYS}" 2>/dev/null || echo 0)
            if [ "${JSON}" -eq 1 ]; then
                out_json "auth-keys" "" "path" "${SSHD_AUTH_KEYS}" "count" "${_count}"
            else
                out_info "authorized_keys (${SSHD_AUTH_KEYS}): ${_count} line(s)"
                grep -v '^[[:space:]]*$' "${SSHD_AUTH_KEYS}" 2>/dev/null | while IFS= read -r _line; do
                    out_plain "  ${_line}"
                done
            fi
            unset _count
            ;;
        add)
            if [ -z "${_arg}" ]; then
                out_die "auth-keys add needs a public-key file path. Example: ${APP_NAME} auth-keys add ./id_ed25519.pub"
            fi
            if [ ! -f "${_arg}" ] || [ ! -r "${_arg}" ]; then
                out_die "Cannot read public-key file: ${_arg}"
            fi
            _key=$(grep -E '^(ssh-(rsa|ed25519)|ecdsa-sha2-nistp|sk-ssh-)' "${_arg}" | head -n 1 || true)
            if [ -z "${_key}" ]; then
                out_die "No SSH public key line found in ${_arg}."
            fi
            touch "${SSHD_AUTH_KEYS}" || out_die "Could not create ${SSHD_AUTH_KEYS}."
            chmod 600 "${SSHD_AUTH_KEYS}" 2>/dev/null || true
            if grep -Fqx "${_key}" "${SSHD_AUTH_KEYS}" 2>/dev/null; then
                if [ "${JSON}" -eq 1 ]; then
                    out_json "out_success" "Key already present." "path" "${SSHD_AUTH_KEYS}"
                else
                    out_success "That key is already in ${SSHD_AUTH_KEYS}."
                fi
                unset _sub _arg _key
                return 0
            fi
            printf '%s\n' "${_key}" >> "${SSHD_AUTH_KEYS}" || out_die "Could not append to ${SSHD_AUTH_KEYS}."
            if [ "${JSON}" -eq 1 ]; then
                out_json "out_success" "Key added." "path" "${SSHD_AUTH_KEYS}"
            else
                out_success "Added the key to ${SSHD_AUTH_KEYS}."
            fi
            unset _key
            ;;
        *)
            out_die "Unknown auth-keys action '${_sub}'. Use list or add <pubkey-file>."
            ;;
    esac
    unset _sub _arg
}

# =============================================================================
# sshd_dns_* — this login ~/.ssh/config as an SSH dns-ip list
# requirement-domain-sshd: list; TTY action menu (edit/add/delete); show; set.
# Do-not-capture-read: action pick, Host pick, and field prompts read in-shell.
# =============================================================================

sshd_dns_config_path() {
    printf '%s' "${HOME}/.ssh/config"
}

# =============================================================================
# util_sudo() - Only in-tool sudo call site (NOPASSWD backup-config argv)
# =============================================================================
#
# ALIGNMENT: requirement-shell-sudoer.md · requirement-shell-sudo-command.md
# Last updated: 2026-09-11
# =============================================================================
util_sudo() {
    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        "$@"
        return $?
    fi
    command -v sudo >/dev/null 2>&1 || return 1
    sudo -n "$@"
}

sshd_invoking_login() {
    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
        printf '%s' "${SUDO_USER}"
        return 0
    fi
    id -un 2>/dev/null || echo "unknown"
}

sshd_invoking_home() {
    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ] && [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
        _h=""
        if command -v getent >/dev/null 2>&1; then
            _h=$(getent passwd "${SUDO_USER}" 2>/dev/null | cut -d: -f6)
        fi
        if [ -z "${_h}" ] && [ -r /etc/passwd ]; then
            _h=$(awk -F: -v u="${SUDO_USER}" '$1==u {print $6; exit}' /etc/passwd 2>/dev/null)
        fi
        if [ -n "${_h}" ] && [ -d "${_h}" ]; then
            printf '%s' "${_h}"
            unset _h
            return 0
        fi
        unset _h
    fi
    printf '%s' "${HOME:-/tmp}"
}

sshd_cli_root() {
    : "${SSHD_CLI_ROOT:=/var/sshd-cli}"
    printf '%s' "${SSHD_CLI_ROOT}"
}

sshd_ssh_config_src() {
    printf '%s' "$(sshd_invoking_home)/.ssh/config"
}

sshd_host_normal_user_only_label() {
    if sshd_is_termux; then
        printf '%s' "termux"
        return 0
    fi
    if sshd_is_git_bash; then
        printf '%s' "gitbash"
        return 0
    fi
    if sshd_is_windows_cmd; then
        printf '%s' "windows-cmd"
        return 0
    fi
    printf '%s' ""
}

sshd_refuse_config_backup_on_nuser() {
    : "${APP_NAME:=sshd-cli}"
    _lab=$(sshd_host_normal_user_only_label)
    if [ -z "${_lab}" ]; then
        unset _lab
        return 0
    fi
    out_die "backup-config and sync-config are not available for ${_lab}. Next: use a POSIX Linux host, or copy ~/.ssh/config by hand."
}

sshd_dest_needs_elev() {
    _d="${1:-}"
    : "${_d:=/var/sshd-cli}"
    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        unset _d
        return 1
    fi
    case "${_d}" in
        /var/sshd-cli|/var/sshd-cli/*)
            unset _d
            return 0
            ;;
    esac
    if [ -d "${_d}" ] && [ -w "${_d}" ]; then
        unset _d
        return 1
    fi
    if mkdir -p "${_d}" 2>/dev/null && [ -w "${_d}" ]; then
        unset _d
        return 1
    fi
    unset _d
    return 0
}

sshd_sudoers_trust_tier() {
    : "${APP_NAME:=sshd-cli}"
    : "${HOME:=/tmp}"
    : "${GLOBAL_BIN:=/usr/local/bin}"
    : "${USER_BIN:=${HOME}/.local/bin}"
    if [ -r "${GLOBAL_BIN}/${APP_NAME}" ] && [ -x "${GLOBAL_BIN}/${APP_NAME}" ]; then
        printf '%s' "production"
        return 0
    fi
    if [ -r "${USER_BIN}/${APP_NAME}" ] && [ -x "${USER_BIN}/${APP_NAME}" ]; then
        printf '%s' "test_local"
        return 0
    fi
    printf '%s' "unmanaged"
    return 0
}

sshd_current_login_user() {
    id -un 2>/dev/null || echo "unknown"
}

sshd_sudoers_d_dir() {
    : "${SUDOERS_D_DIR:=/etc/sudoers.d}"
    printf '%s' "${SUDOERS_D_DIR}"
}

sshd_default_installed_sudoers_path() {
    : "${APP_NAME:=sshd-cli}"
    printf '%s' "$(sshd_sudoers_d_dir)/${APP_NAME}-$(sshd_current_login_user)"
}

sshd_default_project_sudoers_path() {
    : "${APP_NAME:=sshd-cli}"
    : "${HOME:=/tmp}"
    printf '%s' "${HOME}/.config/${APP_NAME}/sudoers.fragment-$(sshd_current_login_user)"
}

sshd_default_sudoer_request_path() {
    : "${APP_NAME:=sshd-cli}"
    : "${HOME:=/tmp}"
    printf '%s' "${HOME}/.config/${APP_NAME}/sudoer-request-$(sshd_current_login_user).json"
}

sshd_sudoers_fragment_text() {
    : "${APP_NAME:=sshd-cli}"
    : "${GLOBAL_BIN:=/usr/local/bin}"
    : "${USER_BIN:=${HOME:-/tmp}/.local/bin}"
    _user=$(sshd_current_login_user)
    _tier=$(sshd_sudoers_trust_tier)
    _global_path="${GLOBAL_BIN}/${APP_NAME}"
    _installed=$(sshd_default_installed_sudoers_path)
    _purpose="Allow ${_user} to run ${APP_NAME} backup-config as root."
    cat <<EOF
# Purpose: ${_purpose}
# ${APP_NAME} — ${APP_NAME} backup-config only (review before install)
# Target user: ${_user}
# Install: sudo install -m 0440 <this-file> ${_installed}
# Validate: sudo visudo -c -f ${_installed}
# Trust tier: ${_tier}
# Grant is the project command only. Does NOT allowlist mkdir/cp/chmod/chown.
# After elev, the ship unit copies ~/.ssh/config and chown/chmod internally.
${_user} ALL=(root) NOPASSWD: ${_global_path} backup-config
EOF
    unset _user _tier _global_path _installed _purpose
}

sshd_sudoers_json_text_compact() {
    : "${APP_NAME:=sshd-cli}"
    : "${GLOBAL_BIN:=/usr/local/bin}"
    : "${SUBMIT_ACTION:=add}"
    _user=$(sshd_current_login_user)
    _global_path="${GLOBAL_BIN}/${APP_NAME}"
    _action="${SUBMIT_ACTION}"
    case "${_action}" in
        add|update) ;;
        *) _action="add" ;;
    esac
    printf '%s' "{\"schema_version\":1,\"purpose\":\"Allow ${_user} to run ${APP_NAME} backup-config as root.\",\"username\":\"${_user}\",\"service\":\"${APP_NAME}\",\"action\":\"${_action}\",\"commands\":[{\"runas\":\"root\",\"tags\":[\"NOPASSWD\"],\"path\":\"${_global_path}\",\"args\":[\"backup-config\"]}]}"
    printf '\n'
    unset _user _global_path _action
}

sshd_sudoers_refuse_forbidden_grant() {
    _gf="${1:-}"
    : "${APP_NAME:=sshd-cli}"
    : "${GLOBAL_BIN:=/usr/local/bin}"
    if [ -z "${_gf}" ] || [ ! -f "${_gf}" ]; then
        out_die "sudoer grant file missing"
    fi
    _gb=$(cat "${_gf}" 2>/dev/null || true)
    case "${_gb}" in
        *"/usr/bin/mkdir"*|*"/bin/mkdir"*|*"/usr/bin/cp"*|*"/bin/cp"*|*"/usr/bin/chmod"*|*"/bin/chmod"*|*"/usr/bin/chown"*|*"/bin/chown"*)
            out_die "refusing sudoer grant with OS-tool commands (need ${GLOBAL_BIN}/${APP_NAME} backup-config only)"
            ;;
    esac
    unset _gf _gb
    return 0
}

sshd_sudoers_verify_grant_verbs() {
    _gf="${1:-}"
    if [ -z "${_gf}" ] || [ ! -f "${_gf}" ]; then
        out_die "sudoer file missing (cannot verify backup-config)"
    fi
    _gb=$(cat "${_gf}" 2>/dev/null || true)
    case "${_gb}" in
        *'"backup-config"'*) ;;
        *) out_die "Sudoer file is incomplete: it does not allow backup-config. Path: ${_gf}" ;;
    esac
    unset _gf _gb
    return 0
}

sshd_sudoers_require_emit_trust() {
    : "${APP_NAME:=sshd-cli}"
    : "${GLOBAL_BIN:=/usr/local/bin}"
    : "${ALLOW_TEST_LOCAL_SUDOERS:=0}"
    _cmd="${1:-submit-sudoer-request}"
    _tier=$(sshd_sudoers_trust_tier)
    if [ "${_tier}" != "production" ]; then
        if [ "${ALLOW_TEST_LOCAL_SUDOERS}" -ne 1 ]; then
            out_die "${_cmd} trust tier is ${_tier} (not production). Prefer: sudo ${APP_NAME} install (global ${GLOBAL_BIN}/${APP_NAME}). To emit a test file: ${APP_NAME} ${_cmd} --allow-test-local  or ALLOW_TEST_LOCAL_SUDOERS=1"
        fi
    fi
    unset _cmd _tier
}

sshd_detect_sudoer_cli() {
    : "${HOME:=/tmp}"
    : "${GLOBAL_BIN:=/usr/local/bin}"
    : "${USER_BIN:=${HOME}/.local/bin}"
    : "${SUDOER_CLI:=}"
    if [ -n "${SUDOER_CLI}" ] && [ -x "${SUDOER_CLI}" ]; then
        printf '%s' "${SUDOER_CLI}"
        return 0
    fi
    if [ -x "${GLOBAL_BIN}/sudoer-cli" ]; then
        printf '%s' "${GLOBAL_BIN}/sudoer-cli"
        return 0
    fi
    if [ -x "${USER_BIN}/sudoer-cli" ]; then
        printf '%s' "${USER_BIN}/sudoer-cli"
        return 0
    fi
    _found=$(command -v sudoer-cli 2>/dev/null || true)
    if [ -n "${_found}" ] && [ -x "${_found}" ]; then
        printf '%s' "${_found}"
        unset _found
        return 0
    fi
    unset _found
    return 1
}

sshd_detect_sudoer_adm() {
    : "${SUDOER_ADM_USER:=sudoer-adm}"
    if id "${SUDOER_ADM_USER}" >/dev/null 2>&1; then
        printf '%s' "${SUDOER_ADM_USER}"
        return 0
    fi
    return 1
}

sshd_detect_sudoer_inbound() {
    : "${SUDOER_ADM_USER:=sudoer-adm}"
    : "${SUDOER_QUEUE_INBOUND:=}"
    : "${SUDOER_PUBLIC_ROOT:=/var/sudoer-cli}"
    if [ -n "${SUDOER_QUEUE_INBOUND}" ] && [ -d "${SUDOER_QUEUE_INBOUND}" ]; then
        printf '%s' "${SUDOER_QUEUE_INBOUND}"
        return 0
    fi
    if [ -d "${SUDOER_PUBLIC_ROOT}/sudoer-request" ]; then
        printf '%s' "${SUDOER_PUBLIC_ROOT}/sudoer-request"
        return 0
    fi
    return 1
}

# =============================================================================
# sshd_cmd_backup_config() - elevated deposit of ~/.ssh/config → /var/sshd-cli
# =============================================================================
#
# ALIGNMENT: requirement-shell-config-backup.md · requirement-shell-sudoer.md
# Last updated: 2026-09-11
# =============================================================================
sshd_cmd_backup_config() {
    : "${APP_NAME:=sshd-cli}"
    : "${JSON:=0}"
    : "${GLOBAL_BIN:=/usr/local/bin}"
    sshd_refuse_config_backup_on_nuser
    _src=$(sshd_ssh_config_src)
    _dest=$(sshd_cli_root)
    if [ ! -f "${_src}" ]; then
        out_die "Cannot backup-config: missing ${_src}. Next: create this login's SSH config (for example ${APP_NAME} dns add), then ${APP_NAME} backup-config."
    fi
    if [ "$(id -u 2>/dev/null || echo 1)" -ne 0 ] && sshd_dest_needs_elev "${_dest}"; then
        _bin="${GLOBAL_BIN}/${APP_NAME}"
        if [ ! -x "${_bin}" ]; then
            out_die "Cannot push to ${_dest}: need the global binary ${_bin} (sudo ${APP_NAME} backup-config). Next: sudo sh src/${APP_NAME} install, then ${APP_NAME} generate-sudoer-request and ${APP_NAME} submit-sudoer-request so sudoer-adm can approve passwordless sudo ${APP_NAME} backup-config."
        fi
        if ! command -v sudo >/dev/null 2>&1; then
            out_die "sudo not found. Pushing into ${_dest} needs passwordless sudo ${APP_NAME} backup-config after sudoer-adm approval."
        fi
        out_info "Elevating: sudo -n ${_bin} backup-config"
        _sudo_ec=0
        if [ "${JSON}" -eq 1 ]; then
            util_sudo "${_bin}" backup-config >/dev/null
            _sudo_ec=$?
        else
            util_sudo "${_bin}" backup-config
            _sudo_ec=$?
        fi
        if [ "${_sudo_ec}" -ne 0 ]; then
            out_die "sudo ${APP_NAME} backup-config was refused. Next: ${APP_NAME} generate-sudoer-request && ${APP_NAME} submit-sudoer-request, then ask sudoer-adm to approve the JSON grant (NOPASSWD ${_bin} backup-config)."
        fi
        if [ "${JSON}" -eq 1 ]; then
            out_json "backup-config" "ok" \
                "app" "${APP_NAME}" \
                "source" "${_src}" \
                "destination" "${_dest}/config" \
                "elevated" "true"
        fi
        unset _src _dest _bin _sudo_ec
        return 0
    fi
    if [ ! -d "${_dest}" ]; then
        mkdir -p "${_dest}" || out_die "Cannot create ${_dest} (need allowlisted sudo ${APP_NAME} backup-config). Next: ${APP_NAME} generate-sudoer-request && ${APP_NAME} submit-sudoer-request."
    fi
    if [ ! -w "${_dest}" ]; then
        out_die "Cannot write ${_dest}. Only an approved passwordless sudo ${APP_NAME} backup-config may push files there."
    fi
    _outp="${_dest}/config"
    if command -v install >/dev/null 2>&1; then
        install -m 0644 "${_src}" "${_outp}" || out_die "Failed to copy ${_src} into ${_dest}."
    else
        cp "${_src}" "${_outp}" || out_die "Failed to copy ${_src} into ${_dest}."
        chmod 0644 "${_outp}" 2>/dev/null || true
    fi
    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        chown root:root "${_outp}" 2>/dev/null || true
        chmod 0644 "${_outp}" 2>/dev/null || true
        chown root:root "${_dest}" 2>/dev/null || true
        chmod 0755 "${_dest}" 2>/dev/null || true
    fi
    _owner="invoking-user"
    if [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        _owner="root:root"
    fi
    out_success "backup-config complete: ${_src} → ${_outp}"
    out_info "Store owner/mode: ${_owner}; file 0644 so a normal login can ${APP_NAME} sync-config without sudo."
    if [ "${JSON}" -eq 1 ]; then
        out_json "backup-config" "ok" \
            "app" "${APP_NAME}" \
            "source" "${_src}" \
            "destination" "${_outp}" \
            "owner" "${_owner}" \
            "elevated" "$([ "$(id -u 2>/dev/null || echo 1)" -eq 0 ] && echo true || echo false)"
    fi
    unset _src _dest _outp _owner
    return 0
}

# =============================================================================
# sshd_cmd_sync_config() - Type 0 copy /var/sshd-cli/config → ~/.ssh/config
# =============================================================================
#
# ALIGNMENT: requirement-shell-config-backup.md
# Last updated: 2026-09-11
# =============================================================================
sshd_cmd_sync_config() {
    : "${APP_NAME:=sshd-cli}"
    : "${JSON:=0}"
    : "${HOME:=/tmp}"
    sshd_refuse_config_backup_on_nuser
    _src="$(sshd_cli_root)/config"
    _destdir="${HOME}/.ssh"
    _dest="${_destdir}/config"
    if [ ! -f "${_src}" ]; then
        out_die "Cannot sync-config: store missing (${_src}). Next: someone with an approved sudo ${APP_NAME} backup-config must push ~/.ssh/config first."
    fi
    if [ ! -r "${_src}" ]; then
        out_die "Cannot read ${_src} without sudo. The store file must be world-readable (backup-config chmod 0644)."
    fi
    if [ ! -d "${_destdir}" ]; then
        mkdir -p "${_destdir}" || out_die "Cannot create ${_destdir}."
    fi
    chmod 0700 "${_destdir}" 2>/dev/null || true
    if command -v install >/dev/null 2>&1; then
        install -m 0600 "${_src}" "${_dest}" || out_die "Failed to write ${_dest}."
    else
        cp "${_src}" "${_dest}" || out_die "Failed to write ${_dest}."
        chmod 0600 "${_dest}" 2>/dev/null || true
    fi
    chmod 0600 "${_dest}" 2>/dev/null || true
    out_success "sync-config complete: ${_src} → ${_dest} (mode 600)"
    if [ "${JSON}" -eq 1 ]; then
        out_json "sync-config" "ok" \
            "app" "${APP_NAME}" \
            "source" "${_src}" \
            "destination" "${_dest}"
    fi
    unset _src _destdir _dest
    return 0
}

sshd_scp_cmd() {
    : "${SSHD_CLI_SCP:=}"
    if [ -n "${SSHD_CLI_SCP}" ]; then
        printf '%s' "${SSHD_CLI_SCP}"
        return 0
    fi
    command -v scp 2>/dev/null || true
}

sshd_ssh_cmd() {
    : "${SSHD_CLI_SSH:=}"
    if [ -n "${SSHD_CLI_SSH}" ]; then
        printf '%s' "${SSHD_CLI_SSH}"
        return 0
    fi
    command -v ssh 2>/dev/null || true
}

# Class-B: POSIX single-quote a string for a remote sh -c / ssh command.
sshd_sh_quote() {
    _q_in="${1-}"
    _q_out=$(printf '%s' "${_q_in}" | sed "s/'/'\\\\''/g")
    printf "'%s'" "${_q_out}"
    unset _q_in _q_out
}

sshd_host_is_ipv4() {
    _h="${1-}"
    [ -n "${_h}" ] || return 1
    _n=0
    _rest="${_h}."
    while [ -n "${_rest}" ]; do
        _oct="${_rest%%.*}"
        _rest="${_rest#*.}"
        case "${_oct}" in
            ''|*[!0-9]*) return 1 ;;
        esac
        if [ "${_oct}" -lt 0 ] || [ "${_oct}" -gt 255 ]; then
            return 1
        fi
        _n=$((_n + 1))
        if [ "${_n}" -gt 4 ]; then
            return 1
        fi
    done
    [ "${_n}" -eq 4 ]
}

sshd_host_is_dns() {
    _h="${1-}"
    [ -n "${_h}" ] || return 1
    case "${_h}" in
        *[!A-Za-z0-9.-]*|.*|*..*|*.) return 1 ;;
        -*|*-) return 1 ;;
    esac
    case "${_h}" in
        *[A-Za-z]*) return 0 ;;
        *) return 1 ;;
    esac
}

sshd_parse_remote_spec() {
    _spec="${1-}"
    SSHD_REMOTE_USER=""
    SSHD_REMOTE_HOST=""
    if [ -z "${_spec}" ]; then
        return 1
    fi
    case "${_spec}" in
        *[';|&$`()<>\\/ '*]*|*'*'*|*\[*|*\]*)
            return 1
            ;;
        -*)
            return 1
            ;;
    esac
    _atcount=0
    _tmp="${_spec}"
    while [ -n "${_tmp}" ]; do
        case "${_tmp}" in
            *@*)
                _atcount=$((_atcount + 1))
                _tmp="${_tmp#*@}"
                ;;
            *)
                _tmp=""
                ;;
        esac
    done
    if [ "${_atcount}" -gt 1 ]; then
        return 1
    fi
    if [ "${_atcount}" -eq 1 ]; then
        SSHD_REMOTE_USER="${_spec%@*}"
        SSHD_REMOTE_HOST="${_spec#*@}"
        if [ -z "${SSHD_REMOTE_USER}" ] || [ -z "${SSHD_REMOTE_HOST}" ]; then
            SSHD_REMOTE_USER=""
            SSHD_REMOTE_HOST=""
            return 1
        fi
        case "${SSHD_REMOTE_USER}" in
            *[!A-Za-z0-9_.-]*)
                SSHD_REMOTE_USER=""
                SSHD_REMOTE_HOST=""
                return 1
                ;;
        esac
        case "${SSHD_REMOTE_USER}" in
            [A-Za-z_]*|[0-9]*)
                ;;
            *)
                SSHD_REMOTE_USER=""
                SSHD_REMOTE_HOST=""
                return 1
                ;;
        esac
    else
        SSHD_REMOTE_HOST="${_spec}"
    fi
    if sshd_host_is_ipv4 "${SSHD_REMOTE_HOST}"; then
        return 0
    fi
    if sshd_host_is_dns "${SSHD_REMOTE_HOST}"; then
        return 0
    fi
    SSHD_REMOTE_USER=""
    SSHD_REMOTE_HOST=""
    return 1
}

sshd_preferred_remote_path() {
    : "${APP_NAME:=sshd-cli}"
    if [ -z "${PERSISTENT_STORAGE_DIR:-}" ]; then
        PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)
        export PERSISTENT_STORAGE_DIR
    fi
    printf '%s' "${PERSISTENT_STORAGE_DIR}/preferred-remote"
}

sshd_preferred_remote_load() {
    _pr_path=$(sshd_preferred_remote_path)
    if [ ! -f "${_pr_path}" ]; then
        printf '%s' ""
        return 0
    fi
    _pr_line=$(head -n1 "${_pr_path}" 2>/dev/null || true)
    _pr_line=$(printf '%s' "${_pr_line}" | tr -d '\r')
    if [ -z "${_pr_line}" ]; then
        printf '%s' ""
        return 0
    fi
    if sshd_parse_remote_spec "${_pr_line}"; then
        printf '%s' "${_pr_line}"
        return 0
    fi
    printf '%s' ""
    return 0
}

sshd_preferred_remote_save() {
    _pr_spec="${1-}"
    if ! sshd_parse_remote_spec "${_pr_spec}"; then
        return 1
    fi
    _pr_path=$(sshd_preferred_remote_path)
    printf '%s\n' "${_pr_spec}" > "${_pr_path}" || return 1
    chmod 0600 "${_pr_path}" 2>/dev/null || true
    return 0
}

# =============================================================================
# sshd_cmd_sync_from_remote() - Type 0 scp of remote /var/sshd-cli/config
# =============================================================================
#
# GENERAL PURPOSE:
# Pull config from a remote host's SSHD_CLI_REMOTE_ROOT (default /var/sshd-cli)
# into this login ~/.ssh/config (mode 600). SPEC is user@host, IPv4, domain,
# or user@domain. scp BatchMode. MUST NOT sudo. Preferred SPEC is stored under
# ${HOME}/.local/${APP_NAME}/preferred-remote (mode 0600) and used as the TTY
# default next time.
#
# ALIGNMENT: requirement-shell-config-backup.md
# Last updated: 2026-09-11
# =============================================================================
sshd_cmd_sync_from_remote() {
    : "${APP_NAME:=sshd-cli}"
    : "${JSON:=0}"
    : "${TTY:=0}"
    : "${QUIET:=0}"
    : "${SSHD_CLI_REMOTE_ROOT:=/var/sshd-cli}"
    : "${HOME:=/tmp}"

    _spec="${1-}"
    if [ -z "${_spec}" ] && [ "${TTY}" -eq 1 ] && [ "${JSON}" -ne 1 ] && [ "${QUIET}" -ne 1 ]; then
        _pref=$(sshd_preferred_remote_load)
        if [ -n "${_pref}" ]; then
            out_msg_n "Remote (user@host, IPv4, domain, or user@domain) [${_pref}]: "
        else
            out_msg_n "Remote (user@host, IPv4, domain, or user@domain): "
        fi
        _spec=""
        read -r _spec || true
        if [ -z "${_spec}" ]; then
            _spec="${_pref}"
        fi
        unset _pref
    fi
    if [ -z "${_spec}" ]; then
        out_die "Cannot sync-from-remote: missing remote. Next: ${APP_NAME} sync-from-remote USER@HOST"
    fi
    if ! sshd_parse_remote_spec "${_spec}"; then
        out_die "Cannot sync-from-remote: remote '${_spec}' is not user@host, IPv4, domain, or user@domain. Next: ${APP_NAME} sync-from-remote USER@HOST"
    fi

    _scp=$(sshd_scp_cmd)
    if [ -z "${_scp}" ] || [ ! -x "${_scp}" ]; then
        out_die "Cannot sync-from-remote: scp not found. Next: install openssh-client, then ${APP_NAME} sync-from-remote ${_spec}"
    fi

    _destdir="${HOME}/.ssh"
    _dest="${_destdir}/config"
    if [ ! -d "${_destdir}" ]; then
        mkdir -p "${_destdir}" || out_die "Cannot create ${_destdir}."
    fi
    chmod 0700 "${_destdir}" 2>/dev/null || true

    _cfg_src="${SSHD_CLI_REMOTE_ROOT}/config"
    if [ -n "${SSHD_REMOTE_USER}" ]; then
        _remote="${SSHD_REMOTE_USER}@${SSHD_REMOTE_HOST}:${_cfg_src}"
        _label="${SSHD_REMOTE_USER}@${SSHD_REMOTE_HOST}"
    else
        _remote="${SSHD_REMOTE_HOST}:${_cfg_src}"
        _label="${SSHD_REMOTE_HOST}"
    fi

    _tmp=$(mktemp -t "${APP_NAME}.remote.XXXXXX") || out_die "Could not create a temp file for sync-from-remote."
    out_info "Fetching config from ${_label}"
    if ! "${_scp}" -o BatchMode=yes -o ConnectTimeout=15 "${_remote}" "${_tmp}"; then
        rm -f "${_tmp}"
        out_die "Cannot sync-from-remote: scp from ${_label} failed. Next: ssh ${_label}, then ${APP_NAME} sync-from-remote ${_spec}"
    fi
    if [ ! -s "${_tmp}" ]; then
        rm -f "${_tmp}"
        out_die "Cannot sync-from-remote: remote ${_label} has no config under ${SSHD_CLI_REMOTE_ROOT}. Next: on that host run ${APP_NAME} backup-config, then ${APP_NAME} sync-from-remote ${_spec}"
    fi

    if command -v install >/dev/null 2>&1; then
        install -m 0600 "${_tmp}" "${_dest}" || out_die "Failed to write ${_dest}."
    else
        cp "${_tmp}" "${_dest}" || out_die "Failed to write ${_dest}."
        chmod 0600 "${_dest}" 2>/dev/null || true
    fi
    rm -f "${_tmp}"
    chmod 0600 "${_dest}" 2>/dev/null || true

    out_success "sync-from-remote complete: ${_label}:${SSHD_CLI_REMOTE_ROOT}/config → ${_dest} (mode 600)"
    if [ "${JSON}" -eq 1 ]; then
        out_json "sync-from-remote" "ok" \
            "app" "${APP_NAME}" \
            "remote" "${_label}" \
            "host" "${SSHD_REMOTE_HOST}" \
            "user" "${SSHD_REMOTE_USER}" \
            "source" "${SSHD_CLI_REMOTE_ROOT}/config" \
            "destination" "${_dest}"
    fi
    sshd_preferred_remote_save "${_spec}" || true
    unset _spec _scp _destdir _dest _cfg_src _remote _label _tmp
    return 0
}

sshd_cmd_print_sudoers() {
    : "${APP_NAME:=sshd-cli}"
    : "${JSON:=0}"
    : "${ALLOW_TEST_LOCAL_SUDOERS:=0}"
    sshd_refuse_config_backup_on_nuser
    _out_path="${1:-}"
    _tier=$(sshd_sudoers_trust_tier)
    _global_path="${GLOBAL_BIN:-/usr/local/bin}/${APP_NAME}"
    if [ "${_tier}" != "production" ]; then
        if [ "${ALLOW_TEST_LOCAL_SUDOERS}" -ne 1 ]; then
            out_die "print-sudoers trust tier is ${_tier} (not production). Prefer: sudo ${APP_NAME} install (global ${_global_path}). To emit a test fragment anyway: ${APP_NAME} print-sudoers --allow-test-local [path] or ALLOW_TEST_LOCAL_SUDOERS=1"
        fi
        if [ "${JSON}" -eq 0 ]; then
            out_warn "TEST MODE ONLY: trust tier=${_tier}. Prefer global install for production."
        fi
    fi
    _installed=$(sshd_default_installed_sudoers_path)
    _fragment=$(sshd_sudoers_fragment_text)
    if [ -n "${_out_path}" ]; then
        _dir=$(dirname -- "${_out_path}")
        if [ ! -d "${_dir}" ]; then
            mkdir -p "${_dir}" || out_die "Cannot create ${_dir}"
        fi
        printf '%s\n' "${_fragment}" > "${_out_path}" || out_die "Cannot write ${_out_path}"
        out_success "Wrote sudoers fragment to ${_out_path}"
        out_info "Admin: sudo visudo -c -f ${_out_path}"
        out_info "Admin: sudo install -m 0440 ${_out_path} ${_installed}"
        if [ "${JSON}" -eq 1 ]; then
            out_json "print-sudoers" "written" \
                "path" "${_out_path}" \
                "installed_path" "${_installed}" \
                "trust_tier" "${_tier}"
        fi
        unset _out_path _tier _global_path _installed _fragment _dir
        return 0
    fi
    if [ "${JSON}" -eq 1 ]; then
        out_json "print-sudoers" "use human mode or path arg to capture fragment" \
            "installed_path" "${_installed}" \
            "trust_tier" "${_tier}"
        unset _out_path _tier _global_path _installed _fragment
        return 0
    fi
    out_info "Sudoers fragment for $(sshd_current_login_user) → ${_global_path} backup-config (trust_tier=${_tier})"
    out_plain "${_fragment}"
    out_info "Tip: ${APP_NAME} print-sudoers $(sshd_default_project_sudoers_path)"
    unset _out_path _tier _global_path _installed _fragment
    return 0
}

sshd_cmd_generate_sudoer_request() {
    : "${APP_NAME:=sshd-cli}"
    : "${JSON:=0}"
    : "${HOME:=/tmp}"
    : "${SUBMIT_ACTION:=add}"
    sshd_refuse_config_backup_on_nuser
    sshd_sudoers_require_emit_trust "generate-sudoer-request"
    _out_path="${1:-}"
    if [ -z "${_out_path}" ]; then
        _out_path=$(sshd_default_sudoer_request_path)
    fi
    case "${_out_path}" in
        /etc|/etc/*)
            out_die "generate-sudoer-request refuses to write under /etc (Type 0). Use a path under \$HOME or /dev/shm."
            ;;
        /var/sudoer-cli|/var/sudoer-cli/*)
            out_die "generate-sudoer-request does not write inbound. Write a local file, then: ${APP_NAME} submit-sudoer-request <path>"
            ;;
    esac
    _dir=$(dirname -- "${_out_path}")
    if [ ! -d "${_dir}" ]; then
        mkdir -p "${_dir}" || out_die "Cannot create ${_dir}"
    fi
    sshd_sudoers_json_text_compact >"${_out_path}" || out_die "Cannot write ${_out_path}"
    chmod 0644 "${_out_path}" 2>/dev/null || true
    sshd_sudoers_refuse_forbidden_grant "${_out_path}"
    sshd_sudoers_verify_grant_verbs "${_out_path}"
    out_success "Wrote verified sudoer file to ${_out_path}"
    out_info "Grant allows: ${APP_NAME} backup-config (action=${SUBMIT_ACTION})"
    out_info "Review the file, then: ${APP_NAME} submit-sudoer-request ${_out_path}"
    if [ "${JSON}" -eq 1 ]; then
        out_json "generate-sudoer-request" "written" \
            "path" "${_out_path}" \
            "action" "${SUBMIT_ACTION}" \
            "user" "$(sshd_current_login_user)"
    fi
    unset _out_path _dir
    return 0
}

sshd_cmd_submit_sudoer_request() {
    : "${APP_NAME:=sshd-cli}"
    : "${JSON:=0}"
    sshd_refuse_config_backup_on_nuser
    _src_file="${1:-}"
    _cli=""
    if _cli=$(sshd_detect_sudoer_cli); then
        :
    else
        out_die "sudoer-cli not found (set SUDOER_CLI or install sudoer-cli). Submit is Type 0 compose — this CLI does not write /etc. Next: ${APP_NAME} generate-sudoer-request, then install sudoer-cli, then ${APP_NAME} submit-sudoer-request."
    fi
    _adm=""
    if _adm=$(sshd_detect_sudoer_adm); then
        :
    else
        out_die "sudoer-adm not found (id ${SUDOER_ADM_USER:-sudoer-adm} failed). Ask an admin to run: sudo sudoer-cli setup"
    fi
    _inbound=""
    if _inbound=$(sshd_detect_sudoer_inbound); then
        :
    else
        out_die "sudoer inbound queue not found (preferred /var/sudoer-cli/sudoer-request). Ask an admin to run: sudo sudoer-cli setup"
    fi
    if [ ! -w "${_inbound}" ]; then
        out_die "sudoer inbound not writable: ${_inbound}."
    fi
    _tmp=""
    _cleanup_tmp=0
    if [ -n "${_src_file}" ]; then
        if [ ! -f "${_src_file}" ]; then
            out_die "sudoers file not found: ${_src_file}"
        fi
        _tmp="${_src_file}"
    else
        sshd_sudoers_require_emit_trust "submit-sudoer-request"
        _tmp=$(mktemp -t "${APP_NAME}.sudoer.XXXXXX") || out_die "Could not create a temp sudoer file."
        sshd_sudoers_json_text_compact >"${_tmp}" || out_die "cannot write temp sudoer JSON ${_tmp}"
        _cleanup_tmp=1
    fi
    sshd_sudoers_refuse_forbidden_grant "${_tmp}"
    sshd_sudoers_verify_grant_verbs "${_tmp}"
    _purpose="${SUBMIT_PURPOSE:-Allow $(sshd_current_login_user) to run ${APP_NAME} backup-config as root.}"
    _verb="add-sudoer-request"
    if [ "${SUBMIT_ACTION}" = "update" ]; then
        _verb="update-sudoer-request"
    fi
    _errf=$(mktemp -t "${APP_NAME}.sudoer-err.XXXXXX") || _errf="/dev/null"
    _out=""
    _rc=0
    if [ "${JSON}" -eq 1 ]; then
        _out=$("${_cli}" --json "${_verb}" --file "${_tmp}" --purpose "${_purpose}" --service "${APP_NAME}" 2>"${_errf}")
        _rc=$?
    else
        _out=$("${_cli}" "${_verb}" --file "${_tmp}" --purpose "${_purpose}" --service "${APP_NAME}" 2>"${_errf}")
        _rc=$?
    fi
    _err=$(cat "${_errf}" 2>/dev/null || true)
    if [ "${_errf}" != "/dev/null" ]; then
        rm -f "${_errf}"
    fi
    if [ "${_cleanup_tmp}" -eq 1 ]; then
        rm -f "${_tmp}"
    fi
    if [ "${_rc}" -ne 0 ]; then
        if [ -n "${_err}" ]; then
            out_die "sudoer-cli ${_verb} failed: ${_err}"
        fi
        out_die "sudoer-cli ${_verb} failed (exit ${_rc})"
    fi
    out_success "Submitted sudoer request via ${_cli} (${_verb})"
    if [ -n "${_out}" ] && [ "${JSON}" -eq 0 ]; then
        out_plain "${_out}"
    fi
    if [ "${JSON}" -eq 1 ]; then
        out_json "submit-sudoer-request" "submitted" \
            "action" "${SUBMIT_ACTION}" \
            "service" "${APP_NAME}" \
            "sudoer_cli" "${_cli}" \
            "sudoer_adm" "${_adm}"
    fi
    unset _src_file _cli _adm _inbound _tmp _cleanup_tmp _purpose _verb _errf _out _rc _err
    return 0
}

sshd_cmd_print_sudoers_install_script() {
    : "${APP_NAME:=sshd-cli}"
    : "${JSON:=0}"
    sshd_refuse_config_backup_on_nuser
    sshd_sudoers_require_emit_trust "print-sudoers-install-script"
    _out="${1:-}"
    if [ -z "${_out}" ]; then
        _out="${TMPDIR:-/tmp}/${APP_NAME}-$(sshd_current_login_user)-sudoers-admin.sh"
    fi
    _installed=$(sshd_default_installed_sudoers_path)
    _draft=$(sshd_default_project_sudoers_path)
    sshd_cmd_print_sudoers "${_draft}"
    cat > "${_out}" <<EOF
#!/bin/sh
# Generated by: ${APP_NAME} print-sudoers-install-script
set -u
PROJECT_SUDOERS_FILE="${_draft}"
INSTALLED="${_installed}"
die() { printf '%s\\n' "\$*" >&2; exit 1; }
info() { printf '%s\\n' "\$*"; }
[ "\$(id -u)" -eq 0 ] || die "run as root: sudo sh \$0 install|uninstall|replace"
[ -f "\${PROJECT_SUDOERS_FILE}" ] || die "Missing project sudoers file: \${PROJECT_SUDOERS_FILE} — regenerate with: ${APP_NAME} print-sudoers --allow-test-local \${PROJECT_SUDOERS_FILE}"
cmd="\${1:-install}"
case "\${cmd}" in
    install|replace)
        visudo -c -f "\${PROJECT_SUDOERS_FILE}" || die "visudo -c failed"
        install -m 0440 "\${PROJECT_SUDOERS_FILE}" "\${INSTALLED}" || die "install failed"
        visudo -c -f "\${INSTALLED}" || die "installed fragment failed visudo -c"
        info "Installed \${INSTALLED}"
        ;;
    uninstall)
        rm -f "\${INSTALLED}"
        info "Removed \${INSTALLED}"
        ;;
    *) die "use install|uninstall|replace" ;;
esac
EOF
    chmod 0755 "${_out}" 2>/dev/null || true
    out_success "Wrote admin script ${_out}"
    out_info "Admin: sudo sh ${_out} install"
    if [ "${JSON}" -eq 1 ]; then
        out_json "print-sudoers-install-script" "written" \
            "path" "${_out}" \
            "installed_path" "${_installed}"
    fi
    unset _out _installed _draft
    return 0
}

sshd_cmd_remove_project_sudoers() {
    : "${APP_NAME:=sshd-cli}"
    : "${JSON:=0}"
    sshd_refuse_config_backup_on_nuser
    _path="${1:-}"
    if [ -z "${_path}" ]; then
        _path=$(sshd_default_project_sudoers_path)
    fi
    case "${_path}" in
        /etc|/etc/*)
            out_die "Refusing to remove paths under /etc as Type 0. This command only deletes the user draft. Host elev is admin-only: ${APP_NAME} print-sudoers-install-script && sudo sh <script> uninstall"
            ;;
    esac
    if [ ! -f "${_path}" ]; then
        out_die "No project-sudoers draft at ${_path}."
    fi
    rm -f "${_path}" || out_die "Could not remove ${_path}."
    out_success "Removed project-sudoers draft ${_path}"
    if [ "${JSON}" -eq 1 ]; then
        out_json "remove-project-sudoers" "removed" "path" "${_path}"
    fi
    unset _path
    return 0
}

sshd_cmd_sudoers_menu() {
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ] || [ "${TTY}" -ne 1 ]; then
        out_die "sudoers menu needs a terminal. Next: ${APP_NAME} generate-sudoer-request"
    fi
    while true; do
        out_info "$(printf '%s' "${APP_NAME}") — $(app_menu_text sudoers_header)"
        case "${APP_LANG:-en}" in
            zh-Hant)
                out_menu_choice "51" "generate-sudoer-request" "寫一份可閱讀的 JSON 授權"
                ;;
            es)
                out_menu_choice "51" "generate-sudoer-request" "Escribe una concesión JSON que se puede leer"
                ;;
            fr)
                out_menu_choice "51" "generate-sudoer-request" "Écrire une autorisation JSON lisible"
                ;;
            de)
                out_menu_choice "51" "generate-sudoer-request" "Eine lesbare JSON-Freigabe schreiben"
                ;;
            zh-Hans)
                out_menu_choice "51" "generate-sudoer-request" "写一份可阅读的 JSON 授权"
                ;;
            ja)
                out_menu_choice "51" "generate-sudoer-request" "読める JSON 認可を書く"
                ;;
            ko)
                out_menu_choice "51" "generate-sudoer-request" "읽을 수 있는 JSON 허가를 작성"
                ;;
            ar)
                out_menu_choice "51" "generate-sudoer-request" "اكتب منحة JSON يمكن الاطلاع عليها"
                ;;
            pt)
                out_menu_choice "51" "generate-sudoer-request" "Escreva uma concessão JSON que se pode consultar"
                ;;
            ru)
                out_menu_choice "51" "generate-sudoer-request" "Запишите JSON-разрешение, которое можно просмотреть"
                ;;
            nl)
                out_menu_choice "51" "generate-sudoer-request" "Schrijf een JSON-toekenning die u kunt bekijken"
                ;;
            el)
                out_menu_choice "51" "generate-sudoer-request" "Γράψτε μια παραχώρηση JSON που μπορείτε να δείτε"
                ;;
            *)
                out_menu_choice "51" "generate-sudoer-request" "Write a JSON grant you can read"
                ;;
        esac
        out_menu_choice "52" "submit-sudoer-request" "$(app_menu_text sudoers_52_long)"
        out_menu_choice "53" "print-sudoers" "$(app_menu_text sudoers_53_long)"
        out_menu_choice "54" "print-sudoers-install-script" "$(app_menu_text sudoers_54_long)"
        out_menu_choice "55" "remove-project-sudoers" "$(app_menu_text sudoers_55_long)"
        out_plain "$(app_menu_text line_back)"
        out_msg_n "$(app_menu_text line_prompt)"
        _sc=""
        read -r _sc || true
        case "${_sc}" in
            51|generate-sudoer-request) sshd_cmd_generate_sudoer_request; break ;;
            52|submit-sudoer-request) sshd_cmd_submit_sudoer_request; break ;;
            53|print-sudoers) sshd_cmd_print_sudoers; break ;;
            54|print-sudoers-install-script) sshd_cmd_print_sudoers_install_script; break ;;
            55|remove-project-sudoers) sshd_cmd_remove_project_sudoers; break ;;
            0|q|exit|"") break ;;
            *)
                out_warn "$(app_menu_text unknown_sudoers "${_sc}")"
                continue
                ;;
        esac
    done
    unset _sc
}

sshd_dns_can_prompt() {
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${TTY:=0}"
    : "${INTERACTIVE:=0}"
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ]; then
        return 1
    fi
    if [ "${TTY}" -eq 1 ] || [ "${INTERACTIVE}" -eq 1 ]; then
        return 0
    fi
    return 1
}

sshd_dns_norm() {
    case "${1-}" in
        ''|'""'|"''") printf '' ;;
        *) printf '%s' "$1" ;;
    esac
}

sshd_dns_disp_user() {
    if [ -n "${1-}" ]; then
        printf '%s' "$1"
    else
        printf 'empty'
    fi
}

sshd_dns_disp_port() {
    if [ -n "${1-}" ]; then
        printf '%s' "$1"
    else
        printf '22'
    fi
}

sshd_dns_disp_ip() {
    if [ -n "${1-}" ]; then
        printf '%s' "$1"
    else
        printf '(empty)'
    fi
}

sshd_dns_disp_opt() {
    if [ -n "${1-}" ]; then
        printf '%s' "$1"
    else
        printf 'empty'
    fi
}

# Termux client profile (as Termux): Port 8022 + keep-alives + IPQoS + simpler
# Ciphers/MACs. Some Termux OpenSSH sshd versions reply too slowly under default
# AEAD; the client then aborts (ssh-connection-corrupt).
sshd_dns_termux_bundle_yes() {
    DNS_TX_PORT="8022"
    DNS_TX_SAI="15"
    DNS_TX_SACM="12"
    DNS_TX_TCPKA="yes"
    DNS_TX_IPQOS="none"
    DNS_TX_CIPHERS="aes128-ctr,aes256-ctr"
    DNS_TX_MACS="hmac-sha2-256"
}

sshd_dns_termux_profile() {
    sshd_dns_termux_bundle_yes
    [ "${1-}" = "${DNS_TX_PORT}" ] && [ "${2-}" = "${DNS_TX_SAI}" ] && [ "${3-}" = "${DNS_TX_SACM}" ] && [ "${4-}" = "${DNS_TX_TCPKA}" ] && [ "${5-}" = "${DNS_TX_IPQOS}" ] && [ "${6-}" = "${DNS_TX_CIPHERS}" ] && [ "${7-}" = "${DNS_TX_MACS}" ]
}

sshd_dns_old_profile() {
    [ -n "${1-}" ] || [ -n "${2-}" ]
}

sshd_dns_disp_termux() {
    if sshd_dns_termux_profile "${1-}" "${2-}" "${3-}" "${4-}" "${5-}" "${6-}" "${7-}"; then
        printf 'yes'
    else
        printf 'no'
    fi
}

sshd_dns_disp_old() {
    if sshd_dns_old_profile "${1-}" "${2-}"; then
        printf 'yes'
    else
        printf 'no'
    fi
}

sshd_dns_load_row() {
    _lr="${1-}"
    DNS_R_N=$(printf '%s\n' "${_lr}" | cut -f1)
    DNS_R_DNS=$(printf '%s\n' "${_lr}" | cut -f2)
    DNS_R_IP=$(printf '%s\n' "${_lr}" | cut -f3)
    DNS_R_USER=$(printf '%s\n' "${_lr}" | cut -f4)
    DNS_R_PORT=$(printf '%s\n' "${_lr}" | cut -f5)
    DNS_R_IDFILE=$(printf '%s\n' "${_lr}" | cut -f6)
    DNS_R_IDONLY=$(printf '%s\n' "${_lr}" | cut -f7)
    DNS_R_SAI=$(printf '%s\n' "${_lr}" | cut -f8)
    DNS_R_SACM=$(printf '%s\n' "${_lr}" | cut -f9)
    DNS_R_TCPKA=$(printf '%s\n' "${_lr}" | cut -f10)
    DNS_R_IPQOS=$(printf '%s\n' "${_lr}" | cut -f11)
    DNS_R_HKA=$(printf '%s\n' "${_lr}" | cut -f12)
    DNS_R_PAA=$(printf '%s\n' "${_lr}" | cut -f13)
    DNS_R_CIPHERS=$(printf '%s\n' "${_lr}" | cut -f14)
    DNS_R_MACS=$(printf '%s\n' "${_lr}" | cut -f15)
    unset _lr
}

# Sets DNS_YN_VALUE to yes or no. MUST run in current shell (do-not-capture-read).
sshd_dns_prompt_yn() {
    _yn_label="$1"
    _yn_default="${2:-yes}"
    DNS_YN_VALUE="${_yn_default}"
    if ! sshd_dns_can_prompt; then
        unset _yn_label _yn_default
        return 0
    fi
    if [ "${_yn_default}" = "yes" ]; then
        _yn_hint="Y/n"
    else
        _yn_hint="y/N"
    fi
    out_msg_n "${_yn_label} (${_yn_hint}): "
    _yn_ans=""
    read -r _yn_ans || true
    case "${_yn_ans}" in
        "")
            DNS_YN_VALUE="${_yn_default}"
            ;;
        [Yy]|[Yy][Ee][Ss])
            DNS_YN_VALUE="yes"
            ;;
        [Nn]|[Nn][Oo])
            DNS_YN_VALUE="no"
            ;;
        *)
            out_die "${_yn_label} needs y or n, not '${_yn_ans}'."
            ;;
    esac
    unset _yn_label _yn_default _yn_hint _yn_ans
}

sshd_dns_parse_yn_operand() {
    _yn_field="$1"
    _yn_raw="${2-}"
    case "${_yn_raw}" in
        [Yy]|[Yy][Ee][Ss]|[Tt][Rr][Uu][Ee])
            DNS_YN_VALUE="yes"
            ;;
        [Nn]|[Nn][Oo]|[Ff][Aa][Ll][Ss][Ee])
            DNS_YN_VALUE="no"
            ;;
        *)
            out_die "${_yn_field} needs yes or no, not '${_yn_raw}'."
            ;;
    esac
    unset _yn_field _yn_raw
}

sshd_dns_norm_idonly() {
    case "${1-}" in
        ''|'""'|"''") printf '' ;;
        [Yy]|[Yy][Ee][Ss]|[Tt][Rr][Uu][Ee]) printf 'yes' ;;
        [Nn]|[Nn][Oo]|[Ff][Aa][Ll][Ss][Ee]) printf 'no' ;;
        yes|no) printf '%s' "$1" ;;
        *) printf '%s' "$1" ;;
    esac
}

sshd_dns_validate_idonly() {
    _vio="${1-}"
    case "${_vio}" in
        ''|yes|no) ;;
        *) out_die "identities-only needs yes, no, or empty, not '${_vio}'." ;;
    esac
    unset _vio
}

# Class-B: print TSV n dns ip user port idfile idonly sai sacm tcpka ipqos hka paa ciphers macs.
# OpenSSH accepts "Key value", "Key=value", and "Key = value".
sshd_dns_records() {
    _rec_cfg=$(sshd_dns_config_path)
    if [ ! -r "${_rec_cfg}" ]; then
        unset _rec_cfg
        return 0
    fi
    awk '
        function parse_line(line,    s, commented) {
            key=""; val=""; lk=""
            commented=0
            s=line
            sub(/^[[:space:]]+/, "", s)
            if (s=="") return 0
            if (substr(s,1,1)=="#") {
                sub(/^#+[[:space:]]*/, "", s)
                commented=1
                if (s=="") return 0
            }
            if (!match(s, /^[A-Za-z][A-Za-z0-9]*/)) return 0
            key=substr(s, RSTART, RLENGTH)
            s=substr(s, RSTART+RLENGTH)
            sub(/^[[:space:]]*=[[:space:]]*/, "", s)
            sub(/^[[:space:]]+/, "", s)
            if (match(s, /^[^[:space:]]+/)) val=substr(s, RSTART, RLENGTH)
            lk=tolower(key)
            if (commented && lk!="hostkeyalgorithms" && lk!="pubkeyacceptedalgorithms" && lk!="pubkeyacceptedkeytypes") return 0
            return 1
        }
        function is_concrete(p) {
            return (p != "" && p !~ /[?*]/)
        }
        function reset_body() {
            ip=""; user=""; port=""
            idfile=""; idonly=""; sai=""; sacm=""; tcpka=""; ipqos=""; hka=""; paa=""
            ciphers=""; macs=""
        }
        function flush() {
            if (concrete && dns != "") {
                n++
                printf "%d\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n", n, dns, ip, user, port, idfile, idonly, sai, sacm, tcpka, ipqos, hka, paa, ciphers, macs
            }
            concrete=0; dns=""; reset_body()
        }
        BEGIN { n=0; in_match=0; concrete=0; dns=""; reset_body() }
        {
            if (!parse_line($0)) next
            if (lk=="match") { flush(); in_match=1; next }
            if (lk=="host") {
                flush()
                in_match=0
                if (!is_concrete(val)) { concrete=0; dns=""; next }
                concrete=1
                dns=val
                reset_body()
                next
            }
            if (in_match) next
            if (concrete) {
                if (lk=="hostname") ip=val
                if (lk=="user") user=val
                if (lk=="port") port=val
                if (lk=="identityfile") idfile=val
                if (lk=="identitiesonly") idonly=tolower(val)
                if (lk=="serveraliveinterval") sai=val
                if (lk=="serveralivecountmax") sacm=val
                if (lk=="tcpkeepalive") tcpka=tolower(val)
                if (lk=="ipqos") ipqos=val
                if (lk=="hostkeyalgorithms") hka=val
                if (lk=="pubkeyacceptedalgorithms" || lk=="pubkeyacceptedkeytypes") paa=val
                if (lk=="ciphers") ciphers=val
                if (lk=="macs") macs=val
            }
        }
        END { flush() }
    ' "${_rec_cfg}"
    unset _rec_cfg
}

sshd_dns_count() {
    sshd_dns_records | awk 'END { print NR+0 }'
}

sshd_dns_row() {
    _want="$1"
    sshd_dns_records | awk -F '\t' -v w="${_want}" '
        $1==w { print; found=1; exit }
        END { if (!found) exit 1 }
    '
}

sshd_dns_row_by_name() {
    _want="$1"
    sshd_dns_records | awk -F '\t' -v w="${_want}" '
        $2==w { print; found=1; exit }
        END { if (!found) exit 1 }
    '
}

sshd_dns_lookup() {
    _sel="${1-}"
    if [ -z "${_sel}" ]; then
        unset _sel
        return 1
    fi
    case "${_sel}" in
        *[!0-9]*)
            sshd_dns_row_by_name "${_sel}"
            ;;
        *)
            sshd_dns_row "${_sel}"
            ;;
    esac
}

sshd_dns_validate_name() {
    _vname="$1"
    _vnext="${2:-${APP_NAME} dns add dns <name>  or  ${APP_NAME} dns set <n> dns <name>}"
    if [ -z "${_vname}" ]; then
        out_die "dns name cannot be empty. Next: ${_vnext}"
    fi
    case "${_vname}" in
        *[!A-Za-z0-9._-]*)
            out_die "dns name '${_vname}' is not a Host alias (use letters, digits, dot, underscore, hyphen). Next: ${_vnext}"
            ;;
    esac
    unset _vname _vnext
}

sshd_dns_validate_port() {
    _vp="$1"
    if [ -z "${_vp}" ]; then
        unset _vp
        return 0
    fi
    case "${_vp}" in
        *[!0-9]*) out_die "Port must be a number from 1 to 65535, not '${_vp}'." ;;
    esac
    if [ "${_vp}" -lt 1 ] || [ "${_vp}" -gt 65535 ]; then
        out_die "Port must be a number from 1 to 65535, not '${_vp}'."
    fi
    unset _vp
}

sshd_dns_print_details() {
    _pd_n="$1"; _pd_dns="$2"; _pd_ip="$3"; _pd_user="$4"; _pd_port="$5"
    _pd_idfile="${6-}"; _pd_idonly="${7-}"
    _pd_sai="${8-}"; _pd_sacm="${9-}"; _pd_tcpka="${10-}"; _pd_ipqos="${11-}"
    _pd_hka="${12-}"; _pd_paa="${13-}"
    _pd_ciphers="${14-}"; _pd_macs="${15-}"
    _pd_termux=$(sshd_dns_disp_termux "${_pd_port}" "${_pd_sai}" "${_pd_sacm}" "${_pd_tcpka}" "${_pd_ipqos}" "${_pd_ciphers}" "${_pd_macs}")
    _pd_old=$(sshd_dns_disp_old "${_pd_hka}" "${_pd_paa}")
    if [ "${JSON}" -eq 1 ]; then
        out_json "dns_show" "" \
            "n" "${_pd_n}" \
            "dns" "${_pd_dns}" \
            "ip" "${_pd_ip}" \
            "user" "${_pd_user}" \
            "port" "${_pd_port}" \
            "identity_file" "${_pd_idfile}" \
            "identities_only" "${_pd_idonly}" \
            "termux" "${_pd_termux}" \
            "old_openssh" "${_pd_old}" \
            "user_display" "$(sshd_dns_disp_user "${_pd_user}")" \
            "port_display" "$(sshd_dns_disp_port "${_pd_port}")"
    else
        out_plain "dns:  ${_pd_dns}"
        if [ -n "${_pd_ip}" ]; then
            out_plain "ip:   ${_pd_ip}"
        else
            out_plain "ip:   empty"
        fi
        out_plain "user: $(sshd_dns_disp_user "${_pd_user}")"
        out_plain "port: $(sshd_dns_disp_port "${_pd_port}")"
        out_plain "identity-file: $(sshd_dns_disp_opt "${_pd_idfile}")"
        out_plain "identities-only: $(sshd_dns_disp_opt "${_pd_idonly}")"
        out_plain "termux: ${_pd_termux}"
        out_plain "old-openssh: ${_pd_old}"
    fi
    unset _pd_n _pd_dns _pd_ip _pd_user _pd_port _pd_idfile _pd_idonly
    unset _pd_sai _pd_sacm _pd_tcpka _pd_ipqos _pd_hka _pd_paa _pd_ciphers _pd_macs _pd_termux _pd_old
}

sshd_dns_list_human() {
    _cfg=$(sshd_dns_config_path)
    _any=0
    while IFS= read -r _line || [ -n "${_line}" ]; do
        _any=1
        _n=$(printf '%s' "${_line}" | awk -F '\t' '{print $1}')
        _dns=$(printf '%s' "${_line}" | awk -F '\t' '{print $2}')
        _ip=$(printf '%s' "${_line}" | awk -F '\t' '{print $3}')
        out_plain "${_n}. ${_dns}  $(sshd_dns_disp_ip "${_ip}")"
    done <<EOF
$(sshd_dns_records)
EOF
    if [ "${_any}" -eq 0 ]; then
        out_info "No concrete Host entries in ${_cfg}."
        out_info "Next: ${APP_NAME} dns add"
    fi
    unset _cfg _any _line _n _dns _ip
}

# Context block for the TTY action menu: names only, no choice numbers
# (Host row 1 must not look like action 1. Edit).
sshd_dns_list_context() {
    _cfg=$(sshd_dns_config_path)
    _any=0
    while IFS= read -r _line || [ -n "${_line}" ]; do
        _any=1
        _dns=$(printf '%s' "${_line}" | awk -F '\t' '{print $2}')
        _ip=$(printf '%s' "${_line}" | awk -F '\t' '{print $3}')
        out_plain "  ${_dns}  $(sshd_dns_disp_ip "${_ip}")"
    done <<EOF
$(sshd_dns_records)
EOF
    if [ "${_any}" -eq 0 ]; then
        out_info "No concrete Host entries in ${_cfg}."
        out_info "Next: ${APP_NAME} dns add"
    fi
    unset _cfg _any _line _dns _ip
}

sshd_dns_list_json() {
    _items="["
    _first=1
    _count=0
    while IFS= read -r _line || [ -n "${_line}" ]; do
        [ -z "${_line}" ] && continue
        _count=$((_count + 1))
        _n=$(printf '%s' "${_line}" | awk -F '\t' '{print $1}')
        _dns=$(printf '%s' "${_line}" | awk -F '\t' '{print $2}')
        _ip=$(printf '%s' "${_line}" | awk -F '\t' '{print $3}')
        _user=$(printf '%s' "${_line}" | awk -F '\t' '{print $4}')
        _port=$(printf '%s' "${_line}" | awk -F '\t' '{print $5}')
        _obj=$(printf '{"n":%s,"dns":"%s","ip":"%s","user":"%s","port":"%s","user_display":"%s","port_display":"%s"}' \
            "${_n}" \
            "$(util_json_escape "${_dns}")" \
            "$(util_json_escape "${_ip}")" \
            "$(util_json_escape "${_user}")" \
            "$(util_json_escape "${_port}")" \
            "$(util_json_escape "$(sshd_dns_disp_user "${_user}")")" \
            "$(util_json_escape "$(sshd_dns_disp_port "${_port}")")")
        if [ "${_first}" -eq 1 ]; then
            _items="${_items}${_obj}"
            _first=0
        else
            _items="${_items},${_obj}"
        fi
    done <<EOF
$(sshd_dns_records)
EOF
    _items="${_items}]"
    out_json "dns_list" "" "count" "${_count}" "@items" "${_items}"
    unset _items _first _count _line _n _dns _ip _user _port _obj
}

sshd_dns_ensure_file() {
    _ens_dir="${HOME}/.ssh"
    _ens_cfg=$(sshd_dns_config_path)
    mkdir -p "${_ens_dir}" || out_die "Could not create ${_ens_dir}."
    chmod 700 "${_ens_dir}" 2>/dev/null || true
    if [ ! -f "${_ens_cfg}" ]; then
        : > "${_ens_cfg}" || out_die "Could not create ${_ens_cfg}."
        chmod 600 "${_ens_cfg}" 2>/dev/null || true
    fi
    if [ ! -w "${_ens_cfg}" ]; then
        out_die "ssh config is not writable: ${_ens_cfg}."
    fi
    unset _ens_dir _ens_cfg
}

sshd_dns_backup() {
    _bk_cfg="$1"
    _bk_reason="$2"
    if [ -s "${_bk_cfg}" ]; then
        util_backup "${_bk_cfg}" "${_bk_reason}" || out_die "Could not backup ${_bk_cfg}."
    fi
    unset _bk_cfg _bk_reason
}

sshd_dns_commit_tmp() {
    _cm_tmp="$1"
    _cm_cfg="$2"
    mv "${_cm_tmp}" "${_cm_cfg}" || {
        rm -f "${_cm_tmp}"
        out_die "Could not replace ${_cm_cfg}."
    }
    chmod 600 "${_cm_cfg}" 2>/dev/null || true
    unset _cm_tmp _cm_cfg
}

# OS class for OpenSSH client keywords. SSHD_CLI_OS overrides detect.
# alpine: ID or ID_LIKE contains alpine. termux: sshd_is_termux. else posix.
# requirement-domain-sshd.
sshd_fix_os_class() {
    case "${SSHD_CLI_OS-}" in
        alpine|termux|posix)
            printf '%s' "${SSHD_CLI_OS}"
            return 0
            ;;
    esac
    if sshd_is_termux; then
        printf '%s' termux
        return 0
    fi
    if [ -r /etc/os-release ]; then
        _foc_id=$(grep -E '^(ID|ID_LIKE)=' /etc/os-release 2>/dev/null || true)
        case "${_foc_id}" in
            *alpine*)
                unset _foc_id
                printf '%s' alpine
                return 0
                ;;
        esac
        unset _foc_id
    fi
    printf '%s' posix
}

# Comment active keywords this OS rejects. Keep indent. Leave other lines.
# Alpine: GSSAPI*. Termux: HostKeyAlgorithms, PubkeyAcceptedAlgorithms,
# PubkeyAcceptedKeyTypes. posix: those keywords stay active.
# requirement-domain-sshd.
sshd_fix_config_render() {
    _fcr_src="$1"
    _fcr_dst="$2"
    _fcr_os=$(sshd_fix_os_class)
    if ! awk -v os="${_fcr_os}" '
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
            if (rest == "" || substr(rest, 1, 1) == "#") {
                print line
                next
            }
            if (match(rest, /^[A-Za-z][A-Za-z0-9]*/)) {
                k = tolower(substr(rest, RSTART, RLENGTH))
                if (unsupported(k)) {
                    print indent "# " rest
                    next
                }
            }
            print line
        }
    ' "${_fcr_src}" > "${_fcr_dst}"; then
        unset _fcr_src _fcr_dst _fcr_os
        return 1
    fi
    unset _fcr_src _fcr_dst _fcr_os
    return 0
}

# Silent pass on this login ~/.ssh/config. Missing, unreadable, or
# unwritable is a no-op. Identical text is a no-op. No out_* (version
# and --json stay one object). requirement-domain-sshd.
sshd_fix_config_auto() {
    : "${HOME:=/tmp}"
    _fca_cfg="${HOME}/.ssh/config"
    if [ ! -f "${_fca_cfg}" ] || [ ! -r "${_fca_cfg}" ] || [ ! -w "${_fca_cfg}" ]; then
        unset _fca_cfg
        return 0
    fi
    _fca_tmp=$(mktemp -t "${APP_NAME}.fix-config.XXXXXX") || {
        unset _fca_cfg
        return 0
    }
    if ! sshd_fix_config_render "${_fca_cfg}" "${_fca_tmp}"; then
        rm -f "${_fca_tmp}" >/dev/null 2>&1 || true
        unset _fca_cfg _fca_tmp
        return 0
    fi
    if cmp -s "${_fca_cfg}" "${_fca_tmp}"; then
        rm -f "${_fca_tmp}" >/dev/null 2>&1 || true
        unset _fca_cfg _fca_tmp
        return 0
    fi
    if ! cp -f "${_fca_cfg}" "${_fca_cfg}.fix-config.bak"; then
        rm -f "${_fca_tmp}" >/dev/null 2>&1 || true
        unset _fca_cfg _fca_tmp
        return 0
    fi
    chmod 600 "${_fca_cfg}.fix-config.bak" 2>/dev/null || true
    if ! mv "${_fca_tmp}" "${_fca_cfg}"; then
        rm -f "${_fca_tmp}" >/dev/null 2>&1 || true
        unset _fca_cfg _fca_tmp
        return 0
    fi
    chmod 600 "${_fca_cfg}" 2>/dev/null || true
    unset _fca_cfg _fca_tmp
}

# Comment unsupported OpenSSH client keywords. Flags follow the verb.
# requirement-domain-sshd.
sshd_cmd_fix_config() {
    _fcc_in=""
    _fcc_out=""
    _fcc_in_set=0
    _fcc_out_set=0
    while [ $# -gt 0 ]; do
        case "$1" in
            --input-file)
                if [ $# -lt 2 ] || [ -z "${2-}" ]; then
                    out_die "--input-file requires a path. Next: ${APP_NAME} fix-config [--input-file PATH] [--output-file PATH]."
                fi
                _fcc_in="$2"
                _fcc_in_set=1
                shift 2
                ;;
            --output-file)
                if [ $# -lt 2 ] || [ -z "${2-}" ]; then
                    out_die "--output-file requires a path. Next: ${APP_NAME} fix-config [--input-file PATH] [--output-file PATH]."
                fi
                _fcc_out="$2"
                _fcc_out_set=1
                shift 2
                ;;
            *)
                out_die "Unknown fix-config operand: $1. Next: ${APP_NAME} fix-config [--input-file PATH] [--output-file PATH]."
                ;;
        esac
    done
    if [ "${_fcc_in_set}" -eq 0 ]; then
        _fcc_in="${HOME}/.ssh/config"
    fi
    if [ ! -f "${_fcc_in}" ] || [ ! -r "${_fcc_in}" ]; then
        out_die "Cannot read ssh config: ${_fcc_in}."
    fi
    _fcc_os=$(sshd_fix_os_class)
    _fcc_tmp=$(mktemp -t "${APP_NAME}.fix-config.XXXXXX") || out_die "Could not create a temp file for ssh config."
    if ! sshd_fix_config_render "${_fcc_in}" "${_fcc_tmp}"; then
        rm -f "${_fcc_tmp}" >/dev/null 2>&1 || true
        out_die "Could not rewrite ${_fcc_in}."
    fi
    _fcc_changed=false
    if ! cmp -s "${_fcc_in}" "${_fcc_tmp}"; then
        _fcc_changed=true
    fi
    if [ "${_fcc_out_set}" -eq 1 ] && [ "${_fcc_out}" != "${_fcc_in}" ]; then
        _fcc_dir=$(dirname "${_fcc_out}")
        if [ ! -d "${_fcc_dir}" ] || [ ! -w "${_fcc_dir}" ]; then
            rm -f "${_fcc_tmp}" >/dev/null 2>&1 || true
            out_die "Cannot write ssh config: ${_fcc_out}."
        fi
        if [ -e "${_fcc_out}" ] && [ ! -w "${_fcc_out}" ]; then
            rm -f "${_fcc_tmp}" >/dev/null 2>&1 || true
            out_die "Cannot write ssh config: ${_fcc_out}."
        fi
        if ! mv "${_fcc_tmp}" "${_fcc_out}"; then
            rm -f "${_fcc_tmp}" >/dev/null 2>&1 || true
            out_die "Could not write ${_fcc_out}."
        fi
        chmod 600 "${_fcc_out}" 2>/dev/null || true
        unset _fcc_dir
    else
        if [ "${_fcc_changed}" = "true" ]; then
            if [ ! -w "${_fcc_in}" ]; then
                rm -f "${_fcc_tmp}" >/dev/null 2>&1 || true
                out_die "ssh config is not writable: ${_fcc_in}."
            fi
            sshd_dns_backup "${_fcc_in}" "fix-config"
            if ! mv "${_fcc_tmp}" "${_fcc_in}"; then
                rm -f "${_fcc_tmp}" >/dev/null 2>&1 || true
                out_die "Could not replace ${_fcc_in}."
            fi
            chmod 600 "${_fcc_in}" 2>/dev/null || true
        else
            rm -f "${_fcc_tmp}" >/dev/null 2>&1 || true
        fi
    fi
    if [ "${_fcc_changed}" = "true" ]; then
        _fcc_msg="Commented unsupported OpenSSH client keywords (${_fcc_os})."
    else
        _fcc_msg="OpenSSH client config already matches this OS (${_fcc_os})."
    fi
    out_json "fix-config" "${_fcc_msg}" "changed" "${_fcc_changed}" "os" "${_fcc_os}"
    out_success "${_fcc_msg}"
    unset _fcc_in _fcc_out _fcc_in_set _fcc_out_set _fcc_os _fcc_tmp _fcc_changed _fcc_msg
}

# Same comment rule as fix-config, before a dns rewrite. requirement-domain-sshd.
sshd_dns_plain_copy() {
    _plain_in="$1"
    _plain_out=$(mktemp -t "${APP_NAME}.ssh_config.plain.XXXXXX") || out_die "Could not create a temp file for ssh config."
    if ! sshd_fix_config_render "${_plain_in}" "${_plain_out}"; then
        rm -f "${_plain_out}"
        out_die "Could not rewrite ${_plain_in}."
    fi
    DNS_PLAIN="${_plain_out}"
    unset _plain_in _plain_out
}

# Rewrite concrete Host stanza number n. Empty new_* means omit that keyword.
# Keep extra Host aliases after the first pattern; canonicalize Key value form.
# 1 on Termux: HostKeyAlgorithms / PubkeyAcceptedAlgorithms are comments.
# An active keyword makes the Termux OpenSSH client error.
sshd_dns_algo_comment_flag() {
    if [ "$(sshd_fix_os_class)" = "termux" ]; then
        printf '1'
    else
        printf '0'
    fi
}

sshd_dns_old_openssh_hint() {
    if [ "$(sshd_fix_os_class)" = "termux" ]; then
        printf '%s' "Old OpenSSH on Termux writes HostKeyAlgorithms and PubkeyAcceptedAlgorithms as comments (an active line makes this ssh client error). ssh then passes -o HostKeyAlgorithms=+ssh-rsa."
    else
        printf '%s' "Old OpenSSH writes HostKeyAlgorithms and PubkeyAcceptedAlgorithms +ssh-rsa,ssh-dss."
    fi
}

sshd_dns_rewrite() {
    _rw_n="$1"
    _new_dns="$2"
    _new_ip="$3"
    _new_user="$4"
    _new_port="$5"
    _new_idfile="${6-}"
    _new_idonly="${7-}"
    _new_sai="${8-}"
    _new_sacm="${9-}"
    _new_tcpka="${10-}"
    _new_ipqos="${11-}"
    _new_hka="${12-}"
    _new_paa="${13-}"
    _new_ciphers="${14-}"
    _new_macs="${15-}"
    _cfg=$(sshd_dns_config_path)
    sshd_dns_ensure_file
    sshd_dns_backup "${_cfg}" "dns-edit"
    _tmp=$(mktemp -t "${APP_NAME}.ssh_config.XXXXXX") || out_die "Could not create a temp file for ssh config."
    _algo_comment=$(sshd_dns_algo_comment_flag)
    sshd_dns_plain_copy "${_cfg}"
    awk -v algocomment="${_algo_comment}" -v target="${_rw_n}" -v newdns="${_new_dns}" -v newip="${_new_ip}" \
        -v newuser="${_new_user}" -v newport="${_new_port}" \
        -v newidfile="${_new_idfile}" -v newidonly="${_new_idonly}" \
        -v newsai="${_new_sai}" -v newsacm="${_new_sacm}" \
        -v newtcpka="${_new_tcpka}" -v newipqos="${_new_ipqos}" \
        -v newhka="${_new_hka}" -v newpaa="${_new_paa}" \
        -v newciphers="${_new_ciphers}" -v newmacs="${_new_macs}" '
        function parse_line(line,    s, commented) {
            key=""; val=""; lk=""; host_rest=""
            commented=0
            s=line
            sub(/^[[:space:]]+/, "", s)
            if (s=="") return 0
            if (substr(s,1,1)=="#") {
                sub(/^#+[[:space:]]*/, "", s)
                commented=1
                if (s=="") return 0
            }
            if (!match(s, /^[A-Za-z][A-Za-z0-9]*/)) return 0
            key=substr(s, RSTART, RLENGTH)
            s=substr(s, RSTART+RLENGTH)
            sub(/^[[:space:]]*=[[:space:]]*/, "", s)
            sub(/^[[:space:]]+/, "", s)
            host_rest=s
            if (match(s, /^[^[:space:]]+/)) {
                val=substr(s, RSTART, RLENGTH)
                host_rest=substr(s, RSTART+RLENGTH)
            }
            lk=tolower(key)
            if (commented && lk!="hostkeyalgorithms" && lk!="pubkeyacceptedalgorithms" && lk!="pubkeyacceptedkeytypes") return 0
            return 1
        }
        function is_concrete(p) {
            return (p != "" && p !~ /[?*]/)
        }
        function emit_algo(key, val) {
            if (val == "") return
            if (algocomment+0 == 1) print "    # " key " " val
            else print "    " key " " val
        }
        function reset_saw() {
            saw_hn=0; saw_user=0; saw_port=0
            saw_idfile=0; saw_idonly=0; saw_sai=0; saw_sacm=0
            saw_tcpka=0; saw_ipqos=0; saw_hka=0; saw_paa=0
            saw_ciphers=0; saw_macs=0
        }
        function emit_missing() {
            if (!in_target) return
            if (!saw_hn && newip != "") print "    HostName " newip
            if (!saw_user && newuser != "") print "    User " newuser
            if (!saw_port && newport != "" && newport != "22") print "    Port " newport
            if (!saw_idfile && newidfile != "") print "    IdentityFile " newidfile
            if (!saw_idonly && newidonly != "") print "    IdentitiesOnly " newidonly
            if (!saw_ciphers && newciphers != "") print "    Ciphers " newciphers
            if (!saw_macs && newmacs != "") print "    MACs " newmacs
            if (!saw_sai && newsai != "") print "    ServerAliveInterval " newsai
            if (!saw_sacm && newsacm != "") print "    ServerAliveCountMax " newsacm
            if (!saw_tcpka && newtcpka != "") print "    TCPKeepAlive " newtcpka
            if (!saw_ipqos && newipqos != "") print "    IPQoS " newipqos
            if (!saw_hka && newhka != "") emit_algo("HostKeyAlgorithms", newhka)
            if (!saw_paa && newpaa != "") emit_algo("PubkeyAcceptedAlgorithms", newpaa)
        }
        BEGIN { n=0; in_match=0; in_target=0; reset_saw() }
        {
            raw=$0
            if (!parse_line($0)) {
                print raw
                next
            }
            if (lk=="match") {
                emit_missing()
                in_target=0
                in_match=1
                print raw
                next
            }
            if (lk=="host") {
                emit_missing()
                in_match=0
                in_target=0
                if (is_concrete(val)) {
                    n++
                    if (n==target+0) {
                        in_target=1
                        reset_saw()
                        extra=host_rest
                        sub(/^[[:space:]]+/, "", extra)
                        sub(/[[:space:]]+$/, "", extra)
                        if (extra != "") print "Host " newdns " " extra
                        else print "Host " newdns
                        next
                    }
                }
                print raw
                next
            }
            if (in_match) { print raw; next }
            if (in_target) {
                if (lk=="hostname") {
                    saw_hn=1
                    if (newip != "") print "    HostName " newip
                    next
                }
                if (lk=="user") {
                    saw_user=1
                    if (newuser != "") print "    User " newuser
                    next
                }
                if (lk=="port") {
                    saw_port=1
                    if (newport != "" && newport != "22") print "    Port " newport
                    next
                }
                if (lk=="identityfile") {
                    saw_idfile=1
                    if (newidfile != "") print "    IdentityFile " newidfile
                    next
                }
                if (lk=="identitiesonly") {
                    saw_idonly=1
                    if (newidonly != "") print "    IdentitiesOnly " newidonly
                    next
                }
                if (lk=="ciphers") {
                    saw_ciphers=1
                    if (newciphers != "") print "    Ciphers " newciphers
                    next
                }
                if (lk=="macs") {
                    saw_macs=1
                    if (newmacs != "") print "    MACs " newmacs
                    next
                }
                if (lk=="serveraliveinterval") {
                    saw_sai=1
                    if (newsai != "") print "    ServerAliveInterval " newsai
                    next
                }
                if (lk=="serveralivecountmax") {
                    saw_sacm=1
                    if (newsacm != "") print "    ServerAliveCountMax " newsacm
                    next
                }
                if (lk=="tcpkeepalive") {
                    saw_tcpka=1
                    if (newtcpka != "") print "    TCPKeepAlive " newtcpka
                    next
                }
                if (lk=="ipqos") {
                    saw_ipqos=1
                    if (newipqos != "") print "    IPQoS " newipqos
                    next
                }
                if (lk=="hostkeyalgorithms") {
                    saw_hka=1
                    if (newhka != "") emit_algo("HostKeyAlgorithms", newhka)
                    next
                }
                if (lk=="pubkeyacceptedalgorithms" || lk=="pubkeyacceptedkeytypes") {
                    saw_paa=1
                    if (newpaa != "") emit_algo("PubkeyAcceptedAlgorithms", newpaa)
                    next
                }
                print raw
                next
            }
            print raw
        }
        END { emit_missing() }
    ' "${DNS_PLAIN}" > "${_tmp}" || {
        rm -f "${_tmp}" "${DNS_PLAIN}"
        unset DNS_PLAIN
        out_die "Could not rewrite ${_cfg}."
    }
    rm -f "${DNS_PLAIN}"
    unset DNS_PLAIN
    sshd_dns_commit_tmp "${_tmp}" "${_cfg}"
    unset _rw_n _new_dns _new_ip _new_user _new_port _new_idfile _new_idonly
    unset _new_sai _new_sacm _new_tcpka _new_ipqos _new_hka _new_paa
    unset _new_ciphers _new_macs _cfg _tmp _algo_comment
}

# Insert a concrete Host before the first wildcard Host / Match (OpenSSH first-match).
sshd_dns_append() {
    _new_dns="$1"
    _new_ip="$2"
    _new_user="$3"
    _new_port="$4"
    _new_idfile="${5-}"
    _new_idonly="${6-}"
    _new_sai="${7-}"
    _new_sacm="${8-}"
    _new_tcpka="${9-}"
    _new_ipqos="${10-}"
    _new_hka="${11-}"
    _new_paa="${12-}"
    _new_ciphers="${13-}"
    _new_macs="${14-}"
    _cfg=$(sshd_dns_config_path)
    sshd_dns_ensure_file
    sshd_dns_backup "${_cfg}" "dns-add"
    _tmp=$(mktemp -t "${APP_NAME}.ssh_config.XXXXXX") || out_die "Could not create a temp file for ssh config."
    _algo_comment=$(sshd_dns_algo_comment_flag)
    sshd_dns_plain_copy "${_cfg}"
    awk -v algocomment="${_algo_comment}" -v newdns="${_new_dns}" -v newip="${_new_ip}" \
        -v newuser="${_new_user}" -v newport="${_new_port}" \
        -v newidfile="${_new_idfile}" -v newidonly="${_new_idonly}" \
        -v newsai="${_new_sai}" -v newsacm="${_new_sacm}" \
        -v newtcpka="${_new_tcpka}" -v newipqos="${_new_ipqos}" \
        -v newhka="${_new_hka}" -v newpaa="${_new_paa}" \
        -v newciphers="${_new_ciphers}" -v newmacs="${_new_macs}" '
        function parse_line(line,    s) {
            key=""; val=""; lk=""
            s=line
            sub(/^[[:space:]]+/, "", s)
            if (s=="" || substr(s,1,1)=="#") return 0
            if (!match(s, /^[A-Za-z][A-Za-z0-9]*/)) return 0
            key=substr(s, RSTART, RLENGTH)
            s=substr(s, RSTART+RLENGTH)
            sub(/^[[:space:]]*=[[:space:]]*/, "", s)
            sub(/^[[:space:]]+/, "", s)
            if (match(s, /^[^[:space:]]+/)) val=substr(s, RSTART, RLENGTH)
            lk=tolower(key)
            return 1
        }
        function emit_algo(key, val) {
            if (val == "") return
            if (algocomment+0 == 1) print "    # " key " " val
            else print "    " key " " val
        }
        function emit_stanza() {
            if (emitted) return
            if (had_output) print ""
            print "Host " newdns
            if (newip != "") print "    HostName " newip
            if (newuser != "") print "    User " newuser
            if (newport != "" && newport != "22") print "    Port " newport
            if (newidfile != "") print "    IdentityFile " newidfile
            if (newidonly != "") print "    IdentitiesOnly " newidonly
            if (newciphers != "") print "    Ciphers " newciphers
            if (newmacs != "") print "    MACs " newmacs
            if (newsai != "") print "    ServerAliveInterval " newsai
            if (newsacm != "") print "    ServerAliveCountMax " newsacm
            if (newtcpka != "") print "    TCPKeepAlive " newtcpka
            if (newipqos != "") print "    IPQoS " newipqos
            if (newhka != "") emit_algo("HostKeyAlgorithms", newhka)
            if (newpaa != "") emit_algo("PubkeyAcceptedAlgorithms", newpaa)
            emitted=1
        }
        BEGIN { emitted=0; had_output=0 }
        {
            raw=$0
            parsed=parse_line($0)
            if (parsed && (lk=="match" || (lk=="host" && (val=="" || val ~ /[?*]/)))) {
                emit_stanza()
            }
            print raw
            had_output=1
        }
        END { emit_stanza() }
    ' "${DNS_PLAIN}" > "${_tmp}" || {
        rm -f "${_tmp}" "${DNS_PLAIN}"
        unset DNS_PLAIN
        out_die "Could not rewrite ${_cfg}."
    }
    rm -f "${DNS_PLAIN}"
    unset DNS_PLAIN
    sshd_dns_commit_tmp "${_tmp}" "${_cfg}"
    unset _new_dns _new_ip _new_user _new_port _new_idfile _new_idonly
    unset _new_sai _new_sacm _new_tcpka _new_ipqos _new_hka _new_paa
    unset _new_ciphers _new_macs _cfg _tmp _algo_comment
}

# Drop concrete Host stanza number n (whole stanza, including extra aliases).
sshd_dns_remove() {
    _rm_n="$1"
    _cfg=$(sshd_dns_config_path)
    sshd_dns_ensure_file
    sshd_dns_backup "${_cfg}" "dns-delete"
    _tmp=$(mktemp -t "${APP_NAME}.ssh_config.XXXXXX") || out_die "Could not create a temp file for ssh config."
    sshd_dns_plain_copy "${_cfg}"
    awk -v target="${_rm_n}" '
        function parse_line(line,    s) {
            key=""; val=""; lk=""
            s=line
            sub(/^[[:space:]]+/, "", s)
            if (s=="" || substr(s,1,1)=="#") return 0
            if (!match(s, /^[A-Za-z][A-Za-z0-9]*/)) return 0
            key=substr(s, RSTART, RLENGTH)
            s=substr(s, RSTART+RLENGTH)
            sub(/^[[:space:]]*=[[:space:]]*/, "", s)
            sub(/^[[:space:]]+/, "", s)
            if (match(s, /^[^[:space:]]+/)) val=substr(s, RSTART, RLENGTH)
            lk=tolower(key)
            return 1
        }
        function is_concrete(p) {
            return (p != "" && p !~ /[?*]/)
        }
        BEGIN { n=0; skip=0 }
        {
            raw=$0
            if (!parse_line($0)) {
                if (skip) next
                print raw
                next
            }
            if (lk=="match") {
                skip=0
                print raw
                next
            }
            if (lk=="host") {
                skip=0
                if (is_concrete(val)) {
                    n++
                    if (n==target+0) {
                        skip=1
                        next
                    }
                }
                print raw
                next
            }
            if (skip) next
            print raw
        }
    ' "${DNS_PLAIN}" > "${_tmp}" || {
        rm -f "${_tmp}" "${DNS_PLAIN}"
        unset DNS_PLAIN
        out_die "Could not rewrite ${_cfg}."
    }
    rm -f "${DNS_PLAIN}"
    unset DNS_PLAIN
    sshd_dns_commit_tmp "${_tmp}" "${_cfg}"
    unset _rm_n _cfg _tmp
}

sshd_dns_name_taken() {
    _name="$1"
    _except_n="${2-}"
    sshd_dns_records | awk -F '\t' -v w="${_name}" -v ex="${_except_n}" '
        $2==w && $1!=ex { found=1; exit }
        END { exit found?0:1 }
    '
}

# Sets DNS_FIELD_VALUE. MUST run in current shell (do-not-capture-read).
sshd_dns_prompt_field() {
    _label="$1"
    _cur="$2"
    _disp="$3"
    DNS_FIELD_VALUE="${_cur}"
    if ! sshd_dns_can_prompt; then
        unset _label _cur _disp
        return 0
    fi
    out_msg_n "${_label} [${_disp}]: "
    _ans=""
    read -r _ans || true
    if [ -z "${_ans}" ]; then
        DNS_FIELD_VALUE="${_cur}"
    else
        DNS_FIELD_VALUE=$(sshd_dns_norm "${_ans}")
    fi
    unset _label _cur _disp _ans
}

sshd_dns_parse_kv() {
    DNS_SET_DNS=0
    DNS_SET_IP=0
    DNS_SET_USER=0
    DNS_SET_PORT=0
    DNS_SET_IDFILE=0
    DNS_SET_IDONLY=0
    DNS_SET_TERMUX=0
    DNS_SET_OLD=0
    DNS_NEW_DNS=""
    DNS_NEW_IP=""
    DNS_NEW_USER=""
    DNS_NEW_PORT=""
    DNS_NEW_IDFILE=""
    DNS_NEW_IDONLY=""
    DNS_NEW_TERMUX=""
    DNS_NEW_OLD=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --dns|dns)
                [ $# -lt 2 ] && out_die "dns needs a value. Next: ${APP_NAME} dns set <n> dns <name>"
                DNS_SET_DNS=1
                DNS_NEW_DNS=$(sshd_dns_norm "$2")
                shift 2
                ;;
            --ip|ip)
                [ $# -lt 2 ] && out_die "ip needs a value. Next: ${APP_NAME} dns set <n> ip <addr>"
                DNS_SET_IP=1
                DNS_NEW_IP=$(sshd_dns_norm "$2")
                shift 2
                ;;
            --user|user)
                [ $# -lt 2 ] && out_die "user needs a value (use \"\" for empty). Next: ${APP_NAME} dns set <n> user \"\""
                DNS_SET_USER=1
                DNS_NEW_USER=$(sshd_dns_norm "$2")
                shift 2
                ;;
            --port|port)
                [ $# -lt 2 ] && out_die "port needs a value (use \"\" for default 22). Next: ${APP_NAME} dns set <n> port \"\""
                DNS_SET_PORT=1
                DNS_NEW_PORT=$(sshd_dns_norm "$2")
                shift 2
                ;;
            --identity-file|identity-file|identityfile)
                [ $# -lt 2 ] && out_die "identity-file needs a value (use \"\" for empty). Next: ${APP_NAME} dns set <n> identity-file \"\""
                DNS_SET_IDFILE=1
                DNS_NEW_IDFILE=$(sshd_dns_norm "$2")
                shift 2
                ;;
            --identities-only|identities-only|identitiesonly)
                [ $# -lt 2 ] && out_die "identities-only needs yes, no, or empty. Next: ${APP_NAME} dns set <n> identities-only yes"
                DNS_SET_IDONLY=1
                DNS_NEW_IDONLY=$(sshd_dns_norm_idonly "$(sshd_dns_norm "$2")")
                shift 2
                ;;
            --termux|termux)
                [ $# -lt 2 ] && out_die "termux needs yes or no. Next: ${APP_NAME} dns add dns <name> termux yes"
                DNS_SET_TERMUX=1
                sshd_dns_parse_yn_operand "termux" "$2"
                DNS_NEW_TERMUX="${DNS_YN_VALUE}"
                shift 2
                ;;
            --old-openssh|old-openssh|oldopenssh)
                [ $# -lt 2 ] && out_die "old-openssh needs yes or no. Next: ${APP_NAME} dns add dns <name> old-openssh yes"
                DNS_SET_OLD=1
                sshd_dns_parse_yn_operand "old-openssh" "$2"
                DNS_NEW_OLD="${DNS_YN_VALUE}"
                shift 2
                ;;
            *)
                out_die "Unknown dns field '${1}'. Use dns, ip, user, port, identity-file, identities-only, termux, or old-openssh."
                ;;
        esac
    done
}

sshd_dns_apply_set() {
    _sel="$1"
    shift
    _row=$(sshd_dns_lookup "${_sel}") || out_die "No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list"
    sshd_dns_load_row "${_row}"
    _n="${DNS_R_N}"
    _dns="${DNS_R_DNS}"
    _ip="${DNS_R_IP}"
    _user="${DNS_R_USER}"
    _port="${DNS_R_PORT}"
    _idfile="${DNS_R_IDFILE}"
    _idonly="${DNS_R_IDONLY}"
    _sai="${DNS_R_SAI}"
    _sacm="${DNS_R_SACM}"
    _tcpka="${DNS_R_TCPKA}"
    _ipqos="${DNS_R_IPQOS}"
    _hka="${DNS_R_HKA}"
    _paa="${DNS_R_PAA}"
    _ciphers="${DNS_R_CIPHERS}"
    _macs="${DNS_R_MACS}"
    sshd_dns_parse_kv "$@"
    [ "${DNS_SET_DNS}" -eq 1 ] && _dns="${DNS_NEW_DNS}"
    [ "${DNS_SET_IP}" -eq 1 ] && _ip="${DNS_NEW_IP}"
    [ "${DNS_SET_USER}" -eq 1 ] && _user="${DNS_NEW_USER}"
    [ "${DNS_SET_PORT}" -eq 1 ] && _port="${DNS_NEW_PORT}"
    [ "${DNS_SET_IDFILE}" -eq 1 ] && _idfile="${DNS_NEW_IDFILE}"
    [ "${DNS_SET_IDONLY}" -eq 1 ] && _idonly="${DNS_NEW_IDONLY}"
    if [ "${DNS_SET_TERMUX}" -eq 1 ]; then
        if [ "${DNS_NEW_TERMUX}" = "yes" ]; then
            sshd_dns_termux_bundle_yes
            _port="${DNS_TX_PORT}"
            _sai="${DNS_TX_SAI}"
            _sacm="${DNS_TX_SACM}"
            _tcpka="${DNS_TX_TCPKA}"
            _ipqos="${DNS_TX_IPQOS}"
            _ciphers="${DNS_TX_CIPHERS}"
            _macs="${DNS_TX_MACS}"
        else
            _sai=""
            _sacm=""
            _tcpka=""
            _ipqos=""
            _ciphers=""
            _macs=""
        fi
    fi
    if [ "${DNS_SET_OLD}" -eq 1 ]; then
        if [ "${DNS_NEW_OLD}" = "yes" ]; then
            _hka="+ssh-rsa,ssh-dss"
            _paa="+ssh-rsa,ssh-dss"
        else
            _hka=""
            _paa=""
        fi
    fi
    sshd_dns_validate_name "${_dns}" "${APP_NAME} dns set ${_n} dns <name>"
    sshd_dns_validate_port "${_port}"
    sshd_dns_validate_idonly "${_idonly}"
    if sshd_dns_name_taken "${_dns}" "${_n}"; then
        out_die "dns name '${_dns}' is already a Host entry. Next: ${APP_NAME} dns list"
    fi
    sshd_dns_rewrite "${_n}" "${_dns}" "${_ip}" "${_user}" "${_port}" \
        "${_idfile}" "${_idonly}" "${_sai}" "${_sacm}" "${_tcpka}" "${_ipqos}" "${_hka}" "${_paa}" \
        "${_ciphers}" "${_macs}"
    if [ "${JSON}" -eq 1 ]; then
        out_json "out_success" "Host entry updated." "n" "${_n}" "dns" "${_dns}" "ip" "${_ip}" "user" "${_user}" "port" "${_port}"
    else
        out_success "Updated Host ${_dns} in $(sshd_dns_config_path)."
        sshd_dns_print_details "${_n}" "${_dns}" "${_ip}" "${_user}" "${_port}" \
            "${_idfile}" "${_idonly}" "${_sai}" "${_sacm}" "${_tcpka}" "${_ipqos}" "${_hka}" "${_paa}" \
            "${_ciphers}" "${_macs}"
    fi
    unset _sel _row _n _dns _ip _user _port _idfile _idonly _sai _sacm _tcpka _ipqos _hka _paa _ciphers _macs
}

sshd_dns_walk_edit() {
    _sel="$1"
    _row=$(sshd_dns_lookup "${_sel}") || out_die "No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list"
    sshd_dns_load_row "${_row}"
    _n="${DNS_R_N}"
    _dns="${DNS_R_DNS}"
    _ip="${DNS_R_IP}"
    _user="${DNS_R_USER}"
    _port="${DNS_R_PORT}"
    _idfile="${DNS_R_IDFILE}"
    _idonly="${DNS_R_IDONLY}"
    _sai="${DNS_R_SAI}"
    _sacm="${DNS_R_SACM}"
    _tcpka="${DNS_R_TCPKA}"
    _ipqos="${DNS_R_IPQOS}"
    _hka="${DNS_R_HKA}"
    _paa="${DNS_R_PAA}"
    _ciphers="${DNS_R_CIPHERS}"
    _macs="${DNS_R_MACS}"
    sshd_dns_print_details "${_n}" "${_dns}" "${_ip}" "${_user}" "${_port}" \
        "${_idfile}" "${_idonly}" "${_sai}" "${_sacm}" "${_tcpka}" "${_ipqos}" "${_hka}" "${_paa}" \
        "${_ciphers}" "${_macs}"
    if ! sshd_dns_can_prompt; then
        out_die "dns edit needs a terminal. Next: ${APP_NAME} dns set ${_n} ip <addr> user \"\" port 22"
    fi
    out_info "Enter keeps the current value. Type \"\" for empty."
    sshd_dns_prompt_field "dns" "${_dns}" "${_dns}"
    _dns="${DNS_FIELD_VALUE}"
    sshd_dns_prompt_field "ip" "${_ip}" "$(sshd_dns_disp_ip "${_ip}")"
    _ip="${DNS_FIELD_VALUE}"
    sshd_dns_prompt_field "user" "${_user}" "$(sshd_dns_disp_user "${_user}")"
    _user="${DNS_FIELD_VALUE}"
    _termux_def=$(sshd_dns_disp_termux "${_port}" "${_sai}" "${_sacm}" "${_tcpka}" "${_ipqos}" "${_ciphers}" "${_macs}")
    out_info "as Termux writes Port 8022, Ciphers aes128-ctr,aes256-ctr, MACs hmac-sha2-256, ServerAliveInterval 15, ServerAliveCountMax 12, TCPKeepAlive yes, IPQoS none (slow Termux sshd can otherwise corrupt the session)."
    sshd_dns_prompt_yn "as Termux" "${_termux_def}"
    if [ "${DNS_YN_VALUE}" = "yes" ]; then
        sshd_dns_termux_bundle_yes
        _port="${DNS_TX_PORT}"
        _sai="${DNS_TX_SAI}"
        _sacm="${DNS_TX_SACM}"
        _tcpka="${DNS_TX_TCPKA}"
        _ipqos="${DNS_TX_IPQOS}"
        _ciphers="${DNS_TX_CIPHERS}"
        _macs="${DNS_TX_MACS}"
    else
        _sai=""
        _sacm=""
        _tcpka=""
        _ipqos=""
        _ciphers=""
        _macs=""
        sshd_dns_prompt_field "port" "${_port}" "$(sshd_dns_disp_port "${_port}")"
        _port="${DNS_FIELD_VALUE}"
    fi
    sshd_dns_prompt_field "identity-file" "${_idfile}" "$(sshd_dns_disp_opt "${_idfile}")"
    _idfile="${DNS_FIELD_VALUE}"
    sshd_dns_prompt_field "identities-only" "${_idonly}" "$(sshd_dns_disp_opt "${_idonly}")"
    _idonly=$(sshd_dns_norm_idonly "${DNS_FIELD_VALUE}")
    _old_def=$(sshd_dns_disp_old "${_hka}" "${_paa}")
    out_info "$(sshd_dns_old_openssh_hint)"
    sshd_dns_prompt_yn "Old OpenSSH" "${_old_def}"
    if [ "${DNS_YN_VALUE}" = "yes" ]; then
        _hka="+ssh-rsa,ssh-dss"
        _paa="+ssh-rsa,ssh-dss"
    else
        _hka=""
        _paa=""
    fi
    sshd_dns_validate_name "${_dns}" "${APP_NAME} dns set ${_n} dns <name>"
    sshd_dns_validate_port "${_port}"
    sshd_dns_validate_idonly "${_idonly}"
    if sshd_dns_name_taken "${_dns}" "${_n}"; then
        out_die "dns name '${_dns}' is already a Host entry. Next: ${APP_NAME} dns list"
    fi
    sshd_dns_rewrite "${_n}" "${_dns}" "${_ip}" "${_user}" "${_port}" \
        "${_idfile}" "${_idonly}" "${_sai}" "${_sacm}" "${_tcpka}" "${_ipqos}" "${_hka}" "${_paa}" \
        "${_ciphers}" "${_macs}"
    out_success "Updated Host ${_dns} in $(sshd_dns_config_path)."
    sshd_dns_print_details "${_n}" "${_dns}" "${_ip}" "${_user}" "${_port}" \
        "${_idfile}" "${_idonly}" "${_sai}" "${_sacm}" "${_tcpka}" "${_ipqos}" "${_hka}" "${_paa}" \
        "${_ciphers}" "${_macs}"
    unset _sel _row _n _dns _ip _user _port _idfile _idonly _sai _sacm _tcpka _ipqos _hka _paa _ciphers _macs _termux_def _old_def
}

sshd_dns_walk_add() {
    _dns=""
    _ip=""
    _user=""
    _port=""
    _idfile=""
    _idonly=""
    _sai=""
    _sacm=""
    _tcpka=""
    _ipqos=""
    _hka=""
    _paa=""
    _ciphers=""
    _macs=""
    _idonly_def=""
    if sshd_dns_can_prompt && [ $# -eq 0 ]; then
        out_info "New Host in $(sshd_dns_config_path). Enter keeps empty. Type \"\" for empty."
        sshd_dns_prompt_field "dns" "" "(empty)"
        _dns="${DNS_FIELD_VALUE}"
        sshd_dns_prompt_field "ip" "" "(empty)"
        _ip="${DNS_FIELD_VALUE}"
        sshd_dns_prompt_field "user" "" "empty"
        _user="${DNS_FIELD_VALUE}"
        out_info "as Termux writes Port 8022, Ciphers aes128-ctr,aes256-ctr, MACs hmac-sha2-256, ServerAliveInterval 15, ServerAliveCountMax 12, TCPKeepAlive yes, IPQoS none (slow Termux sshd can otherwise corrupt the session)."
        sshd_dns_prompt_yn "as Termux" "yes"
        if [ "${DNS_YN_VALUE}" = "yes" ]; then
            sshd_dns_termux_bundle_yes
            _port="${DNS_TX_PORT}"
            _sai="${DNS_TX_SAI}"
            _sacm="${DNS_TX_SACM}"
            _tcpka="${DNS_TX_TCPKA}"
            _ipqos="${DNS_TX_IPQOS}"
            _ciphers="${DNS_TX_CIPHERS}"
            _macs="${DNS_TX_MACS}"
        else
            sshd_dns_prompt_field "port" "" "22"
            _port="${DNS_FIELD_VALUE}"
        fi
        sshd_dns_prompt_field "identity-file" "" "empty"
        _idfile="${DNS_FIELD_VALUE}"
        if [ -n "${_idfile}" ]; then
            _idonly_def="yes"
        else
            _idonly_def=""
        fi
        sshd_dns_prompt_field "identities-only" "${_idonly_def}" "$(sshd_dns_disp_opt "${_idonly_def}")"
        _idonly=$(sshd_dns_norm_idonly "${DNS_FIELD_VALUE}")
        out_info "$(sshd_dns_old_openssh_hint)"
        sshd_dns_prompt_yn "Old OpenSSH" "yes"
        if [ "${DNS_YN_VALUE}" = "yes" ]; then
            _hka="+ssh-rsa,ssh-dss"
            _paa="+ssh-rsa,ssh-dss"
        fi
    else
        sshd_dns_parse_kv "$@"
        [ "${DNS_SET_DNS}" -eq 1 ] && _dns="${DNS_NEW_DNS}"
        [ "${DNS_SET_IP}" -eq 1 ] && _ip="${DNS_NEW_IP}"
        [ "${DNS_SET_USER}" -eq 1 ] && _user="${DNS_NEW_USER}"
        [ "${DNS_SET_PORT}" -eq 1 ] && _port="${DNS_NEW_PORT}"
        [ "${DNS_SET_IDFILE}" -eq 1 ] && _idfile="${DNS_NEW_IDFILE}"
        [ "${DNS_SET_IDONLY}" -eq 1 ] && _idonly="${DNS_NEW_IDONLY}"
        if [ "${DNS_SET_TERMUX}" -eq 1 ] && [ "${DNS_NEW_TERMUX}" = "yes" ]; then
            sshd_dns_termux_bundle_yes
            _port="${DNS_TX_PORT}"
            _sai="${DNS_TX_SAI}"
            _sacm="${DNS_TX_SACM}"
            _tcpka="${DNS_TX_TCPKA}"
            _ipqos="${DNS_TX_IPQOS}"
            _ciphers="${DNS_TX_CIPHERS}"
            _macs="${DNS_TX_MACS}"
        fi
        if [ "${DNS_SET_OLD}" -eq 1 ] && [ "${DNS_NEW_OLD}" = "yes" ]; then
            _hka="+ssh-rsa,ssh-dss"
            _paa="+ssh-rsa,ssh-dss"
        fi
    fi
    sshd_dns_validate_name "${_dns}" "${APP_NAME} dns add dns <name>"
    sshd_dns_validate_port "${_port}"
    sshd_dns_validate_idonly "${_idonly}"
    if sshd_dns_name_taken "${_dns}" ""; then
        out_die "dns name '${_dns}' is already a Host entry. Next: ${APP_NAME} dns list"
    fi
    sshd_dns_append "${_dns}" "${_ip}" "${_user}" "${_port}" \
        "${_idfile}" "${_idonly}" "${_sai}" "${_sacm}" "${_tcpka}" "${_ipqos}" "${_hka}" "${_paa}" \
        "${_ciphers}" "${_macs}"
    _n=$(sshd_dns_count)
    if [ "${JSON}" -eq 1 ]; then
        out_json "out_success" "Host entry added." "n" "${_n}" "dns" "${_dns}" "ip" "${_ip}" "user" "${_user}" "port" "${_port}"
    else
        out_success "Added Host ${_dns} in $(sshd_dns_config_path)."
        sshd_dns_print_details "${_n}" "${_dns}" "${_ip}" "${_user}" "${_port}" \
            "${_idfile}" "${_idonly}" "${_sai}" "${_sacm}" "${_tcpka}" "${_ipqos}" "${_hka}" "${_paa}" \
            "${_ciphers}" "${_macs}"
    fi
    unset _dns _ip _user _port _idfile _idonly _sai _sacm _tcpka _ipqos _hka _paa _ciphers _macs _n _idonly_def
}

# Last updated: 2026-09-12
# Optional fields only. MUST NOT clear dns (Host) or ip (HostName).
sshd_dns_unset_refuse_identity() {
    out_die "Cannot unset dns or ip (the Host name and address stay). Next: ${APP_NAME} dns unset <n> user"
}

# Last updated: 2026-09-12
sshd_dns_unset_parse_fields() {
    DNS_UNSET_USER=0
    DNS_UNSET_PORT=0
    DNS_UNSET_IDFILE=0
    DNS_UNSET_IDONLY=0
    DNS_UNSET_TERMUX=0
    DNS_UNSET_OLD=0
    DNS_UNSET_ANY=0
    while [ $# -gt 0 ]; do
        _uf=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
        case "${_uf}" in
            dns|--dns|ip|--ip|hostname|--hostname|host|--host)
                unset _uf
                sshd_dns_unset_refuse_identity
                ;;
            user|--user)
                DNS_UNSET_USER=1
                DNS_UNSET_ANY=1
                shift
                ;;
            port|--port)
                DNS_UNSET_PORT=1
                DNS_UNSET_ANY=1
                shift
                ;;
            identity-file|--identity-file|identityfile)
                DNS_UNSET_IDFILE=1
                DNS_UNSET_ANY=1
                shift
                ;;
            identities-only|--identities-only|identitiesonly)
                DNS_UNSET_IDONLY=1
                DNS_UNSET_ANY=1
                shift
                ;;
            termux|--termux)
                DNS_UNSET_TERMUX=1
                DNS_UNSET_ANY=1
                shift
                ;;
            old-openssh|--old-openssh|oldopenssh)
                DNS_UNSET_OLD=1
                DNS_UNSET_ANY=1
                shift
                ;;
            *)
                out_die "Unknown extra setting '${1}'. Use user, port, identity-file, identities-only, termux, or old-openssh (not dns or ip). Next: ${APP_NAME} dns unset <n> user"
                ;;
        esac
    done
    unset _uf
}

# Last updated: 2026-09-12
# Apply already-parsed DNS_UNSET_* flags to a loaded row, then rewrite.
sshd_dns_unset_commit() {
    _n="${DNS_R_N}"
    _dns="${DNS_R_DNS}"
    _ip="${DNS_R_IP}"
    _user="${DNS_R_USER}"
    _port="${DNS_R_PORT}"
    _idfile="${DNS_R_IDFILE}"
    _idonly="${DNS_R_IDONLY}"
    _sai="${DNS_R_SAI}"
    _sacm="${DNS_R_SACM}"
    _tcpka="${DNS_R_TCPKA}"
    _ipqos="${DNS_R_IPQOS}"
    _hka="${DNS_R_HKA}"
    _paa="${DNS_R_PAA}"
    _ciphers="${DNS_R_CIPHERS}"
    _macs="${DNS_R_MACS}"
    _cleared=""
    if [ "${DNS_UNSET_USER}" -eq 1 ]; then
        _user=""
        _cleared="${_cleared} user"
    fi
    if [ "${DNS_UNSET_PORT}" -eq 1 ]; then
        _port=""
        _cleared="${_cleared} port"
    fi
    if [ "${DNS_UNSET_IDFILE}" -eq 1 ]; then
        _idfile=""
        _cleared="${_cleared} identity-file"
    fi
    if [ "${DNS_UNSET_IDONLY}" -eq 1 ]; then
        _idonly=""
        _cleared="${_cleared} identities-only"
    fi
    if [ "${DNS_UNSET_TERMUX}" -eq 1 ]; then
        _sai=""
        _sacm=""
        _tcpka=""
        _ipqos=""
        _ciphers=""
        _macs=""
        _cleared="${_cleared} termux"
    fi
    if [ "${DNS_UNSET_OLD}" -eq 1 ]; then
        _hka=""
        _paa=""
        _cleared="${_cleared} old-openssh"
    fi
    _cleared="${_cleared# }"
    sshd_dns_rewrite "${_n}" "${_dns}" "${_ip}" "${_user}" "${_port}" \
        "${_idfile}" "${_idonly}" "${_sai}" "${_sacm}" "${_tcpka}" "${_ipqos}" "${_hka}" "${_paa}" \
        "${_ciphers}" "${_macs}"
    if [ "${JSON}" -eq 1 ]; then
        out_json "out_success" "Host extra settings cleared." "n" "${_n}" "dns" "${_dns}" "cleared" "${_cleared}"
    else
        out_success "Cleared ${_cleared} from Host ${_dns} in $(sshd_dns_config_path)."
        sshd_dns_print_details "${_n}" "${_dns}" "${_ip}" "${_user}" "${_port}" \
            "${_idfile}" "${_idonly}" "${_sai}" "${_sacm}" "${_tcpka}" "${_ipqos}" "${_hka}" "${_paa}" \
            "${_ciphers}" "${_macs}"
    fi
    unset _n _dns _ip _user _port _idfile _idonly _sai _sacm _tcpka _ipqos _hka _paa _ciphers _macs _cleared
}

# Last updated: 2026-09-12
# TTY picker of currently set extra fields. MUST run in current shell (do-not-capture-read).
sshd_dns_walk_unset() {
    _sel="$1"
    out_info "Clear extra settings. dns (Host name) and ip (address) stay. Enter on Edit still keeps the current value."
    while true; do
        _row=$(sshd_dns_lookup "${_sel}") || out_die "No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list"
        sshd_dns_load_row "${_row}"
        _n="${DNS_R_N}"
        _dns="${DNS_R_DNS}"
        _tx=$(sshd_dns_disp_termux "${DNS_R_PORT}" "${DNS_R_SAI}" "${DNS_R_SACM}" "${DNS_R_TCPKA}" "${DNS_R_IPQOS}" "${DNS_R_CIPHERS}" "${DNS_R_MACS}")
        _old=$(sshd_dns_disp_old "${DNS_R_HKA}" "${DNS_R_PAA}")
        _keys=""
        _i=0
        if [ -n "${DNS_R_USER}" ]; then
            _i=$((_i + 1))
            _keys="${_keys} user"
            out_plain "${_i}. user (${DNS_R_USER})"
        fi
        if [ -n "${DNS_R_PORT}" ]; then
            _i=$((_i + 1))
            _keys="${_keys} port"
            out_plain "${_i}. port (${DNS_R_PORT})"
        fi
        if [ -n "${DNS_R_IDFILE}" ]; then
            _i=$((_i + 1))
            _keys="${_keys} identity-file"
            out_plain "${_i}. identity-file (${DNS_R_IDFILE})"
        fi
        if [ -n "${DNS_R_IDONLY}" ]; then
            _i=$((_i + 1))
            _keys="${_keys} identities-only"
            out_plain "${_i}. identities-only (${DNS_R_IDONLY})"
        fi
        if [ "${_tx}" = "yes" ]; then
            _i=$((_i + 1))
            _keys="${_keys} termux"
            out_plain "${_i}. as Termux (yes)"
        fi
        if [ "${_old}" = "yes" ]; then
            _i=$((_i + 1))
            _keys="${_keys} old-openssh"
            out_plain "${_i}. Old OpenSSH (yes)"
        fi
        if [ "${_i}" -eq 0 ]; then
            out_info "Nothing extra to clear on Host ${_dns} (dns and ip stay)."
            unset _sel _row _n _dns _tx _old _keys _i _pick _k
            return 0
        fi
        out_plain "0. Done"
        out_msg_n "Choose a number to clear (0 to leave): "
        _pick=""
        read -r _pick || true
        case "${_pick}" in
            0|q|exit|"")
                unset _sel _row _n _dns _tx _old _keys _i _pick _k
                return 0
                ;;
        esac
        case "${_pick}" in
            *[!0-9]*)
                out_warn "Unknown extra-settings choice '${_pick}'. Choose a number from the list (0 to leave)."
                continue
                ;;
        esac
        if [ "${_pick}" -lt 1 ] || [ "${_pick}" -gt "${_i}" ]; then
            out_warn "Unknown extra-settings choice '${_pick}'. Choose a number from the list (0 to leave)."
            continue
        fi
        _k=$(printf '%s' "${_keys}" | awk -v n="${_pick}" '{print $n}')
        sshd_dns_unset_parse_fields "${_k}"
        sshd_dns_unset_commit
    done
}

# Last updated: 2026-09-12
sshd_dns_apply_unset() {
    _sel="${1-}"
    if [ -z "${_sel}" ]; then
        if sshd_dns_can_prompt; then
            if sshd_dns_pick_host "unset"; then
                sshd_dns_walk_unset "${DNS_PICK_SEL}"
            fi
            unset _sel
            return 0
        fi
        out_die "dns unset needs a number or Host name and a field. Next: ${APP_NAME} dns unset <n> user"
    fi
    shift
    _row=$(sshd_dns_lookup "${_sel}") || out_die "No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list"
    sshd_dns_load_row "${_row}"
    if [ $# -eq 0 ]; then
        if sshd_dns_can_prompt; then
            sshd_dns_walk_unset "${_sel}"
            unset _sel _row
            return 0
        fi
        out_die "dns unset needs a field (user, port, identity-file, identities-only, termux, or old-openssh — not dns or ip). Next: ${APP_NAME} dns unset ${_sel} user"
    fi
    sshd_dns_unset_parse_fields "$@"
    if [ "${DNS_UNSET_ANY}" -ne 1 ]; then
        out_die "dns unset needs a field (user, port, identity-file, identities-only, termux, or old-openssh — not dns or ip). Next: ${APP_NAME} dns unset ${_sel} user"
    fi
    sshd_dns_unset_commit
    unset _sel _row
}

sshd_dns_apply_delete() {
    : "${FORCE:=0}"
    _sel="$1"
    _row=$(sshd_dns_lookup "${_sel}") || out_die "No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list"
    sshd_dns_load_row "${_row}"
    _n="${DNS_R_N}"
    _dns="${DNS_R_DNS}"
    _ip="${DNS_R_IP}"
    _user="${DNS_R_USER}"
    _port="${DNS_R_PORT}"
    if sshd_dns_can_prompt; then
        sshd_dns_print_details "${_n}" "${_dns}" "${_ip}" "${_user}" "${_port}" \
            "${DNS_R_IDFILE}" "${DNS_R_IDONLY}" "${DNS_R_SAI}" "${DNS_R_SACM}" "${DNS_R_TCPKA}" "${DNS_R_IPQOS}" "${DNS_R_HKA}" "${DNS_R_PAA}" \
            "${DNS_R_CIPHERS}" "${DNS_R_MACS}"
        if [ "${FORCE}" -eq 0 ]; then
            if ! prompt_yes_no "Delete Host ${_dns} from $(sshd_dns_config_path)"; then
                out_info "Delete cancelled."
                unset _sel _row _n _dns _ip _user _port
                return 0
            fi
        fi
    fi
    sshd_dns_remove "${_n}"
    if [ "${JSON}" -eq 1 ]; then
        out_json "out_success" "Host entry deleted." "n" "${_n}" "dns" "${_dns}"
    else
        out_success "Deleted Host ${_dns} from $(sshd_dns_config_path)."
    fi
    unset _sel _row _n _dns _ip _user _port
}

# Sets DNS_PICK_SEL. MUST run in current shell (do-not-capture-read).
# Return 1 = leave / empty list. Host pick uses 0 to leave (row 9 is a Host).
# Unknown / out-of-range choice warns and redisplays (MUST NOT out_die).
sshd_dns_pick_host() {
    _ph_verb="$1"
    DNS_PICK_SEL=""
    if [ "$(sshd_dns_count)" -eq 0 ]; then
        out_info "No concrete Host entries in $(sshd_dns_config_path)."
        out_info "Next: ${APP_NAME} dns add"
        unset _ph_verb
        return 1
    fi
    while true; do
        sshd_dns_list_human
        out_plain "0. Exit"
        out_msg_n "Choose a number to ${_ph_verb} (0 to leave): "
        _choice=""
        read -r _choice || true
        case "${_choice}" in
            0|q|exit|"")
                unset _ph_verb _choice
                return 1
                ;;
        esac
        if sshd_dns_lookup "${_choice}" >/dev/null; then
            DNS_PICK_SEL="${_choice}"
            unset _ph_verb _choice
            return 0
        fi
        out_warn "Unknown Host choice '${_choice}'. Choose a number from the list (0 to leave)."
    done
}

sshd_dns_interactive_pick() {
    while true; do
        out_info "SSH names (dns) in $(sshd_dns_config_path)"
        sshd_dns_list_context
        out_menu_choice "111" "Edit" "change this Host (dns, ip, user, Termux, identity, Old OpenSSH). Enter keeps the current value"
        out_menu_choice "112" "Add" "new Host in this login ~/.ssh/config"
        out_menu_choice "113" "Delete" "remove a Host"
        out_menu_choice "114" "Unset" "drop extra settings (user, port, …) — not dns or ip"
        out_plain "0. Back"
        out_msg_n "Choose a number, or type the command name: "
        _act=""
        read -r _act || true
        case "${_act}" in
            111|edit)
                if sshd_dns_pick_host "edit"; then
                    sshd_dns_walk_edit "${DNS_PICK_SEL}"
                fi
                break
                ;;
            112|add)
                sshd_dns_walk_add
                break
                ;;
            113|delete|rm)
                if sshd_dns_pick_host "delete"; then
                    sshd_dns_apply_delete "${DNS_PICK_SEL}"
                fi
                break
                ;;
            114|unset|clear)
                if sshd_dns_pick_host "unset"; then
                    sshd_dns_walk_unset "${DNS_PICK_SEL}"
                fi
                break
                ;;
            0|q|exit|"")
                unset _act
                return 0
                ;;
            *)
                out_warn "Unknown dns action '${_act}'. Choose a number from the list, or type edit, add, delete, or unset."
                continue
                ;;
        esac
    done
    unset _act
}

# Last updated: 2026-09-12
# ALIGNMENT: requirement-domain-sshd.md · requirement-shell-cli-interface.md
sshd_cmd_dns() {
    : "${INTERACTIVE:=0}"
    _sub="${1-}"
    if [ $# -gt 0 ]; then
        shift
    fi
    case "${_sub}" in
        ""|list)
            if [ -z "${_sub}" ] && sshd_dns_can_prompt; then
                sshd_dns_interactive_pick
            elif [ "${JSON}" -eq 1 ]; then
                sshd_dns_list_json
            else
                sshd_dns_list_human
            fi
            ;;
        show)
            _sel="${1-}"
            [ -z "${_sel}" ] && out_die "dns show needs a number or Host name. Next: ${APP_NAME} dns list"
            _row=$(sshd_dns_lookup "${_sel}") || out_die "No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list"
            sshd_dns_load_row "${_row}"
            sshd_dns_print_details "${DNS_R_N}" "${DNS_R_DNS}" "${DNS_R_IP}" "${DNS_R_USER}" "${DNS_R_PORT}" \
                "${DNS_R_IDFILE}" "${DNS_R_IDONLY}" "${DNS_R_SAI}" "${DNS_R_SACM}" "${DNS_R_TCPKA}" "${DNS_R_IPQOS}" "${DNS_R_HKA}" "${DNS_R_PAA}" \
                "${DNS_R_CIPHERS}" "${DNS_R_MACS}"
            unset _sel _row
            ;;
        edit)
            _sel="${1-}"
            [ -z "${_sel}" ] && out_die "dns edit needs a number or Host name. Next: ${APP_NAME} dns list"
            sshd_dns_walk_edit "${_sel}"
            unset _sel
            ;;
        set)
            _sel="${1-}"
            [ -z "${_sel}" ] && out_die "dns set needs a number or Host name. Next: ${APP_NAME} dns list"
            shift
            sshd_dns_apply_set "${_sel}" "$@"
            unset _sel
            ;;
        add)
            sshd_dns_walk_add "$@"
            ;;
        delete|rm)
            _sel="${1-}"
            [ -z "${_sel}" ] && out_die "dns delete needs a number or Host name. Next: ${APP_NAME} dns list"
            sshd_dns_apply_delete "${_sel}"
            unset _sel
            ;;
        unset|clear)
            sshd_dns_apply_unset "$@"
            ;;
        *)
            out_die "Unknown dns action '${_sub}'. Use list, show, edit, set, add, delete, or unset."
            ;;
    esac
    unset _sub
}

# =============================================================================
# sshd_cmd_ssh / sshd_cmd_download — OpenSSH client using this-login Host list
# =============================================================================
#
# GENERAL PURPOSE:
# ssh: pick a concrete Host from ~/.ssh/config and run OpenSSH client ssh
# with that alias (Port/IdentityFile from the stanza apply). TTY asks user
# with default (Host User, else this login). download:
# pick a Host, TTY asks user (same default as ssh), pick or type a remote
# folder, tar.gz on the remote, extract into this login's current directory.
# When this login is the gzip reader and it is Git Bash, the archive is a
# finished file copied with scp, not a stdin stream. Other readers keep
# the stream. Previous folders per Host are stored
# under ${HOME}/.local/${APP_NAME}/download-folders (mode 0600).
#
# ALIGNMENT: requirement-domain-sshd.md · requirement-shell-cli-interface.md
#            requirement-shell-windows-git-bash-cli-coding.md
# Last updated: 2026-10-16
# Lessons: INC-20260912-002 — ~/folder is allowed; remote quote uses "$HOME"
#          (single-quoting the whole ~/path blocks remote tilde). ~ alone
#          and ~user/path stay refused.
# =============================================================================

# Sets SSHD_SSH_USER. MUST run in current shell (do-not-capture-read).
# Default: Host User if set, else this login. Enter keeps default. "" means empty (no -l).
sshd_ssh_walk_user() {
    _su_cur="${1-}"
    _su_login=$(sshd_current_login_user)
    if [ -n "${_su_cur}" ]; then
        _su_def="${_su_cur}"
    else
        _su_def="${_su_login}"
    fi
    SSHD_SSH_USER="${_su_def}"
    if ! sshd_dns_can_prompt; then
        unset _su_cur _su_login _su_def
        return 0
    fi
    out_msg_n "user [${_su_def}]: "
    _su_ans=""
    read -r _su_ans || true
    if [ -z "${_su_ans}" ]; then
        SSHD_SSH_USER="${_su_def}"
    else
        SSHD_SSH_USER=$(sshd_dns_norm "${_su_ans}")
    fi
    unset _su_cur _su_login _su_def _su_ans
}

sshd_ssh_validate_user() {
    _vu="${1-}"
    _vu_next="${2-}"
    if [ -z "${_vu_next}" ]; then
        _vu_next="ssh <n|name>"
    fi
    if [ -z "${_vu}" ]; then
        unset _vu _vu_next
        return 0
    fi
    case "${_vu}" in
        *[!A-Za-z0-9._-]*)
            out_die "user '${_vu}' is not allowed. Use letters, digits, dot, underscore, or hyphen. Next: ${APP_NAME} ${_vu_next}"
            ;;
    esac
    unset _vu _vu_next
}

sshd_download_folders_path() {
    : "${APP_NAME:=sshd-cli}"
    if [ -z "${PERSISTENT_STORAGE_DIR:-}" ]; then
        PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)
        export PERSISTENT_STORAGE_DIR
    fi
    printf '%s' "${PERSISTENT_STORAGE_DIR}/download-folders"
}

sshd_download_folders_list() {
    _df_dns="${1-}"
    _df_path=$(sshd_download_folders_path)
    if [ ! -f "${_df_path}" ] || [ -z "${_df_dns}" ]; then
        unset _df_dns _df_path
        return 0
    fi
    awk -F '\t' -v d="${_df_dns}" '$1==d && $2!="" {print $2}' "${_df_path}"
    unset _df_dns _df_path
}

sshd_download_folders_save() {
    _df_dns="${1-}"
    _df_folder="${2-}"
    if [ -z "${_df_dns}" ] || [ -z "${_df_folder}" ]; then
        unset _df_dns _df_folder
        return 1
    fi
    _df_path=$(sshd_download_folders_path)
    _df_tmp=$(mktemp -t "${APP_NAME}.dlfolders.XXXXXX") || return 1
    printf '%s\t%s\n' "${_df_dns}" "${_df_folder}" > "${_df_tmp}"
    _df_n=1
    if [ -f "${_df_path}" ]; then
        while IFS= read -r _df_line || [ -n "${_df_line}" ]; do
            _df_d="${_df_line%%	*}"
            _df_f="${_df_line#*	}"
            if [ "${_df_d}" = "${_df_dns}" ] && [ "${_df_f}" = "${_df_folder}" ]; then
                continue
            fi
            if [ "${_df_d}" = "${_df_dns}" ]; then
                _df_n=$((_df_n + 1))
                if [ "${_df_n}" -gt 20 ]; then
                    continue
                fi
            fi
            if [ -n "${_df_line}" ]; then
                printf '%s\n' "${_df_line}" >> "${_df_tmp}"
            fi
        done < "${_df_path}"
    fi
    if command -v install >/dev/null 2>&1; then
        if ! install -m 0600 "${_df_tmp}" "${_df_path}"; then
            rm -f "${_df_tmp}"
            unset _df_dns _df_folder _df_path _df_tmp _df_n _df_line _df_d _df_f
            return 1
        fi
    else
        if ! mv "${_df_tmp}" "${_df_path}"; then
            rm -f "${_df_tmp}"
            unset _df_dns _df_folder _df_path _df_tmp _df_n _df_line _df_d _df_f
            return 1
        fi
        chmod 0600 "${_df_path}" 2>/dev/null || true
    fi
    rm -f "${_df_tmp}"
    unset _df_dns _df_folder _df_path _df_tmp _df_n _df_line _df_d _df_f
    return 0
}

sshd_download_norm_folder() {
    _nf="${1-}"
    _nf=$(printf '%s' "${_nf}" | tr -d '\r')
    while [ "${#_nf}" -gt 1 ]; do
        case "${_nf}" in
            */) _nf="${_nf%/}" ;;
            *) break ;;
        esac
    done
    printf '%s' "${_nf}"
    unset _nf
}

# Quote a remote download path for sh. ~/folder becomes "$HOME"/'folder'
# so the ssh user home expands; a fully single-quoted ~/path does not.
sshd_download_remote_quote() {
    _rq="${1-}"
    _rq_rest="${_rq#\~}"
    if [ "${_rq}" != "${_rq_rest}" ]; then
        case "${_rq_rest}" in
            "")
                printf '%s' '"$HOME"'
                ;;
            /*)
                _rq_body="${_rq_rest#/}"
                if [ -z "${_rq_body}" ]; then
                    printf '%s' '"$HOME"'
                else
                    printf '"$HOME"/%s' "$(sshd_sh_quote "${_rq_body}")"
                fi
                unset _rq_body
                ;;
            *)
                sshd_sh_quote "${_rq}"
                ;;
        esac
    else
        sshd_sh_quote "${_rq}"
    fi
    unset _rq _rq_rest
}

sshd_download_validate_folder() {
    _vf="${1-}"
    if [ -z "${_vf}" ]; then
        out_die "download needs a remote folder. Next: ${APP_NAME} download <n|name> /path/on/that-host"
    fi
    case "${_vf}" in
        -*)
            out_die "Remote folder '${_vf}' is not allowed. Use an absolute or relative path, or ~/folder (not ., .., /, or ~ alone). Next: ${APP_NAME} download <n|name> /path/on/that-host"
            ;;
    esac
    _vf_body="${_vf}"
    _vf_rest="${_vf#\~}"
    if [ "${_vf}" != "${_vf_rest}" ]; then
        case "${_vf_rest}" in
            /*)
                _vf_body="${_vf_rest#/}"
                if [ -z "${_vf_body}" ]; then
                    out_die "Remote folder '${_vf}' is not allowed. Use ~/folder for the remote login home (not ~ alone). Next: ${APP_NAME} download <n|name> /path/on/that-host"
                fi
                ;;
            *)
                out_die "Remote folder '${_vf}' is not allowed. Use ~/folder for the remote login home (not ~ alone or ~user). Next: ${APP_NAME} download <n|name> /path/on/that-host"
                ;;
        esac
    fi
    if [ "${_vf}" = "." ] || [ "${_vf}" = ".." ] || [ "${_vf}" = "/" ]; then
        out_die "Remote folder '${_vf}' is not allowed. Use an absolute or relative path, or ~/folder (not ., .., /, or ~ alone). Next: ${APP_NAME} download <n|name> /path/on/that-host"
    fi
    case "${_vf_body}" in
        *';'*|*'|'*|*'&'*|'$'*|'`'*|*"\\"*|*'('*|*')'*|*'<'*|*'>'*|'*'*|'?'*|*'!'*|*'~'*|*'#'*)
            out_die "Remote folder '${_vf}' has a character that is not allowed. Next: ${APP_NAME} download <n|name> /path/on/that-host"
            ;;
    esac
    unset _vf _vf_body _vf_rest
}

# Sets SSHD_DL_FOLDER. MUST run in current shell (do-not-capture-read).
# Out-of-range numbered choice warns and redisplays. Empty still fail-closed.
sshd_download_walk_folder() {
    _dw_dns="$1"
    SSHD_DL_FOLDER=""
    while true; do
        _dw_i=0
        _dw_keys=""
        while IFS= read -r _dw_p || [ -n "${_dw_p}" ]; do
            [ -n "${_dw_p}" ] || continue
            _dw_i=$((_dw_i + 1))
            if [ -z "${_dw_keys}" ]; then
                _dw_keys="${_dw_p}"
            else
                _dw_keys="${_dw_keys}
${_dw_p}"
            fi
            out_plain "${_dw_i}. ${_dw_p}"
        done <<EOF
$(sshd_download_folders_list "${_dw_dns}")
EOF
        if [ "${_dw_i}" -eq 0 ]; then
            out_msg_n "Remote folder to download (absolute, relative, or ~/folder on ${_dw_dns}): "
        else
            out_info "Previous folders for ${_dw_dns}. Choose a number, or type a folder path."
            out_msg_n "Folder: "
        fi
        _dw_pick=""
        read -r _dw_pick || true
        if [ -z "${_dw_pick}" ]; then
            _dw_name="${_dw_dns}"
            unset _dw_dns _dw_i _dw_keys _dw_p _dw_pick
            out_die "download needs a remote folder. Next: ${APP_NAME} download ${_dw_name} /path/on/that-host"
        fi
        _dw_is_num=0
        case "${_dw_pick}" in
            *[!0-9]*) _dw_is_num=0 ;;
            *) _dw_is_num=1 ;;
        esac
        if [ "${_dw_is_num}" -eq 1 ] && [ "${_dw_i}" -gt 0 ]; then
            if [ "${_dw_pick}" -ge 1 ] && [ "${_dw_pick}" -le "${_dw_i}" ]; then
                SSHD_DL_FOLDER=$(printf '%s\n' "${_dw_keys}" | awk -v n="${_dw_pick}" 'NR==n {print; exit}')
                unset _dw_dns _dw_i _dw_keys _dw_p _dw_pick _dw_is_num
                return 0
            fi
            out_warn "Unknown folder choice '${_dw_pick}'. Choose a number from the list, or type a folder path."
            continue
        fi
        SSHD_DL_FOLDER="${_dw_pick}"
        unset _dw_dns _dw_i _dw_keys _dw_p _dw_pick _dw_is_num
        return 0
    done
}

# Return 0 when this Host stanza comments HostKeyAlgorithms or
# PubkeyAcceptedAlgorithms. OpenSSH ignores the comment; ssh must pass -o.
sshd_ssh_host_algo_commented() {
    _hac_host="${1-}"
    _hac_cfg=$(sshd_dns_config_path)
    if [ -z "${_hac_host}" ] || [ ! -r "${_hac_cfg}" ]; then
        unset _hac_host _hac_cfg
        return 1
    fi
    awk -v host="${_hac_host}" '
        function first_pat(rest,    n, a) {
            n=split(rest, a, /[[:space:]]+/)
            if (n < 1) return ""
            return a[1]
        }
        BEGIN { inhost=0; found=0 }
        {
            s=$0
            sub(/\r$/, "", s)
            sub(/^[[:space:]]+/, "", s)
            if (tolower(s) ~ /^host[[:space:]]/) {
                rest=s
                sub(/^[Hh][Oo][Ss][Tt][[:space:]]+/, "", rest)
                if (first_pat(rest) == host) inhost=1
                else inhost=0
                next
            }
            if (tolower(s) ~ /^match[[:space:]]/) { inhost=0; next }
            if (!inhost) next
            if (substr(s,1,1) != "#") next
            sub(/^#+[[:space:]]*/, "", s)
            lk=tolower(s)
            if (lk ~ /^hostkeyalgorithms([[:space:]=]|$)/) found=1
            if (lk ~ /^pubkeyacceptedalgorithms([[:space:]=]|$)/) found=1
            if (lk ~ /^pubkeyacceptedkeytypes([[:space:]=]|$)/) found=1
        }
        END { exit found ? 0 : 1 }
    ' "${_hac_cfg}"
    _hac_ec=$?
    unset _hac_host _hac_cfg
    return "${_hac_ec}"
}

sshd_cmd_ssh() {
    : "${JSON:=0}"
    : "${TTY:=0}"
    : "${QUIET:=0}"
    : "${SSHD_CLI_SSH:=}"
    : "${APP_NAME:=sshd-cli}"
    _sel="${1-}"
    if [ -z "${_sel}" ]; then
        if sshd_dns_can_prompt; then
            if sshd_dns_pick_host "ssh"; then
                _sel="${DNS_PICK_SEL}"
            else
                unset _sel
                return 0
            fi
        else
            out_die "ssh needs a number or Host name. Next: ${APP_NAME} dns list, then ${APP_NAME} ssh <n|name>"
        fi
    fi
    _row=$(sshd_dns_lookup "${_sel}") || out_die "No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list"
    sshd_dns_load_row "${_row}"
    _dns="${DNS_R_DNS}"
    _n="${DNS_R_N}"
    _user=""
    if sshd_dns_can_prompt; then
        sshd_ssh_walk_user "${DNS_R_USER}"
        _user="${SSHD_SSH_USER}"
        sshd_ssh_validate_user "${_user}"
    fi
    _bin=$(sshd_ssh_cmd)
    if [ -z "${_bin}" ] || [ ! -x "${_bin}" ]; then
        out_die "Cannot ssh: OpenSSH client not found. Next: install openssh-client, then ${APP_NAME} ssh ${_dns}"
    fi
    _legacy=0
    if sshd_ssh_host_algo_commented "${_dns}"; then
        _legacy=1
    fi
    _cmd="ssh"
    if [ "${_legacy}" -eq 1 ]; then
        _cmd="${_cmd} -o HostKeyAlgorithms=+ssh-rsa"
    fi
    if [ -n "${_user}" ]; then
        _cmd="${_cmd} -l ${_user}"
    fi
    _cmd="${_cmd} ${_dns}"
    if [ "${JSON}" -eq 1 ]; then
        _json_user="${_user}"
        if [ -z "${_json_user}" ]; then
            _json_user="${DNS_R_USER}"
        fi
        out_json "ssh" "ok" "n" "${_n}" "dns" "${_dns}" "user" "${_json_user}" "command" "${_cmd}"
        unset _sel _row _dns _n _user _bin _cmd _json_user _legacy
        return 0
    fi
    out_info "Connecting to ${_dns} as ${_user:-${DNS_R_USER:-this login}} (OpenSSH client; Host from $(sshd_dns_config_path))"
    if [ -n "${SSHD_CLI_SSH}" ]; then
        if [ "${_legacy}" -eq 1 ] && [ -n "${_user}" ]; then
            if ! "${_bin}" -o HostKeyAlgorithms=+ssh-rsa -l "${_user}" "${_dns}"; then
                out_die "ssh ${_dns} failed. Next: ssh -o HostKeyAlgorithms=+ssh-rsa ${_dns}"
            fi
        elif [ "${_legacy}" -eq 1 ]; then
            if ! "${_bin}" -o HostKeyAlgorithms=+ssh-rsa "${_dns}"; then
                out_die "ssh ${_dns} failed. Next: ssh -o HostKeyAlgorithms=+ssh-rsa ${_dns}"
            fi
        elif [ -n "${_user}" ]; then
            if ! "${_bin}" -l "${_user}" "${_dns}"; then
                out_die "ssh ${_dns} failed. Next: ssh ${_dns}"
            fi
        else
            if ! "${_bin}" "${_dns}"; then
                out_die "ssh ${_dns} failed. Next: ssh ${_dns}"
            fi
        fi
        out_success "ssh ${_dns} complete."
        unset _sel _row _dns _n _user _bin _cmd _legacy
        return 0
    fi
    if [ "${TTY}" -eq 1 ]; then
        if [ "${_legacy}" -eq 1 ] && [ -n "${_user}" ]; then
            exec "${_bin}" -o HostKeyAlgorithms=+ssh-rsa -l "${_user}" "${_dns}"
        elif [ "${_legacy}" -eq 1 ]; then
            exec "${_bin}" -o HostKeyAlgorithms=+ssh-rsa "${_dns}"
        elif [ -n "${_user}" ]; then
            exec "${_bin}" -l "${_user}" "${_dns}"
        else
            exec "${_bin}" "${_dns}"
        fi
        out_die "Could not start ssh ${_dns}. Next: ssh ${_dns}"
    fi
    if [ "${_legacy}" -eq 1 ] && [ -n "${_user}" ]; then
        if ! "${_bin}" -o HostKeyAlgorithms=+ssh-rsa -o BatchMode=yes -o ConnectTimeout=15 -l "${_user}" "${_dns}"; then
            out_die "ssh ${_dns} failed. Next: ssh -o HostKeyAlgorithms=+ssh-rsa ${_dns}"
        fi
    elif [ "${_legacy}" -eq 1 ]; then
        if ! "${_bin}" -o HostKeyAlgorithms=+ssh-rsa -o BatchMode=yes -o ConnectTimeout=15 "${_dns}"; then
            out_die "ssh ${_dns} failed. Next: ssh -o HostKeyAlgorithms=+ssh-rsa ${_dns}"
        fi
    elif [ -n "${_user}" ]; then
        if ! "${_bin}" -o BatchMode=yes -o ConnectTimeout=15 -l "${_user}" "${_dns}"; then
            out_die "ssh ${_dns} failed. Next: ssh ${_dns}"
        fi
    else
        if ! "${_bin}" -o BatchMode=yes -o ConnectTimeout=15 "${_dns}"; then
            out_die "ssh ${_dns} failed. Next: ssh ${_dns}"
        fi
    fi
    unset _sel _row _dns _n _user _bin _cmd _legacy
    return 0
}

# =============================================================================
# sshd_gzip_text_is_msys — probe text names an MSYS2 / Git Bash gzip reader
# =============================================================================
#
# GENERAL PURPOSE:
# The remote probe prints one uname line and one OSTYPE line. This returns 0
# only when uname is MINGW* or MSYS*, or OSTYPE is msys* or mingw*.
# Windows_NT alone is not this reader.
#
# CIAO PRINCIPLES APPLIED:
# - Caution: a failed or empty probe is not treated as MSYS.
# - Intentional: the marker lines are the only match surface.
# - Anti-fragile: peer OS text keeps the streamed pipe.
# - Over-protect: do not match Windows_NT.
#
# ALIGNMENT:
# - requirement-shell-windows-git-bash-cli-coding.md
# - requirement-shell-windows-cmd-cli-coding.md
#
# Last updated: 2026-10-16
# =============================================================================
sshd_gzip_text_is_msys() {
    _gt="${1-}"
    case "${_gt}" in
        *__SSHD_CLI_UNAME__MINGW*|*__SSHD_CLI_UNAME__MSYS*)
            unset _gt
            return 0
            ;;
    esac
    case "${_gt}" in
        *__SSHD_CLI_OSTYPE__msys*|*__SSHD_CLI_OSTYPE__mingw*|*__SSHD_CLI_OSTYPE__MSYS*|*__SSHD_CLI_OSTYPE__MINGW*)
            unset _gt
            return 0
            ;;
    esac
    unset _gt
    return 1
}

# =============================================================================
# sshd_remote_reader_is_msys — ask the remote shell who reads gzip
# =============================================================================
#
# GENERAL PURPOSE:
# One BatchMode ssh prints uname -s and OSTYPE. Return 0 when that text is
# an MSYS2 or Git Bash reader. A non-zero ssh, empty text, or Windows_NT
# returns 1 so the caller keeps the streamed pipe.
#
# ALIGNMENT:
# - requirement-shell-windows-git-bash-cli-coding.md
# - requirement-domain-sshd.md
#
# Last updated: 2026-10-16
# =============================================================================
sshd_remote_reader_is_msys() {
    _pr_bin="${1-}"
    _pr_user="${2-}"
    _pr_dns="${3-}"
    _pr_cmd='printf "%s\n" "__SSHD_CLI_UNAME__$(uname -s 2>/dev/null)" "__SSHD_CLI_OSTYPE__${OSTYPE-}"'
    _pr_out=""
    _pr_rc=0
    if [ -n "${_pr_user}" ]; then
        _pr_out=$("${_pr_bin}" -o BatchMode=yes -o ConnectTimeout=15 -l "${_pr_user}" "${_pr_dns}" "${_pr_cmd}" </dev/null 2>/dev/null) || _pr_rc=$?
    else
        _pr_out=$("${_pr_bin}" -o BatchMode=yes -o ConnectTimeout=15 "${_pr_dns}" "${_pr_cmd}" </dev/null 2>/dev/null) || _pr_rc=$?
    fi
    if [ "${_pr_rc}" -ne 0 ]; then
        unset _pr_bin _pr_user _pr_dns _pr_cmd _pr_out _pr_rc
        return 1
    fi
    if sshd_gzip_text_is_msys "${_pr_out}"; then
        unset _pr_bin _pr_user _pr_dns _pr_cmd _pr_out _pr_rc
        return 0
    fi
    unset _pr_bin _pr_user _pr_dns _pr_cmd _pr_out _pr_rc
    return 1
}

# =============================================================================
# sshd_xfer_new_name — unique archive basename for one transfer
# =============================================================================
#
# GENERAL PURPOSE:
# Mint a dotfile basename that is unique in the destination directory.
# The leaf comes from mktemp. The caller writes the bytes.
#
# ALIGNMENT:
# - requirement-shell-windows-git-bash-cli-coding.md
# - requirement-shell-cli-storage.md
#
# Last updated: 2026-10-16
# =============================================================================
sshd_xfer_new_name() {
    : "${APP_NAME:=sshd-cli}"
    _xn_tmp=$(mktemp -t "${APP_NAME}.xfer.XXXXXX") || return 1
    _xn_leaf=$(basename "${_xn_tmp}")
    rm -f "${_xn_tmp}"
    printf '.%s.tar.gz' "${_xn_leaf}"
    unset _xn_tmp _xn_leaf
}

# =============================================================================
# sshd_xfer_show_err — replay captured remote text, then name gzip or tar
# =============================================================================
#
# GENERAL PURPOSE:
# When gzip or tar has already rejected the archive, the operator line names
# that program. A connection failure that did not say gzip or tar stays an
# ssh failure. Remote text is shown again before the [ERROR] line.
#
# ALIGNMENT:
# - requirement-shell-windows-git-bash-cli-coding.md
# - requirement-shell-output-requirements.md
#
# Last updated: 2026-10-16
# =============================================================================
sshd_xfer_show_err() {
    : "${APP_NAME:=sshd-cli}"
    _xe_kind="${1-}"
    _xe_err="${2-}"
    _xe_dns="${3-}"
    _xe_folder="${4-}"
    _xe_next="${5-}"
    if [ -n "${_xe_err}" ]; then
        printf '%s\n' "${_xe_err}" >&2
    fi
    case "${_xe_err}" in
        *gzip*)
            out_die "Cannot ${_xe_kind}: gzip rejected the archive for ${_xe_folder} on ${_xe_dns}. Next: ${_xe_next}, then ${APP_NAME} ${_xe_kind} ${_xe_dns} ${_xe_folder}"
            ;;
        *tar:*)
            out_die "Cannot ${_xe_kind}: tar rejected the archive for ${_xe_folder} on ${_xe_dns}. Next: ${_xe_next}, then ${APP_NAME} ${_xe_kind} ${_xe_dns} ${_xe_folder}"
            ;;
        *)
            out_die "Cannot ${_xe_kind}: ssh ${_xe_dns} failed. Next: ${_xe_next}, then ${APP_NAME} ${_xe_kind} ${_xe_dns} ${_xe_folder}"
            ;;
    esac
}

# =============================================================================
# sshd_xfer_ssh — one BatchMode ssh with an optional -l user
# =============================================================================
#
# GENERAL PURPOSE:
# Run one remote command. The caller passes the command as one argument so
# "$HOME" stays for the remote shell.
#
# ALIGNMENT:
# - requirement-domain-sshd.md
#
# Last updated: 2026-10-16
# =============================================================================
sshd_xfer_ssh() {
    _xs_bin="${1-}"
    _xs_user="${2-}"
    _xs_dns="${3-}"
    _xs_cmd="${4-}"
    if [ -n "${_xs_user}" ]; then
        "${_xs_bin}" -o BatchMode=yes -o ConnectTimeout=15 -l "${_xs_user}" "${_xs_dns}" "${_xs_cmd}" </dev/null
        _xs_rc=$?
    else
        "${_xs_bin}" -o BatchMode=yes -o ConnectTimeout=15 "${_xs_dns}" "${_xs_cmd}" </dev/null
        _xs_rc=$?
    fi
    unset _xs_bin _xs_user _xs_dns _xs_cmd
    return ${_xs_rc}
}

# =============================================================================
# sshd_xfer_scp_to — copy a finished archive with scp (not a shell pipe)
# =============================================================================
#
# GENERAL PURPOSE:
# Put or get one file. Direction is "put" (local path, then remote spec) or
# "get" (remote spec, then local path). scp is not cat-into-ssh.
#
# ALIGNMENT:
# - requirement-shell-windows-git-bash-cli-coding.md
#
# Last updated: 2026-10-16
# =============================================================================
sshd_xfer_scp() {
    _xp_scp="${1-}"
    _xp_src="${2-}"
    _xp_dst="${3-}"
    "${_xp_scp}" -o BatchMode=yes -o ConnectTimeout=15 "${_xp_src}" "${_xp_dst}"
    _xp_rc=$?
    unset _xp_scp _xp_src _xp_dst
    return ${_xp_rc}
}

# =============================================================================
# sshd_upload_msys_file — finished archive, scp, file extract, remove
# =============================================================================
#
# GENERAL PURPOSE:
# The remote reader is MSYS2 or Git Bash. Build tar.gz here, prove it with
# gzip -t, copy the file with scp, extract that file under the remote
# "$HOME", then remove the archive. Do not pipe gzip into that reader.
#
# ALIGNMENT:
# - requirement-shell-windows-git-bash-cli-coding.md
# - requirement-domain-sshd.md
#
# Last updated: 2026-10-16
# =============================================================================
sshd_upload_msys_file() {
    : "${APP_NAME:=sshd-cli}"
    _um_scp=$(sshd_scp_cmd)
    if [ -z "${_um_scp}" ] || [ ! -x "${_um_scp}" ]; then
        out_die "Cannot upload: scp not found. Next: install openssh-client, then ${APP_NAME} upload ${_dns} ${_folder}"
    fi
    if ! command -v gzip >/dev/null 2>&1; then
        out_die "Cannot upload: gzip not found. Next: install gzip, then ${APP_NAME} upload ${_dns} ${_folder}"
    fi
    _um_stage=$(mktemp -d -t "${APP_NAME}.upload.XXXXXX") || out_die "Cannot upload: could not create a temp folder for the archive. Next: ${APP_NAME} upload ${_dns} ${_folder}"
    chmod 0700 "${_um_stage}" || true
    if [ ! -d "${_um_stage}" ] || [ ! -w "${_um_stage}" ] || [ ! -x "${_um_stage}" ]; then
        rm -rf "${_um_stage}"
        out_die "Cannot upload: the temp folder for the archive is not usable. Next: ${APP_NAME} upload ${_dns} ${_folder}"
    fi
    _um_name=$(sshd_xfer_new_name) || true
    if [ -z "${_um_name}" ]; then
        rm -rf "${_um_stage}"
        out_die "Cannot upload: could not name the archive. Next: ${APP_NAME} upload ${_dns} ${_folder}"
    fi
    _um_path="${_um_stage}/${_um_name}"
    if ! tar czf "${_um_path}" -C "${_dir}" "${_base}"; then
        rm -rf "${_um_stage}"
        out_die "Cannot upload: tar could not build the archive for ${_folder}. Next: ${_next_ssh}, then ${APP_NAME} upload ${_dns} ${_folder}"
    fi
    if ! gzip -t "${_um_path}"; then
        rm -rf "${_um_stage}"
        out_die "Cannot upload: gzip rejected the archive for ${_folder}. Next: ${_next_ssh}, then ${APP_NAME} upload ${_dns} ${_folder}"
    fi
    if [ -n "${_user}" ]; then
        _um_remote="${_user}@${_dns}:${_um_name}"
    else
        _um_remote="${_dns}:${_um_name}"
    fi
    if ! sshd_xfer_scp "${_um_scp}" "${_um_path}" "${_um_remote}"; then
        rm -rf "${_um_stage}"
        out_die "Cannot upload: scp could not copy the archive to ${_dns}. Next: ${_next_ssh}, then ${APP_NAME} upload ${_dns} ${_folder}"
    fi
    rm -rf "${_um_stage}"
    _um_q=$(sshd_sh_quote "${_um_name}")
    _um_cmd="tar xzf \"\$HOME\"/${_um_q} -C \"\$HOME\" && rm -f \"\$HOME\"/${_um_q}"
    _um_errf=$(mktemp -t "${APP_NAME}.uploaderr.XXXXXX") || _um_errf=""
    _um_rc=0
    if [ -n "${_um_errf}" ]; then
        if ! sshd_xfer_ssh "${_bin}" "${_user}" "${_dns}" "${_um_cmd}" 2>"${_um_errf}"; then
            _um_rc=1
        fi
        _um_err=$(cat "${_um_errf}" 2>/dev/null || true)
        rm -f "${_um_errf}"
    else
        if ! sshd_xfer_ssh "${_bin}" "${_user}" "${_dns}" "${_um_cmd}"; then
            _um_rc=1
        fi
        _um_err=""
    fi
    if [ "${_um_rc}" -ne 0 ]; then
        _um_rm="rm -f \"\$HOME\"/${_um_q}"
        sshd_xfer_ssh "${_bin}" "${_user}" "${_dns}" "${_um_rm}" >/dev/null 2>&1 || true
        sshd_xfer_show_err "upload" "${_um_err}" "${_dns}" "${_folder}" "${_next_ssh}"
    fi
    unset _um_scp _um_stage _um_name _um_path _um_remote _um_q _um_cmd _um_errf _um_rc _um_err _um_rm
    return 0
}

# =============================================================================
# sshd_download_msys_file — remote finished archive, scp, local file extract
# =============================================================================
#
# GENERAL PURPOSE:
# This login is the gzip reader and it is MSYS2 or Git Bash. The remote
# side finishes tar czf to a file and gzip -t. scp copies that file here.
# Local tar xzf names the file. Both copies of the archive are removed.
#
# ALIGNMENT:
# - requirement-shell-windows-git-bash-cli-coding.md
# - requirement-domain-sshd.md
#
# Last updated: 2026-10-16
# =============================================================================
sshd_download_msys_file() {
    : "${APP_NAME:=sshd-cli}"
    _dm_scp=$(sshd_scp_cmd)
    if [ -z "${_dm_scp}" ] || [ ! -x "${_dm_scp}" ]; then
        out_die "Cannot download: scp not found. Next: install openssh-client, then ${APP_NAME} download ${_dns} ${_folder}"
    fi
    if ! command -v gzip >/dev/null 2>&1; then
        out_die "Cannot download: gzip not found. Next: install gzip, then ${APP_NAME} download ${_dns} ${_folder}"
    fi
    _dm_name=$(sshd_xfer_new_name) || out_die "Cannot download: could not name the archive. Next: ${APP_NAME} download ${_dns} ${_folder}"
    _dm_q=$(sshd_sh_quote "${_dm_name}")
    _dm_build="test -d ${_qpath} && tar czf \"\$HOME\"/${_dm_q} -C ${_qdir} ${_qbase} && gzip -t \"\$HOME\"/${_dm_q}"
    _dm_errf=$(mktemp -t "${APP_NAME}.downloaderr.XXXXXX") || _dm_errf=""
    _dm_rc=0
    if [ -n "${_dm_errf}" ]; then
        if ! sshd_xfer_ssh "${_bin}" "${_user}" "${_dns}" "${_dm_build}" 2>"${_dm_errf}"; then
            _dm_rc=1
        fi
        _dm_err=$(cat "${_dm_errf}" 2>/dev/null || true)
        rm -f "${_dm_errf}"
    else
        if ! sshd_xfer_ssh "${_bin}" "${_user}" "${_dns}" "${_dm_build}"; then
            _dm_rc=1
        fi
        _dm_err=""
    fi
    if [ "${_dm_rc}" -ne 0 ]; then
        _dm_rm="rm -f \"\$HOME\"/${_dm_q}"
        sshd_xfer_ssh "${_bin}" "${_user}" "${_dns}" "${_dm_rm}" >/dev/null 2>&1 || true
        sshd_xfer_show_err "download" "${_dm_err}" "${_dns}" "${_folder}" "${_next_ssh}"
    fi
    _dm_stage=$(mktemp -d -t "${APP_NAME}.download.XXXXXX") || out_die "Cannot download: could not create a temp folder for the archive. Next: ${APP_NAME} download ${_dns} ${_folder}"
    chmod 0700 "${_dm_stage}" || true
    if [ ! -d "${_dm_stage}" ] || [ ! -w "${_dm_stage}" ] || [ ! -x "${_dm_stage}" ]; then
        rm -rf "${_dm_stage}"
        out_die "Cannot download: the temp folder for the archive is not usable. Next: ${APP_NAME} download ${_dns} ${_folder}"
    fi
    _dm_path="${_dm_stage}/${_dm_name}"
    if [ -n "${_user}" ]; then
        _dm_remote="${_user}@${_dns}:${_dm_name}"
    else
        _dm_remote="${_dns}:${_dm_name}"
    fi
    if ! sshd_xfer_scp "${_dm_scp}" "${_dm_remote}" "${_dm_path}"; then
        _dm_rm="rm -f \"\$HOME\"/${_dm_q}"
        sshd_xfer_ssh "${_bin}" "${_user}" "${_dns}" "${_dm_rm}" >/dev/null 2>&1 || true
        rm -rf "${_dm_stage}"
        out_die "Cannot download: scp could not copy the archive from ${_dns}. Next: ${_next_ssh}, then ${APP_NAME} download ${_dns} ${_folder}"
    fi
    if ! gzip -t "${_dm_path}"; then
        _dm_rm="rm -f \"\$HOME\"/${_dm_q}"
        sshd_xfer_ssh "${_bin}" "${_user}" "${_dns}" "${_dm_rm}" >/dev/null 2>&1 || true
        rm -rf "${_dm_stage}"
        out_die "Cannot download: gzip rejected the archive from ${_dns}. Next: ${_next_ssh}, then ${APP_NAME} download ${_dns} ${_folder}"
    fi
    if ! tar xzf "${_dm_path}" -C "${_cwd}"; then
        _dm_rm="rm -f \"\$HOME\"/${_dm_q}"
        sshd_xfer_ssh "${_bin}" "${_user}" "${_dns}" "${_dm_rm}" >/dev/null 2>&1 || true
        rm -rf "${_dm_stage}"
        out_die "Cannot download: tar could not extract the archive into ${_cwd}. Next: ${_next_ssh}, then ${APP_NAME} download ${_dns} ${_folder}"
    fi
    rm -rf "${_dm_stage}"
    _dm_rm="rm -f \"\$HOME\"/${_dm_q}"
    sshd_xfer_ssh "${_bin}" "${_user}" "${_dns}" "${_dm_rm}" >/dev/null 2>&1 || true
    unset _dm_scp _dm_name _dm_q _dm_build _dm_errf _dm_rc _dm_err _dm_rm _dm_stage _dm_path _dm_remote
    return 0
}

sshd_cmd_download() {
    : "${JSON:=0}"
    : "${TTY:=0}"
    : "${QUIET:=0}"
    : "${SSHD_CLI_SSH:=}"
    : "${APP_NAME:=sshd-cli}"
    _sel="${1-}"
    _folder="${2-}"
    if [ -z "${_sel}" ]; then
        if sshd_dns_can_prompt; then
            if sshd_dns_pick_host "download"; then
                _sel="${DNS_PICK_SEL}"
            else
                unset _sel _folder
                return 0
            fi
        else
            out_die "download needs a number or Host name and a remote folder. Next: ${APP_NAME} dns list, then ${APP_NAME} download <n|name> /path/on/that-host"
        fi
    fi
    _row=$(sshd_dns_lookup "${_sel}") || out_die "No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list"
    sshd_dns_load_row "${_row}"
    _dns="${DNS_R_DNS}"
    _n="${DNS_R_N}"
    _user=""
    if sshd_dns_can_prompt; then
        sshd_ssh_walk_user "${DNS_R_USER}"
        _user="${SSHD_SSH_USER}"
        sshd_ssh_validate_user "${_user}" "download <n|name> /path/on/that-host"
    fi
    if [ -z "${_folder}" ]; then
        if sshd_dns_can_prompt; then
            sshd_download_walk_folder "${_dns}"
            _folder="${SSHD_DL_FOLDER}"
        else
            out_die "download needs a remote folder. Next: ${APP_NAME} download ${_dns} /path/on/that-host"
        fi
    fi
    _folder=$(sshd_download_norm_folder "${_folder}")
    sshd_download_validate_folder "${_folder}"
    _base=$(basename "${_folder}")
    _dir=$(dirname "${_folder}")
    if [ -z "${_base}" ] || [ "${_base}" = "/" ] || [ "${_base}" = "." ] || [ "${_base}" = ".." ]; then
        out_die "Remote folder '${_folder}' is not allowed. Next: ${APP_NAME} download ${_dns} /path/on/that-host"
    fi
    _bin=$(sshd_ssh_cmd)
    if [ -z "${_bin}" ] || [ ! -x "${_bin}" ]; then
        out_die "Cannot download: OpenSSH client not found. Next: install openssh-client, then ${APP_NAME} download ${_dns} ${_folder}"
    fi
    if ! command -v tar >/dev/null 2>&1; then
        out_die "Cannot download: tar not found. Next: install tar, then ${APP_NAME} download ${_dns} ${_folder}"
    fi
    _qpath=$(sshd_download_remote_quote "${_folder}")
    _qdir=$(sshd_download_remote_quote "${_dir}")
    _qbase=$(sshd_sh_quote "${_base}")
    _cwd=$(pwd)
    if [ -n "${_user}" ]; then
        _next_ssh="ssh -l ${_user} ${_dns}"
    else
        _next_ssh="ssh ${_dns}"
    fi
    out_info "Downloading ${_folder} from ${_dns} as ${_user:-${DNS_R_USER:-this login}} into ${_cwd}"
    if sshd_is_git_bash; then
        sshd_download_msys_file
    else
        _remote_cmd="test -d ${_qpath} && tar czf - -C ${_qdir} ${_qbase}"
        _tmp=$(mktemp -t "${APP_NAME}.download.XXXXXX") || out_die "Could not create a temp file for download."
        _dl_errf=$(mktemp -t "${APP_NAME}.downloaderr.XXXXXX") || _dl_errf=""
        _dl_rc=0
        if [ -n "${_user}" ]; then
            if [ -n "${_dl_errf}" ]; then
                if ! "${_bin}" -o BatchMode=yes -o ConnectTimeout=15 -l "${_user}" "${_dns}" "${_remote_cmd}" > "${_tmp}" 2>"${_dl_errf}"; then
                    _dl_rc=1
                fi
            else
                if ! "${_bin}" -o BatchMode=yes -o ConnectTimeout=15 -l "${_user}" "${_dns}" "${_remote_cmd}" > "${_tmp}"; then
                    _dl_rc=1
                fi
            fi
        else
            if [ -n "${_dl_errf}" ]; then
                if ! "${_bin}" -o BatchMode=yes -o ConnectTimeout=15 "${_dns}" "${_remote_cmd}" > "${_tmp}" 2>"${_dl_errf}"; then
                    _dl_rc=1
                fi
            else
                if ! "${_bin}" -o BatchMode=yes -o ConnectTimeout=15 "${_dns}" "${_remote_cmd}" > "${_tmp}"; then
                    _dl_rc=1
                fi
            fi
        fi
        _dl_err=""
        if [ -n "${_dl_errf}" ]; then
            _dl_err=$(cat "${_dl_errf}" 2>/dev/null || true)
            rm -f "${_dl_errf}"
        fi
        if [ "${_dl_rc}" -ne 0 ]; then
            rm -f "${_tmp}"
            sshd_xfer_show_err "download" "${_dl_err}" "${_dns}" "${_folder}" "${_next_ssh}"
        fi
        if [ -n "${_dl_err}" ]; then
            # remote program text, not a product message
            printf '%s\n' "${_dl_err}" >&2
        fi
        if [ ! -s "${_tmp}" ]; then
            rm -f "${_tmp}"
            out_die "Cannot download: remote ${_dns} returned an empty archive for ${_folder}. Next: ssh ${_dns} and check that folder exists"
        fi
        if ! tar xzf "${_tmp}" -C "${_cwd}"; then
            rm -f "${_tmp}"
            out_die "Cannot download: tar could not extract the archive into ${_cwd}. Next: check this folder is writable, then ${APP_NAME} download ${_dns} ${_folder}"
        fi
        rm -f "${_tmp}"
    fi
    sshd_download_folders_save "${_dns}" "${_folder}" || true
    if [ "${JSON}" -eq 1 ]; then
        _json_user="${_user}"
        if [ -z "${_json_user}" ]; then
            _json_user="${DNS_R_USER}"
        fi
        out_json "download" "ok" "n" "${_n}" "dns" "${_dns}" "user" "${_json_user}" "folder" "${_folder}" "destination" "${_cwd}/${_base}"
    else
        out_success "Downloaded ${_folder} from ${_dns} into ${_cwd}/${_base}"
    fi
    unset _sel _folder _row _dns _n _user _base _dir _bin _qpath _qdir _qbase _remote_cmd _cwd _tmp _json_user _next_ssh _dl_errf _dl_rc _dl_err
    return 0
}

# =============================================================================
# sshd_cmd_upload — local folder tar.gz onto a Host (extract under remote home)
# =============================================================================
#
# Inverse of download. Host pick + TTY user [default] (same as ssh).
# Folder is local (this login). ~/folder expands against this login HOME for
# tar only. Remote dest is "$HOME" for the ssh user — not this login HOME.
# Memory: ${HOME}/.local/${APP_NAME}/upload-folders (mode 0600), not download-folders.
#
# When the remote gzip reader is MSYS2 or Git Bash, the archive is a finished
# file copied with scp. Other readers keep the stdin stream.
#
# ALIGNMENT: requirement-domain-sshd.md · requirement-shell-cli-interface.md
#            requirement-shell-interactive-vs-noninteractive.md
#            requirement-shell-windows-git-bash-cli-coding.md
# Last updated: 2026-10-16
# =============================================================================

sshd_upload_folders_path() {
    : "${APP_NAME:=sshd-cli}"
    if [ -z "${PERSISTENT_STORAGE_DIR:-}" ]; then
        PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)
        export PERSISTENT_STORAGE_DIR
    fi
    printf '%s' "${PERSISTENT_STORAGE_DIR}/upload-folders"
}

sshd_upload_folders_list() {
    _uf_dns="${1-}"
    _uf_path=$(sshd_upload_folders_path)
    if [ ! -f "${_uf_path}" ] || [ -z "${_uf_dns}" ]; then
        unset _uf_dns _uf_path
        return 0
    fi
    awk -F '\t' -v d="${_uf_dns}" '$1==d && $2!="" {print $2}' "${_uf_path}"
    unset _uf_dns _uf_path
}

sshd_upload_folders_save() {
    _uf_dns="${1-}"
    _uf_folder="${2-}"
    if [ -z "${_uf_dns}" ] || [ -z "${_uf_folder}" ]; then
        unset _uf_dns _uf_folder
        return 1
    fi
    _uf_path=$(sshd_upload_folders_path)
    _uf_tmp=$(mktemp -t "${APP_NAME}.ulfolders.XXXXXX") || return 1
    printf '%s\t%s\n' "${_uf_dns}" "${_uf_folder}" > "${_uf_tmp}"
    _uf_n=1
    if [ -f "${_uf_path}" ]; then
        while IFS= read -r _uf_line || [ -n "${_uf_line}" ]; do
            _uf_d="${_uf_line%%	*}"
            _uf_f="${_uf_line#*	}"
            if [ "${_uf_d}" = "${_uf_dns}" ] && [ "${_uf_f}" = "${_uf_folder}" ]; then
                continue
            fi
            if [ "${_uf_d}" = "${_uf_dns}" ]; then
                _uf_n=$((_uf_n + 1))
                if [ "${_uf_n}" -gt 20 ]; then
                    continue
                fi
            fi
            if [ -n "${_uf_line}" ]; then
                printf '%s\n' "${_uf_line}" >> "${_uf_tmp}"
            fi
        done < "${_uf_path}"
    fi
    if command -v install >/dev/null 2>&1; then
        if ! install -m 0600 "${_uf_tmp}" "${_uf_path}"; then
            rm -f "${_uf_tmp}"
            unset _uf_dns _uf_folder _uf_path _uf_tmp _uf_n _uf_line _uf_d _uf_f
            return 1
        fi
    else
        if ! mv "${_uf_tmp}" "${_uf_path}"; then
            rm -f "${_uf_tmp}"
            unset _uf_dns _uf_folder _uf_path _uf_tmp _uf_n _uf_line _uf_d _uf_f
            return 1
        fi
        chmod 0600 "${_uf_path}" 2>/dev/null || true
    fi
    rm -f "${_uf_tmp}"
    unset _uf_dns _uf_folder _uf_path _uf_tmp _uf_n _uf_line _uf_d _uf_f
    return 0
}

sshd_upload_norm_folder() {
    _nf="${1-}"
    _nf=$(printf '%s' "${_nf}" | tr -d '\r')
    while [ "${#_nf}" -gt 1 ]; do
        case "${_nf}" in
            */) _nf="${_nf%/}" ;;
            *) break ;;
        esac
    done
    printf '%s' "${_nf}"
    unset _nf
}

# ~/folder → this login HOME/folder for local tar. Other paths unchanged.
sshd_upload_local_path() {
    : "${HOME:=/tmp}"
    _up="${1-}"
    _up_rest="${_up#\~}"
    if [ "${_up}" != "${_up_rest}" ]; then
        case "${_up_rest}" in
            /*)
                printf '%s' "${HOME}/${_up_rest#/}"
                ;;
            *)
                printf '%s' "${_up}"
                ;;
        esac
    else
        printf '%s' "${_up}"
    fi
    unset _up _up_rest
}

sshd_upload_validate_folder() {
    _vf="${1-}"
    if [ -z "${_vf}" ]; then
        out_die "upload needs a local folder. Next: ${APP_NAME} upload <n|name> ./folder"
    fi
    case "${_vf}" in
        -*)
            out_die "Local folder '${_vf}' is not allowed. Use an absolute or relative path, or ~/folder (not ., .., /, or ~ alone). Next: ${APP_NAME} upload <n|name> ./folder"
            ;;
    esac
    _vf_body="${_vf}"
    _vf_rest="${_vf#\~}"
    if [ "${_vf}" != "${_vf_rest}" ]; then
        case "${_vf_rest}" in
            /*)
                _vf_body="${_vf_rest#/}"
                if [ -z "${_vf_body}" ]; then
                    out_die "Local folder '${_vf}' is not allowed. Use ~/folder for this login home (not ~ alone). Next: ${APP_NAME} upload <n|name> ./folder"
                fi
                ;;
            *)
                out_die "Local folder '${_vf}' is not allowed. Use ~/folder for this login home (not ~ alone or ~user). Next: ${APP_NAME} upload <n|name> ./folder"
                ;;
        esac
    fi
    if [ "${_vf}" = "." ] || [ "${_vf}" = ".." ] || [ "${_vf}" = "/" ]; then
        out_die "Local folder '${_vf}' is not allowed. Use an absolute or relative path, or ~/folder (not ., .., /, or ~ alone). Next: ${APP_NAME} upload <n|name> ./folder"
    fi
    case "${_vf_body}" in
        *';'*|*'|'*|*'&'*|'$'*|'`'*|*"\\"*|*'('*|*')'*|*'<'*|*'>'*|'*'*|'?'*|*'!'*|*'~'*|*'#'*)
            out_die "Local folder '${_vf}' has a character that is not allowed. Next: ${APP_NAME} upload <n|name> ./folder"
            ;;
    esac
    unset _vf _vf_body _vf_rest
}

# Sets SSHD_UL_FOLDER. MUST run in current shell (do-not-capture-read).
sshd_upload_walk_folder() {
    _uw_dns="$1"
    SSHD_UL_FOLDER=""
    while true; do
        _uw_i=0
        _uw_keys=""
        while IFS= read -r _uw_p || [ -n "${_uw_p}" ]; do
            [ -n "${_uw_p}" ] || continue
            _uw_i=$((_uw_i + 1))
            if [ -z "${_uw_keys}" ]; then
                _uw_keys="${_uw_p}"
            else
                _uw_keys="${_uw_keys}
${_uw_p}"
            fi
            out_plain "${_uw_i}. ${_uw_p}"
        done <<EOF
$(sshd_upload_folders_list "${_uw_dns}")
EOF
        if [ "${_uw_i}" -eq 0 ]; then
            out_msg_n "Local folder to upload (absolute, relative, or ~/folder on this login): "
        else
            out_info "Previous local folders for ${_uw_dns}. Choose a number, or type a folder path."
            out_msg_n "Folder: "
        fi
        _uw_pick=""
        read -r _uw_pick || true
        if [ -z "${_uw_pick}" ]; then
            _uw_name="${_uw_dns}"
            unset _uw_dns _uw_i _uw_keys _uw_p _uw_pick
            out_die "upload needs a local folder. Next: ${APP_NAME} upload ${_uw_name} ./folder"
        fi
        _uw_is_num=0
        case "${_uw_pick}" in
            *[!0-9]*) _uw_is_num=0 ;;
            *) _uw_is_num=1 ;;
        esac
        if [ "${_uw_is_num}" -eq 1 ] && [ "${_uw_i}" -gt 0 ]; then
            if [ "${_uw_pick}" -ge 1 ] && [ "${_uw_pick}" -le "${_uw_i}" ]; then
                SSHD_UL_FOLDER=$(printf '%s\n' "${_uw_keys}" | awk -v n="${_uw_pick}" 'NR==n {print; exit}')
                unset _uw_dns _uw_i _uw_keys _uw_p _uw_pick _uw_is_num
                return 0
            fi
            out_warn "Unknown folder choice '${_uw_pick}'. Choose a number from the list, or type a folder path."
            continue
        fi
        SSHD_UL_FOLDER="${_uw_pick}"
        unset _uw_dns _uw_i _uw_keys _uw_p _uw_pick _uw_is_num
        return 0
    done
}

sshd_cmd_upload() {
    : "${JSON:=0}"
    : "${TTY:=0}"
    : "${QUIET:=0}"
    : "${SSHD_CLI_SSH:=}"
    : "${APP_NAME:=sshd-cli}"
    : "${HOME:=/tmp}"
    _sel="${1-}"
    _folder="${2-}"
    if [ -z "${_sel}" ]; then
        if sshd_dns_can_prompt; then
            if sshd_dns_pick_host "upload"; then
                _sel="${DNS_PICK_SEL}"
            else
                unset _sel _folder
                return 0
            fi
        else
            out_die "upload needs a number or Host name and a local folder. Next: ${APP_NAME} dns list, then ${APP_NAME} upload <n|name> ./folder"
        fi
    fi
    _row=$(sshd_dns_lookup "${_sel}") || out_die "No Host entry '${_sel}' in $(sshd_dns_config_path). Next: ${APP_NAME} dns list"
    sshd_dns_load_row "${_row}"
    _dns="${DNS_R_DNS}"
    _n="${DNS_R_N}"
    _user=""
    if sshd_dns_can_prompt; then
        sshd_ssh_walk_user "${DNS_R_USER}"
        _user="${SSHD_SSH_USER}"
        sshd_ssh_validate_user "${_user}" "upload <n|name> ./folder"
    fi
    if [ -z "${_folder}" ]; then
        if sshd_dns_can_prompt; then
            sshd_upload_walk_folder "${_dns}"
            _folder="${SSHD_UL_FOLDER}"
        else
            out_die "upload needs a local folder. Next: ${APP_NAME} upload ${_dns} ./folder"
        fi
    fi
    _folder=$(sshd_upload_norm_folder "${_folder}")
    sshd_upload_validate_folder "${_folder}"
    _local=$(sshd_upload_local_path "${_folder}")
    if [ ! -d "${_local}" ]; then
        out_die "Local folder '${_folder}' is not a directory. Next: ${APP_NAME} upload ${_dns} ./folder"
    fi
    _base=$(basename "${_local}")
    _dir=$(dirname "${_local}")
    if [ -z "${_base}" ] || [ "${_base}" = "/" ] || [ "${_base}" = "." ] || [ "${_base}" = ".." ]; then
        out_die "Local folder '${_folder}' is not allowed. Next: ${APP_NAME} upload ${_dns} ./folder"
    fi
    _bin=$(sshd_ssh_cmd)
    if [ -z "${_bin}" ] || [ ! -x "${_bin}" ]; then
        out_die "Cannot upload: OpenSSH client not found. Next: install openssh-client, then ${APP_NAME} upload ${_dns} ${_folder}"
    fi
    if ! command -v tar >/dev/null 2>&1; then
        out_die "Cannot upload: tar not found. Next: install tar, then ${APP_NAME} upload ${_dns} ${_folder}"
    fi
    _dest="\$HOME/${_base}"
    if [ -n "${_user}" ]; then
        _next_ssh="ssh -l ${_user} ${_dns}"
    else
        _next_ssh="ssh ${_dns}"
    fi
    out_info "Uploading ${_folder} to ${_dns} as ${_user:-${DNS_R_USER:-this login}} (extract under that ssh user home as ${_base})"
    if sshd_remote_reader_is_msys "${_bin}" "${_user}" "${_dns}"; then
        sshd_upload_msys_file
    else
        _remote_cmd='tar xzf - -C "$HOME"'
        _up_errf=$(mktemp -t "${APP_NAME}.uploaderr.XXXXXX") || _up_errf=""
        _up_rc=0
        if [ -n "${_user}" ]; then
            if [ -n "${_up_errf}" ]; then
                if ! { tar czf - -C "${_dir}" "${_base}" | "${_bin}" -o BatchMode=yes -o ConnectTimeout=15 -l "${_user}" "${_dns}" "${_remote_cmd}"; } 2>"${_up_errf}"; then
                    _up_rc=1
                fi
            else
                if ! tar czf - -C "${_dir}" "${_base}" | "${_bin}" -o BatchMode=yes -o ConnectTimeout=15 -l "${_user}" "${_dns}" "${_remote_cmd}"; then
                    _up_rc=1
                fi
            fi
        else
            if [ -n "${_up_errf}" ]; then
                if ! { tar czf - -C "${_dir}" "${_base}" | "${_bin}" -o BatchMode=yes -o ConnectTimeout=15 "${_dns}" "${_remote_cmd}"; } 2>"${_up_errf}"; then
                    _up_rc=1
                fi
            else
                if ! tar czf - -C "${_dir}" "${_base}" | "${_bin}" -o BatchMode=yes -o ConnectTimeout=15 "${_dns}" "${_remote_cmd}"; then
                    _up_rc=1
                fi
            fi
        fi
        _up_err=""
        if [ -n "${_up_errf}" ]; then
            _up_err=$(cat "${_up_errf}" 2>/dev/null || true)
            rm -f "${_up_errf}"
        fi
        if [ "${_up_rc}" -ne 0 ]; then
            sshd_xfer_show_err "upload" "${_up_err}" "${_dns}" "${_folder}" "${_next_ssh}"
        fi
        if [ -n "${_up_err}" ]; then
            # remote program text, not a product message
            printf '%s\n' "${_up_err}" >&2
        fi
    fi
    sshd_upload_folders_save "${_dns}" "${_folder}" || true
    if [ "${JSON}" -eq 1 ]; then
        _json_user="${_user}"
        if [ -z "${_json_user}" ]; then
            _json_user="${DNS_R_USER}"
        fi
        out_json "upload" "ok" "n" "${_n}" "dns" "${_dns}" "user" "${_json_user}" "folder" "${_folder}" "destination" "${_dest}"
    else
        out_success "Uploaded ${_folder} to ${_dns} (extract under that ssh user home as ${_base})"
    fi
    unset _sel _folder _row _dns _n _user _local _base _dir _bin _remote_cmd _dest _json_user _next_ssh _up_errf _up_rc _up_err
    return 0
}

# Last updated: 2026-09-16
# ALIGNMENT: requirement-shell-cli-default-interaction
# Return 0 if ${_choice} was a typed leaf. Submenu callers then return to the
# front board; the front board continues its loop. TTY typed `version` runs
# about (INC-20260914-001). Argv `version` stays app_version.
sshd_menu_typed_leaf() {
    case "${_choice}" in
        status) sshd_cmd_status; return 0 ;;
        start) sshd_cmd_start; return 0 ;;
        stop) sshd_cmd_stop; return 0 ;;
        restart) sshd_cmd_restart; return 0 ;;
        dns) sshd_cmd_dns; return 0 ;;
        ssh) sshd_cmd_ssh; return 0 ;;
        download) sshd_cmd_download; return 0 ;;
        upload) sshd_cmd_upload; return 0 ;;
        backup-config) sshd_cmd_backup_config; return 0 ;;
        sync-config) sshd_cmd_sync_config; return 0 ;;
        sudoers) sshd_cmd_sudoers_menu; return 0 ;;
        sync-from-remote) sshd_cmd_sync_from_remote; return 0 ;;
        generate-sudoer-request) sshd_cmd_generate_sudoer_request; return 0 ;;
        submit-sudoer-request) sshd_cmd_submit_sudoer_request; return 0 ;;
        print-sudoers) sshd_cmd_print_sudoers; return 0 ;;
        print-sudoers-install-script) sshd_cmd_print_sudoers_install_script; return 0 ;;
        remove-project-sudoers) sshd_cmd_remove_project_sudoers; return 0 ;;
        port) sshd_cmd_port; return 0 ;;
        config) sshd_cmd_config; return 0 ;;
        host-keys) sshd_cmd_host_keys list; return 0 ;;
        auth-keys) sshd_cmd_auth_keys list; return 0 ;;
        wake-lock) sshd_cmd_wake_lock; return 0 ;;
        wake-unlock) sshd_cmd_wake_unlock; return 0 ;;
        install) inst_perform_install; return 0 ;;
        self-install) inst_self_install; return 0 ;;
        version) app_about; return 0 ;;
        about) app_about; return 0 ;;
        version-check) ver_check; return 0 ;;
        self-update) inst_self_update; return 0 ;;
        self-uninstall) inst_self_uninstall; return 0 ;;
        *) return 1 ;;
    esac
}

# Last updated: 2026-09-28
# ALIGNMENT: requirement-shell-cli-language.md · requirement-shell-cli-storage.md
# APP_LANG is one accepted code. Missing or unrecognized file stays en.
# SSHD_CLI_LANG wins over the file when it is one of those codes.
# One call at the start of app_main, after persistence is resolved.
# A later pick updates APP_LANG in this process; do not call this again
# in that process or the env value would cover the pick.
app_lang_load() {
    APP_LANG=en
    if [ -z "${PERSISTENT_STORAGE_DIR:-}" ]; then
        PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)
        export PERSISTENT_STORAGE_DIR
    fi
    _ll_path="${PERSISTENT_STORAGE_DIR}/language"
    if [ -f "${_ll_path}" ]; then
        _ll_line=$(head -n 1 "${_ll_path}" 2>/dev/null || true)
        _ll_line=$(printf '%s' "${_ll_line}" | tr -d '\r')
        case "${_ll_line}" in
            en|zh-Hans|zh-Hant|es|ar|fr|pt|ru|de|ja|ko|nl|el) APP_LANG="${_ll_line}" ;;
        esac
    fi
    case "${SSHD_CLI_LANG-}" in
        en|zh-Hans|zh-Hant|es|ar|fr|pt|ru|de|ja|ko|nl|el) APP_LANG="${SSHD_CLI_LANG}" ;;
    esac
    export APP_LANG
    unset _ll_path _ll_line
}

# Last updated: 2026-09-28
# ALIGNMENT: requirement-shell-cli-language.md · requirement-shell-cli-storage.md
# Write one line, mode 0600, under persistence. Set APP_LANG on success.
app_lang_save() {
    _ls_code=${1-}
    case "${_ls_code}" in
        en|zh-Hans|zh-Hant|es|ar|fr|pt|ru|de|ja|ko|nl|el) ;;
        *)
            unset _ls_code
            return 1
            ;;
    esac
    if [ -z "${PERSISTENT_STORAGE_DIR:-}" ]; then
        PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)
        export PERSISTENT_STORAGE_DIR
    fi
    _ls_path="${PERSISTENT_STORAGE_DIR}/language"
    if ! printf '%s\n' "${_ls_code}" > "${_ls_path}"; then
        unset _ls_code _ls_path
        return 1
    fi
    chmod 0600 "${_ls_path}" 2>/dev/null || true
    APP_LANG="${_ls_code}"
    export APP_LANG
    unset _ls_code _ls_path
    return 0
}

# Last updated: 2026-10-14
# ALIGNMENT: requirement-shell-cli-language.md
# Menu copy for APP_LANG (en, zh-Hans, zh-Hant, es, ar, fr, pt, ru, de, ja, ko, nl, el). Pure data. No input builtin.
# A missing key prints the key. Call from the current shell or a command
# substitution. Keep this body free of the four letters r, e, a, d in a row.
app_menu_text() {
    _mt_key=${1-}
    _mt_extra=${2-}
    _mt_lang=${APP_LANG:-en}
    case "${_mt_lang}" in
        zh-Hans|zh-Hant|es|ar|fr|pt|ru|de|ja|ko|nl|el) ;;
        *) _mt_lang=en ;;
    esac
    _mt_out=""
    case "${_mt_key}" in
        cat_client)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="用戶端" ;;
                es) _mt_out="cliente" ;;
                fr) _mt_out="client" ;;
                de) _mt_out="Client" ;;
                zh-Hans) _mt_out="客户端" ;;
                ja) _mt_out="クライアント" ;;
                ko) _mt_out="클라이언트" ;;
                ar) _mt_out="عميل" ;;
                pt) _mt_out="cliente" ;;
                ru) _mt_out="клиент" ;;
                nl) _mt_out="client" ;;
                el) _mt_out="πελάτης" ;;
                *) _mt_out="client-side" ;;
            esac
            ;;
        cat_server)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="伺服器端" ;;
                es) _mt_out="servidor" ;;
                fr) _mt_out="serveur" ;;
                de) _mt_out="Server" ;;
                zh-Hans) _mt_out="服务器端" ;;
                ja) _mt_out="サーバー" ;;
                ko) _mt_out="서버" ;;
                ar) _mt_out="خادم" ;;
                pt) _mt_out="servidor" ;;
                ru) _mt_out="сервер" ;;
                nl) _mt_out="server" ;;
                el) _mt_out="διακομιστής" ;;
                *) _mt_out="server-side" ;;
            esac
            ;;
        cat_self)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="自我管理" ;;
                es) _mt_out="autogestión" ;;
                fr) _mt_out="autogestion" ;;
                de) _mt_out="Selbstverwaltung" ;;
                zh-Hans) _mt_out="自我管理" ;;
                ja) _mt_out="自己管理" ;;
                ko) _mt_out="자기관리" ;;
                ar) _mt_out="إدارة-ذاتية" ;;
                pt) _mt_out="autogestão" ;;
                ru) _mt_out="самоуправление" ;;
                nl) _mt_out="zelfbeheer" ;;
                el) _mt_out="αυτοδιαχείριση" ;;
                *) _mt_out="self-management" ;;
            esac
            ;;
        cat_language)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="語言" ;;
                es) _mt_out="idioma" ;;
                fr) _mt_out="langue" ;;
                de) _mt_out="Sprache" ;;
                zh-Hans) _mt_out="语言" ;;
                ja) _mt_out="言語" ;;
                ko) _mt_out="언어" ;;
                ar) _mt_out="لغة" ;;
                pt) _mt_out="idioma" ;;
                ru) _mt_out="язык" ;;
                nl) _mt_out="taal" ;;
                el) _mt_out="γλώσσα" ;;
                *) _mt_out="language" ;;
            esac
            ;;
        front_client_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個登入的 OpenSSH 用戶端（~/.ssh/config、ssh、資料夾）" ;;
                es) _mt_out="cliente OpenSSH de este inicio (~/.ssh/config, ssh, carpetas)" ;;
                fr) _mt_out="client OpenSSH de cette session (~/.ssh/config, ssh, dossiers)" ;;
                de) _mt_out="OpenSSH-Client dieser Anmeldung (~/.ssh/config, ssh, Ordner)" ;;
                zh-Hans) _mt_out="这个登录的 OpenSSH 客户端（~/.ssh/config、ssh、文件夹）" ;;
                ja) _mt_out="このログインの OpenSSH クライアント（~/.ssh/config、ssh、フォルダ）" ;;
                ko) _mt_out="이 로그인의 OpenSSH 클라이언트(~/.ssh/config, ssh, 폴더)" ;;
                ar) _mt_out="عميل OpenSSH لهذا الدخول (~/.ssh/config وssh والمجلدات)" ;;
                pt) _mt_out="cliente OpenSSH deste login (~/.ssh/config, ssh, pastas)" ;;
                ru) _mt_out="клиент OpenSSH этого входа (~/.ssh/config, ssh, папки)" ;;
                nl) _mt_out="OpenSSH-client van deze login (~/.ssh/config, ssh, mappen)" ;;
                el) _mt_out="πελάτης OpenSSH αυτής της σύνδεσης (~/.ssh/config, ssh, φάκελοι)" ;;
                *) _mt_out="this login OpenSSH client (~/.ssh/config, ssh, folders)" ;;
            esac
            ;;
        front_server_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這台主機的 OpenSSH sshd（接聽、金鑰、連接埠）" ;;
                es) _mt_out="sshd OpenSSH de este equipo (escucha, claves, puerto)" ;;
                fr) _mt_out="sshd OpenSSH de cet hôte (écoute, clés, port)" ;;
                de) _mt_out="OpenSSH-sshd dieses Rechners (wartet, Schlüssel, Port)" ;;
                zh-Hans) _mt_out="这台主机的 OpenSSH sshd（监听、密钥、端口）" ;;
                ja) _mt_out="このホストの OpenSSH sshd（待ち受け、鍵、ポート）" ;;
                ko) _mt_out="이 호스트의 OpenSSH sshd(대기, 키, 포트)" ;;
                ar) _mt_out="sshd الخاص بـ OpenSSH على هذا الجهاز (الاستماع والمفاتيح والمنفذ)" ;;
                pt) _mt_out="sshd OpenSSH deste equipamento (escuta, chaves, porta)" ;;
                ru) _mt_out="sshd OpenSSH этого узла (прослушивание, ключи, порт)" ;;
                nl) _mt_out="OpenSSH sshd van deze host (luisteren, sleutels, poort)" ;;
                el) _mt_out="sshd OpenSSH αυτού του υπολογιστή (ακρόαση, κλειδιά, θύρα)" ;;
                *) _mt_out="this host OpenSSH sshd (listen, keys, port)" ;;
            esac
            ;;
        front_language_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單的顯示語言" ;;
                es) _mt_out="idioma de este menú" ;;
                fr) _mt_out="langue d'affichage de ce menu" ;;
                de) _mt_out="Anzeigesprache dieses Menüs" ;;
                zh-Hans) _mt_out="这个菜单的显示语言" ;;
                ja) _mt_out="このメニューの表示言語" ;;
                ko) _mt_out="이 메뉴의 표시 언어" ;;
                ar) _mt_out="لغة العرض لهذه القائمة" ;;
                pt) _mt_out="idioma de exibição deste menu" ;;
                ru) _mt_out="язык отображения этого меню" ;;
                nl) _mt_out="weergavetaal van dit menu" ;;
                el) _mt_out="γλώσσα εμφάνισης αυτού του μενού" ;;
                *) _mt_out="display language for this menu" ;;
            esac
            ;;
        front_sudoers_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="免密碼 sudo 的授權與草稿" ;;
                es) _mt_out="concesión y borradores de sudo sin contraseña" ;;
                fr) _mt_out="autorisation et brouillons pour sudo sans mot de passe" ;;
                de) _mt_out="Freigabe und Entwürfe für sudo ohne Passwort" ;;
                zh-Hans) _mt_out="免密码 sudo 的授权与草稿" ;;
                ja) _mt_out="パスワードなし sudo の認可と下書き" ;;
                ko) _mt_out="비밀번호 없는 sudo의 허가와 초안" ;;
                ar) _mt_out="منح ومسودات sudo بلا كلمة مرور" ;;
                pt) _mt_out="concessão e rascunhos de sudo sem senha" ;;
                ru) _mt_out="выдача и черновики sudo без пароля" ;;
                nl) _mt_out="toekenning en concepten voor sudo zonder wachtwoord" ;;
                el) _mt_out="παραχώρηση και πρόχειρα για sudo χωρίς κωδικό" ;;
                *) _mt_out="grant and drafts for passwordless sudo" ;;
            esac
            ;;
        front_self_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個 CLI 的安裝、版本、更新、移除" ;;
                es) _mt_out="instalación, versión, actualización y desinstalación de este CLI" ;;
                fr) _mt_out="installation, version, mise à jour et retrait de ce CLI" ;;
                de) _mt_out="Installation, Version, Aktualisierung und Entfernen dieses CLI" ;;
                zh-Hans) _mt_out="这个 CLI 的安装、版本、更新、移除" ;;
                ja) _mt_out="この CLI のインストール、バージョン、更新、削除" ;;
                ko) _mt_out="이 CLI의 설치, 버전, 업데이트, 제거" ;;
                ar) _mt_out="تثبيت هذا CLI وإصداره وتحديثه وإزالته" ;;
                pt) _mt_out="instalação, versão, atualização e remoção deste CLI" ;;
                ru) _mt_out="установка, версия, обновление и удаление этого CLI" ;;
                nl) _mt_out="installatie, versie, update en verwijdering van deze CLI" ;;
                el) _mt_out="εγκατάσταση, έκδοση, ενημέρωση και αφαίρεση αυτού του CLI" ;;
                *) _mt_out="this CLI install, version, update, uninstall" ;;
            esac
            ;;
        client_11_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個登入的 ~/.ssh/config Host 清單" ;;
                es) _mt_out="lista Host de ~/.ssh/config de este inicio" ;;
                fr) _mt_out="liste Host de ~/.ssh/config pour cette session" ;;
                de) _mt_out="Host-Liste in ~/.ssh/config dieser Anmeldung" ;;
                zh-Hans) _mt_out="这个登录的 ~/.ssh/config Host 清单" ;;
                ja) _mt_out="このログインの ~/.ssh/config の Host 一覧" ;;
                ko) _mt_out="이 로그인의 ~/.ssh/config Host 목록" ;;
                ar) _mt_out="قائمة Host في ~/.ssh/config لهذا الدخول" ;;
                pt) _mt_out="lista de Host em ~/.ssh/config deste login" ;;
                ru) _mt_out="список Host в ~/.ssh/config этого входа" ;;
                nl) _mt_out="Host-lijst in ~/.ssh/config van deze login" ;;
                el) _mt_out="λίστα Host στο ~/.ssh/config αυτής της σύνδεσης" ;;
                *) _mt_out="this login ~/.ssh/config Host list" ;;
            esac
            ;;
        client_12_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="以這個登入的 ~/.ssh/config 連線到 Host" ;;
                es) _mt_out="cliente OpenSSH hacia un Host de ~/.ssh/config de este inicio" ;;
                fr) _mt_out="client OpenSSH vers un Host du ~/.ssh/config de cette session" ;;
                de) _mt_out="OpenSSH-Client zu einem Host aus ~/.ssh/config dieser Anmeldung" ;;
                zh-Hans) _mt_out="用这个登录的 ~/.ssh/config 连接到 Host" ;;
                ja) _mt_out="このログインの ~/.ssh/config の Host へ接続する OpenSSH クライアント" ;;
                ko) _mt_out="이 로그인의 ~/.ssh/config Host로 접속하는 OpenSSH 클라이언트" ;;
                ar) _mt_out="عميل OpenSSH إلى Host من ~/.ssh/config لهذا الدخول" ;;
                pt) _mt_out="cliente OpenSSH para um Host de ~/.ssh/config deste login" ;;
                ru) _mt_out="клиент OpenSSH к Host из ~/.ssh/config этого входа" ;;
                nl) _mt_out="OpenSSH-client naar een Host uit ~/.ssh/config van deze login" ;;
                el) _mt_out="πελάτης OpenSSH προς Host από το ~/.ssh/config αυτής της σύνδεσης" ;;
                *) _mt_out="OpenSSH client to a Host from this login ~/.ssh/config" ;;
            esac
            ;;
        client_13_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="將遠端資料夾打包為 tar.gz 放到這個目錄" ;;
                es) _mt_out="empaquetar una carpeta remota en tar.gz en este directorio" ;;
                fr) _mt_out="placer un dossier distant en tar.gz dans ce répertoire" ;;
                de) _mt_out="einen fernen Ordner als tar.gz in dieses Verzeichnis holen" ;;
                zh-Hans) _mt_out="将远程文件夹打包为 tar.gz 放到这个目录" ;;
                ja) _mt_out="遠隔フォルダを tar.gz にしてこのディレクトリへ置く" ;;
                ko) _mt_out="원격 폴더를 tar.gz로 이 디렉터리에 받기" ;;
                ar) _mt_out="حزم مجلدا بعيدا كـ tar.gz في هذا الدليل" ;;
                pt) _mt_out="empacotar uma pasta remota em tar.gz neste diretório" ;;
                ru) _mt_out="упаковать удалённую папку в tar.gz в этот каталог" ;;
                nl) _mt_out="een externe map als tar.gz in deze map plaatsen" ;;
                el) _mt_out="πακετάρισμα απομακρυσμένου φακέλου σε tar.gz σε αυτόν τον κατάλογο" ;;
                *) _mt_out="tar.gz a remote folder into this directory" ;;
            esac
            ;;
        client_14_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="將本機資料夾打包為 tar.gz 傳到 Host（在該 ssh 使用者家目錄解開）" ;;
                es) _mt_out="empaquetar una carpeta local en tar.gz hacia un Host (extraer en el home de ese usuario ssh)" ;;
                fr) _mt_out="envoyer un dossier local en tar.gz vers un Host (extraire dans le home de cet utilisateur ssh)" ;;
                de) _mt_out="einen lokalen Ordner als tar.gz auf einen Host legen (entpacken im Home dieses ssh-Benutzers)" ;;
                zh-Hans) _mt_out="将本机文件夹打包为 tar.gz 传到 Host（在该 ssh 用户主目录解开）" ;;
                ja) _mt_out="ローカルフォルダを tar.gz にして Host へ送る（その ssh ユーザーのホームで展開）" ;;
                ko) _mt_out="로컬 폴더를 tar.gz로 Host에 보내기(그 ssh 사용자 홈에서 풀기)" ;;
                ar) _mt_out="حزم مجلدا محليا كـ tar.gz إلى Host (يفك تحت منزل مستخدم ssh)" ;;
                pt) _mt_out="empacotar uma pasta local em tar.gz para um Host (extrai no home desse usuário ssh)" ;;
                ru) _mt_out="упаковать локальную папку в tar.gz на Host (распаковка в домашнем каталоге пользователя ssh)" ;;
                nl) _mt_out="een lokale map als tar.gz naar een Host (uitpakken in de home van die ssh-gebruiker)" ;;
                el) _mt_out="πακετάρισμα τοπικού φακέλου σε tar.gz προς Host (εξαγωγή στον αρχικό κατάλογο αυτού του χρήστη ssh)" ;;
                *) _mt_out="tar.gz a local folder onto a Host (extract under that ssh user home)" ;;
            esac
            ;;
        client_15_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="把這個登入的 ~/.ssh/config 複製到 /var/sshd-cli" ;;
                es) _mt_out="copiar ~/.ssh/config de este inicio a /var/sshd-cli" ;;
                fr) _mt_out="copier le ~/.ssh/config de cette session vers /var/sshd-cli" ;;
                de) _mt_out="~/.ssh/config dieser Anmeldung nach /var/sshd-cli kopieren" ;;
                zh-Hans) _mt_out="把这个登录的 ~/.ssh/config 复制到 /var/sshd-cli" ;;
                ja) _mt_out="このログインの ~/.ssh/config を /var/sshd-cli へコピー" ;;
                ko) _mt_out="이 로그인의 ~/.ssh/config를 /var/sshd-cli로 복사" ;;
                ar) _mt_out="نسخ ~/.ssh/config لهذا الدخول إلى /var/sshd-cli" ;;
                pt) _mt_out="copiar ~/.ssh/config deste login para /var/sshd-cli" ;;
                ru) _mt_out="копировать ~/.ssh/config этого входа в /var/sshd-cli" ;;
                nl) _mt_out="kopieer ~/.ssh/config van deze login naar /var/sshd-cli" ;;
                el) _mt_out="αντιγραφή του ~/.ssh/config αυτής της σύνδεσης στο /var/sshd-cli" ;;
                *) _mt_out="copy this login ~/.ssh/config to /var/sshd-cli" ;;
            esac
            ;;
        client_16_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="把 /var/sshd-cli/config 複製進這個登入的 ~/.ssh/config" ;;
                es) _mt_out="copiar /var/sshd-cli/config en ~/.ssh/config de este inicio" ;;
                fr) _mt_out="copier /var/sshd-cli/config dans le ~/.ssh/config de cette session" ;;
                de) _mt_out="/var/sshd-cli/config in ~/.ssh/config dieser Anmeldung kopieren" ;;
                zh-Hans) _mt_out="把 /var/sshd-cli/config 复制进这个登录的 ~/.ssh/config" ;;
                ja) _mt_out="/var/sshd-cli/config をこのログインの ~/.ssh/config へコピー" ;;
                ko) _mt_out="/var/sshd-cli/config를 이 로그인의 ~/.ssh/config로 복사" ;;
                ar) _mt_out="نسخ /var/sshd-cli/config إلى ~/.ssh/config لهذا الدخول" ;;
                pt) _mt_out="copiar /var/sshd-cli/config para ~/.ssh/config deste login" ;;
                ru) _mt_out="копировать /var/sshd-cli/config в ~/.ssh/config этого входа" ;;
                nl) _mt_out="kopieer /var/sshd-cli/config naar ~/.ssh/config van deze login" ;;
                el) _mt_out="αντιγραφή του /var/sshd-cli/config στο ~/.ssh/config αυτής της σύνδεσης" ;;
                *) _mt_out="copy /var/sshd-cli/config into this login ~/.ssh/config" ;;
            esac
            ;;
        client_18_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="從 user@host（或 host）複製 /var/sshd-cli/config" ;;
                es) _mt_out="copiar /var/sshd-cli/config desde user@host (o host)" ;;
                fr) _mt_out="copier /var/sshd-cli/config depuis user@host (ou host)" ;;
                de) _mt_out="/var/sshd-cli/config von user@host (oder host) kopieren" ;;
                zh-Hans) _mt_out="从 user@host（或 host）复制 /var/sshd-cli/config" ;;
                ja) _mt_out="user@host（または host）から /var/sshd-cli/config をコピー" ;;
                ko) _mt_out="user@host(또는 host)에서 /var/sshd-cli/config 복사" ;;
                ar) _mt_out="نسخ /var/sshd-cli/config من user@host (أو host)" ;;
                pt) _mt_out="copiar /var/sshd-cli/config de user@host (ou host)" ;;
                ru) _mt_out="копировать /var/sshd-cli/config с user@host (или host)" ;;
                nl) _mt_out="kopieer /var/sshd-cli/config van user@host (of host)" ;;
                el) _mt_out="αντιγραφή του /var/sshd-cli/config από user@host (ή host)" ;;
                *) _mt_out="copy /var/sshd-cli/config from user@host (or host)" ;;
            esac
            ;;
        hint_sync_typed)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="   （或輸入 sync-from-remote [user@host]：從另一台主機複製 /var/sshd-cli/config）" ;;
                es) _mt_out="   (o escriba sync-from-remote [user@host]: copiar /var/sshd-cli/config desde otro equipo)" ;;
                fr) _mt_out="   (ou saisissez sync-from-remote [user@host] : copier /var/sshd-cli/config depuis un autre hôte)" ;;
                de) _mt_out="   (oder sync-from-remote [user@host] eingeben: /var/sshd-cli/config von einem anderen Rechner kopieren)" ;;
                zh-Hans) _mt_out="   （或输入 sync-from-remote [user@host]：从另一台主机复制 /var/sshd-cli/config）" ;;
                ja) _mt_out="   （または sync-from-remote [user@host] と入力: 別のホストから /var/sshd-cli/config をコピー）" ;;
                ko) _mt_out="   (또는 sync-from-remote [user@host] 입력: 다른 호스트에서 /var/sshd-cli/config 복사)" ;;
                ar) _mt_out="   (أو اكتب sync-from-remote [user@host]: نسخ /var/sshd-cli/config من جهاز آخر)" ;;
                pt) _mt_out="   (ou digite sync-from-remote [user@host]: copia /var/sshd-cli/config de outro host)" ;;
                ru) _mt_out="   (или введите sync-from-remote [user@host]: копия /var/sshd-cli/config с другого узла)" ;;
                nl) _mt_out="   (of typ sync-from-remote [user@host]: kopieer /var/sshd-cli/config van een andere host)" ;;
                el) _mt_out="   (ή πληκτρολογήστε sync-from-remote [user@host]: αντιγραφή /var/sshd-cli/config από άλλον υπολογιστή)" ;;
                *) _mt_out="   (or type sync-from-remote [user@host]: copy /var/sshd-cli/config from another host)" ;;
            esac
            ;;
        server_21_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="執行狀態、連接埠與路徑" ;;
                es) _mt_out="estado, puerto y rutas" ;;
                fr) _mt_out="état, port et chemins" ;;
                de) _mt_out="Laufzustand, Port und Pfade" ;;
                zh-Hans) _mt_out="运行状态、端口与路径" ;;
                ja) _mt_out="実行状態、ポート、パス" ;;
                ko) _mt_out="실행 상태, 포트, 경로" ;;
                ar) _mt_out="التشغيل والمنفذ والمسارات" ;;
                pt) _mt_out="em execução, porta e caminhos" ;;
                ru) _mt_out="работа, порт и пути" ;;
                nl) _mt_out="actief, poort en paden" ;;
                el) _mt_out="εκτέλεση, θύρα και διαδρομές" ;;
                *) _mt_out="running, port, and paths" ;;
            esac
            ;;
        server_22_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="啟動 OpenSSH 常駐程式（背景執行，不是開機服務）" ;;
                es) _mt_out="iniciar el demonio OpenSSH (en segundo plano, no como servicio de arranque)" ;;
                fr) _mt_out="lancer le démon OpenSSH (en arrière-plan, pas un service de démarrage)" ;;
                de) _mt_out="OpenSSH-Daemon starten (im Hintergrund, kein Startdienst)" ;;
                zh-Hans) _mt_out="启动 OpenSSH 常驻程序（后台运行，不是开机服务）" ;;
                ja) _mt_out="OpenSSH デーモンを起動（バックグラウンド。起動時サービスではない）" ;;
                ko) _mt_out="OpenSSH 데몬 시작(백그라운드, 부팅 서비스 아님)" ;;
                ar) _mt_out="تشغيل خدمة OpenSSH (في الخلفية، ليست خدمة إقلاع)" ;;
                pt) _mt_out="iniciar o daemon OpenSSH (em segundo plano, não é serviço de arranque)" ;;
                ru) _mt_out="запустить демон OpenSSH (в фоне, не служба загрузки)" ;;
                nl) _mt_out="start de OpenSSH-daemon (op de achtergrond, geen opstartservice)" ;;
                el) _mt_out="εκκίνηση του δαίμονα OpenSSH (στο παρασκήνιο, όχι υπηρεσία εκκίνησης)" ;;
                *) _mt_out="launch the OpenSSH daemon (background, not a boot service)" ;;
            esac
            ;;
        server_23_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="結束正在執行的常駐程式" ;;
                es) _mt_out="terminar el demonio en ejecución" ;;
                fr) _mt_out="arrêter le démon en cours" ;;
                de) _mt_out="den laufenden Daemon beenden" ;;
                zh-Hans) _mt_out="结束正在运行的常驻程序" ;;
                ja) _mt_out="実行中のデーモンを終了" ;;
                ko) _mt_out="실행 중인 데몬 종료" ;;
                ar) _mt_out="إنهاء الخدمة العاملة" ;;
                pt) _mt_out="encerrar o daemon em execução" ;;
                ru) _mt_out="остановить работающий демон" ;;
                nl) _mt_out="stop de lopende daemon" ;;
                el) _mt_out="τερματισμός του δαίμονα που εκτελείται" ;;
                *) _mt_out="end the running daemon" ;;
            esac
            ;;
        server_24_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="先停止再啟動" ;;
                es) _mt_out="detener y luego iniciar" ;;
                fr) _mt_out="arrêter puis lancer" ;;
                de) _mt_out="stoppen und dann starten" ;;
                zh-Hans) _mt_out="先停止再启动" ;;
                ja) _mt_out="停止してから起動" ;;
                ko) _mt_out="중지한 다음 시작" ;;
                ar) _mt_out="إيقاف ثم تشغيل" ;;
                pt) _mt_out="parar e depois iniciar" ;;
                ru) _mt_out="остановить, затем запустить" ;;
                nl) _mt_out="stoppen en daarna starten" ;;
                el) _mt_out="διακοπή και έπειτα εκκίνηση" ;;
                *) _mt_out="stop then start" ;;
            esac
            ;;
        self_61_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="放置 ${APP_NAME}；確保 rc 與 Termux 的 openssh/termux-auth；啟動 sshd" ;;
                es) _mt_out="colocar ${APP_NAME}; asegurar rc y openssh/termux-auth de Termux; iniciar sshd" ;;
                fr) _mt_out="placer ${APP_NAME} ; assurer rc et openssh/termux-auth de Termux ; lancer sshd" ;;
                de) _mt_out="${APP_NAME} ablegen; rc und Termux openssh/termux-auth sicherstellen; sshd starten" ;;
                zh-Hans) _mt_out="放置 ${APP_NAME}；确保 rc 与 Termux 的 openssh/termux-auth；启动 sshd" ;;
                ja) _mt_out="${APP_NAME} を配置；rc と Termux の openssh/termux-auth を整え；sshd を起動" ;;
                ko) _mt_out="${APP_NAME} 배치; rc와 Termux openssh/termux-auth 확보; sshd 시작" ;;
                ar) _mt_out="وضع ${APP_NAME}؛ تأكد من rc وopenssh/termux-auth في Termux؛ ابدأ sshd" ;;
                pt) _mt_out="colocar ${APP_NAME}; garantir rc + openssh/termux-auth no Termux; iniciar sshd" ;;
                ru) _mt_out="разместить ${APP_NAME}; обеспечить rc + openssh/termux-auth в Termux; запустить sshd" ;;
                nl) _mt_out="plaats ${APP_NAME}; zorg voor rc + Termux openssh/termux-auth; start sshd" ;;
                el) _mt_out="τοποθέτηση ${APP_NAME}· rc + openssh/termux-auth στο Termux· εκκίνηση sshd" ;;
                *) _mt_out="place ${APP_NAME}; ensure rc + Termux openssh/termux-auth; start sshd" ;;
            esac
            ;;
        self_62_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="顯示版本與詳細診斷（about）" ;;
                es) _mt_out="mostrar la versión y el diagnóstico detallado (about)" ;;
                fr) _mt_out="afficher la version et le diagnostic détaillé (about)" ;;
                de) _mt_out="Version und ausführliche Diagnose anzeigen (about)" ;;
                zh-Hans) _mt_out="显示版本与详细诊断（about）" ;;
                ja) _mt_out="バージョンと詳細な診断を表示（about）" ;;
                ko) _mt_out="버전과 자세한 진단 표시(about)" ;;
                ar) _mt_out="عرض الإصدار والتشخيص المفصل (about)" ;;
                pt) _mt_out="mostrar a versão e o diagnóstico detalhado (about)" ;;
                ru) _mt_out="показать версию и подробную диагностику (about)" ;;
                nl) _mt_out="toon versie en uitgebreide diagnostiek (about)" ;;
                el) _mt_out="εμφάνιση έκδοσης και λεπτομερούς διάγνωσης (about)" ;;
                *) _mt_out="show version and detailed diagnostics (about)" ;;
            esac
            ;;
        self_63_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="顯示詳細診斷" ;;
                es) _mt_out="mostrar el diagnóstico detallado" ;;
                fr) _mt_out="afficher le diagnostic détaillé" ;;
                de) _mt_out="ausführliche Diagnose anzeigen" ;;
                zh-Hans) _mt_out="显示详细诊断" ;;
                ja) _mt_out="詳細な診断を表示" ;;
                ko) _mt_out="자세한 진단 표시" ;;
                ar) _mt_out="عرض التشخيص المفصل" ;;
                pt) _mt_out="mostrar o diagnóstico detalhado" ;;
                ru) _mt_out="показать подробную диагностику" ;;
                nl) _mt_out="toon uitgebreide diagnostiek" ;;
                el) _mt_out="εμφάνιση λεπτομερούς διάγνωσης" ;;
                *) _mt_out="show detailed diagnostics" ;;
            esac
            ;;
        self_64_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="比較本機與遠端版本" ;;
                es) _mt_out="comparar la versión local con la remota" ;;
                fr) _mt_out="comparer la version locale et la version distante" ;;
                de) _mt_out="lokale und ferne Version vergleichen" ;;
                zh-Hans) _mt_out="比较本机与远程版本" ;;
                ja) _mt_out="ローカルと遠隔のバージョンを比較" ;;
                ko) _mt_out="로컬과 원격 버전 비교" ;;
                ar) _mt_out="قارن الإصدار المحلي بالبعيد" ;;
                pt) _mt_out="comparar a versão local com a remota" ;;
                ru) _mt_out="сравнить локальную и удалённую версию" ;;
                nl) _mt_out="vergelijk lokale en externe versie" ;;
                el) _mt_out="σύγκριση τοπικής και απομακρυσμένης έκδοσης" ;;
                *) _mt_out="compare local vs remote version" ;;
            esac
            ;;
        self_65_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="將 ${APP_NAME} 更新到較新的遠端版本" ;;
                es) _mt_out="actualizar ${APP_NAME} a una versión remota más nueva" ;;
                fr) _mt_out="mettre ${APP_NAME} à jour vers une version distante plus récente" ;;
                de) _mt_out="${APP_NAME} auf eine neuere ferne Version aktualisieren" ;;
                zh-Hans) _mt_out="将 ${APP_NAME} 更新到较新的远程版本" ;;
                ja) _mt_out="${APP_NAME} を新しい遠隔バージョンへ更新" ;;
                ko) _mt_out="${APP_NAME}를 더 새로운 원격 버전으로 업데이트" ;;
                ar) _mt_out="تحديث ${APP_NAME} إلى إصدار بعيد أحدث" ;;
                pt) _mt_out="atualizar ${APP_NAME} para uma versão remota mais nova" ;;
                ru) _mt_out="обновить ${APP_NAME} до более новой удалённой версии" ;;
                nl) _mt_out="werk ${APP_NAME} bij naar een nieuwere externe versie" ;;
                el) _mt_out="ενημέρωση ${APP_NAME} σε νεότερη απομακρυσμένη έκδοση" ;;
                *) _mt_out="update ${APP_NAME} to a newer remote version" ;;
            esac
            ;;
        self_66_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="移除 ${APP_NAME}（安全清理 PATH）" ;;
                es) _mt_out="quitar ${APP_NAME} (limpieza segura de PATH)" ;;
                fr) _mt_out="retirer ${APP_NAME} (nettoyage sûr de PATH)" ;;
                de) _mt_out="${APP_NAME} entfernen (sicheres Aufräumen von PATH)" ;;
                zh-Hans) _mt_out="移除 ${APP_NAME}（安全清理 PATH）" ;;
                ja) _mt_out="${APP_NAME} を削除（PATH を安全に整理）" ;;
                ko) _mt_out="${APP_NAME} 제거(PATH를 안전하게 정리)" ;;
                ar) _mt_out="إزالة ${APP_NAME} (تنظيف PATH بأمان)" ;;
                pt) _mt_out="remover ${APP_NAME} (limpeza segura do PATH)" ;;
                ru) _mt_out="удалить ${APP_NAME} (безопасная очистка PATH)" ;;
                nl) _mt_out="verwijder ${APP_NAME} (veilige PATH-opruiming)" ;;
                el) _mt_out="αφαίρεση ${APP_NAME} (ασφαλής καθαρισμός του PATH)" ;;
                *) _mt_out="remove ${APP_NAME} (safe PATH cleanup)" ;;
            esac
            ;;
        self_67_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="只放置這個 CLI（複製這個檔案，或在管線輸入時下載）" ;;
                es) _mt_out="colocar solo este CLI (copiar este archivo, o descargar si llega por una tubería)" ;;
                fr) _mt_out="placer seulement ce CLI (copier ce fichier, ou télécharger s'il arrive dans un tube)" ;;
                de) _mt_out="nur dieses CLI ablegen (diese Datei kopieren, oder laden wenn sie in einer Pipe ankommt)" ;;
                zh-Hans) _mt_out="只放置这个 CLI（复制这个文件，或在管道输入时下载）" ;;
                ja) _mt_out="この CLI だけを配置（このファイルをコピー、またはパイプで届いたとき取り込む）" ;;
                ko) _mt_out="이 CLI만 배치(이 파일을 복사하거나, 파이프로 들어올 때 가져오기)" ;;
                ar) _mt_out="وضع هذا CLI فقط (نسخ هذا الملف، أو تنزيل عند التوجيه)" ;;
                pt) _mt_out="colocar só este CLI (copiar este arquivo, ou baixar quando canalizado)" ;;
                ru) _mt_out="разместить только этот CLI (копировать этот файл или загрузить по каналу)" ;;
                nl) _mt_out="plaats alleen deze CLI (kopieer dit bestand, of download bij een pipe)" ;;
                el) _mt_out="τοποθέτηση μόνο αυτού του CLI (αντιγραφή αυτού του αρχείου, ή λήψη σε διοχέτευση)" ;;
                *) _mt_out="place this CLI only (copy this file, or download when piped)" ;;
            esac
            ;;
        line_back)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="0. 返回" ;;
                es) _mt_out="0. Atrás" ;;
                fr) _mt_out="0. Retour" ;;
                de) _mt_out="0. Zurück" ;;
                zh-Hans) _mt_out="0. 返回" ;;
                ja) _mt_out="0. 戻る" ;;
                ko) _mt_out="0. 뒤로" ;;
                ar) _mt_out="0. رجوع" ;;
                pt) _mt_out="0. Voltar" ;;
                ru) _mt_out="0. Назад" ;;
                nl) _mt_out="0. Terug" ;;
                el) _mt_out="0. Πίσω" ;;
                *) _mt_out="0. Back" ;;
            esac
            ;;
        line_exit)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="9. 離開" ;;
                es) _mt_out="9. Salir" ;;
                fr) _mt_out="9. Quitter" ;;
                de) _mt_out="9. Beenden" ;;
                zh-Hans) _mt_out="9. 离开" ;;
                ja) _mt_out="9. 終了" ;;
                ko) _mt_out="9. 종료" ;;
                ar) _mt_out="9. خروج" ;;
                pt) _mt_out="9. Sair" ;;
                ru) _mt_out="9. Выход" ;;
                nl) _mt_out="9. Afsluiten" ;;
                el) _mt_out="9. Έξοδος" ;;
                *) _mt_out="9. Exit" ;;
            esac
            ;;
        line_prompt)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="請輸入編號，或輸入指令名稱： " ;;
                es) _mt_out="Elija un número, o escriba el nombre del comando: " ;;
                fr) _mt_out="Choisissez un numéro, ou saisissez le nom de la commande : " ;;
                de) _mt_out="Wählen Sie eine Nummer, oder geben Sie den Befehlsnamen ein: " ;;
                zh-Hans) _mt_out="请输入编号，或输入指令名称： " ;;
                ja) _mt_out="番号を入力するか、コマンド名を入力してください: " ;;
                ko) _mt_out="번호를 입력하거나 명령 이름을 입력하세요: " ;;
                ar) _mt_out="اختر رقما، أو اكتب اسم الأمر: " ;;
                pt) _mt_out="Escolha um número, ou escreva o nome do comando: " ;;
                ru) _mt_out="Выберите номер или введите имя команды: " ;;
                nl) _mt_out="Kies een nummer, of typ de opdrachtnaam: " ;;
                el) _mt_out="Επιλέξτε αριθμό ή πληκτρολογήστε το όνομα της εντολής: " ;;
                *) _mt_out="Choose a number, or type the command name: " ;;
            esac
            ;;
        lang_en_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用英文" ;;
                es) _mt_out="usar inglés en este menú" ;;
                fr) _mt_out="utiliser l'anglais pour ce menu" ;;
                de) _mt_out="Englisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用英文" ;;
                ja) _mt_out="このメニューを英語にする" ;;
                ko) _mt_out="이 메뉴를 영어로" ;;
                ar) _mt_out="استخدام الإنجليزية لهذه القائمة" ;;
                pt) _mt_out="usar inglês neste menu" ;;
                ru) _mt_out="использовать английский для этого меню" ;;
                nl) _mt_out="Engels voor dit menu gebruiken" ;;
                el) _mt_out="χρήση αγγλικών για αυτό το μενού" ;;
                *) _mt_out="use English for this menu" ;;
            esac
            ;;
        lang_zh_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用繁體中文" ;;
                es) _mt_out="usar chino tradicional en este menú" ;;
                fr) _mt_out="utiliser le chinois traditionnel pour ce menu" ;;
                de) _mt_out="Traditionelles Chinesisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用繁体中文" ;;
                ja) _mt_out="このメニューを繁体字中国語にする" ;;
                ko) _mt_out="이 메뉴를 번체 중국어로" ;;
                ar) _mt_out="استخدام الصينية التقليدية لهذه القائمة" ;;
                pt) _mt_out="usar chinês tradicional neste menu" ;;
                ru) _mt_out="использовать традиционный китайский для этого меню" ;;
                nl) _mt_out="Traditioneel Chinees voor dit menu gebruiken" ;;
                el) _mt_out="χρήση παραδοσιακών κινεζικών για αυτό το μενού" ;;
                *) _mt_out="use Traditional Chinese for this menu" ;;
            esac
            ;;
        lang_es_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用西班牙文" ;;
                es) _mt_out="usar español en este menú" ;;
                fr) _mt_out="utiliser l'espagnol pour ce menu" ;;
                de) _mt_out="Spanisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用西班牙文" ;;
                ja) _mt_out="このメニューをスペイン語にする" ;;
                ko) _mt_out="이 메뉴를 스페인어로" ;;
                ar) _mt_out="استخدام الإسبانية لهذه القائمة" ;;
                pt) _mt_out="usar espanhol neste menu" ;;
                ru) _mt_out="использовать испанский для этого меню" ;;
                nl) _mt_out="Spaans voor dit menu gebruiken" ;;
                el) _mt_out="χρήση ισπανικών για αυτό το μενού" ;;
                *) _mt_out="use Spanish for this menu" ;;
            esac
            ;;
        lang_fr_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用法文" ;;
                es) _mt_out="usar francés en este menú" ;;
                fr) _mt_out="utiliser le français pour ce menu" ;;
                de) _mt_out="Französisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用法文" ;;
                ja) _mt_out="このメニューをフランス語にする" ;;
                ko) _mt_out="이 메뉴를 프랑스어로" ;;
                ar) _mt_out="استخدام الفرنسية لهذه القائمة" ;;
                pt) _mt_out="usar francês neste menu" ;;
                ru) _mt_out="использовать французский для этого меню" ;;
                nl) _mt_out="Frans voor dit menu gebruiken" ;;
                el) _mt_out="χρήση γαλλικών για αυτό το μενού" ;;
                *) _mt_out="use French for this menu" ;;
            esac
            ;;
        lang_de_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用德文" ;;
                es) _mt_out="usar alemán en este menú" ;;
                fr) _mt_out="utiliser l'allemand pour ce menu" ;;
                de) _mt_out="Deutsch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用德文" ;;
                ja) _mt_out="このメニューをドイツ語にする" ;;
                ko) _mt_out="이 메뉴를 독일어로" ;;
                ar) _mt_out="استخدام الألمانية لهذه القائمة" ;;
                pt) _mt_out="usar alemão neste menu" ;;
                ru) _mt_out="использовать немецкий для этого меню" ;;
                nl) _mt_out="Duits voor dit menu gebruiken" ;;
                el) _mt_out="χρήση γερμανικών για αυτό το μενού" ;;
                *) _mt_out="use German for this menu" ;;
            esac
            ;;
        lang_zh_hans_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用簡體中文" ;;
                es) _mt_out="usar chino simplificado en este menú" ;;
                fr) _mt_out="utiliser le chinois simplifié pour ce menu" ;;
                de) _mt_out="Vereinfachtes Chinesisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用简体中文" ;;
                ja) _mt_out="このメニューを簡体字中国語にする" ;;
                ko) _mt_out="이 메뉴를 간체 중국어로" ;;
                ar) _mt_out="استخدام الصينية المبسطة لهذه القائمة" ;;
                pt) _mt_out="usar chinês simplificado neste menu" ;;
                ru) _mt_out="использовать упрощённый китайский для этого меню" ;;
                nl) _mt_out="Vereenvoudigd Chinees voor dit menu gebruiken" ;;
                el) _mt_out="χρήση απλοποιημένων κινεζικών για αυτό το μενού" ;;
                *) _mt_out="use Simplified Chinese for this menu" ;;
            esac
            ;;
        lang_saved)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="選單語言是繁體中文" ;;
                es) _mt_out="El idioma del menú es español" ;;
                fr) _mt_out="La langue du menu est le français" ;;
                de) _mt_out="Die Menüsprache ist Deutsch" ;;
                zh-Hans) _mt_out="菜单语言是简体中文" ;;
                ja) _mt_out="メニューの言語は日本語" ;;
                ko) _mt_out="메뉴 언어는 한국어" ;;
                ar) _mt_out="لغة القائمة هي العربية" ;;
                pt) _mt_out="O idioma do menu é português" ;;
                ru) _mt_out="Язык меню — русский" ;;
                nl) _mt_out="De menutaal is Nederlands" ;;
                el) _mt_out="Η γλώσσα του μενού είναι ελληνικά" ;;
                *) _mt_out="Menu language is English" ;;
            esac
            ;;
        lang_save_fail)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="無法儲存選單語言" ;;
                es) _mt_out="No se pudo guardar el idioma del menú" ;;
                fr) _mt_out="Impossible d'enregistrer la langue du menu" ;;
                de) _mt_out="Die Menüsprache konnte nicht gespeichert werden" ;;
                zh-Hans) _mt_out="无法保存菜单语言" ;;
                ja) _mt_out="メニューの言語を保存できませんでした" ;;
                ko) _mt_out="메뉴 언어를 저장하지 못했습니다" ;;
                ar) _mt_out="تعذر حفظ لغة القائمة" ;;
                pt) _mt_out="Não foi possível guardar o idioma do menu" ;;
                ru) _mt_out="Не удалось сохранить язык меню" ;;
                nl) _mt_out="De menutaal kon niet worden opgeslagen" ;;
                el) _mt_out="Δεν ήταν δυνατή η αποθήκευση της γλώσσας του μενού" ;;
                *) _mt_out="Could not save the menu language" ;;
            esac
            ;;
        sudoers_header)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="sudoers（免密碼授權與草稿）" ;;
                es) _mt_out="sudoers (concesión y borradores)" ;;
                fr) _mt_out="sudoers (autorisation et brouillons)" ;;
                de) _mt_out="sudoers (Freigabe und Entwürfe)" ;;
                zh-Hans) _mt_out="sudoers（免密码授权与草稿）" ;;
                ja) _mt_out="sudoers（パスワードなしの認可と下書き）" ;;
                ko) _mt_out="sudoers(비밀번호 없는 허가와 초안)" ;;
                ar) _mt_out="sudoers (منح ومسودات)" ;;
                pt) _mt_out="sudoers (concessão e rascunhos)" ;;
                ru) _mt_out="sudoers (выдача и черновики)" ;;
                nl) _mt_out="sudoers (toekenning en concepten)" ;;
                el) _mt_out="sudoers (παραχώρηση και πρόχειρα)" ;;
                *) _mt_out="sudoers (grant and drafts)" ;;
            esac
            ;;
        sudoers_52_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="將 JSON 授權排入待處理佇列" ;;
                es) _mt_out="poner la concesión JSON en la cola de entrada" ;;
                fr) _mt_out="mettre l'autorisation JSON dans la file d'entrée" ;;
                de) _mt_out="die JSON-Freigabe in die Eingangs-Warteschlange legen" ;;
                zh-Hans) _mt_out="将 JSON 授权排入待处理队列" ;;
                ja) _mt_out="JSON 認可を受信待ちへ入れる" ;;
                ko) _mt_out="JSON 허가를 수신 대기열에 넣기" ;;
                ar) _mt_out="صف منحة JSON الواردة" ;;
                pt) _mt_out="enfileirar a concessão JSON de entrada" ;;
                ru) _mt_out="поставить входящую JSON-выдачу в очередь" ;;
                nl) _mt_out="zet de inkomende JSON-toekenning in de wachtrij" ;;
                el) _mt_out="ουρά για την εισερχόμενη παραχώρηση JSON" ;;
                *) _mt_out="Queue the JSON grant inbound" ;;
            esac
            ;;
        sudoers_53_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="輸出 sudoers 草稿" ;;
                es) _mt_out="emitir el borrador sudoers" ;;
                fr) _mt_out="émettre le brouillon sudoers" ;;
                de) _mt_out="sudoers-Entwurf ausgeben" ;;
                zh-Hans) _mt_out="输出 sudoers 草稿" ;;
                ja) _mt_out="sudoers 下書きを出力" ;;
                ko) _mt_out="sudoers 초안 출력" ;;
                ar) _mt_out="إخراج مسودة sudoers" ;;
                pt) _mt_out="emitir o rascunho sudoers" ;;
                ru) _mt_out="вывести черновик sudoers" ;;
                nl) _mt_out="toon het sudoers-concept" ;;
                el) _mt_out="εμφάνιση πρόχειρου sudoers" ;;
                *) _mt_out="Emit sudoers draft" ;;
            esac
            ;;
        sudoers_54_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="寫出管理者安裝腳本" ;;
                es) _mt_out="escribir el script de instalación del administrador" ;;
                fr) _mt_out="écrire le script d'installation pour l'administrateur" ;;
                de) _mt_out="Installationsskript für die Verwaltung schreiben" ;;
                zh-Hans) _mt_out="写出管理者安装脚本" ;;
                ja) _mt_out="管理者向けインストールスクリプトを書く" ;;
                ko) _mt_out="관리자 설치 스크립트 작성" ;;
                ar) _mt_out="كتابة سكربت التثبيت للمسؤول" ;;
                pt) _mt_out="escrever o script de instalação do admin" ;;
                ru) _mt_out="записать скрипт установки для администратора" ;;
                nl) _mt_out="schrijf het installatiescript voor de beheerder" ;;
                el) _mt_out="εγγραφή σεναρίου εγκατάστασης διαχειριστή" ;;
                *) _mt_out="Write admin install script" ;;
            esac
            ;;
        sudoers_55_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="只移除 sudoers 草稿" ;;
                es) _mt_out="quitar solo el borrador sudoers" ;;
                fr) _mt_out="retirer seulement le brouillon sudoers" ;;
                de) _mt_out="nur den sudoers-Entwurf entfernen" ;;
                zh-Hans) _mt_out="只移除 sudoers 草稿" ;;
                ja) _mt_out="sudoers 下書きだけを削除" ;;
                ko) _mt_out="sudoers 초안만 제거" ;;
                ar) _mt_out="إزالة مسودة sudoers فقط" ;;
                pt) _mt_out="remover só o rascunho sudoers" ;;
                ru) _mt_out="удалить только черновик sudoers" ;;
                nl) _mt_out="verwijder alleen het sudoers-concept" ;;
                el) _mt_out="αφαίρεση μόνο του πρόχειρου sudoers" ;;
                *) _mt_out="Remove sudoers draft only" ;;
            esac
            ;;
        hidden_front)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="sudoers 不適用於 ${_mt_extra}" ;;
                es) _mt_out="sudoers no está disponible para ${_mt_extra}" ;;
                fr) _mt_out="sudoers n'est pas disponible pour ${_mt_extra}" ;;
                de) _mt_out="sudoers ist nicht verfügbar für ${_mt_extra}" ;;
                zh-Hans) _mt_out="sudoers 不适用于 ${_mt_extra}" ;;
                ja) _mt_out="sudoers は ${_mt_extra} では使えません" ;;
                ko) _mt_out="sudoers 는 ${_mt_extra} 에서 사용할 수 없습니다" ;;
                ar) _mt_out="sudoers غير متاح لـ ${_mt_extra}" ;;
                pt) _mt_out="sudoers não está disponível para ${_mt_extra}" ;;
                ru) _mt_out="sudoers недоступен для ${_mt_extra}" ;;
                nl) _mt_out="sudoers is niet beschikbaar voor ${_mt_extra}" ;;
                el) _mt_out="το sudoers δεν είναι διαθέσιμο για ${_mt_extra}" ;;
                *) _mt_out="sudoers not available for ${_mt_extra}" ;;
            esac
            ;;
        hidden_client)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="backup-config 與 sync-config 不適用於 ${_mt_extra}" ;;
                es) _mt_out="backup-config y sync-config no están disponibles para ${_mt_extra}" ;;
                fr) _mt_out="backup-config et sync-config ne sont pas disponibles pour ${_mt_extra}" ;;
                de) _mt_out="backup-config und sync-config sind nicht verfügbar für ${_mt_extra}" ;;
                zh-Hans) _mt_out="backup-config 与 sync-config 不适用于 ${_mt_extra}" ;;
                ja) _mt_out="backup-config と sync-config は ${_mt_extra} では使えません" ;;
                ko) _mt_out="backup-config 와 sync-config 는 ${_mt_extra} 에서 사용할 수 없습니다" ;;
                ar) _mt_out="backup-config وsync-config غير متاحين لـ ${_mt_extra}" ;;
                pt) _mt_out="backup-config e sync-config não estão disponíveis para ${_mt_extra}" ;;
                ru) _mt_out="backup-config и sync-config недоступны для ${_mt_extra}" ;;
                nl) _mt_out="backup-config en sync-config zijn niet beschikbaar voor ${_mt_extra}" ;;
                el) _mt_out="τα backup-config και sync-config δεν είναι διαθέσιμα για ${_mt_extra}" ;;
                *) _mt_out="backup-config and sync-config not available for ${_mt_extra}" ;;
            esac
            ;;
        hidden_server)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="非 root 在 ${_mt_extra} 無法使用 start/stop/restart sshd" ;;
                es) _mt_out="las funciones start/stop/restart sshd no están disponibles sin root en ${_mt_extra}" ;;
                fr) _mt_out="les fonctions start/stop/restart sshd ne sont pas disponibles hors root sur ${_mt_extra}" ;;
                de) _mt_out="start/stop/restart sshd ist ohne root auf ${_mt_extra} nicht verfügbar" ;;
                zh-Hans) _mt_out="非 root 在 ${_mt_extra} 无法使用 start/stop/restart sshd" ;;
                ja) _mt_out="root 以外は ${_mt_extra} で start/stop/restart sshd を使えません" ;;
                ko) _mt_out="root가 아니면 ${_mt_extra} 에서 start/stop/restart sshd 를 사용할 수 없습니다" ;;
                ar) _mt_out="ميزات start/stop/restart sshd غير متاحة لغير root في ${_mt_extra}" ;;
                pt) _mt_out="as funções start/stop/restart sshd não estão disponíveis sem root em ${_mt_extra}" ;;
                ru) _mt_out="функции start/stop/restart sshd недоступны без root в ${_mt_extra}" ;;
                nl) _mt_out="start/stop/restart sshd is zonder root op ${_mt_extra} niet beschikbaar" ;;
                el) _mt_out="οι λειτουργίες start/stop/restart sshd δεν είναι διαθέσιμες χωρίς root στο ${_mt_extra}" ;;
                *) _mt_out="start/stop/restart sshd features are not available for non-root in ${_mt_extra}" ;;
            esac
            ;;
        unknown_menu)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="未知的選單選項 '${_mt_extra}'。請從清單選擇編號，或輸入指令名稱。" ;;
                es) _mt_out="Opción de menú desconocida '${_mt_extra}'. Elija un número de la lista, o escriba el nombre del comando." ;;
                fr) _mt_out="Choix de menu inconnu '${_mt_extra}'. Choisissez un numéro dans la liste, ou saisissez le nom de la commande." ;;
                de) _mt_out="Unbekannte Menüauswahl '${_mt_extra}'. Wählen Sie eine Nummer aus der Liste, oder geben Sie den Befehlsnamen ein." ;;
                zh-Hans) _mt_out="未知的菜单选项 '${_mt_extra}'。请从清单选择编号，或输入指令名称。" ;;
                ja) _mt_out="未知のメニュー選択 '${_mt_extra}'。一覧の番号を選ぶか、コマンド名を入力してください。" ;;
                ko) _mt_out="알 수 없는 메뉴 선택 '${_mt_extra}'. 목록의 번호를 고르거나 명령 이름을 입력하세요." ;;
                ar) _mt_out="خيار قائمة غير معروف '${_mt_extra}'. اختر رقما من القائمة، أو اكتب اسم الأمر." ;;
                pt) _mt_out="Opção de menu desconhecida '${_mt_extra}'. Escolha um número da lista, ou escreva o nome do comando." ;;
                ru) _mt_out="Неизвестный пункт меню '${_mt_extra}'. Выберите номер из списка или введите имя команды." ;;
                nl) _mt_out="Onbekende menukeuze '${_mt_extra}'. Kies een nummer uit de lijst, of typ de opdrachtnaam." ;;
                el) _mt_out="Άγνωστη επιλογή μενού '${_mt_extra}'. Επιλέξτε αριθμό από τη λίστα ή πληκτρολογήστε το όνομα της εντολής." ;;
                *) _mt_out="Unknown menu choice '${_mt_extra}'. Choose a number from the list, or type the command name." ;;
            esac
            ;;
        unknown_sudoers)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="未知的 sudoers 選項 '${_mt_extra}'。請從清單選擇編號，或輸入指令名稱。" ;;
                es) _mt_out="Opción de sudoers desconocida '${_mt_extra}'. Elija un número de la lista, o escriba el nombre del comando." ;;
                fr) _mt_out="Choix sudoers inconnu '${_mt_extra}'. Choisissez un numéro dans la liste, ou saisissez le nom de la commande." ;;
                de) _mt_out="Unbekannte sudoers-Auswahl '${_mt_extra}'. Wählen Sie eine Nummer aus der Liste, oder geben Sie den Befehlsnamen ein." ;;
                zh-Hans) _mt_out="未知的 sudoers 选项 '${_mt_extra}'。请从清单选择编号，或输入指令名称。" ;;
                ja) _mt_out="未知の sudoers 選択 '${_mt_extra}'。一覧の番号を選ぶか、コマンド名を入力してください。" ;;
                ko) _mt_out="알 수 없는 sudoers 선택 '${_mt_extra}'. 목록의 번호를 고르거나 명령 이름을 입력하세요." ;;
                ar) _mt_out="خيار sudoers غير معروف '${_mt_extra}'. اختر رقما من القائمة، أو اكتب اسم الأمر." ;;
                pt) _mt_out="Opção de sudoers desconhecida '${_mt_extra}'. Escolha um número da lista, ou escreva o nome do comando." ;;
                ru) _mt_out="Неизвестный пункт sudoers '${_mt_extra}'. Выберите номер из списка или введите имя команды." ;;
                nl) _mt_out="Onbekende sudoers-keuze '${_mt_extra}'. Kies een nummer uit de lijst, of typ de opdrachtnaam." ;;
                el) _mt_out="Άγνωστη επιλογή sudoers '${_mt_extra}'. Επιλέξτε αριθμό από τη λίστα ή πληκτρολογήστε το όνομα της εντολής." ;;
                *) _mt_out="Unknown sudoers choice '${_mt_extra}'. Choose a number from the list, or type the command name." ;;
            esac
            ;;
        lang_ja_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用日文" ;;
                es) _mt_out="usar japonés en este menú" ;;
                fr) _mt_out="utiliser le japonais pour ce menu" ;;
                de) _mt_out="Japanisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用日文" ;;
                ja) _mt_out="このメニューを日本語にする" ;;
                ko) _mt_out="이 메뉴를 일본어로" ;;
                ar) _mt_out="استخدام اليابانية لهذه القائمة" ;;
                pt) _mt_out="usar japonês neste menu" ;;
                ru) _mt_out="использовать японский для этого меню" ;;
                nl) _mt_out="Japans voor dit menu gebruiken" ;;
                el) _mt_out="χρήση ιαπωνικών για αυτό το μενού" ;;
                *) _mt_out="use Japanese for this menu" ;;
            esac
            ;;
        lang_ko_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用韓文" ;;
                es) _mt_out="usar coreano en este menú" ;;
                fr) _mt_out="utiliser le coréen pour ce menu" ;;
                de) _mt_out="Koreanisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用韩文" ;;
                ja) _mt_out="このメニューを韓国語にする" ;;
                ko) _mt_out="이 메뉴를 한국어로" ;;
                ar) _mt_out="استخدام الكورية لهذه القائمة" ;;
                pt) _mt_out="usar coreano neste menu" ;;
                ru) _mt_out="использовать корейский для этого меню" ;;
                nl) _mt_out="Koreaans voor dit menu gebruiken" ;;
                el) _mt_out="χρήση κορεατικών για αυτό το μενού" ;;
                *) _mt_out="use Korean for this menu" ;;
            esac
            ;;
        help_short)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="簡化 Termux 安裝 sshd" ;;
                es) _mt_out="simplificar la instalación de sshd en Termux" ;;
                fr) _mt_out="simplifier l'installation de sshd sur Termux" ;;
                de) _mt_out="sshd auf Termux einfach installieren" ;;
                zh-Hans) _mt_out="简化 Termux 安装 sshd" ;;
                ja) _mt_out="Termux で sshd を簡単に導入する" ;;
                ko) _mt_out="Termux에서 sshd 설치를 단순하게" ;;
                ar) _mt_out="تبسيط تثبيت sshd على Termux" ;;
                pt) _mt_out="simplificar a instalação de sshd no Termux" ;;
                ru) _mt_out="упростить установку sshd в Termux" ;;
                nl) _mt_out="sshd installeren op Termux vereenvoudigen" ;;
                el) _mt_out="απλοποίηση εγκατάστασης sshd στο Termux" ;;
                *) _mt_out="Simplify Termux to install sshd" ;;
            esac
            ;;
        help_desc)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="POSIX /bin/sh CLI：簡化 Termux 安裝並執行 OpenSSH sshd（status/start/stop/port/keys/dns），以及 self-install；Linux 主機上 ~/.ssh/config 的存放（backup-config / sync-config / sync-from-remote）。" ;;
                es) _mt_out="CLI POSIX /bin/sh: simplifica instalar y ejecutar OpenSSH sshd en Termux (status/start/stop/port/keys/dns) y self-install; depósito en el host Linux de ~/.ssh/config (backup-config / sync-config / sync-from-remote)." ;;
                fr) _mt_out="CLI POSIX /bin/sh : simplifier l'installation et l'exécution d'OpenSSH sshd sur Termux (status/start/stop/port/keys/dns), plus self-install ; dépôt sur l'hôte Linux de ~/.ssh/config (backup-config / sync-config / sync-from-remote)." ;;
                de) _mt_out="POSIX /bin/sh CLI: OpenSSH sshd auf Termux installieren und starten (status/start/stop/port/keys/dns) sowie self-install; Ablage von ~/.ssh/config auf dem Linux-Host (backup-config / sync-config / sync-from-remote)." ;;
                zh-Hans) _mt_out="POSIX /bin/sh CLI：简化 Termux 安装并运行 OpenSSH sshd（status/start/stop/port/keys/dns），以及 self-install；Linux 主机上 ~/.ssh/config 的存放（backup-config / sync-config / sync-from-remote）。" ;;
                ja) _mt_out="POSIX /bin/sh CLI。Termux で OpenSSH sshd を導入して動かす（status/start/stop/port/keys/dns）ほか self-install。Linux ホストへ ~/.ssh/config を預ける（backup-config / sync-config / sync-from-remote）。" ;;
                ko) _mt_out="POSIX /bin/sh CLI. Termux에서 OpenSSH sshd를 설치하고 실행(status/start/stop/port/keys/dns)하며 self-install. Linux 호스트에 ~/.ssh/config를 맡김(backup-config / sync-config / sync-from-remote)." ;;
                ar) _mt_out="واجهة POSIX /bin/sh: تبسيط تثبيت وتشغيل sshd الخاص بـ OpenSSH على Termux (status/start/stop/port/keys/dns) مع self-install؛ إيداع ~/.ssh/config على مضيف Linux ‏(backup-config / sync-config / sync-from-remote)." ;;
                pt) _mt_out="CLI POSIX /bin/sh: simplificar instalar e executar o sshd OpenSSH no Termux (status/start/stop/port/keys/dns) mais self-install; depósito de ~/.ssh/config no host Linux (backup-config / sync-config / sync-from-remote)." ;;
                ru) _mt_out="CLI на POSIX /bin/sh: упростить установку и запуск sshd OpenSSH в Termux (status/start/stop/port/keys/dns) и self-install; хранение ~/.ssh/config на узле Linux (backup-config / sync-config / sync-from-remote)." ;;
                nl) _mt_out="POSIX /bin/sh CLI: Termux sshd van OpenSSH installeren en starten vereenvoudigen (status/start/stop/port/keys/dns) plus self-install; storting van ~/.ssh/config op een Linux-host (backup-config / sync-config / sync-from-remote)." ;;
                el) _mt_out="CLI POSIX /bin/sh: απλοποίηση εγκατάστασης και εκτέλεσης του sshd OpenSSH στο Termux (status/start/stop/port/keys/dns) και self-install· κατάθεση του ~/.ssh/config σε κεντρικό Linux (backup-config / sync-config / sync-from-remote)." ;;
                *) _mt_out="POSIX /bin/sh CLI: simplify Termux to install and run OpenSSH sshd (status/start/stop/port/keys/dns) plus self-install; Linux host deposit of ~/.ssh/config (backup-config / sync-config / sync-from-remote)." ;;
            esac
            ;;
        help_h_usage)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="用法：" ;;
                es) _mt_out="Uso:" ;;
                fr) _mt_out="Utilisation :" ;;
                de) _mt_out="Verwendung:" ;;
                zh-Hans) _mt_out="用法：" ;;
                ja) _mt_out="使い方:" ;;
                ko) _mt_out="사용법:" ;;
                ar) _mt_out="الاستخدام:" ;;
                pt) _mt_out="Uso:" ;;
                ru) _mt_out="Использование:" ;;
                nl) _mt_out="Gebruik:" ;;
                el) _mt_out="Χρήση:" ;;
                *) _mt_out="Usage:" ;;
            esac
            ;;
        help_usage_args)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="[命令] [選項]" ;;
                es) _mt_out="[comando] [opciones]" ;;
                fr) _mt_out="[commande] [options]" ;;
                de) _mt_out="[Befehl] [Optionen]" ;;
                zh-Hans) _mt_out="[命令] [选项]" ;;
                ja) _mt_out="[コマンド] [オプション]" ;;
                ko) _mt_out="[명령] [옵션]" ;;
                ar) _mt_out="[أمر] [خيارات]" ;;
                pt) _mt_out="[comando] [opções]" ;;
                ru) _mt_out="[команда] [параметры]" ;;
                nl) _mt_out="[opdracht] [opties]" ;;
                el) _mt_out="[εντολή] [επιλογές]" ;;
                *) _mt_out="[command] [options]" ;;
            esac
            ;;
        help_h_self)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="自我管理（這個登入）：" ;;
                es) _mt_out="Autogestión (este inicio):" ;;
                fr) _mt_out="Autogestion (cette session) :" ;;
                de) _mt_out="Selbstverwaltung (diese Anmeldung):" ;;
                zh-Hans) _mt_out="自我管理（这个登录）：" ;;
                ja) _mt_out="自己管理（このログイン）:" ;;
                ko) _mt_out="자기관리(이 로그인):" ;;
                ar) _mt_out="الإدارة الذاتية (هذا الدخول):" ;;
                pt) _mt_out="Autogestão (este login):" ;;
                ru) _mt_out="Самоуправление (этот вход):" ;;
                nl) _mt_out="Zelfbeheer (deze login):" ;;
                el) _mt_out="Αυτοδιαχείριση (αυτή η σύνδεση):" ;;
                *) _mt_out="Self-management (this login):" ;;
            esac
            ;;
        help_self_install)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="只放置這個 CLI（以腳本執行時複製這個檔案；從管線傳入時下載）" ;;
                es) _mt_out="colocar solo este CLI (copiar este archivo si se ejecuta como script; descargar si llega por una tubería)" ;;
                fr) _mt_out="placer seulement ce CLI (copier ce fichier s'il est lancé comme script ; télécharger s'il arrive dans un tube)" ;;
                de) _mt_out="nur dieses CLI ablegen (diese Datei kopieren, wenn sie als Skript läuft; laden, wenn sie in einer Pipe ankommt)" ;;
                zh-Hans) _mt_out="只放置这个 CLI（作为脚本运行时复制这个文件；从管道传入时下载）" ;;
                ja) _mt_out="この CLI だけを配置（スクリプトとして実行したときはこのファイルをコピー、パイプで届いたときは取り込む）" ;;
                ko) _mt_out="이 CLI만 배치(스크립트로 실행하면 이 파일을 복사, 파이프로 오면 가져오기)" ;;
                ar) _mt_out="وضع هذا CLI فقط (نسخ هذا الملف عند التشغيل كسكربت؛ تنزيل عند التوجيه)" ;;
                pt) _mt_out="Colocar só este CLI (copiar este arquivo quando executado como script; baixar quando canalizado)" ;;
                ru) _mt_out="Разместить только этот CLI (копировать этот файл при запуске как скрипт; загрузить по каналу)" ;;
                nl) _mt_out="Plaats alleen deze CLI (kopieer dit bestand bij uitvoering als script; download bij een pipe)" ;;
                el) _mt_out="Τοποθέτηση μόνο αυτού του CLI (αντιγραφή αυτού του αρχείου ως σενάριο· λήψη σε διοχέτευση)" ;;
                *) _mt_out="Place this CLI only (copy this file when run as a script; download when piped)" ;;
            esac
            ;;
        help_install)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="確保 rc 與 Termux 的 openssh/termux-auth；啟動 sshd（payload）" ;;
                es) _mt_out="asegurar rc y openssh/termux-auth de Termux; iniciar sshd (payload)" ;;
                fr) _mt_out="assurer rc et openssh/termux-auth de Termux ; lancer sshd (payload)" ;;
                de) _mt_out="rc und Termux openssh/termux-auth sicherstellen; sshd starten (Nutzlast)" ;;
                zh-Hans) _mt_out="确保 rc 与 Termux 的 openssh/termux-auth；启动 sshd（payload）" ;;
                ja) _mt_out="rc と Termux の openssh/termux-auth を整えて sshd を起動（payload）" ;;
                ko) _mt_out="rc와 Termux openssh/termux-auth를 확보하고 sshd 시작(payload)" ;;
                ar) _mt_out="تأكد من rc وopenssh/termux-auth في Termux؛ ابدأ sshd (الحمولة)" ;;
                pt) _mt_out="Garantir rc + openssh/termux-auth no Termux; iniciar sshd (carga)" ;;
                ru) _mt_out="Обеспечить rc + openssh/termux-auth в Termux; запустить sshd (нагрузка)" ;;
                nl) _mt_out="Zorg voor rc + Termux openssh/termux-auth; start sshd (lading)" ;;
                el) _mt_out="Διασφάλιση rc + openssh/termux-auth στο Termux· εκκίνηση sshd (φορτίο)" ;;
                *) _mt_out="Ensure rc + Termux openssh/termux-auth; start sshd (payload)" ;;
            esac
            ;;
        help_version)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="顯示目前版本（TTY 選單 62 會執行 about）" ;;
                es) _mt_out="mostrar la versión actual (el menú TTY 62 ejecuta about)" ;;
                fr) _mt_out="afficher la version actuelle (le menu TTY 62 lance about)" ;;
                de) _mt_out="aktuelle Version anzeigen (TTY-Menü 62 führt about aus)" ;;
                zh-Hans) _mt_out="显示当前版本（TTY 菜单 62 会运行 about）" ;;
                ja) _mt_out="現在のバージョンを表示（TTY メニュー 62 は about を実行）" ;;
                ko) _mt_out="현재 버전 표시(TTY 메뉴 62는 about 실행)" ;;
                ar) _mt_out="عرض الإصدار الحالي (القائمة 62 على TTY تشغل about)" ;;
                pt) _mt_out="Mostrar a versão atual (o menu TTY 62 executa about)" ;;
                ru) _mt_out="Показать текущую версию (пункт TTY 62 запускает about)" ;;
                nl) _mt_out="Toon de huidige versie (TTY-menu 62 voert about uit)" ;;
                el) _mt_out="Εμφάνιση τρέχουσας έκδοσης (το μενού TTY 62 εκτελεί about)" ;;
                *) _mt_out="Show current version (TTY menu 62 runs about)" ;;
            esac
            ;;
        help_about)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="顯示詳細診斷" ;;
                es) _mt_out="mostrar el diagnóstico detallado" ;;
                fr) _mt_out="afficher le diagnostic détaillé" ;;
                de) _mt_out="ausführliche Diagnose anzeigen" ;;
                zh-Hans) _mt_out="显示详细诊断" ;;
                ja) _mt_out="詳細な診断を表示" ;;
                ko) _mt_out="자세한 진단 표시" ;;
                ar) _mt_out="عرض التشخيص المفصل" ;;
                pt) _mt_out="Mostrar o diagnóstico detalhado" ;;
                ru) _mt_out="Показать подробную диагностику" ;;
                nl) _mt_out="Toon uitgebreide diagnostiek" ;;
                el) _mt_out="Εμφάνιση λεπτομερούς διάγνωσης" ;;
                *) _mt_out="Show detailed diagnostics" ;;
            esac
            ;;
        help_version_check)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="比較本機與遠端版本（需要 SCRIPT_URL）" ;;
                es) _mt_out="comparar la versión local con la remota (hace falta SCRIPT_URL)" ;;
                fr) _mt_out="comparer la version locale et la version distante (SCRIPT_URL requis)" ;;
                de) _mt_out="lokale und ferne Version vergleichen (SCRIPT_URL nötig)" ;;
                zh-Hans) _mt_out="比较本机与远程版本（需要 SCRIPT_URL）" ;;
                ja) _mt_out="ローカルと遠隔のバージョンを比較（SCRIPT_URL が必要）" ;;
                ko) _mt_out="로컬과 원격 버전 비교(SCRIPT_URL 필요)" ;;
                ar) _mt_out="قارن الإصدار المحلي بالبعيد (يحتاج SCRIPT_URL)" ;;
                pt) _mt_out="Comparar a versão local com a remota (precisa de SCRIPT_URL)" ;;
                ru) _mt_out="Сравнить локальную и удалённую версию (нужен SCRIPT_URL)" ;;
                nl) _mt_out="Vergelijk lokale en externe versie (vereist SCRIPT_URL)" ;;
                el) _mt_out="Σύγκριση τοπικής και απομακρυσμένης έκδοσης (χρειάζεται SCRIPT_URL)" ;;
                *) _mt_out="Compare local vs remote version (needs SCRIPT_URL)" ;;
            esac
            ;;
        help_self_update)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="將 ${APP_NAME} 更新到較新的遠端版本" ;;
                es) _mt_out="actualizar ${APP_NAME} a una versión remota más nueva" ;;
                fr) _mt_out="mettre ${APP_NAME} à jour vers une version distante plus récente" ;;
                de) _mt_out="${APP_NAME} auf eine neuere ferne Version aktualisieren" ;;
                zh-Hans) _mt_out="将 ${APP_NAME} 更新到较新的远程版本" ;;
                ja) _mt_out="${APP_NAME} を新しい遠隔バージョンへ更新" ;;
                ko) _mt_out="${APP_NAME}를 더 새로운 원격 버전으로 업데이트" ;;
                ar) _mt_out="تحديث ${APP_NAME} إلى إصدار بعيد أحدث" ;;
                pt) _mt_out="Atualizar ${APP_NAME} para uma versão remota mais nova" ;;
                ru) _mt_out="Обновить ${APP_NAME} до более новой удалённой версии" ;;
                nl) _mt_out="Werk ${APP_NAME} bij naar een nieuwere externe versie" ;;
                el) _mt_out="Ενημέρωση ${APP_NAME} σε νεότερη απομακρυσμένη έκδοση" ;;
                *) _mt_out="Update ${APP_NAME} to a newer remote version" ;;
            esac
            ;;
        help_self_uninstall)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="移除 ${APP_NAME}（安全清理 PATH）" ;;
                es) _mt_out="quitar ${APP_NAME} (limpieza segura de PATH)" ;;
                fr) _mt_out="retirer ${APP_NAME} (nettoyage sûr de PATH)" ;;
                de) _mt_out="${APP_NAME} entfernen (sicheres Aufräumen von PATH)" ;;
                zh-Hans) _mt_out="移除 ${APP_NAME}（安全清理 PATH）" ;;
                ja) _mt_out="${APP_NAME} を削除（PATH を安全に整理）" ;;
                ko) _mt_out="${APP_NAME} 제거(PATH를 안전하게 정리)" ;;
                ar) _mt_out="إزالة ${APP_NAME} (تنظيف PATH بأمان)" ;;
                pt) _mt_out="Remover ${APP_NAME} (limpeza segura do PATH)" ;;
                ru) _mt_out="Удалить ${APP_NAME} (безопасная очистка PATH)" ;;
                nl) _mt_out="Verwijder ${APP_NAME} (veilige PATH-opruiming)" ;;
                el) _mt_out="Αφαίρεση ${APP_NAME} (ασφαλής καθαρισμός του PATH)" ;;
                *) _mt_out="Remove ${APP_NAME} (safe PATH cleanup)" ;;
            esac
            ;;
        help_help)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="顯示這份說明" ;;
                es) _mt_out="mostrar esta ayuda" ;;
                fr) _mt_out="afficher cette aide" ;;
                de) _mt_out="diese Hilfe anzeigen" ;;
                zh-Hans) _mt_out="显示这份说明" ;;
                ja) _mt_out="この説明を表示" ;;
                ko) _mt_out="이 도움말 표시" ;;
                ar) _mt_out="عرض هذه المساعدة" ;;
                pt) _mt_out="Mostrar esta ajuda" ;;
                ru) _mt_out="Показать эту справку" ;;
                nl) _mt_out="Toon deze help" ;;
                el) _mt_out="Εμφάνιση αυτής της βοήθειας" ;;
                *) _mt_out="Show this help" ;;
            esac
            ;;
        help_h_domain)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="網域指令（OpenSSH sshd）：" ;;
                es) _mt_out="Comandos de dominio (OpenSSH sshd):" ;;
                fr) _mt_out="Commandes du domaine (OpenSSH sshd) :" ;;
                de) _mt_out="Domänenbefehle (OpenSSH sshd):" ;;
                zh-Hans) _mt_out="领域命令（OpenSSH sshd）：" ;;
                ja) _mt_out="ドメインコマンド（OpenSSH sshd）:" ;;
                ko) _mt_out="도메인 명령(OpenSSH sshd):" ;;
                ar) _mt_out="أوامر النطاق (OpenSSH sshd):" ;;
                pt) _mt_out="Comandos de domínio (OpenSSH sshd):" ;;
                ru) _mt_out="Команды области (OpenSSH sshd):" ;;
                nl) _mt_out="Domeinopdrachten (OpenSSH sshd):" ;;
                el) _mt_out="Εντολές τομέα (OpenSSH sshd):" ;;
                *) _mt_out="Domain commands (OpenSSH sshd):" ;;
            esac
            ;;
        help_status)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="顯示 sshd 是否在執行，以及連接埠與路徑（Linux systemd：單元名稱與 active）" ;;
                es) _mt_out="mostrar si sshd está en ejecución, y el puerto/rutas (Linux systemd: nombre de la unidad + active)" ;;
                fr) _mt_out="afficher si sshd tourne, ainsi que le port et les chemins (Linux systemd : nom de l'unité + active)" ;;
                de) _mt_out="zeigen, ob sshd läuft, sowie Port und Pfade (Linux systemd: Unit-Name + active)" ;;
                zh-Hans) _mt_out="显示 sshd 是否在运行，以及端口与路径（Linux systemd：单元名称与 active）" ;;
                ja) _mt_out="sshd が動いているか、ポートとパスを表示（Linux systemd: ユニット名と active）" ;;
                ko) _mt_out="sshd 실행 여부와 포트/경로 표시(Linux systemd: 유닛 이름과 active)" ;;
                ar) _mt_out="إظهار هل sshd يعمل، والمنفذ/المسارات (systemd على Linux: اسم الوحدة + active)" ;;
                pt) _mt_out="Mostrar se o sshd está em execução, e a porta/caminhos (systemd no Linux: nome da unidade + active)" ;;
                ru) _mt_out="Показать, работает ли sshd, порт и пути (systemd в Linux: имя юнита + active)" ;;
                nl) _mt_out="Toon of sshd actief is, en de poort/paden (Linux systemd: unitnaam + active)" ;;
                el) _mt_out="Εμφάνιση αν το sshd εκτελείται, και θύρα/διαδρομές (systemd σε Linux: όνομα μονάδας + active)" ;;
                *) _mt_out="Show whether sshd is running, and the port/paths (Linux systemd: unit name + active)" ;;
            esac
            ;;
        help_start)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="啟動 sshd：Termux／沒有單元的 Linux = 背景常駐程式（sshd -f）；Linux 發行版單元 = 以 root 執行 systemctl start" ;;
                es) _mt_out="iniciar sshd: Termux / Linux sin unidad = demonio en segundo plano (sshd -f); unidad de la distro = systemctl start como root" ;;
                fr) _mt_out="lancer sshd : Termux / Linux sans unité = démon en arrière-plan (sshd -f) ; unité de la distribution = systemctl start en root" ;;
                de) _mt_out="sshd starten: Termux / Linux ohne Unit = Daemon im Hintergrund (sshd -f); Distro-Unit = systemctl start als root" ;;
                zh-Hans) _mt_out="启动 sshd：Termux／没有单元的 Linux = 后台常驻程序（sshd -f）；Linux 发行版单元 = 以 root 执行 systemctl start" ;;
                ja) _mt_out="sshd を起動：Termux／ユニットのない Linux = バックグラウンドのデーモン（sshd -f）；ディストロのユニット = root で systemctl start" ;;
                ko) _mt_out="sshd 시작: Termux / 유닛 없는 Linux = 백그라운드 데몬(sshd -f); 배포판 유닛 = root로 systemctl start" ;;
                ar) _mt_out="بدء sshd: Termux / Linux بلا وحدة = خدمة خلفية (sshd -f)؛ وحدة توزيعة Linux = systemctl start كـ root" ;;
                pt) _mt_out="Iniciar sshd: Termux / Linux sem unidade = daemon em segundo plano (sshd -f); unidade de distro Linux = systemctl start como root" ;;
                ru) _mt_out="Запустить sshd: Termux / Linux без юнита = фоновый демон (sshd -f); юнит дистрибутива Linux = systemctl start от root" ;;
                nl) _mt_out="Start sshd: Termux / Linux zonder unit = achtergronddaemon (sshd -f); Linux-distro-unit = systemctl start als root" ;;
                el) _mt_out="Εκκίνηση sshd: Termux / Linux χωρίς μονάδα = δαίμονας στο παρασκήνιο (sshd -f)· μονάδα διανομής Linux = systemctl start ως root" ;;
                *) _mt_out="Start sshd: Termux / no-unit Linux = background daemon (sshd -f); Linux distro unit = systemctl start as root" ;;
            esac
            ;;
        help_stop)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="停止 sshd（有發行版單元時用 systemctl stop）" ;;
                es) _mt_out="detener sshd (systemctl stop si existe una unidad de la distro)" ;;
                fr) _mt_out="arrêter sshd (systemctl stop si une unité de la distribution existe)" ;;
                de) _mt_out="sshd stoppen (systemctl stop, wenn eine Distro-Unit existiert)" ;;
                zh-Hans) _mt_out="停止 sshd（有发行版单元时用 systemctl stop）" ;;
                ja) _mt_out="sshd を停止（ディストロのユニットがあるときは systemctl stop）" ;;
                ko) _mt_out="sshd 중지(배포판 유닛이 있으면 systemctl stop)" ;;
                ar) _mt_out="إيقاف sshd ‏(systemctl stop عند وجود وحدة توزيعة)" ;;
                pt) _mt_out="Parar sshd (systemctl stop quando existe uma unidade de distro)" ;;
                ru) _mt_out="Остановить sshd (systemctl stop, если есть юнит дистрибутива)" ;;
                nl) _mt_out="Stop sshd (systemctl stop als er een distro-unit is)" ;;
                el) _mt_out="Διακοπή sshd (systemctl stop όταν υπάρχει μονάδα διανομής)" ;;
                *) _mt_out="Stop sshd (systemctl stop when a distro unit exists)" ;;
            esac
            ;;
        help_restart)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="重新啟動 sshd（有發行版單元時用 systemctl restart；否則先停止再啟動）" ;;
                es) _mt_out="reiniciar sshd (systemctl restart si existe una unidad; si no, detener y luego iniciar)" ;;
                fr) _mt_out="relancer sshd (systemctl restart si une unité existe ; sinon arrêter puis lancer)" ;;
                de) _mt_out="sshd neu starten (systemctl restart, wenn eine Unit existiert; sonst stoppen und dann starten)" ;;
                zh-Hans) _mt_out="重新启动 sshd（有发行版单元时用 systemctl restart；否则先停止再启动）" ;;
                ja) _mt_out="sshd を再起動（ユニットがあるときは systemctl restart、なければ停止してから起動）" ;;
                ko) _mt_out="sshd 다시 시작(유닛이 있으면 systemctl restart, 없으면 중지 후 시작)" ;;
                ar) _mt_out="إعادة تشغيل sshd ‏(systemctl restart عند وجود وحدة؛ وإلا إيقاف ثم تشغيل)" ;;
                pt) _mt_out="Reiniciar sshd (systemctl restart quando existe uma unidade; senão parar e iniciar)" ;;
                ru) _mt_out="Перезапустить sshd (systemctl restart при наличии юнита; иначе остановить и запустить)" ;;
                nl) _mt_out="Herstart sshd (systemctl restart als er een unit is; anders stoppen en starten)" ;;
                el) _mt_out="Επανεκκίνηση sshd (systemctl restart όταν υπάρχει μονάδα· αλλιώς διακοπή και εκκίνηση)" ;;
                *) _mt_out="Restart sshd (systemctl restart when a distro unit exists; else stop then start)" ;;
            esac
            ;;
        help_port)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="顯示或設定 sshd_config 的聽候 Port" ;;
                es) _mt_out="mostrar o fijar el Port de escucha en sshd_config" ;;
                fr) _mt_out="afficher ou régler le Port d'écoute dans sshd_config" ;;
                de) _mt_out="Port zum Warten in sshd_config anzeigen oder setzen" ;;
                zh-Hans) _mt_out="显示或设置 sshd_config 里的监听 Port" ;;
                ja) _mt_out="sshd_config の待ち受け Port を表示または設定" ;;
                ko) _mt_out="sshd_config의 수신 Port를 표시하거나 설정" ;;
                ar) _mt_out="عرض أو ضبط منفذ الاستماع Port في sshd_config" ;;
                pt) _mt_out="Mostrar ou definir a porta de escuta Port em sshd_config" ;;
                ru) _mt_out="Показать или задать порт прослушивания Port в sshd_config" ;;
                nl) _mt_out="Toon of stel de luisterpoort Port in sshd_config in" ;;
                el) _mt_out="Εμφάνιση ή ορισμός της θύρας ακρόασης Port στο sshd_config" ;;
                *) _mt_out="Show or set the listen Port in sshd_config" ;;
            esac
            ;;
        help_config)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="顯示解析後的 sshd 路徑與重要設定" ;;
                es) _mt_out="mostrar las rutas resueltas de sshd y los ajustes principales" ;;
                fr) _mt_out="afficher les chemins sshd résolus et les réglages principaux" ;;
                de) _mt_out="aufgelöste sshd-Pfade und wichtige Einstellungen anzeigen" ;;
                zh-Hans) _mt_out="显示解析后的 sshd 路径与重要设置" ;;
                ja) _mt_out="解決済みの sshd パスと主要な設定を表示" ;;
                ko) _mt_out="해석된 sshd 경로와 주요 설정 표시" ;;
                ar) _mt_out="عرض مسارات sshd المحلولة والإعدادات الأساسية" ;;
                pt) _mt_out="Mostrar os caminhos resolvidos do sshd e as definições principais" ;;
                ru) _mt_out="Показать разрешённые пути sshd и основные параметры" ;;
                nl) _mt_out="Toon de opgeloste sshd-paden en de belangrijkste instellingen" ;;
                el) _mt_out="Εμφάνιση επιλυμένων διαδρομών sshd και βασικών ρυθμίσεων" ;;
                *) _mt_out="Show resolved sshd paths and key settings" ;;
            esac
            ;;
        help_host_keys)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="列出或建立主機金鑰" ;;
                es) _mt_out="listar o crear claves de host" ;;
                fr) _mt_out="lister ou créer les clés d'hôte" ;;
                de) _mt_out="Host-Schlüssel auflisten oder anlegen" ;;
                zh-Hans) _mt_out="列出或建立主机密钥" ;;
                ja) _mt_out="ホスト鍵を一覧または作成" ;;
                ko) _mt_out="호스트 키를 나열하거나 만들기" ;;
                ar) _mt_out="عرض مفاتيح المضيف أو إنشاؤها" ;;
                pt) _mt_out="Listar ou criar chaves de anfitrião" ;;
                ru) _mt_out="Показать или создать ключи узла" ;;
                nl) _mt_out="Toon of maak hostsleutels" ;;
                el) _mt_out="Εμφάνιση ή δημιουργία κλειδιών υπολογιστή" ;;
                *) _mt_out="List or create host keys" ;;
            esac
            ;;
        help_auth_keys)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個登入的 authorized_keys" ;;
                es) _mt_out="authorized_keys de este inicio" ;;
                fr) _mt_out="authorized_keys de cette session" ;;
                de) _mt_out="authorized_keys dieser Anmeldung" ;;
                zh-Hans) _mt_out="这个登录的 authorized_keys" ;;
                ja) _mt_out="このログインの authorized_keys" ;;
                ko) _mt_out="이 로그인의 authorized_keys" ;;
                ar) _mt_out="authorized_keys لهذا الدخول" ;;
                pt) _mt_out="authorized_keys deste login" ;;
                ru) _mt_out="authorized_keys этого входа" ;;
                nl) _mt_out="authorized_keys van deze login" ;;
                el) _mt_out="authorized_keys αυτής της σύνδεσης" ;;
                *) _mt_out="This login authorized_keys" ;;
            esac
            ;;
        help_fix_config)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="依這個作業系統，把 OpenSSH 用戶端設定檔裡不支援的關鍵字改成註解。可加 --input-file 與 --output-file。" ;;
                es) _mt_out="Comenta en el config del cliente OpenSSH las palabras que este sistema no admite. Opcional --input-file y --output-file." ;;
                fr) _mt_out="Met en commentaire les mots OpenSSH que ce système n'accepte pas dans le fichier client. --input-file et --output-file sont facultatifs." ;;
                de) _mt_out="Kommentiert OpenSSH-Client-Schlüssel, die dieses System nicht kennt, in der Client-Datei. --input-file und --output-file sind optional." ;;
                zh-Hans) _mt_out="按这个操作系统，把 OpenSSH 客户端配置文件里不支持的关键字改成注释。可加 --input-file 与 --output-file。" ;;
                ja) _mt_out="この OS が受け付けない OpenSSH クライアント設定の語をコメントにする。--input-file と --output-file は任意。" ;;
                ko) _mt_out="이 OS가 받지 않는 OpenSSH 클라이언트 설정의 낱말을 주석으로 바꿈. --input-file 과 --output-file 은 선택." ;;
                ar) _mt_out="تعليق كلمات عميل OpenSSH التي لا يدعمها هذا النظام في إعداد العميل. --input-file و--output-file اختياريان." ;;
                pt) _mt_out="Comentar palavras do cliente OpenSSH que este SO não suporta na config do cliente. --input-file e --output-file opcionais." ;;
                ru) _mt_out="Закомментировать ключевые слова клиента OpenSSH, которые эта ОС не поддерживает. Необязательные --input-file и --output-file." ;;
                nl) _mt_out="Zet OpenSSH-clienttrefwoorden die dit OS niet ondersteunt als commentaar in de clientconfig. Optioneel --input-file en --output-file." ;;
                el) _mt_out="Σχολιασμός λέξεων-κλειδιών πελάτη OpenSSH που αυτό το OS δεν υποστηρίζει. Προαιρετικά --input-file και --output-file." ;;
                *) _mt_out="Comment OpenSSH client keywords this OS does not support in the client config. Optional --input-file and --output-file." ;;
            esac
            ;;
        help_dns)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個登入的 ~/.ssh/config Host 清單（dns-ip；as Termux / identity-file / Old OpenSSH；unset 只去掉額外設定，不去掉 dns 或 ip）" ;;
                es) _mt_out="lista Host de ~/.ssh/config de este inicio (dns-ip; as Termux / identity-file / Old OpenSSH; unset quita ajustes extra, no dns ni ip)" ;;
                fr) _mt_out="liste Host de ~/.ssh/config pour cette session (dns-ip ; as Termux / identity-file / Old OpenSSH ; unset retire les réglages en plus, pas dns ni ip)" ;;
                de) _mt_out="Host-Liste in ~/.ssh/config dieser Anmeldung (dns-ip; as Termux / identity-file / Old OpenSSH; unset entfernt Zusatz, nicht dns oder ip)" ;;
                zh-Hans) _mt_out="这个登录的 ~/.ssh/config Host 清单（dns-ip；as Termux / identity-file / Old OpenSSH；unset 只去掉额外设置，不去掉 dns 或 ip）" ;;
                ja) _mt_out="このログインの ~/.ssh/config の Host 一覧（dns-ip、as Termux / identity-file / Old OpenSSH。unset は追加設定だけを外し、dns と ip は残す）" ;;
                ko) _mt_out="이 로그인의 ~/.ssh/config Host 목록(dns-ip, as Termux / identity-file / Old OpenSSH. unset은 추가 설정만 지우고 dns와 ip는 남김)" ;;
                ar) _mt_out="قائمة Host في ~/.ssh/config لهذا الدخول (dns-ip؛ as Termux / identity-file / Old OpenSSH؛ unset يسقط الإعدادات الإضافية، لا dns أو ip)" ;;
                pt) _mt_out="Lista de Host em ~/.ssh/config deste login (dns-ip; as Termux / identity-file / Old OpenSSH; unset remove ajustes extras, não dns nem ip)" ;;
                ru) _mt_out="Список Host в ~/.ssh/config этого входа (dns-ip; as Termux / identity-file / Old OpenSSH; unset снимает доп. параметры, не dns и не ip)" ;;
                nl) _mt_out="Host-lijst in ~/.ssh/config van deze login (dns-ip; as Termux / identity-file / Old OpenSSH; unset laat extra instellingen vallen, niet dns of ip)" ;;
                el) _mt_out="Λίστα Host στο ~/.ssh/config αυτής της σύνδεσης (dns-ip· as Termux / identity-file / Old OpenSSH· το unset αφαιρεί επιπλέον ρυθμίσεις, όχι dns ή ip)" ;;
                *) _mt_out="This login ~/.ssh/config Host list (dns-ip; as Termux / identity-file / Old OpenSSH; unset drops extra settings, not dns or ip)" ;;
            esac
            ;;
        help_ssh)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="以這個登入的 ~/.ssh/config 對 Host 開 OpenSSH 用戶端（TTY：先選編號，再選使用者與預設；註解的 HostKeyAlgorithms 會加上 -o HostKeyAlgorithms=+ssh-rsa）" ;;
                es) _mt_out="cliente OpenSSH hacia un Host de ~/.ssh/config de este inicio (TTY: elección numerada, luego usuario con predeterminado; HostKeyAlgorithms comentado pasa -o HostKeyAlgorithms=+ssh-rsa)" ;;
                fr) _mt_out="client OpenSSH vers un Host du ~/.ssh/config de cette session (TTY : choix numéroté, puis utilisateur avec défaut ; HostKeyAlgorithms en commentaire passe -o HostKeyAlgorithms=+ssh-rsa)" ;;
                de) _mt_out="OpenSSH-Client zu einem Host aus ~/.ssh/config dieser Anmeldung (TTY: nummerierte Wahl, dann Benutzer mit Vorgabe; kommentiertes HostKeyAlgorithms gibt -o HostKeyAlgorithms=+ssh-rsa)" ;;
                zh-Hans) _mt_out="用这个登录的 ~/.ssh/config 对 Host 打开 OpenSSH 客户端（TTY：先选编号，再选用户与默认；注释的 HostKeyAlgorithms 会加上 -o HostKeyAlgorithms=+ssh-rsa）" ;;
                ja) _mt_out="このログインの ~/.ssh/config の Host へ OpenSSH クライアント（TTY：番号で選び、次に既定つきのユーザー。コメントの HostKeyAlgorithms は -o HostKeyAlgorithms=+ssh-rsa を渡す）" ;;
                ko) _mt_out="이 로그인의 ~/.ssh/config Host로 OpenSSH 클라이언트(TTY: 번호로 고른 뒤 기본값이 있는 사용자. 주석 처리된 HostKeyAlgorithms는 -o HostKeyAlgorithms=+ssh-rsa 를 넘김)" ;;
                ar) _mt_out="عميل OpenSSH إلى Host من ~/.ssh/config لهذا الدخول (TTY: اختيار مرقم ثم المستخدم مع الافتراضي؛ HostKeyAlgorithms المعلق يمرر -o HostKeyAlgorithms=+ssh-rsa)" ;;
                pt) _mt_out="Cliente OpenSSH para um Host de ~/.ssh/config deste login (TTY: escolha numerada, depois o usuário com o padrão; HostKeyAlgorithms comentado passa -o HostKeyAlgorithms=+ssh-rsa)" ;;
                ru) _mt_out="Клиент OpenSSH к Host из ~/.ssh/config этого входа (TTY: номер, затем пользователь со значением по умолчанию; закомментированный HostKeyAlgorithms передаёт -o HostKeyAlgorithms=+ssh-rsa)" ;;
                nl) _mt_out="OpenSSH-client naar een Host uit ~/.ssh/config van deze login (TTY: genummerde keuze, daarna gebruiker met standaard; becommentarieerd HostKeyAlgorithms geeft -o HostKeyAlgorithms=+ssh-rsa)" ;;
                el) _mt_out="Πελάτης OpenSSH προς Host από το ~/.ssh/config αυτής της σύνδεσης (TTY: αριθμημένη επιλογή, έπειτα χρήστης με προεπιλογή· σχολιασμένο HostKeyAlgorithms περνά -o HostKeyAlgorithms=+ssh-rsa)" ;;
                *) _mt_out="OpenSSH client to a Host from this login ~/.ssh/config (TTY: numbered pick, then user with default; commented HostKeyAlgorithms passes -o HostKeyAlgorithms=+ssh-rsa)" ;;
            esac
            ;;
        help_download)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="透過 ssh 把遠端資料夾打成 tar.gz 並在這裡解開（TTY：選 Host，再選使用者與預設，再選先前的編號資料夾或輸入路徑；可用 ~/folder）" ;;
                es) _mt_out="tar.gz de una carpeta remota por ssh y extraerla aquí (TTY: elegir Host, luego usuario con predeterminado, luego carpetas anteriores numeradas o escribir una ruta; ~/folder permitido)" ;;
                fr) _mt_out="tar.gz d'un dossier distant via ssh et l'extraire ici (TTY : choisir un Host, puis l'utilisateur avec défaut, puis les dossiers précédents numérotés ou saisir un chemin ; ~/folder permis)" ;;
                de) _mt_out="einen fernen Ordner per ssh als tar.gz holen und hier entpacken (TTY: Host wählen, dann Benutzer mit Vorgabe, dann nummerierte bisherige Ordner oder einen Pfad tippen; ~/folder erlaubt)" ;;
                zh-Hans) _mt_out="通过 ssh 把远程文件夹打成 tar.gz 并在这里解开（TTY：选 Host，再选用户与默认，再选先前的编号文件夹或输入路径；可用 ~/folder）" ;;
                ja) _mt_out="ssh 経由で遠隔フォルダを tar.gz にしてここで展開（TTY：Host を選び、次に既定つきのユーザー、次に過去の番号付きフォルダかパス。~/folder 可）" ;;
                ko) _mt_out="ssh로 원격 폴더를 tar.gz로 받아 여기서 풀기(TTY: Host를 고르고, 기본값이 있는 사용자를 고른 뒤, 이전 번호 폴더를 고르거나 경로 입력. ~/folder 가능)" ;;
                ar) _mt_out="حزم مجلدا بعيدا عبر ssh كـ tar.gz وفكّه هنا (TTY: اختر Host ثم المستخدم مع الافتراضي ثم مجلدات سابقة مرقمة أو اكتب مسارا؛ ~/folder مسموح)" ;;
                pt) _mt_out="tar.gz de uma pasta remota via ssh e extração aqui (TTY: escolha o Host, depois o usuário com o padrão, depois pastas anteriores numeradas ou digite um caminho; ~/folder é permitido)" ;;
                ru) _mt_out="tar.gz удалённой папки по ssh и распаковка здесь (TTY: выбор Host, затем пользователь по умолчанию, затем прежние папки по номеру или ввод пути; ~/folder допустим)" ;;
                nl) _mt_out="tar.gz van een externe map via ssh en hier uitpakken (TTY: kies Host, dan gebruiker met standaard, dan genummerde eerdere mappen of typ een pad; ~/folder mag)" ;;
                el) _mt_out="tar.gz απομακρυσμένου φακέλου μέσω ssh και εξαγωγή εδώ (TTY: επιλογή Host, έπειτα χρήστης με προεπιλογή, έπειτα αριθμημένοι προηγούμενοι φάκελοι ή πληκτρολόγηση διαδρομής· το ~/folder επιτρέπεται)" ;;
                *) _mt_out="tar.gz a remote folder over ssh and extract it here (TTY: pick Host, then user with default, then numbered previous folders or type a path; ~/folder allowed)" ;;
            esac
            ;;
        help_upload)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="透過 ssh 把本機資料夾打成 tar.gz 並在遠端登入的家目錄解開（TTY：選 Host，再選使用者與預設，再選先前的本機編號資料夾或輸入路徑；~/folder 是這個登入）" ;;
                es) _mt_out="tar.gz de una carpeta local por ssh y extraerla en el home del inicio remoto (TTY: elegir Host, luego usuario con predeterminado, luego carpetas locales anteriores o escribir una ruta; ~/folder es este inicio)" ;;
                fr) _mt_out="tar.gz d'un dossier local via ssh et l'extraire dans le home de la session distante (TTY : choisir un Host, puis l'utilisateur avec défaut, puis les dossiers locaux précédents ou saisir un chemin ; ~/folder est cette session)" ;;
                de) _mt_out="einen lokalen Ordner per ssh als tar.gz legen und im Home der fernen Anmeldung entpacken (TTY: Host wählen, dann Benutzer mit Vorgabe, dann bisherige lokale Ordner oder einen Pfad; ~/folder ist diese Anmeldung)" ;;
                zh-Hans) _mt_out="通过 ssh 把本机文件夹打成 tar.gz 并在远程登录的主目录解开（TTY：选 Host，再选用户与默认，再选先前的本机编号文件夹或输入路径；~/folder 是这个登录）" ;;
                ja) _mt_out="ssh 経由でローカルフォルダを tar.gz にして遠隔ログインのホームで展開（TTY：Host、次に既定つきのユーザー、次に過去のローカルフォルダかパス。~/folder はこのログイン）" ;;
                ko) _mt_out="ssh로 로컬 폴더를 tar.gz로 보내 원격 로그인 홈에서 풀기(TTY: Host, 기본값이 있는 사용자, 이전 로컬 폴더 또는 경로. ~/folder는 이 로그인)" ;;
                ar) _mt_out="حزم مجلدا محليا عبر ssh كـ tar.gz وفكّه تحت منزل الدخول البعيد (TTY: اختر Host ثم المستخدم مع الافتراضي ثم مجلدات محلية سابقة أو اكتب مسارا؛ ~/folder هو هذا الدخول)" ;;
                pt) _mt_out="tar.gz de uma pasta local via ssh e extração no home do login remoto (TTY: escolha o Host, depois o usuário com o padrão, depois pastas locais anteriores numeradas ou digite um caminho; ~/folder é este login)" ;;
                ru) _mt_out="tar.gz локальной папки по ssh и распаковка в домашнем каталоге удалённого входа (TTY: выбор Host, затем пользователь по умолчанию, затем прежние локальные папки или ввод пути; ~/folder — этот вход)" ;;
                nl) _mt_out="tar.gz van een lokale map via ssh en uitpakken in de home van de externe login (TTY: kies Host, dan gebruiker met standaard, dan genummerde eerdere lokale mappen of typ een pad; ~/folder is deze login)" ;;
                el) _mt_out="tar.gz τοπικού φακέλου μέσω ssh και εξαγωγή στον αρχικό κατάλογο της απομακρυσμένης σύνδεσης (TTY: επιλογή Host, έπειτα χρήστης με προεπιλογή, έπειτα αριθμημένοι προηγούμενοι τοπικοί φάκελοι ή πληκτρολόγηση διαδρομής· το ~/folder είναι αυτή η σύνδεση)" ;;
                *) _mt_out="tar.gz a local folder over ssh and extract it under the remote login home (TTY: pick Host, then user with default, then numbered previous local folders or type a path; ~/folder is this login)" ;;
            esac
            ;;
        help_backup)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="把這個登入的 ~/.ssh/config 複製到 /var/sshd-cli（sudoer-adm 之後可免密碼 sudo sshd-cli backup-config）" ;;
                es) _mt_out="copiar ~/.ssh/config de este inicio a /var/sshd-cli (sudo sin contraseña sshd-cli backup-config tras sudoer-adm)" ;;
                fr) _mt_out="copier le ~/.ssh/config de cette session vers /var/sshd-cli (sudo sans mot de passe sshd-cli backup-config après sudoer-adm)" ;;
                de) _mt_out="~/.ssh/config dieser Anmeldung nach /var/sshd-cli kopieren (passwortloses sudo sshd-cli backup-config nach sudoer-adm)" ;;
                zh-Hans) _mt_out="把这个登录的 ~/.ssh/config 复制到 /var/sshd-cli（sudoer-adm 之后可免密码 sudo sshd-cli backup-config）" ;;
                ja) _mt_out="このログインの ~/.ssh/config を /var/sshd-cli へコピー（sudoer-adm のあと、パスワードなしの sudo sshd-cli backup-config）" ;;
                ko) _mt_out="이 로그인의 ~/.ssh/config를 /var/sshd-cli로 복사(sudoer-adm 이후 비밀번호 없는 sudo sshd-cli backup-config)" ;;
                ar) _mt_out="نسخ ~/.ssh/config لهذا الدخول إلى /var/sshd-cli ‏(sudo بلا كلمة مرور لـ sshd-cli backup-config بعد sudoer-adm)" ;;
                pt) _mt_out="Copiar ~/.ssh/config deste login para /var/sshd-cli (sudo sem senha para sshd-cli backup-config após sudoer-adm)" ;;
                ru) _mt_out="Копировать ~/.ssh/config этого входа в /var/sshd-cli (sudo без пароля для sshd-cli backup-config после sudoer-adm)" ;;
                nl) _mt_out="Kopieer ~/.ssh/config van deze login naar /var/sshd-cli (sudo zonder wachtwoord voor sshd-cli backup-config na sudoer-adm)" ;;
                el) _mt_out="Αντιγραφή του ~/.ssh/config αυτής της σύνδεσης στο /var/sshd-cli (sudo χωρίς κωδικό για sshd-cli backup-config μετά το sudoer-adm)" ;;
                *) _mt_out="Copy this login ~/.ssh/config into /var/sshd-cli (passwordless sudo sshd-cli backup-config after sudoer-adm)" ;;
            esac
            ;;
        help_sync)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="把 /var/sshd-cli/config 複製進這個登入的 ~/.ssh/config（模式 600；不用 sudo）" ;;
                es) _mt_out="copiar /var/sshd-cli/config en ~/.ssh/config de este inicio (modo 600; sin sudo)" ;;
                fr) _mt_out="copier /var/sshd-cli/config dans le ~/.ssh/config de cette session (mode 600 ; sans sudo)" ;;
                de) _mt_out="/var/sshd-cli/config in ~/.ssh/config dieser Anmeldung kopieren (Modus 600; ohne sudo)" ;;
                zh-Hans) _mt_out="把 /var/sshd-cli/config 复制进这个登录的 ~/.ssh/config（模式 600；不用 sudo）" ;;
                ja) _mt_out="/var/sshd-cli/config をこのログインの ~/.ssh/config へコピー（モード 600、sudo なし）" ;;
                ko) _mt_out="/var/sshd-cli/config를 이 로그인의 ~/.ssh/config로 복사(모드 600, sudo 없음)" ;;
                ar) _mt_out="نسخ /var/sshd-cli/config إلى ~/.ssh/config لهذا الدخول (الوضع 600؛ بلا sudo)" ;;
                pt) _mt_out="Copiar /var/sshd-cli/config para ~/.ssh/config deste login (modo 600; sem sudo)" ;;
                ru) _mt_out="Копировать /var/sshd-cli/config в ~/.ssh/config этого входа (режим 600; без sudo)" ;;
                nl) _mt_out="Kopieer /var/sshd-cli/config naar ~/.ssh/config van deze login (modus 600; geen sudo)" ;;
                el) _mt_out="Αντιγραφή του /var/sshd-cli/config στο ~/.ssh/config αυτής της σύνδεσης (λειτουργία 600· χωρίς sudo)" ;;
                *) _mt_out="Copy /var/sshd-cli/config into this login ~/.ssh/config (mode 600; no sudo)" ;;
            esac
            ;;
        help_sync_remote)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="把遠端主機的 /var/sshd-cli/config 複製進這個登入的 ~/.ssh/config（scp；記住上次的 user@host）" ;;
                es) _mt_out="copiar el /var/sshd-cli/config de otro equipo en ~/.ssh/config de este inicio (scp; recuerda el último user@host)" ;;
                fr) _mt_out="copier le /var/sshd-cli/config d'un hôte distant dans le ~/.ssh/config de cette session (scp ; retient le dernier user@host)" ;;
                de) _mt_out="/var/sshd-cli/config eines fernen Rechners in ~/.ssh/config dieser Anmeldung kopieren (scp; merkt sich das letzte user@host)" ;;
                zh-Hans) _mt_out="把远程主机的 /var/sshd-cli/config 复制进这个登录的 ~/.ssh/config（scp；记住上次的 user@host）" ;;
                ja) _mt_out="遠隔ホストの /var/sshd-cli/config をこのログインの ~/.ssh/config へコピー（scp。最後の user@host を覚える）" ;;
                ko) _mt_out="원격 호스트의 /var/sshd-cli/config를 이 로그인의 ~/.ssh/config로 복사(scp. 마지막 user@host를 기억)" ;;
                ar) _mt_out="نسخ /var/sshd-cli/config من مضيف بعيد إلى ~/.ssh/config لهذا الدخول (scp؛ يتذكر آخر user@host)" ;;
                pt) _mt_out="Copiar /var/sshd-cli/config de um host remoto para ~/.ssh/config deste login (scp; lembra o último user@host)" ;;
                ru) _mt_out="Копировать /var/sshd-cli/config с удалённого узла в ~/.ssh/config этого входа (scp; помнит последний user@host)" ;;
                nl) _mt_out="Kopieer /var/sshd-cli/config van een externe host naar ~/.ssh/config van deze login (scp; onthoudt de laatste user@host)" ;;
                el) _mt_out="Αντιγραφή του /var/sshd-cli/config από απομακρυσμένο υπολογιστή στο ~/.ssh/config αυτής της σύνδεσης (scp· θυμάται το τελευταίο user@host)" ;;
                *) _mt_out="Copy a remote host's /var/sshd-cli/config into this login ~/.ssh/config (scp; remembers last user@host)" ;;
            esac
            ;;
        help_print_sudoers)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="輸出給管理者安裝用的 project-sudoers-file（草稿）" ;;
                es) _mt_out="emitir project-sudoers-file (borrador) para la instalación del administrador" ;;
                fr) _mt_out="émettre project-sudoers-file (brouillon) pour l'installation par l'administrateur" ;;
                de) _mt_out="project-sudoers-file (Entwurf) für die Admin-Installation ausgeben" ;;
                zh-Hans) _mt_out="输出给管理者安装用的 project-sudoers-file（草稿）" ;;
                ja) _mt_out="管理者のインストール用 project-sudoers-file（下書き）を出力" ;;
                ko) _mt_out="관리자 설치용 project-sudoers-file(초안) 출력" ;;
                ar) _mt_out="إخراج project-sudoers-file (مسودة) لتثبيت المسؤول" ;;
                pt) _mt_out="Emitir project-sudoers-file (rascunho) para instalação do admin" ;;
                ru) _mt_out="Вывести project-sudoers-file (черновик) для установки администратором" ;;
                nl) _mt_out="Toon project-sudoers-file (concept) voor installatie door de beheerder" ;;
                el) _mt_out="Εμφάνιση project-sudoers-file (πρόχειρο) για εγκατάσταση από διαχειριστή" ;;
                *) _mt_out="Emit project-sudoers-file (draft) for admin install" ;;
            esac
            ;;
        help_print_script)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="寫出 sudo 安裝／移除／取代用的管理者腳本" ;;
                es) _mt_out="escribir el script de administrador para sudo install/uninstall/replace" ;;
                fr) _mt_out="écrire le script d'administration pour sudo install/uninstall/replace" ;;
                de) _mt_out="Admin-Skript für sudo install/uninstall/replace schreiben" ;;
                zh-Hans) _mt_out="写出 sudo 安装／移除／替换用的管理者脚本" ;;
                ja) _mt_out="sudo の install/uninstall/replace 用の管理者スクリプトを書く" ;;
                ko) _mt_out="sudo install/uninstall/replace 용 관리자 스크립트 작성" ;;
                ar) _mt_out="كتابة سكربت المسؤول لتثبيت sudo أو إزالته أو استبداله" ;;
                pt) _mt_out="Escrever o script do admin para instalar/desinstalar/substituir sudo" ;;
                ru) _mt_out="Записать скрипт администратора для установки/удаления/замены sudo" ;;
                nl) _mt_out="Schrijf het beheerdersscript voor sudo installeren/verwijderen/vervangen" ;;
                el) _mt_out="Εγγραφή σεναρίου διαχειριστή για εγκατάσταση/αφαίρεση/αντικατάσταση sudo" ;;
                *) _mt_out="Write admin script for sudo install/uninstall/replace" ;;
            esac
            ;;
        help_generate)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="單獨寫出一份 JSON 授權（backup-config 動詞）" ;;
                es) _mt_out="escribir por separado una concesión JSON (verbo backup-config)" ;;
                fr) _mt_out="écrire séparément une autorisation JSON (verbe backup-config)" ;;
                de) _mt_out="eigenständig eine JSON-Freigabe schreiben (Verb backup-config)" ;;
                zh-Hans) _mt_out="单独写出一份 JSON 授权（backup-config 动词）" ;;
                ja) _mt_out="JSON 認可を単独で書く（動詞は backup-config）" ;;
                ko) _mt_out="JSON 허가를 따로 작성(동사는 backup-config)" ;;
                ar) _mt_out="كتابة منحة JSON بشكل مستقل (فعل backup-config)" ;;
                pt) _mt_out="Escrever de forma independente uma concessão JSON (verbo backup-config)" ;;
                ru) _mt_out="Самостоятельно записать JSON-выдачу (команда backup-config)" ;;
                nl) _mt_out="Schrijf zelfstandig een JSON-toekenning (werkwoord backup-config)" ;;
                el) _mt_out="Ανεξάρτητη εγγραφή παραχώρησης JSON (ρήμα backup-config)" ;;
                *) _mt_out="Independently write a JSON grant (backup-config verb)" ;;
            esac
            ;;
        help_submit)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="透過 sudoer-cli 把 JSON sudoers 授權請求排入佇列" ;;
                es) _mt_out="encolar una solicitud JSON de concesión sudoers mediante sudoer-cli" ;;
                fr) _mt_out="mettre en file une demande JSON d'autorisation sudoers via sudoer-cli" ;;
                de) _mt_out="eine JSON-sudoers-Freigabe über sudoer-cli in die Warteschlange legen" ;;
                zh-Hans) _mt_out="通过 sudoer-cli 把 JSON sudoers 授权请求排入队列" ;;
                ja) _mt_out="sudoer-cli 経由で JSON の sudoers 認可要求を待ち行列へ入れる" ;;
                ko) _mt_out="sudoer-cli로 JSON sudoers 허가 요청을 대기열에 넣기" ;;
                ar) _mt_out="صف طلب منحة sudoers بصيغة JSON عبر sudoer-cli" ;;
                pt) _mt_out="Enfileirar um pedido de concessão sudoers em JSON via sudoer-cli" ;;
                ru) _mt_out="Поставить в очередь запрос JSON-выдачи sudoers через sudoer-cli" ;;
                nl) _mt_out="Zet een JSON-verzoek voor een sudoers-toekenning in de wachtrij via sudoer-cli" ;;
                el) _mt_out="Ουρά αιτήματος παραχώρησης sudoers σε JSON μέσω sudoer-cli" ;;
                *) _mt_out="Queue a JSON sudoers-grant request via sudoer-cli" ;;
            esac
            ;;
        help_remove)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="只刪除 project-sudoers-file 草稿" ;;
                es) _mt_out="borrar solo el borrador project-sudoers-file" ;;
                fr) _mt_out="supprimer seulement le brouillon project-sudoers-file" ;;
                de) _mt_out="nur den Entwurf project-sudoers-file löschen" ;;
                zh-Hans) _mt_out="只删除 project-sudoers-file 草稿" ;;
                ja) _mt_out="project-sudoers-file の下書きだけを削除" ;;
                ko) _mt_out="project-sudoers-file 초안만 삭제" ;;
                ar) _mt_out="حذف مسودة project-sudoers-file فقط" ;;
                pt) _mt_out="Apagar só o rascunho project-sudoers-file" ;;
                ru) _mt_out="Удалить только черновик project-sudoers-file" ;;
                nl) _mt_out="Verwijder alleen het concept project-sudoers-file" ;;
                el) _mt_out="Διαγραφή μόνο του πρόχειρου project-sudoers-file" ;;
                *) _mt_out="Delete project-sudoers-file draft only" ;;
            esac
            ;;
        help_h_termux)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="Termux（Android 喚醒鎖）：" ;;
                es) _mt_out="Termux (bloqueo de despertar de Android):" ;;
                fr) _mt_out="Termux (verrou de réveil Android) :" ;;
                de) _mt_out="Termux (Android-Wachhaltesperre):" ;;
                zh-Hans) _mt_out="Termux（Android 唤醒锁）：" ;;
                ja) _mt_out="Termux（Android の起動維持ロック）:" ;;
                ko) _mt_out="Termux(Android 깨어 있기 잠금):" ;;
                ar) _mt_out="Termux (قفل الإيقاظ في أندرويد):" ;;
                pt) _mt_out="Termux (bloqueio de vigília do Android):" ;;
                ru) _mt_out="Termux (блокировка сна Android):" ;;
                nl) _mt_out="Termux (Android-waakvergrendeling):" ;;
                el) _mt_out="Termux (κλείδωμα αφύπνισης Android):" ;;
                *) _mt_out="Termux (Android wake lock):" ;;
            esac
            ;;
        help_wake_lock)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="取得 Android 喚醒鎖，讓 sshd 在螢幕關閉時繼續聽候（可重複取得；若 Android 放下鎖就再取得）" ;;
                es) _mt_out="tomar el bloqueo de despertar de Android para que sshd siga escuchando con la pantalla apagada (se puede repetir; tomarlo de nuevo si Android lo soltó)" ;;
                fr) _mt_out="prendre le verrou de réveil Android pour que sshd continue d'écouter écran éteint (répétable ; le reprendre si Android l'a lâché)" ;;
                de) _mt_out="die Android-Wachhaltesperre nehmen, damit sshd bei ausgeschaltetem Bildschirm weiter wartet (wiederholbar; erneut nehmen, wenn Android sie losließ)" ;;
                zh-Hans) _mt_out="取得 Android 唤醒锁，让 sshd 在屏幕关闭时继续监听（可重复取得；若 Android 放开锁就再取得）" ;;
                ja) _mt_out="Android の起動維持ロックを取って、画面が消えても sshd が待ち受けを続ける（繰り返してよい。Android が外したらもう一度取る）" ;;
                ko) _mt_out="화면이 꺼져도 sshd가 계속 듣도록 Android 깨어 있기 잠금을 획득(반복 가능. Android가 놓으면 다시 획득)" ;;
                ar) _mt_out="احصل على قفل الإيقاظ في أندرويد ليواصل sshd الاستماع والشاشة مطفأة (متكرر؛ أعد الحصول إذا أسقطه أندرويد)" ;;
                pt) _mt_out="Obter o bloqueio de vigília do Android para o sshd continuar a escutar com a tela desligada (idempotente; obtenha de novo se o Android o largar)" ;;
                ru) _mt_out="Взять блокировку сна Android, чтобы sshd слушал при выключенном экране (идемпотентно; взять снова, если Android её снял)" ;;
                nl) _mt_out="Neem de Android-waakvergrendeling zodat sshd blijft luisteren met het scherm uit (idempotent; neem opnieuw als Android hem liet vallen)" ;;
                el) _mt_out="Απόκτηση του κλειδώματος αφύπνισης Android ώστε το sshd να συνεχίζει την ακρόαση με την οθόνη σβηστή (ταυτοδύναμο· αποκτήστε ξανά αν το Android το αφήσει)" ;;
                *) _mt_out="Acquire the Android wake lock so sshd can keep listening with the screen off (idempotent; acquire again if Android dropped it)" ;;
            esac
            ;;
        help_wake_unlock)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="放開 Android 喚醒鎖（不會停止 sshd；鎖是整個 Termux 共用）" ;;
                es) _mt_out="soltar el bloqueo de despertar de Android (no detiene sshd; el bloqueo es de todo Termux)" ;;
                fr) _mt_out="relâcher le verrou de réveil Android (n'arrête pas sshd ; le verrou vaut pour tout Termux)" ;;
                de) _mt_out="die Android-Wachhaltesperre loslassen (stoppt sshd nicht; die Sperre gilt für ganz Termux)" ;;
                zh-Hans) _mt_out="放开 Android 唤醒锁（不会停止 sshd；锁是整个 Termux 共用）" ;;
                ja) _mt_out="Android の起動維持ロックを放す（sshd は止めない。ロックは Termux 全体）" ;;
                ko) _mt_out="Android 깨어 있기 잠금 해제(sshd는 멈추지 않음. 잠금은 Termux 전체)" ;;
                ar) _mt_out="حرّر قفل الإيقاظ في أندرويد (لا يوقف sshd؛ القفل على نطاق Termux)" ;;
                pt) _mt_out="Largar o bloqueio de vigília do Android (não para o sshd; o bloqueio é de todo o Termux)" ;;
                ru) _mt_out="Снять блокировку сна Android (не останавливает sshd; блокировка на весь Termux)" ;;
                nl) _mt_out="Laat de Android-waakvergrendeling los (stopt sshd niet; het slot geldt voor heel Termux)" ;;
                el) _mt_out="Απελευθέρωση του κλειδώματος αφύπνισης Android (δεν σταματά το sshd· το κλείδωμα ισχύει για όλο το Termux)" ;;
                *) _mt_out="Release the Android wake lock (does not stop sshd; lock is Termux-wide)" ;;
            esac
            ;;
        help_h_tests)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="測試（本機資料夾；不是安裝）：" ;;
                es) _mt_out="Pruebas (carpeta local; no es la instalación):" ;;
                fr) _mt_out="Essais (dossier local ; pas l'installation) :" ;;
                de) _mt_out="Tests (lokaler Ordner; nicht die Installation):" ;;
                zh-Hans) _mt_out="测试（本机文件夹；不是安装）：" ;;
                ja) _mt_out="テスト（ローカルフォルダ。インストールではない）:" ;;
                ko) _mt_out="테스트(로컬 폴더, 설치 아님):" ;;
                ar) _mt_out="اختبارات (مجلد محلي؛ ليس التثبيت):" ;;
                pt) _mt_out="Testes (pasta local; não é instalação):" ;;
                ru) _mt_out="Проверки (локальная папка; не установка):" ;;
                nl) _mt_out="Tests (lokale map; geen installatie):" ;;
                el) _mt_out="Δοκιμές (τοπικός φάκελος· όχι εγκατάσταση):" ;;
                *) _mt_out="Tests (local folder; not install):" ;;
            esac
            ;;
        help_rc_test)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="在 --root 暫存目錄證明 PATH／profile 確保（--file bashrc|profile --case create|modify|noop）。不會寫這個登入真正的 ~/.bashrc" ;;
                es) _mt_out="probar el ensure de PATH/profile en un tmp de --root (--file bashrc|profile --case create|modify|noop). No escribe el ~/.bashrc real de este inicio" ;;
                fr) _mt_out="prouver l'ensure PATH/profile dans un tmp --root (--file bashrc|profile --case create|modify|noop). N'écrit pas le vrai ~/.bashrc de cette session" ;;
                de) _mt_out="PATH/Profil-Ensure in einem --root-tmp prüfen (--file bashrc|profile --case create|modify|noop). Schreibt nicht die echte ~/.bashrc dieser Anmeldung" ;;
                zh-Hans) _mt_out="在 --root 临时目录证明 PATH／profile 确保（--file bashrc|profile --case create|modify|noop）。不会写这个登录真正的 ~/.bashrc" ;;
                ja) _mt_out="--root の一時ディレクトリで PATH/profile の確保を確かめる（--file bashrc|profile --case create|modify|noop）。このログインの本物の ~/.bashrc は書かない" ;;
                ko) _mt_out="--root 임시 폴더에서 PATH/profile 확보를 확인(--file bashrc|profile --case create|modify|noop). 이 로그인의 실제 ~/.bashrc는 쓰지 않음" ;;
                ar) _mt_out="أثبت ضمان PATH/profile في --root tmp ‏(--file bashrc|profile --case create|modify|noop). لا يكتب ~/.bashrc الحقيقي لهذا الدخول" ;;
                pt) _mt_out="Provar a garantia de PATH/profile em --root tmp (--file bashrc|profile --case create|modify|noop). Não escreve o ~/.bashrc real deste login" ;;
                ru) _mt_out="Проверить обеспечение PATH/profile в --root tmp (--file bashrc|profile --case create|modify|noop). Не пишет настоящий ~/.bashrc этого входа" ;;
                nl) _mt_out="Toon PATH/profile-borging in --root tmp (--file bashrc|profile --case create|modify|noop). Schrijft niet het echte ~/.bashrc van deze login" ;;
                el) _mt_out="Απόδειξη διασφάλισης PATH/profile σε --root tmp (--file bashrc|profile --case create|modify|noop). Δεν γράφει το πραγματικό ~/.bashrc αυτής της σύνδεσης" ;;
                *) _mt_out="Prove PATH/profile ensure in --root tmp (--file bashrc|profile --case create|modify|noop). Does not write this login's real ~/.bashrc" ;;
            esac
            ;;
        help_h_options)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="全域選項：" ;;
                es) _mt_out="Opciones globales:" ;;
                fr) _mt_out="Options globales :" ;;
                de) _mt_out="Globale Optionen:" ;;
                zh-Hans) _mt_out="全局选项：" ;;
                ja) _mt_out="全体オプション:" ;;
                ko) _mt_out="전역 옵션:" ;;
                ar) _mt_out="خيارات عامة:" ;;
                pt) _mt_out="Opções globais:" ;;
                ru) _mt_out="Общие параметры:" ;;
                nl) _mt_out="Algemene opties:" ;;
                el) _mt_out="Γενικές επιλογές:" ;;
                *) _mt_out="Global Options:" ;;
            esac
            ;;
        help_quiet)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="不顯示 info／success（錯誤與警告仍會顯示）" ;;
                es) _mt_out="ocultar info/success (los errores y avisos siguen viéndose)" ;;
                fr) _mt_out="masquer info/success (les erreurs et avertissements restent visibles)" ;;
                de) _mt_out="info/success unterdrücken (Fehler und Warnungen bleiben sichtbar)" ;;
                zh-Hans) _mt_out="不显示 info／success（错误与警告仍会显示）" ;;
                ja) _mt_out="info/success を出さない（エラーと警告は出る）" ;;
                ko) _mt_out="info/success 숨김(오류와 경고는 그대로 표시)" ;;
                ar) _mt_out="إخفاء المعلومات/النجاح (تبقى الأخطاء والتحذيرات)" ;;
                pt) _mt_out="Suprimir info/sucesso (erros e avisos continuam)" ;;
                ru) _mt_out="Скрыть info/success (ошибки и предупреждения остаются)" ;;
                nl) _mt_out="Onderdruk info/succes (fouten en waarschuwingen blijven)" ;;
                el) _mt_out="Απόκρυψη info/επιτυχίας (σφάλματα και προειδοποιήσεις μένουν)" ;;
                *) _mt_out="Suppress info/success (errors and warnings still shown)" ;;
            esac
            ;;
        help_force)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="強制重裝／略過移除確認／允許降版" ;;
                es) _mt_out="forzar reinstalación / omitir la confirmación de desinstalación / permitir bajar de versión" ;;
                fr) _mt_out="forcer la réinstallation / sauter la confirmation de retrait / permettre une version plus ancienne" ;;
                de) _mt_out="Neuinstallation erzwingen / Bestätigung der Entfernung überspringen / ältere Version erlauben" ;;
                zh-Hans) _mt_out="强制重装／跳过移除确认／允许降级" ;;
                ja) _mt_out="再インストールを強制／削除確認を飛ばす／古い版を許す" ;;
                ko) _mt_out="재설치 강제 / 제거 확인 건너뛰기 / 낮은 버전 허용" ;;
                ar) _mt_out="فرض إعادة التثبيت / تخطي تأكيد الإزالة / السماح بالرجوع لإصدار أقدم" ;;
                pt) _mt_out="Forçar reinstalação / saltar a confirmação de desinstalação / permitir versão anterior" ;;
                ru) _mt_out="Принудительная переустановка / пропуск подтверждения удаления / разрешить понижение" ;;
                nl) _mt_out="Forceer herinstallatie / sla de bevestiging van verwijderen over / sta een oudere versie toe" ;;
                el) _mt_out="Εξαναγκασμός επανεγκατάστασης / παράλειψη επιβεβαίωσης αφαίρεσης / επιτρέπεται παλαιότερη έκδοση" ;;
                *) _mt_out="Force reinstall / skip uninstall confirm / allow downgrade" ;;
            esac
            ;;
        help_debug)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="偵錯診斷寫到 stderr" ;;
                es) _mt_out="diagnóstico de depuración en stderr" ;;
                fr) _mt_out="diagnostic de débogage sur stderr" ;;
                de) _mt_out="Debug-Diagnose auf stderr" ;;
                zh-Hans) _mt_out="调试诊断写到 stderr" ;;
                ja) _mt_out="デバッグ診断を stderr へ" ;;
                ko) _mt_out="디버그 진단을 stderr로" ;;
                ar) _mt_out="تشخيص التصحيح على stderr" ;;
                pt) _mt_out="Diagnóstico de depuração em stderr" ;;
                ru) _mt_out="Отладочная диагностика в stderr" ;;
                nl) _mt_out="Foutopsporingsdiagnostiek op stderr" ;;
                el) _mt_out="Διαγνωστικά αποσφαλμάτωσης στο stderr" ;;
                *) _mt_out="Debug diagnostics on stderr" ;;
            esac
            ;;
        help_h_env)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="環境：" ;;
                es) _mt_out="Entorno:" ;;
                fr) _mt_out="Environnement :" ;;
                de) _mt_out="Umgebung:" ;;
                zh-Hans) _mt_out="环境：" ;;
                ja) _mt_out="環境:" ;;
                ko) _mt_out="환경:" ;;
                ar) _mt_out="البيئة:" ;;
                pt) _mt_out="Ambiente:" ;;
                ru) _mt_out="Окружение:" ;;
                nl) _mt_out="Omgeving:" ;;
                el) _mt_out="Περιβάλλον:" ;;
                *) _mt_out="Environment:" ;;
            esac
            ;;
        help_repo_user)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="用來組成預設 SCRIPT_URL 的 GitHub 擁有者" ;;
                es) _mt_out="propietario de GitHub usado para componer el SCRIPT_URL predeterminado" ;;
                fr) _mt_out="propriétaire GitHub utilisé pour composer le SCRIPT_URL par défaut" ;;
                de) _mt_out="GitHub-Eigentümer für die vorgegebene SCRIPT_URL" ;;
                zh-Hans) _mt_out="用来组成默认 SCRIPT_URL 的 GitHub 所有者" ;;
                ja) _mt_out="既定の SCRIPT_URL を組み立てる GitHub 所有者" ;;
                ko) _mt_out="기본 SCRIPT_URL을 만드는 GitHub 소유자" ;;
                ar) _mt_out="مالك GitHub المستخدم لتركيب SCRIPT_URL الافتراضي" ;;
                pt) _mt_out="Dono do GitHub usado para compor o SCRIPT_URL padrão" ;;
                ru) _mt_out="Владелец GitHub для сборки SCRIPT_URL по умолчанию" ;;
                nl) _mt_out="GitHub-eigenaar voor het standaard SCRIPT_URL" ;;
                el) _mt_out="Κάτοχος GitHub για τη σύνθεση του προεπιλεγμένου SCRIPT_URL" ;;
                *) _mt_out="GitHub owner used to compose default SCRIPT_URL" ;;
            esac
            ;;
        help_repo_name)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="用來組成預設 SCRIPT_URL 的 GitHub 倉儲" ;;
                es) _mt_out="repositorio de GitHub usado para componer el SCRIPT_URL predeterminado" ;;
                fr) _mt_out="dépôt GitHub utilisé pour composer le SCRIPT_URL par défaut" ;;
                de) _mt_out="GitHub-Repo für die vorgegebene SCRIPT_URL" ;;
                zh-Hans) _mt_out="用来组成默认 SCRIPT_URL 的 GitHub 仓库" ;;
                ja) _mt_out="既定の SCRIPT_URL を組み立てる GitHub リポジトリ" ;;
                ko) _mt_out="기본 SCRIPT_URL을 만드는 GitHub 저장소" ;;
                ar) _mt_out="مستودع GitHub المستخدم لتركيب SCRIPT_URL الافتراضي" ;;
                pt) _mt_out="Repositório GitHub usado para compor o SCRIPT_URL padrão" ;;
                ru) _mt_out="Репозиторий GitHub для сборки SCRIPT_URL по умолчанию" ;;
                nl) _mt_out="GitHub-repo voor het standaard SCRIPT_URL" ;;
                el) _mt_out="Αποθετήριο GitHub για τη σύνθεση του προεπιλεγμένου SCRIPT_URL" ;;
                *) _mt_out="GitHub repo used to compose default SCRIPT_URL" ;;
            esac
            ;;
        help_url_unset)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="（未設定）" ;;
                es) _mt_out="(sin definir)" ;;
                fr) _mt_out="(non défini)" ;;
                de) _mt_out="(nicht gesetzt)" ;;
                zh-Hans) _mt_out="（未设置）" ;;
                ja) _mt_out="（未設定）" ;;
                ko) _mt_out="(설정 안 됨)" ;;
                ar) _mt_out="(غير مضبوط)" ;;
                pt) _mt_out="(não definido)" ;;
                ru) _mt_out="(не задано)" ;;
                nl) _mt_out="(niet ingesteld)" ;;
                el) _mt_out="(δεν έχει οριστεί)" ;;
                *) _mt_out="(not set)" ;;
            esac
            ;;
        help_url_desc)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="標準安裝通道（可用環境變數覆寫；version-check／self-update 需要它）" ;;
                es) _mt_out="canal canónico de instalación (se puede cambiar por el entorno; hace falta para version-check/self-update)" ;;
                fr) _mt_out="canal d'installation canonique (surcharge par l'environnement ; requis pour version-check/self-update)" ;;
                de) _mt_out="kanonischer Installationskanal (per Umgebung überschreibbar; nötig für version-check/self-update)" ;;
                zh-Hans) _mt_out="标准安装通道（可用环境变量覆盖；version-check／self-update 需要它）" ;;
                ja) _mt_out="標準の導入経路（環境変数で上書き可。version-check/self-update に必要）" ;;
                ko) _mt_out="기본 설치 경로(환경 변수로 바꿀 수 있음. version-check/self-update에 필요)" ;;
                ar) _mt_out="قناة التثبيت الرسمية (تجاوز عبر البيئة؛ لازم لـ version-check/self-update)" ;;
                pt) _mt_out="Canal oficial de instalação (substituição via ambiente; necessário para version-check/self-update)" ;;
                ru) _mt_out="Штатный канал установки (переопределение через окружение; нужен для version-check/self-update)" ;;
                nl) _mt_out="Officieel installatiekanaal (overschrijven via de omgeving; nodig voor version-check/self-update)" ;;
                el) _mt_out="Επίσημο κανάλι εγκατάστασης (παράκαμψη μέσω περιβάλλοντος· χρειάζεται για version-check/self-update)" ;;
                *) _mt_out="Canonical install channel (override via env; needed for version-check/self-update)" ;;
            esac
            ;;
        help_bashrc)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="install 的 PATH 確保所寫的互動 rc（預設 \${HOME}/.bashrc；測試／CI 可覆寫）" ;;
                es) _mt_out="rc interactivo que escribe el ensure de PATH de install (predeterminado \${HOME}/.bashrc; se puede cambiar en pruebas/CI)" ;;
                fr) _mt_out="rc interactif écrit par l'ensure PATH de install (défaut \${HOME}/.bashrc ; surcharge pour les essais/CI)" ;;
                de) _mt_out="interaktive rc, die das PATH-Ensure von install schreibt (Vorgabe \${HOME}/.bashrc; für Tests/CI überschreibbar)" ;;
                zh-Hans) _mt_out="install 的 PATH 确保所写的交互 rc（默认 \${HOME}/.bashrc；测试／CI 可覆盖）" ;;
                ja) _mt_out="install の PATH 確保が書く対話 rc（既定 \${HOME}/.bashrc。テスト／CI では上書き可）" ;;
                ko) _mt_out="install의 PATH 확보가 쓰는 대화형 rc(기본 \${HOME}/.bashrc. 테스트/CI에서 바꿀 수 있음)" ;;
                ar) _mt_out="ملف rc التفاعلي الذي يكتبه ضمان PATH في install (الافتراضي \${HOME}/.bashrc؛ تجاوز للاختبارات/CI)" ;;
                pt) _mt_out="rc interativo escrito pela garantia de PATH do install (padrão \${HOME}/.bashrc; substituição para testes/CI)" ;;
                ru) _mt_out="Интерактивный rc, который пишет обеспечение PATH при install (по умолчанию \${HOME}/.bashrc; замена для проверок/CI)" ;;
                nl) _mt_out="Interactieve rc die de PATH-borging van install schrijft (standaard \${HOME}/.bashrc; overschrijven voor tests/CI)" ;;
                el) _mt_out="Διαδραστικό rc που γράφει η διασφάλιση PATH του install (προεπιλογή \${HOME}/.bashrc· παράκαμψη για δοκιμές/CI)" ;;
                *) _mt_out="Interactive rc written by install PATH ensure (default \${HOME}/.bashrc; override for tests/CI)" ;;
            esac
            ;;
        help_root)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="耐久存放處（預設 /var/sshd-cli）" ;;
                es) _mt_out="almacén duradero (predeterminado /var/sshd-cli)" ;;
                fr) _mt_out="dépôt durable (défaut /var/sshd-cli)" ;;
                de) _mt_out="dauerhafter Speicher (Vorgabe /var/sshd-cli)" ;;
                zh-Hans) _mt_out="耐久存放处（默认 /var/sshd-cli）" ;;
                ja) _mt_out="永続の置き場（既定 /var/sshd-cli）" ;;
                ko) _mt_out="지속 저장소(기본 /var/sshd-cli)" ;;
                ar) _mt_out="مخزن دائم (الافتراضي /var/sshd-cli)" ;;
                pt) _mt_out="armazenamento durável (padrão /var/sshd-cli)" ;;
                ru) _mt_out="постоянное хранилище (по умолчанию /var/sshd-cli)" ;;
                nl) _mt_out="duurzame opslag (standaard /var/sshd-cli)" ;;
                el) _mt_out="μόνιμη αποθήκη (προεπιλογή /var/sshd-cli)" ;;
                *) _mt_out="durable store (default /var/sshd-cli)" ;;
            esac
            ;;
        help_remote_root)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="sync-from-remote 的遠端存放處（預設 /var/sshd-cli）" ;;
                es) _mt_out="almacén remoto para sync-from-remote (predeterminado /var/sshd-cli)" ;;
                fr) _mt_out="dépôt distant pour sync-from-remote (défaut /var/sshd-cli)" ;;
                de) _mt_out="ferner Speicher für sync-from-remote (Vorgabe /var/sshd-cli)" ;;
                zh-Hans) _mt_out="sync-from-remote 的远程存放处（默认 /var/sshd-cli）" ;;
                ja) _mt_out="sync-from-remote の遠隔の置き場（既定 /var/sshd-cli）" ;;
                ko) _mt_out="sync-from-remote용 원격 저장소(기본 /var/sshd-cli)" ;;
                ar) _mt_out="المخزن البعيد لـ sync-from-remote (الافتراضي /var/sshd-cli)" ;;
                pt) _mt_out="armazenamento remoto para sync-from-remote (padrão /var/sshd-cli)" ;;
                ru) _mt_out="удалённое хранилище для sync-from-remote (по умолчанию /var/sshd-cli)" ;;
                nl) _mt_out="externe opslag voor sync-from-remote (standaard /var/sshd-cli)" ;;
                el) _mt_out="απομακρυσμένη αποθήκη για sync-from-remote (προεπιλογή /var/sshd-cli)" ;;
                *) _mt_out="remote store for sync-from-remote (default /var/sshd-cli)" ;;
            esac
            ;;
        help_scp)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="覆寫 scp 執行檔（測試會注入假的）" ;;
                es) _mt_out="sustituir el binario scp (las pruebas inyectan uno falso)" ;;
                fr) _mt_out="remplacer le binaire scp (les essais injectent un faux)" ;;
                de) _mt_out="scp-Programm ersetzen (Tests setzen ein Ersatzprogramm)" ;;
                zh-Hans) _mt_out="覆盖 scp 可执行文件（测试会注入假的）" ;;
                ja) _mt_out="scp 実行ファイルの差し替え（テストは偽物を入れる）" ;;
                ko) _mt_out="scp 바이너리 교체(테스트는 가짜를 넣음)" ;;
                ar) _mt_out="تجاوز ثنائي scp (الاختبارات تحقن نسخة مزيفة)" ;;
                pt) _mt_out="substituição do binário scp (os testes injetam um falso)" ;;
                ru) _mt_out="подмена двоичного файла scp (проверки подставляют подделку)" ;;
                nl) _mt_out="overschrijving van het scp-programma (tests zetten een nepversie)" ;;
                el) _mt_out="παράκαμψη δυαδικού scp (οι δοκιμές εισάγουν ψεύτικο)" ;;
                *) _mt_out="scp binary override (tests inject a fake)" ;;
            esac
            ;;
        help_ssh_bin)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="覆寫 ssh 執行檔（測試會注入假的）" ;;
                es) _mt_out="sustituir el binario ssh (las pruebas inyectan uno falso)" ;;
                fr) _mt_out="remplacer le binaire ssh (les essais injectent un faux)" ;;
                de) _mt_out="ssh-Programm ersetzen (Tests setzen ein Ersatzprogramm)" ;;
                zh-Hans) _mt_out="覆盖 ssh 可执行文件（测试会注入假的）" ;;
                ja) _mt_out="ssh 実行ファイルの差し替え（テストは偽物を入れる）" ;;
                ko) _mt_out="ssh 바이너리 교체(테스트는 가짜를 넣음)" ;;
                ar) _mt_out="تجاوز ثنائي ssh (الاختبارات تحقن نسخة مزيفة)" ;;
                pt) _mt_out="substituição do binário ssh (os testes injetam um falso)" ;;
                ru) _mt_out="подмена двоичного файла ssh (проверки подставляют подделку)" ;;
                nl) _mt_out="overschrijving van het ssh-programma (tests zetten een nepversie)" ;;
                el) _mt_out="παράκαμψη δυαδικού ssh (οι δοκιμές εισάγουν ψεύτικο)" ;;
                *) _mt_out="ssh binary override (tests inject a fake)" ;;
            esac
            ;;
        help_json_note)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="請把 --json 用在 version、about、version-check、install、self-install、self-update、self-uninstall、rc-test。" ;;
                es) _mt_out="Use --json con version, about, version-check, install, self-install, self-update, self-uninstall, rc-test." ;;
                fr) _mt_out="Utilisez --json avec version, about, version-check, install, self-install, self-update, self-uninstall, rc-test." ;;
                de) _mt_out="--json mit version, about, version-check, install, self-install, self-update, self-uninstall, rc-test verwenden." ;;
                zh-Hans) _mt_out="请把 --json 用在 version、about、version-check、install、self-install、self-update、self-uninstall、rc-test。" ;;
                ja) _mt_out="--json は version、about、version-check、install、self-install、self-update、self-uninstall、rc-test と一緒に使う。" ;;
                ko) _mt_out="--json 은 version, about, version-check, install, self-install, self-update, self-uninstall, rc-test 와 함께 쓴다." ;;
                ar) _mt_out="استخدم --json مع version وabout وversion-check وinstall وself-install وself-update وself-uninstall وrc-test." ;;
                pt) _mt_out="Use --json com version, about, version-check, install, self-install, self-update, self-uninstall, rc-test." ;;
                ru) _mt_out="Используйте --json с version, about, version-check, install, self-install, self-update, self-uninstall, rc-test." ;;
                nl) _mt_out="Gebruik --json met version, about, version-check, install, self-install, self-update, self-uninstall, rc-test." ;;
                el) _mt_out="Χρησιμοποιήστε --json με version, about, version-check, install, self-install, self-update, self-uninstall, rc-test." ;;
                *) _mt_out="Use --json with version, about, version-check, install, self-install, self-update, self-uninstall, rc-test." ;;
            esac
            ;;
        help_menu)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="編號樹：1 用戶端、2 伺服器端、5 sudoers、6 自我管理、7 語言、9 離開。語言 71 English、72 简体中文、73 繁體中文、74 Español、75 العربية、76 Français、77 Português、78 Русский、79 Deutsch、80 日本語、81 한국어、82 Nederlands、83 Ελληνικά。用戶端 11… dns/ssh/download/upload。伺服器 21… status/start/stop/restart。自我管理 61… install/version/about、67 self-install。子選單 0 返回。別名：main" ;;
                es) _mt_out="Árbol numerado: 1 cliente, 2 servidor, 5 sudoers, 6 autogestión, 7 idioma, 9 Salir. Idiomas 71 English, 72 简体中文, 73 繁體中文, 74 Español, 75 العربية, 76 Français, 77 Português, 78 Русский, 79 Deutsch, 80 日本語, 81 한국어, 82 Nederlands, 83 Ελληνικά. Cliente 11… dns/ssh/download/upload. Servidor 21… status/start/stop/restart. Autogestión 61… install/version/about, 67 self-install. Submenús 0 Atrás. Alias: main" ;;
                fr) _mt_out="Arbre numéroté : 1 client, 2 serveur, 5 sudoers, 6 autogestion, 7 langue, 9 Quitter. Langues 71 English, 72 简体中文, 73 繁體中文, 74 Español, 75 العربية, 76 Français, 77 Português, 78 Русский, 79 Deutsch, 80 日本語, 81 한국어, 82 Nederlands, 83 Ελληνικά. Client 11… dns/ssh/download/upload. Serveur 21… status/start/stop/restart. Autogestion 61… install/version/about, 67 self-install. Sous-menus 0 Retour. Alias : main" ;;
                de) _mt_out="Nummerierter Baum: 1 Client, 2 Server, 5 sudoers, 6 Selbstverwaltung, 7 Sprache, 9 Beenden. Sprachen 71 English, 72 简体中文, 73 繁體中文, 74 Español, 75 العربية, 76 Français, 77 Português, 78 Русский, 79 Deutsch, 80 日本語, 81 한국어, 82 Nederlands, 83 Ελληνικά. Client 11… dns/ssh/download/upload. Server 21… status/start/stop/restart. Selbstverwaltung 61… install/version/about, 67 self-install. Untermenüs 0 Zurück. Alias: main" ;;
                zh-Hans) _mt_out="编号树：1 客户端、2 服务器端、5 sudoers、6 自我管理、7 语言、9 离开。语言 71 English、72 简体中文、73 繁體中文、74 Español、75 العربية、76 Français、77 Português、78 Русский、79 Deutsch、80 日本語、81 한국어、82 Nederlands、83 Ελληνικά。客户端 11… dns/ssh/download/upload。服务器 21… status/start/stop/restart。自我管理 61… install/version/about、67 self-install。子菜单 0 返回。别名：main" ;;
                ja) _mt_out="番号の木: 1 クライアント、2 サーバー、5 sudoers、6 自己管理、7 言語、9 終了。言語 71 English、72 简体中文、73 繁體中文、74 Español、75 العربية、76 Français、77 Português、78 Русский、79 Deutsch、80 日本語、81 한국어、82 Nederlands、83 Ελληνικά。クライアント 11… dns/ssh/download/upload。サーバー 21… status/start/stop/restart。自己管理 61… install/version/about、67 self-install。サブメニュー 0 戻る。別名: main" ;;
                ko) _mt_out="번호 나무: 1 클라이언트, 2 서버, 5 sudoers, 6 자기관리, 7 언어, 9 종료. 언어 71 English, 72 简体中文, 73 繁體中文, 74 Español, 75 العربية, 76 Français, 77 Português, 78 Русский, 79 Deutsch, 80 日本語, 81 한국어, 82 Nederlands, 83 Ελληνικά. 클라이언트 11… dns/ssh/download/upload. 서버 21… status/start/stop/restart. 자기관리 61… install/version/about, 67 self-install. 하위 메뉴 0 뒤로. 별칭: main" ;;
                ar) _mt_out="شجرة مرقمة: 1 عميل، 2 خادم، 5 sudoers، 6 إدارة-ذاتية، 7 لغة، 9 خروج. اللغات 71 English، 72 简体中文، 73 繁體中文، 74 Español، 75 العربية، 76 Français، 77 Português، 78 Русский، 79 Deutsch، 80 日本語، 81 한국어، 82 Nederlands، 83 Ελληνικά. العميل 11… dns/ssh/download/upload. الخادم 21… status/start/stop/restart. الإدارة 61… install/version/about، 67 self-install. القوائم الفرعية 0 رجوع. الاسم البديل: main" ;;
                pt) _mt_out="Árvore numerada: 1 cliente, 2 servidor, 5 sudoers, 6 autogestão, 7 idioma, 9 Sair. Idiomas 71 English, 72 简体中文, 73 繁體中文, 74 Español, 75 العربية, 76 Français, 77 Português, 78 Русский, 79 Deutsch, 80 日本語, 81 한국어, 82 Nederlands, 83 Ελληνικά. Cliente 11… dns/ssh/download/upload. Servidor 21… status/start/stop/restart. Autogestão 61… install/version/about, 67 self-install. Submenus 0 Voltar. Apelido: main" ;;
                ru) _mt_out="Нумерованное дерево: 1 клиент, 2 сервер, 5 sudoers, 6 самоуправление, 7 язык, 9 Выход. Языки 71 English, 72 简体中文, 73 繁體中文, 74 Español, 75 العربية, 76 Français, 77 Português, 78 Русский, 79 Deutsch, 80 日本語, 81 한국어, 82 Nederlands, 83 Ελληνικά. Клиент 11… dns/ssh/download/upload. Сервер 21… status/start/stop/restart. Самоуправление 61… install/version/about, 67 self-install. Подменю 0 Назад. Псевдоним: main" ;;
                nl) _mt_out="Genummerde boom: 1 client, 2 server, 5 sudoers, 6 zelfbeheer, 7 taal, 9 Afsluiten. Talen 71 English, 72 简体中文, 73 繁體中文, 74 Español, 75 العربية, 76 Français, 77 Português, 78 Русский, 79 Deutsch, 80 日本語, 81 한국어, 82 Nederlands, 83 Ελληνικά. Client 11… dns/ssh/download/upload. Server 21… status/start/stop/restart. Zelfbeheer 61… install/version/about, 67 self-install. Submenu's 0 Terug. Alias: main" ;;
                el) _mt_out="Αριθμημένο δέντρο: 1 πελάτης, 2 διακομιστής, 5 sudoers, 6 αυτοδιαχείριση, 7 γλώσσα, 9 Έξοδος. Γλώσσες 71 English, 72 简体中文, 73 繁體中文, 74 Español, 75 العربية, 76 Français, 77 Português, 78 Русский, 79 Deutsch, 80 日本語, 81 한국어, 82 Nederlands, 83 Ελληνικά. Πελάτης 11… dns/ssh/download/upload. Διακομιστής 21… status/start/stop/restart. Αυτοδιαχείριση 61… install/version/about, 67 self-install. Υπομενού 0 Πίσω. Ψευδώνυμο: main" ;;
                *) _mt_out="Numbered tree: 1 client-side, 2 server-side, 5 sudoers, 6 self-management, 7 language, 9 Exit. Language 71 English, 72 Simplified Chinese, 73 Traditional Chinese, 74 Spanish, 75 Arabic, 76 French, 77 Portuguese, 78 Russian, 79 German, 80 Japanese, 81 Korean, 82 Dutch, 83 Greek. Client 11… dns/ssh/download/upload; server 21… status/start/stop/restart; self-management 61… install/version/about, 67 self-install. Submenus 0 Back. Alias: main" ;;
            esac
            ;;
        about_title)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="關於 / 診斷" ;;
                es) _mt_out="Acerca de / diagnóstico" ;;
                fr) _mt_out="À propos / diagnostic" ;;
                de) _mt_out="Über / Diagnose" ;;
                zh-Hans) _mt_out="关于 / 诊断" ;;
                ja) _mt_out="概要 / 診断" ;;
                ko) _mt_out="개요 / 진단" ;;
                ar) _mt_out="حول / تشخيص" ;;
                pt) _mt_out="Acerca de / diagnóstico" ;;
                ru) _mt_out="О программе / диагностика" ;;
                nl) _mt_out="Over / diagnose" ;;
                el) _mt_out="Σχετικά / διάγνωση" ;;
                *) _mt_out="About / Diagnostics" ;;
            esac
            ;;
        about_installed)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="${APP_NAME} 已正確安裝。" ;;
                es) _mt_out="${APP_NAME} está instalado correctamente." ;;
                fr) _mt_out="${APP_NAME} est correctement installé." ;;
                de) _mt_out="${APP_NAME} ist ordnungsgemäß installiert." ;;
                zh-Hans) _mt_out="${APP_NAME} 已正确安装。" ;;
                ja) _mt_out="${APP_NAME} は正しく配置されています。" ;;
                ko) _mt_out="${APP_NAME}가 올바르게 설치되어 있습니다." ;;
                ar) _mt_out="${APP_NAME} مثبت بشكل صحيح." ;;
                pt) _mt_out="${APP_NAME} está instalado corretamente." ;;
                ru) _mt_out="${APP_NAME} установлен правильно." ;;
                nl) _mt_out="${APP_NAME} is correct geïnstalleerd." ;;
                el) _mt_out="Το ${APP_NAME} είναι σωστά εγκατεστημένο." ;;
                *) _mt_out="${APP_NAME} is properly installed." ;;
            esac
            ;;
        about_missing)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="${APP_NAME} 沒有安裝在你的 PATH。" ;;
                es) _mt_out="${APP_NAME} NO está instalado en tu PATH." ;;
                fr) _mt_out="${APP_NAME} n'est PAS installé dans votre PATH." ;;
                de) _mt_out="${APP_NAME} ist NICHT in Ihrem PATH installiert." ;;
                zh-Hans) _mt_out="${APP_NAME} 没有安装在你的 PATH。" ;;
                ja) _mt_out="${APP_NAME} は PATH に入っていません。" ;;
                ko) _mt_out="${APP_NAME}가 PATH에 설치되어 있지 않습니다." ;;
                ar) _mt_out="${APP_NAME} غير مثبت في PATH." ;;
                pt) _mt_out="${APP_NAME} NÃO está instalado no seu PATH." ;;
                ru) _mt_out="${APP_NAME} НЕ установлен в вашем PATH." ;;
                nl) _mt_out="${APP_NAME} is NIET geïnstalleerd in uw PATH." ;;
                el) _mt_out="Το ${APP_NAME} ΔΕΝ είναι εγκατεστημένο στο PATH σας." ;;
                *) _mt_out="${APP_NAME} is NOT installed in your PATH." ;;
            esac
            ;;
        about_recommend)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="   建議：curl -fsSL ${SCRIPT_URL} | sh" ;;
                es) _mt_out="   Recomendado: curl -fsSL ${SCRIPT_URL} | sh" ;;
                fr) _mt_out="   Recommandé : curl -fsSL ${SCRIPT_URL} | sh" ;;
                de) _mt_out="   Empfohlen: curl -fsSL ${SCRIPT_URL} | sh" ;;
                zh-Hans) _mt_out="   建议：curl -fsSL ${SCRIPT_URL} | sh" ;;
                ja) _mt_out="   推奨: curl -fsSL ${SCRIPT_URL} | sh" ;;
                ko) _mt_out="   권장: curl -fsSL ${SCRIPT_URL} | sh" ;;
                ar) _mt_out="   موصى به: curl -fsSL ${SCRIPT_URL} | sh" ;;
                pt) _mt_out="   Recomendado: curl -fsSL ${SCRIPT_URL} | sh" ;;
                ru) _mt_out="   Рекомендуется: curl -fsSL ${SCRIPT_URL} | sh" ;;
                nl) _mt_out="   Aanbevolen: curl -fsSL ${SCRIPT_URL} | sh" ;;
                el) _mt_out="   Συνιστάται: curl -fsSL ${SCRIPT_URL} | sh" ;;
                *) _mt_out="   Recommended: curl -fsSL ${SCRIPT_URL} | sh" ;;
            esac
            ;;
        about_set_url)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="   請把 SCRIPT_URL 設成安裝腳本的 URL，然後： " ;;
                es) _mt_out="   Defina SCRIPT_URL con la URL del script de instalación y luego: " ;;
                fr) _mt_out="   Réglez SCRIPT_URL sur l'URL du script d'installation, puis : " ;;
                de) _mt_out="   Setzen Sie SCRIPT_URL auf die URL des Installationsskripts, dann: " ;;
                zh-Hans) _mt_out="   请把 SCRIPT_URL 设成安装脚本的 URL，然后： " ;;
                ja) _mt_out="   SCRIPT_URL を導入スクリプトの URL にしてから: " ;;
                ko) _mt_out="   SCRIPT_URL을 설치 스크립트 URL로 지정한 다음: " ;;
                ar) _mt_out="   اضبط SCRIPT_URL على عنوان سكربت التثبيت، ثم: " ;;
                pt) _mt_out="   Defina SCRIPT_URL como o URL do script de instalação e depois: " ;;
                ru) _mt_out="   Задайте SCRIPT_URL как URL скрипта установки, затем: " ;;
                nl) _mt_out="   Stel SCRIPT_URL in op de URL van het installatiescript, daarna: " ;;
                el) _mt_out="   Ορίστε το SCRIPT_URL στη διεύθυνση του σεναρίου εγκατάστασης και έπειτα: " ;;
                *) _mt_out="   Set SCRIPT_URL to the install script URL, then: " ;;
            esac
            ;;
        about_global)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="全域安裝  (" ;;
                es) _mt_out="Instalación global  (" ;;
                fr) _mt_out="Installation globale  (" ;;
                de) _mt_out="Globale Installation  (" ;;
                zh-Hans) _mt_out="全局安装  (" ;;
                ja) _mt_out="全体インストール  (" ;;
                ko) _mt_out="전역 설치  (" ;;
                ar) _mt_out="تثبيت عام  (" ;;
                pt) _mt_out="Instalação global  (" ;;
                ru) _mt_out="Глобальная установка  (" ;;
                nl) _mt_out="Globale installatie  (" ;;
                el) _mt_out="Καθολική εγκατάσταση  (" ;;
                *) _mt_out="Global install  (" ;;
            esac
            ;;
        about_local)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="本機安裝   (" ;;
                es) _mt_out="Instalación local   (" ;;
                fr) _mt_out="Installation locale   (" ;;
                de) _mt_out="Lokale Installation   (" ;;
                zh-Hans) _mt_out="本机安装   (" ;;
                ja) _mt_out="ローカルインストール   (" ;;
                ko) _mt_out="로컬 설치   (" ;;
                ar) _mt_out="تثبيت محلي   (" ;;
                pt) _mt_out="Instalação local   (" ;;
                ru) _mt_out="Локальная установка   (" ;;
                nl) _mt_out="Lokale installatie   (" ;;
                el) _mt_out="Τοπική εγκατάσταση   (" ;;
                *) _mt_out="Local install   (" ;;
            esac
            ;;
        about_not_found)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="找不到" ;;
                es) _mt_out="no encontrado" ;;
                fr) _mt_out="introuvable" ;;
                de) _mt_out="nicht gefunden" ;;
                zh-Hans) _mt_out="找不到" ;;
                ja) _mt_out="見つかりません" ;;
                ko) _mt_out="없음" ;;
                ar) _mt_out="غير موجود" ;;
                pt) _mt_out="não encontrado" ;;
                ru) _mt_out="не найден" ;;
                nl) _mt_out="niet gevonden" ;;
                el) _mt_out="δεν βρέθηκε" ;;
                *) _mt_out="not found" ;;
            esac
            ;;
        about_user)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="目前使用者：      " ;;
                es) _mt_out="Usuario actual:      " ;;
                fr) _mt_out="Utilisateur actuel :      " ;;
                de) _mt_out="Aktueller Benutzer:      " ;;
                zh-Hans) _mt_out="当前用户：      " ;;
                ja) _mt_out="現在のユーザー:      " ;;
                ko) _mt_out="현재 사용자:      " ;;
                ar) _mt_out="المستخدم الحالي:      " ;;
                pt) _mt_out="Usuário atual:      " ;;
                ru) _mt_out="Текущий пользователь:      " ;;
                nl) _mt_out="Huidige gebruiker:      " ;;
                el) _mt_out="Τρέχων χρήστης:      " ;;
                *) _mt_out="Current user:      " ;;
            esac
            ;;
        about_root)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="執行身分：root（可用全域安裝路徑）" ;;
                es) _mt_out="Contexto de ejecución: root (ruta de instalación global disponible)" ;;
                fr) _mt_out="Contexte d'exécution : root (chemin d'installation global disponible)" ;;
                de) _mt_out="Ausführungskontext: root (globaler Installationspfad verfügbar)" ;;
                zh-Hans) _mt_out="执行身份：root（可用全局安装路径）" ;;
                ja) _mt_out="実行コンテキスト: root（全体インストールのパスが使える）" ;;
                ko) _mt_out="실행 맥락: root(전역 설치 경로 사용 가능)" ;;
                ar) _mt_out="سياق التنفيذ: root (مسار التثبيت العام متاح)" ;;
                pt) _mt_out="Contexto de execução: root (caminho de instalação global disponível)" ;;
                ru) _mt_out="Контекст выполнения: root (доступен глобальный путь установки)" ;;
                nl) _mt_out="Uitvoeringscontext: root (globaal installatiepad beschikbaar)" ;;
                el) _mt_out="Πλαίσιο εκτέλεσης: root (διαθέσιμη καθολική διαδρομή εγκατάστασης)" ;;
                *) _mt_out="Execution context: root (global install path available)" ;;
            esac
            ;;
        about_login)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="執行身分：這個登入（這個 CLI 不需要 root）" ;;
                es) _mt_out="Contexto de ejecución: este inicio (este CLI no necesita root)" ;;
                fr) _mt_out="Contexte d'exécution : cette session (ce CLI n'a pas besoin de root)" ;;
                de) _mt_out="Ausführungskontext: diese Anmeldung (dieses CLI braucht kein root)" ;;
                zh-Hans) _mt_out="执行身份：这个登录（这个 CLI 不需要 root）" ;;
                ja) _mt_out="実行コンテキスト: このログイン（この CLI に root は不要）" ;;
                ko) _mt_out="실행 맥락: 이 로그인(이 CLI에는 root가 필요 없음)" ;;
                ar) _mt_out="سياق التنفيذ: هذا الدخول (هذا CLI لا يحتاج root)" ;;
                pt) _mt_out="Contexto de execução: este login (este CLI não precisa de root)" ;;
                ru) _mt_out="Контекст выполнения: этот вход (этому CLI не нужен root)" ;;
                nl) _mt_out="Uitvoeringscontext: deze login (deze CLI heeft geen root nodig)" ;;
                el) _mt_out="Πλαίσιο εκτέλεσης: αυτή η σύνδεση (αυτό το CLI δεν χρειάζεται root)" ;;
                *) _mt_out="Execution context: this login (no root required for this CLI)" ;;
            esac
            ;;
        about_shell)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="目前 shell：     " ;;
                es) _mt_out="Shell actual:     " ;;
                fr) _mt_out="Shell actuel :     " ;;
                de) _mt_out="Aktuelle Shell:     " ;;
                zh-Hans) _mt_out="当前 shell：     " ;;
                ja) _mt_out="現在のシェル:     " ;;
                ko) _mt_out="현재 셸:     " ;;
                ar) _mt_out="الصدفة الحالية:     " ;;
                pt) _mt_out="Shell atual:     " ;;
                ru) _mt_out="Текущая оболочка:     " ;;
                nl) _mt_out="Huidige shell:     " ;;
                el) _mt_out="Τρέχον κέλυφος:     " ;;
                *) _mt_out="Current shell:     " ;;
            esac
            ;;
        about_tty_yes)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="TTY／互動：是" ;;
                es) _mt_out="TTY / interactivo: sí" ;;
                fr) _mt_out="TTY / interactif : oui" ;;
                de) _mt_out="TTY / interaktiv: ja" ;;
                zh-Hans) _mt_out="TTY／交互：是" ;;
                ja) _mt_out="TTY / 対話: はい" ;;
                ko) _mt_out="TTY / 대화형: 예" ;;
                ar) _mt_out="TTY / تفاعلي: نعم" ;;
                pt) _mt_out="TTY / interativo: sim" ;;
                ru) _mt_out="TTY / интерактивно: да" ;;
                nl) _mt_out="TTY / interactief: ja" ;;
                el) _mt_out="TTY / διαδραστικό: ναι" ;;
                *) _mt_out="TTY / Interactive: yes" ;;
            esac
            ;;
        about_tty_no)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="TTY／互動：否（非互動／腳本模式）" ;;
                es) _mt_out="TTY / interactivo: no (modo no interactivo / script)" ;;
                fr) _mt_out="TTY / interactif : non (mode non interactif / script)" ;;
                de) _mt_out="TTY / interaktiv: nein (nicht interaktiv / Skript)" ;;
                zh-Hans) _mt_out="TTY／交互：否（非交互／脚本模式）" ;;
                ja) _mt_out="TTY / 対話: いいえ（非対話／スクリプト）" ;;
                ko) _mt_out="TTY / 대화형: 아니요(비대화 / 스크립트)" ;;
                ar) _mt_out="TTY / تفاعلي: لا (وضع غير تفاعلي / سكربت)" ;;
                pt) _mt_out="TTY / interativo: não (modo não interativo / script)" ;;
                ru) _mt_out="TTY / интерактивно: нет (неинтерактивный / скриптовый режим)" ;;
                nl) _mt_out="TTY / interactief: nee (niet-interactief / script)" ;;
                el) _mt_out="TTY / διαδραστικό: όχι (μη διαδραστικό / σενάριο)" ;;
                *) _mt_out="TTY / Interactive: no (non-interactive / scripted mode)" ;;
            esac
            ;;
        about_cache_used)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="使用的快取資料夾：" ;;
                es) _mt_out="Carpeta de caché en uso: " ;;
                fr) _mt_out="Dossier de cache utilisé : " ;;
                de) _mt_out="Verwendeter Cache-Ordner: " ;;
                zh-Hans) _mt_out="使用的缓存文件夹：" ;;
                ja) _mt_out="使用中のキャッシュフォルダ: " ;;
                ko) _mt_out="사용 중인 캐시 폴더: " ;;
                ar) _mt_out="مجلد الذاكرة المؤقتة المستخدم: " ;;
                pt) _mt_out="Pasta de cache em uso: " ;;
                ru) _mt_out="Используемая папка кэша: " ;;
                nl) _mt_out="Gebruikte cachemap: " ;;
                el) _mt_out="Φάκελος προσωρινής μνήμης σε χρήση: " ;;
                *) _mt_out="Cache folder used: " ;;
            esac
            ;;
        about_cache_pref)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="快取資料夾（偏好）：" ;;
                es) _mt_out="Carpeta de caché (preferida): " ;;
                fr) _mt_out="Dossier de cache (préféré) : " ;;
                de) _mt_out="Cache-Ordner (bevorzugt): " ;;
                zh-Hans) _mt_out="缓存文件夹（首选）：" ;;
                ja) _mt_out="キャッシュフォルダ（優先）: " ;;
                ko) _mt_out="캐시 폴더(선호): " ;;
                ar) _mt_out="مجلد الذاكرة المؤقتة (المفضل): " ;;
                pt) _mt_out="Pasta de cache (preferida): " ;;
                ru) _mt_out="Папка кэша (предпочтительная): " ;;
                nl) _mt_out="Cachemap (voorkeur): " ;;
                el) _mt_out="Φάκελος προσωρινής μνήμης (προτιμώμενος): " ;;
                *) _mt_out="Cache folder (preferred): " ;;
            esac
            ;;
        about_cache_1)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="快取資料夾（第 1 候補）：" ;;
                es) _mt_out="Carpeta de caché (1.er respaldo): " ;;
                fr) _mt_out="Dossier de cache (1er repli) : " ;;
                de) _mt_out="Cache-Ordner (1. Ausweich): " ;;
                zh-Hans) _mt_out="缓存文件夹（第 1 后备）：" ;;
                ja) _mt_out="キャッシュフォルダ（第1候補）: " ;;
                ko) _mt_out="캐시 폴더(1차 대안): " ;;
                ar) _mt_out="مجلد الذاكرة المؤقتة (البديل 1): " ;;
                pt) _mt_out="Pasta de cache (1.º recurso): " ;;
                ru) _mt_out="Папка кэша (1-й запасной): " ;;
                nl) _mt_out="Cachemap (1e uitwijk): " ;;
                el) _mt_out="Φάκελος προσωρινής μνήμης (1η εφεδρική): " ;;
                *) _mt_out="Cache folder (1st fallback): " ;;
            esac
            ;;
        about_cache_2)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="快取資料夾（第 2 候補）：" ;;
                es) _mt_out="Carpeta de caché (2.º respaldo): " ;;
                fr) _mt_out="Dossier de cache (2e repli) : " ;;
                de) _mt_out="Cache-Ordner (2. Ausweich): " ;;
                zh-Hans) _mt_out="缓存文件夹（第 2 后备）：" ;;
                ja) _mt_out="キャッシュフォルダ（第2候補）: " ;;
                ko) _mt_out="캐시 폴더(2차 대안): " ;;
                ar) _mt_out="مجلد الذاكرة المؤقتة (البديل 2): " ;;
                pt) _mt_out="Pasta de cache (2.º recurso): " ;;
                ru) _mt_out="Папка кэша (2-й запасной): " ;;
                nl) _mt_out="Cachemap (2e uitwijk): " ;;
                el) _mt_out="Φάκελος προσωρινής μνήμης (2η εφεδρική): " ;;
                *) _mt_out="Cache folder (2nd fallback): " ;;
            esac
            ;;
        about_persist)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="持久儲存：" ;;
                es) _mt_out="Almacenamiento persistente: " ;;
                fr) _mt_out="Stockage persistant : " ;;
                de) _mt_out="Dauerhafter Speicher: " ;;
                zh-Hans) _mt_out="持久存储：" ;;
                ja) _mt_out="永続ストレージ: " ;;
                ko) _mt_out="지속 저장소: " ;;
                ar) _mt_out="التخزين الدائم: " ;;
                pt) _mt_out="Armazenamento persistente: " ;;
                ru) _mt_out="Постоянное хранилище: " ;;
                nl) _mt_out="Persistente opslag: " ;;
                el) _mt_out="Μόνιμη αποθήκευση: " ;;
                *) _mt_out="Persistence storage: " ;;
            esac
            ;;
        about_platform)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="sshd 平台：    " ;;
                es) _mt_out="plataforma sshd:    " ;;
                fr) _mt_out="plateforme sshd :    " ;;
                de) _mt_out="sshd-Plattform:    " ;;
                zh-Hans) _mt_out="sshd 平台：    " ;;
                ja) _mt_out="sshd のプラットフォーム:    " ;;
                ko) _mt_out="sshd 플랫폼:    " ;;
                ar) _mt_out="منصة sshd:    " ;;
                pt) _mt_out="plataforma sshd:    " ;;
                ru) _mt_out="платформа sshd:    " ;;
                nl) _mt_out="sshd-platform:    " ;;
                el) _mt_out="πλατφόρμα sshd:    " ;;
                *) _mt_out="sshd platform:    " ;;
            esac
            ;;
        about_binary)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="sshd 執行檔：      " ;;
                es) _mt_out="binario sshd:      " ;;
                fr) _mt_out="binaire sshd :      " ;;
                de) _mt_out="sshd-Programm:      " ;;
                zh-Hans) _mt_out="sshd 可执行文件：      " ;;
                ja) _mt_out="sshd 実行ファイル:      " ;;
                ko) _mt_out="sshd 바이너리:      " ;;
                ar) _mt_out="ثنائي sshd:      " ;;
                pt) _mt_out="binário sshd:      " ;;
                ru) _mt_out="двоичный файл sshd:      " ;;
                nl) _mt_out="sshd-programma:      " ;;
                el) _mt_out="δυαδικό sshd:      " ;;
                *) _mt_out="sshd binary:      " ;;
            esac
            ;;
        about_port)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="sshd 連接埠：        " ;;
                es) _mt_out="puerto sshd:        " ;;
                fr) _mt_out="port sshd :        " ;;
                de) _mt_out="sshd-Port:        " ;;
                zh-Hans) _mt_out="sshd 端口：        " ;;
                ja) _mt_out="sshd ポート:        " ;;
                ko) _mt_out="sshd 포트:        " ;;
                ar) _mt_out="منفذ sshd:        " ;;
                pt) _mt_out="porta sshd:        " ;;
                ru) _mt_out="порт sshd:        " ;;
                nl) _mt_out="sshd-poort:        " ;;
                el) _mt_out="θύρα sshd:        " ;;
                *) _mt_out="sshd port:        " ;;
            esac
            ;;
        about_running_yes)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="sshd 執行中：     是" ;;
                es) _mt_out="sshd en ejecución:     sí" ;;
                fr) _mt_out="sshd en cours :     oui" ;;
                de) _mt_out="sshd läuft:     ja" ;;
                zh-Hans) _mt_out="sshd 运行中：     是" ;;
                ja) _mt_out="sshd 実行中:     はい" ;;
                ko) _mt_out="sshd 실행 중:     예" ;;
                ar) _mt_out="sshd يعمل:     نعم" ;;
                pt) _mt_out="sshd em execução:     sim" ;;
                ru) _mt_out="sshd работает:     да" ;;
                nl) _mt_out="sshd actief:     ja" ;;
                el) _mt_out="sshd σε εκτέλεση:     ναι" ;;
                *) _mt_out="sshd running:     yes" ;;
            esac
            ;;
        about_running_no)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="sshd 執行中：     否" ;;
                es) _mt_out="sshd en ejecución:     no" ;;
                fr) _mt_out="sshd en cours :     non" ;;
                de) _mt_out="sshd läuft:     nein" ;;
                zh-Hans) _mt_out="sshd 运行中：     否" ;;
                ja) _mt_out="sshd 実行中:     いいえ" ;;
                ko) _mt_out="sshd 실행 중:     아니요" ;;
                ar) _mt_out="sshd يعمل:     لا" ;;
                pt) _mt_out="sshd em execução:     não" ;;
                ru) _mt_out="sshd работает:     нет" ;;
                nl) _mt_out="sshd actief:     nee" ;;
                el) _mt_out="sshd σε εκτέλεση:     όχι" ;;
                *) _mt_out="sshd running:     no" ;;
            esac
            ;;
        about_unit)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="sshd 單元：        " ;;
                es) _mt_out="unidad sshd:        " ;;
                fr) _mt_out="unité sshd :        " ;;
                de) _mt_out="sshd-Unit:        " ;;
                zh-Hans) _mt_out="sshd 单元：        " ;;
                ja) _mt_out="sshd ユニット:        " ;;
                ko) _mt_out="sshd 유닛:        " ;;
                ar) _mt_out="وحدة sshd:        " ;;
                pt) _mt_out="unidade sshd:        " ;;
                ru) _mt_out="юнит sshd:        " ;;
                nl) _mt_out="sshd-unit:        " ;;
                el) _mt_out="μονάδα sshd:        " ;;
                *) _mt_out="sshd unit:        " ;;
            esac
            ;;
        about_active)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="active" ;;
                es) _mt_out="active" ;;
                fr) _mt_out="active" ;;
                de) _mt_out="active" ;;
                zh-Hans) _mt_out="active" ;;
                ja) _mt_out="active" ;;
                ko) _mt_out="active" ;;
                ar) _mt_out="نشط" ;;
                pt) _mt_out="ativo" ;;
                ru) _mt_out="активен" ;;
                nl) _mt_out="actief" ;;
                el) _mt_out="ενεργό" ;;
                *) _mt_out="active" ;;
            esac
            ;;
        about_none)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="無" ;;
                es) _mt_out="ninguna" ;;
                fr) _mt_out="aucune" ;;
                de) _mt_out="keine" ;;
                zh-Hans) _mt_out="无" ;;
                ja) _mt_out="なし" ;;
                ko) _mt_out="없음" ;;
                ar) _mt_out="لا شيء" ;;
                pt) _mt_out="nenhum" ;;
                ru) _mt_out="нет" ;;
                nl) _mt_out="geen" ;;
                el) _mt_out="κανένα" ;;
                *) _mt_out="none" ;;
            esac
            ;;
        about_useful)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="實用指令：" ;;
                es) _mt_out="Comandos útiles:" ;;
                fr) _mt_out="Commandes utiles :" ;;
                de) _mt_out="Nützliche Befehle:" ;;
                zh-Hans) _mt_out="实用命令：" ;;
                ja) _mt_out="便利なコマンド:" ;;
                ko) _mt_out="유용한 명령:" ;;
                ar) _mt_out="أوامر مفيدة:" ;;
                pt) _mt_out="Comandos úteis:" ;;
                ru) _mt_out="Полезные команды:" ;;
                nl) _mt_out="Handige opdrachten:" ;;
                el) _mt_out="Χρήσιμες εντολές:" ;;
                *) _mt_out="Useful commands:" ;;
            esac
            ;;
        about_full_usage)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="完整用法" ;;
                es) _mt_out="Uso completo" ;;
                fr) _mt_out="Utilisation complète" ;;
                de) _mt_out="Vollständige Verwendung" ;;
                zh-Hans) _mt_out="完整用法" ;;
                ja) _mt_out="詳しい使い方" ;;
                ko) _mt_out="전체 사용법" ;;
                ar) _mt_out="الاستخدام الكامل" ;;
                pt) _mt_out="Uso completo" ;;
                ru) _mt_out="Полное использование" ;;
                nl) _mt_out="Volledig gebruik" ;;
                el) _mt_out="Πλήρης χρήση" ;;
                *) _mt_out="Full usage" ;;
            esac
            ;;
        about_cmd_update)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="更新到最新版本" ;;
                es) _mt_out="Actualizar a la última versión" ;;
                fr) _mt_out="Mettre à jour vers la dernière version" ;;
                de) _mt_out="Auf die neueste Version aktualisieren" ;;
                zh-Hans) _mt_out="更新到最新版本" ;;
                ja) _mt_out="最新バージョンへ更新" ;;
                ko) _mt_out="최신 버전으로 업데이트" ;;
                ar) _mt_out="التحديث إلى أحدث إصدار" ;;
                pt) _mt_out="Atualizar para a versão mais recente" ;;
                ru) _mt_out="Обновить до последней версии" ;;
                nl) _mt_out="Bijwerken naar de nieuwste versie" ;;
                el) _mt_out="Ενημέρωση στην πιο πρόσφατη έκδοση" ;;
                *) _mt_out="Update to latest version" ;;
            esac
            ;;
        about_cmd_remove)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="從系統乾淨移除" ;;
                es) _mt_out="Retirada limpia del sistema" ;;
                fr) _mt_out="Retrait propre du système" ;;
                de) _mt_out="Sauberes Entfernen vom System" ;;
                zh-Hans) _mt_out="从系统干净移除" ;;
                ja) _mt_out="システムからきれいに削除" ;;
                ko) _mt_out="시스템에서 깨끗이 제거" ;;
                ar) _mt_out="إزالة نظيفة من النظام" ;;
                pt) _mt_out="Remoção limpa do sistema" ;;
                ru) _mt_out="Чистое удаление из системы" ;;
                nl) _mt_out="Schone verwijdering van het systeem" ;;
                el) _mt_out="Καθαρή αφαίρεση από το σύστημα" ;;
                *) _mt_out="Clean removal from system" ;;
            esac
            ;;
        about_footer)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="執行 '${APP_NAME} help' 可看完整用法。" ;;
                es) _mt_out="Ejecute '${APP_NAME} help' para la información de uso completa." ;;
                fr) _mt_out="Lancez '${APP_NAME} help' pour l'information d'utilisation complète." ;;
                de) _mt_out="Führen Sie '${APP_NAME} help' für die vollständige Verwendung aus." ;;
                zh-Hans) _mt_out="运行 '${APP_NAME} help' 可看完整用法。" ;;
                ja) _mt_out="詳しい使い方は '${APP_NAME} help' を実行。" ;;
                ko) _mt_out="전체 사용법은 '${APP_NAME} help' 를 실행." ;;
                ar) _mt_out="شغّل '${APP_NAME} help' لمعلومات الاستخدام الكاملة." ;;
                pt) _mt_out="Execute '${APP_NAME} help' para a informação de uso completa." ;;
                ru) _mt_out="Выполните '${APP_NAME} help' для полной информации об использовании." ;;
                nl) _mt_out="Voer '${APP_NAME} help' uit voor de volledige gebruiksinformatie." ;;
                el) _mt_out="Εκτελέστε '${APP_NAME} help' για πλήρεις πληροφορίες χρήσης." ;;
                *) _mt_out="Run '${APP_NAME} help' for complete usage information." ;;
            esac
            ;;
        lang_ar_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用阿拉伯文" ;;
                es) _mt_out="usar árabe en este menú" ;;
                fr) _mt_out="utiliser l'arabe pour ce menu" ;;
                de) _mt_out="Arabisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用阿拉伯文" ;;
                ja) _mt_out="このメニューをアラビア語にする" ;;
                ko) _mt_out="이 메뉴를 아랍어로" ;;
                ar) _mt_out="استخدام العربية لهذه القائمة" ;;
                pt) _mt_out="usar árabe neste menu" ;;
                ru) _mt_out="использовать арабский для этого меню" ;;
                nl) _mt_out="Arabisch voor dit menu gebruiken" ;;
                el) _mt_out="χρήση αραβικών για αυτό το μενού" ;;
                *) _mt_out="use Arabic for this menu" ;;
            esac
            ;;
        lang_pt_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用葡萄牙文" ;;
                es) _mt_out="usar portugués en este menú" ;;
                fr) _mt_out="utiliser le portugais pour ce menu" ;;
                de) _mt_out="Portugiesisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用葡萄牙文" ;;
                ja) _mt_out="このメニューをポルトガル語にする" ;;
                ko) _mt_out="이 메뉴를 포르투갈어로" ;;
                ar) _mt_out="استخدام البرتغالية لهذه القائمة" ;;
                pt) _mt_out="usar português neste menu" ;;
                ru) _mt_out="использовать португальский для этого меню" ;;
                nl) _mt_out="Portugees voor dit menu gebruiken" ;;
                el) _mt_out="χρήση πορτογαλικών για αυτό το μενού" ;;
                *) _mt_out="use Portuguese for this menu" ;;
            esac
            ;;
        lang_ru_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用俄文" ;;
                es) _mt_out="usar ruso en este menú" ;;
                fr) _mt_out="utiliser le russe pour ce menu" ;;
                de) _mt_out="Russisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用俄文" ;;
                ja) _mt_out="このメニューをロシア語にする" ;;
                ko) _mt_out="이 메뉴를 러시아어로" ;;
                ar) _mt_out="استخدام الروسية لهذه القائمة" ;;
                pt) _mt_out="usar russo neste menu" ;;
                ru) _mt_out="использовать русский для этого меню" ;;
                nl) _mt_out="Russisch voor dit menu gebruiken" ;;
                el) _mt_out="χρήση ρωσικών για αυτό το μενού" ;;
                *) _mt_out="use Russian for this menu" ;;
            esac
            ;;
        lang_nl_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用荷蘭文" ;;
                es) _mt_out="usar neerlandés en este menú" ;;
                fr) _mt_out="utiliser le néerlandais pour ce menu" ;;
                de) _mt_out="Niederländisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用荷兰文" ;;
                ja) _mt_out="このメニューをオランダ語にする" ;;
                ko) _mt_out="이 메뉴를 네덜란드어로" ;;
                ar) _mt_out="استخدام الهولندية لهذه القائمة" ;;
                pt) _mt_out="usar neerlandês neste menu" ;;
                ru) _mt_out="использовать нидерландский для этого меню" ;;
                nl) _mt_out="Nederlands voor dit menu gebruiken" ;;
                el) _mt_out="χρήση ολλανδικών για αυτό το μενού" ;;
                *) _mt_out="use Dutch for this menu" ;;
            esac
            ;;
        lang_el_long)
            case "${_mt_lang}" in
                zh-Hant) _mt_out="這個選單改用希臘文" ;;
                es) _mt_out="usar griego en este menú" ;;
                fr) _mt_out="utiliser le grec pour ce menu" ;;
                de) _mt_out="Griechisch für dieses Menü verwenden" ;;
                zh-Hans) _mt_out="这个菜单改用希腊文" ;;
                ja) _mt_out="このメニューをギリシャ語にする" ;;
                ko) _mt_out="이 메뉴를 그리스어로" ;;
                ar) _mt_out="استخدام اليونانية لهذه القائمة" ;;
                pt) _mt_out="usar grego neste menu" ;;
                ru) _mt_out="использовать греческий для этого меню" ;;
                nl) _mt_out="Grieks voor dit menu gebruiken" ;;
                el) _mt_out="χρήση ελληνικών για αυτό το μενού" ;;
                *) _mt_out="use Greek for this menu" ;;
            esac
            ;;
        *)
            _mt_out="${_mt_key}"
            ;;
    esac
    printf '%s' "${_mt_out}"
    unset _mt_key _mt_extra _mt_lang _mt_out
}

# Last updated: 2026-10-14
# ALIGNMENT: requirement-shell-cli-language.md · requirement-shell-cli-default-interaction.md
# Parent 7. Language rows are reserved 70-89 (at most 20 languages).
# Assigned: 71 en, 72 zh-Hans, 73 zh-Hant, 74 es, 75 ar, 76 fr,
# 77 pt, 78 ru, 79 de, 80 ja, 81 ko, 82 nl, 83 el.
# 70 and 84-89 stay unprinted. Each assigned row returns to the front board.
# 0 / empty / EOF is Back. The choice is a current-shell input builtin.
app_cmd_menu_language() {
    while true; do
        out_info "**${APP_NAME}**(*${VERSION}*) — $(app_menu_text cat_language)"
        out_menu_choice "71" "English" "$(app_menu_text lang_en_long)"
        out_menu_choice "72" "简体中文" "$(app_menu_text lang_zh_hans_long)"
        out_menu_choice "73" "繁體中文" "$(app_menu_text lang_zh_long)"
        out_menu_choice "74" "Español" "$(app_menu_text lang_es_long)"
        out_menu_choice "75" "العربية" "$(app_menu_text lang_ar_long)"
        out_menu_choice "76" "Français" "$(app_menu_text lang_fr_long)"
        out_menu_choice "77" "Português" "$(app_menu_text lang_pt_long)"
        out_menu_choice "78" "Русский" "$(app_menu_text lang_ru_long)"
        out_menu_choice "79" "Deutsch" "$(app_menu_text lang_de_long)"
        out_menu_choice "80" "日本語" "$(app_menu_text lang_ja_long)"
        out_menu_choice "81" "한국어" "$(app_menu_text lang_ko_long)"
        out_menu_choice "82" "Nederlands" "$(app_menu_text lang_nl_long)"
        out_menu_choice "83" "Ελληνικά" "$(app_menu_text lang_el_long)"
        out_plain "$(app_menu_text line_back)"
        out_msg_n "$(app_menu_text line_prompt)"
        _choice=""
        if ! read -r _choice; then
            unset _choice
            return 0
        fi
        case "${_choice}" in
            71|english|en|English)
                if app_lang_save en; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            72|simplified-chinese|zh-hans|zh-Hans|简体中文)
                if app_lang_save zh-Hans; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            73|traditional-chinese|zh-hant|zh-Hant|繁體中文)
                if app_lang_save zh-Hant; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            74|spanish|es|Español|español)
                if app_lang_save es; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            75|arabic|ar|العربية|عربي)
                if app_lang_save ar; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            76|french|fr|Français|français)
                if app_lang_save fr; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            77|portuguese|pt|Português|português|portugues)
                if app_lang_save pt; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            78|russian|ru|Русский|русский)
                if app_lang_save ru; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            79|german|de|Deutsch|deutsch)
                if app_lang_save de; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            80|japanese|ja|日本語)
                if app_lang_save ja; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            81|korean|ko|한국어)
                if app_lang_save ko; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            82|dutch|nl|Nederlands|nederlands)
                if app_lang_save nl; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            83|greek|el|Ελληνικά|ελληνικά)
                if app_lang_save el; then
                    out_info "$(app_menu_text lang_saved)"
                else
                    out_warn "$(app_menu_text lang_save_fail)"
                fi
                unset _choice
                return 0
                ;;
            0|q|"")
                unset _choice
                return 0
                ;;
            *)
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
        esac
    done
}

# Last updated: 2026-09-28
# ALIGNMENT: requirement-shell-cli-default-interaction
# A valid leaf (or nested action board) returns to the front board. Unknown
# choice retries this layer. 0 / empty / EOF is Back.
app_cmd_menu_client() {
    _show_cfg=1
    if sshd_is_normal_user_only_cli; then
        _show_cfg=0
    fi
    while true; do
        out_info "**${APP_NAME}**(*${VERSION}*) — $(app_menu_text cat_client)"
        if [ "${_show_cfg}" -eq 0 ]; then
            out_info "$(app_menu_text hidden_client "$(sshd_host_normal_user_only_label)")"
        fi
        out_menu_choice "11" "dns" "$(app_menu_text client_11_long)"
        out_menu_choice "12" "ssh" "$(app_menu_text client_12_long)"
        out_menu_choice "13" "download" "$(app_menu_text client_13_long)"
        out_menu_choice "14" "upload" "$(app_menu_text client_14_long)"
        if [ "${_show_cfg}" -eq 1 ]; then
            out_menu_choice "15" "backup-config" "$(app_menu_text client_15_long)"
            out_menu_choice "16" "sync-config" "$(app_menu_text client_16_long)"
            out_plain "$(app_menu_text hint_sync_typed)"
        else
            out_menu_choice "18" "sync-from-remote" "$(app_menu_text client_18_long)"
        fi
        out_plain "$(app_menu_text line_back)"
        out_msg_n "$(app_menu_text line_prompt)"
        _choice=""
        if ! read -r _choice; then
            unset _choice _show_cfg
            return 0
        fi
        case "${_choice}" in
            11|dns)
                sshd_cmd_dns
                unset _choice _show_cfg
                return 0
                ;;
            12|ssh)
                sshd_cmd_ssh
                unset _choice _show_cfg
                return 0
                ;;
            13|download)
                sshd_cmd_download
                unset _choice _show_cfg
                return 0
                ;;
            14|upload)
                sshd_cmd_upload
                unset _choice _show_cfg
                return 0
                ;;
            15)
                if [ "${_show_cfg}" -eq 1 ]; then
                    sshd_cmd_backup_config
                    unset _choice _show_cfg
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            16)
                if [ "${_show_cfg}" -eq 1 ]; then
                    sshd_cmd_sync_config
                    unset _choice _show_cfg
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            18)
                if [ "${_show_cfg}" -eq 0 ]; then
                    sshd_cmd_sync_from_remote
                    unset _choice _show_cfg
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            0|q|"")
                unset _choice _show_cfg
                return 0
                ;;
            *)
                if sshd_menu_typed_leaf; then
                    unset _choice _show_cfg
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
        esac
    done
}

# Last updated: 2026-09-28
# ALIGNMENT: requirement-shell-cli-default-interaction
# A valid leaf returns to the front board. Unknown choice retries this layer.
# 0 / empty / EOF is Back.
app_cmd_menu_server() {
    _show_daemon=0
    if sshd_menu_show_daemon_rows; then
        _show_daemon=1
    fi
    while true; do
        out_info "**${APP_NAME}**(*${VERSION}*) — $(app_menu_text cat_server)"
        if [ "${_show_daemon}" -eq 0 ]; then
            out_info "$(app_menu_text hidden_server "$(sshd_os_name)")"
        fi
        out_menu_choice "21" "status" "$(app_menu_text server_21_long)"
        if [ "${_show_daemon}" -eq 1 ]; then
            out_menu_choice "22" "start" "$(app_menu_text server_22_long)"
            out_menu_choice "23" "stop" "$(app_menu_text server_23_long)"
            out_menu_choice "24" "restart" "$(app_menu_text server_24_long)"
        fi
        out_plain "$(app_menu_text line_back)"
        out_msg_n "$(app_menu_text line_prompt)"
        _choice=""
        if ! read -r _choice; then
            unset _choice _show_daemon
            return 0
        fi
        case "${_choice}" in
            21|status)
                sshd_cmd_status
                unset _choice _show_daemon
                return 0
                ;;
            22)
                if [ "${_show_daemon}" -eq 1 ]; then
                    sshd_cmd_start
                    unset _choice _show_daemon
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            23)
                if [ "${_show_daemon}" -eq 1 ]; then
                    sshd_cmd_stop
                    unset _choice _show_daemon
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            24)
                if [ "${_show_daemon}" -eq 1 ]; then
                    sshd_cmd_restart
                    unset _choice _show_daemon
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            0|q|"")
                unset _choice _show_daemon
                return 0
                ;;
            *)
                if sshd_menu_typed_leaf; then
                    unset _choice _show_daemon
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
        esac
    done
}

# Last updated: 2026-10-14
# ALIGNMENT: requirement-shell-cli-default-interaction
# A valid leaf returns to the front board. Unknown choice retries this layer.
# 0 / empty / EOF is Back. Children are 61-67 under front 6.
app_cmd_menu_self() {
    while true; do
        out_info "**${APP_NAME}**(*${VERSION}*) — $(app_menu_text cat_self)"
        out_menu_choice "61" "install" "$(app_menu_text self_61_long)"
        out_menu_choice "62" "version" "$(app_menu_text self_62_long)"
        out_menu_choice "63" "about" "$(app_menu_text self_63_long)"
        out_menu_choice "64" "version-check" "$(app_menu_text self_64_long)"
        out_menu_choice "65" "self-update" "$(app_menu_text self_65_long)"
        out_menu_choice "66" "self-uninstall" "$(app_menu_text self_66_long)"
        out_menu_choice "67" "self-install" "$(app_menu_text self_67_long)"
        out_plain "$(app_menu_text line_back)"
        out_msg_n "$(app_menu_text line_prompt)"
        _choice=""
        if ! read -r _choice; then
            unset _choice
            return 0
        fi
        case "${_choice}" in
            61|install)
                inst_perform_install
                unset _choice
                return 0
                ;;
            62|version)
                app_about
                unset _choice
                return 0
                ;;
            63|about)
                app_about
                unset _choice
                return 0
                ;;
            64|version-check)
                ver_check
                unset _choice
                return 0
                ;;
            65|self-update)
                inst_self_update
                unset _choice
                return 0
                ;;
            66|self-uninstall)
                inst_self_uninstall
                unset _choice
                return 0
                ;;
            67|self-install)
                inst_self_install
                unset _choice
                return 0
                ;;
            0|q|"")
                unset _choice
                return 0
                ;;
            *)
                if sshd_menu_typed_leaf; then
                    unset _choice
                    return 0
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
        esac
    done
}

# Last updated: 2026-10-14
# ALIGNMENT: requirement-shell-cli-default-interaction · requirement-shell-cli-language.md · requirement-shell-cli-zero-arguments
# Front board loops until Exit. Category rows open a submenu.
# POSIX Linux row 5 opens sudoers (51-55). Termux, Git Bash, and Windows cmd
# omit row 5 and print why before the numbers. Row 5 stays reserved when hidden.
# Row 6 opens self-management (61-67). Row 7 opens language.
# Rows 70-89 are reserved for at most 20 languages.
# Assigned: 71 English, 72 Simplified Chinese, 73 Traditional Chinese,
# 74 Spanish, 75 Arabic, 76 French, 77 Portuguese, 78 Russian, 79 German,
# 80 Japanese, 81 Korean, 82 Dutch, 83 Greek. 70 and 84-89 stay unprinted.
# A finished leaf redisplays this board. Unknown choice retries this layer.
# Front 8 is not a row.
app_cmd_menu() {
    if [ "${JSON}" -eq 1 ] || [ "${QUIET}" -eq 1 ] || [ "${TTY}" -ne 1 ]; then
        out_die "menu needs a terminal. Run a named command instead, for example: ${APP_NAME} status"
    fi
    _show_sudoers=1
    if sshd_is_normal_user_only_cli; then
        _show_sudoers=0
    fi
    while true; do
        out_info "**${APP_NAME}**(*${VERSION}*)"
        if [ "${_show_sudoers}" -eq 0 ]; then
            out_info "$(app_menu_text hidden_front "$(sshd_host_normal_user_only_label)")"
        fi
        out_menu_choice "1" "$(app_menu_text cat_client)" "$(app_menu_text front_client_long)"
        out_menu_choice "2" "$(app_menu_text cat_server)" "$(app_menu_text front_server_long)"
        if [ "${_show_sudoers}" -eq 1 ]; then
            out_menu_choice "5" "sudoers" "$(app_menu_text front_sudoers_long)"
        fi
        out_menu_choice "6" "$(app_menu_text cat_self)" "$(app_menu_text front_self_long)"
        out_menu_choice "7" "$(app_menu_text cat_language)" "$(app_menu_text front_language_long)"
        out_plain "$(app_menu_text line_exit)"
        out_msg_n "$(app_menu_text line_prompt)"
        _choice=""
        if ! read -r _choice; then
            unset _choice _show_sudoers
            return 0
        fi
        case "${_choice}" in
            1|client-side|用戶端|客户端|cliente|client|Client|クライアント|클라이언트|عميل|клиент|πελάτης) app_cmd_menu_client; continue ;;
            2|server-side|伺服器端|服务器端|servidor|serveur|Server|server|サーバー|서버|خادم|сервер|διακομιστής) app_cmd_menu_server; continue ;;
            5)
                if [ "${_show_sudoers}" -eq 1 ]; then
                    sshd_cmd_sudoers_menu
                    continue
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
            6|self-management|自我管理|autogestión|autogestão|autogestion|Selbstverwaltung|selbstverwaltung|自己管理|자기관리|إدارة-ذاتية|самоуправление|zelfbeheer|αυτοδιαχείριση) app_cmd_menu_self; continue ;;
            7|language|語言|语言|idioma|langue|Sprache|sprache|言語|언어|لغة|язык|taal|γλώσσα) app_cmd_menu_language; continue ;;
            9|99|999|exit|"")
                unset _choice _show_sudoers
                return 0
                ;;
            *)
                if sshd_menu_typed_leaf; then
                    continue
                fi
                out_warn "$(app_menu_text unknown_menu "${_choice}")"
                continue
                ;;
        esac
    done
}


app_about() {
    # --- Safe Variable Defaults ---
    : "${JSON:=0}"
    : "${QUIET:=0}"
    : "${APP_NAME:=sshd-cli}"
    # Version comes from global SSOT (VERSION="…" hard-assign near top); default only if unset
    : "${VERSION:=1.11.0}"
    if [ -n "${PREFIX-}" ] && [ -d "${PREFIX}/bin" ]; then
    : "${GLOBAL_BIN:=${PREFIX}/bin}"
else
    : "${GLOBAL_BIN:=/usr/local/bin}"
fi
    : "${USER_BIN:=${HOME}/.local/bin}"
    : "${SCRIPT_URL:=}"
    : "${USERNAME:=unknown}"
    : "${HOME:=/tmp}"

    # Cache + persistence (requirement-shell-cli-storage): resolve if main has not yet
    if [ -z "${EFFECTIVE_STORAGE_DIR:-}" ]; then
        EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)
    fi
    _cache_preferred=$(util_preferred_cache_dir)
    _cache_fallback=$(util_fallback_cache_dir)
    _cache_fallback_2=$(util_fallback2_cache_dir)
    STORAGE_DIR="${_cache_fallback}"
    if [ -z "${PERSISTENT_STORAGE_DIR:-}" ]; then
        PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)
    fi

    sshd_resolve
    SSHD_ABOUT_RUNNING="false"
    if sshd_running_pid >/dev/null 2>&1; then
        SSHD_ABOUT_RUNNING="true"
    fi
    SSHD_ABOUT_SYSTEMD="false"
    SSHD_ABOUT_UNIT=""
    SSHD_ABOUT_UNIT_ACTIVE="false"
    if sshd_is_systemd_host; then
        SSHD_ABOUT_SYSTEMD="true"
        SSHD_ABOUT_UNIT=$(sshd_systemd_unit || true)
        if [ -n "${SSHD_ABOUT_UNIT}" ] && sshd_systemd_is_active "${SSHD_ABOUT_UNIT}"; then
            SSHD_ABOUT_UNIT_ACTIVE="true"
        fi
    fi

    if [ "${JSON}" -eq 1 ]; then
        # === JSON MODE - Clean, machine-friendly output ===
        local installed="false"
        inst_is_installed && installed="true"

        local global_ver="not found"
        if [ -x "${GLOBAL_BIN}/${APP_NAME}" ]; then
            global_ver=$(grep '^VERSION="' "${GLOBAL_BIN}/${APP_NAME}" 2>/dev/null | cut -d'"' -f2 || echo "unknown")
        fi

        local local_ver="not found"
        if [ -x "${USER_BIN}/${APP_NAME}" ]; then
            local_ver=$(grep '^VERSION="' "${USER_BIN}/${APP_NAME}" 2>/dev/null | cut -d'"' -f2 || echo "unknown")
        fi

        local current_shell
        current_shell=$(util_get_current_shell)

        local interactive="false"
        [ -t 1 ] && interactive="true"

        local current_user
        current_user="$(id -un 2>/dev/null || echo "unknown")"

        out_json "about" "" \
            "app" "${APP_NAME}" \
            "version" "${VERSION}" \
            "installed" "${installed}" \
            "global_version" "${global_ver}" \
            "local_version" "${local_ver}" \
            "shell" "${current_shell}" \
            "interactive" "${interactive}" \
            "user" "${current_user}" \
            "cache_used" "${EFFECTIVE_STORAGE_DIR}" \
            "cache_preferred" "${_cache_preferred}" \
            "cache_fallback" "${_cache_fallback}" \
            "cache_fallback_2" "${_cache_fallback_2}" \
            "persistence_storage" "${PERSISTENT_STORAGE_DIR}" \
            "effective_storage" "${EFFECTIVE_STORAGE_DIR}" \
            "storage_dir" "${STORAGE_DIR}" \
            "sshd_platform" "${SSHD_PLATFORM:-}" \
            "sshd_bin" "${SSHD_BIN:-}" \
            "sshd_port" "${SSHD_PORT:-}" \
            "sshd_running" "${SSHD_ABOUT_RUNNING:-false}" \
            "sshd_systemd" "${SSHD_ABOUT_SYSTEMD:-false}" \
            "sshd_unit" "${SSHD_ABOUT_UNIT:-}" \
            "sshd_unit_active" "${SSHD_ABOUT_UNIT_ACTIVE:-false}"
        return 0
    fi

    # === Normal Human-readable Mode ===
    [ "${QUIET}" -eq 1 ] && return 0

    out_info "=== ${APP_NAME} ${VERSION} - $(app_menu_text about_title) ==="
    out_empty_line

    # Installation status
    if inst_is_installed; then
        out_success "$(app_menu_text about_installed)"
    else
        out_warn "$(app_menu_text about_missing)"
        if [ -n "${SCRIPT_URL}" ]; then
            out_info "$(app_menu_text about_recommend)"
        else
            out_info "$(app_menu_text about_set_url)curl -fsSL \"\${SCRIPT_URL}\" | sh"
        fi
    fi

    out_empty_line

    # Global vs Local installation details
    if [ -x "${GLOBAL_BIN}/${APP_NAME}" ]; then
        global_ver=$(grep '^VERSION="' "${GLOBAL_BIN}/${APP_NAME}" 2>/dev/null | cut -d'"' -f2 || echo "unknown")
        out_info "$(app_menu_text about_global)${GLOBAL_BIN}/${APP_NAME}):   ${global_ver}"
    else
        out_info "$(app_menu_text about_global)${GLOBAL_BIN}/${APP_NAME}):   $(app_menu_text about_not_found)"
    fi

    if [ -x "${USER_BIN}/${APP_NAME}" ]; then
        local_ver=$(grep '^VERSION="' "${USER_BIN}/${APP_NAME}" 2>/dev/null | cut -d'"' -f2 || echo "unknown")
        out_info "$(app_menu_text about_local)${USER_BIN}/${APP_NAME}):    ${local_ver}"
    else
        out_info "$(app_menu_text about_local)${USER_BIN}/${APP_NAME}):    $(app_menu_text about_not_found)"
    fi

    out_empty_line

    local current_user
    current_user="$(id -un 2>/dev/null || echo "unknown")"
    out_info "$(app_menu_text about_user)${current_user}"

    if [ "$(id -u)" -eq 0 ]; then
        out_success "$(app_menu_text about_root)"
    else
        out_info "$(app_menu_text about_login)"
    fi

    out_empty_line

    local current_shell
    current_shell=$(util_get_current_shell)

    out_info "$(app_menu_text about_shell)${current_shell}"

    if [ -t 1 ]; then
        out_info "$(app_menu_text about_tty_yes)"
    else
        out_info "$(app_menu_text about_tty_no)"
    fi

    out_empty_line
    out_info "$(app_menu_text about_cache_used)${EFFECTIVE_STORAGE_DIR}"
    out_info "$(app_menu_text about_cache_pref)${_cache_preferred}"
    out_info "$(app_menu_text about_cache_1)${_cache_fallback}"
    if [ -n "${_cache_fallback_2}" ]; then
        out_info "$(app_menu_text about_cache_2)${_cache_fallback_2}"
    fi
    out_info "$(app_menu_text about_persist)${PERSISTENT_STORAGE_DIR}"

    # --- DOMAIN_ABOUT_FIELDS (specializee injection) ---
    out_empty_line
    out_info "$(app_menu_text about_platform)${SSHD_PLATFORM}"
    if [ -n "${SSHD_BIN:-}" ]; then
        out_info "$(app_menu_text about_binary)${SSHD_BIN}"
    else
        out_info "$(app_menu_text about_binary)$(app_menu_text about_not_found)"
    fi
    out_info "$(app_menu_text about_port)${SSHD_PORT}"
    if [ "${SSHD_ABOUT_RUNNING}" = "true" ]; then
        out_success "$(app_menu_text about_running_yes)"
    else
        out_info "$(app_menu_text about_running_no)"
    fi
    if [ "${SSHD_ABOUT_SYSTEMD}" = "true" ]; then
        if [ -n "${SSHD_ABOUT_UNIT}" ]; then
            out_info "$(app_menu_text about_unit)${SSHD_ABOUT_UNIT} ($(app_menu_text about_active)=${SSHD_ABOUT_UNIT_ACTIVE})"
        else
            out_info "$(app_menu_text about_unit)$(app_menu_text about_none)"
        fi
    fi
    # --- end DOMAIN_ABOUT_FIELDS ---

    out_empty_line
    out_info "$(app_menu_text about_useful)"
    out_info "   ${APP_NAME} help           → $(app_menu_text about_full_usage)"
    out_info "   ${APP_NAME} self-update    → $(app_menu_text about_cmd_update)"
    out_info "   ${APP_NAME} self-uninstall → $(app_menu_text about_cmd_remove)"
    case "${APP_LANG:-en}" in
        zh-Hant) out_info "   ${APP_NAME} --json         → 機器可處理的輸出" ;;
        es) out_info "   ${APP_NAME} --json         → salida para máquinas" ;;
        fr) out_info "   ${APP_NAME} --json         → sortie pour les machines" ;;
        de) out_info "   ${APP_NAME} --json         → Ausgabe für Maschinen" ;;
        zh-Hans) out_info "   ${APP_NAME} --json         → 机器可处理的输出" ;;
        ja) out_info "   ${APP_NAME} --json         → 機械向けの出力" ;;
        ko) out_info "   ${APP_NAME} --json         → 기계용 출력" ;;
        ar) out_info "   ${APP_NAME} --json         → خرج للآلات" ;;
        pt) out_info "   ${APP_NAME} --json         → saída para máquinas" ;;
        ru) out_info "   ${APP_NAME} --json         → вывод для машин" ;;
        nl) out_info "   ${APP_NAME} --json         → uitvoer voor machines" ;;
        el) out_info "   ${APP_NAME} --json         → έξοδος για μηχανές" ;;
        *) out_info "   ${APP_NAME} --json         → Machine-readable output" ;;
    esac

    out_empty_line
    out_info "$(app_menu_text about_footer)"
}

app_version() {
    : "${APP_NAME:=sshd-cli}"
    : "${VERSION:=1.11.0}"
    : "${JSON:=0}"
    if [ "${JSON}" -eq 1 ]; then
        # Same machine contract as historical app_main inline path
        out_json "version" "" "app" "${APP_NAME}" "version" "${VERSION}"
    else
        out_info "${APP_NAME} version ${VERSION}"
    fi
}

# =============================================================================
# app_help() - Display help for selfmanaged
# =============================================================================
#
# Shows usage, available commands, and global flags.
# Fully respects --quiet and --json modes.
#
# In --json mode: returns a minimal success object instead of long text.
# In --quiet mode: prints nothing (silent).
#
# Keep in sync with requirement-shell-cli-interface.md command table.
# =============================================================================

app_help() {
    : "${SHORT_DESCRIPTION:=${APP_DESC:-Simplify Termux to install sshd}}"
    : "${DESCRIPTION:=POSIX /bin/sh CLI: simplify Termux to install and run OpenSSH sshd (status/start/stop/port/keys/dns) plus self-install; Linux host deposit of ~/.ssh/config (backup-config / sync-config / sync-from-remote).}"

    if [ "${JSON}" -eq 1 ]; then
        case "${APP_LANG:-en}" in
            zh-Hant) _help_note="說明文字在人類可讀模式。請不要加 --json。" ;;
            es) _help_note="El texto de ayuda está en el modo para personas. Ejecute sin --json." ;;
            fr) _help_note="Le texte d'aide est dans le mode pour les personnes. Lancez sans --json." ;;
            de) _help_note="Der Hilfetext steht im Modus für Menschen. Starten Sie ohne --json." ;;
            zh-Hans) _help_note="说明文字在人可读模式。请不要加 --json。" ;;
            ja) _help_note="説明は人が読むモードにあります。--json を付けずに実行してください。" ;;
            ko) _help_note="도움말 문장은 사람이 읽는 모드에 있습니다. --json 없이 실행하세요." ;;
            ar) _help_note="نص المساعدة في وضع الأشخاص. شغّل بدون --json." ;;
            pt) _help_note="O texto de ajuda está no modo para pessoas. Execute sem --json." ;;
            ru) _help_note="Текст справки в режиме для людей. Запустите без --json." ;;
            nl) _help_note="De helptekst staat in de modus voor mensen. Start zonder --json." ;;
            el) _help_note="Το κείμενο βοήθειας είναι στη λειτουργία για ανθρώπους. Εκτελέστε χωρίς --json." ;;
            *) _help_note="Help text available in human-readable mode. Run without --json." ;;
        esac
        out_json "success" "${_help_note}" \
            "command" "help" \
            "note" "$(app_menu_text help_json_note)"
        unset _help_note
        return 0
    fi

    if [ "${QUIET}" -eq 1 ]; then
        return 0
    fi

    out_info "${APP_NAME} — $(app_menu_text help_short)"
    out_plain "$(app_menu_text help_desc)"
    out_empty_line

    out_info "$(app_menu_text help_h_usage)"
    out_plain "  ${APP_NAME} $(app_menu_text help_usage_args)"
    out_empty_line

    out_info "$(app_menu_text help_h_self)"
    out_plain "  self-install         $(app_menu_text help_self_install)"
    out_plain "  install              $(app_menu_text help_install)"
    out_plain "  version              $(app_menu_text help_version)"
    out_plain "  about                $(app_menu_text help_about)"
    out_plain "  version-check        $(app_menu_text help_version_check)"
    out_plain "  self-update          $(app_menu_text help_self_update)"
    out_plain "  self-uninstall       $(app_menu_text help_self_uninstall)"
    out_plain "  help                 $(app_menu_text help_help)"
    out_empty_line

    # --- DOMAIN_HELP_ROWS (specializee injection) ---
    out_info "$(app_menu_text help_h_domain)"
    out_plain "  status               $(app_menu_text help_status)"
    out_plain "  start                $(app_menu_text help_start)"
    out_plain "  stop                 $(app_menu_text help_stop)"
    out_plain "  restart              $(app_menu_text help_restart)"
    out_plain "  port [N]             $(app_menu_text help_port)"
    out_plain "  config               $(app_menu_text help_config)"
    out_plain "  host-keys [list|generate]  $(app_menu_text help_host_keys)"
    out_plain "  auth-keys [list|add <file>]  $(app_menu_text help_auth_keys)"
    out_plain "  dns [list|show N|edit N|set N …|add …|delete N|unset N field …]  $(app_menu_text help_dns)"
    out_plain "  fix-config [--input-file PATH] [--output-file PATH]  $(app_menu_text help_fix_config)"
    out_plain "  ssh [N|name]         $(app_menu_text help_ssh)"
    out_plain "  download [N|name] [folder]  $(app_menu_text help_download)"
    out_plain "  upload [N|name] [folder]  $(app_menu_text help_upload)"
    out_plain "  backup-config        $(app_menu_text help_backup)"
    out_plain "  sync-config          $(app_menu_text help_sync)"
    out_plain "  sync-from-remote [SPEC]  $(app_menu_text help_sync_remote)"
    out_plain "  print-sudoers        $(app_menu_text help_print_sudoers)"
    out_plain "  print-sudoers-install-script  $(app_menu_text help_print_script)"
    out_plain "  generate-sudoer-request [path]  $(app_menu_text help_generate)"
    out_plain "  submit-sudoer-request [file]  $(app_menu_text help_submit)"
    out_plain "  remove-project-sudoers [path]  $(app_menu_text help_remove)"
    out_plain "  menu                 $(app_menu_text help_menu)"
    out_empty_line
    out_info "$(app_menu_text help_h_termux)"
    out_plain "  wake-lock            $(app_menu_text help_wake_lock)"
    out_plain "  wake-unlock          $(app_menu_text help_wake_unlock)"
    out_empty_line
    # --- end DOMAIN_HELP_ROWS ---

    out_info "$(app_menu_text help_h_tests)"
    out_plain "  rc-test              $(app_menu_text help_rc_test)"
    out_empty_line

    out_info "$(app_menu_text help_h_options)"
    out_plain "  --quiet, -q          $(app_menu_text help_quiet)"
    case "${APP_LANG:-en}" in
        zh-Hant) out_plain "  --json               機器可處理的 JSON（同時視為 --quiet）" ;;
        es) out_plain "  --json               JSON para máquinas (implica --quiet)" ;;
        fr) out_plain "  --json               JSON pour les machines (implique --quiet)" ;;
        de) out_plain "  --json               JSON für Maschinen (schließt --quiet ein)" ;;
        zh-Hans) out_plain "  --json               机器可处理的 JSON（同时视为 --quiet）" ;;
        ja) out_plain "  --json               機械向け JSON（--quiet を含む）" ;;
        ko) out_plain "  --json               기계용 JSON(--quiet 포함)" ;;
        ar) out_plain "  --json               JSON للآلات (يعني --quiet)" ;;
        pt) out_plain "  --json               JSON para máquinas (implica --quiet)" ;;
        ru) out_plain "  --json               JSON для машин (включает --quiet)" ;;
        nl) out_plain "  --json               JSON voor machines (houdt --quiet in)" ;;
        el) out_plain "  --json               JSON για μηχανές (συνεπάγεται --quiet)" ;;
        *) out_plain "  --json               Machine-readable JSON (implies --quiet)" ;;
    esac
    out_plain "  --force              $(app_menu_text help_force)"
    out_plain "  --debug              $(app_menu_text help_debug)"
    out_empty_line

    # Effective channel values (Config SSOT / env override) so help is actionable.
    # CHECKSUM is an install-path runtime pin only — never listed here (requirement-shell-automatic-checksum).
    : "${REPO_USER:=cloudgen}"
    : "${REPO_NAME:=sshd-cli}"
    : "${SCRIPT_URL:=}"
    : "${HOME:=/tmp}"
    : "${BASHRC:=${HOME}/.bashrc}"

    out_info "$(app_menu_text help_h_env)"
    out_plain "  REPO_USER            ${REPO_USER}"
    out_plain "                       $(app_menu_text help_repo_user)"
    out_plain "  REPO_NAME            ${REPO_NAME}"
    out_plain "                       $(app_menu_text help_repo_name)"
    if [ -n "${SCRIPT_URL}" ]; then
        out_plain "  SCRIPT_URL           ${SCRIPT_URL}"
    else
        out_plain "  SCRIPT_URL           $(app_menu_text help_url_unset)"
    fi
    out_plain "                       $(app_menu_text help_url_desc)"
    out_plain "  BASHRC               ${BASHRC}"
    out_plain "                       $(app_menu_text help_bashrc)"
    out_plain "  SSHD_CLI_ROOT        $(app_menu_text help_root)"
    out_plain "  SSHD_CLI_REMOTE_ROOT $(app_menu_text help_remote_root)"
    out_plain "  SSHD_CLI_SCP         $(app_menu_text help_scp)"
    out_plain "  SSHD_CLI_SSH         $(app_menu_text help_ssh_bin)"
    out_empty_line
}


# =============================================================================
# app_main() - Main entrypoint and command dispatcher
# =============================================================================
#
# GENERAL PURPOSE:
# Thin dispatcher for the selfmanaged CLI (Type 0 only).
# Handles:
#   - Auto-install behavior for classic `curl | sh` one-liner (zero arguments)
#   - Global flag parsing (--quiet, --json, --debug, --force)
#   - Command routing for all Type 0 self-management commands
#
# This is the single entry point when the script is executed directly.
#
# CIAO PRINCIPLES APPLIED:
# - Caution (Principle 1): Never call undefined functions. Always use inst_is_installed.
#   Auto-install block is kept at the very top as required by existing comments.
# - Intentional (Principle 2): All supported commands from
#   requirement-shell-cli-interface.md and app_help() are recognized and routed.
# - Anti-fragile (Principle 3): Works correctly in interactive TTY, quiet, JSON,
#   and non-interactive `curl | sh` environments.
# - Over-protect (Principle 18): Explicit if/then logic, safe defaults, and centralized
#   output via out_die for unknown commands.
#
# !!! DO NOT MODIFY OR SIMPLIFY THIS FUNCTION !!!
# This is the central command dispatcher. Changes here affect every execution path.
#
# Lessons Learned (CIAO Reflection):
# 2026-06-26:
#   - Original version called non-existent functions and only recognized
#     version/about/help; expanded routing and safe defaults.
# 2026-07-12:
#   - Wired --force → FORCE=1 and FORCE_REINSTALL=1 (requirement-shell-cli-interface).
# 2026-07-14:
#   - version routes through app_version (no dual inline path).
#   - zero-arg install propagates failure exit status.
#   - Type O empty argv: always install-ensure (not help when already installed).
#     Cases A/B/C (not installed / local / global). --force only for deliberate
#     re-download/replace — not required for a second one-liner run.
#     SSOT: requirement-shell-cli-zero-arguments.md (selfmanaged = Type O).
# 2026-08-11:
#   - Specializee injection anchors (DOMAIN_DISPATCH_*) for A→B products; empty
#     argv remains Type O — domain setup uses explicit verbs only.
# 2026-09-05:
#   - Empty argv split: interactive (TTY, not quiet/json) → domain menu;
#     non-interactive / curl|sh / quiet / json → Type O install-ensure.
#     SSOT: requirement-shell-cli-zero-arguments.md
# 2026-09-28:
#   - Zero-cli-verb is no command after switches. The same split runs for a
#     no-token line and again after flag parse when COMMAND is still empty.
#     --debug / --force with no verb stay no command. --quiet / --json with
#     no verb are non-interactive (CLI self-install, not help).
#     SSOT: requirement-shell-cli-zero-arguments.md
#     requirement-shell-cli-default-interaction.md
#     requirement-shell-cli-self-install.md
# 2026-09-30:
#   - Every run comments unsupported OpenSSH client keywords in
#     ~/.ssh/config before dispatch, including a zero-cli-verb. Silent.
#     SSOT: requirement-domain-sshd.md
#
# Last updated: 2026-09-30
# Cache resolve is per login and per process. A missed tier is silent.
# =============================================================================

app_main() {
    # --- Safe Variable Defaults ---
    # Empty until a routed-verb token sets it. Help is the explicit verb only.
    : "${COMMAND:=}"
    : "${DOMAIN_OPERANDS:=}"
    : "${RC_TEST_OPERANDS:=}"
    : "${QUIET:=0}"
    : "${JSON:=0}"
    : "${DEBUG:=0}"
    : "${FORCE:=0}"
    : "${FORCE_REINSTALL:=0}"

    # Cache folder for this run (requirement-shell-cli-storage).
    # Linux: /dev/shm/cache leaf, then /tmp/cache, then ${HOME}/.cache.
    # Git Bash: /tmp/cache, then AppData Local Temp. Mac adds ${HOME}/cache.
    # A missed tier is silent. Die only if every tier failed.
    # Export TMPDIR so mktemp -t lands under this process cache leaf.
    : "${USERNAME:=unknown}"
    : "${HOME:=/tmp}"
    EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)
    STORAGE_DIR=$(util_fallback_cache_dir)
    PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)
    export EFFECTIVE_STORAGE_DIR STORAGE_DIR PERSISTENT_STORAGE_DIR
    export TMPDIR="${EFFECTIVE_STORAGE_DIR}"

    # One language load for help, about, and the menu.
    # requirement-shell-cli-language.md
    app_lang_load

    # Comment unsupported OpenSSH client keywords in ~/.ssh/config.
    # Silent. Missing file is a no-op. Runs before every dispatch, including
    # a zero-cli-verb. requirement-domain-sshd.md
    sshd_fix_config_auto

    # === ZERO-CLI-VERB (no-token fast path) ===
    # Interactive (TTY=1, not quiet/json): main menu (app_cmd_menu).
    # Non-interactive (pipe / curl|sh / quiet / json / no TTY): CLI self-install
    # (not payload install). The same split runs after flag parse when no
    # routed-verb remains (switches are not a verb).
    # SSOT: requirement-shell-cli-zero-arguments.md ·
    # requirement-shell-cli-default-interaction.md ·
    # requirement-shell-cli-self-install.md
    if [ $# -eq 0 ]; then
        if [ "${TTY}" -eq 1 ] && [ "${JSON}" -eq 0 ] && [ "${QUIET}" -eq 0 ]; then
            app_cmd_menu
            exit $?
        fi
        inst_self_install
        exit $?
    fi

    # === Argument parsing: flags and commands (order-independent) ===
    while [ $# -gt 0 ]; do
        case "$1" in
            --quiet|-q) QUIET=1 ;;
            --json)     JSON=1; QUIET=1 ;;
            --debug)    DEBUG=1 ;;
            --force)    FORCE=1; FORCE_REINSTALL=1 ;;
            --allow-test-local)
                ALLOW_TEST_LOCAL_SUDOERS=1
                export ALLOW_TEST_LOCAL_SUDOERS
                ;;
            --update)
                SUBMIT_ACTION="update"
                SUBMIT_ACTION_EXPLICIT=1
                export SUBMIT_ACTION SUBMIT_ACTION_EXPLICIT
                ;;
            --add)
                SUBMIT_ACTION="add"
                SUBMIT_ACTION_EXPLICIT=1
                export SUBMIT_ACTION SUBMIT_ACTION_EXPLICIT
                ;;
            --purpose)
                if [ $# -lt 2 ]; then
                    out_die "--purpose requires TEXT"
                fi
                SUBMIT_PURPOSE="$2"
                export SUBMIT_PURPOSE
                shift
                ;;
            # --- DOMAIN_DISPATCH_FLAGS (specializee injection) ---
            # Specialized products MAY parse domain-only flags here (e.g. --no-cloudflare).
            # --- end DOMAIN_DISPATCH_FLAGS ---
            version|about|help|version-check|self-update|self-uninstall|self-install|install|rc-test)
                COMMAND="$1"
                ;;
            # --- DOMAIN_DISPATCH_COMMANDS (specializee injection) ---
            status|start|stop|restart|port|config|host-keys|auth-keys|dns|fix-config|ssh|download|upload|menu|main|wake-lock|wake-unlock|backup-config|sync-config|sync-from-remote|print-sudoers|print-sudoers-install-script|generate-sudoer-request|submit-sudoer-request|remove-project-sudoers)
                case "${COMMAND}" in
                    port|host-keys|auth-keys|dns|fix-config|ssh|download|upload|sync-from-remote|print-sudoers|print-sudoers-install-script|generate-sudoer-request|submit-sudoer-request|remove-project-sudoers)
                        if [ "${COMMAND}" = "dns" ] && [ -z "$1" ]; then
                            _op='""'
                        else
                            _op="$1"
                        fi
                        if [ -n "${DOMAIN_OPERANDS}" ]; then
                            DOMAIN_OPERANDS="${DOMAIN_OPERANDS} ${_op}"
                        else
                            DOMAIN_OPERANDS="${_op}"
                        fi
                        unset _op
                        ;;
                    *)
                        COMMAND="$1"
                        ;;
                esac
                ;;
            # --- end DOMAIN_DISPATCH_COMMANDS ---
            *)
                case "${COMMAND}" in
                    rc-test)
                        if [ -n "${RC_TEST_OPERANDS}" ]; then
                            RC_TEST_OPERANDS="${RC_TEST_OPERANDS} $1"
                        else
                            RC_TEST_OPERANDS="$1"
                        fi
                        ;;
                    port|host-keys|auth-keys|dns|fix-config|ssh|download|upload|sync-from-remote|print-sudoers|print-sudoers-install-script|generate-sudoer-request|submit-sudoer-request|remove-project-sudoers)
                        if [ "${COMMAND}" = "dns" ] && [ -z "$1" ]; then
                            _op='""'
                        else
                            _op="$1"
                        fi
                        if [ -n "${DOMAIN_OPERANDS}" ]; then
                            DOMAIN_OPERANDS="${DOMAIN_OPERANDS} ${_op}"
                        else
                            DOMAIN_OPERANDS="${_op}"
                        fi
                        unset _op
                        ;;
                    *)
                        out_die "Unknown command or flag: $1. See '${APP_NAME} help'."
                        ;;
                esac
                ;;
        esac
        shift
    done

    # Zero-cli-verb after switches. --debug / --force are not a verb.
    # --quiet / --json with no verb are non-interactive (CLI self-install).
    # requirement-shell-cli-zero-arguments.md
    if [ -z "${COMMAND}" ]; then
        if [ "${TTY}" -eq 1 ] && [ "${JSON}" -eq 0 ] && [ "${QUIET}" -eq 0 ]; then
            app_cmd_menu
            exit $?
        fi
        inst_self_install
        exit $?
    fi

    out_debug "dispatch command=${COMMAND} quiet=${QUIET} json=${JSON} force=${FORCE}"

    case "${COMMAND}" in
        version)
            app_version
            ;;
        about)
            app_about
            ;;
        version-check)
            ver_check
            ;;
        self-update)
            inst_self_update
            ;;
        self-uninstall)
            inst_self_uninstall
            ;;
        self-install)
            inst_self_install
            ;;
        install)
            inst_perform_install
            ;;
        rc-test)
            # shellcheck disable=SC2086
            set -- ${RC_TEST_OPERANDS}
            path_rc_test "$@"
            ;;
        # --- DOMAIN_DISPATCH_ROUTES (specializee injection) ---
        # No systemd / systemctl / termux-services / sv-enable / add-crontab / enable-service.
        # requirement-domain-sshd: start is OpenSSH daemonize.
        status) sshd_cmd_status ;;
        start) sshd_cmd_start ;;
        stop) sshd_cmd_stop ;;
        restart) sshd_cmd_restart ;;
        port)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_port "${1-}"
            ;;
        config) sshd_cmd_config ;;
        host-keys)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_host_keys "${1:-list}"
            ;;
        auth-keys)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_auth_keys "${1:-list}" "${2-}"
            ;;
        dns)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_dns "$@"
            ;;
        fix-config)
            # shellcheck disable=SC2086
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_fix_config "$@"
            ;;
        ssh)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_ssh "$@"
            ;;
        download)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_download "$@"
            ;;
        upload)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_upload "$@"
            ;;
        menu|main) app_cmd_menu ;;
        wake-lock) sshd_cmd_wake_lock ;;
        wake-unlock) sshd_cmd_wake_unlock ;;
        backup-config) sshd_cmd_backup_config ;;
        sync-config) sshd_cmd_sync_config ;;
        sync-from-remote)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_sync_from_remote "${1-}"
            ;;
        print-sudoers)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_print_sudoers "${1-}"
            ;;
        print-sudoers-install-script)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_print_sudoers_install_script "${1-}"
            ;;
        generate-sudoer-request)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_generate_sudoer_request "${1-}"
            ;;
        submit-sudoer-request)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_submit_sudoer_request "${1-}"
            ;;
        remove-project-sudoers)
            set -- ${DOMAIN_OPERANDS}
            sshd_cmd_remove_project_sudoers "${1-}"
            ;;
        # --- end DOMAIN_DISPATCH_ROUTES ---
        help|*)
            app_help
            ;;
    esac
}


# =============================================================================
# BOOTSTRAP
# =============================================================================
#
# Always invoke the single dispatcher. Do NOT gate on ${0##*/} matching APP_NAME:
# under curl | sh / stdin pipe, $0 is the shell (sh/bash/…), not the product
# filename — a basename gate causes silent no-op and breaks one-liner install.
# Product law: requirement-shell-cli-zero-arguments.md (TTY menu) +
# requirement-shell-cli-self-install.md (non-TTY CLI place) +
# requirement-shell-cli-interface.md (single app_main entry). Historical: INC-20260712-001.
#
# Single-file install CLI: source-as-library is unsupported; main always runs.
# =============================================================================
app_main "$@"

# End of selfmanaged - Full featured CIAO-compliant Type 0 implementation
