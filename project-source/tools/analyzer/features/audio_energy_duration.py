"""Exact sample-energy 2.5%..97.5% interval with bounded, two-pass accumulation."""

ASSET_TYPE = "audio"
VERSION = 1
METRICS = {"energy_duration_95": "s"}


def run(path, params, context):
    import numpy as np
    from audio_adapter import blocks
    from audio_statistics import channel_mean_power
    from protocol import metric, unavailable
    total = sum(float(channel_mean_power(block).sum()) for block in blocks(path, params))
    if total == 0:
        return {"energy_duration_95": unavailable("not_applicable", "Digital silence has no energy interval", "s")}, {}, []
    thresholds = [.025 * total, .975 * total]
    indices, energy, cursor = [], 0.0, 0
    for block in blocks(path, params):
        cumulative = np.cumsum(channel_mean_power(block))
        while len(indices) < 2 and energy + cumulative[-1] >= thresholds[len(indices)]:
            indices.append(cursor + int(np.searchsorted(cumulative, thresholds[len(indices)] - energy)))
        energy += float(cumulative[-1])
        cursor += len(block)
    rate = context["metrics"]["sample_rate"]["value"]
    return {"energy_duration_95": metric((indices[1] - indices[0] + 1) / rate, "s")}, {}, [
        {"code": "energy_duration_method", "message": "Original channel-mean sample power; cumulative energy quantiles 2.5%..97.5%, inclusive sample interval."}]
