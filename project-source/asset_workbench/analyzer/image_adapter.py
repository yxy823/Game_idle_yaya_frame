"""Pillow decoding with bounded tile statistics and explicit palette sampling."""

import math

import numpy as np
from PIL import Image

from protocol import metric, sequence, unavailable
from source_probe import AnalysisError, decode_error

TILE = 256
COLOR_SAMPLE_PIXELS = 262144


def analyze(path, params):
    try:
        with Image.open(path) as image:
            if image.width * image.height > params["max_image_pixels"]:
                raise AnalysisError("resource_limit", "Image exceeds max_image_pixels")
            image.load()
            return measurements(image, params)
    except (AnalysisError, MemoryError):
        raise
    except (OSError, ValueError, NotImplementedError) as error:
        raise decode_error(error) from error


def measurements(image, params):
    """Only the decoder image is full-size. Numeric intermediates are tile-bounded."""
    total = image.width * image.height
    step = max(1, math.ceil(total / COLOR_SAMPLE_PIXELS))
    alpha_hist = np.zeros(256, dtype=np.int64)
    rgb_hist = np.zeros((3, 256), dtype=np.int64)
    sat_hist = np.zeros(32, dtype=np.int64)
    luma_hist = np.zeros(32, dtype=np.int64)
    rgb_sum = np.zeros(3, dtype=np.float64)
    visible = 0
    sat_sum = luma_sum = luma_square = 0.0
    palette_parts = []
    for y in range(0, image.height, TILE):
        for x in range(0, image.width, TILE):
            with image.crop((x, y, min(x + TILE, image.width), min(y + TILE, image.height))) as tile:
                rgba = np.asarray(tile.convert("RGBA"))
            alpha = rgba[:, :, 3].reshape(-1)
            alpha_hist += np.bincount(alpha, minlength=256)
            rgb = rgba[:, :, :3].reshape(-1, 3)[alpha > 0]
            row_indices = np.arange(y, y + rgba.shape[0])[:, None] * image.width
            indices = row_indices + np.arange(x, x + rgba.shape[1])
            sampled = rgba[(indices % step == 0) & (rgba[:, :, 3] > 0), :3]
            if len(sampled):
                palette_parts.append(sampled.copy())
            if not len(rgb):
                continue
            visible += len(rgb)
            rgb_sum += rgb.sum(axis=0, dtype=np.float64)
            for channel in range(3):
                rgb_hist[channel] += np.bincount(rgb[:, channel], minlength=256)
            normalized = rgb.astype(np.float32) / 255
            high, low = normalized.max(axis=1), normalized.min(axis=1)
            saturation = np.divide(high - low, high, out=np.zeros_like(high), where=high > 0)
            luma = normalized @ np.array([0.2126, 0.7152, 0.0722], dtype=np.float32)
            sat_sum += saturation.sum(dtype=np.float64)
            luma_sum += luma.sum(dtype=np.float64)
            luma_square += np.einsum("i,i->", luma, luma, dtype=np.float64)
            sat_hist += np.histogram(saturation, bins=32, range=(0, 1))[0]
            luma_hist += np.histogram(luma, bins=32, range=(0, 1))[0]
    metrics = {
        "format": metric(image.format), "width": metric(image.width, "px"),
        "height": metric(image.height, "px"), "aspect_ratio": metric(image.width / image.height),
        "mode": metric(image.mode),
        "has_alpha": metric("A" in image.getbands() or "transparency" in image.info),
        "transparent_ratio": metric(float(alpha_hist[0] / total), "ratio"),
        "opaque_ratio": metric(float(alpha_hist[255] / total), "ratio"),
        "translucent_ratio": metric(float(alpha_hist[1:255].sum() / total), "ratio"),
        "alpha_mean": metric(float(alpha_hist @ np.arange(256) / total), "0..255"),
    }
    series = {"alpha_histogram": distribution(alpha_hist, total, 256, "alpha 0..255")}
    notes = [{"code": "source_pixels", "message":
              "First frame; encoded sRGB assumption. Color statistics exclude alpha=0 with equal "
              "weight. Import, shader, display and ICC transforms are not measured."}]
    if not visible:
        for key in ("dominant_color", "palette", "color_count", "rgb_mean",
                    "saturation_mean", "luma_mean", "luma_stddev", "palette_sample_pixels"):
            metrics[key] = unavailable("not_applicable", "No visible pixels")
        return metrics, series, notes
    metrics.update({
        "rgb_mean": metric((rgb_sum / visible).tolist(), "RGB 0..255"),
        "saturation_mean": metric(float(sat_sum / visible), "ratio"),
        "luma_mean": metric(float(luma_sum / visible), "encoded sRGB 0..1"),
        "luma_stddev": metric(math.sqrt(max(0, luma_square / visible - (luma_sum / visible) ** 2)),
                              "encoded sRGB 0..1"),
    })
    metrics.update(palette_metrics(palette_parts, step, params["palette_size"]))
    if step > 1:
        notes.append({"code": "sampled_palette", "message":
                      f"Palette uses deterministic source-pixel stride {step}, at most "
                      f"{COLOR_SAMPLE_PIXELS} pixels; exact color count is unsupported at this size. "
                      "Alpha, mean values and histograms still use all pixels."})
    for channel, name in enumerate(("red", "green", "blue")):
        series[name + "_histogram"] = distribution(rgb_hist[channel], visible, 256, "RGB 0..255")
    series["saturation_histogram"] = distribution(sat_hist, visible, 1, "saturation 0..1")
    series["luma_histogram"] = distribution(luma_hist, visible, 1, "encoded sRGB luma 0..1")
    return metrics, series, notes


def palette_metrics(parts, step, size):
    if not parts:
        return {key: unavailable("not_applicable", "No visible pixel in bounded palette sample")
                for key in ("palette", "dominant_color", "color_count", "palette_sample_pixels")}
    sampled = np.concatenate(parts)
    colors, counts = np.unique(sampled, axis=0, return_counts=True)
    order = np.argsort(counts)[-size:][::-1]
    palette = [{"rgb": colors[i].tolist(), "ratio": float(counts[i] / len(sampled))} for i in order]
    return {
        "dominant_color": metric(palette[0]["rgb"], "RGB 0..255"),
        "palette": metric(palette, "sampled visible pixel frequency" if step > 1 else "visible pixel frequency"),
        "palette_sample_pixels": metric(len(sampled), "px"),
        "color_count": metric(len(colors), "distinct visible RGB") if step == 1 else unavailable(
            "unsupported", "Exact color count limited to 262144 source pixels", "distinct visible RGB"),
    }


def distribution(counts, total, upper, unit):
    centers = (np.arange(len(counts), dtype=np.float64) + 0.5) * upper / len(counts)
    return sequence(centers.tolist(), (counts / max(total, 1)).tolist(), unit, "ratio", "histogram")
