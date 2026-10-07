"""Conservative monophonic pYIN summary on the highest-energy AC channel."""

ASSET_TYPE = "audio"
VERSION = 1
METRICS = {"pitch": "Hz", "pitch_note": "note", "pitch_voiced_fraction": "ratio", "pitch_confidence": "ratio"}
DEFAULTS = {"max_pitch_seconds": 10.0}
LIMITS = {"max_pitch_seconds": [.064, 10.0]}


def skipped(status, reason):
    from protocol import unavailable
    return {name: unavailable(status, reason, unit) for name, unit in METRICS.items()}, {}, []


def run(path, params, context):
    import math
    import numpy as np
    from scipy.signal import resample_poly
    from audio_adapter import blocks
    from protocol import metric, unavailable
    from source_probe import AnalysisError
    rate = context["metrics"]["sample_rate"]["value"]
    channels = context["metrics"]["channels"]["value"]
    duration = context["metrics"]["duration"]["value"]
    if duration > params["max_pitch_seconds"]:
        return skipped("unsupported", "Duration exceeds max_pitch_seconds; no silent excerpting")
    fmin, fmax, target_rate = 65.406, min(4000, rate / 2), 16000
    frame, hop = 1024, 256
    if duration < frame / target_rate or fmax <= fmin:
        return skipped("not_applicable", "Insufficient unpadded signal or frequency range for pYIN")
    frames = round(duration * rate)
    sums, squares = np.zeros(channels), np.zeros(channels)
    for block in blocks(path, params):
        sums += block.sum(axis=0, dtype=np.float64)
        squares += np.einsum("ij,ij->j", block, block, dtype=np.float64)
    means = sums / frames
    energies = np.maximum(0, squares / frames - means ** 2)
    channel = int(np.argmax(energies))
    if energies[channel] <= 10 ** (params["silence_dbfs"] / 10):
        return skipped("not_applicable", "No AC signal above the silence threshold")
    signal = np.empty(frames, dtype=np.float32)
    cursor = 0
    for block in blocks(path, params):
        signal[cursor:cursor + len(block)] = block[:, channel] - means[channel]
        cursor += len(block)
    if cursor != frames:
        raise AnalysisError("asset_changed", "Audio length changed between decoding passes")
    divisor = math.gcd(rate, target_rate)
    signal = resample_poly(signal, target_rate // divisor, rate // divisor)
    assert target_rate / fmin < frame // 2
    import librosa
    f0, voiced, probability = librosa.pyin(
        signal, sr=target_rate, fmin=fmin, fmax=fmax, frame_length=frame, hop_length=hop,
        center=True, pad_mode="constant", fill_na=np.nan)
    # Match pYIN's centered frames; padded tail centers are not observations.
    padded = np.pad(signal, frame // 2)
    rms = np.array([np.sqrt(np.mean(padded[start:start + frame].astype(np.float64) ** 2))
                    for start in range(0, len(padded) - frame + 1, hop)])
    active = (rms > 10 ** (params["silence_dbfs"] / 20)) & (rms >= rms.max() * .01)
    active &= np.arange(len(rms)) * hop < len(signal)
    if not active.any():
        return skipped("not_applicable", "No active pYIN frames")
    voiced = voiced & np.isfinite(f0) & active
    fraction = float(voiced.sum() / active.sum())
    confidence = float(probability[active].mean())
    accepted = voiced & (probability >= .5)
    metrics = {"pitch_voiced_fraction": metric(fraction, "ratio"), "pitch_confidence": metric(confidence, "ratio")}
    if accepted.sum() >= 3 and fraction >= .6 and confidence >= .5:
        hz = float(np.median(f0[accepted]))
        midi = int(np.rint(69 + 12 * np.log2(hz / 440)))
        names = ("C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B")
        metrics.update(pitch=metric(hz, "Hz"), pitch_note=metric(names[midi % 12] + str(midi // 12 - 1), "note"))
    else:
        reason = "No sufficiently supported fundamental detected; normal for noise and impacts"
        metrics.update(pitch=unavailable("not_applicable", reason, "Hz"),
                       pitch_note=unavailable("not_applicable", reason, "note"))
    return metrics, {}, [{"code": "pitch_method", "message":
        f"pYIN 16 kHz, 65.406..{fmax:g} Hz, frame=1024/hop=256, AC channel {channel}; voiced fraction and mean voicing probability over active frames. Probability is not calibrated pitch correctness; monophonic heuristic, not chord/key analysis."}]
