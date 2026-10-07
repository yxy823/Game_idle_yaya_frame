"""Tile-bounded Machado 2009 severity-1 simulation and linear-luminance gray."""

ASSET_TYPE = "image"
VERSION = 1
METRICS = {"cvd_grid": "PNG"}
ARTIFACTS = {"cvd_grid": "cvd-grid.png"}
DEFAULTS = {"cvd_max_panel_pixels": 2073600}
LIMITS = {"cvd_max_panel_pixels": [1, 2073600]}
MATRICES = (
    ((.152286, 1.052583, -.204868), (.114503, .786281, .099216), (-.003882, -.048116, 1.051998)),
    ((.367322, .860646, -.227968), (.280085, .672501, .047413), (-.011820, .042940, .968881)),
)


def panels(rgb):
    import numpy as np
    from skimage.color import rgb2xyz

    def encode(linear):
        linear = np.clip(linear, 0, 1)
        return np.where(linear <= .0031308, 12.92 * linear, 1.055 * linear ** (1 / 2.4) - .055)

    linear = np.where(rgb <= .04045, rgb / 12.92, ((rgb + .055) / 1.055) ** 2.4)
    yield rgb
    yield encode(np.repeat(rgb2xyz(rgb)[..., 1:2], 3, axis=-1))
    for matrix in MATRICES:
        yield encode(linear @ np.asarray(matrix, dtype=np.float32).T)


def run(path, params, context):
    import math
    import numpy as np
    from PIL import Image, ImageDraw
    from atomic_output import atomic_target
    from protocol import metric
    from source_probe import AnalysisError
    header = 24
    labels = ("Normal", "Gray", "Protan", "Deutan")
    with Image.open(path) as source:
        if source.width * source.height > params["max_image_pixels"]:
            raise AnalysisError("resource_limit", "Image exceeds max_image_pixels")
        source_size = list(source.size)
        scale = min(1.0, math.sqrt(params["cvd_max_panel_pixels"] / (source.width * source.height)))
        size = (max(1, int(source.width * scale)), max(1, int(source.height * scale)))
        with source.convert("RGBA") as rgba:
            preview = rgba.resize(size, Image.Resampling.LANCZOS) if size != rgba.size else rgba.copy()
    with preview:
        width, height = size
        with Image.new("RGBA", (width * 2, (height + header) * 2), (32, 32, 32, 255)) as grid:
            draw = ImageDraw.Draw(grid)
            for index, label in enumerate(labels):
                draw.text(((index % 2) * width + 2, (index // 2) * (height + header) + 4), label, fill="white")
            for y in range(0, height, 256):
                for x in range(0, width, 256):
                    with preview.crop((x, y, min(x + 256, width), min(y + 256, height))) as tile:
                        pixels = np.asarray(tile)
                        rgb = pixels[:, :, :3].astype(np.float32) / 255
                        for index, transformed in enumerate(panels(rgb)):
                            output = pixels.copy()
                            output[:, :, :3] = np.rint(transformed * 255).astype(np.uint8)
                            with Image.fromarray(output) as result_tile:
                                grid.paste(result_tile, ((index % 2) * width + x,
                                                        (index // 2) * (height + header) + header + y))
            destination = (context["artifact_dir"] / "cvd-grid.png").resolve()
            with atomic_target(destination) as temporary:
                grid.save(temporary, format="PNG")
            value = {"path": destination.as_posix(), "method": "Machado2009_severity_1_linear_srgb",
                     "panels": ["normal", "gray", "protan", "deutan"], "source_size": source_size,
                     "panel_size": list(size), "image_size": list(grid.size)}
    return {"cvd_grid": metric(value, "PNG")}, {}, [{"code": "cvd_simulation", "message":
        "Machado 2009 severity=1 in linear sRGB; gray uses XYZ Y; clipped to sRGB, alpha preserved. Display-sized preview only; simulation is not a universal accessibility pass/fail. Source: doi:10.1109/TVCG.2009.113"}]
