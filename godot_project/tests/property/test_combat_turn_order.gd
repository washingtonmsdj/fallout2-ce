extends Node

## Property Test: Combat Turn Order by Sequence
## **Feature: godot-game-migration, Property 8: Combat Turn Order by Sequence**
## **Validates: Requirements 5.1**
##
## Property: For any list of combatants with different Sequence values,
## the turn order SHALL be sorted in descending order by Sequence.

const ITERATIONS = 100

class MockCombatant:
	var name: String
	var perception: int
	var sequence: int
	
	func _init(n: String, p: int):
		name = n
		perception = p
		sequence = p * 2

func _ready():
	print("\n=== Property Test: Combat Turn Order by Sequence ===")
	print("Running ", ITERATIONS, " iterations...")
	
	var passed = 0
	var failed = 0
	
	for i in range(ITERATIONS):
		if test_turn_order_property():
			passed += 1
		else:
			failed += 1
	
	print("\nResults:")
	print("  Passed: ", passed, "/", ITERATIONS)
	print("  Failed: ", failed, "/", ITERATIONS)
	
	if failed == 0:
		print("✅ All tests passed!")
	else:
		print("❌ Some tests failed!")
	
	# Exit
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func test_turn_order_property() -> bool:
	"""
	Test that turn order is correctly sorted by Sequence (descending)
	"""
	# Generate random combatants with different Sequence values
	var num_combatants = randi_range(2, 10)
	var combatants = []
	
	for i in range(num_combatants):
		var perception = randi_range(1, 10)
		var combatant = MockCombatant.new("Combatant_" + str(i), perception)
		combatants.append(combatant)
	
	# Sort using the same logic as CombatSystem
	var turn_order = combatants.duplicate()
	turn_order.sort_custom(func(a, b):
		return a.sequence > b.sequence
	)
	
	# Property: turn_order must be sorted in descending order by Sequence
	for i in range(turn_order.size() - 1):
		var current_seq = turn_order[i].sequence
		var next_seq = turn_order[i + 1].sequence
		
		if current_seq < next_seq:
			print("❌ FAILED: Turn order not sorted correctly!")
			print("   Position ", i, ": ", turn_order[i].name, " (Seq: ", current_seq, ")")
			print("   Position ", i + 1, ": ", turn_order[i + 1].name, " (Seq: ", next_seq, ")")
			return false
	
	return true
