extends Node2D
## Cena de teste para o sistema de combate turn-based

# Referências UI
@onready var turn_label: Label = $UI/BattleUI/TopPanel/TurnLabel
@onready var player_hp_label: Label = $UI/BattleUI/BottomPanel/PlayerStats/PlayerHP
@onready var player_ap_label: Label = $UI/BattleUI/BottomPanel/PlayerStats/PlayerAP
@onready var enemy_hp_label: Label = $UI/BattleUI/BottomPanel/EnemyStats/EnemyHP
@onready var enemy_ap_label: Label = $UI/BattleUI/BottomPanel/EnemyStats/EnemyAP
@onready var attack_btn: Button = $UI/BattleUI/BottomPanel/ActionButtons/AttackBtn
@onready var heal_btn: Button = $UI/BattleUI/BottomPanel/ActionButtons/HealBtn
@onready var end_turn_btn: Button = $UI/BattleUI/BottomPanel/ActionButtons/EndTurnBtn
@onready var combat_log: RichTextLabel = $UI/BattleUI/CombatLog/LogLabel
@onready var game_over_panel: Panel = $UI/BattleUI/GameOverPanel
@onready var result_label: Label = $UI/BattleUI/GameOverPanel/ResultLabel
@onready var restart_btn: Button = $UI/BattleUI/GameOverPanel/RestartBtn
@onready var player_sprite: Polygon2D = $Arena/PlayerSprite
@onready var enemy_sprite: Polygon2D = $Arena/EnemySprite
@onready var damage_label: Label = $Arena/DamageLabel

# Personagens
var player: Critter
var enemy: Critter

# Sistema de combate
var combat: CombatSystem
var is_player_turn: bool = true

func _ready() -> void:
	_setup_characters()
	_setup_combat()
	_connect_signals()
	_update_ui()
	_log("[b]Combat started![/b]")

func _setup_characters() -> void:
	# Criar jogador
	player = Critter.new()
	player.critter_name = "Player"
	player.is_player = true
	player.faction = "player"
	player.stats = StatData.new()
	player.stats.strength = 6
	player.stats.perception = 7
	player.stats.endurance = 6
	player.stats.agility = 7
	player.stats.luck = 6
	player.stats.calculate_derived_stats()
	player.skills = SkillData.new()
	player.skills.tag_skill(SkillData.Skill.SMALL_GUNS)
	
	# Criar arma do jogador
	var pistol: Weapon = Weapon.new()
	pistol.item_name = "10mm Pistol"
	pistol.weapon_type = GameConstants.WeaponType.SMALL_GUN
	pistol.min_damage = 5
	pistol.max_damage = 12
	pistol.ap_cost_primary = 5
	pistol.range = 20
	player.equipped_weapon = pistol
	
	# Criar inimigo
	enemy = Critter.new()
	enemy.critter_name = "Raider"
	enemy.is_player = false
	enemy.faction = "enemy"
	enemy.stats = StatData.new()
	enemy.stats.strength = 5
	enemy.stats.perception = 5
	enemy.stats.endurance = 5
	enemy.stats.agility = 5
	enemy.stats.luck = 4
	enemy.stats.calculate_derived_stats()
	enemy.skills = SkillData.new()
	
	# Arma do inimigo
	var knife: Weapon = Weapon.new()
	knife.item_name = "Combat Knife"
	knife.weapon_type = GameConstants.WeaponType.MELEE
	knife.min_damage = 3
	knife.max_damage = 8
	knife.ap_cost_primary = 4
	knife.range = 1
	enemy.equipped_weapon = knife
	
	# Nota: Critter é Node, então podemos adicionar como filho
	# Se der erro, comente estas linhas - o combate funciona sem elas
	add_child(player)
	add_child(enemy)

func _setup_combat() -> void:
	combat = CombatSystem.new()
	add_child(combat)
	
	combat.turn_started.connect(_on_turn_started)
	combat.turn_ended.connect(_on_turn_ended)
	combat.attack_executed.connect(_on_attack_executed)
	combat.combat_ended.connect(_on_combat_ended)
	
	combat.start_combat([player, enemy])

