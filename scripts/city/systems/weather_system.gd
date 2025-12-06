## WeatherSystem - Sistema de clima e ciclo dia/noite
## Gerencia condições climáticas e seus efeitos na cidade
class_name WeatherSystem
extends Node

# Enum para tipos de clima
enum WeatherType {
	CLEAR,          # Céu limpo
	CLOUDY,         # Nublado
	DUST_STORM,     # Tempestade de poeira
	RAD_STORM,      # Tempestade radioativa
	ACID_RAIN,      # Chuva ácida
	HEAT_WAVE,      # Onda de calor
	COLD_SNAP       # Onda de frio
}

# Classe para dados do clima
class WeatherData:
	var type: int = WeatherType.CLEAR
	var intensity: float = 0.5  # 0-1
	var duration: float = 0.0  # Segundos restantes
	var visibility: float = 1.0  # 0-1
	var movement_modifier: float = 1.0  # Multiplicador de velocidade
	var radiation: float = 0.0  # Rads por segundo
	var damage_per_second: float = 0.0
	
	func _init(p_type: int = WeatherType.CLEAR, p_intensity: float = 0.5, p_duration: float = 300.0) -> void:
		type = p_type
		intensity = clamp(p_intensity, 0.0, 1.0)
		duration = p_duration
		_update_effects()
	
	func _update_effects() -> void:
		"""Atualiza os efeitos baseados no tipo e intensidade"""
		match type:
			WeatherType.CLEAR:
				visibility = 1.0
				movement_modifier = 1.0
				radiation = 0.0
				damage_per_second = 0.0
			
			WeatherType.CLOUDY:
				visibility = 0.8
				movement_modifier = 1.0
				radiation = 0.0
				damage_per_second = 0.0
			
			WeatherType.DUST_STORM:
				visibility = 0.3 * (1.0 - intensity * 0.5)
				movement_modifier = 0.6 * (1.0 - intensity * 0.3)
				radiation = 0.0
				damage_per_second = 0.0
			
			WeatherType.RAD_STORM:
				visibility = 0.5 * (1.0 - intensity * 0.3)
				movement_modifier = 0.8
				radiation = 5.0 * intensity
				damage_per_second = 0.5 * intensity
			
			WeatherType.ACID_RAIN:
				visibility = 0.6
				movement_modifier = 0.7
				radiation = 0.0
				damage_per_second = 1.0 * intensity
			
			WeatherType.HEAT_WAVE:
				visibility = 0.9
				movement_modifier = 0.8 * (1.0 - intensity * 0.2)
				radiation = 0.0
				damage_per_second = 0.2 * intensity
			
			WeatherType.COLD_SNAP:
				visibility = 0.7
				movement_modifier = 0.7 * (1.0 - intensity * 0.2)
				radiation = 0.0
				damage_per_second = 0.3 * intensity

# Estado atual
var current_weather: WeatherData
var next_weather: WeatherData
var transition_time: float = 0.0
var is_transitioning: bool = false

# Ciclo dia/noite
var current_hour: int = 12  # 0-23
var current_day: int = 1
var time_scale: float = 1.0  # Multiplicador de velocidade do tempo
var hour_length: float = 60.0  # Segundos por hora no jogo
var accumulated_time: float = 0.0

# Configuração
var weather_change_interval: float = 600.0  # Segundos entre mudanças de clima
var weather_change_timer: float = 0.0
var auto_weather_changes: bool = true

# Sistemas
var citizen_system
var building_system
var event_bus
var config

# Estatísticas
var total_radiation_damage: float = 0.0
var citizens_in_shelter: int = 0

func _ready() -> void:
	current_weather = WeatherData.new(WeatherType.CLEAR, 0.5, 600.0)
	next_weather = WeatherData.new(WeatherType.CLEAR, 0.5, 600.0)

func set_config(cfg) -> void:
	config = cfg
	if config == null:
		config = CityConfig.new()
	
	# Usar configurações do CityConfig se disponíveis
	if config.has("HOUR_LENGTH_SECONDS"):
		hour_length = config.HOUR_LENGTH_SECONDS

func set_systems(citizens, buildings, bus) -> void:
	"""Define as referências aos sistemas"""
	citizen_system = citizens
	building_system = buildings
	event_bus = bus

func update(delta: float) -> void:
	"""Atualiza o sistema de clima (deve ser chamado a cada frame)"""
	# Atualizar ciclo dia/noite
	_update_day_night_cycle(delta)
	
	# Atualizar clima
	_update_weather(delta)
	
	# Aplicar efeitos do clima
	_apply_weather_effects(delta)
	
	# Verificar mudanças automáticas de clima
	if auto_weather_changes:
		weather_change_timer += delta
		if weather_change_timer >= weather_change_interval:
			weather_change_timer = 0.0
			_trigger_random_weather()

