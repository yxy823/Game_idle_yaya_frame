"""Streaming magnitude descriptors and Welch channel-power band fractions."""

ASSET_TYPE = "audio"
VERSION = 1
METRICS = {"spectral_centroid": "Hz", "spectral_bandwidth": "Hz", "spectral_rolloff_85": "Hz",
           "band_energy_ratios": "ratio"}
BANDS = ((20, 120), (120, 500), (500, 2000), (2000, 8000), (8000, 20000))


def run(path, params, context):
    import numpy as np
    from scipy.fft import rfft, rfftfreq
    from scipy.signal.windows import hann
    from audio_adapter import blocks
    from audio_statistics import windows
    from protocol import metric, unavailable
    rate = context["metrics"]["sample_rate"]["value"]
    channels = context["metrics"]["channels"]["value"]
    frames = round(context["metrics"]["duration"]["value"] * rate)
    sums = np.zeros(channels, dtype=np.float64)
    for block in blocks(path, params):
        sums += block.sum(axis=0, dtype=np.float64)
    mean = sums / frames

    def ac_blocks():
        for block in blocks(path, params):
            yield block.astype(np.float64) - mean

    nfft = min(frames, max(2, 1 << max(1, int(np.ceil(rate * 2048 / 48000)) - 1).bit_length()))
    hop = min(nfft, max(1, round(rate * .01)))
    frequency = rfftfreq(nfft, 1 / rate)
    support = frequency <= min(20000, rate / 2)
    window = hann(nfft, sym=False) if nfft > 1 else np.ones(1)
    descriptor_sums, weight = np.zeros(3), 0.0
    for _, block in windows(ac_blocks(), nfft, hop, partial=True):
        padded = np.zeros((nfft, channels))
        padded[:len(block)] = block
        power = np.square(np.abs(rfft(padded * window[:, None], axis=0, workers=1))).mean(axis=1)
        magnitude = np.sqrt(power[support])
        energy, total = float(power[support].sum()), float(magnitude.sum())
        if total > 0:
            f = frequency[support]
            centroid = float(f @ magnitude / total)
            bandwidth = float(np.sqrt(((f - centroid) ** 2) @ magnitude / total))
            rolloff = float(f[np.searchsorted(np.cumsum(magnitude), .85 * total)])
            descriptor_sums += np.array([centroid, bandwidth, rolloff]) * energy
            weight += energy

    segment = min(frames, max(2, round(rate * 8192 / 48000)))
    welch_window = hann(segment, sym=False) if segment > 1 else np.ones(1)
    psd = np.zeros(segment // 2 + 1)
    for _, block in windows(ac_blocks(), segment, max(1, segment // 2), partial=True):
        padded = np.zeros((segment, channels))
        padded[:len(block)] = block
        power = np.square(np.abs(rfft(padded * welch_window[:, None], axis=0, workers=1))).mean(axis=1)
        power[1:-1 if segment % 2 == 0 else None] *= 2
        psd += power
    bins = rfftfreq(segment, 1 / rate)
    total = float(psd.sum())
    metrics = {name: metric(float(value / weight), "Hz") if weight else unavailable(
        "not_applicable", "No AC spectral energy", "Hz")
        for name, value in zip(("spectral_centroid", "spectral_bandwidth", "spectral_rolloff_85"), descriptor_sums)}
    bands = []
    for low, high in BANDS:
        observed_high = min(high, rate / 2)
        covered = low < observed_high
        selected = (bins >= low) & (bins < observed_high)
        if covered and observed_high == rate / 2:
            selected |= bins == observed_high
        bands.append({"low_hz": low, "high_hz": high,
                      "observed_high_hz": observed_high if covered else None,
                      "coverage": "full" if high <= rate / 2 else "partial" if covered else "unavailable",
                      "ratio": float(psd[selected].sum() / total) if covered and total else None})
    metrics["band_energy_ratios"] = metric(bands, "ratio") if total else unavailable(
        "not_applicable", "No AC spectral energy", "ratio")
    return metrics, {}, [{"code": "spectrum_method", "message":
        "Per-channel DC removal only here; channel-power average; Hann magnitude-weighted centroid/bandwidth/85% rolloff, energy-weighted across 10 ms hops. Welch power fractions use all observed AC bins as denominator; final partial windows are zero padded."}]
