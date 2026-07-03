extends Node

## Autoload singleton wrapping the shared PrngService (registered as `Prng`).
## Systems that need randomness pull it from here (or a named sub-stream) so the
## whole project stays deterministic for a given seed — nothing should ever call
## Godot's global randi()/randf().

var service: PrngService


func _ready() -> void:
	# A default deterministic service until a level configures one.
	if service == null:
		service = PrngService.new(false, 0)


## (Re)initialises the shared service from a GenerationConfig. `entropy` is only
## consulted when the config requests a random seed.
func configure(config: GenerationConfig, entropy: int = 0) -> void:
	service = config.make_prng(entropy)


func configure_with_seed(use_random_seed: bool, seed_value: int, entropy: int = 0) -> void:
	service = PrngService.new(use_random_seed, seed_value, entropy)


## Named sub-stream off the shared service (see PrngService.get_stream).
func stream(stream_name: String) -> PrngService:
	return service.get_stream(stream_name)
