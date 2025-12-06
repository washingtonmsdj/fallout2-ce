extends Node
## Enhanced Audio Manager for Fallout 2 CE
## Controls music, SFX, voice, ambient sounds with advanced features

signal music_transition_completed(from_stream: AudioStream, to_stream: AudioStream)
signal sfx_played(sfx_name: String)
signal voice_line_completed(voice_id: String)

const MAX_SFX_PLAYERS := 16
const MAX_VOICE_PLAYERS := 4
const MAX_AMBIENT_PLAYERS := 8

# Music system
var music_player: AudioStreamPlayer
var music_player_secondary: AudioStreamPlayer  # For crossfading
var current_music_stream: AudioStream = null
var target_music_stream: AudioStream = null
var music_crossfade_duration: float = 2.0
var music_crossfade_timer: float = 0.0
var is_crossfading: bool = false

# SFX system
var sfx_players: Array[AudioStreamPlayer] = []
var current_sfx_index := 0
var sfx_library: Dictionary = {}  # {sfx_name: AudioStream}

# Voice system
var voice_players: Array[AudioStreamPlayer] = []
var current_voice_index := 0
var voice_library: Dictionary = {}  # {voice_id: AudioStream}
var current_voice_id: String = ""

# Ambient system
var ambient_players: Array[AudioStreamPlayer] = []
var current_ambient_index := 0
var ambient_library: Dictionary = {}  # {ambient_name: AudioStream}
var active_ambients: Array[String] = []

# Audio settings
var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 0.8
var voice_volume: float = 0.9
var ambient_volume: float = 0.5

func _ready() -> void:
	_setup_audio_players()
	_load_audio_settings()

func _setup_audio_players() -> void:
	# Music players (primary and secondary for crossfading)
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)

	music_player_secondary = AudioStreamPlayer.new()
	music_player_secondary.bus = "Music"
	add_child(music_player_secondary)

	# SFX players
	for i in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		player.finished.connect(_on_sfx_finished.bind(i))
		add_child(player)
		sfx_players.append(player)

	# Voice players
	for i in MAX_VOICE_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = "Voice"
		player.finished.connect(_on_voice_finished.bind(i))
		add_child(player)
		voice_players.append(player)

	# Ambient players
	for i in MAX_AMBIENT_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = "Ambient"
		player.finished.connect(_on_ambient_finished.bind(i))
		add_child(player)
		ambient_players.append(player)

func _process(delta: float) -> void:
	_handle_music_crossfade(delta)

## Handle music crossfade transitions
func _handle_music_crossfade(delta: float) -> void:
	if not is_crossfading:
		return

	music_crossfade_timer += delta
	var progress = music_crossfade_timer / music_crossfade_duration

	if progress >= 1.0:
		# Crossfade complete
		music_player.stream = target_music_stream
		music_player.volume_db = linear_to_db(music_volume)
		music_player_secondary.stop()
		current_music_stream = target_music_stream
		target_music_stream = null
		is_crossfading = false
		music_crossfade_timer = 0.0
		music_transition_completed.emit(current_music_stream, target_music_stream)
	else:
		# Crossfade in progress
		var primary_vol = music_volume * (1.0 - progress)
		var secondary_vol = music_volume * progress
		music_player.volume_db = linear_to_db(primary_vol)
		music_player_secondary.volume_db = linear_to_db(secondary_vol)

## Enhanced music playback with crossfade support
func play_music(stream: AudioStream, fade_duration: float = 2.0, force_restart: bool = false) -> void:
	if music_player.stream == stream and music_player.playing and not force_restart:
		return

	if fade_duration <= 0.0:
		# Instant switch
		music_player.stream = stream
		music_player.volume_db = linear_to_db(music_volume)
		music_player.play()
		current_music_stream = stream
		return

	# Start crossfade
	target_music_stream = stream
	music_crossfade_duration = fade_duration
	music_crossfade_timer = 0.0
	is_crossfading = true

	# Setup secondary player
	music_player_secondary.stream = stream
	music_player_secondary.volume_db = linear_to_db(0.0)  # Start silent
	music_player_secondary.play()

## Stop music with fade out
func stop_music(fade_duration: float = 1.0) -> void:
	if fade_duration <= 0.0:
		music_player.stop()
		music_player_secondary.stop()
		current_music_stream = null
		target_music_stream = null
		is_crossfading = false
		return

	# Fade out current music
	target_music_stream = null
	music_crossfade_duration = fade_duration
	music_crossfade_timer = 0.0
	is_crossfading = true

## Enhanced SFX playback with library support
func play_sfx(stream: AudioStream, volume_db: float = 0.0, sfx_name: String = "") -> void:
	var player := sfx_players[current_sfx_index]
	player.stream = stream
	player.volume_db = volume_db + linear_to_db(sfx_volume)
	player.play()
	current_sfx_index = (current_sfx_index + 1) % MAX_SFX_PLAYERS

	if sfx_name != "":
		sfx_played.emit(sfx_name)

