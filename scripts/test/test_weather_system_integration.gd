## Test: WeatherSystem Integration
## Testes de integração para o sistema de clima

class_name TestWeatherSystemIntegration
extends GdUnitTestSuite

var weather_system: WeatherSystem
var citizen_system: CitizenSystem
var building_system: BuildingSystem
var event_bus: CityEventBus

func before_each() -> void:
	# Criar sistemas
	weather_system = WeatherSystem.new()
	citizen_system = CitizenSystem.new()
	building_system = BuildingSystem.new()
	event_bus = CityEventBus.new()
	
	# Configurar sistemas
	var config = CityConfig.new()
	weather_system.set_config(config)
	citizen_system.set_config(config)
	building_system.set_config(config)
	
	# Conectar sistemas
	weather_system.set_systems(citizen_system, building_system, event_bus)
	
	# Inicializar
	weather_system._ready()

func after_each() -> void:
	weather_system.clear()

func test_initial_weather() -> void:
	"""Test: Clima inicial deve ser limpo"""
	var current = weather_system.get_current_weather()
	
	assert_that(current.type).is_equal(WeatherSystem.WeatherType.CLEAR)
	assert_that(current.visibility).is_equal(1.0)
	assert_that(current.movement_modifier).is_equal(1.0)

func test_set_weather() -> void:
	"""Test: Definir clima"""
	weather_system.set_weather(WeatherSystem.WeatherType.DUST_STORM, 0.8, 300.0, 0.0)
	
	var current = weather_system.get_current_weather()
	assert_that(current.type).is_equal(WeatherSystem.WeatherType.DUST_STORM)
	assert_that(current.intensity).is_equal(0.8)

func test_weather_effects_dust_storm() -> void:
	"""Test: Efeitos de tempestade de poeira"""
	weather_system.force_weather(WeatherSystem.WeatherType.DUST_STORM, 0.7, 300.0)
	
	var current = weather_system.get_current_weather()
	assert_that(current.visibility).is_less_than(0.5)
	assert_that(current.movement_modifier).is_less_than(1.0)
	assert_that(current.radiation).is_equal(0.0)

func test_weather_effects_rad_storm() -> void:
	"""Test: Efeitos de tempestade radioativa"""
	weather_system.force_weather(WeatherSystem.WeatherType.RAD_STORM, 0.8, 300.0)
	
	var current = weather_system.get_current_weather()
	assert_that(current.radiation).is_greater_than(0.0)
	assert_that(current.damage_per_second).is_greater_than(0.0)

func test_weather_effects_acid_rain() -> void:
	"""Test: Efeitos de chuva ácida"""
	weather_system.force_weather(WeatherSystem.WeatherType.ACID_RAIN, 0.6, 300.0)
	
	var current = weather_system.get_current_weather()
	assert_that(current.damage_per_second).is_greater_than(0.0)
	assert_that(current.radiation).is_equal(0.0)

func test_is_weather_hazardous() -> void:
	"""Test: Detectar clima perigoso"""
	# Clima seguro
	weather_system.force_weather(WeatherSystem.WeatherType.CLEAR, 0.5, 300.0)
	assert_that(weather_system.is_weather_hazardous()).is_false()
	
	# Clima perigoso
	weather_system.force_weather(WeatherSystem.WeatherType.RAD_STORM, 0.8, 300.0)
	assert_that(weather_system.is_weather_hazardous()).is_true()

func test_day_night_cycle() -> void:
	"""Test: Ciclo dia/noite"""
	weather_system.set_time(12, 1)
	
	assert_that(weather_system.get_time_of_day()).is_equal(12)
	assert_that(weather_system.is_daytime()).is_true()
	assert_that(weather_system.is_nighttime()).is_false()
	
	# Mudar para noite
	weather_system.set_time(22, 1)
	assert_that(weather_system.is_nighttime()).is_true()
	assert_that(weather_system.is_daytime()).is_false()

func test_time_progression() -> void:
	"""Test: Progressão do tempo"""
	weather_system.set_time(10, 1)
	weather_system.set_time_scale(1.0)
	
	# Simular 1 hora (60 segundos no jogo)
	for i in range(60):
		weather_system.update(1.0)
	
	assert_that(weather_system.get_time_of_day()).is_equal(11)

func test_day_change() -> void:
	"""Test: Mudança de dia"""
	weather_system.set_time(23, 1)
	
	# Simular 1 hora para passar para o próximo dia
	for i in range(60):
		weather_system.update(1.0)
	
	assert_that(weather_system.get_time_of_day()).is_equal(0)
	assert_that(weather_system.get_current_day()).is_equal(2)

