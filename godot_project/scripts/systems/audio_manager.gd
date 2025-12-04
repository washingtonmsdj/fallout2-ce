extends Node

## AudioManager - Sistema de áudio do Fallout 2
## Gerenciar música ambiente e efeitos sonoros

signal music_changed(track_name: String)
signal volume_changed(volume_type: String, value: float)

# Players de áudio
var music_player: AudioStreamPlayer = null
var music_player_fade: AudioStreamPlayer = null  # Para crossfade
var sfx_players: Array[AudioStreamPlayer] = []
var voice_player: AudioStreamPlayer = null

# Configuração de volumes
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var voice_volume: float = 1.0

# Estado
var current_music: String = ""
var is_fading: bool = false
var fade_tween: Tween = null

# Constantes
const MAX_SFX_PLAYERS = 10
const FADE_DURATION = 1.0

func _ready():
	_setup_audio_players()
	
	# Conectar ao GameManager para volumes
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		master_volume = gm.master_volume
		music_volume = gm.music_volume
		sfx_volume = gm.sfx_volume
		voice_volume = gm.speech_volume
		
		# Conectar sinais de mudança de volume
		# (será implementado quando GameManager emitir sinais)

func _setup_audio_players():
	"""Configura players de áudio"""
	# Player de música principal
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = linear_to_db(music_volume * master_volume)
	add_child(music_player)
	
	# Player de música para crossfade
	music_player_fade = AudioStreamPlayer.new()
	music_player_fade.name = "MusicPlayerFade"
	music_player_fade.volume_db = linear_to_db(music_volume * master_volume)
	add_child(music_player_fade)
	
	# Players de SFX
	for i in range(MAX_SFX_PLAYERS):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer" + str(i)
		sfx_player.volume_db = linear_to_db(sfx_volume * master_volume)
		add_child(sfx_player)
		sfx_players.append(sfx_player)
	
	# Player de voz
	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.volume_db = linear_to_db(voice_volume * master_volume)
	add_child(voice_player)

# === MÚSICA AMBIENTE ===

func play_music(track_path: String, fade_in: bool = false):
	"""
	Gerenciar música ambiente
	Reproduz música de fundo
	"""
	if current_music == track_path and music_player.playing:
		return  # Já está tocando
	
	current_music = track_path
	
	var stream = load(track_path)
	if not stream:
		push_error("AudioManager: Música não encontrada: " + track_path)
		return
	
	music_player.stream = stream
	music_player.play()
	
	if fade_in:
		_fade_in_music(music_player)
	
	music_changed.emit(track_path)
	print("AudioManager: Tocando música: ", track_path)

func stop_music(fade_out: bool = false):
	"""Para música ambiente"""
	if fade_out:
		_fade_out_music(music_player)
	else:
		music_player.stop()
	
	current_music = ""
	music_changed.emit("")

func change_music(new_track_path: String, crossfade: bool = true):
	"""
	Implementar transição de música
	Crossfade entre tracks
	Mudar música por área
	"""
	if crossfade and music_player.playing:
		# Crossfade: fade out atual, fade in nova
		_crossfade_music(new_track_path)
	else:
		# Mudança direta
		play_music(new_track_path, true)

func _crossfade_music(new_track_path: String):
	"""Faz crossfade entre duas músicas"""
	if is_fading:
		return
	
	is_fading = true
	
	var new_stream = load(new_track_path)
	if not new_stream:
		push_error("AudioManager: Música não encontrada: " + new_track_path)
		is_fading = false
		return
	
	# Configurar player de fade com nova música
	music_player_fade.stream = new_stream
	music_player_fade.volume_db = linear_to_db(0.0)  # Começar em 0
	music_player_fade.play()
	
	# Fade out música atual, fade in nova
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	
	# Fade out atual
	fade_tween.tween_property(music_player, "volume_db", linear_to_db(0.0), FADE_DURATION)
	
	# Fade in nova
	fade_tween.tween_property(music_player_fade, "volume_db", linear_to_db(music_volume * master_volume), FADE_DURATION)
	
	await fade_tween.finished
	
	# Trocar players
	var temp = music_player
	music_player = music_player_fade
	music_player_fade = temp
	
	music_player_fade.stop()
	music_player_fade.volume_db = linear_to_db(music_volume * master_volume)
	
	current_music = new_track_path
	is_fading = false
	music_changed.emit(new_track_path)
	
	print("AudioManager: Crossfade completo para: ", new_track_path)

