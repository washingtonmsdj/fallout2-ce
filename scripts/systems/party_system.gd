extends Node
class_name PartySystem
## Sistema de gerenciamento de party e companheiros

signal companion_joined(companion: Critter)
signal companion_left(companion: Critter)
signal companion_died(companion: Critter)
signal companion_unconscious(companion: Critter)

const MAX_PARTY_SIZE := 5  # Máximo de companheiros (não incluindo o jogador)

var party_members: Array[Critter] = []
var player: Critter = null

# Configurações de comportamento dos companheiros
var companion_behaviors: Dictionary = {}  # {companion_id: behavior_settings}

# Histórico de companheiros (para quests e diálogos)
var former_companions: Array[Critter] = []

func _ready() -> void:
	pass

## Define o jogador
func set_player(player_critter: Critter) -> void:
	if not player_critter:
		push_error("PartySystem: Cannot set null player")
		return
	
	player = player_critter
	player.is_player = true

## Adiciona um companheiro ao party
func add_companion(companion: Critter) -> bool:
	if not companion:
		push_error("PartySystem: Cannot add null companion")
		return false
	
	if is_party_full():
		push_warning("PartySystem: Party is full, cannot add companion")
		return false
	
	if companion in party_members:
		push_warning("PartySystem: Companion already in party")
		return false
	
	if companion == player:
		push_error("PartySystem: Cannot add player as companion")
		return false
	
	# Adicionar ao party
	party_members.append(companion)
	
	# Inicializar companheiro
	_initialize_companion(companion)
	
	companion_joined.emit(companion)
	return true

## Remove um companheiro do party
func remove_companion(companion: Critter) -> void:
	if not companion:
		return
	
	if not companion in party_members:
		push_warning("PartySystem: Companion not in party")
		return
	
	# Remover do party
	party_members.erase(companion)
	
	# Limpar configurações
	if companion.critter_name in companion_behaviors:
		companion_behaviors.erase(companion.critter_name)
	
	# Adicionar ao histórico
	former_companions.append(companion)
	
	companion_left.emit(companion)

## Verifica se o party está cheio
func is_party_full() -> bool:
	return party_members.size() >= MAX_PARTY_SIZE

## Obtém todos os membros do party para combate (incluindo jogador)
func get_party_for_combat() -> Array[Critter]:
	var combat_party: Array[Critter] = []
	
	# Adicionar jogador primeiro
	if player and player.stats and player.stats.is_alive():
		combat_party.append(player)
	
	# Adicionar companheiros vivos
	for companion in party_members:
		if companion and companion.stats and companion.stats.is_alive():
			combat_party.append(companion)
	
	# Ordenar por Sequence (maior primeiro)
	combat_party.sort_custom(func(a: Critter, b: Critter) -> bool:
		if not a.stats or not b.stats:
			return false
		return a.stats.sequence > b.stats.sequence
	)
	
	return combat_party

## Cura todos os membros do party
func heal_party(amount: int) -> void:
	if player and player.stats:
		player.stats.heal(amount)
	
	for companion in party_members:
		if companion and companion.stats:
			companion.stats.heal(amount)

## Obtém um companheiro pelo nome
func get_companion(name: String) -> Critter:
	for companion in party_members:
		if companion and companion.critter_name == name:
			return companion
	return null

## Verifica se um critter é membro do party
func is_party_member(critter: Critter) -> bool:
	if critter == player:
		return true
	return critter in party_members

## Obtém o tamanho total do party (jogador + companheiros)
func get_party_size() -> int:
	var size = 0
	if player:
		size += 1
	size += party_members.size()
	return size

## Inicializa um companheiro
func _initialize_companion(companion: Critter) -> void:
	if not companion:
		return
	
	# Garantir que não é o jogador
	companion.is_player = false
	
	# Inicializar stats se necessário
	if not companion.stats:
		companion.stats = StatData.new()
	if not companion.skills:
		companion.skills = SkillData.new()
	
	# Configurar comportamento padrão
	if not companion.critter_name in companion_behaviors:
		companion_behaviors[companion.critter_name] = {
			"aggressive": false,
			"use_items": true,
			"flee_when_low_hp": true,
			"low_hp_threshold": 0.25
		}
	
	# Conectar sinais
	if not companion.health_changed.is_connected(_on_companion_health_changed):
		companion.health_changed.connect(_on_companion_health_changed)
	if not companion.died.is_connected(_on_companion_died):
		companion.died.connect(_on_companion_died)

## Handler para mudança de HP de companheiro
func _on_companion_health_changed(old_value: int, new_value: int) -> void:
	# Verificar se companheiro ficou inconsciente
	for companion in party_members:
		if companion and companion.stats:
			if companion.stats.current_hp <= 0 and companion.stats.current_hp > -companion.stats.max_hp:
				# Inconsciente (não morto)
				companion_unconscious.emit(companion)

## Handler para morte de companheiro
func _on_companion_died() -> void:
	# Encontrar qual companheiro morreu
	for companion in party_members:
		if companion and companion.stats and not companion.stats.is_alive():
			companion_died.emit(companion)
			# Não remover do party automaticamente (pode ser revivido)

## Define comportamento de um companheiro
func set_companion_behavior(companion: Critter, behavior_settings: Dictionary) -> void:
	if not companion or not companion in party_members:
		return
	
	if not companion.critter_name in companion_behaviors:
		companion_behaviors[companion.critter_name] = {}
	
	companion_behaviors[companion.critter_name].merge(behavior_settings)

## Obtém comportamento de um companheiro
func get_companion_behavior(companion: Critter) -> Dictionary:
	if not companion or not companion in party_members:
		return {}
	
	if companion.critter_name in companion_behaviors:
		return companion_behaviors[companion.critter_name].duplicate()
	
	return {}

## Obtém todos os companheiros vivos
func get_living_companions() -> Array[Critter]:
	var living: Array[Critter] = []
	for companion in party_members:
		if companion and companion.stats and companion.stats.is_alive():
			living.append(companion)
	return living

## Obtém todos os companheiros inconscientes
func get_unconscious_companions() -> Array[Critter]:
	var unconscious: Array[Critter] = []
	for companion in party_members:
		if companion and companion.stats:
			if companion.stats.current_hp <= 0 and companion.stats.current_hp > -companion.stats.max_hp:
				unconscious.append(companion)
	return unconscious

## Obtém todos os companheiros mortos
func get_dead_companions() -> Array[Critter]:
	var dead: Array[Critter] = []
	for companion in party_members:
		if companion and companion.stats and companion.stats.current_hp <= -companion.stats.max_hp:
			dead.append(companion)
	return dead

## Limpa o party (remove todos os companheiros)
func clear_party() -> void:
	for companion in party_members.duplicate():
		remove_companion(companion)

## Obtém estatísticas do party
func get_party_stats() -> Dictionary:
	var stats = {
		"total_members": get_party_size(),
		"companions": party_members.size(),
		"living": get_living_companions().size(),
		"unconscious": get_unconscious_companions().size(),
		"dead": get_dead_companions().size()
	}
	return stats
