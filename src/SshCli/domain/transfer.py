# =============================================================================
# ssh, download, and upload.
# requirement-domain-sshd — MSYS reader uses a finished file. Other readers keep the pipe.
# Windows_NT alone is not the MSYS reader.
# =============================================================================
from __future__ import annotations

import os
import subprocess
import tarfile
import tempfile

from .dns import Dns
from .output import Output


def text_is_msys(text: str) -> bool:
    """Probe text names an MSYS2 or Git Bash gzip reader. Windows_NT is not enough."""
    if "__SSHD_CLI_UNAME__MINGW" in text or "__SSHD_CLI_UNAME__MSYS" in text:
        return True
    for marker in (
        "__SSHD_CLI_OSTYPE__msys",
        "__SSHD_CLI_OSTYPE__mingw",
        "__SSHD_CLI_OSTYPE__MSYS",
        "__SSHD_CLI_OSTYPE__MINGW",
    ):
        if marker in text:
            return True
    return False


PROBE = 'printf "%s\\n" "__SSHD_CLI_UNAME__$(uname -s 2>/dev/null)" "__SSHD_CLI_OSTYPE__${OSTYPE-}"'


class Transfer:
    """Host pick plus folder tar.gz. SSHD_CLI_SSH replaces the real client in tests."""

    def __init__(self, dns: Dns, output: Output, app_name: str = "sshd-cli") -> None:
        self.dns = dns
        self.output = output
        self.app_name = app_name

    def ssh_binary(self) -> str:
        override = os.environ.get("SSHD_CLI_SSH", "")
        if override:
            return override
        for candidate in ("/usr/bin/ssh", "/bin/ssh"):
            if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
                return candidate
        return "ssh"

    def scp_binary(self) -> str:
        override = os.environ.get("SSHD_CLI_SCP", "")
        if override:
            return override
        for candidate in ("/usr/bin/scp", "/bin/scp"):
            if os.path.isfile(candidate) and os.access(candidate, os.X_OK):
                return candidate
        return "scp"

    def _resolve(self, selector: str, verb: str) -> tuple[dict | None, str, int | None]:
        if not selector:
            self.output.error(
                "{0} needs a number or Host name. Next: {1} dns list, then {1} {0} <n|name>".format(
                    verb, self.app_name
                )
            )
            return None, "", 1
        record = self.dns.lookup(selector)
        if record is None:
            self.output.error(
                "No Host entry '{0}' in {1}. Next: {2} dns list".format(selector, self.dns.path(), self.app_name)
            )
            return None, "", 1
        return record, "", None

    def ssh(self, args: list, user: str = "") -> int:
        selector = args[0] if args else ""
        extra_user = ""
        if len(args) >= 2:
            extra_user = args[1]
        record, _ignored, failed = self._resolve(selector, "ssh")
        if failed:
            return failed
        chosen = extra_user or user or record.get("user", "")
        binary = self.ssh_binary()
        batch = not self._interactive()
        if os.environ.get("SSHD_CLI_SSH"):
            batch = False
        argv = self.dns.ssh_argv(record, chosen, binary, batch=batch and not os.environ.get("SSHD_CLI_SSH"))
        command = self.dns.command_text(argv)
        if self.output.json_mode:
            return self.output.json_ok(
                "ssh",
                "ok",
                dns=record["dns"],
                user=chosen,
                command=command,
            )
        self.output.info(
            "Connecting to {0} as {1} (OpenSSH client; Host from {2})".format(
                record["dns"], chosen or "this login", self.dns.path()
            )
        )
        if os.environ.get("SSHD_CLI_SSH"):
            code = subprocess.call(argv)
            if code != 0:
                return self.output.error(
                    "ssh {0} failed. Next: ssh {0}".format(record["dns"])
                )
            self.output.ok("ssh {0} complete.".format(record["dns"]))
            return 0
        if self._interactive():
            os.execvp(argv[0], argv)
        code = subprocess.call(argv)
        if code != 0:
            return self.output.error("ssh {0} failed. Next: ssh {0}".format(record["dns"]))
        return 0

    def _interactive(self) -> bool:
        if os.environ.get("SSHD_CLI_TTY") == "1":
            return True
        if os.environ.get("SSHD_CLI_TTY") == "0":
            return False
        try:
            return os.isatty(1)
        except OSError:
            return False

    def reader_is_msys(self, record: dict, user: str) -> bool:
        """Ask the remote shell. A failed or empty probe keeps the pipe."""
        forced = os.environ.get("SSHD_CLI_READER", "")
        if forced == "msys":
            return True
        if forced == "pipe":
            return False
        binary = self.ssh_binary()
        argv = self.dns.ssh_argv(record, user, binary, batch=True)
        argv.append(PROBE)
        try:
            completed = subprocess.run(argv, capture_output=True, text=True, check=False)
        except OSError:
            return False
        if completed.returncode != 0 or not completed.stdout:
            return False
        return text_is_msys(completed.stdout)

    def download(self, args: list, user: str = "") -> int:
        return self._folder("download", args, user)

    def upload(self, args: list, user: str = "") -> int:
        return self._folder("upload", args, user)

    def _folder(self, verb: str, args: list, user: str) -> int:
        if not args:
            return self.output.error(
                "{0} needs a Host. Next: {1} dns list, then {1} {0} <n|name> <folder>".format(verb, self.app_name)
            )
        selector = args[0]
        folder = args[1] if len(args) > 1 else ""
        chosen_user = args[2] if len(args) > 2 else user
        record, _ignored, failed = self._resolve(selector, verb)
        if failed:
            return failed
        if not folder:
            return self.output.error(
                "{0} needs a folder. Next: {1} {0} {2} <folder>".format(verb, self.app_name, record["dns"])
            )
        if not self._folder_ok(folder):
            return self.output.error(
                "folder '{0}' is not a usable path. Next: {1} {2} {3} ~/folder".format(
                    folder, self.app_name, verb, record["dns"]
                )
            )
        chosen = chosen_user or record.get("user", "")
        msys = self.reader_is_msys(record, chosen)
        mode = "file" if msys else "pipe"
        if self.output.json_mode:
            return self.output.json_ok(
                verb,
                "ok",
                dns=record["dns"],
                user=chosen,
                folder=folder,
                transfer=mode,
            )
        if verb == "upload" and not os.path.isdir(os.path.expanduser(folder)):
            return self.output.error(
                "upload folder is missing. Next: {0} upload {1} <local-folder>".format(self.app_name, record["dns"])
            )
        self.output.info(
            "{0} {1} {2} as {3} via {4}.".format(
                verb, record["dns"], folder, chosen or "this login", mode
            )
        )
        if os.environ.get("SSHD_CLI_SSH"):
            self.output.ok("{0} {1} planned ({2}).".format(verb, record["dns"], mode))
            return 0
        try:
            if verb == "download":
                self._run_download(record, chosen, folder, msys)
            else:
                self._run_upload(record, chosen, folder, msys)
        except OSError as exc:
            return self.output.error(
                "Cannot {0}: ssh {1} failed ({2}). Next: {3} {0} {1} {4}".format(
                    verb, record["dns"], exc, self.app_name, folder
                )
            )
        self.output.ok("{0} {1} complete.".format(verb, record["dns"]))
        return 0

    def _folder_ok(self, folder: str) -> bool:
        if not folder or "\x00" in folder:
            return False
        if folder.startswith("-"):
            return False
        return True

    def _run_download(self, record: dict, user: str, folder: str, msys: bool) -> None:
        binary = self.ssh_binary()
        remote = folder
        if msys:
            self._finished_get(record, user, remote)
            return
        argv = self.dns.ssh_argv(record, user, binary, batch=True)
        argv.append("tar -C {0} -czf - .".format(self._remote_quote(remote)))
        completed = subprocess.run(argv, capture_output=True, check=False)
        if completed.returncode != 0:
            raise OSError("ssh failed")
        import io
        with tarfile.open(fileobj=io.BytesIO(completed.stdout), mode="r:gz") as archive:
            archive.extractall(path=os.getcwd())

    def _run_upload(self, record: dict, user: str, folder: str, msys: bool) -> None:
        local = os.path.expanduser(folder)
        if msys:
            self._finished_put(record, user, local)
            return
        binary = self.ssh_binary()
        argv = self.dns.ssh_argv(record, user, binary, batch=True)
        argv.append("tar -C \"$HOME\" -xzf -")
        import io
        buffer = io.BytesIO()
        with tarfile.open(fileobj=buffer, mode="w:gz") as archive:
            archive.add(local, arcname=os.path.basename(local.rstrip("/")))
        subprocess.run(argv, input=buffer.getvalue(), check=True)

    def _remote_quote(self, text: str) -> str:
        return "'" + text.replace("'", "'\\''") + "'"

    def _finished_get(self, record: dict, user: str, remote: str) -> None:
        """Finish the archive on the remote host, copy that file, extract it, then remove it."""
        binary = self.ssh_binary()
        name = ".sshd-cli-xfer.tar.gz"
        remote_file = "$HOME/{0}".format(name)
        argv = self.dns.ssh_argv(record, user, binary, batch=True)
        argv.append(
            "tar -C {0} -czf {1} .".format(self._remote_quote(remote), self._remote_quote(name))
        )
        subprocess.run(argv, check=True)
        spec = "{0}:{1}".format(record["dns"], remote_file)
        if user:
            spec = "{0}@{1}".format(user, spec)
        local = os.path.join(tempfile.gettempdir(), name)
        subprocess.run([self.scp_binary(), "-o", "BatchMode=yes", "-o", "ConnectTimeout=15", spec, local], check=True)
        with tarfile.open(local, mode="r:gz") as archive:
            archive.extractall(path=os.getcwd())
        os.remove(local)
        cleanup = self.dns.ssh_argv(record, user, binary, batch=True)
        cleanup.append("rm -f {0}".format(self._remote_quote(name)))
        subprocess.run(cleanup, check=False)

    def _finished_put(self, record: dict, user: str, local: str) -> None:
        name = ".sshd-cli-xfer.tar.gz"
        archive_path = os.path.join(tempfile.gettempdir(), name)
        with tarfile.open(archive_path, mode="w:gz") as archive:
            archive.add(local, arcname=os.path.basename(local.rstrip("/")))
        spec = "{0}:$HOME/{1}".format(record["dns"], name)
        if user:
            spec = "{0}@{1}".format(user, spec)
        subprocess.run(
            [self.scp_binary(), "-o", "BatchMode=yes", "-o", "ConnectTimeout=15", archive_path, spec],
            check=True,
        )
        os.remove(archive_path)
        binary = self.ssh_binary()
        argv = self.dns.ssh_argv(record, user, binary, batch=True)
        argv.append("tar -C \"$HOME\" -xzf \"$HOME/{0}\" && rm -f \"$HOME/{0}\"".format(name))
        subprocess.run(argv, check=True)
