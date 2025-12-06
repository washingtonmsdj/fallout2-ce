class_name Vehicle extends Resource

@export var id: String
@export var name: String
@export var speed_multiplier: float = 2.0
@export var fuel_consumption: float = 1.0  # fuel per distance unit
@export var trunk_capacity: float = 100.0
@export var current_fuel: float = 50.0
@export var max_fuel: float = 100.0
@export var condition: float = 100.0  # 0-100

func _to_string() -> String:
	return "Vehicle(%s)" % name

func is_operational() -> bool:
	return condition > 0.0 and current_fuel > 0.0

func consume_fuel(amount: float) -> void:
	current_fuel = maxf(0.0, current_fuel - amount)

func refuel(amount: float) -> void:
	current_fuel = minf(max_fuel, current_fuel + amount)

func repair(amount: float) -> void:
	condition = minf(100.0, condition + amount)

func damage(amount: float) -> void:
	condition = maxf(0.0, condition - amount)
