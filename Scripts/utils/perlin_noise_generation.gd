class_name PerlinNoise

const OCTAVES: int = 5

var size: Vector2i
var prng: Prng
var _cachedData: Array[float]

func _init(config: GeneratorConfiguration) -> void:
	self.size = Vector2i(config.mapSize.x, config.mapSize.y);
	self.prng = Prng.new(config.getSeed())
	_warmUpPrng()

func get2DPlot(x: int, y: int) -> float:
	var total  = 0.0
	var offset = 1.0
	var divider = 1.0
	var amplitude = 32.0
	for i in OCTAVES:
		var currentX: float = x * offset
		var currentY: float = y * offset
		var value = getSmoothedPlot(int(currentX), int(currentY)) * amplitude
		total += value
		divider += amplitude
		amplitude *= .5
		offset *= .5
	return total / divider

func getSmoothedPlot(x: int, y: int) -> float:
	var current = _cachedData[coordToIndex(x, y)]

	var left = _cachedData[coordToIndex(x - 1, y)]
	var right = _cachedData[coordToIndex(x + 1, y)]
	var top = _cachedData[coordToIndex(x, y - 1)]
	var bottom = _cachedData[coordToIndex(x, y + 1)]

	var n1: float = lerpf(current, top, abs(top - current));
	var n2: float = lerpf(current, right, abs(right - current));
	var n3: float = lerpf(current, bottom, abs(bottom - current));
	var n4: float = lerpf(current, left, abs(left - current));

	var topLeft = _cachedData[coordToIndex(x - 1, y - 1)]
	var topRight = _cachedData[coordToIndex(x + 1, y - 1)]
	var bottomLeft = _cachedData[coordToIndex(x - 1, y + 1)]
	var bottomRight = _cachedData[coordToIndex(x + 1, y + 1)]

	var reducer = .5

	var n5: float = lerpf(current, topLeft, abs(topLeft - current)) * reducer;
	var n6: float = lerpf(current, topRight, abs(topRight - current)) * reducer;
	var n7: float = lerpf(current, bottomRight, abs(bottomRight - current)) * reducer;
	var n8: float = lerpf(current, bottomLeft, abs(bottomLeft - current)) * reducer;

	var noiseValue: float = (n1 + n2 + n3 + n4 + n5 + n6 + n7 + n8) / (4.0 + 4 * reducer);
	return noiseValue;

func _warmUpPrng() -> void:
	var cacheSize: Vector2i = size + Vector2i.ONE * 2;
	_cachedData.resize(cacheSize.x * cacheSize.y)

	var index = 0
	for y in range(-1, cacheSize.y - 1):
		for x in range(-1, cacheSize.x - 1):
			_cachedData[index] = self.prng.rand_float(x, y)
			index += 1

func coordToIndex(x: int, y: int) -> int:
	return (y + 1) * (size.x + 2) + (x + 1)
