extends CharacterBody2D

## Player do Fallout 2 - Controle de movimento e stats
## Fiel ao comportamento do jogo original

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
var current_direction: int = 0  # 0-5 para as 6 direcoes isometricas
var target_position: Vector2 = Vector2.ZERO
var move_to_target: bool = false

# Animacao de caminhada (bobbing)
var walk_time: float = 0.0
var walk_bob_amount: float = 3.0  # Pixels de movimento vertical
var walk_bob_speed: float = 12.0  # Velocidade do bob
var sprite_base_offset: Vector2 = Vector2(0, -30)

# Referencias
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# Texturas das 6 direcoes
var direction_textures: Array[Texture2D] = []
var texture_paths: Array[String] = [
	"res://assets/sprites/player/player_ne.png",  # 0 = NE
	"res://assets/sprites/player/player_e.png",   # 1 = E
	"res://assets/sprites/player/player_se.png",  # 2 = SE
	"res://assets/sprites/player/player_sw.png",  # 3 = SW
	"res://assets/sprites/player/player_w.png",   # 4 = W
	"res://assets/sprites/player/player_nw.png"   # 5 = NW
]

func _ready():
	add_to_group("player")
	_load_direction_textures()
	_calculate_derived_stats()
	
	# Guardar offset base do sprite
	if sprite:
		sprite_base_offset = sprite.offset
	
	print("Player: Inicializado - HP:", hp, "/", max_hp, " AP:", action_points)

func _load_direction_textures():
	"""Carrega as texturas das 6 direcoes"""
	direction_textures.clear()
	for path in texture_paths:
		var tex = load(path)
		if tex:
			direction_textures.append(tex)
		else:
			print("Player: AVISO - Textura nao encontrada: ", path)
			direction_textures.append(null)
	print("Player: ", direction_textures.size(), " texturas direcionais carregadas")

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
	_update_walk_animation(delta)
	move_and_slide()

func _handle_input():
	"""Processa input do jogador"""
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
	"""Processa movimento para posicao alvo (click)"""
	if move_to_target:
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

func _update_walk_animation(delta):
	"""Atualiza animacao de caminhada (bobbing)"""
	if not sprite:
		return
	
	if is_moving:
		# Incrementar tempo de caminhada
		var speed_mult = walk_bob_speed * (1.5 if is_running else 1.0)
		walk_time += delta * speed_mult
		
		# Calcular bob vertical (simula pernas se movendo)
		var bob_y = abs(sin(walk_time)) * walk_bob_amount
		
		# Pequeno movimento horizontal para simular balanco
		var bob_x = sin(walk_time * 0.5) * (walk_bob_amount * 0.3)
		
		sprite.offset = sprite_base_offset + Vector2(bob_x, -bob_y)
	else:
		# Voltar suavemente para posicao original
		walk_time = 0.0
		sprite.offset = sprite.offset.lerp(sprite_base_offset, 0.2)

func _update_direction(dir: Vector2):
	"""Atualiza direcao do sprite (6 direcoes isometricas)"""
	var angle = dir.angle()
	var deg = rad_to_deg(angle)
	
	if deg < 0:
		deg += 360
	
	var new_direction: int
	if deg >= 330 or deg < 30:
		new_direction = 1  # E
	elif deg >= 30 and deg < 90:
		new_direction = 2  # SE
	elif deg >= 90 and deg < 150:
		new_direction = 3  # SW
	elif deg >= 150 and deg < 210:
		new_direction = 4  # W
	elif deg >= 210 and deg < 270:
		new_direction = 5  # NW
	else:
		new_direction = 0  # NE
	
	if new_direction != current_direction:
		current_direction = new_direction
		_set_sprite_direction(current_direction)

func _set_sprite_direction(dir_index: int):
	"""Troca a textura do sprite para a direcao especificada"""
	if sprite and dir_index >= 0 and dir_index < direction_textures.size():
		var tex = direction_textures[dir_index]
		if tex:
			sprite.texture = tex

func move_to(pos: Vector2):
	"""Move o player para uma posicao especifica"""
	target_position = pos
	move_to_target = true

func stop_movement():
	"""Para o movimento"""
	move_to_target = false
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

func _die():
	print("Player: MORTO!")
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

# === INTERACAO ===

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
