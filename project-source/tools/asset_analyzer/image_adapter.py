"""Pillow/NumPy source-image measurements; no inferred aesthetic scores."""

import numpy as np
from PIL import Image

from protocol import metric, sequence, unavailable


def analyze(path, params):
    with Image.open(path) as image:
        if image.width * image.height > params["max_image_pixels"]:
            raise ValueError("Image exceeds max_image_pixels")
        image.load()
        mode, fmt, size = image.mode, image.format, image.size
        has_alpha = "A" in image.getbands() or "transparency" in image.info
        rgba = np.asarray(image.convert("RGBA"))
    alpha = rgba[:, :, 3].reshape(-1)
    rgb = rgba[:, :, :3].reshape(-1, 3)[alpha > 0]
    metrics = {
        "format": metric(fmt), "width": metric(size[0], "px"),
        "height": metric(size[1], "px"), "aspect_ratio": metric(size[0] / size[1]),
        "mode": metric(mode), "has_alpha": metric(has_alpha),
        "transparent_ratio": metric(float(np.mean(alpha == 0)), "ratio"),
        "opaque_ratio": metric(float(np.mean(alpha == 255)), "ratio"),
        "translucent_ratio": metric(float(np.mean((alpha > 0) & (alpha < 255))), "ratio"),
        "alpha_mean": metric(float(np.mean(alpha)), "0..255"),
    }
    series = {"alpha_histogram": histogram(alpha, 256, (0, 256), "alpha 0..255")}
    if len(rgb) == 0:
        for key in ("dominant_color", "palette", "color_count", "rgb_mean",
                    "saturation_mean", "luma_mean", "luma_stddev"):
            metrics[key] = unavailable("not_applicable", "No visible pixels")
        return metrics, series, []
    colors, counts = np.unique(rgb, axis=0, return_counts=True)
    top = np.argsort(counts)[-params["palette_size"]:][::-1]
    palette = [{"rgb": colors[i].tolist(), "ratio": float(counts[i] / len(rgb))} for i in top]
    normalized = rgb.astype(np.float64) / 255.0
    maximum, minimum = normalized.max(axis=1), normalized.min(axis=1)
    saturation = np.divide(maximum - minimum, maximum, out=np.zeros_like(maximum), where=maximum > 0)
    # Explicit encoded-sRGB luma proxy, not calibrated linear-light luminance.
    luma = normalized @ np.array([0.2126, 0.7152, 0.0722])
    metrics.update({
        "dominant_color": metric(palette[0]["rgb"], "RGB 0..255"),
        "palette": metric(palette, "visible pixel frequency"),
        "color_count": metric(len(colors), "distinct visible RGB"),
        "rgb_mean": metric(rgb.mean(axis=0).tolist(), "RGB 0..255"),
        "saturation_mean": metric(float(saturation.mean()), "ratio"),
        "luma_mean": metric(float(luma.mean()), "encoded sRGB 0..1"),
        "luma_stddev": metric(float(luma.std()), "encoded sRGB 0..1"),
    })
    for channel, name in enumerate(("red", "green", "blue")):
        series[name + "_histogram"] = histogram(rgb[:, channel], 256, (0, 256), "RGB 0..255")
    series["saturation_histogram"] = histogram(saturation, 32, (0, 1), "saturation 0..1")
    series["luma_histogram"] = histogram(luma, 32, (0, 1), "encoded sRGB luma 0..1")
    return metrics, series, [{"code": "source_pixels", "message":
        "First frame; encoded sRGB assumption. Color statistics exclude alpha=0; visible pixels "
        "have equal weight. Godot import, shader, display and ICC transforms are not measured."}]


def histogram(values, bins, limits, unit):
    counts, edges = np.histogram(values, bins=bins, range=limits)
    return sequence(((edges[:-1] + edges[1:]) / 2).tolist(),
                    (counts / max(len(values), 1)).tolist(), unit, "ratio", "histogram")
