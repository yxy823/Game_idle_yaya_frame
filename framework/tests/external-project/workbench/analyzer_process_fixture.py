"""Fault-only process fixture. Copied into tests, never distributed with the tool."""

import json
from pathlib import Path
import sys
import time

request = json.loads(Path(sys.argv[-1]).read_text(encoding="utf-8"))
mode = request.get("parameters", {}).get("fixture", "invalid")
if mode == "timeout":
    time.sleep(60)
elif mode == "exit":
    sys.stderr.write("intentional fixture exit")
    sys.exit(7)
elif mode == "empty":
    sys.exit(0)
elif mode == "overflow":
    sys.stdout.write("x" * 2200000)
else:
    sys.stdout.write('{"broken":')
