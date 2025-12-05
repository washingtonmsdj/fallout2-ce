#!/usr/bin/env python3
"""
Converte TODOS os mapas do Fallout 2 para JSON e gera cenas Godot.

Este script:
1. Lê todos os arquivos .MAP do DAT
2. Extrai tiles, objetos, NPCs
3. Gera arquivos JSON para cada mapa
4. Gera cenas .tscn para o Godot
"""

import os
import sys
import json
import struct
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, asdict

# Adicionar diretório de extractors ao path
sys.path.insert(0, str(Path(__file__).parent))

try:
    from extractors.dat2_reader import DAT2Reader
except ImportError:
    DAT2Reader = None


@dataclass
class TileInfo:
    """Informação de um tile."""
    floor_id: int
    roof_id: int
    x: int
    y: int
    elevation: int


@dataclass
class ObjectInfo:
    """Informação de um objeto no mapa."""
    pid: int
    x: int
    y: int
    elevation: int
    orientation: int
    script_id: int
    object_type: str  # item, critter, scenery, wall, misc


@dataclass
class MapInfo:
    """Informação completa de um mapa."""
    name: str
    filename: str
    version: int
    width: int
    height: int
    num_levels: int
    entering_tile: int
    entering_elevation: int
    entering_rotation: int
    tiles: List[TileInfo]
    objects: List[ObjectInfo]
    script_name: str


class FullMapParser:
    """Parser completo de mapas do Fallout 2."""
    
    MAP_WIDTH = 100
    MAP_HEIGHT = 100
    TILES_PER_LEVEL = MAP_WIDTH * MAP_HEIGHT
    
    # Tipos de objeto baseados no PID
    OBJECT_TYPES = {
        0: "item",
        1: "critter", 
        2: "scenery",
        3: "wall",
        4: "tile",
        5: "misc"
    }
    
    def __init__(self):
        self.maps_converted = 0
        self.errors = []
    
    def parse_map(self, data: bytes, filename: str) -> Optional[MapInfo]:
        """Parseia um arquivo MAP completo."""
        try:
            offset = 0
            
            # Header (versão)
            version = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            # Nome do mapa (16 bytes, null-terminated)
            name_bytes = data[offset:offset+16]
            name = name_bytes.split(b'\x00')[0].decode('latin-1', errors='ignore').strip()
            if not name:
                name = Path(filename).stem
            offset += 16
            
            # Posição de entrada
            entering_tile = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            entering_elevation = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            entering_rotation = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            # Variáveis locais
            local_vars = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            # Script index
            script_index = struct.unpack('>i', data[offset:offset+4])[0]
            offset += 4
            
            # Flags
            flags = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            # Darkness
            darkness = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            # Global vars
            global_vars = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            # Map ID
            map_id = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            # Timestamp
            timestamp = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            # Pular campos reservados (44 * 4 = 176 bytes)
            offset += 176
            
            # Ler variáveis globais
            offset += global_vars * 4
            
            # Ler variáveis locais
            offset += local_vars * 4
            
            # Ler tiles - respeitar flags de elevação
            # Flag 2 = elevação 0 não presente
            # Flag 4 = elevação 1 não presente
            # Flag 8 = elevação 2 não presente
            elev_flags = [2, 4, 8]
            tiles = []
            
            for elevation in range(3):
                # Verificar se esta elevação está presente
                if (flags & elev_flags[elevation]) != 0:
                    continue  # Elevação não presente, pular
                
                for i in range(self.TILES_PER_LEVEL):
                    if offset + 4 > len(data):
                        break
                    
                    # Ler como um int32 (big-endian)
                    tile_value = struct.unpack('>I', data[offset:offset+4])[0]
                    offset += 4
                    
                    # floor_id = bits 0-15, roof_id = bits 16-31
                    floor_id = tile_value & 0xFFFF
                    roof_id = (tile_value >> 16) & 0xFFFF
                    
                    x = i % self.MAP_WIDTH
                    y = i // self.MAP_WIDTH
                    
                    # Só adicionar tiles não vazios
                    if floor_id != 0 or roof_id != 0:
                        tiles.append(TileInfo(
                            floor_id=floor_id,
                            roof_id=roof_id,
                            x=x,
                            y=y,
                            elevation=elevation
                        ))
            
            # Ler objetos
            objects = []
            if offset < len(data) - 4:
                try:
                    total_objects = struct.unpack('>I', data[offset:offset+4])[0]
                    offset += 4
                    
                    for _ in range(min(total_objects, 10000)):  # Limite de segurança
                        if offset + 80 > len(data):
                            break
                        
                        obj = self._parse_object(data, offset)
                        if obj:
                            objects.append(obj)
                        offset += 80  # Tamanho aproximado de um objeto
                except:
                    pass
            
            script_name = f"script_{script_index}.int" if script_index > 0 else ""
            
            return MapInfo(
                name=name,
                filename=filename,
                version=version,
                width=self.MAP_WIDTH,
                height=self.MAP_HEIGHT,
                num_levels=3,
                entering_tile=entering_tile,
                entering_elevation=entering_elevation,
                entering_rotation=entering_rotation,
                tiles=tiles,
                objects=objects,
                script_name=script_name
            )
            
        except Exception as e:
            self.errors.append(f"{filename}: {str(e)}")
            return None
    
    def _parse_object(self, data: bytes, offset: int) -> Optional[ObjectInfo]:
        """Parseia um objeto do mapa."""
        try:
            # PID (4 bytes)
            pid = struct.unpack('>I', data[offset:offset+4])[0]
            
            # Posição (tile index)
            tile_pos = struct.unpack('>I', data[offset+4:offset+8])[0]
            x = tile_pos % self.MAP_WIDTH
            y = tile_pos // self.MAP_WIDTH
            
            # Elevação
            elevation = struct.unpack('>I', data[offset+12:offset+16])[0] & 0x3
            
            # Orientação
            orientation = struct.unpack('>I', data[offset+16:offset+20])[0] & 0x7
            
            # Script ID
            script_id = struct.unpack('>i', data[offset+24:offset+28])[0]
            
            # Tipo de objeto (baseado no PID)
            obj_type_id = (pid >> 24) & 0xF
            obj_type = self.OBJECT_TYPES.get(obj_type_id, "misc")
            
            return ObjectInfo(
                pid=pid,
                x=x,
                y=y,
                elevation=elevation,
                orientation=orientation,
                script_id=script_id,
                object_type=obj_type
            )
        except:
            return None
    
    def to_json(self, map_info: MapInfo) -> dict:
        """Converte MapInfo para dicionário JSON."""
        return {
            "name": map_info.name,
            "filename": map_info.filename,
            "version": map_info.version,
            "width": map_info.width,
            "height": map_info.height,
            "num_levels": map_info.num_levels,
            "entering": {
                "tile": map_info.entering_tile,
                "elevation": map_info.entering_elevation,
                "rotation": map_info.entering_rotation,
                "x": map_info.entering_tile % self.MAP_WIDTH,
                "y": map_info.entering_tile // self.MAP_WIDTH
            },
            "script": map_info.script_name,
            "tiles": [asdict(t) for t in map_info.tiles],
            "objects": [asdict(o) for o in map_info.objects],
            "stats": {
                "total_tiles": len(map_info.tiles),
                "total_objects": len(map_info.objects),
                "critters": len([o for o in map_info.objects if o.object_type == "critter"]),
                "items": len([o for o in map_info.objects if o.object_type == "item"]),
                "scenery": len([o for o in map_info.objects if o.object_type == "scenery"])
            }
        }


