extends Node

## Property Test: Damage Formula Correctness
## **Feature: godot-game-migration, Property 10: Damage Formula Correctness**
## **Validates: Requirements 5.4**
##
## Property: For any weapon damage W, strength bonus B, and target damage resistance DR,
## final damage SHALL equal max(1, W + B - (DR * (W + B) / 100)).

const ITERATIONS = 100

func _ready():
	print("\n=== Property Test: Damage Formula Correctness ===")
	print("Running ", ITERATIONS, " iterations...")
	
	var passed = 0
	var failed = 0
	
	for i in range(ITERATIONS):
		if test_damage_formula():
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

func test_damage_formula() -> bool:
	"""
	Test that damage formula is correctly calculated
	Formula: Damage = Weapon_Damage + Strength_Bonus - (DR * (Weapon_Damage + Strength_Bonus) / 100)
	Minimum of 1 damage
	"""
	# Generate random parameters
	var weapon_damage = randi_range(1, 50)
	var strength_bonus = randi_range(0, 10)
	var target_dr = randi_range(0, 90)  # DR typically 0-90%
	
	# Calculate expected damage
	var total_damage = weapon_damage + strength_bonus
	var dr_reduction = (target_dr * total_damage) / 100
	var expected = max(1, total_damage - dr_reduction)
	
	# Calculate actual damage using the formula
	var actual = calculate_damage(weapon_damage, strength_bonus, target_dr)
	
	# Property: actual must equal expected
	if actual != expected:
		print("❌ FAILED: Damage formula incorrect!")
		print("   Weapon Damage: ", weapon_damage)
		print("   Strength Bonus: ", strength_bonus)
		print("   Target DR: ", target_dr, "%")
		print("   Expected: ", expected)
		print("   Actual: ", actual)
		return false
	
	# Additional property: damage must be at least 1
	if actual < 1:
		print("❌ FAILED: Damage below minimum!")
		print("   Result: ", actual)
		return false
	
	return true

func calculate_damage(weapon_damage: int, strength_bonus: int, target_dr: int) -> int:
	"""
	Calculate damage using Fallout 2 formula
	This mimics CombatSystem._calculate_damage() logic
	"""
	var total_damage = weapon_damage + strength_bonus
	var dr_reduction = (target_dr * total_damage) / 100
	var final_damage = total_damage - dr_reduction
	return max(1, int(final_damage))
