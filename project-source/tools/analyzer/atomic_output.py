"""Publish files on their destination volume; own only this worker's temporary files."""

from contextlib import contextmanager
import json
import os
from pathlib import Path
import tempfile
import threading
import time

from protocol import validate
from source_probe import AnalysisError

WRITE_LOCK = threading.Lock()
OWNED_TEMPORARIES = set()
MAX_RESULT_BYTES = 2 * 1024**2


@contextmanager
def atomic_target(destination):
    destination = Path(destination)
    destination.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix=destination.name + ".", suffix=".tmp", dir=destination.parent)
    os.close(fd)
    temporary = Path(name)
    with WRITE_LOCK:
        OWNED_TEMPORARIES.add(temporary)
    try:
        yield temporary
        with WRITE_LOCK:
            # Windows readers deny replacement until their short-lived handle closes.
            # Retry only sharing/access conflicts; persistent permissions still fail.
            for attempt in range(21):
                try:
                    os.replace(temporary, destination)
                    break
                except PermissionError as error:
                    if error.winerror not in (5, 32) or attempt == 20:
                        raise
                    time.sleep(.05)
    finally:
        with WRITE_LOCK:
            temporary.unlink(missing_ok=True)
            OWNED_TEMPORARIES.discard(temporary)


def encode_result(data):
    validate(data)
    payload = json.dumps(data, ensure_ascii=False, allow_nan=False).encode("utf-8")
    if len(payload) > MAX_RESULT_BYTES:
        raise AnalysisError("result_too_large", "Result exceeds 2 MiB")
    return payload


def write_result(destination, data):
    payload = encode_result(data)
    with atomic_target(destination) as temporary:
        temporary.write_bytes(payload)
