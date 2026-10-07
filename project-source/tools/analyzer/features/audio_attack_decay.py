"""Operational envelope crossings; no ADSR or reverberation fit."""

ASSET_TYPE = "audio"
VERSION = 1
METRICS = {"attack_10_90": "s", "decay_to_10": "s"}


def run(path, params, context):
    import numpy as np
    from audio_adapter import blocks
    from audio_statistics import channel_mean_power, windows
    from protocol import metric, unavailable
    rate = context["metrics"]["sample_rate"]["value"]
    length = max(1, round(rate / 1000))
    envelope = np.array([np.sqrt(channel_mean_power(block).mean())
                         for _, block in windows(blocks(path, params), length, length, partial=True)])
    peak = int(np.argmax(envelope))
    if envelope[peak] == 0:
        return {name: unavailable("not_applicable", "Digital silence has no envelope crossings", unit)
                for name, unit in METRICS.items()}, {}, []
    rise = envelope[:peak + 1]
    i10 = int(np.flatnonzero(rise >= envelope[peak] * .1)[0])
    i90 = int(np.flatnonzero(rise >= envelope[peak] * .9)[0])
    crossings = np.flatnonzero(envelope[peak + 1:] <= envelope[peak] * .1)
    decay = metric(float((crossings[0] + 1) * length / rate), "s") if len(crossings) else unavailable(
        "not_applicable", "Signal does not decay to 10% after its envelope peak", "s")
    return {"attack_10_90": metric((i90 - i10) * length / rate, "s"), "decay_to_10": decay}, {}, [
        {"code": "envelope_crossings", "message":
         "1 ms channel-mean-power RMS envelope; first pre-peak 10%-90% rise and first post-peak 10% crossing. Multi-event sounds can mislead."}]
