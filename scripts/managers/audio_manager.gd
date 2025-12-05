extends Node
## Gerenciador de áudio centralizado
## Controla música, SFX e mixagem

const MAX_SFX_PLAYERS := 16

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var current_sfx_index := 0

func _ready() -> void:
	_setup_audio_players()

func _setup_audio_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Music"
	add_child(music_player)
	
	for i in MAX_SFX_PLAYERS:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_players.append(player)

func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
	if music_player.stream == stream and music_player.playing:
		return
	music_player.stream = stream
	music_player.play()

func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	var player := sfx_players[current_sfx_index]
	player.stream = stream
	player.volume_db = volume_db
	player.play()
	current_sfx_index = (current_sfx_index + 1) % MAX_SFX_PLAYERS
