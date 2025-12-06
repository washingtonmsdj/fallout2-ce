extends Node
class_name CompanionDialogue
## Sistema de diálogos e comentários contextuais de companheiros

signal companion_comment(companion: Critter, comment: String)
signal companion_event_triggered(companion: Critter, event_type: String)

var party_system: PartySystem = null

# Comentários contextuais
var location_comments: Dictionary = {}  # {companion_id: {location_id: comment}}
var event_comments: Dictionary = {}     # {companion_id: {event_type: comment}}

func _ready() -> void:
	pass

## Define o sistema de party
func set_party_system(system: PartySystem) -> void:
	party_system = system
	
	# Conectar sinais do party system
	if party_system:
		if not party_system.companion_joined.is_connected(_on_companion_joined):
			party_system.companion_joined.connect(_on_companion_joined)
		if not party_system.companion_left.is_connected(_on_companion_left):
			party_system.companion_left.connect(_on_companion_left)

## Quando um companheiro entra no party
func _on_companion_joined(companion: Critter) -> void:
	if not companion:
		return
	
	# Inicializar comentários do companheiro
	_initialize_companion_comments(companion)

## Quando um companheiro sai do party
func _on_companion_left(companion: Critter) -> void:
	if not companion:
		return
	
	# Limpar comentários
	if companion.critter_name in location_comments:
		location_comments.erase(companion.critter_name)
	if companion.critter_name in event_comments:
		event_comments.erase(companion.critter_name)

## Inicializa comentários de um companheiro
func _initialize_companion_comments(companion: Critter) -> void:
	if not companion:
		return
	
	# TODO: Carregar comentários de arquivo de dados ou script
	# Por enquanto, usar comentários genéricos
	location_comments[companion.critter_name] = {}
	event_comments[companion.critter_name] = {}

## Dispara comentário contextual baseado em localização
func trigger_location_comment(location_id: String) -> void:
	if not party_system:
		return
	
	for companion in party_system.party_members:
		if not companion:
			continue
		
		if companion.critter_name in location_comments:
			var comments = location_comments[companion.critter_name]
			if location_id in comments:
				var comment = comments[location_id]
				companion_comment.emit(companion, comment)

## Dispara comentário contextual baseado em evento
func trigger_event_comment(event_type: String, event_data: Dictionary = {}) -> void:
	if not party_system:
		return
	
	for companion in party_system.party_members:
		if not companion:
			continue
		
		if companion.critter_name in event_comments:
			var comments = event_comments[companion.critter_name]
			if event_type in comments:
				var comment = comments[event_type]
				# Substituir placeholders no comentário
				comment = _format_comment(comment, event_data)
				companion_comment.emit(companion, comment)
				companion_event_triggered.emit(companion, event_type)

## Formata comentário com dados do evento
func _format_comment(comment: String, data: Dictionary) -> String:
	var formatted = comment
	
	# Substituir placeholders simples
	for key in data:
		formatted = formatted.replace("{%s}" % key, str(data[key]))
	
	return formatted

## Adiciona comentário de localização para um companheiro
func add_location_comment(companion: Critter, location_id: String, comment: String) -> void:
	if not companion:
		return
	
	if not companion.critter_name in location_comments:
		location_comments[companion.critter_name] = {}
	
	location_comments[companion.critter_name][location_id] = comment

## Adiciona comentário de evento para um companheiro
func add_event_comment(companion: Critter, event_type: String, comment: String) -> void:
	if not companion:
		return
	
	if not companion.critter_name in event_comments:
		event_comments[companion.critter_name] = {}
	
	event_comments[companion.critter_name][event_type] = comment

## Obtém comentário de localização
func get_location_comment(companion: Critter, location_id: String) -> String:
	if not companion or not companion.critter_name in location_comments:
		return ""
	
	var comments = location_comments[companion.critter_name]
	if location_id in comments:
		return comments[location_id]
	
	return ""

## Obtém comentário de evento
func get_event_comment(companion: Critter, event_type: String) -> String:
	if not companion or not companion.critter_name in event_comments:
		return ""
	
	var comments = event_comments[companion.critter_name]
	if event_type in comments:
		return comments[event_type]
	
	return ""
