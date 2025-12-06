extends Node
class_name PerkSystem
## Sistema de gerenciamento de perks para personagens

signal perk_acquired(perk: PerkData, rank: int)
signal perk_removed(perk: PerkData)
signal perk_rank_increased(perk: PerkData, new_rank: int)

var all_perks: Dictionary = {}  # {Perk: PerkData}
var acquired_perks: Dictionary = {}  # {Perk: rank}
var current_critter: Critter = null

func _ready() -> void:
	# Carregar todas as definições de perks
	all_perks = PerkDefinitions.get_all_perks()

## Define o personagem atual para o qual os perks serão gerenciados
func set_current_critter(critter: Critter) -> void:
	current_critter = critter
	if critter:
		acquired_perks.clear()

## Retorna uma lista de perks disponíveis para o personagem atual
func get_available_perks(critter: Critter = null) -> Array[PerkData]:
	if critter == null:
		critter = current_critter
	
	if critter == null:
		return []
	
	var available: Array[PerkData] = []
	
	for perk_id in all_perks:
		var perk: PerkData = all_perks[perk_id]
		
		# Verificar se o personagem pode adquirir este perk
		if perk.can_acquire(critter):
			# Verificar se já tem o perk no máximo de ranks
			var current_rank = acquired_perks.get(perk_id, 0)
			if current_rank < perk.max_ranks:
				available.append(perk)
	
	return available

## Adquire um perk para o personagem atual
func acquire_perk(perk: PerkData, critter: Critter = null) -> bool:
	if perk == null:
		push_error("PerkSystem.acquire_perk: perk is null")
		return false
	
	if critter == null:
		critter = current_critter
	
	if critter == null:
		push_error("PerkSystem.acquire_perk: no critter set")
		return false
	
	# Verificar se o personagem pode adquirir este perk
	if not perk.can_acquire(critter):
		return false
	
	# Verificar se já tem o perk no máximo de ranks
	var current_rank = acquired_perks.get(perk.perk_id, 0)
	if current_rank >= perk.max_ranks:
		return false
	
	# Aumentar o rank do perk
	var new_rank = current_rank + 1
	acquired_perks[perk.perk_id] = new_rank
	
	# Aplicar os efeitos do perk
	perk.apply_effects(critter)
	
	# Emitir sinais
	if current_rank == 0:
		perk_acquired.emit(perk, new_rank)
	else:
		perk_rank_increased.emit(perk, new_rank)
	
	return true

## Remove um perk do personagem
func remove_perk(perk: PerkData, critter: Critter = null) -> bool:
	if perk == null:
		return false
	
	if critter == null:
		critter = current_critter
	
	if critter == null:
		return false
	
	# Verificar se o personagem tem este perk
	if perk.perk_id not in acquired_perks:
		return false
	
	# Remover os efeitos do perk
	perk.remove_effects(critter)
	
	# Remover o perk
	acquired_perks.erase(perk.perk_id)
	
	# Emitir sinal
	perk_removed.emit(perk)
	
	return true

## Verifica se o personagem tem um perk específico
func has_perk(perk_id: PerkData.Perk, critter: Critter = null) -> bool:
	if critter == null:
		critter = current_critter
	
	if critter == null:
		return false
	
	return perk_id in acquired_perks

## Retorna o rank de um perk para o personagem
func get_perk_rank(perk_id: PerkData.Perk, critter: Critter = null) -> int:
	if critter == null:
		critter = current_critter
	
	if critter == null:
		return 0
	
	return acquired_perks.get(perk_id, 0)

## Retorna o perk com o ID especificado
func get_perk(perk_id: PerkData.Perk) -> PerkData:
	return all_perks.get(perk_id, null)

## Retorna todos os perks adquiridos pelo personagem
func get_acquired_perks(critter: Critter = null) -> Array[PerkData]:
	if critter == null:
		critter = current_critter
	
	if critter == null:
		return []
	
	var acquired: Array[PerkData] = []
	
	for perk_id in acquired_perks:
		var perk = all_perks.get(perk_id, null)
		if perk:
			acquired.append(perk)
	
	return acquired

## Retorna o número total de perks adquiridos
func get_acquired_perk_count(critter: Critter = null) -> int:
	if critter == null:
		critter = current_critter
	
	if critter == null:
		return 0
	
	return acquired_perks.size()

## Limpa todos os perks adquiridos
func clear_acquired_perks(critter: Critter = null) -> void:
	if critter == null:
		critter = current_critter
	
	if critter == null:
		return
	
	# Remover todos os efeitos
	for perk_id in acquired_perks:
		var perk = all_perks.get(perk_id, null)
		if perk:
			perk.remove_effects(critter)
	
	acquired_perks.clear()

## Retorna informações sobre um perk
func get_perk_info(perk_id: PerkData.Perk) -> Dictionary:
	var perk = all_perks.get(perk_id, null)
	if not perk:
		return {}
	
	return {
		"id": perk_id,
		"name": perk.get_name(),
		"description": perk.get_description(),
		"max_ranks": perk.max_ranks,
		"level_requirement": perk.level_requirement,
		"stat_requirements": perk.stat_requirements,
		"skill_requirements": perk.skill_requirements,
		"effects": perk.effects
	}

## Retorna uma lista de todos os perks disponíveis no jogo
func get_all_perks_list() -> Array[PerkData]:
	var perks: Array[PerkData] = []
	
	for perk_id in all_perks:
		var perk = all_perks[perk_id]
		if perk:
			perks.append(perk)
	
	return perks

## Verifica se um personagem pode adquirir um perk específico
func can_acquire_perk(perk_id: PerkData.Perk, critter: Critter = null) -> bool:
	if critter == null:
		critter = current_critter
	
	if critter == null:
		return false
	
	var perk = all_perks.get(perk_id, null)
	if not perk:
		return false
	
	# Verificar se já tem o perk no máximo de ranks
	var current_rank = acquired_perks.get(perk_id, 0)
	if current_rank >= perk.max_ranks:
		return false
	
	return perk.can_acquire(critter)
