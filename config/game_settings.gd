extends Resource
class_name GameSettings
## Configurações globais do jogo

@export_group("Graphics")
@export var resolution: Vector2i = Vector2i(1920, 1080)
@export var fullscreen: bool = false
@export var vsync: bool = true
@export_range(0, 3) var quality_preset: int = 2  # 0=Low, 1=Medium, 2=High, 3=Ultra

@export_group("Audio")
@export_range(0.0, 1.0) var master_volume: float = 1.0
@export_range(0.0, 1.0) var music_volume: float = 0.8
@export_range(0.0, 1.0) var sfx_volume: float = 1.0
@export_range(0.0, 1.0) var voice_volume: float = 1.0

@export_group("Gameplay")
@export var difficulty: int = 1  # 0=Easy, 1=Normal, 2=Hard
@export var auto_save: bool = true
@export var show_tutorials: bool = true

func apply_settings() -> void:
	_apply_graphics()
	_apply_audio()

func _apply_graphics() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
	
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)

func _apply_audio() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus != -1:
		AudioServer.set_bus_volume_db(music_bus, linear_to_db(music_volume))
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if sfx_bus != -1:
		AudioServer.set_bus_volume_db(sfx_bus, linear_to_db(sfx_volume))
