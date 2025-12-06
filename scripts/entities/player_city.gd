## Player para o mapa da cidade isométrica
## Integra o sistema Critter do Fallout com movimento isométrico
class_name PlayerCity
extends Node2D

signal moved(new_grid_pos: Vector2i)
signal interacted(target: Dictionary)

## Referência ao Critter (dados do personagem)
var critter: Critter

## Posição no grid
var grid_position: Vector2i = Vector2i(25, 25)

## Configurações de movimento
@export var move_speed: float = 150.0
@export var tile_width: float = 64.0
@export var tile_height: float = 32.0

## Estado
var is_moving: bool = false
var target_position: Vector2 = Vector2.ZERO
var input_buffer: Vector2i = Vector2i.ZERO

## Referência à simulação da cidade (para verificar estradas)
var city_simulation: CitySimulation

func _ready():
	# Criar Critter com stats do Fallout
	critter = Critter.new()
	critter.critter_name = "Vault Dweller"
	critter.is_player = true
	critter.faction = "player"
	
	# Configurar stats SPECIAL
	critter.stats = StatData.new()
	critter.stats.strength = 6
	critter.stats.perception = 7
	critter.stats.endurance = 6
	critter.stats.charisma = 5
	critter.stats.intelligence = 7
	critter.stats.agility = 8
	critter.stats.luck = 6
	critter.stats.calculate_derived_stats()
	
	# Configurar skills
	critter.skills = SkillData.new()
	critter.skills.tag_skill(SkillData.Skill.SMALL_GUNS)
	critter.skills.tag_skill(SkillData.Skill.LOCKPICK)
	critter.skills.tag_skill(SkillData.Skill.SPEECH)
	
	add_child(critter)
	
	# Posição inicial
	_update_visual_position()

func _process(delta):
	_update_input()
	_process_movement(delta)

func _update_input():
	# Captura direção atual do input
	input_buffer = Vector2i.ZERO
	
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_buffer = Vector2i(0, -1)
	elif Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_buffer = Vector2i(0, 1)
	elif Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_buffer = Vector2i(-1, 0)
	elif Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_buffer = Vector2i(1, 0)

func _try_move(direction: Vector2i) -> bool:
	var new_pos = grid_position + direction
	
	# Verificar limites do mapa
	if new_pos.x < 0 or new_pos.x >= 50 or new_pos.y < 0 or new_pos.y >= 50:
		return false
	
	# Verificar se a nova posição é uma estrada
	if not _is_road(new_pos):
		return false
	
	# Iniciar movimento
	grid_position = new_pos
	target_position = grid_to_iso(Vector2(grid_position))
	is_moving = true
	moved.emit(grid_position)
	return true

## Verifica se a posição é uma estrada
func _is_road(pos: Vector2i) -> bool:
	if not city_simulation:
		return true  # Se não tiver referência, permite movimento
	return pos in city_simulation.roads

## Encontra a estrada mais próxima para spawn inicial
func find_nearest_road() -> Vector2i:
	if not city_simulation or city_simulation.roads.is_empty():
		return Vector2i(25, 25)
	
	# Procurar estrada mais próxima do centro
	var center = Vector2i(25, 25)
	var nearest = city_simulation.roads[0]
	var min_dist = float(center.distance_squared_to(nearest))
	
	for road in city_simulation.roads:
		var dist = float(center.distance_squared_to(road))
		if dist < min_dist:
			min_dist = dist
			nearest = road
	
	return nearest

## Teleporta o player para uma estrada
func spawn_on_road():
	if city_simulation and not city_simulation.roads.is_empty():
		grid_position = find_nearest_road()
		_update_visual_position()
		print("Player spawned at road: ", grid_position)

func _process_movement(delta):
	# Se não está movendo, tenta iniciar movimento com input atual
	if not is_moving:
		if input_buffer != Vector2i.ZERO:
			_try_move(input_buffer)
		return
	
	# Movimento linear constante
	var move_step = move_speed * delta
	var remaining = position.distance_to(target_position)
	
	if remaining <= move_step:
		# Chegou no destino - usa o movimento restante para continuar
		var leftover = move_step - remaining
		position = target_position
		is_moving = false
		
		# Continuar imediatamente se ainda há input pressionado
		if input_buffer != Vector2i.ZERO and _try_move(input_buffer):
			# Aplica o movimento restante do frame
			if leftover > 0:
				var direction = (target_position - position).normalized()
				position += direction * leftover
	else:
		# Mover em direção ao alvo
		var direction = (target_position - position).normalized()
		position += direction * move_step

func _update_visual_position():
	position = grid_to_iso(Vector2(grid_position))
	target_position = position

## Converte coordenadas do grid para isométrico
func grid_to_iso(grid_pos: Vector2) -> Vector2:
	var iso_x = (grid_pos.x - grid_pos.y) * (tile_width / 2.0)
	var iso_y = (grid_pos.x + grid_pos.y) * (tile_height / 2.0)
	return Vector2(iso_x, iso_y)

## Converte coordenadas isométricas para grid
func iso_to_grid(iso_pos: Vector2) -> Vector2:
	var grid_x = (iso_pos.x / (tile_width / 2.0) + iso_pos.y / (tile_height / 2.0)) / 2.0
	var grid_y = (iso_pos.y / (tile_height / 2.0) - iso_pos.x / (tile_width / 2.0)) / 2.0
	return Vector2(grid_x, grid_y)

func _draw():
	# Sombra
	_draw_ellipse(Vector2(0, 4), Vector2(12, 6), Color(0, 0, 0, 0.4))
	
	# Corpo (vault suit azul)
	_draw_ellipse(Vector2(0, -8), Vector2(8, 14), Color(0.2, 0.3, 0.7))
	
	# Cabeça
	draw_circle(Vector2(0, -26), 8, Color(0.9, 0.75, 0.6))
	
	# Cabelo
	draw_circle(Vector2(0, -32), 6, Color(0.3, 0.2, 0.1))
	
	# Olhos
	draw_circle(Vector2(-3, -26), 1.5, Color.WHITE)
	draw_circle(Vector2(3, -26), 1.5, Color.WHITE)
	draw_circle(Vector2(-3, -26), 0.8, Color.BLACK)
	draw_circle(Vector2(3, -26), 0.8, Color.BLACK)
	
	# Número do Vault no peito
	draw_string(ThemeDB.fallback_font, Vector2(-6, -4), "13", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color.YELLOW)

func _draw_ellipse(center: Vector2, size: Vector2, color: Color):
	var points = PackedVector2Array()
	for i in range(16):
		var angle = i * TAU / 16
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)

## API para interação com o mundo

func get_stats() -> Dictionary:
	return {
		"name": critter.critter_name,
		"level": critter.level,
		"hp": critter.stats.current_hp,
		"max_hp": critter.stats.max_hp,
		"ap": critter.stats.current_ap,
		"max_ap": critter.stats.max_ap,
		"xp": critter.experience,
		"caps": 100,  # TODO: implementar inventário de caps
		"karma": critter.karma
	}

func get_special() -> Dictionary:
	return {
		"S": critter.stats.strength,
		"P": critter.stats.perception,
		"E": critter.stats.endurance,
		"C": critter.stats.charisma,
		"I": critter.stats.intelligence,
		"A": critter.stats.agility,
		"L": critter.stats.luck
	}
