extends Node
class_name AnimationController

## Controlador de Animações para personagens do Fallout 2
## Gerencia estados de animação e direções (6 direções isométricas)

signal animation_finished(anim_name: String)
signal frame_changed(frame: int)

enum AnimationState {
	IDLE,
	WALK,
	RUN,
	ATTACK_UNARMED,
	ATTACK_MELEE,
	ATTACK_RANGED,
	DODGE,
	HIT,
	DEATH
}

# Mapeamento de estado para nome de animação
const STATE_NAMES: Dictionary = {
	AnimationState.IDLE: "idle",
	AnimationState.WALK: "walk",
	AnimationState.RUN: "run",
	AnimationState.ATTACK_UNARMED: "attack_unarmed",
	AnimationState.ATTACK_MELEE: "attack_melee",
	AnimationState.ATTACK_RANGED: "attack_ranged",
	AnimationState.DODGE: "dodge",
	AnimationState.HIT: "hit",
	AnimationState.DEATH: "death"
}

# Nomes das direções
const DIRECTION_NAMES: Array[String] = ["ne", "e", "se", "sw", "w", "nw"]

# Estado atual
var current_state: AnimationState = AnimationState.IDLE
var current_direction: int = 2  # SE por padrão
var is_playing: bool = false

# Referência ao AnimatedSprite2D (se existir) ou Sprite2D
var animated_sprite: AnimatedSprite2D = null
var static_sprite: Sprite2D = null

# Texturas estáticas por direção (fallback quando não há animação)
var direction_textures: Dictionary = {}  # {direction_index: Texture2D}

# SpriteFrames carregados por estado
var sprite_frames_by_state: Dictionary = {}  # {AnimationState: SpriteFrames}

# Configuração
@export var default_fps: float = 10.0
@export var auto_play: bool = true

func _ready():
	# Procurar sprite no parent
	var parent = get_parent()
	if parent:
		animated_sprite = parent.get_node_or_null("AnimatedSprite2D")
		static_sprite = parent.get_node_or_null("Sprite2D")
		
		if animated_sprite:
			animated_sprite.animation_finished.connect(_on_animation_finished)
			animated_sprite.frame_changed.connect(_on_frame_changed)

func _on_animation_finished():
	animation_finished.emit(get_current_animation_name())
	
	# Voltar para idle após animações de ataque/hit
	if current_state in [AnimationState.ATTACK_UNARMED, AnimationState.ATTACK_MELEE, 
						  AnimationState.ATTACK_RANGED, AnimationState.DODGE, AnimationState.HIT]:
		set_state(AnimationState.IDLE)

func _on_frame_changed():
	if animated_sprite:
		frame_changed.emit(animated_sprite.frame)

func get_current_animation_name() -> String:
	var state_name = STATE_NAMES.get(current_state, "idle")
	var dir_name = DIRECTION_NAMES[current_direction] if current_direction < DIRECTION_NAMES.size() else "se"
	return "%s_%s" % [state_name, dir_name]

func set_state(new_state: AnimationState):
	"""Define o estado de animação"""
	if new_state == current_state:
		return
	
	current_state = new_state
	_update_animation()

func set_direction(direction_index: int):
	"""Define a direção (0-5 para as 6 direções isométricas)"""
	direction_index = clampi(direction_index, 0, 5)
	if direction_index == current_direction:
		return
	
	current_direction = direction_index
	_update_animation()

func _update_animation():
	"""Atualiza a animação baseado no estado e direção atuais"""
	var anim_name = get_current_animation_name()
	
	# Tentar usar AnimatedSprite2D primeiro
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)
			is_playing = true
			return
		
		# Fallback: tentar só o estado (sem direção)
		var state_name = STATE_NAMES.get(current_state, "idle")
		if animated_sprite.sprite_frames.has_animation(state_name):
			animated_sprite.play(state_name)
			is_playing = true
			return
	
	# Fallback: usar textura estática
	_update_static_sprite()

func _update_static_sprite():
	"""Atualiza sprite estático quando não há animação"""
	if static_sprite and direction_textures.has(current_direction):
		static_sprite.texture = direction_textures[current_direction]

func load_direction_textures(textures: Array[Texture2D]):
	"""Carrega texturas estáticas para cada direção"""
	direction_textures.clear()
	for i in range(min(textures.size(), 6)):
		if textures[i]:
			direction_textures[i] = textures[i]

func load_spritesheets_for_state(_state: AnimationState, _paths: Array[String]):
	"""Carrega spritesheets para um estado específico (placeholder)"""
	# TODO: Implementar carregamento de SpriteFrames quando os assets forem extraídos
	pass

func sync_with_movement(is_moving: bool, move_direction: Vector2):
	"""Sincroniza animação com movimento do personagem"""
	if is_moving:
		# Determinar se está correndo baseado na velocidade
		var is_running = move_direction.length() > 1.0
		set_state(AnimationState.RUN if is_running else AnimationState.WALK)
	else:
		set_state(AnimationState.IDLE)

func play_attack(attack_type: String = "unarmed"):
	"""Reproduz animação de ataque"""
	match attack_type:
		"unarmed":
			set_state(AnimationState.ATTACK_UNARMED)
		"melee":
			set_state(AnimationState.ATTACK_MELEE)
		"ranged":
			set_state(AnimationState.ATTACK_RANGED)
		_:
			set_state(AnimationState.ATTACK_UNARMED)

func play_hit():
	"""Reproduz animação de ser atingido"""
	set_state(AnimationState.HIT)

func play_dodge():
	"""Reproduz animação de esquiva"""
	set_state(AnimationState.DODGE)

func set_death():
	"""Define estado de morte (não volta para idle)"""
	current_state = AnimationState.DEATH
	_update_animation()

func stop():
	"""Para a animação atual"""
	if animated_sprite:
		animated_sprite.stop()
	is_playing = false

func is_animation_playing() -> bool:
	"""Verifica se uma animação está tocando"""
	if animated_sprite:
		return animated_sprite.is_playing()
	return false
