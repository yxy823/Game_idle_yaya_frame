"""Maximum complete 10/20/50 ms RMS windows, 1 ms hop, loudest channel."""

ASSET_TYPE = "audio"
VERSION = 1
METRICS = {"max_rms_10ms": "dBFS", "max_rms_20ms": "dBFS", "max_rms_50ms": "dBFS"}


def maximum_rms(blocks, rate):
    import numpy as np
    lengths = {ms: max(1, round(rate * ms / 1000)) for ms in (10, 20, 50)}
    hop = max(1, round(rate / 1000))
    next_start = {ms: 0 for ms in lengths}
    maxima = {ms: None for ms in lengths}
    tail, cursor = None, 0
    for block in blocks:
        joined = block if tail is None else np.concatenate((tail, block))
        offset = cursor - (0 if tail is None else len(tail))
        power = np.square(joined, dtype=np.float64)
        cumulative = np.vstack((np.zeros((1, joined.shape[1])), np.cumsum(power, axis=0)))
        for ms, length in lengths.items():
            starts = np.arange(next_start[ms], offset + len(joined) - length + 1, hop)
            if len(starts):
                local = starts - offset
                means = (cumulative[local + length] - cumulative[local]) / length
                peak = float(np.maximum(means, 0).max())
                maxima[ms] = peak if maxima[ms] is None else max(maxima[ms], peak)
                next_start[ms] = int(starts[-1]) + hop
        cursor += len(block)
        retained = max(lengths.values()) - 1
        tail = joined[-retained:].copy() if retained else joined[:0]
    return maxima


def run(path, params, context):
    import math
    from audio_adapter import blocks
    from audio_statistics import db_metric
    from protocol import unavailable
    rate = context["metrics"]["sample_rate"]["value"]
    maxima = maximum_rms(blocks(path, params), rate)
    metrics = {f"max_rms_{ms}ms": db_metric(math.sqrt(power)) if power is not None else unavailable(
        "not_applicable", f"Requires a complete {ms} ms window; no padding", "dBFS")
        for ms, power in maxima.items()}
    return metrics, {}, [{"code": "max_rms_method", "message":
        "Complete 10/20/50 ms windows, 1 ms hop, original samples; maximum across windows and channels. Not LUFS."}]
