extends RefCounted
## Silhouette measurements on mask renders: a pixel belongs to the subject when every RGB channel
## is above 127. Pure functions on Image, so they run headless; measure_3d.gd does the rendering.

const THRESHOLD := 127


## The subject pixels inside region (clipped to the image): {"region": Rect2i, "bits": 1 per pixel}.
static func mask(image: Image, region: Rect2i) -> Dictionary:
	var area := region.intersection(Rect2i(Vector2i.ZERO, image.get_size()))
	var rgb := image
	if image.get_format() != Image.FORMAT_RGB8:
		rgb = Image.create_from_data(image.get_width(), image.get_height(), false, image.get_format(),
			image.get_data())
		rgb.convert(Image.FORMAT_RGB8)
	var data := rgb.get_data()
	var bits := PackedByteArray()
	bits.resize(area.size.x * area.size.y)
	for y in area.size.y:
		var row := (area.position.y + y) * rgb.get_width() + area.position.x
		for x in area.size.x:
			var offset := (row + x) * 3
			if data[offset] > THRESHOLD and data[offset + 1] > THRESHOLD and data[offset + 2] > THRESHOLD:
				bits[y * area.size.x + x] = 1
	return {"region": area, "bits": bits}


## Bounding box in image pixels as [left, top, right, bottom) with its edges and pixel area.
static func dimensions(silhouette: Dictionary) -> Dictionary:
	var region: Rect2i = silhouette.region
	var bits: PackedByteArray = silhouette.bits
	var low := Vector2i(region.end)
	var high := Vector2i(-1, -1)
	var area := 0
	for y in region.size.y:
		for x in region.size.x:
			if bits[y * region.size.x + x] == 0:
				continue
			var point := region.position + Vector2i(x, y)
			low = low.min(point)
			high = high.max(point)
			area += 1
	if area == 0:
		return {"error": ERR_INVALID_DATA, "message": "empty silhouette"}
	var size := high - low + Vector2i.ONE
	return {"error": OK, "bounds": [low.x, low.y, high.x + 1, high.y + 1], "width": size.x,
		"height": size.y, "long_edge": maxi(size.x, size.y), "short_edge": mini(size.x, size.y),
		"area": area}


## How far the silhouette reaches outside the slot's projected outline, a convex polygon in screen
## pixels; ratio divides by the outline's screen width. Pixel centres are measured.
static func protrusion(silhouette: Dictionary, outline: PackedVector2Array) -> Dictionary:
	var region: Rect2i = silhouette.region
	var bits: PackedByteArray = silhouette.bits
	var farthest := 0.0
	var extremity := Vector2.ZERO
	for y in region.size.y:
		for x in region.size.x:
			if bits[y * region.size.x + x] == 0:
				continue
			var point := Vector2(region.position) + Vector2(x + 0.5, y + 0.5)
			var distance := _outside_distance(point, outline)
			if distance > farthest:
				farthest = distance
				extremity = point
	var left := INF
	var right := -INF
	for corner in outline:
		left = minf(left, corner.x)
		right = maxf(right, corner.x)
	var width := right - left
	return {"pixels": farthest, "ratio": farthest / width, "slot_width": width,
		"extremity": [extremity.x, extremity.y]}


## The share of the subject hidden when its neighbours are rendered too. Both masks cover the same
## region; a subject pixel that appears only with neighbours means the subject moved between renders.
static func occlusion(alone: Dictionary, with_neighbors: Dictionary) -> Dictionary:
	if alone.region != with_neighbors.region:
		return {"error": ERR_INVALID_PARAMETER, "message": "masks cover different regions"}
	var own: PackedByteArray = alone.bits
	var shown: PackedByteArray = with_neighbors.bits
	var total := 0
	var hidden := 0
	for index in own.size():
		if shown[index] == 1 and own[index] == 0:
			return {"error": ERR_INVALID_DATA, "message": "silhouette moved between the two renders"}
		total += own[index]
		hidden += 1 if own[index] == 1 and shown[index] == 0 else 0
	if total == 0:
		return {"error": ERR_INVALID_DATA, "message": "empty silhouette"}
	return {"error": OK, "hidden_pixels": hidden, "ratio": float(hidden) / total}


static func _outside_distance(point: Vector2, outline: PackedVector2Array) -> float:
	var nearest := INF
	var positive := true
	var negative := true
	for index in outline.size():
		var start := outline[index]
		var edge := outline[(index + 1) % outline.size()] - start
		var offset := point - start
		var side := edge.cross(offset)
		positive = positive and side >= 0.0
		negative = negative and side <= 0.0
		var along := clampf(offset.dot(edge) / edge.length_squared(), 0.0, 1.0)
		nearest = minf(nearest, (offset - edge * along).length())
	return 0.0 if positive or negative else nearest
