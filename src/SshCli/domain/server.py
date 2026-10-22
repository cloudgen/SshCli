# =============================================================================
# sshd status, start, stop, restart, port, config, host keys, auth keys.
# requirement-domain-sshd — one launch path. No sudo wrap. No systemctl verb.
# =============================================================================
from __future__ import annotations

import os
import shutil
import subprocess

from .host import Host
from .output import Output


class Server:
    """This host's OpenSSH sshd. Termux uses sshd -f. A root systemd host uses systemctl."""

    def __init__(self, host: Host, output: Output, app_name: str = "sshd-cli") -> None:
        self.host = host
        self.output = output
        self.app_name = app_name

    def prefix(self) -> str:
        if self.host.is_termux():
            return self.host.environ.get("PREFIX", "/data/data/com.termux/files/usr")
        return ""

    def sshd_bin(self) -> str:
        override = os.environ.get("SSHD_CLI_SSHD", "")
        if override:
            return override
        if self.host.is_termux():
            return os.path.join(self.prefix(), "bin", "sshd")
        for candidate in ("/usr/sbin/sshd", "/usr/bin/sshd", "/sbin/sshd"):
            if os.path.isfile(candidate):
                return candidate
        return shutil.which("sshd") or ""

    def config_path(self) -> str:
        override = os.environ.get("SSHD_CLI_CONFIG", "")
        if override:
            return override
        if self.host.is_termux():
            return os.path.join(self.prefix(), "etc", "ssh", "sshd_config")
        for candidate in ("/etc/ssh/sshd_config", "/etc/sshd_config"):
            if os.path.isfile(candidate):
                return candidate
        return "/etc/ssh/sshd_config"

    def pidfile(self) -> str:
        if self.host.is_termux():
            return os.path.join(self.prefix(), "var", "run", "sshd.pid")
        return "/run/sshd.pid"

    def port(self) -> str:
        forced = os.environ.get("SSHD_CLI_PORT", "")
        if forced:
            return forced
        return "8022" if self.host.is_termux() else "22"

    def systemd_unit(self) -> str:
        forced = os.environ.get("SSHD_CLI_UNIT", "")
        if forced:
            return forced
        if self.host.normal_user_only():
            return ""
        systemctl = os.environ.get("SSHD_CLI_SYSTEMCTL", "")
        if not systemctl and not shutil.which("systemctl"):
            return ""
        return os.environ.get("SSHD_CLI_UNIT_NAME", "ssh.service")

    def running_pid(self) -> str:
        forced = os.environ.get("SSHD_CLI_PID", "")
        if forced:
            return "" if forced == "0" else forced
        path = self.pidfile()
        try:
            with open(path, "r", encoding="utf-8") as handle:
                text = handle.read().strip()
        except OSError:
            return ""
        return text if text.isdigit() else ""

    def status(self) -> int:
        pid = self.running_pid()
        running = "true" if pid else "false"
        unit = self.systemd_unit()
        if self.output.json_mode:
            return self.output.json_ok(
                "status",
                app=self.app_name,
                platform="termux" if self.host.is_termux() else "linux",
                sshd_bin=self.sshd_bin(),
                sshd_config=self.config_path(),
                port=self.port(),
                running=running,
                pid=pid,
                sshd_unit=unit,
            )
        self.output.info("=== {0} sshd status ===".format(self.app_name))
        binary = self.sshd_bin()
        if binary and os.path.isfile(binary):
            self.output.info("sshd binary:  {0}".format(binary))
        else:
            self.output.warn("sshd binary:  not found")
        self.output.info("Config:       {0}".format(self.config_path()))
        self.output.info("Listen port:  {0}".format(self.port()))
        if unit:
            self.output.info("systemd unit: {0}".format(unit))
        if pid:
            self.output.ok("sshd is running (pid {0}).".format(pid))
        else:
            self.output.warn("sshd is not running.")
        return 0

    def _refuse_daemon(self, verb: str) -> int | None:
        if self.host.show_daemon_rows():
            return None
        return self.output.error(
            "{0} needs a root login on {1}. Next: re-run {2} {0} as root. This program does not wrap sudo.".format(
                verb, self.host.os_name(), self.app_name
            )
        )

    def start(self) -> int:
        refused = self._refuse_daemon("start")
        if refused:
            return refused
        unit = self.systemd_unit()
        if unit and self.host.is_root() and not self.host.normal_user_only():
            return self._systemctl("start", unit)
        binary = self.sshd_bin()
        if not binary:
            return self.output.error(
                "sshd is missing. Next: {0} install".format(self.app_name)
            )
        config = self.config_path()
        argv = [binary, "-f", config]
        if os.environ.get("SSHD_CLI_SSHD"):
            code = subprocess.call(argv)
            if code != 0:
                return self.output.error("sshd -f failed. Next: {0} status".format(self.app_name))
            self.output.ok("sshd started with -f {0}.".format(config))
            return 0
        code = subprocess.call(argv)
        if code != 0:
            return self.output.error("sshd -f failed. Next: {0} status".format(self.app_name))
        self.output.ok("sshd started with -f {0}.".format(config))
        return 0

    def stop(self) -> int:
        refused = self._refuse_daemon("stop")
        if refused:
            return refused
        unit = self.systemd_unit()
        if unit and self.host.is_root() and not self.host.normal_user_only():
            return self._systemctl("stop", unit)
        pid = self.running_pid()
        if not pid:
            self.output.warn("sshd is not running.")
            return 0
        if os.environ.get("SSHD_CLI_SSHD"):
            self.output.ok("sshd stop requested (pid {0}).".format(pid))
            return 0
        os.kill(int(pid), 15)
        self.output.ok("sshd stopped (pid {0}).".format(pid))
        return 0

    def restart(self) -> int:
        refused = self._refuse_daemon("restart")
        if refused:
            return refused
        unit = self.systemd_unit()
        if unit and self.host.is_root() and not self.host.normal_user_only():
            return self._systemctl("restart", unit)
        self.stop()
        return self.start()

    def _systemctl(self, action: str, unit: str) -> int:
        binary = os.environ.get("SSHD_CLI_SYSTEMCTL", "") or shutil.which("systemctl") or "systemctl"
        argv = [binary, action, unit]
        if os.environ.get("SSHD_CLI_SYSTEMCTL"):
            code = subprocess.call(argv)
        else:
            code = subprocess.call(argv)
        if code != 0:
            return self.output.error(
                "systemctl {0} {1} failed. Next: {2} status".format(action, unit, self.app_name)
            )
        self.output.ok("systemctl {0} {1}.".format(action, unit))
        return 0

    def show_port(self, args: list) -> int:
        if args:
            return self.output.error(
                "port does not change the file from this verb. Next: edit {0}".format(self.config_path())
            )
        self.output.info("Listen port: {0}".format(self.port()))
        return 0

    def show_config(self) -> int:
        self.status()
        path = self.config_path()
        if os.path.isfile(path) and os.access(path, os.R_OK):
            self.output.info("Config file: {0}".format(path))
        else:
            self.output.warn("Config file is not readable: {0}".format(path))
        return 0

    def host_keys(self, args: list) -> int:
        folder = os.path.dirname(self.config_path())
        if args and args[0] == "generate":
            keygen = os.environ.get("SSHD_CLI_KEYGEN", "") or shutil.which("ssh-keygen") or ""
            if not keygen:
                return self.output.error("ssh-keygen is missing. Next: install OpenSSH, then {0} host-keys generate".format(self.app_name))
            target = os.path.join(folder, "ssh_host_ed25519_key")
            code = subprocess.call([keygen, "-t", "ed25519", "-f", target, "-N", ""])
            if code != 0:
                return self.output.error("host key generation failed.")
            self.output.ok("Host key written: {0}".format(target))
            return 0
        self.output.info("Host key directory: {0}".format(folder))
        return 0

    def auth_keys(self) -> int:
        path = os.path.join(os.environ.get("HOME", ""), ".ssh", "authorized_keys")
        self.output.info("authorized_keys: {0}".format(path))
        return 0

    def install_openssh(self) -> int:
        """Termux companion only. POSIX Linux does not wrap apt or dnf."""
        if not self.host.is_termux():
            return self.output.error(
                "install of OpenSSH packages is a Termux step. Next: use this OS package tool yourself, then {0} start".format(
                    self.app_name
                )
            )
        pkg = os.environ.get("SSHD_CLI_PKG", "") or "pkg"
        argv = [pkg, "install", "-y", "openssh", "termux-auth"]
        code = subprocess.call(argv)
        if code != 0:
            return self.output.error("pkg install openssh termux-auth failed. Next: pkg install openssh termux-auth")
        self.output.ok("OpenSSH and termux-auth are installed.")
        return 0

    def wake(self, unlock: bool = False) -> int:
        if not self.host.is_termux():
            return self.output.error(
                "wake-lock is a Termux step. Next: {0} status".format(self.app_name)
            )
        tool = "termux-wake-unlock" if unlock else "termux-wake-lock"
        binary = os.environ.get("SSHD_CLI_WAKE", "") or tool
        argv = [binary] if os.environ.get("SSHD_CLI_WAKE") else [tool]
        code = subprocess.call(argv)
        if code != 0:
            return self.output.error("{0} failed.".format(tool))
        self.output.ok("{0} complete.".format(tool))
        return 0
