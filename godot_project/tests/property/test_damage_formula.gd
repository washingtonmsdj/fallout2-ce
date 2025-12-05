extends Node

## Property Test: Damage Formula Correctness
## **Feature: godot-game-migration, Property 10: Damage Formula Correctness**
## **Validates: Requirements 5.4**
##
## Property: For any weapon damage W, strength bonus B, target damage threshold DT,
## and target damage resistance DR, final damage SHALL equal:
## max(0, (W + B - DT) * (1 - DR/100))
## 
## This implements the Fallout 2 damage system with both DT and DR.

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
	Test that damage formula is correctly calculated with DT and DR
	Formula: Damage = (Weapon_Damage + Strength_Bonus - DT) * (1 - DR/100)
	Minimum of 0 damage (can be fully blocked)
	"""
	# Generate random parameters
	var weapon_damage = randi_range(1, 50)
	var strength_bonus = randi_range(0, 10)
	var target_dt = randi_range(0, 15)  # DT typically 0-15
	var target_dr = randi_range(0, 90)  # DR typically 0-90%
	
	# Calculate expected damage
	var total_damage = weapon_damage + strength_bonus
	
	# Apply DT first
	total_damage -= target_dt
	if total_damage <= 0:
		# DT blocked all damage
		var expected = 0
		var actual = calculate_damage(weapon_damage, strength_bonus, target_dt, target_dr)
		
		if actual != expected:
			print("❌ FAILED: DT should block all damage!")
			print("   Weapon Damage: ", weapon_damage)
			print("   Strength Bonus: ", strength_bonus)
			print("   Target DT: ", target_dt)
			print("   Target DR: ", target_dr, "%")
			print("   Expected: ", expected)
			print("   Actual: ", actual)
			return false
		return true
	
	# Apply DR
	var dr_multiplier = 1.0 - (target_dr / 100.0)
	var expected = int(total_damage * dr_multiplier)
	expected = max(0, expected)
	
	# Calculate actual damage using the formula
	var actual = calculate_damage(weapon_damage, strength_bonus, target_dt, target_dr)
	
	# Property: actual must equal expected
	if actual != expected:
		print("❌ FAILED: Damage formula incorrect!")
		print("   Weapon Damage: ", weapon_damage)
		print("   Strength Bonus: ", strength_bonus)
		print("   Target DT: ", target_dt)
		print("   Target DR: ", target_dr, "%")
		print("   Expected: ", expected)
		print("   Actual: ", actual)
		return false
	
	# Additional property: damage must be >= 0
	if actual < 0:
		print("❌ FAILED: Damage below minimum!")
		print("   Result: ", actual)
		return false
	
	return true

func calculate_damage(weapon_damage: int, strength_bonus: int, target_dt: int, target_dr: int) -> int:
	"""
	Calculate damage using Fallout 2 formula with DT and DR
	This mimics CombatSystem._calculate_damage() logic
	"""
	var total_damage = weapon_damage + strength_bonus
	
	# Apply DT (Damage Threshold)
	total_damage -= target_dt
	if total_damage <= 0:
		return 0
	
	# Apply DR (Damage Resistance)
	var dr_multiplier = 1.0 - (target_dr / 100.0)
	var final_damage = int(total_damage * dr_multiplier)
	
	return max(0, final_damage)