## Play SFX by name from library
func play_sfx_by_name(sfx_name: String, volume_db: float = 0.0) -> void:
	if sfx_library.has(sfx_name):
		play_sfx(sfx_library[sfx_name], volume_db, sfx_name)
	else:
		push_warning("SFX not found in library: " + sfx_name)

## Register SFX in library
func register_sfx(sfx_name: String, stream: AudioStream) -> void:
	sfx_library[sfx_name] = stream

## Play action-based SFX (combat, movement, etc.)
func play_action_sfx(action_type: String, variant: String = "default") -> void:
	var sfx_name = action_type + "_" + variant
	play_sfx_by_name(sfx_name)

## Voice system methods
func play_voice_line(voice_id: String, volume_db: float = 0.0) -> void:
	if voice_library.has(voice_id):
		var player := voice_players[current_voice_index]
		player.stream = voice_library[voice_id]
		player.volume_db = volume_db + linear_to_db(voice_volume)
		player.play()
		current_voice_id = voice_id
		current_voice_index = (current_voice_index + 1) % MAX_VOICE_PLAYERS
	else:
		push_warning("Voice line not found: " + voice_id)

## Register voice line in library
func register_voice_line(voice_id: String, stream: AudioStream) -> void:
	voice_library[voice_id] = stream

## Check if voice line exists
func has_voice_line(voice_id: String) -> bool:
	return voice_library.has(voice_id)

## Stop current voice line
func stop_voice_line() -> void:
	for player in voice_players:
		player.stop()
	current_voice_id = ""

## Ambient sound system methods
func play_ambient_sound(ambient_name: String, loop: bool = true) -> void:
	if ambient_library.has(ambient_name):
		if ambient_name in active_ambients:
			return  # Already playing

		var player := ambient_players[current_ambient_index]
		player.stream = ambient_library[ambient_name]
		player.volume_db = linear_to_db(ambient_volume)
		if loop:
			player.stream.loop = true
		player.play()
		active_ambients.append(ambient_name)
		current_ambient_index = (current_ambient_index + 1) % MAX_AMBIENT_PLAYERS
	else:
		push_warning("Ambient sound not found: " + ambient_name)

## Stop ambient sound
func stop_ambient_sound(ambient_name: String) -> void:
	if ambient_name in active_ambients:
		active_ambients.erase(ambient_name)

		# Find and stop the player
		for player in ambient_players:
			if player.playing and player.stream == ambient_library.get(ambient_name):
				player.stop()
				break

## Stop all ambient sounds
func stop_all_ambient_sounds() -> void:
	active_ambients.clear()
	for player in ambient_players:
		player.stop()

## Register ambient sound in library
func register_ambient_sound(ambient_name: String, stream: AudioStream) -> void:
	ambient_library[ambient_name] = stream

## Set area ambient sounds (location-based)
func set_area_ambient(ambient_names: Array[String]) -> void:
	stop_all_ambient_sounds()
	for ambient_name in ambient_names:
		play_ambient_sound(ambient_name)

## Audio settings methods
func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	_save_audio_settings()

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	if music_player and not is_crossfading:
		music_player.volume_db = linear_to_db(music_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	_save_audio_settings()

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	_save_audio_settings()

func set_voice_volume(volume: float) -> void:
	voice_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"), linear_to_db(voice_volume))
	_save_audio_settings()

func set_ambient_volume(volume: float) -> void:
	ambient_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Ambient"), linear_to_db(ambient_volume))
	for player in ambient_players:
		if player.playing:
			player.volume_db = linear_to_db(ambient_volume)
	_save_audio_settings()

## Get current audio settings
func get_audio_settings() -> Dictionary:
	return {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"voice_volume": voice_volume,
		"ambient_volume": ambient_volume
	}

## Load audio settings from config
func _load_audio_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	if err == OK:
		master_volume = config.get_value("audio", "master_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 0.7)
		sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
		voice_volume = config.get_value("audio", "voice_volume", 0.9)
		ambient_volume = config.get_value("audio", "ambient_volume", 0.5)

		# Apply loaded settings
		set_master_volume(master_volume)
		set_music_volume(music_volume)
		set_sfx_volume(sfx_volume)
		set_voice_volume(voice_volume)
		set_ambient_volume(ambient_volume)

## Save audio settings to config
func _save_audio_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "voice_volume", voice_volume)
	config.set_value("audio", "ambient_volume", ambient_volume)
	config.save("user://audio_settings.cfg")

## Callback methods for audio players
func _on_sfx_finished(player_index: int) -> void:
	# SFX finished playing
	pass

func _on_voice_finished(player_index: int) -> void:
	var voice_id = current_voice_id
	current_voice_id = ""
	voice_line_completed.emit(voice_id)

func _on_ambient_finished(player_index: int) -> void:
	# Ambient sound finished (if not looping)
	pass