def generate_godot_scene(map_info: MapInfo, output_path: Path) -> str:
    """Gera uma cena .tscn do Godot para o mapa."""
    
    scene_name = Path(map_info.filename).stem.replace(".", "_")
    
    # Template básico de cena
    scene = f'''[gd_scene load_steps=3 format=3 uid="uid://{scene_name}_map"]

[ext_resource type="Script" path="res://scripts/maps/base_map.gd" id="1_script"]
[ext_resource type="PackedScene" path="res://scenes/characters/player.tscn" id="2_player"]

[node name="{scene_name}" type="Node2D"]
script = ExtResource("1_script")
map_name = "{map_info.name}"
map_file = "{map_info.filename}"
entering_x = {map_info.entering_tile % 100}
entering_y = {map_info.entering_tile // 100}
entering_elevation = {map_info.entering_elevation}

[node name="World" type="Node2D" parent="."]

[node name="Ground" type="Node2D" parent="World"]
z_index = -1

[node name="Objects" type="Node2D" parent="World"]

[node name="Player" parent="." instance=ExtResource("2_player")]
position = Vector2(512, 384)
z_index = 100

[node name="HUD" type="CanvasLayer" parent="."]
layer = 5
'''
    
    return scene


def main():
    """Função principal - converte todos os mapas."""
    
    print("=" * 60)
    print("CONVERSOR DE MAPAS DO FALLOUT 2")
    print("=" * 60)
    
    # Diretórios
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    output_json = project_root / "godot_project" / "assets" / "data" / "maps"
    output_scenes = project_root / "godot_project" / "scenes" / "maps"
    
    # Criar diretórios
    output_json.mkdir(parents=True, exist_ok=True)
    output_scenes.mkdir(parents=True, exist_ok=True)
    
    parser = FullMapParser()
    maps_data = []
    
    # Verificar se temos o DAT
    if dat_path.exists() and DAT2Reader:
        print(f"\nLendo mapas de: {dat_path}")
        
        try:
            with DAT2Reader(str(dat_path)) as reader:
                files = reader.list_files()
                map_files = [f for f in files if f.lower().endswith('.map')]
                
                print(f"Encontrados {len(map_files)} arquivos de mapa")
                
                for i, map_file in enumerate(map_files):
                    try:
                        data = reader.extract_file(map_file)
                        if data:
                            map_info = parser.parse_map(data, map_file)
                            if map_info:
                                maps_data.append(map_info)
                                
                                # Salvar JSON
                                json_file = output_json / f"{Path(map_file).stem}.json"
                                with open(json_file, 'w', encoding='utf-8') as f:
                                    json.dump(parser.to_json(map_info), f, indent=2)
                                
                                # Gerar cena Godot
                                scene_file = output_scenes / f"{Path(map_file).stem}.tscn"
                                scene_content = generate_godot_scene(map_info, scene_file)
                                with open(scene_file, 'w', encoding='utf-8') as f:
                                    f.write(scene_content)
                                
                                parser.maps_converted += 1
                                
                                if (i + 1) % 10 == 0:
                                    print(f"  Processados: {i + 1}/{len(map_files)}")
                                    
                    except Exception as e:
                        parser.errors.append(f"{map_file}: {str(e)}")
                    
        except Exception as e:
            print(f"Erro ao ler DAT: {e}")
    else:
        print(f"\nDAT não encontrado em: {dat_path}")
        print("Criando mapas de exemplo...")
        
        # Criar mapas de exemplo
        example_maps = [
            ("artemple", "Temple of Trials", 100, 100),
            ("arvillag", "Arroyo Village", 150, 150),
            ("klamath", "Klamath", 200, 200),
        ]
        
        for filename, name, w, h in example_maps:
            # Criar JSON de exemplo
            example_data = {
                "name": name,
                "filename": f"{filename}.map",
                "version": 20,
                "width": w,
                "height": h,
                "num_levels": 3,
                "entering": {"tile": 5050, "elevation": 0, "rotation": 0, "x": 50, "y": 50},
                "script": "",
                "tiles": [],
                "objects": [],
                "stats": {"total_tiles": 0, "total_objects": 0, "critters": 0, "items": 0, "scenery": 0}
            }
            
            # Gerar tiles de exemplo
            for y in range(h):
                for x in range(w):
                    if x >= 10 and x < w-10 and y >= 10 and y < h-10:
                        example_data["tiles"].append({
                            "floor_id": 1 + ((x + y) % 5),
                            "roof_id": 0,
                            "x": x,
                            "y": y,
                            "elevation": 0
                        })
            
            example_data["stats"]["total_tiles"] = len(example_data["tiles"])
            
            json_file = output_json / f"{filename}.json"
            with open(json_file, 'w', encoding='utf-8') as f:
                json.dump(example_data, f, indent=2)
            
            parser.maps_converted += 1
            print(f"  Criado: {filename}.json")
    
    # Criar script base para mapas
    base_map_script = output_scenes.parent.parent / "scripts" / "maps" / "base_map.gd"
    base_map_script.parent.mkdir(parents=True, exist_ok=True)
    
    with open(base_map_script, 'w', encoding='utf-8') as f:
        f.write(BASE_MAP_SCRIPT)
    
    # Criar índice de mapas
    index_file = output_json / "_index.json"
    index_data = {
        "total_maps": parser.maps_converted,
        "maps": [{"name": m.name, "file": m.filename} for m in maps_data] if maps_data else [],
        "errors": parser.errors[:10]  # Primeiros 10 erros
    }
    with open(index_file, 'w', encoding='utf-8') as f:
        json.dump(index_data, f, indent=2)
    
    print("\n" + "=" * 60)
    print(f"CONVERSÃO COMPLETA!")
    print(f"  Mapas convertidos: {parser.maps_converted}")
    print(f"  Erros: {len(parser.errors)}")
    print(f"  JSONs em: {output_json}")
    print(f"  Cenas em: {output_scenes}")
    print("=" * 60)


