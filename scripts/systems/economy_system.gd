extends Node
class_name EconomySystem
## Sistema de economia e comércio

signal trade_started(trader: Critter)
signal trade_completed(trader: Critter, player_items: Array[Item], trader_items: Array[Item])
signal trade_cancelled(trader: Critter)
signal item_price_calculated(item: Item, base_price: int, final_price: int)

# Configurações de economia
var base_price_multiplier: float = 1.0
var barter_skill_modifier: float = 0.01  # 1% de desconto por ponto de Barter

# Histórico de trades
var trade_history: Array[Dictionary] = []

func _ready() -> void:
	pass

## Calcula preço base de um item
func calculate_base_price(item: Item) -> int:
	if not item:
		return 0
	
	# Preço base do item (se tiver)
	if item.has_method("get_base_price"):
		return item.get_base_price()
	
	# Fallback: calcular baseado em peso e tipo
	var base_price = int(item.weight * 10)
	
	match item.item_type:
		GameConstants.ItemType.WEAPON:
			base_price *= 5
		GameConstants.ItemType.ARMOR:
			base_price *= 4
		GameConstants.ItemType.CONSUMABLE:
			base_price *= 2
		GameConstants.ItemType.AMMO:
			base_price *= 1
		_:
			base_price *= 1
	
	return max(1, base_price)

## Calcula preço final considerando modificadores
func calculate_final_price(item: Item, buyer: Critter, seller: Critter, is_buying: bool) -> int:
	if not item or not buyer or not seller:
		return 0
	
	var base_price = calculate_base_price(item)
	var final_price = float(base_price)
	
	# Modificador de Barter skill
	if buyer.skills:
		var barter_skill = buyer.skills.get_skill_value(SkillData.Skill.BARTER)
		var barter_modifier = float(barter_skill) * barter_skill_modifier
		
		if is_buying:
			# Comprar: Barter reduz preço
			final_price *= (1.0 - barter_modifier)
		else:
			# Vender: Barter aumenta preço recebido
			final_price *= (1.0 + barter_modifier * 0.5)  # Vender tem menos impacto
	
	# Modificador de reputação (se seller tem facção)
	if seller.faction != "" and seller.faction != "neutral":
		var reputation_modifier = _get_reputation_price_modifier(buyer, seller.faction)
		final_price *= reputation_modifier
	
	# Se buyer tem facção, também aplicar modificador
	if buyer.faction != "" and buyer.faction != "neutral" and buyer.faction == seller.faction:
		# Mesma facção: desconto adicional
		final_price *= 0.9  # 10% desconto
	
	# Aplicar multiplicador base
	final_price *= base_price_multiplier
	
	# Arredondar para inteiro
	var final = int(final_price)
	final = max(1, final)  # Mínimo 1 cap
	
	item_price_calculated.emit(item, base_price, final)
	return final

## Obtém modificador de preço baseado em reputação
func _get_reputation_price_modifier(buyer: Critter, faction: String) -> float:
	# TODO: Integrar com sistema de reputação quando disponível
	# Por enquanto, retorna 1.0 (sem modificador)
	# Em implementação completa:
	# - Reputação muito alta: 0.8 (20% desconto)
	# - Reputação alta: 0.9 (10% desconto)
	# - Reputação neutra: 1.0 (preço normal)
	# - Reputação baixa: 1.1 (10% markup)
	# - Reputação muito baixa: 1.2 (20% markup)
	return 1.0

## Calcula valor total de uma lista de itens
func calculate_total_value(items: Array[Item], buyer: Critter, seller: Critter, is_buying: bool) -> int:
	var total = 0
	for item in items:
		if item:
			total += calculate_final_price(item, buyer, seller, is_buying)
	return total

## Verifica se um trade é válido
func validate_trade(player_items: Array[Item], trader_items: Array[Item], 
				   player: Critter, trader: Critter, player_caps: int, trader_caps: int) -> Dictionary:
	var result = {
		"valid": true,
		"errors": [],
		"player_pays": 0,
		"trader_pays": 0
	}
	
	# Calcular valores
	var player_items_value = calculate_total_value(player_items, trader, player, false)  # Player vende
	var trader_items_value = calculate_total_value(trader_items, player, trader, true)   # Player compra
	
	# Calcular diferença
	var difference = trader_items_value - player_items_value
	
	if difference > 0:
		# Player precisa pagar
		result.player_pays = difference
		if player_caps < difference:
			result.valid = false
			result.errors.append("Player doesn't have enough caps")
	else:
		# Trader precisa pagar (ou troca igual)
		result.trader_pays = -difference
		if trader_caps < -difference:
			result.valid = false
			result.errors.append("Trader doesn't have enough caps")
	
	# Verificar peso do player
	var total_weight = 0.0
	for item in trader_items:
		if item:
			total_weight += item.weight
	
	var current_weight = _calculate_inventory_weight(player)
	if current_weight + total_weight > player.stats.carry_weight:
		result.valid = false
		result.errors.append("Player doesn't have enough carry weight")
	
	# Verificar limite de caps do trader
	if difference < 0:  # Trader precisa pagar
		var trader_pays = -difference
		if not check_trader_cap_limit(trader, trader_pays):
			result.valid = false
			result.errors.append("Trader doesn't have enough caps (limit exceeded)")
	
	return result

