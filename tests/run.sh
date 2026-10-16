#!/bin/sh
# =============================================================================
# tests/run.sh — CI entrypoint for sshd-cli
# =============================================================================
#
# GENERAL PURPOSE:
# Run the product test suite offline-friendly, isolated HOME, no public network.
#
# Usage:
#   ./tests/run.sh
#   sh tests/run.sh
#
# Exit 0 when all assertions pass; non-zero when any fail.
# =============================================================================

set -u

TESTS_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${TESTS_ROOT}/.." && pwd)
export TESTS_ROOT REPO_ROOT
SCRIPT="${REPO_ROOT}/src/sshd-cli"
export SCRIPT
APP_NAME="sshd-cli"
export APP_NAME

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"
# shellcheck source=test_cli.sh
. "${TESTS_ROOT}/test_cli.sh"
# shellcheck source=test_local_lifecycle.sh
. "${TESTS_ROOT}/test_local_lifecycle.sh"
# shellcheck source=test_dns.sh
. "${TESTS_ROOT}/test_dns.sh"
# shellcheck source=test_fix_config.sh
. "${TESTS_ROOT}/test_fix_config.sh"
# shellcheck source=test_config_backup.sh
. "${TESTS_ROOT}/test_config_backup.sh"
# shellcheck source=test_ssh_download.sh
. "${TESTS_ROOT}/test_ssh_download.sh"
# shellcheck source=test_os_transfer.sh
. "${TESTS_ROOT}/test_os_transfer.sh"

PASS=0
FAIL=0
SKIP=0

_cleanup() {
    ci_cleanup_env 2>/dev/null || true
}
trap _cleanup EXIT INT HUP TERM

printf 'sshd-cli CI tests\n'
printf 'script: %s\n' "${SCRIPT}"

if [ ! -f "${SCRIPT}" ]; then
    printf 'ERROR: ship unit missing: %s\n' "${SCRIPT}" >&2
    exit 2
fi
if [ ! -x "${SCRIPT}" ]; then
    chmod +x "${SCRIPT}" 2>/dev/null || true
fi

run_test_cli
run_test_local_lifecycle
run_test_dns
run_test_fix_config
run_test_config_backup
run_test_ssh_download
run_test_os_transfer

printf '\n== summary ==\n'
printf 'PASS=%s FAIL=%s SKIP=%s\n' "${PASS}" "${FAIL}" "${SKIP}"

if [ "${FAIL}" -gt 0 ]; then
    printf 'RESULT: FAILED\n' >&2
    exit 1
fi

printf 'RESULT: OK\n'
exit 0
