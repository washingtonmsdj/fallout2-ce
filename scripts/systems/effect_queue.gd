extends Node
class_name EffectQueue
## Sistema de fila de efeitos temporários

signal effect_applied(effect: TimedEffect, target: Critter)
signal effect_expired(effect: TimedEffect, target: Critter)
signal effect_removed(effect: TimedEffect, target: Critter)
signal addiction_gained(target: Critter, drug_name: String, severity: int)

# Efeitos ativos por critter
var active_effects: Dictionary = {}  # {critter_id: Array[TimedEffect]}

# Vícios ativos
var addictions: Dictionary = {}  # {critter_id: {drug_name: severity}}

# Registro de critters para lookup
var critter_registry: Dictionary = {}  # {critter_id: Critter}

# Taxa de passagem de tempo (horas de jogo por segundo real)
var time_rate: float = 1.0 / 3600.0  # 1 hora de jogo = 1 segundo real

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	# Converter delta para horas de jogo
	var game_hours_passed = delta * time_rate
	
	# Atualizar todos os efeitos
	_tick_all_effects(game_hours_passed)

## Adiciona um efeito a um critter
func add_effect(target: Critter, effect: TimedEffect) -> void:
	if not target or not effect:
		return
	
	var target_id = _get_critter_id(target)
	
	if not target_id in active_effects:
		active_effects[target_id] = []
	
	# Verificar se efeito já existe (evitar duplicatas)
	for existing_effect in active_effects[target_id]:
		if existing_effect.id == effect.id:
			# Atualizar duração se for o mesmo efeito
			existing_effect.remaining_duration = max(existing_effect.remaining_duration, effect.remaining_duration)
			return
	
	# Aplicar efeito
	effect.apply_to(target)
	active_effects[target_id].append(effect)
	
	effect_applied.emit(effect, target)

## Remove um efeito de um critter
func remove_effect(target: Critter, effect: TimedEffect) -> void:
	if not target or not effect:
		return
	
	var target_id = _get_critter_id(target)
	
	if not target_id in active_effects:
		return
	
	# Remover efeito
	var index = active_effects[target_id].find(effect)
	if index != -1:
		effect.remove_from(target)
		active_effects[target_id].remove_at(index)
		effect_removed.emit(effect, target)
		
		# Limpar array se vazio
		if active_effects[target_id].is_empty():
			active_effects.erase(target_id)

## Atualiza todos os efeitos
func _tick_all_effects(time_passed: float) -> void:
	var effects_to_remove: Array[Dictionary] = []  # [{target_id, effect}]
	
	for target_id in active_effects:
		var target = _get_critter_by_id(target_id)
		if not target:
			continue
		
		for effect in active_effects[target_id]:
			if not effect:
				continue
			
			# Reduzir duração
			effect.tick(time_passed)
			
			# Aplicar efeitos de dano/cura por hora
			if effect.damage_per_hour > 0.0:
				var damage = int(effect.damage_per_hour * time_passed)
				if damage > 0 and target.stats:
					target.stats.take_damage(damage, GameConstants.DamageType.POISON)
			
			if effect.healing_per_hour > 0.0:
				var healing = int(effect.healing_per_hour * time_passed)
				if healing > 0 and target.stats:
					target.stats.heal(healing)
			
			# Verificar se expirou
			if effect.is_expired():
				effects_to_remove.append({"target_id": target_id, "effect": effect})
	
	# Remover efeitos expirados
	for item in effects_to_remove:
		var target = _get_critter_by_id(item.target_id)
		if target:
			remove_effect(target, item.effect)
			effect_expired.emit(item.effect, target)

