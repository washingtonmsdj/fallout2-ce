extends Control
class_name PipboyUI
## Interface principal do Pipboy

signal pipboy_opened
signal pipboy_closed
signal tab_changed(tab: Tab)

enum Tab {
	STATUS,    # Tab 0: Status do personagem
	INVENTORY, # Tab 1: Inventário
	MAP,       # Tab 2: Mapa
	DATA       # Tab 3: Quests e dados
}

@export var player: Critter = null
@export var animation_duration: float = 0.3

var current_tab: Tab = Tab.STATUS
var is_open: bool = false

# Referências aos painéis (serão configuradas na cena ou via código)
@onready var status_panel: StatusPanel = null
@onready var inventory_panel: InventoryPanel = null
@onready var map_panel: MapPanel = null
@onready var data_panel: DataPanel = null

# Referências aos botões de tab (serão configuradas na cena)
@onready var status_button: Button = null
@onready var inventory_button: Button = null
@onready var map_button: Button = null
@onready var data_button: Button = null

# Referência ao container de conteúdo
@onready var content_container: Control = null

func _ready() -> void:
	# Inicialmente fechado
	visible = false
	is_open = false
	
	# Conectar botões de tab se existirem
	_connect_tab_buttons()
	
	# Configurar painéis se não foram configurados na cena
	_setup_panels()

## Abre o Pipboy
func open() -> void:
	if is_open:
		return
	
	if not player:
		push_error("PipboyUI: Cannot open without player reference")
		return
	
	is_open = true
	visible = true
	
	# Animação de abertura
	var tween = create_tween()
	tween.set_parallel(true)
	modulate.a = 0.0
	tween.tween_property(self, "modulate:a", 1.0, animation_duration)
	
	# Atualizar painel atual
	switch_tab(current_tab)
	
	pipboy_opened.emit()
	
	# Pausar o jogo (opcional)
	get_tree().paused = true

## Fecha o Pipboy
func close() -> void:
	if not is_open:
		return
	
	# Animação de fechamento
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, animation_duration)
	await tween.finished
	
	is_open = false
	visible = false
	
	pipboy_closed.emit()
	
	# Despausar o jogo
	get_tree().paused = false

## Troca de tab
func switch_tab(tab: Tab) -> void:
	if not is_open:
		return
	
	current_tab = tab
	
	# Esconder todos os painéis
	_hide_all_panels()
	
	# Mostrar painel correspondente
	match tab:
		Tab.STATUS:
			if status_panel:
				status_panel.visible = true
				status_panel.refresh()
		Tab.INVENTORY:
			if inventory_panel:
				inventory_panel.visible = true
				inventory_panel.refresh()
		Tab.MAP:
			if map_panel:
				map_panel.visible = true
				map_panel.refresh()
		Tab.DATA:
			if data_panel:
				data_panel.visible = true
				data_panel.refresh()
	
	# Atualizar botões
	_update_tab_buttons()
	
	tab_changed.emit(tab)

## Atualiza o painel atual
func refresh_current_tab() -> void:
	if not is_open:
		return
	
	match current_tab:
		Tab.STATUS:
			if status_panel:
				status_panel.refresh()
		Tab.INVENTORY:
			if inventory_panel:
				inventory_panel.refresh()
		Tab.MAP:
			if map_panel:
				map_panel.refresh()
		Tab.DATA:
			if data_panel:
				data_panel.refresh()

## Define o jogador
func set_player(player_critter: Critter) -> void:
	player = player_critter
	
	# Atualizar referências nos painéis
	if status_panel:
		status_panel.set_player(player)
	if inventory_panel:
		inventory_panel.set_player(player)
	if map_panel:
		map_panel.set_player(player)
	if data_panel:
		data_panel.set_player(player)

## Processa input
func _input(event: InputEvent) -> void:
	if not is_open:
		return
	
	# Fechar com ESC ou Tab
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pipboy"):
		close()
		get_viewport().set_input_as_handled()
		return
	
	# Navegação por teclado
	if event.is_action_pressed("ui_pipboy_status"):
		switch_tab(Tab.STATUS)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_pipboy_inventory"):
		switch_tab(Tab.INVENTORY)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_pipboy_map"):
		switch_tab(Tab.MAP)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_pipboy_data"):
		switch_tab(Tab.DATA)
		get_viewport().set_input_as_handled()

## Conecta os botões de tab
func _connect_tab_buttons() -> void:
	if status_button:
		status_button.pressed.connect(func(): switch_tab(Tab.STATUS))
	if inventory_button:
		inventory_button.pressed.connect(func(): switch_tab(Tab.INVENTORY))
	if map_button:
		map_button.pressed.connect(func(): switch_tab(Tab.MAP))
	if data_button:
		data_button.pressed.connect(func(): switch_tab(Tab.DATA))

## Atualiza o estado visual dos botões de tab
func _update_tab_buttons() -> void:
	if status_button:
		status_button.button_pressed = (current_tab == Tab.STATUS)
	if inventory_button:
		inventory_button.button_pressed = (current_tab == Tab.INVENTORY)
	if map_button:
		map_button.button_pressed = (current_tab == Tab.MAP)
	if data_button:
		data_button.button_pressed = (current_tab == Tab.DATA)

## Esconde todos os painéis
func _hide_all_panels() -> void:
	if status_panel:
		status_panel.visible = false
	if inventory_panel:
		inventory_panel.visible = false
	if map_panel:
		map_panel.visible = false
	if data_panel:
		data_panel.visible = false

## Configura os painéis se não foram configurados na cena
func _setup_panels() -> void:
	# Se os painéis não foram configurados, criar instâncias básicas
	# Isso permite que o sistema funcione mesmo sem cena completa
	if not status_panel:
		status_panel = StatusPanel.new()
		status_panel.name = "StatusPanel"
		if content_container:
			content_container.add_child(status_panel)
		else:
			add_child(status_panel)
	
	if not inventory_panel:
		inventory_panel = InventoryPanel.new()
		inventory_panel.name = "InventoryPanel"
		if content_container:
			content_container.add_child(inventory_panel)
		else:
			add_child(inventory_panel)
	
	if not map_panel:
		map_panel = MapPanel.new()
		map_panel.name = "MapPanel"
		if content_container:
			content_container.add_child(map_panel)
		else:
			add_child(map_panel)
	
	if not data_panel:
		data_panel = DataPanel.new()
		data_panel.name = "DataPanel"
		if content_container:
			content_container.add_child(data_panel)
		else:
			add_child(data_panel)
	
	# Esconder todos inicialmente
	_hide_all_panels()
