"""PyAV decoding, NumPy statistics and pyloudnorm BS.1770 measurements."""

import math
import re
import warnings

import av
import numpy as np
import pyloudnorm

from protocol import metric, sequence, unavailable


def decode(path, params):
    """Bound decoded memory; preserve channels/sample rate, never normalize gain."""
    frames = []
    count = 0
    with av.open(str(path)) as container:
        if not container.streams.audio:
            raise ValueError("No audio stream")
        stream = container.streams.audio[0]
        context = stream.codec_context
        rate = context.sample_rate
        layout = context.layout.name
        channels = len(context.layout.channels)
        codec, fmt = context.name, container.format.name
        precision = re.match(r"pcm_[suf](\d+)", codec)
        bit_depth = int(precision[1]) if precision else None
        resampler = av.AudioResampler(format="fltp", layout=context.layout, rate=rate)
        for frame in container.decode(stream):
            for converted in resampler.resample(frame):
                count += converted.samples * channels
                if count > params["max_audio_samples"]:
                    raise ValueError("Decoded audio exceeds max_audio_samples")
                frames.append(converted.to_ndarray().T.copy())
    if not frames:
        raise ValueError("Empty audio stream")
    samples = np.concatenate(frames).astype(np.float64)
    if not np.isfinite(samples).all():
        raise ValueError("Non-finite decoded samples")
    return samples, rate, layout, codec, fmt, bit_depth


def analyze(path, params):
    samples, rate, layout, codec, fmt, bits = decode(path, params)
    duration = len(samples) / rate
    peak, rms = float(np.abs(samples).max()), float(np.sqrt(np.mean(samples ** 2)))
    metrics = {
        "format": metric(fmt), "codec": metric(codec), "duration": metric(duration, "s"),
        "sample_rate": metric(rate, "Hz"), "channels": metric(samples.shape[1]),
        "channel_layout": metric(layout),
        "bit_depth": metric(bits, "bit") if bits else unavailable(
            "not_applicable", "Lossy/unknown source precision; decoded float is not source bit depth", "bit"),
        "sample_peak": db_metric(peak), "rms": db_metric(rms),
        "crest_factor": metric(20 * math.log10(peak / rms), "dB") if rms else unavailable(
            "not_applicable", "Digital silence has no finite crest factor", "dB"),
        "true_peak": unavailable("unsupported", "No oversampled true-peak backend", "dBTP"),
        "pitch": unavailable("unsupported", "Advanced tonal analysis is not installed", "Hz"),
        "tempo": unavailable("unsupported", "Advanced musical analysis is not installed", "BPM"),
    }
    metrics.update(loudness(samples, rate, layout))
    metrics.update(silence(samples, rate, params))
    edges = np.linspace(0, len(samples), min(params["series_points"], len(samples)) + 1, dtype=int)
    peaks = [float(np.abs(samples[a:b]).max()) for a, b in zip(edges[:-1], edges[1:])]
    levels = [float(np.sqrt(np.mean(samples[a:b] ** 2))) for a, b in zip(edges[:-1], edges[1:])]
    times = ((edges[:-1] + edges[1:]) / (2 * rate)).tolist()
    series = {"peak_envelope": sequence(times, peaks, "s", "linear full scale"),
              "rms_envelope": sequence(times, levels, "s", "linear full scale")}
    notes = [{"code": "source_audio", "message":
              "First audio stream, decoded source samples. Peak is sample peak; crest factor is "
              "peak/RMS, not loudness range. Playback gain, pitch, bus and Godot import are excluded."}]
    return metrics, series, notes


def db_metric(value):
    if value == 0:
        return unavailable("not_applicable", "Digital silence: negative infinity dBFS", "dBFS")
    return metric(20 * math.log10(value), "dBFS")


def loudness(samples, rate, layout):
    output = {}
    for key, seconds, unit in (("integrated_loudness", 0.4, "LUFS"), ("loudness_range", 3.0, "LU")):
        if samples.shape[1] not in {1, 2}:
            output[key] = unavailable("unsupported", "Only verified mono/stereo channel weighting", unit)
        elif len(samples) / rate < seconds:
            output[key] = unavailable("not_applicable", f"Requires at least {seconds} seconds", unit)
        else:
            output[key] = measure_loudness(samples, rate, key, unit)
    return output


def measure_loudness(samples, rate, key, unit):
    try:
        meter = pyloudnorm.Meter(rate)
        with warnings.catch_warnings():
            warnings.simplefilter("ignore", RuntimeWarning)
            value = float(getattr(meter, key)(samples))
        if not math.isfinite(value):
            return unavailable("not_applicable", "No signal above the loudness gate", unit)
        return metric(value, unit)
    except (ValueError, RuntimeError, ArithmeticError) as error:
        return unavailable("failed", str(error)[:500], unit)


def silence(samples, rate, params):
    """All channels must be below the explicit sample-amplitude threshold."""
    quiet = np.max(np.abs(samples), axis=1) <= 10 ** (params["silence_dbfs"] / 20)
    changes = np.diff(np.concatenate(([False], quiet, [False])).astype(np.int8))
    starts, ends = np.flatnonzero(changes == 1), np.flatnonzero(changes == -1)
    intervals = [{"start": int(a) / rate, "end": int(b) / rate, "duration": int(b - a) / rate}
                 for a, b in zip(starts, ends) if (b - a) / rate >= params["silence_min_seconds"]]
    leading = intervals[0]["duration"] if intervals and intervals[0]["start"] == 0 else 0.0
    trailing = intervals[-1]["duration"] if intervals and intervals[-1]["end"] == len(samples) / rate else 0.0
    return {"silence_intervals": metric(intervals, "s"),
            "leading_silence": metric(leading, "s"), "trailing_silence": metric(trailing, "s")}