## Aplica uma droga a um critter
func apply_drug(target: Critter, drug: TimedEffect) -> void:
	if not target or not drug:
		return
	
	# Adicionar efeito imediato da droga
	add_effect(target, drug)
	
	# Verificar vício (apenas se não for um efeito de vício)
	if not drug.is_addiction:
		check_addiction(target, drug.name)
	
	# Se já tem vício dessa droga, aplicar efeitos de abstinência
	var target_id = _get_critter_id(target)
	if target_id in addictions and drug.name in addictions[target_id]:
		_apply_withdrawal_effects(target, drug.name)

## Verifica se um critter pode ficar viciado
func check_addiction(target: Critter, drug_name: String) -> bool:
	if not target:
		return false
	
	var target_id = _get_critter_id(target)
	
	# Chance base de vício (simplificado)
	var addiction_chance = 0.1  # 10% base
	
	# Aumentar chance se já tem vício
	if target_id in addictions and drug_name in addictions[target_id]:
		addiction_chance = 0.5  # 50% se já viciado
	
	# Roll para vício
	if randf() < addiction_chance:
		# Criar efeito de vício
		var addiction_effect = TimedEffect.new()
		addiction_effect.id = "addiction_%s" % drug_name
		addiction_effect.name = "%s Addiction" % drug_name
		addiction_effect.is_addiction = true
		addiction_effect.duration = 999999.0  # Vício permanente até curado
		addiction_effect.addiction_severity = 50
		
		# Penalidades de vício
		addiction_effect.stat_modifiers = {
			"agility": -1,
			"intelligence": -1
		}
		
		# Adicionar vício
		if not target_id in addictions:
			addictions[target_id] = {}
		addictions[target_id][drug_name] = 50
		
		# Aplicar efeito
		add_effect(target, addiction_effect)
		
		addiction_gained.emit(target, drug_name, 50)
		return true
	
	return false

## Aplica efeitos de abstinência
func _apply_withdrawal_effects(target: Critter, drug_name: String) -> void:
	if not target:
		return
	
	var target_id = _get_critter_id(target)
	if not target_id in addictions or not drug_name in addictions[target_id]:
		return
	
	var severity = addictions[target_id][drug_name]
	
	# Criar efeito de abstinência
	var withdrawal_effect = TimedEffect.new()
	withdrawal_effect.id = "withdrawal_%s" % drug_name
	withdrawal_effect.name = "%s Withdrawal" % drug_name
	withdrawal_effect.duration = 24.0  # 24 horas
	withdrawal_effect.remaining_duration = 24.0
	
	# Penalidades de abstinência baseadas na severidade
	var penalty = int(severity / 10)
	withdrawal_effect.stat_modifiers = {
		"agility": -penalty,
		"intelligence": -penalty,
		"strength": -penalty / 2
	}
	withdrawal_effect.damage_per_hour = float(severity) / 10.0
	
	add_effect(target, withdrawal_effect)

## Verifica se um critter tem vício
func has_addiction(target: Critter, drug_name: String) -> bool:
	if not target:
		return false
	
	var target_id = _get_critter_id(target)
	if target_id in addictions:
		return drug_name in addictions[target_id]
	return false

## Cura um vício
func cure_addiction(target: Critter, drug_name: String) -> bool:
	if not target:
		return false
	
	var target_id = _get_critter_id(target)
	if not target_id in addictions or not drug_name in addictions[target_id]:
		return false
	
	# Remover efeito de vício
	var addiction_id = "addiction_%s" % drug_name
	var effects = active_effects.get(target_id, [])
	for effect in effects:
		if effect and effect.id == addiction_id:
			remove_effect(target, effect)
			break
	
	# Remover do registro
	addictions[target_id].erase(drug_name)
	if addictions[target_id].is_empty():
		addictions.erase(target_id)
	
	return true

## Obtém modificador total de um stat considerando todos os efeitos
func get_total_stat_modifier(target: Critter, stat: GameConstants.PrimaryStat) -> int:
	if not target:
		return 0
	
	var target_id = _get_critter_id(target)
	if not target_id in active_effects:
		return 0
	
	var total_modifier = 0
	var stat_name = _get_stat_name(stat)
	
	for effect in active_effects[target_id]:
		if effect:
			total_modifier += effect.get_stat_modifier(stat_name)
	
	return total_modifier

