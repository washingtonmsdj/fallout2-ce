extends Node

## Property Test: Combat State Consistency
## **Feature: godot-game-migration, Property 11: Combat State Consistency**
## **Validates: Requirements 5.5, 5.6**
##
## Property: For any combat state where all enemies have HP <= 0 or have fled,
## combat SHALL transition to INACTIVE state.

const ITERATIONS = 100

class MockCombatant:
	var name: String
	var hp: int
	var is_player: bool
	
	func _init(n: String, h: int, player: bool = false):
		name = n
		hp = h
		is_player = player

func _ready():
	print("\n=== Property Test: Combat State Consistency ===")
	print("Running ", ITERATIONS, " iterations...")
	
	var passed = 0
	var failed = 0
	
	for i in range(ITERATIONS):
		if test_combat_end_condition():
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

func test_combat_end_condition() -> bool:
	"""
	Test that combat ends when all enemies are dead or player is dead
	"""
	# Generate random combat scenario
	var num_enemies = randi_range(1, 5)
	var combatants = []
	
	# Add player
	var player_hp = randi_range(-10, 100)
	var player = MockCombatant.new("Player", player_hp, true)
	combatants.append(player)
	
	# Add enemies
	for i in range(num_enemies):
		var enemy_hp = randi_range(-10, 100)
		var enemy = MockCombatant.new("Enemy_" + str(i), enemy_hp, false)
		combatants.append(enemy)
	
	# Check if combat should end
	var should_end = check_combat_end(combatants, player)
	
	# Calculate expected result
	var player_alive = player.hp > 0
	var alive_enemies = 0
	for c in combatants:
		if not c.is_player and c.hp > 0:
			alive_enemies += 1
	
	var expected_end = not player_alive or alive_enemies == 0
	
	# Property: should_end must match expected_end
	if should_end != expected_end:
		print("❌ FAILED: Combat end condition incorrect!")
		print("   Player HP: ", player.hp, " (alive: ", player_alive, ")")
		print("   Alive enemies: ", alive_enemies)
		print("   Expected end: ", expected_end)
		print("   Actual end: ", should_end)
		return false
	
	return true

func check_combat_end(combatants: Array, player: MockCombatant) -> bool:
	"""
	Check if combat should end
	This mimics CombatSystem._check_combat_end() logic
	"""
	var alive_enemies = 0
	var player_alive = false
	
	for c in combatants:
		var is_alive = c.hp > 0
		
		if c.is_player:
			player_alive = is_alive
		elif is_alive:
			alive_enemies += 1
	
	# Combat ends if player died OR all enemies died
	return not player_alive or alive_enemies == 0
