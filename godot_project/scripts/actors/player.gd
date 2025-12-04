extends CharacterBody2D

## Player do Fallout 2 - Controle de movimento e stats
## Usa AnimatedSprite2D com animações extraídas do jogo original

signal hp_changed(current: int, maximum: int)
signal ap_changed(current: int, maximum: int)
signal level_changed(new_level: int)
signal died()

# Movimento
@export var base_speed: float = 150.0
@export var run_speed_multiplier: float = 1.5

# Action Points (igual ao original)
@export var action_points: int = 10
@export var max_action_points: int = 10

# Estatisticas SPECIAL (igual ao original: 1-10)
@export_group("SPECIAL Stats")
@export_range(1, 10) var strength: int = 5
@export_range(1, 10) var perception: int = 5
@export_range(1, 10) var endurance: int = 5
@export_range(1, 10) var charisma: int = 5
@export_range(1, 10) var intelligence: int = 5
@export_range(1, 10) var agility: int = 5
@export_range(1, 10) var luck: int = 5

# Status
@export_group("Status")
@export var hp: int = 30
@export var max_hp: int = 30
@export var level: int = 1
@export var experience: int = 0

# Derivados (calculados a partir de SPECIAL)
var armor_class: int = 0
var melee_damage: int = 0
var carry_weight: int = 0
var sequence: int = 0
var healing_rate: int = 0
var critical_chance: int = 0

# Estado
var is_moving: bool = false
var is_running: bool = false
var current_direction: int = 2  # 0-5 para as 6 direcoes isometricas (começa SE)
var target_position: Vector2 = Vector2.ZERO
var move_to_target: bool = false

# Pathfinding
var current_path: Array[Vector2i] = []
var path_index: int = 0
var following_path: bool = false

# Nomes das direções para animações
const DIRECTION_NAMES: Array[String] = ["ne", "e", "se", "sw", "w", "nw"]

# Referencias
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# Estado da animação
var current_anim_state: String = "idle"

func _ready():
	add_to_group("player")
	_calculate_derived_stats()
	_setup_animations()
	print("Player: Inicializado - HP:", hp, "/", max_hp, " AP:", action_points)

func _setup_animations():
	"""Configura as animações do player"""
	if animated_sprite:
		# Começar com idle na direção SE
		_play_animation("idle")
		print("Player: Animações configuradas")

func _calculate_derived_stats():
	"""Calcula stats derivados baseado em SPECIAL (igual ao original)"""
	armor_class = agility
	melee_damage = max(1, strength - 5)
	carry_weight = 25 + (strength * 25)
	sequence = 2 * perception
	healing_rate = max(1, endurance / 3)
	critical_chance = luck
	
	if level == 1 and max_hp == 30:
		max_hp = 15 + strength + (2 * endurance)
		hp = max_hp
	
	max_action_points = 5 + (agility / 2)
	action_points = max_action_points

func _physics_process(delta):
	_handle_input()
	_handle_movement(delta)
	_update_animation()
	move_and_slide()

func _handle_input():
	"""Processa input do jogador"""
	var inventory = get_node_or_null("/root/InventorySystem")
	if inventory and inventory.is_encumbered():
		velocity = Vector2.ZERO
		is_moving = false
		return
	
	var input_dir = Vector2.ZERO
	
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	is_running = Input.is_key_pressed(KEY_SHIFT)
	
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()
		var speed = base_speed * (run_speed_multiplier if is_running else 1.0)
		velocity = input_dir * speed
		is_moving = true
		_update_direction(input_dir)
	else:
		velocity = Vector2.ZERO
		is_moving = false

