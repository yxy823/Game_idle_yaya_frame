import pathlib
import subprocess
import sys
import time


if sys.argv[1] == "--child":
    time.sleep(600)
else:
    output = pathlib.Path(sys.argv[1])
    output.parent.mkdir(parents=True, exist_ok=True)
    child = subprocess.Popen(
        [sys.executable, "-B", __file__, "--child"],
        creationflags=subprocess.CREATE_NO_WINDOW,
    )
    output.write_text("{}", encoding="utf-8")
    marker = pathlib.Path(str(output) + ".child")
    temporary = marker.with_suffix(".child.tmp")
    temporary.write_text(str(child.pid), encoding="utf-8")
    temporary.replace(marker)
    time.sleep(600)
