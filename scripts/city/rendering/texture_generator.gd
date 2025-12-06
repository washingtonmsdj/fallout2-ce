## TextureGenerator - Gera texturas procedurais para o renderer
## Cria texturas simples para terreno, edifícios, etc.
class_name TextureGenerator
extends RefCounted

## Gera textura de grama com variação
static func generate_grass_texture(size: int = 64) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGB8)
	
	var base_color = Color(0.79, 0.88, 0.67)
	
	for y in range(size):
		for x in range(size):
			# Adicionar ruído
			var noise = (sin(x * 0.5) * cos(y * 0.5) + randf_range(-0.1, 0.1)) * 0.1
			var color = base_color.lightened(noise)
			image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

## Gera textura de asfalto
static func generate_asphalt_texture(size: int = 64) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGB8)
	
	var base_color = Color(0.3, 0.3, 0.3)
	
	for y in range(size):
		for x in range(size):
			# Ruído para dar textura
			var noise = randf_range(-0.05, 0.05)
			var color = base_color.lightened(noise)
			image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

## Gera textura de parede de tijolo
static func generate_brick_texture(size: int = 64) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGB8)
	
	var brick_color = Color(0.72, 0.45, 0.35)
	var mortar_color = Color(0.6, 0.55, 0.5)
	
	var brick_height = 8
	var brick_width = 16
	
	for y in range(size):
		for x in range(size):
			var row = int(y / brick_height)
			var offset = (row % 2) * (brick_width / 2)
			var brick_x = (x + offset) % brick_width
			var brick_y = y % brick_height
			
			# Juntas de argamassa
			if brick_x < 2 or brick_y < 2:
				image.set_pixel(x, y, mortar_color)
			else:
				var noise = randf_range(-0.05, 0.05)
				image.set_pixel(x, y, brick_color.lightened(noise))
	
	return ImageTexture.create_from_image(image)

## Gera textura de concreto
static func generate_concrete_texture(size: int = 64) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGB8)
	
	var base_color = Color(0.7, 0.7, 0.68)
	
	for y in range(size):
		for x in range(size):
			var noise = randf_range(-0.1, 0.1)
			var color = base_color.lightened(noise)
			image.set_pixel(x, y, color)
	
	return ImageTexture.create_from_image(image)

## Gera sprite de árvore simples
static func generate_tree_sprite(size: int = 32) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # Transparente
	
	var trunk_color = Color(0.4, 0.3, 0.2)
	var canopy_color = Color(0.3, 0.6, 0.2)
	
	var center_x = size / 2
	var center_y = size / 2
	
	# Tronco
	for y in range(int(size * 0.6), size):
		for x in range(center_x - 2, center_x + 3):
			if x >= 0 and x < size and y >= 0 and y < size:
				image.set_pixel(x, y, trunk_color)
	
	# Copa (círculo)
	var radius = size * 0.35
	for y in range(size):
		for x in range(size):
			var dx = x - center_x
			var dy = y - (center_y - 4)
			if dx * dx + dy * dy < radius * radius:
				var noise = randf_range(-0.1, 0.1)
				image.set_pixel(x, y, canopy_color.lightened(noise))
	
	return ImageTexture.create_from_image(image)

## Gera sprite de carro simples
static func generate_car_sprite(size: int = 24, car_color: Color = Color.RED) -> ImageTexture:
	var image = Image.create(size, int(size * 0.6), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	var body_color = car_color
	var window_color = Color(0.3, 0.4, 0.5, 0.8)
	var wheel_color = Color(0.1, 0.1, 0.1)
	
	var width = size
	var height = int(size * 0.6)
	
	# Corpo do carro
	for y in range(int(height * 0.3), height):
		for x in range(2, width - 2):
			image.set_pixel(x, y, body_color)
	
	# Janelas
	for y in range(int(height * 0.15), int(height * 0.4)):
		for x in range(int(width * 0.3), int(width * 0.7)):
			image.set_pixel(x, y, window_color)
	
	# Rodas
	var wheel_y = height - 2
	for x in [int(width * 0.2), int(width * 0.8)]:
		for dy in range(-2, 3):
			for dx in range(-2, 3):
				var px = x + dx
				var py = wheel_y + dy
				if px >= 0 and px < width and py >= 0 and py < height:
					if dx * dx + dy * dy < 4:
						image.set_pixel(px, py, wheel_color)
	
	return ImageTexture.create_from_image(image)

## Gera sprite de pessoa simples
static func generate_person_sprite(size: int = 16) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	var skin_color = Color(0.9, 0.75, 0.6)
	var body_color = Color(0.2, 0.35, 0.65)  # Vault suit
	
	var center_x = size / 2
	
	# Cabeça
	var head_radius = size * 0.2
	var head_y = int(size * 0.25)
	for y in range(size):
		for x in range(size):
			var dx = x - center_x
			var dy = y - head_y
			if dx * dx + dy * dy < head_radius * head_radius:
				image.set_pixel(x, y, skin_color)
	
	# Corpo
	for y in range(int(size * 0.4), int(size * 0.8)):
		for x in range(center_x - 3, center_x + 4):
			if x >= 0 and x < size:
				image.set_pixel(x, y, body_color)
	
	# Pernas
	for y in range(int(size * 0.8), size):
		image.set_pixel(center_x - 2, y, Color(0.25, 0.25, 0.3))
		image.set_pixel(center_x + 2, y, Color(0.25, 0.25, 0.3))
	
	return ImageTexture.create_from_image(image)