func _handle_movement(_delta):
	"""Processa movimento para posicao alvo (click) ou seguindo caminho"""
	var inventory = get_node_or_null("/root/InventorySystem")
	if inventory and inventory.is_encumbered():
		velocity = Vector2.ZERO
		is_moving = false
		move_to_target = false
		following_path = false
		return
	
	if following_path and current_path.size() > 0:
		_follow_path()
	elif move_to_target:
		var dir = (target_position - global_position).normalized()
		var dist = global_position.distance_to(target_position)
		
		if dist < 5:
			move_to_target = false
			velocity = Vector2.ZERO
			is_moving = false
		else:
			var speed = base_speed * (run_speed_multiplier if is_running else 1.0)
			velocity = dir * speed
			is_moving = true
			_update_direction(dir)

func _follow_path():
	"""Segue o caminho calculado pelo pathfinding"""
	if path_index >= current_path.size():
		_stop_following_path()
		return
	
	var renderer = get_node_or_null("/root/IsometricRenderer")
	if renderer == null:
		_stop_following_path()
		return
	
	var next_tile = current_path[path_index]
	var next_world_pos = renderer.tile_to_screen(next_tile, 0)
	var dir = (next_world_pos - global_position).normalized()
	var dist = global_position.distance_to(next_world_pos)
	
	if dist < 10:
		path_index += 1
		var combat_system = get_node_or_null("/root/CombatSystem")
		if combat_system != null and combat_system.is_in_combat():
			if not use_action_points(1):
				_stop_following_path()
				return
	else:
		var speed = base_speed * (run_speed_multiplier if is_running else 1.0)
		velocity = dir * speed
		is_moving = true
		_update_direction(dir)

func _stop_following_path():
	"""Para de seguir o caminho"""
	following_path = false
	current_path.clear()
	path_index = 0
	velocity = Vector2.ZERO
	is_moving = false

func _update_animation():
	"""Atualiza a animação baseado no estado atual"""
	var new_state: String
	
	if is_moving:
		new_state = "run" if is_running else "walk"
	else:
		new_state = "idle"
	
	if new_state != current_anim_state:
		current_anim_state = new_state
		_play_animation(new_state)

func _play_animation(anim_name: String):
	"""Toca uma animação específica na direção atual"""
	if not animated_sprite or not animated_sprite.sprite_frames:
		return
	
	var dir_name = DIRECTION_NAMES[current_direction]
	var full_anim_name = "%s_%s" % [anim_name, dir_name]
	
	# Tentar tocar a animação com direção
	if animated_sprite.sprite_frames.has_animation(full_anim_name):
		animated_sprite.play(full_anim_name)
	# Fallback: tentar só o nome base
	elif animated_sprite.sprite_frames.has_animation(anim_name):
		animated_sprite.play(anim_name)
	# Fallback final: default
	elif animated_sprite.sprite_frames.has_animation("default"):
		animated_sprite.play("default")

func _update_direction(dir: Vector2):
	"""
	Atualiza direcao do sprite (6 direcoes isometricas)
	
	Mapeamento de direções do Fallout 2:
	- 0 = NE (nordeste) - diagonal cima-direita
	- 1 = E  (leste)    - direita
	- 2 = SE (sudeste)  - diagonal baixo-direita
	- 3 = SW (sudoeste) - diagonal baixo-esquerda
	- 4 = W  (oeste)    - esquerda
	- 5 = NW (noroeste) - diagonal cima-esquerda
	
	Ângulos em Godot (Y para baixo):
	- 0° = direita (+X)
	- 90° = baixo (+Y)
	- 180° = esquerda (-X)
	- 270° = cima (-Y)
	"""
	var angle = dir.angle()
	var deg = rad_to_deg(angle)
	
	# Normalizar para 0-360
	if deg < 0:
		deg += 360
	
	# Mapear ângulo para direção isométrica
	# Dividimos o círculo em 6 setores de 60° cada
	var new_direction: int
	
	# Direita pura (0°) = E
	# Baixo-direita (60°) = SE  
	# Baixo-esquerda (120°) = SW
	# Esquerda pura (180°) = W
	# Cima-esquerda (240°) = NW
	# Cima-direita (300°) = NE
	
	if deg >= 330 or deg < 30:
		new_direction = 1  # E (direita)
	elif deg >= 30 and deg < 90:
		new_direction = 2  # SE (baixo-direita)
	elif deg >= 90 and deg < 150:
		new_direction = 3  # SW (baixo-esquerda)
	elif deg >= 150 and deg < 210:
		new_direction = 4  # W (esquerda)
	elif deg >= 210 and deg < 270:
		new_direction = 5  # NW (cima-esquerda)
	else:  # 270-330
		new_direction = 0  # NE (cima-direita)
	
	if new_direction != current_direction:
		current_direction = new_direction
		# Atualizar animação para nova direção
		_play_animation(current_anim_state)

