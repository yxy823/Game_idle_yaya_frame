"""4x polyphase reconstructed peak estimate with context across chunk boundaries."""

ASSET_TYPE = "audio"
VERSION = 1
METRICS = {"true_peak": "dBTP"}


def true_peak_estimate(blocks, channels, factor=4):
    import numpy as np
    from scipy.signal import resample_poly
    from audio_statistics import windows
    peak = 0.0
    chunk, halo = 65536, 128

    def padded():
        nonlocal peak
        yield np.zeros((halo, channels), dtype=np.float32)
        for block in blocks:
            peak = max(peak, float(np.abs(block).max()))
            yield block
        yield np.zeros((halo, channels), dtype=np.float32)

    for _, samples in windows(padded(), chunk + 2 * halo, chunk, partial=True):
        count = min(chunk, len(samples) - 2 * halo)
        if count <= 0:
            continue
        up = resample_poly(samples, factor, 1, axis=0,
                           window=("kaiser", 5.0), padtype="constant")
        core = up[halo * factor:(halo + count) * factor]
        peak = max(peak, float(np.abs(core).max()))
    return peak


def run(path, params, context):
    import math
    from audio_adapter import blocks
    from protocol import metric, unavailable
    channels = context["metrics"]["channels"]["value"]
    peak = true_peak_estimate(blocks(path, params), channels)
    value = metric(20 * math.log10(peak), "dBTP") if peak else unavailable(
        "not_applicable", "Digital silence: negative infinity dBTP", "dBTP")
    return {"true_peak": value}, {}, [{"code": "true_peak_estimate", "message":
        "4x scipy.signal.resample_poly, Kaiser beta=5, overlap 128 source samples, zero file-edge extension; maximum across channels, not a certified BS.1770 meter."}]