func _fade_in_music(player: AudioStreamPlayer):
	"""Fade in de música"""
	player.volume_db = linear_to_db(0.0)
	
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(player, "volume_db", linear_to_db(music_volume * master_volume), FADE_DURATION)

func _fade_out_music(player: AudioStreamPlayer):
	"""Fade out de música"""
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.tween_property(player, "volume_db", linear_to_db(0.0), FADE_DURATION)
	await fade_tween.finished
	player.stop()

# === EFEITOS SONOROS ===

func play_sfx(sound_path: String, position: Vector2 = Vector2.ZERO):
	"""
	Implementar efeitos sonoros
	Tocar sons de ações (ataque, passo, etc.)
	Posicionamento 2D básico
	"""
	var stream = load(sound_path)
	if not stream:
		push_error("AudioManager: SFX não encontrado: " + sound_path)
		return
	
	# Encontrar player disponível
	var player = _get_available_sfx_player()
	if not player:
		# Todos ocupados, usar o primeiro
		player = sfx_players[0]
	
	player.stream = stream
	player.volume_db = linear_to_db(sfx_volume * master_volume)
	
	# Posicionamento 2D básico
	if position != Vector2.ZERO:
		player.position = position
		player.pitch_scale = 1.0  # Pode variar para efeito de distância
	
	player.play()
	
	print("AudioManager: Tocando SFX: ", sound_path)

func play_voice(voice_path: String):
	"""Toca voz/diálogo"""
	var stream = load(voice_path)
	if not stream:
		push_error("AudioManager: Voz não encontrada: " + voice_path)
		return
	
	voice_player.stream = stream
	voice_player.volume_db = linear_to_db(voice_volume * master_volume)
	voice_player.play()
	
	print("AudioManager: Tocando voz: ", voice_path)

func stop_voice():
	"""Para voz"""
	voice_player.stop()

func _get_available_sfx_player() -> AudioStreamPlayer:
	"""Retorna player de SFX disponível"""
	for player in sfx_players:
		if not player.playing:
			return player
	return null

# === CONTROLE DE VOLUME ===

func set_master_volume(value: float):
	"""
	Implementar controle de volume
	Volumes separados (master, music, sfx, voice)
	Aplicar configurações imediatamente
	"""
	master_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	volume_changed.emit("master", master_volume)

func set_music_volume(value: float):
	"""Define volume de música"""
	music_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	volume_changed.emit("music", music_volume)

func set_sfx_volume(value: float):
	"""Define volume de SFX"""
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	volume_changed.emit("sfx", sfx_volume)

func set_voice_volume(value: float):
	"""Define volume de voz"""
	voice_volume = clamp(value, 0.0, 1.0)
	_apply_volumes()
	volume_changed.emit("voice", voice_volume)

func _apply_volumes():
	"""Aplica volumes a todos os players"""
	if music_player:
		music_player.volume_db = linear_to_db(music_volume * master_volume)
	if music_player_fade:
		music_player_fade.volume_db = linear_to_db(music_volume * master_volume)
	
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume * master_volume)
	
	if voice_player:
		voice_player.volume_db = linear_to_db(voice_volume * master_volume)

# === UTILIDADES ===

func get_master_volume() -> float:
	"""Retorna volume master"""
	return master_volume

func get_music_volume() -> float:
	"""Retorna volume de música"""
	return music_volume

func get_sfx_volume() -> float:
	"""Retorna volume de SFX"""
	return sfx_volume

func get_voice_volume() -> float:
	"""Retorna volume de voz"""
	return voice_volume

func is_music_playing() -> bool:
	"""Verifica se música está tocando"""
	return music_player.playing

func get_current_music() -> String:
	"""Retorna música atual"""
	return current_music

