extends Control
class_name MapPanel
## Painel de mapa do Pipboy - mostra mapa local com marcadores

var player: Critter = null
var map_system: MapSystem = null

var map_view: Control = null
var location_markers: Array[Control] = []

func _ready() -> void:
	_setup_ui()

## Define o jogador
func set_player(player_critter: Critter) -> void:
	player = player_critter
	refresh()

## Define o sistema de mapas
func set_map_system(system: MapSystem) -> void:
	map_system = system
	refresh()

## Atualiza o conteúdo do painel
func refresh() -> void:
	if not map_view:
		return
	
	_clear_markers()
	_draw_map()
	_draw_location_markers()

## Desenha o mapa
func _draw_map() -> void:
	if not map_system or not map_system.current_map:
		return
	
	# TODO: Implementar renderização do mapa quando sistema de mapas estiver completo
	# Por enquanto, apenas placeholder
	if map_view:
		# Limpar view anterior
		for child in map_view.get_children():
			child.queue_free()
		
		var label = Label.new()
		label.text = "Map View\n(To be implemented with MapSystem)"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		map_view.add_child(label)

## Desenha marcadores de localização
func _draw_location_markers() -> void:
	if not map_system or not map_system.current_map:
		return
	
	# TODO: Implementar marcadores quando sistema de mapas estiver completo
	# Por enquanto, apenas placeholder

## Limpa marcadores
func _clear_markers() -> void:
	for marker in location_markers:
		if is_instance_valid(marker):
			marker.queue_free()
	location_markers.clear()

## Configura a UI
func _setup_ui() -> void:
	if not map_view:
		_create_basic_ui()

## Cria UI básica
func _create_basic_ui() -> void:
	map_view = Control.new()
	map_view.name = "MapView"
	map_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(map_view)