# Script base para mapas no Godot
BASE_MAP_SCRIPT = '''extends Node2D

## Script base para mapas convertidos do Fallout 2
## Carrega dados do JSON e renderiza o mapa

@export var map_name: String = ""
@export var map_file: String = ""
@export var entering_x: int = 50
@export var entering_y: int = 50
@export var entering_elevation: int = 0

@onready var world: Node2D = $World
@onready var ground: Node2D = $World/Ground
@onready var objects_node: Node2D = $World/Objects
@onready var player: CharacterBody2D = $Player

var iso_renderer: Node = null
var map_data: Dictionary = {}
var is_ready: bool = false

func _ready():
	print("BaseMap: Carregando ", map_name)
	
	iso_renderer = get_node_or_null("/root/IsometricRenderer")
	
	await get_tree().process_frame
	
	# Carregar dados do mapa
	_load_map_data()
	
	# Renderizar mapa
	_render_map()
	
	# Configurar player
	_setup_player()
	
	# Notificar GameManager
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.current_map = self
		gm.current_map_name = map_name
		gm.change_state(gm.GameState.EXPLORATION)
	
	is_ready = true
	print("BaseMap: ", map_name, " carregado!")

func _load_map_data():
	"""Carrega dados do JSON do mapa."""
	var json_path = "res://assets/data/maps/" + map_file.replace(".map", ".json")
	
	if ResourceLoader.exists(json_path):
		var file = FileAccess.open(json_path, FileAccess.READ)
		if file:
			var json_text = file.get_as_text()
			var json = JSON.new()
			if json.parse(json_text) == OK:
				map_data = json.data
				print("BaseMap: Dados carregados - ", map_data.get("stats", {}))
	else:
		print("BaseMap: JSON não encontrado: ", json_path)

func _render_map():
	"""Renderiza tiles e objetos do mapa."""
	if map_data.is_empty():
		_create_fallback_map()
		return
	
	var tiles = map_data.get("tiles", [])
	var tile_textures = _load_tile_textures()
	
	print("BaseMap: Renderizando ", tiles.size(), " tiles")
	
	for tile in tiles:
		if tile.get("elevation", 0) != 0:
			continue  # Por enquanto só nível 0
		
		var x = tile.get("x", 0)
		var y = tile.get("y", 0)
		var floor_id = tile.get("floor_id", 1)
		
		var tile_pos = Vector2i(x, y)
		var screen_pos = Vector2.ZERO
		
		if iso_renderer:
			screen_pos = iso_renderer.tile_to_screen(tile_pos, 0)
		else:
			screen_pos = Vector2(x * 40 - y * 40, (x + y) * 18)
		
		var sprite = Sprite2D.new()
		sprite.name = "Tile_%d_%d" % [x, y]
		sprite.position = screen_pos
		sprite.centered = true
		
		if tile_textures.size() > 0:
			var tex_idx = floor_id % tile_textures.size()
			sprite.texture = tile_textures[tex_idx]
		
		sprite.z_index = -10000 + (x + y) * 10
		ground.add_child(sprite)

func _load_tile_textures() -> Array[Texture2D]:
	"""Carrega texturas de tiles."""
	var textures: Array[Texture2D] = []
	var paths = [
		"res://assets/sprites/tiles/aft1000.png",
		"res://assets/sprites/tiles/aft1001.png",
		"res://assets/sprites/tiles/arfl001.png",
		"res://assets/sprites/tiles/arfl002.png",
		"res://assets/sprites/tiles/arfl003.png",
	]
	
	for path in paths:
		if ResourceLoader.exists(path):
			var tex = load(path)
			if tex:
				textures.append(tex)
	
	return textures

func _create_fallback_map():
	"""Cria mapa básico se não houver dados."""
	print("BaseMap: Criando mapa fallback")
	
	for y in range(30):
		for x in range(30):
			var rect = ColorRect.new()
			rect.name = "Tile_%d_%d" % [x, y]
			rect.size = Vector2(80, 36)
			rect.color = Color(0.3, 0.25, 0.2) if (x + y) % 2 == 0 else Color(0.25, 0.2, 0.15)
			
			if iso_renderer:
				rect.position = iso_renderer.tile_to_screen(Vector2i(x, y), 0) - Vector2(40, 18)
			else:
				rect.position = Vector2(x * 40 - y * 40, (x + y) * 18)
			
			rect.z_index = -10000 + (x + y) * 10
			ground.add_child(rect)

func _setup_player():
	"""Configura player na posição de entrada."""
	if not player:
		return
	
	player.add_to_group("player")
	
	var start_tile = Vector2i(entering_x, entering_y)
	if iso_renderer:
		player.position = world.position + iso_renderer.tile_to_screen(start_tile, 0)
	else:
		player.position = Vector2(512, 384)
	
	player.z_index = 1000
	
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.enabled = true
		camera.make_current()
		camera.position_smoothing_enabled = true

func _input(event):
	if not is_ready:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var world_pos = get_global_mouse_position()
			if player and player.has_method("move_to"):
				player.move_to(world_pos)
'''


if __name__ == "__main__":
    main()
