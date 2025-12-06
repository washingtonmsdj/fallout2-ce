extends Control
class_name CharacterEditor
## Editor de criação de personagem

signal character_created(critter: Critter)

const TOTAL_SPECIAL_POINTS := 40
const MIN_STAT := 1
const MAX_STAT := 10
const MAX_TRAITS := 2
const TAGGED_SKILLS_COUNT := 3

var special_points_remaining: int = TOTAL_SPECIAL_POINTS
var selected_traits: Array[TraitData.Trait] = []
var tagged_skills: Array[SkillData.Skill] = []
var character_name: String = ""

# Stats temporários durante criação
var temp_stats: StatData = null
var temp_skills: SkillData = null
var temp_traits: TraitData = null

# UI Elements (serão configurados na cena ou criados dinamicamente)
var name_input: LineEdit = null
var special_controls: Dictionary = {}  # {stat: {label, decrease_btn, increase_btn, value_label}}
var points_label: Label = null
var traits_container: VBoxContainer = null
var skills_container: VBoxContainer = null
var finalize_button: Button = null

func _ready() -> void:
	_initialize_temp_data()
	_setup_ui()

## Inicializa dados temporários
func _initialize_temp_data() -> void:
	temp_stats = StatData.new()
	# Iniciar todos os stats em 5 (padrão)
	# 7 stats * 5 = 35 pontos usados, 40 - 35 = 5 pontos restantes
	temp_stats.strength = 5
	temp_stats.perception = 5
	temp_stats.endurance = 5
	temp_stats.charisma = 5
	temp_stats.intelligence = 5
	temp_stats.agility = 5
	temp_stats.luck = 5
	
	temp_skills = SkillData.new()
	temp_traits = TraitData.new()
	
	# Calcular pontos usados inicialmente
	special_points_remaining = TOTAL_SPECIAL_POINTS
	_update_points_used()

## Aloca um ponto de stat
func allocate_stat(stat: GameConstants.PrimaryStat, delta: int) -> bool:
	if not temp_stats:
		return false
	
	var current_value = _get_stat_value(stat)
	var new_value = current_value + delta
	
	# Verificar limites
	if new_value < MIN_STAT or new_value > MAX_STAT:
		return false
	
	# Verificar pontos disponíveis
	if delta > 0 and special_points_remaining < delta:
		return false
	
	# Verificar se pode diminuir (deve ter pelo menos MIN_STAT)
	if delta < 0 and current_value <= MIN_STAT:
		return false
	
	# Aplicar mudança
	_set_stat_value(stat, new_value)
	special_points_remaining -= delta
	
	# Atualizar UI
	_update_stat_display(stat)
	_update_points_label()
	
	return true

## Obtém valor de um stat
func _get_stat_value(stat: GameConstants.PrimaryStat) -> int:
	if not temp_stats:
		return 0
	
	match stat:
		GameConstants.PrimaryStat.STRENGTH:
			return temp_stats.strength
		GameConstants.PrimaryStat.PERCEPTION:
			return temp_stats.perception
		GameConstants.PrimaryStat.ENDURANCE:
			return temp_stats.endurance
		GameConstants.PrimaryStat.CHARISMA:
			return temp_stats.charisma
		GameConstants.PrimaryStat.INTELLIGENCE:
			return temp_stats.intelligence
		GameConstants.PrimaryStat.AGILITY:
			return temp_stats.agility
		GameConstants.PrimaryStat.LUCK:
			return temp_stats.luck
		_:
			return 0

## Define valor de um stat
func _set_stat_value(stat: GameConstants.PrimaryStat, value: int) -> void:
	if not temp_stats:
		return
	
	value = clamp(value, MIN_STAT, MAX_STAT)
	
	match stat:
		GameConstants.PrimaryStat.STRENGTH:
			temp_stats.strength = value
		GameConstants.PrimaryStat.PERCEPTION:
			temp_stats.perception = value
		GameConstants.PrimaryStat.ENDURANCE:
			temp_stats.endurance = value
		GameConstants.PrimaryStat.CHARISMA:
			temp_stats.charisma = value
		GameConstants.PrimaryStat.INTELLIGENCE:
			temp_stats.intelligence = value
		GameConstants.PrimaryStat.AGILITY:
			temp_stats.agility = value
		GameConstants.PrimaryStat.LUCK:
			temp_stats.luck = value

## Seleciona um trait
func select_trait(trait: TraitData.Trait) -> bool:
	if selected_traits.size() >= MAX_TRAITS:
		return false
	
	if trait in selected_traits:
		# Desselecionar
		selected_traits.erase(trait)
		temp_traits.remove_trait(trait)
		_refresh_traits_display()
		return true
	
	selected_traits.append(trait)
	temp_traits.select_trait(trait)
	_refresh_traits_display()
	return true

