extends Resource
class_name Item
## Classe base para todos os itens do jogo

@export var item_name: String = "Item"
@export_multiline var description: String = ""
@export var item_type: GameConstants.ItemType = GameConstants.ItemType.MISC
@export var weight: float = 0.0
@export var value: int = 0
@export var icon: Texture2D = null
@export var stackable: bool = false
@export var max_stack: int = 1
@export var is_quest_item: bool = false

var stack_count: int = 1

func use(user: Critter) -> bool:
	# Override em subclasses
	return false

func get_display_name() -> String:
	if stackable and stack_count > 1:
		return "%s (%d)" % [item_name, stack_count]
	return item_name

func can_stack_with(other: Item) -> bool:
	if not stackable or not other.stackable:
		return false
	return item_name == other.item_name

func add_to_stack(amount: int) -> int:
	if not stackable:
		return 0
	
	var space: int = max_stack - stack_count
	var added: int = min(amount, space)
	stack_count += added
	return added

func remove_from_stack(amount: int) -> int:
	var removed: int = min(amount, stack_count)
	stack_count -= removed
	return removed

func is_stack_full() -> bool:
	return stack_count >= max_stack
