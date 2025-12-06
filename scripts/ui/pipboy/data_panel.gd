extends Control
class_name DataPanel
## Painel de dados do Pipboy - mostra quest log e estatísticas

var player: Critter = null
var quest_system: QuestSystem = null

var quest_list: ItemList = null
var quest_details_label: Label = null
var stats_label: Label = null

func _ready() -> void:
	_setup_ui()

## Define o jogador
func set_player(player_critter: Critter) -> void:
	player = player_critter
	refresh()

## Define o sistema de quests
func set_quest_system(system: QuestSystem) -> void:
	quest_system = system
	refresh()

## Atualiza o conteúdo do painel
func refresh() -> void:
	_refresh_quest_log()
	_refresh_statistics()

## Atualiza o quest log
func _refresh_quest_log() -> void:
	if not quest_list:
		return
	
	quest_list.clear()
	
	if not quest_system:
		return
	
	# Adicionar quests ativas
	var active_quests = quest_system.get_active_quests()
	for quest in active_quests:
		if quest:
			var display_text = "[ACTIVE] %s" % quest.title
			quest_list.add_item(display_text)
			quest_list.set_item_metadata(quest_list.get_item_count() - 1, quest)
	
	# Adicionar quests completas
	var completed_quests = quest_system.get_completed_quests()
	for quest in completed_quests:
		if quest:
			var display_text = "[COMPLETED] %s" % quest.title
			quest_list.add_item(display_text)
			quest_list.set_item_metadata(quest_list.get_item_count() - 1, quest)
	
	# Adicionar quests falhadas
	var failed_quests = quest_system.get_failed_quests()
	for quest in failed_quests:
		if quest:
			var display_text = "[FAILED] %s" % quest.title
			quest_list.add_item(display_text)
			quest_list.set_item_metadata(quest_list.get_item_count() - 1, quest)

## Atualiza estatísticas do jogo
func _refresh_statistics() -> void:
	if not stats_label or not player:
		return
	
	var stats_text = "Game Statistics\n\n"
	stats_text += "Level: %d\n" % player.level
	stats_text += "Experience: %d\n" % player.experience
	stats_text += "Karma: %d\n" % player.karma
	
	if quest_system:
		var all_quests = quest_system.get_all_quests()
		var active_count = quest_system.get_active_quests().size()
		var completed_count = quest_system.get_completed_quests().size()
		var failed_count = quest_system.get_failed_quests().size()
		
		stats_text += "\nQuests:\n"
		stats_text += "Active: %d\n" % active_count
		stats_text += "Completed: %d\n" % completed_count
		stats_text += "Failed: %d\n" % failed_count
		stats_text += "Total: %d\n" % all_quests.size()
	
	stats_label.text = stats_text

## Quando uma quest é selecionada
func _on_quest_selected(index: int) -> void:
	if not quest_list:
		return
	
	var quest = quest_list.get_item_metadata(index) as Quest
	if quest and quest_details_label:
		_show_quest_details(quest)

## Mostra detalhes da quest
func _show_quest_details(quest: Quest) -> void:
	if not quest_details_label:
		return
	
	var details = quest.title + "\n\n"
	details += quest.description + "\n\n"
	
	# Estado
	match quest.state:
		Quest.QuestState.ACTIVE:
			details += "Status: Active\n"
		Quest.QuestState.COMPLETED:
			details += "Status: Completed\n"
		Quest.QuestState.FAILED:
			details += "Status: Failed\n"
		_:
			details += "Status: Inactive\n"
	
	# Objetivos
	if not quest.objectives.is_empty():
		details += "\nObjectives:\n"
		for objective in quest.objectives:
			if objective:
				var progress_text = objective.get_progress_text()
				details += "- %s\n" % progress_text
	
	# Recompensas
	if quest.rewards:
		details += "\nRewards:\n"
		if quest.rewards.experience > 0:
			details += "Experience: %d\n" % quest.rewards.experience
		if quest.rewards.caps > 0:
			details += "Caps: %d\n" % quest.rewards.caps
		if quest.rewards.karma != 0:
			details += "Karma: %+d\n" % quest.rewards.karma
	
	quest_details_label.text = details

## Configura a UI
func _setup_ui() -> void:
	if not quest_list:
		_create_basic_ui()

## Cria UI básica
func _create_basic_ui() -> void:
	var hbox = HBoxContainer.new()
	hbox.name = "ContentHBox"
	add_child(hbox)
	
	# Lista de quests
	var quest_vbox = VBoxContainer.new()
	hbox.add_child(quest_vbox)
	
	var quest_label = Label.new()
	quest_label.text = "Quest Log"
	quest_label.add_theme_font_size_override("font_size", 18)
	quest_vbox.add_child(quest_label)
	
	quest_list = ItemList.new()
	quest_list.name = "QuestList"
	quest_list.item_selected.connect(_on_quest_selected)
	quest_vbox.add_child(quest_list)
	
	# Detalhes da quest
	var details_vbox = VBoxContainer.new()
	hbox.add_child(details_vbox)
	
	var details_label = Label.new()
	details_label.text = "Quest Details"
	details_label.add_theme_font_size_override("font_size", 18)
	details_vbox.add_child(details_label)
	
	quest_details_label = Label.new()
	quest_details_label.name = "QuestDetailsLabel"
	quest_details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_vbox.add_child(quest_details_label)
	
	# Estatísticas
	var stats_vbox = VBoxContainer.new()
	hbox.add_child(stats_vbox)
	
	var stats_title = Label.new()
	stats_title.text = "Statistics"
	stats_title.add_theme_font_size_override("font_size", 18)
	stats_vbox.add_child(stats_title)
	
	stats_label = Label.new()
	stats_label.name = "StatsLabel"
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_vbox.add_child(stats_label)