func test_visibility_at_night() -> void:
	"""Test: Visibilidade reduzida à noite"""
	# Dia
	weather_system.set_time(12, 1)
	weather_system.force_weather(WeatherSystem.WeatherType.CLEAR, 0.5, 300.0)
	var day_visibility = weather_system.get_visibility()
	
	# Noite
	weather_system.set_time(22, 1)
	var night_visibility = weather_system.get_visibility()
	
	assert_that(night_visibility).is_less_than(day_visibility)

func test_time_scale() -> void:
	"""Test: Escala de tempo"""
	weather_system.set_time_scale(2.0)
	assert_that(weather_system.get_time_scale()).is_equal(2.0)
	
	weather_system.set_time(10, 1)
	
	# Com escala 2x, 30 segundos devem passar 1 hora
	for i in range(30):
		weather_system.update(1.0)
	
	assert_that(weather_system.get_time_of_day()).is_equal(11)

func test_weather_statistics() -> void:
	"""Test: Estatísticas do clima"""
	weather_system.force_weather(WeatherSystem.WeatherType.DUST_STORM, 0.7, 300.0)
	weather_system.set_time(14, 5)
	
	var stats = weather_system.get_weather_statistics()
	
	assert_that(stats["weather_type"]).is_equal(WeatherSystem.WeatherType.DUST_STORM)
	assert_that(stats["intensity"]).is_equal(0.7)
	assert_that(stats["current_hour"]).is_equal(14)
	assert_that(stats["current_day"]).is_equal(5)
	assert_that(stats["is_daytime"]).is_true()

func test_weather_names() -> void:
	"""Test: Nomes dos climas"""
	assert_that(weather_system.get_weather_name(WeatherSystem.WeatherType.CLEAR)).is_equal("Céu Limpo")
	assert_that(weather_system.get_weather_name(WeatherSystem.WeatherType.RAD_STORM)).is_equal("Tempestade Radioativa")
	assert_that(weather_system.get_weather_name(WeatherSystem.WeatherType.ACID_RAIN)).is_equal("Chuva Ácida")

func test_time_string() -> void:
	"""Test: String de tempo formatada"""
	weather_system.set_time(9, 1)
	assert_that(weather_system.get_time_string()).is_equal("09:00")
	
	weather_system.set_time(15, 1)
	assert_that(weather_system.get_time_string()).is_equal("15:00")

func test_day_progress() -> void:
	"""Test: Progresso do dia"""
	weather_system.set_time(0, 1)
	assert_that(weather_system.get_day_progress()).is_equal(0.0)
	
	weather_system.set_time(12, 1)
	assert_that(weather_system.get_day_progress()).is_equal(0.5)
	
	weather_system.set_time(23, 1)
	var progress = weather_system.get_day_progress()
	assert_that(progress).is_greater_than(0.9)

func test_auto_weather_changes() -> void:
	"""Test: Mudanças automáticas de clima"""
	weather_system.enable_auto_weather(true)
	weather_system.set_weather_change_interval(100.0)
	
	var initial_weather = weather_system.get_current_weather().type
	
	# Simular tempo suficiente para mudança
	for i in range(110):
		weather_system.update(1.0)
	
	# Clima pode ter mudado (não garantido devido à aleatoriedade)
	# Apenas verificar que o sistema não crashou
	var current_weather = weather_system.get_current_weather()
	assert_that(current_weather).is_not_null()

func test_disable_auto_weather() -> void:
	"""Test: Desativar mudanças automáticas"""
	weather_system.enable_auto_weather(false)
	weather_system.force_weather(WeatherSystem.WeatherType.CLEAR, 0.5, 300.0)
	
	var initial_weather = weather_system.get_current_weather().type
	
	# Simular muito tempo
	for i in range(200):
		weather_system.update(1.0)
	
	# Clima não deve ter mudado automaticamente
	assert_that(weather_system.get_current_weather().type).is_equal(initial_weather)

func test_weather_duration() -> void:
	"""Test: Duração do clima"""
	weather_system.force_weather(WeatherSystem.WeatherType.DUST_STORM, 0.5, 10.0)
	
	# Simular 15 segundos
	for i in range(15):
		weather_system.update(1.0)
	
	# Clima deve ter voltado ao normal
	assert_that(weather_system.get_current_weather().type).is_equal(WeatherSystem.WeatherType.CLEAR)

func test_clear_system() -> void:
	"""Test: Limpar sistema"""
	weather_system.force_weather(WeatherSystem.WeatherType.RAD_STORM, 0.8, 300.0)
	weather_system.set_time(20, 10)
	
	weather_system.clear()
	
	assert_that(weather_system.get_current_weather().type).is_equal(WeatherSystem.WeatherType.CLEAR)
	assert_that(weather_system.get_time_of_day()).is_equal(12)
	assert_that(weather_system.get_current_day()).is_equal(1)
