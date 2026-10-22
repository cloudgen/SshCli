# =============================================================================
# Human lines and JSON for domain verbs.
# requirement-domain-sshd — machine channel stays JSON; people see [ERROR].
# HelloTui's own "ERROR:" reporter is not this class.
# =============================================================================
from __future__ import annotations

import json
import sys


class Output:
    """Domain messages. JSON mode prints no human line."""

    def __init__(self, json_mode: bool = False, quiet: bool = False, debug: bool = False) -> None:
        self.json_mode = json_mode
        self.quiet = quiet
        self.debug = debug

    def info(self, message: str) -> None:
        if self.json_mode or self.quiet:
            return
        print("[INFO] {0}".format(message))

    def ok(self, message: str) -> None:
        if self.json_mode or self.quiet:
            return
        print("[OK] {0}".format(message))

    def warn(self, message: str) -> None:
        if self.json_mode:
            return
        print("[WARN] {0}".format(message), file=sys.stderr)

    def error(self, message: str) -> int:
        """Fatal domain line. Status 1. JSON goes to stderr with code unknown."""
        if self.json_mode:
            payload = {"type": "out_error", "message": message, "code": "unknown"}
            print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")), file=sys.stderr)
            return 1
        print("[ERROR] {0}".format(message), file=sys.stderr)
        return 1

    def plain(self, message: str) -> None:
        if self.json_mode or self.quiet:
            return
        print(message)

    def json_ok(self, kind: str, message: str = "", **fields) -> int:
        if not self.json_mode:
            return 0
        payload = {"type": kind}
        if message:
            payload["message"] = message
        for key, value in fields.items():
            payload[key] = "" if value is None else value
        print(json.dumps(payload, ensure_ascii=False, separators=(",", ":")))
        return 0