## Calcula peso total do inventário
func _calculate_inventory_weight(critter: Critter) -> float:
	var total = 0.0
	for item in critter.inventory:
		if item:
			total += item.weight
	return total

## Executa um trade
func execute_trade(player_items: Array[Item], trader_items: Array[Item],
				  player: Critter, trader: Critter) -> bool:
	if not player or not trader:
		return false
	
	# Validar trade
	var validation = validate_trade(player_items, trader_items, player, trader, 
								   player.caps, trader.caps)
	
	if not validation.valid:
		push_warning("EconomySystem: Trade validation failed: %s" % str(validation.errors))
		return false
	
	# Transferir itens
	for item in player_items:
		if item and item in player.inventory:
			player.remove_item(item)
			trader.add_item(item)
	
	for item in trader_items:
		if item and item in trader.inventory:
			trader.remove_item(item)
			player.add_item(item)
	
	# Transferir caps
	if validation.player_pays > 0:
		player.caps -= validation.player_pays
		trader.caps += validation.player_pays
	elif validation.trader_pays > 0:
		trader.caps -= validation.trader_pays
		player.caps += validation.trader_pays
	
	# Registrar no histórico
	trade_history.append({
		"timestamp": Time.get_unix_time_from_system(),
		"player": player.critter_name,
		"trader": trader.critter_name,
		"player_items": player_items.duplicate(),
		"trader_items": trader_items.duplicate(),
		"player_paid": validation.player_pays,
		"trader_paid": validation.trader_pays
	})
	
	trade_completed.emit(trader, player_items, trader_items)
	return true

## Verifica se player pode comprar item
func can_afford_item(item: Item, player: Critter, trader: Critter) -> bool:
	if not item or not player or not trader:
		return false
	
	var price = calculate_final_price(item, player, trader, true)
	return player.caps >= price

## Verifica se trader tem caps suficientes
func trader_has_caps(trader: Critter, amount: int) -> bool:
	if not trader:
		return false
	return trader.caps >= amount

## Obtém limite de caps do trader
func get_trader_cap_limit(trader: Critter) -> int:
	if not trader:
		return 0
	
	# Limite padrão baseado no tipo de trader
	# TODO: Configurar limites por tipo de trader
	# Por enquanto, usar caps atuais como limite
	return trader.caps

## Verifica se trade excede limite de caps do trader
func check_trader_cap_limit(trader: Critter, required_caps: int) -> bool:
	if not trader:
		return false
	
	var limit = get_trader_cap_limit(trader)
	return required_caps <= limit

## Tenta roubar item de um trader
func attempt_steal(item: Item, player: Critter, trader: Critter) -> Dictionary:
	var result = {
		"success": false,
		"caught": false,
		"message": ""
	}
	
	if not item or not player or not trader:
		result.message = "Invalid steal attempt"
		return result
	
	# Verificar se item está no inventário do trader
	if not item in trader.inventory:
		result.message = "Item not in trader inventory"
		return result
	
	# Roll de Steal skill vs Perception do trader
	var steal_skill = player.skills.get_skill_value(SkillData.Skill.STEAL) if player.skills else 0
	var trader_perception = trader.stats.perception if trader.stats else 5
	
	# Chance de sucesso: Steal skill - (Perception * 10)
	var success_chance = float(steal_skill) - (float(trader_perception) * 10.0)
	success_chance = clamp(success_chance, 5.0, 95.0)  # Entre 5% e 95%
	
	var roll = randf() * 100.0
	
	if roll <= success_chance:
		# Sucesso: transferir item
		trader.remove_item(item)
		player.add_item(item)
		result.success = true
		result.message = "Successfully stole %s" % item.item_name
	else:
		# Falhou: foi pego
		result.caught = true
		result.message = "Caught stealing! Reputation decreased."
		
		# Aplicar consequências
		_apply_stealing_consequences(player, trader)
	
	return result

## Aplica consequências de ser pego roubando
func _apply_stealing_consequences(player: Critter, trader: Critter) -> void:
	# Reduzir karma
	player.karma -= 10
	
	# Reduzir reputação com facção do trader
	if trader.faction != "" and trader.faction != "neutral":
		# TODO: Integrar com sistema de reputação
		pass
	
	# Trader pode ficar hostil
	# TODO: Implementar sistema de hostilidade