func _connect_signals() -> void:
	attack_btn.pressed.connect(_on_attack_pressed)
	heal_btn.pressed.connect(_on_heal_pressed)
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)

func _on_attack_pressed() -> void:
	if not is_player_turn:
		return
	
	if player.stats.current_ap < 5:
		_log("[color=yellow]Not enough AP![/color]")
		return
	
	var result: Dictionary = combat.execute_attack(player, enemy)
	_update_ui()

func _on_heal_pressed() -> void:
	if not is_player_turn:
		return
	
	if player.stats.current_ap < 3:
		_log("[color=yellow]Not enough AP![/color]")
		return
	
	player.stats.spend_ap(3)
	var healed: int = player.heal(15)
	_log("[color=green]Player healed %d HP![/color]" % healed)
	_update_ui()

func _on_end_turn_pressed() -> void:
	if not is_player_turn:
		return
	combat.end_turn()

func _on_turn_started(critter: Critter) -> void:
	is_player_turn = critter.is_player
	_update_ui()
	
	if critter.is_player:
		turn_label.text = "YOUR TURN"
		_set_buttons_enabled(true)
	else:
		turn_label.text = "ENEMY TURN"
		_set_buttons_enabled(false)

func _on_turn_ended(_critter: Critter) -> void:
	pass

func _on_attack_executed(attacker: Critter, defender: Critter, result: Dictionary) -> void:
	var attacker_name: String = attacker.critter_name
	var defender_name: String = defender.critter_name
	
	if result.hit:
		var msg: String = "[color=red]%s hits %s for %d damage!" % [attacker_name, defender_name, result.damage]
		if result.critical:
			msg += " [b]CRITICAL![/b]"
		msg += "[/color]"
		_log(msg)
		
		_show_damage(result.damage, defender == enemy)
		
		if result.killed:
			_log("[color=orange][b]%s was killed![/b][/color]" % defender_name)
	else:
		_log("[color=gray]%s missed %s![/color]" % [attacker_name, defender_name])
	
	_update_ui()

func _on_combat_ended() -> void:
	game_over_panel.visible = true
	_set_buttons_enabled(false)
	
	if player.stats.is_alive():
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color.GREEN)
		_log("[color=green][b]You won the battle![/b][/color]")
	else:
		result_label.text = "DEFEAT"
		result_label.add_theme_color_override("font_color", Color.RED)
		_log("[color=red][b]You were defeated![/b][/color]")

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _update_ui() -> void:
	player_hp_label.text = "HP: %d/%d" % [player.stats.current_hp, player.stats.max_hp]
	player_ap_label.text = "AP: %d/%d" % [player.stats.current_ap, player.stats.max_ap]
	enemy_hp_label.text = "HP: %d/%d" % [enemy.stats.current_hp, enemy.stats.max_hp]
	enemy_ap_label.text = "AP: %d/%d" % [enemy.stats.current_ap, enemy.stats.max_ap]
	
	var player_hp_ratio: float = float(player.stats.current_hp) / float(player.stats.max_hp)
	var enemy_hp_ratio: float = float(enemy.stats.current_hp) / float(enemy.stats.max_hp)
	
	player_sprite.color = Color(0.2, 0.6 * player_hp_ratio, 1.0)
	enemy_sprite.color = Color(1.0, 0.3 * enemy_hp_ratio, 0.3 * enemy_hp_ratio)

func _set_buttons_enabled(enabled: bool) -> void:
	attack_btn.disabled = not enabled
	heal_btn.disabled = not enabled
	end_turn_btn.disabled = not enabled

func _log(message: String) -> void:
	combat_log.append_text("\n" + message)

func _show_damage(amount: int, on_enemy: bool) -> void:
	damage_label.text = "-%d" % amount
	damage_label.visible = true
	
	if on_enemy:
		damage_label.position = enemy_sprite.position + Vector2(0, -80)
	else:
		damage_label.position = player_sprite.position + Vector2(0, -80)
	
	var tween: Tween = create_tween()
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 50, 0.5)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func() -> void:
		damage_label.visible = false
		damage_label.modulate.a = 1.0
	)