## Obtém modificador total de uma skill considerando todos os efeitos
func get_total_skill_modifier(target: Critter, skill: SkillData.Skill) -> int:
	if not target:
		return 0
	
	var target_id = _get_critter_id(target)
	if not target_id in active_effects:
		return 0
	
	var total_modifier = 0
	var skill_name = _get_skill_name(skill)
	
	for effect in active_effects[target_id]:
		if effect:
			total_modifier += effect.get_skill_modifier(skill_name)
	
	return total_modifier

## Obtém todos os efeitos ativos de um critter
func get_active_effects(target: Critter) -> Array[TimedEffect]:
	if not target:
		return []
	
	var target_id = _get_critter_id(target)
	if target_id in active_effects:
		return active_effects[target_id].duplicate()
	return []

## Obtém todos os vícios de um critter
func get_addictions(target: Critter) -> Dictionary:
	if not target:
		return {}
	
	var target_id = _get_critter_id(target)
	if target_id in addictions:
		return addictions[target_id].duplicate()
	return {}

## Aplica efeito de membro aleijado
func apply_crippled_limb(target: Critter, limb_name: String, severity: int) -> void:
	if not target:
		return
	
	var effect = TimedEffect.new()
	effect.id = "crippled_%s" % limb_name
	effect.name = "Crippled %s" % limb_name.capitalize()
	effect.duration = 999999.0  # Permanente até curado
	effect.crippled_limbs[limb_name] = severity
	
	add_effect(target, effect)

## Cura membro aleijado
func cure_crippled_limb(target: Critter, limb_name: String) -> bool:
	if not target:
		return false
	
	var target_id = _get_critter_id(target)
	if not target_id in active_effects:
		return false
	
	var effect_id = "crippled_%s" % limb_name
	for effect in active_effects[target_id]:
		if effect and effect.id == effect_id:
			remove_effect(target, effect)
			return true
	
	return false

## Helper para obter ID único de um critter
func _get_critter_id(critter: Critter) -> String:
	if not critter:
		return ""
	return critter.critter_name + "_" + str(critter.get_instance_id())

## Helper para obter critter por ID
func _get_critter_by_id(target_id: String) -> Critter:
	if target_id in critter_registry:
		return critter_registry[target_id]
	return null

## Remove critter do registro (chamar quando critter for destruído)
func unregister_critter(target: Critter) -> void:
	if not target:
		return
	
	var target_id = _get_critter_id(target)
	
	# Remover todos os efeitos
	if target_id in active_effects:
		for effect in active_effects[target_id]:
			if effect:
				effect.remove_from(target)
		active_effects.erase(target_id)
	
	# Remover vícios
	if target_id in addictions:
		addictions.erase(target_id)
	
	# Remover do registro
	if target_id in critter_registry:
		critter_registry.erase(target_id)

## Helper para obter nome de stat
func _get_stat_name(stat: GameConstants.PrimaryStat) -> String:
	var stat_names = {
		GameConstants.PrimaryStat.STRENGTH: "strength",
		GameConstants.PrimaryStat.PERCEPTION: "perception",
		GameConstants.PrimaryStat.ENDURANCE: "endurance",
		GameConstants.PrimaryStat.CHARISMA: "charisma",
		GameConstants.PrimaryStat.INTELLIGENCE: "intelligence",
		GameConstants.PrimaryStat.AGILITY: "agility",
		GameConstants.PrimaryStat.LUCK: "luck"
	}
	return stat_names.get(stat, "")

## Helper para obter nome de skill
func _get_skill_name(skill: SkillData.Skill) -> String:
	var skill_data = SkillData.new()
	return skill_data.get_skill_name(skill).to_lower().replace(" ", "_")