## Tagga uma skill
func tag_skill(skill: SkillData.Skill) -> bool:
	if tagged_skills.size() >= TAGGED_SKILLS_COUNT:
		# Se já tem 3, remover o primeiro e adicionar o novo
		if skill in tagged_skills:
			# Se já está taggeada, desselecionar
			tagged_skills.erase(skill)
			_refresh_skills_display()
			return true
		else:
			# Remover o primeiro e adicionar o novo
			tagged_skills.pop_front()
	
	if skill in tagged_skills:
		# Desselecionar
		tagged_skills.erase(skill)
		_refresh_skills_display()
		return true
	
	tagged_skills.append(skill)
	_refresh_skills_display()
	return true

## Define o nome do personagem
func set_name(name: String) -> bool:
	if name.is_empty() or name.length() < 1:
		return false
	
	character_name = name
	if name_input:
		name_input.text = name
	return true

## Finaliza a criação do personagem
func finalize_character() -> Critter:
	if special_points_remaining != 0:
		push_warning("CharacterEditor: Cannot finalize with %d points remaining" % special_points_remaining)
		return null
	
	if character_name.is_empty():
		push_warning("CharacterEditor: Cannot finalize without a name")
		return null
	
	# Criar Critter
	var critter = Critter.new()
	critter.critter_name = character_name
	critter.is_player = true
	
	# Copiar stats
	critter.stats = StatData.new()
	critter.stats.strength = temp_stats.strength
	critter.stats.perception = temp_stats.perception
	critter.stats.endurance = temp_stats.endurance
	critter.stats.charisma = temp_stats.charisma
	critter.stats.intelligence = temp_stats.intelligence
	critter.stats.agility = temp_stats.agility
	critter.stats.luck = temp_stats.luck
	
	# Aplicar traits
	critter.stats.calculate_derived_stats()
	temp_traits.apply_trait_effects(critter.stats, temp_skills)
	
	# Copiar skills e aplicar tagged bonus
	critter.skills = SkillData.new()
	for skill in SkillData.Skill.values():
		var base_value = temp_skills.get_skill_value(skill)
		if skill in tagged_skills:
			base_value += 20  # +20 bonus para tagged skills
		critter.skills.skill_values[skill] = base_value
	
	# Recalcular derived stats após aplicar traits
	critter.stats.calculate_derived_stats()
	
	# Inicializar outros valores
	critter.level = 1
	critter.experience = 0
	critter.karma = 0
	critter.reputation = 0
	
	character_created.emit(critter)
	return critter

## Atualiza pontos usados
func _update_points_used() -> void:
	if not temp_stats:
		return
	
	var total_used = 0
	total_used += temp_stats.strength
	total_used += temp_stats.perception
	total_used += temp_stats.endurance
	total_used += temp_stats.charisma
	total_used += temp_stats.intelligence
	total_used += temp_stats.agility
	total_used += temp_stats.luck
	
	special_points_remaining = TOTAL_SPECIAL_POINTS - total_used
	if points_label:
		_update_points_label()

## Atualiza label de pontos
func _update_points_label() -> void:
	if points_label:
		points_label.text = "Points Remaining: %d" % special_points_remaining

## Atualiza display de um stat
func _update_stat_display(stat: GameConstants.PrimaryStat) -> void:
	if not stat in special_controls:
		return
	
	var controls = special_controls[stat]
	var value = _get_stat_value(stat)
	
	if "value_label" in controls:
		controls.value_label.text = str(value)
	
	# Atualizar estado dos botões
	if "decrease_btn" in controls:
		controls.decrease_btn.disabled = (value <= MIN_STAT or special_points_remaining >= TOTAL_SPECIAL_POINTS)
	if "increase_btn" in controls:
		controls.increase_btn.disabled = (value >= MAX_STAT or special_points_remaining <= 0)

## Atualiza display de traits
func _refresh_traits_display() -> void:
	if not traits_container:
		return
	
	# Limpar display atual
	for child in traits_container.get_children():
		child.queue_free()
	
	# Adicionar todos os traits
	for trait in TraitData.Trait.values():
		var hbox = HBoxContainer.new()
		
		var checkbox = CheckBox.new()
		checkbox.text = temp_traits.get_trait_name(trait)
		checkbox.button_pressed = (trait in selected_traits)
		checkbox.disabled = (selected_traits.size() >= MAX_TRAITS and not (trait in selected_traits))
		checkbox.toggled.connect(func(pressed): select_trait(trait))
		hbox.add_child(checkbox)
		
		var desc_label = Label.new()
		desc_label.text = temp_traits.get_trait_description(trait)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hbox.add_child(desc_label)
		
		traits_container.add_child(hbox)

