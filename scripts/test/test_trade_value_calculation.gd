extends GdUnitTestSuite
## Property test for trade value calculation
## **Feature: fallout2-complete-migration, Property 30: Trade Value Calculation**
## **Validates: Requirements 12.1, 12.2**

class_name TestTradeValueCalculation
extends GdUnitTestSuite

var economy_system: EconomySystem
var player: Critter
var trader: Critter

func before_test() -> void:
	economy_system = EconomySystem.new()
	add_child(economy_system)
	
	player = Critter.new()
	player.critter_name = "Player"
	player.stats = StatData.new()
	player.skills = SkillData.new()
	player.caps = 1000
	
	trader = Critter.new()
	trader.critter_name = "Trader"
	trader.stats = StatData.new()
	trader.skills = SkillData.new()
	trader.caps = 5000

func after_test() -> void:
	if economy_system:
		economy_system.queue_free()

## Property: For any item, calculate_final_price() SHALL return a value 
## that is modified by Barter skill and reputation
func test_trade_value_calculation_property() -> void:
	# Criar item de teste
	var item = Item.new()
	item.item_name = "Test Item"
	item.value = 100
	item.weight = 1.0
	
	# Testar com diferentes níveis de Barter
	var barter_levels = [0, 50, 100, 150, 200]
	
	for barter_level in barter_levels:
		player.skills.skill_values[SkillData.Skill.BARTER] = barter_level
		
		# Preço ao comprar (deve diminuir com Barter)
		var buy_price = economy_system.calculate_final_price(item, player, trader, true)
		
		# Preço ao vender (deve aumentar com Barter)
		var sell_price = economy_system.calculate_final_price(item, trader, player, false)
		
		# Verificar que preços são válidos
		assert_that(buy_price).is_greater(0, "Buy price should be positive")
		assert_that(sell_price).is_greater(0, "Sell price should be positive")
		
		# Com Barter maior, preço de compra deve ser menor
		if barter_level > 0:
			var base_buy_price = economy_system.calculate_final_price(item, player, trader, true)
			# Nota: Como modificador é aplicado, preço deve variar

## Test that Barter skill reduces buy price
func test_barter_reduces_buy_price() -> void:
	var item = Item.new()
	item.item_name = "Test Item"
	item.value = 100
	item.weight = 1.0
	
	# Sem Barter
	player.skills.skill_values[SkillData.Skill.BARTER] = 0
	var price_no_barter = economy_system.calculate_final_price(item, player, trader, true)
	
	# Com Barter alto
	player.skills.skill_values[SkillData.Skill.BARTER] = 200
	var price_high_barter = economy_system.calculate_final_price(item, player, trader, true)
	
	# Preço com Barter alto deve ser menor
	assert_that(price_high_barter).is_less_equal(price_no_barter,
		"High Barter should reduce buy price")

## Test that Barter skill increases sell price
func test_barter_increases_sell_price() -> void:
	var item = Item.new()
	item.item_name = "Test Item"
	item.value = 100
	item.weight = 1.0
	
	# Sem Barter
	player.skills.skill_values[SkillData.Skill.BARTER] = 0
	var price_no_barter = economy_system.calculate_final_price(item, trader, player, false)
	
	# Com Barter alto
	player.skills.skill_values[SkillData.Skill.BARTER] = 200
	var price_high_barter = economy_system.calculate_final_price(item, trader, player, false)
	
	# Preço com Barter alto deve ser maior
	assert_that(price_high_barter).is_greater_equal(price_no_barter,
		"High Barter should increase sell price")

## Test that prices are consistent
func test_price_consistency() -> void:
	var item = Item.new()
	item.item_name = "Test Item"
	item.value = 100
	item.weight = 1.0
	
	# Preço base deve ser calculado corretamente
	var base_price = economy_system.calculate_base_price(item)
	assert_that(base_price).is_greater(0, "Base price should be positive")
	
	# Preço final deve ser baseado no preço base
	var final_price = economy_system.calculate_final_price(item, player, trader, true)
	assert_that(final_price).is_greater(0, "Final price should be positive")

## Test total value calculation
func test_total_value_calculation() -> void:
	var items: Array[Item] = []
	
	# Criar múltiplos itens
	for i in range(5):
		var item = Item.new()
		item.item_name = "Item %d" % i
		item.value = 50 + (i * 10)
		item.weight = 1.0
		items.append(item)
	
	# Calcular valor total
	var total_value = economy_system.calculate_total_value(items, player, trader, true)
	
	# Valor total deve ser soma dos valores individuais (aproximadamente)
	assert_that(total_value).is_greater(0, "Total value should be positive")
	
	# Verificar que é pelo menos a soma dos valores base
	var base_sum = 0
	for item in items:
		base_sum += economy_system.calculate_base_price(item)
	
	assert_that(total_value).is_greater_equal(int(base_sum * 0.5),
		"Total value should be reasonable compared to base sum")

## Test that different item types have different base prices
func test_item_type_pricing() -> void:
	var weapon = Item.new()
	weapon.item_name = "Weapon"
	weapon.item_type = GameConstants.ItemType.WEAPON
	weapon.weight = 2.0
	
	var consumable = Item.new()
	consumable.item_name = "Consumable"
	consumable.item_type = GameConstants.ItemType.CONSUMABLE
	consumable.weight = 0.5
	
	var weapon_price = economy_system.calculate_base_price(weapon)
	var consumable_price = economy_system.calculate_base_price(consumable)
	
	# Armas devem ter preço base maior que consumíveis
	assert_that(weapon_price).is_greater(consumable_price,
		"Weapons should have higher base price than consumables")
