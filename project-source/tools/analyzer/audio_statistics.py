"""Bounded streaming level/silence accumulation and a second-pass envelope."""

import math

import numpy as np

from protocol import metric, sequence, unavailable
from source_probe import AnalysisError


class AudioStatistics:
    def __init__(self, rate, channels, params):
        self.rate, self.channels, self.params = rate, channels, params
        self.frames, self.peak, self.squares = 0, 0.0, 0.0
        self.quiet_start = None
        self.intervals = []
        self.interval_overflow = False
        self.leading = self.trailing = 0.0
        self.loudness_buffer = np.empty((params["max_loudness_samples"] // channels, channels),
                                       dtype=np.float64) if channels in (1, 2) else None

    def feed(self, samples):
        if not np.isfinite(samples).all():
            raise AnalysisError("corrupt_file", "Non-finite decoded samples")
        amplitude = np.abs(samples)
        self.peak = max(self.peak, float(amplitude.max()))
        self.squares += float(np.einsum("ij,ij->", samples, samples, dtype=np.float64))
        if self.loudness_buffer is not None:
            if self.frames + len(samples) > len(self.loudness_buffer):
                self.loudness_buffer = None
            else:
                self.loudness_buffer[self.frames:self.frames + len(samples)] = samples
        quiet = amplitude.max(axis=1) <= 10 ** (self.params["silence_dbfs"] / 20)
        changes = np.diff(np.concatenate(([self.quiet_start is not None], quiet)).astype(np.int8))
        for index in np.flatnonzero(changes):
            position = self.frames + int(index)
            if changes[index] == 1:
                self.quiet_start = position
            else:
                self._end_silence(position)
        self.frames += len(samples)

    def _end_silence(self, end):
        start = self.quiet_start
        self.quiet_start = None
        seconds = (end - start) / self.rate
        if seconds < self.params["silence_min_seconds"]:
            return
        if start == 0:
            self.leading = seconds
        if len(self.intervals) < 4096:
            self.intervals.append({"start": start / self.rate, "end": end / self.rate, "duration": seconds})
        else:
            self.interval_overflow = True

    def finish(self):
        if not self.frames:
            raise AnalysisError("corrupt_file", "Empty audio stream")
        if self.quiet_start is not None:
            seconds = (self.frames - self.quiet_start) / self.rate
            if seconds >= self.params["silence_min_seconds"]:
                self.trailing = seconds
            self._end_silence(self.frames)
        rms = math.sqrt(self.squares / (self.frames * self.channels))
        return {
            "sample_peak": db_metric(self.peak), "rms": db_metric(rms),
            "crest_factor": metric(20 * math.log10(self.peak / rms), "dB") if rms else unavailable(
                "not_applicable", "Digital silence has no finite crest factor", "dB"),
            "silence_intervals": metric(self.intervals, "s") if not self.interval_overflow else unavailable(
                "unsupported", "More than 4096 silence intervals; use a larger silence_min_seconds", "s"),
            "leading_silence": metric(self.leading, "s"), "trailing_silence": metric(self.trailing, "s"),
        }


def db_metric(value):
    return metric(20 * math.log10(value), "dBFS") if value else unavailable(
        "not_applicable", "Digital silence: negative infinity dBFS", "dBFS")


def envelopes(blocks, frames, rate, channels, points):
    """Second decoding pass avoids retaining signal-sized arrays or temporary audio files."""
    edges = np.linspace(0, frames, min(points, frames) + 1, dtype=np.int64)
    peaks = np.zeros(len(edges) - 1)
    sums = np.zeros_like(peaks)
    cursor = index = 0
    for block in blocks:
        offset = 0
        while offset < len(block):
            if index >= len(peaks):
                raise AnalysisError("asset_changed", "Audio length changed between decoding passes")
            count = min(int(edges[index + 1] - cursor), len(block) - offset)
            part = block[offset:offset + count]
            peaks[index] = max(peaks[index], float(np.abs(part).max()))
            sums[index] += np.einsum("ij,ij->", part, part, dtype=np.float64)
            cursor += count
            offset += count
            if cursor == edges[index + 1]:
                index += 1
    if cursor != frames:
        raise AnalysisError("asset_changed", "Audio length changed between decoding passes")
    times = ((edges[:-1] + edges[1:]) / (2 * rate)).tolist()
    levels = np.sqrt(sums / (np.diff(edges) * channels))
    return {"peak_envelope": sequence(times, peaks.tolist(), "s", "linear full scale"),
            "rms_envelope": sequence(times, levels.tolist(), "s", "linear full scale")}