## Atualiza display de skills
func _refresh_skills_display() -> void:
	if not skills_container:
		return
	
	# Limpar display atual
	for child in skills_container.get_children():
		child.queue_free()
	
	# Adicionar todas as skills
	for skill in SkillData.Skill.values():
		var hbox = HBoxContainer.new()
		
		var checkbox = CheckBox.new()
		var skill_name = temp_skills.get_skill_name(skill)
		checkbox.text = skill_name
		checkbox.button_pressed = (skill in tagged_skills)
		checkbox.disabled = (tagged_skills.size() >= TAGGED_SKILLS_COUNT and not (skill in tagged_skills))
		checkbox.toggled.connect(func(pressed): tag_skill(skill))
		hbox.add_child(checkbox)
		
		var tag_label = Label.new()
		if skill in tagged_skills:
			tag_label.text = "[TAGGED +20]"
			tag_label.modulate = Color.GREEN
		hbox.add_child(tag_label)
		
		skills_container.add_child(hbox)

## Configura a UI
func _setup_ui() -> void:
	if not name_input or special_controls.is_empty():
		_create_basic_ui()

## Cria UI básica
func _create_basic_ui() -> void:
	var vbox = VBoxContainer.new()
	vbox.name = "ContentVBox"
	add_child(vbox)
	
	# Nome do personagem
	var name_label = Label.new()
	name_label.text = "Character Name:"
	vbox.add_child(name_label)
	
	name_input = LineEdit.new()
	name_input.name = "NameInput"
	name_input.text_changed.connect(func(text): set_name(text))
	vbox.add_child(name_input)
	
	# SPECIAL Stats
	var special_label = Label.new()
	special_label.text = "SPECIAL Stats"
	special_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(special_label)
	
	points_label = Label.new()
	points_label.name = "PointsLabel"
	points_label.text = "Points Remaining: %d" % special_points_remaining
	vbox.add_child(points_label)
	
	# Criar controles para cada stat
	var stats = [
		GameConstants.PrimaryStat.STRENGTH,
		GameConstants.PrimaryStat.PERCEPTION,
		GameConstants.PrimaryStat.ENDURANCE,
		GameConstants.PrimaryStat.CHARISMA,
		GameConstants.PrimaryStat.INTELLIGENCE,
		GameConstants.PrimaryStat.AGILITY,
		GameConstants.PrimaryStat.LUCK
	]
	
	for stat in stats:
		var hbox = HBoxContainer.new()
		
		var stat_label = Label.new()
		stat_label.text = GameConstants.PrimaryStat.keys()[stat] + ":"
		stat_label.custom_minimum_size.x = 120
		hbox.add_child(stat_label)
		
		var decrease_btn = Button.new()
		decrease_btn.text = "-"
		decrease_btn.pressed.connect(func(): allocate_stat(stat, -1))
		hbox.add_child(decrease_btn)
		
		var value_label = Label.new()
		value_label.text = str(_get_stat_value(stat))
		value_label.custom_minimum_size.x = 30
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hbox.add_child(value_label)
		
		var increase_btn = Button.new()
		increase_btn.text = "+"
		increase_btn.pressed.connect(func(): allocate_stat(stat, 1))
		hbox.add_child(increase_btn)
		
		special_controls[stat] = {
			"label": stat_label,
			"decrease_btn": decrease_btn,
			"increase_btn": increase_btn,
			"value_label": value_label
		}
		
		vbox.add_child(hbox)
	
	# Traits
	var traits_label = Label.new()
	traits_label.text = "Traits (Select up to %d)" % MAX_TRAITS
	traits_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(traits_label)
	
	traits_container = VBoxContainer.new()
	traits_container.name = "TraitsContainer"
	vbox.add_child(traits_container)
	_refresh_traits_display()
	
	# Skills
	var skills_label = Label.new()
	skills_label.text = "Tag Skills (Select %d)" % TAGGED_SKILLS_COUNT
	skills_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(skills_label)
	
	skills_container = VBoxContainer.new()
	skills_container.name = "SkillsContainer"
	vbox.add_child(skills_container)
	_refresh_skills_display()
	
	# Botão de finalizar
	finalize_button = Button.new()
	finalize_button.name = "FinalizeButton"
	finalize_button.text = "Create Character"
	finalize_button.pressed.connect(_on_finalize_pressed)
	vbox.add_child(finalize_button)
	
	# Atualizar displays iniciais
	_update_points_label()
	for stat in stats:
		_update_stat_display(stat)
	
	# Conectar mudanças de nome
	if name_input:
		name_input.text_changed.connect(func(text): character_name = text)

## Handler do botão de finalizar
func _on_finalize_pressed() -> void:
	var critter = finalize_character()
	if critter:
		# Sucesso - o sinal character_created será emitido
		pass
	else:
		# Mostrar erro
		push_error("CharacterEditor: Failed to create character")
