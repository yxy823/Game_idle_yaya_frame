"""PyAV streaming decode and independently bounded pyloudnorm measurements."""

import math
import re
import warnings

import av
import pyloudnorm

from audio_statistics import AudioStatistics, envelopes
from protocol import metric, unavailable
from source_probe import AnalysisError, decode_error


def blocks(path, params):
    """Yield one float32 decoded block; never retain a list of all audio frames."""
    count = 0
    try:
        with av.open(str(path)) as container:
            if not container.streams.audio:
                raise AnalysisError("unsupported_format", "Container has no audio stream")
            stream = container.streams.audio[0]
            context = stream.codec_context
            channels = len(context.layout.channels)
            if not context.sample_rate or channels < 1:
                raise AnalysisError("decode_failed", "Decoder cannot determine sample rate/channel layout")
            resampler = av.AudioResampler(format="fltp", layout=context.layout, rate=context.sample_rate)
            for frame in container.decode(stream):
                for converted in resampler.resample(frame):
                    count += converted.samples * channels
                    if count > params["max_audio_samples"]:
                        raise AnalysisError("resource_limit", "Decoded audio exceeds max_audio_samples")
                    yield converted.to_ndarray().T
    except (AnalysisError, MemoryError):
        raise
    except (av.error.FFmpegError, ValueError, NotImplementedError) as error:
        raise decode_error(error) from error


def analyze(path, params):
    try:
        with av.open(str(path)) as container:
            if not container.streams.audio:
                raise AnalysisError("unsupported_format", "Container has no audio stream")
            context = container.streams.audio[0].codec_context
            rate, layout = context.sample_rate, context.layout.name
            channels, codec, fmt = len(context.layout.channels), context.name, container.format.name
    except av.error.FFmpegError as error:
        raise decode_error(error) from error
    if rate <= 0 or channels < 1:
        raise AnalysisError("decode_failed", "Invalid sample rate or channel layout")
    statistics = AudioStatistics(rate, channels, params)
    for samples in blocks(path, params):
        statistics.feed(samples)
    levels = statistics.finish()
    precision = re.match(r"pcm_[suf](\d+)", codec)
    bits = int(precision[1]) if precision else None
    metrics = {
        "format": metric(fmt), "codec": metric(codec), "duration": metric(statistics.frames / rate, "s"),
        "sample_rate": metric(rate, "Hz"), "channels": metric(channels), "channel_layout": metric(layout),
        "bit_depth": metric(bits, "bit") if bits else unavailable(
            "not_applicable", "Lossy/unknown source precision; decoded float is not source bit depth", "bit"),
        "true_peak": unavailable("unsupported", "True-peak module not selected", "dBTP"),
        "pitch": unavailable("unsupported", "Pitch module not selected", "Hz"),
        "tempo": unavailable("unsupported", "Tempo analysis is not implemented", "BPM"),
    }
    metrics.update(levels)
    metrics.update(loudness(statistics, rate, channels))
    statistics.loudness_buffer = None
    series = envelopes(blocks(path, params), statistics.frames, rate, channels, params["series_points"])
    notes = [{"code": "source_audio", "message":
              "First audio stream; streaming levels/silence, second-pass envelope. Sample peak and "
              "crest factor are not true peak/LRA. Playback/import effects are excluded. Loudness "
              "uses a separate full-signal budget; signals beyond it retain basic measurements."}]
    return metrics, series, notes


def loudness(statistics, rate, channels):
    output = {}
    for key, seconds, unit in (("integrated_loudness", 0.4, "LUFS"), ("loudness_range", 3.0, "LU")):
        if channels not in {1, 2}:
            output[key] = unavailable("unsupported", "Only verified mono/stereo channel weighting", unit)
        elif statistics.frames / rate < seconds:
            output[key] = unavailable("not_applicable", f"Requires at least {seconds} seconds", unit)
        elif statistics.loudness_buffer is None:
            output[key] = unavailable("unsupported", "Full-signal loudness exceeds max_loudness_samples budget", unit)
        else:
            output[key] = measure_loudness(statistics.loudness_buffer[:statistics.frames], rate, key, unit)
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