func _update_day_night_cycle(delta: float) -> void:
	"""Atualiza o ciclo dia/noite"""
	accumulated_time += delta * time_scale
	
	if accumulated_time >= hour_length:
		accumulated_time -= hour_length
		var old_hour = current_hour
		current_hour = (current_hour + 1) % 24
		
		# Emitir evento de mudança de hora
		if event_bus != null:
			event_bus.time_of_day_changed.emit(old_hour, current_hour)
		
		# Novo dia
		if current_hour == 0:
			var old_day = current_day
			current_day += 1
			if event_bus != null:
				event_bus.day_changed.emit(old_day, current_day)

func _update_weather(delta: float) -> void:
	"""Atualiza o estado do clima"""
	if is_transitioning:
		transition_time -= delta
		if transition_time <= 0.0:
			is_transitioning = false
			current_weather = next_weather
			next_weather = WeatherData.new(current_weather.type, current_weather.intensity, current_weather.duration)
	
	# Reduzir duração do clima atual
	current_weather.duration -= delta
	if current_weather.duration <= 0.0 and not is_transitioning:
		# Clima expirou, voltar ao normal
		set_weather(WeatherType.CLEAR, 0.5, 600.0)

func _apply_weather_effects(delta: float) -> void:
	"""Aplica os efeitos do clima aos cidadãos e edifícios"""
	if citizen_system == null:
		return
	
	# Resetar contador de cidadãos em abrigo
	citizens_in_shelter = 0
	
	# Verificar se o clima é perigoso
	var is_hazardous = current_weather.damage_per_second > 0.0 or current_weather.radiation > 0.0
	
	# Para cada cidadão
	var all_citizens = citizen_system.get_all_citizens()
	for citizen in all_citizens:
		# Se clima perigoso, cidadão deve buscar abrigo
		if is_hazardous:
			# Verificar se está em um edifício
			var is_sheltered = _is_citizen_sheltered(citizen.id)
			
			if is_sheltered:
				citizens_in_shelter += 1
			else:
				# Aplicar dano
				if current_weather.damage_per_second > 0.0:
					var damage = current_weather.damage_per_second * delta
					citizen_system.update_citizen_need(citizen.id, CityConfig.NeedType.HEALTH, -damage)
					total_radiation_damage += damage
				
				# Aplicar radiação
				if current_weather.radiation > 0.0:
					var rad_damage = current_weather.radiation * delta * 0.1
					citizen_system.update_citizen_need(citizen.id, CityConfig.NeedType.HEALTH, -rad_damage)
					total_radiation_damage += rad_damage
				
				# Aumentar medo/reduzir segurança
				citizen_system.update_citizen_need(citizen.id, CityConfig.NeedType.SAFETY, -0.5 * delta)

func _is_citizen_sheltered(citizen_id: int) -> bool:
	"""Verifica se um cidadão está abrigado"""
	if building_system == null or citizen_system == null:
		return false
	
	var citizen = citizen_system.get_citizen(citizen_id)
	if citizen == null:
		return false
	
	# Verificar se está em um edifício
	var building_id = building_system.get_building_at_tile(citizen.grid_position)
	return building_id >= 0

func set_weather(weather_type: int, intensity: float = 0.5, duration: float = 300.0, transition_duration: float = 10.0) -> void:
	"""Define o clima atual"""
	var old_weather = current_weather.type
	
	next_weather = WeatherData.new(weather_type, intensity, duration)
	
	if transition_duration > 0.0:
		is_transitioning = true
		transition_time = transition_duration
	else:
		current_weather = next_weather
		next_weather = WeatherData.new(weather_type, intensity, duration)
	
	# Emitir evento
	if event_bus != null:
		event_bus.weather_changed.emit(old_weather, weather_type, intensity)

func _trigger_random_weather() -> void:
	"""Dispara uma mudança aleatória de clima"""
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# Pesos para cada tipo de clima
	var weather_weights = {
		WeatherType.CLEAR: 40,
		WeatherType.CLOUDY: 25,
		WeatherType.DUST_STORM: 15,
		WeatherType.RAD_STORM: 5,
		WeatherType.ACID_RAIN: 5,
		WeatherType.HEAT_WAVE: 5,
		WeatherType.COLD_SNAP: 5
	}
	
	# Selecionar clima baseado em pesos
	var total_weight = 0
	for weight in weather_weights.values():
		total_weight += weight
	
	var random_value = rng.randi_range(0, total_weight - 1)
	var accumulated_weight = 0
	var selected_weather = WeatherType.CLEAR
	
	for weather_type in weather_weights.keys():
		accumulated_weight += weather_weights[weather_type]
		if random_value < accumulated_weight:
			selected_weather = weather_type
			break
	
	# Intensidade e duração aleatórias
	var intensity = rng.randf_range(0.3, 0.9)
	var duration = rng.randf_range(300.0, 900.0)  # 5-15 minutos
	
	set_weather(selected_weather, intensity, duration, 10.0)

