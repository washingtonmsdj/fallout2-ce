extends GdUnitTestSuite
## Property test for trade execution integrity
## **Feature: fallout2-complete-migration, Property 31: Trade Execution Integrity**
## **Validates: Requirements 12.3**

class_name TestTradeExecutionIntegrity
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
	player.stats.carry_weight = 100.0
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

## Property: For any valid trade, execute_trade() SHALL transfer items 
## and caps correctly without duplication or loss
func test_trade_execution_integrity_property() -> void:
	# Criar itens para trade
	var player_item = Item.new()
	player_item.item_name = "Player Item"
	player_item.value = 100
	player_item.weight = 1.0
	player.add_item(player_item)
	
	var trader_item = Item.new()
	trader_item.item_name = "Trader Item"
	trader_item.value = 150
	trader_item.weight = 1.0
	trader.add_item(trader_item)
	
	# Registrar estado inicial
	var player_caps_before = player.caps
	var trader_caps_before = trader.caps
	var player_items_before = player.inventory.size()
	var trader_items_before = trader.inventory.size()
	
	# Executar trade
	var player_trade = [player_item]
	var trader_trade = [trader_item]
	var success = economy_system.execute_trade(player_trade, trader_trade, player, trader)
	
	assert_that(success).is_true("Trade should succeed")
	
	# Verificar que itens foram transferidos
	assert_that(player_item in player.inventory).is_false("Player item should be removed from player")
	assert_that(player_item in trader.inventory).is_true("Player item should be in trader inventory")
	assert_that(trader_item in trader.inventory).is_false("Trader item should be removed from trader")
	assert_that(trader_item in player.inventory).is_true("Trader item should be in player inventory")
	
	# Verificar que caps foram ajustados corretamente
	var player_caps_after = player.caps
	var trader_caps_after = trader.caps
	
	# Player deve ter pago a diferença (150 - 100 = 50)
	var expected_player_caps = player_caps_before - 50
	var expected_trader_caps = trader_caps_before + 50
	
	# Permitir pequena variação devido a modificadores de Barter
	assert_that(abs(player_caps_after - expected_player_caps)).is_less_equal(10,
		"Player caps should be adjusted correctly")
	assert_that(abs(trader_caps_after - expected_trader_caps)).is_less_equal(10,
		"Trader caps should be adjusted correctly")

## Test that trade fails with insufficient caps
func test_trade_fails_insufficient_caps() -> void:
	var player_item = Item.new()
	player_item.item_name = "Player Item"
	player_item.value = 100
	player_item.weight = 1.0
	player.add_item(player_item)
	
	var trader_item = Item.new()
	trader_item.item_name = "Expensive Item"
	trader_item.value = 10000  # Muito caro
	trader_item.weight = 1.0
	trader.add_item(trader_item)
	
	player.caps = 100  # Não tem caps suficientes
	
	var player_trade = [player_item]
	var trader_trade = [trader_item]
	var success = economy_system.execute_trade(player_trade, trader_trade, player, trader)
	
	assert_that(success).is_false("Trade should fail with insufficient caps")
	
	# Verificar que itens não foram transferidos
	assert_that(player_item in player.inventory).is_true("Player item should still be with player")
	assert_that(trader_item in trader.inventory).is_true("Trader item should still be with trader")

## Test that trade fails with insufficient weight
func test_trade_fails_insufficient_weight() -> void:
	var player_item = Item.new()
	player_item.item_name = "Player Item"
	player_item.value = 100
	player_item.weight = 1.0
	player.add_item(player_item)
	
	var heavy_item = Item.new()
	heavy_item.item_name = "Heavy Item"
	heavy_item.value = 100
	heavy_item.weight = 200.0  # Muito pesado
	trader.add_item(heavy_item)
	
	player.stats.carry_weight = 50.0  # Não pode carregar
	
	var player_trade = [player_item]
	var trader_trade = [heavy_item]
	var success = economy_system.execute_trade(player_trade, trader_trade, player, trader)
	
	assert_that(success).is_false("Trade should fail with insufficient weight")
	
	# Verificar que itens não foram transferidos
	assert_that(heavy_item in player.inventory).is_false("Heavy item should not be with player")

## Test that even trade works correctly
func test_even_trade() -> void:
	var player_item = Item.new()
	player_item.item_name = "Player Item"
	player_item.value = 100
	player_item.weight = 1.0
	player.add_item(player_item)
	
	var trader_item = Item.new()
	trader_item.item_name = "Trader Item"
	trader_item.value = 100  # Mesmo valor
	trader_item.weight = 1.0
	trader.add_item(trader_item)
	
	var player_caps_before = player.caps
	var trader_caps_before = trader.caps
	
	var player_trade = [player_item]
	var trader_trade = [trader_item]
	var success = economy_system.execute_trade(player_trade, trader_trade, player, trader)
	
	assert_that(success).is_true("Even trade should succeed")
	
	# Caps não devem mudar significativamente em trade igual
	var caps_difference = abs(player.caps - player_caps_before)
	assert_that(caps_difference).is_less_equal(5,
		"Caps should not change much in even trade")

## Test that multiple items trade correctly
func test_multiple_items_trade() -> void:
	# Criar múltiplos itens
	var player_items: Array[Item] = []
	var trader_items: Array[Item] = []
	
	for i in range(3):
		var p_item = Item.new()
		p_item.item_name = "Player Item %d" % i
		p_item.value = 50
		p_item.weight = 1.0
		player.add_item(p_item)
		player_items.append(p_item)
		
		var t_item = Item.new()
		t_item.item_name = "Trader Item %d" % i
		t_item.value = 75
		t_item.weight = 1.0
		trader.add_item(t_item)
		trader_items.append(t_item)
	
	var success = economy_system.execute_trade(player_items, trader_items, player, trader)
	
	assert_that(success).is_true("Multiple items trade should succeed")
	
	# Verificar que todos os itens foram transferidos
	for item in player_items:
		assert_that(item in trader.inventory).is_true("Player item should be with trader")
	
	for item in trader_items:
		assert_that(item in player.inventory).is_true("Trader item should be with player")

## Test that trade history is recorded
func test_trade_history() -> void:
	var player_item = Item.new()
	player_item.item_name = "Player Item"
	player_item.value = 100
	player_item.weight = 1.0
	player.add_item(player_item)
	
	var trader_item = Item.new()
	trader_item.item_name = "Trader Item"
	trader_item.value = 150
	trader_item.weight = 1.0
	trader.add_item(trader_item)
	
	var history_before = economy_system.trade_history.size()
	
	var player_trade = [player_item]
	var trader_trade = [trader_item]
	economy_system.execute_trade(player_trade, trader_trade, player, trader)
	
	var history_after = economy_system.trade_history.size()
	
	assert_that(history_after).is_equal(history_before + 1,
		"Trade history should be recorded")
