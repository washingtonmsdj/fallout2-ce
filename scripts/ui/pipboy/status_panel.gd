extends Control
class_name StatusPanel
## Painel de status do Pipboy - mostra SPECIAL, skills, perks e efeitos

var player: Critter = null

# Labels para exibição (serão configurados na cena ou criados dinamicamente)
var special_labels: Dictionary = {}
var derived_stats_labels: Dictionary = {}
var skills_container: VBoxContainer = null
var perks_container: VBoxContainer = null
var effects_container: VBoxContainer = null

func _ready() -> void:
	_setup_ui()

## Define o jogador
func set_player(player_critter: Critter) -> void:
	player = player_critter
	refresh()

## Atualiza o conteúdo do painel
func refresh() -> void:
	if not player:
		return
	
	_refresh_special_stats()
	_refresh_derived_stats()
	_refresh_skills()
	_refresh_perks()
	_refresh_effects()

## Atualiza os stats SPECIAL
func _refresh_special_stats() -> void:
	if not player or not player.stats:
		return
	
	var stats = player.stats
	
	# Atualizar labels de SPECIAL
	_update_label("strength", "Strength: %d" % stats.strength)
	_update_label("perception", "Perception: %d" % stats.perception)
	_update_label("endurance", "Endurance: %d" % stats.endurance)
	_update_label("charisma", "Charisma: %d" % stats.charisma)
	_update_label("intelligence", "Intelligence: %d" % stats.intelligence)
	_update_label("agility", "Agility: %d" % stats.agility)
	_update_label("luck", "Luck: %d" % stats.luck)

## Atualiza os stats derivados
func _refresh_derived_stats() -> void:
	if not player or not player.stats:
		return
	
	var stats = player.stats
	
	# Calcular stats derivados
	stats.calculate_derived_stats()
	
	_update_label("hit_points", "Hit Points: %d / %d" % [stats.current_hp, stats.max_hp])
	_update_label("action_points", "Action Points: %d" % stats.action_points)
	_update_label("armor_class", "Armor Class: %d" % stats.armor_class)
	_update_label("carry_weight", "Carry Weight: %.1f / %.1f" % [stats.current_carry_weight, stats.max_carry_weight])
	_update_label("melee_damage", "Melee Damage: %d" % stats.melee_damage)
	_update_label("damage_resistance", "Damage Resistance: %d%%" % stats.damage_resistance)
	_update_label("damage_threshold", "Damage Threshold: %d" % stats.damage_threshold)
	_update_label("sequence", "Sequence: %d" % stats.sequence)
	_update_label("healing_rate", "Healing Rate: %d" % stats.healing_rate)
	_update_label("critical_chance", "Critical Chance: %d%%" % stats.critical_chance)
	_update_label("radiation_resistance", "Radiation Resistance: %d%%" % stats.radiation_resistance)
	_update_label("poison_resistance", "Poison Resistance: %d%%" % stats.poison_resistance)

## Atualiza a lista de skills
func _refresh_skills() -> void:
	if not player or not player.skills:
		return
	
	if not skills_container:
		return
	
	# Limpar skills existentes
	for child in skills_container.get_children():
		child.queue_free()
	
	# Adicionar todas as skills
	for skill in SkillData.Skill.values():
		var skill_value = player.skills.get_skill_value(skill)
		var skill_name = SkillData.new().get_skill_name(skill)
		
		var label = Label.new()
		label.text = "%s: %d%%" % [skill_name, skill_value]
		skills_container.add_child(label)

## Atualiza a lista de perks
func _refresh_perks() -> void:
	if not player:
		return
	
	if not perks_container:
		return
	
	# Limpar perks existentes
	for child in perks_container.get_children():
		child.queue_free()
	
	# TODO: Adicionar perks quando sistema de perks estiver integrado
	# Por enquanto, apenas placeholder
	var label = Label.new()
	label.text = "Perks: (Sistema de perks em desenvolvimento)"
	perks_container.add_child(label)

## Atualiza a lista de efeitos ativos
func _refresh_effects() -> void:
	if not player:
		return
	
	if not effects_container:
		return
	
	# Limpar efeitos existentes
	for child in effects_container.get_children():
		child.queue_free()
	
	# TODO: Adicionar efeitos quando sistema de efeitos estiver integrado
	# Por enquanto, apenas placeholder
	var label = Label.new()
	label.text = "Active Effects: (Sistema de efeitos em desenvolvimento)"
	effects_container.add_child(label)

## Atualiza um label específico
func _update_label(key: String, text: String) -> void:
	if key in special_labels:
		special_labels[key].text = text
	elif key in derived_stats_labels:
		derived_stats_labels[key].text = text

## Configura a UI
func _setup_ui() -> void:
	# Se não há labels configurados, criar estrutura básica
	# Isso permite que funcione mesmo sem cena completa
	if special_labels.is_empty() and derived_stats_labels.is_empty():
		_create_basic_ui()

## Cria UI básica se não foi configurada na cena
func _create_basic_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.name = "ContentVBox"
	add_child(vbox)
	
	# Seção SPECIAL
	var special_label = Label.new()
	special_label.text = "SPECIAL"
	special_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(special_label)
	
	var special_vbox = VBoxContainer.new()
	vbox.add_child(special_vbox)
	
	for stat_name in ["strength", "perception", "endurance", "charisma", "intelligence", "agility", "luck"]:
		var label = Label.new()
		label.name = stat_name.capitalize() + "Label"
		special_labels[stat_name] = label
		special_vbox.add_child(label)
	
	# Seção Derived Stats
	var derived_label = Label.new()
	derived_label.text = "Derived Stats"
	derived_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(derived_label)
	
	var derived_vbox = VBoxContainer.new()
	vbox.add_child(derived_vbox)
	
	for stat_name in ["hit_points", "action_points", "armor_class", "carry_weight", "melee_damage", "damage_resistance", "damage_threshold", "sequence", "healing_rate", "critical_chance", "radiation_resistance", "poison_resistance"]:
		var label = Label.new()
		label.name = stat_name.capitalize() + "Label"
		derived_stats_labels[stat_name] = label
		derived_vbox.add_child(label)
	
	# Seção Skills
	var skills_label = Label.new()
	skills_label.text = "Skills"
	skills_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(skills_label)
	
	skills_container = VBoxContainer.new()
	vbox.add_child(skills_container)
	
	# Seção Perks
	var perks_label = Label.new()
	perks_label.text = "Perks"
	perks_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(perks_label)
	
	perks_container = VBoxContainer.new()
	vbox.add_child(perks_container)
	
	# Seção Effects
	var effects_label = Label.new()
	effects_label.text = "Active Effects"
	effects_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(effects_label)
	
	effects_container = VBoxContainer.new()
	vbox.add_child(effects_container)