func get_current_weather() -> WeatherData:
	"""Retorna os dados do clima atual"""
	return current_weather

func get_time_of_day() -> int:
	"""Retorna a hora atual (0-23)"""
	return current_hour

func get_current_day() -> int:
	"""Retorna o dia atual"""
	return current_day

func is_daytime() -> bool:
	"""Verifica se é dia"""
	return current_hour >= 6 and current_hour < 20

func is_nighttime() -> bool:
	"""Verifica se é noite"""
	return not is_daytime()

func get_visibility() -> float:
	"""Retorna a visibilidade atual (0-1)"""
	var weather_visibility = current_weather.visibility
	
	# Reduzir visibilidade à noite
	if is_nighttime():
		weather_visibility *= 0.6
	
	return weather_visibility

func get_movement_modifier() -> float:
	"""Retorna o modificador de movimento atual"""
	return current_weather.movement_modifier

func get_radiation_level() -> float:
	"""Retorna o nível de radiação atual"""
	return current_weather.radiation

func get_damage_per_second() -> float:
	"""Retorna o dano por segundo do clima"""
	return current_weather.damage_per_second

func is_weather_hazardous() -> bool:
	"""Verifica se o clima é perigoso"""
	return current_weather.damage_per_second > 0.0 or current_weather.radiation > 0.0

func force_weather(weather_type: int, intensity: float = 0.5, duration: float = 300.0) -> void:
	"""Força um clima específico imediatamente"""
	set_weather(weather_type, intensity, duration, 0.0)

func set_time(hour: int, day: int = -1) -> void:
	"""Define a hora atual"""
	current_hour = clamp(hour, 0, 23)
	if day >= 0:
		current_day = day
	accumulated_time = 0.0

func set_time_scale(scale: float) -> void:
	"""Define a escala de tempo (velocidade)"""
	time_scale = max(0.0, scale)

func get_time_scale() -> float:
	"""Retorna a escala de tempo atual"""
	return time_scale

func get_weather_statistics() -> Dictionary:
	"""Retorna estatísticas do clima"""
	return {
		"current_weather": get_weather_name(current_weather.type),
		"weather_type": current_weather.type,
		"intensity": current_weather.intensity,
		"duration_remaining": current_weather.duration,
		"visibility": get_visibility(),
		"movement_modifier": current_weather.movement_modifier,
		"radiation": current_weather.radiation,
		"damage_per_second": current_weather.damage_per_second,
		"is_hazardous": is_weather_hazardous(),
		"current_hour": current_hour,
		"current_day": current_day,
		"is_daytime": is_daytime(),
		"citizens_in_shelter": citizens_in_shelter,
		"total_radiation_damage": total_radiation_damage
	}

func get_weather_name(weather_type: int) -> String:
	"""Retorna o nome do tipo de clima"""
	match weather_type:
		WeatherType.CLEAR:
			return "Céu Limpo"
		WeatherType.CLOUDY:
			return "Nublado"
		WeatherType.DUST_STORM:
			return "Tempestade de Poeira"
		WeatherType.RAD_STORM:
			return "Tempestade Radioativa"
		WeatherType.ACID_RAIN:
			return "Chuva Ácida"
		WeatherType.HEAT_WAVE:
			return "Onda de Calor"
		WeatherType.COLD_SNAP:
			return "Onda de Frio"
		_:
			return "Desconhecido"

func get_time_string() -> String:
	"""Retorna a hora atual como string formatada"""
	return "%02d:00" % current_hour

func get_day_progress() -> float:
	"""Retorna o progresso do dia (0-1)"""
	return (current_hour + (accumulated_time / hour_length)) / 24.0

func enable_auto_weather(enabled: bool) -> void:
	"""Ativa/desativa mudanças automáticas de clima"""
	auto_weather_changes = enabled

func set_weather_change_interval(interval: float) -> void:
	"""Define o intervalo entre mudanças de clima"""
	weather_change_interval = max(60.0, interval)

func clear() -> void:
	"""Limpa todos os dados do sistema"""
	current_weather = WeatherData.new(WeatherType.CLEAR, 0.5, 600.0)
	next_weather = WeatherData.new(WeatherType.CLEAR, 0.5, 600.0)
	transition_time = 0.0
	is_transitioning = false
	current_hour = 12
	current_day = 1
	accumulated_time = 0.0
	weather_change_timer = 0.0
	total_radiation_damage = 0.0
	citizens_in_shelter = 0