func move_to(pos: Vector2):
	"""Move o player para uma posicao especifica"""
	target_position = pos
	move_to_target = true

func move_to_tile(tile: Vector2i):
	"""Move o player para um tile específico usando pathfinding"""
	var pathfinder = get_node_or_null("/root/Pathfinder")
	var renderer = get_node_or_null("/root/IsometricRenderer")
	
	if pathfinder == null or renderer == null:
		var world_pos = renderer.tile_to_screen(tile, 0) if renderer else Vector2(tile)
		move_to(world_pos)
		return
	
	var current_tile = renderer.screen_to_tile(global_position, 0)
	var path = pathfinder.find_path(current_tile, tile, 0)
	
	if path.size() > 0:
		current_path = path
		path_index = 0
		following_path = true
		move_to_target = false

func stop_movement():
	"""Para o movimento"""
	move_to_target = false
	following_path = false
	current_path.clear()
	path_index = 0
	velocity = Vector2.ZERO
	is_moving = false

# === SISTEMA DE COMBATE ===

func use_action_points(amount: int) -> bool:
	if action_points >= amount:
		action_points -= amount
		ap_changed.emit(action_points, max_action_points)
		return true
	return false

func restore_action_points():
	action_points = max_action_points
	ap_changed.emit(action_points, max_action_points)

func take_damage(amount: int, _source: Node = null):
	var actual_damage = max(0, amount - (armor_class / 5))
	hp -= actual_damage
	hp_changed.emit(hp, max_hp)
	
	if hp <= 0:
		hp = 0
		_die()

func heal(amount: int):
	hp = min(hp + amount, max_hp)
	hp_changed.emit(hp, max_hp)

func play_attack_animation(attack_type: String = "unarmed"):
	"""Toca animação de ataque"""
	match attack_type:
		"unarmed":
			_play_animation("attack_unarmed")
		"melee":
			_play_animation("attack_melee")
		"ranged":
			_play_animation("attack_ranged")
		_:
			_play_animation("attack_unarmed")

func _die():
	print("Player: MORTO!")
	_play_animation("death_1")
	died.emit()

# === SISTEMA DE EXPERIENCIA ===

func add_experience(amount: int):
	experience += amount
	_check_level_up()

func _check_level_up():
	var xp_needed = _get_xp_for_level(level + 1)
	while experience >= xp_needed:
		level += 1
		_on_level_up()
		xp_needed = _get_xp_for_level(level + 1)

func _get_xp_for_level(lvl: int) -> int:
	return int((lvl * (lvl - 1) / 2.0) * 1000)

func _on_level_up():
	var hp_gain = 2 + (endurance / 2)
	max_hp += hp_gain
	hp = max_hp
	_calculate_derived_stats()
	level_changed.emit(level)
	hp_changed.emit(hp, max_hp)
	print("Player: Subiu para nivel ", level, "! HP:", max_hp)

func interact():
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = global_position
	query.collision_mask = 2
	
	var results = space.intersect_point(query, 5)
	for result in results:
		var obj = result.collider
		if obj.has_method("interact"):
			obj.interact(self)
			return
	
	print("Player: Nada para interagir aqui")
