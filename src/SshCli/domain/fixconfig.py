# =============================================================================
# Comment OpenSSH client keywords this OS does not support.
# requirement-domain-sshd — Alpine comments GSSAPI*. Termux comments algorithm lines.
# =============================================================================
from __future__ import annotations

import os
import tempfile

from .host import Host
from .output import Output


def render(text: str, os_class: str) -> str:
    """Return the config with unsupported active keywords commented. Other lines stay."""
    rendered = []
    newline = "\n" if "\r\n" not in text else "\r\n"
    pieces = text.splitlines()
    for body in pieces:
        indent = body[: len(body) - len(body.lstrip(" \t"))]
        rest = body[len(indent):]
        if rest == "" or rest.startswith("#"):
            rendered.append(body)
            continue
        token = []
        for char in rest:
            if char.isalpha() or (token and char.isdigit()):
                token.append(char)
            else:
                break
        key = "".join(token).lower()
        unsupported = False
        if os_class == "alpine" and key.startswith("gssapi"):
            unsupported = True
        if os_class == "termux" and key in (
            "hostkeyalgorithms",
            "pubkeyacceptedalgorithms",
            "pubkeyacceptedkeytypes",
        ):
            unsupported = True
        if unsupported and key:
            rendered.append("{0}# {1}".format(indent, rest))
        else:
            rendered.append(body)
    joined = newline.join(rendered)
    if text.endswith(("\n", "\r\n")):
        joined += newline
    return joined


def _mode600(path: str) -> None:
    try:
        os.chmod(path, 0o600)
    except OSError:
        return


class FixConfig:
    """Explicit fix-config and the silent pass on this login's config."""

    def __init__(self, host: Host, output: Output, home: str | None = None) -> None:
        self.host = host
        self.output = output
        self.home = home if home is not None else os.environ.get("HOME", "")

    def config_path(self) -> str:
        return os.path.join(self.home, ".ssh", "config")

    def auto(self) -> None:
        """Silent. Missing, unreadable, unwritable, or identical text is a no-op."""
        path = self.config_path()
        if not os.path.isfile(path) or not os.access(path, os.R_OK | os.W_OK):
            return
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as handle:
                original = handle.read()
        except OSError:
            return
        rendered = render(original, self.host.os_class())
        if rendered == original:
            return
        backup = path + ".fix-config.bak"
        try:
            with open(backup, "w", encoding="utf-8") as handle:
                handle.write(original)
            _mode600(backup)
            directory = os.path.dirname(path) or "."
            descriptor, tmp = tempfile.mkstemp(prefix="fix-config.", dir=directory)
            try:
                os.write(descriptor, rendered.encode("utf-8"))
            finally:
                os.close(descriptor)
            os.replace(tmp, path)
            _mode600(path)
        except OSError:
            return

    def run(self, input_file: str = "", output_file: str = "") -> int:
        """Comment keywords in an explicit file. Flags follow the verb."""
        name = "sshd-cli"
        if input_file == "" and output_file == "":
            source = self.config_path()
            if not os.path.isfile(source):
                return self.output.error(
                    "fix-config input is missing. Next: {0} fix-config --input-file PATH".format(name)
                )
            destination = source
        else:
            if input_file == "":
                return self.output.error(
                    "--input-file requires a path. Next: {0} fix-config [--input-file PATH] [--output-file PATH].".format(name)
                )
            source = input_file
            destination = output_file or source
        if not os.path.isfile(source) or not os.access(source, os.R_OK):
            return self.output.error(
                "fix-config cannot read {0}. Next: {1} fix-config --input-file PATH".format(source, name)
            )
        try:
            with open(source, "r", encoding="utf-8", errors="replace") as handle:
                original = handle.read()
        except OSError:
            return self.output.error(
                "fix-config cannot read {0}. Next: {1} fix-config --input-file PATH".format(source, name)
            )
        rendered = render(original, self.host.os_class())
        changed = "true" if rendered != original else "false"
        parent = os.path.dirname(os.path.abspath(destination))
        if parent and not os.path.isdir(parent):
            return self.output.error(
                "fix-config output directory is missing. Next: create {0}".format(parent)
            )
        if rendered != original:
            try:
                if os.path.isfile(destination):
                    backup = destination + ".fix-config.bak"
                    if destination == source:
                        prior = original
                    else:
                        with open(destination, "r", encoding="utf-8", errors="replace") as handle:
                            prior = handle.read()
                    with open(backup, "w", encoding="utf-8") as handle:
                        handle.write(prior)
                    _mode600(backup)
                directory = parent or "."
                descriptor, tmp = tempfile.mkstemp(prefix="fix-config.", dir=directory)
                try:
                    os.write(descriptor, rendered.encode("utf-8"))
                finally:
                    os.close(descriptor)
                os.replace(tmp, destination)
                _mode600(destination)
            except OSError as exc:
                return self.output.error(
                    "fix-config could not write {0} ({1}).".format(destination, exc)
                )
        os_class = self.host.os_class()
        if self.output.json_mode:
            return self.output.json_ok("fix-config", changed=changed, os=os_class)
        self.output.ok("fix-config commented unsupported keywords ({0}).".format(os_class))
        return 0
