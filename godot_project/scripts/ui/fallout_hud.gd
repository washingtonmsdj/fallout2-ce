extends Control

## HUD do Fallout 2 - Interface original

@onready var hp_label: Label = $InterfaceBar/HPLabel
@onready var ac_label: Label = $InterfaceBar/ACLabel
@onready var ap_label: Label = $InterfaceBar/APLabel
@onready var location_label: Label = $LocationLabel

var player: Node = null

func _ready():
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.player_spawned.connect(_on_player_spawned)
		gm.game_state_changed.connect(_on_game_state_changed)
	visible = false

func _on_player_spawned(p: Node):
	player = p
	visible = true
	
	if player.has_signal("hp_changed"):
		player.hp_changed.connect(_on_hp_changed)
	if player.has_signal("ap_changed"):
		player.ap_changed.connect(_on_ap_changed)
	
	_update_display()

func _on_game_state_changed(state: int):
	# 0=MENU, 1=PLAYING
	visible = state != 0

func _on_hp_changed(current: int, maximum: int):
	if hp_label:
		hp_label.text = str(current) + "/" + str(maximum)

func _on_ap_changed(current: int, maximum: int):
	if ap_label:
		ap_label.text = str(current) + "/" + str(maximum)

func _update_display():
	if not player:
		return
	
	if hp_label and player.has_method("get"):
		hp_label.text = str(player.hp) + "/" + str(player.max_hp)
	
	if ac_label and player.has_method("get"):
		ac_label.text = str(player.armor_class)
	
	if ap_label and player.has_method("get"):
		ap_label.text = str(player.action_points) + "/" + str(player.max_action_points)

func set_location(name: String):
	if location_label:
		location_label.text = name.to_upper()
