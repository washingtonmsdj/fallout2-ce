"""
Módulo para parsing de arquivos MAP do Fallout 2.

Este módulo implementa o MAPParser que lê arquivos de mapa, extrai
tiles, objetos e scripts, exportando em formato JSON.
"""
import struct
import json
import zlib
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict


# Mapeamento de tipos de objeto do Fallout 2
TYPE_NAMES = {
    0: "item",
    1: "critter",
    2: "scenery",
    3: "wall",
    4: "tile",  # Não usado em objetos
    5: "misc"
}


@dataclass
class MapObject:
    """Objeto em um mapa."""
    pid: int
    x: int
    y: int
    elevation: int
    orientation: int
    script_id: int
    object_type: str
    frm_id: int
    flags: int


@dataclass
class MapData:
    """Dados completos de um mapa."""
    version: int
    name: str
    width: int
    height: int
    num_levels: int
    tiles: List[List[int]]  # [level][tile_index]
    objects: List[MapObject]
    scripts: List[str]
    entering_tile: int
    entering_elevation: int
    entering_rotation: int
    script_index: int
    flags: int
    darkness: int
    global_variables_count: int
    local_variables_count: int


class MAPParser:
    """
    Parser de arquivos MAP do Fallout 2.
    
    Lê arquivos de mapa, extrai informações de tiles, objetos e scripts,
    exportando em formato JSON legível para importação no Godot.
    """
    
    # Tamanho do grid de tiles (geralmente 200x200)
    DEFAULT_MAP_SIZE = 200
    
    def __init__(self):
        """Inicializa o parser de mapas."""
        pass
    
    def parse(self, map_data: bytes, filename: str = "") -> MapData:
        """
        Parseia dados de um arquivo MAP usando o parser definitivo.

        Args:
            map_data: Dados binários do arquivo MAP
            filename: Nome do arquivo para identificação

        Returns:
            MapData com todas as informações do mapa
        """
        # Usar o parser definitivo
        parsed_data = parse_map_definitivo(map_data, filename, verbose=False)

        # Converter para objetos MapObject
        objects = []
        for obj_dict in parsed_data["objects"]:
            objects.append(MapObject(**obj_dict))

        # Tiles já estão organizados por nível
        tiles_by_level = parsed_data["tiles"]

        return MapData(
            version=parsed_data["version"],
            name=parsed_data["name"],
            width=parsed_data["width"],
            height=parsed_data["height"],
            num_levels=parsed_data["num_levels"],
            tiles=tiles_by_level,
            objects=objects,
            scripts=parsed_data["scripts"],
            entering_tile=parsed_data["entering_tile"],
            entering_elevation=parsed_data["entering_elevation"],
            entering_rotation=parsed_data["entering_rotation"],
            script_index=parsed_data["script_index"],
            flags=parsed_data["flags"],
            darkness=parsed_data["darkness"],
            global_variables_count=parsed_data["global_variables_count"],
            local_variables_count=parsed_data["local_variables_count"]
        )
    
    def to_json(self, map_data: MapData, output_path: str):
        """
        Exporta dados do mapa para JSON.
        
        Args:
            map_data: Dados do mapa parseados
            output_path: Caminho do arquivo JSON de saída
        """
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Converter para formato serializável
        output_dict = {
            'version': map_data.version,
            'name': map_data.name,
            'width': map_data.width,
            'height': map_data.height,
            'num_levels': map_data.num_levels,
            'tiles': map_data.tiles,
            'objects': [asdict(obj) for obj in map_data.objects],
            'scripts': map_data.scripts,
            'entering': {
                'tile': map_data.entering_tile,
                'elevation': map_data.entering_elevation,
                'rotation': map_data.entering_rotation
            },
            'script_index': map_data.script_index,
            'flags': map_data.flags,
            'darkness': map_data.darkness,
            'variables': {
                'global_count': map_data.global_variables_count,
                'local_count': map_data.local_variables_count
            }
        }
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(output_dict, f, indent=2, ensure_ascii=False)
    
    def get_tiles(self, map_data: MapData) -> List[List[int]]:
        """
        Obtém array de tiles do mapa.
        
        Args:
            map_data: Dados do mapa
            
        Returns:
            Lista de tiles por nível
        """
        return map_data.tiles
    
    def get_objects(self, map_data: MapData) -> List[MapObject]:
        """
        Obtém lista de objetos do mapa.
        
        Args:
            map_data: Dados do mapa
            
        Returns:
            Lista de objetos
        """
        return map_data.objects


def read_int32_be(data: bytes, offset: int) -> int:
    """Lê um int32 big-endian."""
    return struct.unpack('>i', data[offset:offset+4])[0]


def read_uint32_be(data: bytes, offset: int) -> int:
    """Lê um uint32 big-endian."""
    return struct.unpack('>I', data[offset:offset+4])[0]


def read_object_from_save(data: bytes, offset: int, obj_num: int, verbose: bool = False) -> Tuple[Optional[MapObject], int]:
    """
    Lê um objeto usando o formato de save do Fallout 2.

    Baseado em objectDataRead() do código fonte:
    - 72 bytes: campos base
    - 12 bytes: inventário header
    - 4 bytes por item no inventário
    - dados específicos do tipo (4-48 bytes)
    """

    MIN_SIZE = 84  # Tamanho mínimo de um objeto
    start_offset = offset

    try:
        if offset + MIN_SIZE > len(data):
            return None, offset

        # Campos base (72 bytes)
        obj_id = read_uint32_be(data, offset)
        tile_num = read_int32_be(data, offset + 4)
        x = read_int32_be(data, offset + 8)
        y = read_int32_be(data, offset + 12)
        sx = read_int32_be(data, offset + 16)
        sy = read_int32_be(data, offset + 20)
        frame = read_uint32_be(data, offset + 24)
        rotation = read_uint32_be(data, offset + 28)
        fid = read_uint32_be(data, offset + 32)
        flags = read_uint32_be(data, offset + 36)
        elevation = read_uint32_be(data, offset + 40)
        pid = read_uint32_be(data, offset + 44)
        cid = read_uint32_be(data, offset + 48)
        light_distance = read_uint32_be(data, offset + 52)
        light_intensity = read_uint32_be(data, offset + 56)
        outline = read_uint32_be(data, offset + 60)
        sid = read_int32_be(data, offset + 64)
        script_index = read_uint32_be(data, offset + 68)

        offset += 72

        # Inventário (12 bytes)
        inv_length = read_uint32_be(data, offset)
        inv_capacity = read_uint32_be(data, offset + 4)
        inv_ptr = read_uint32_be(data, offset + 8)

        offset += 12

        # Validar PID
        if pid == 0 or pid == 0xFFFFFFFF:
            return None, offset

        # Pular inventário (4 bytes por item)
        if inv_length > 0 and inv_length < 1000:  # Limite de segurança
            offset += inv_length * 4
        elif inv_length >= 1000:
            # Inventário provavelmente inválido, tentar continuar
            pass

        # Tipo de objeto (byte alto do PID)
        obj_type_id = (pid >> 24) & 0xFF

        # Dados específicos do tipo (4-48 bytes dependendo do tipo)
        if obj_type_id == 1:  # Critter (48 bytes)
            offset += 48
        elif obj_type_id == 0:  # Item (4-8 bytes)
            offset += 4
        elif obj_type_id == 2:  # Scenery (4-12 bytes)
            offset += 4
        elif obj_type_id == 3:  # Wall (4 bytes)
            offset += 4
        elif obj_type_id == 5:  # Misc (20 bytes)
            offset += 20
        else:
            # Tipo desconhecido, assumir 4 bytes
            offset += 4

        # Calcular posição se tile_num for inválido
        if tile_num < 0 or tile_num >= 10000:
            tile_num = 0

        if tile_num == 0 and x == -1 and y == -1:
            x = 0
            y = 0
        else:
            x = tile_num % 100
            y = tile_num // 100

        # Tipo de objeto
        obj_type = TYPE_NAMES.get(obj_type_id, "misc")

        # Criar objeto
        obj = MapObject(
            pid=pid,
            x=x,
            y=y,
            elevation=elevation & 0x3,
            orientation=rotation & 0x7,
            script_id=sid,
            object_type=obj_type,
            frm_id=fid,
            flags=flags
        )

        bytes_read = offset - start_offset

        if verbose and obj_num < 50:
            inv_str = f"inv={inv_length}" if inv_length < 1000 else "inv=?"
            print(f"  {obj_num:3d}: {obj_type:8s} PID={pid:08X} @ ({x:2d},{y:2d}) {inv_str} - {bytes_read} bytes")

        return obj, offset

    except Exception as e:
        if verbose:
            print(f"  ERRO em objeto {obj_num} offset {offset}: {e}")
        return None, offset + MIN_SIZE


def parse_map_definitivo(data: bytes, filename: str, verbose: bool = False) -> dict:
    """Parser definitivo baseado no código fonte do Fallout 2 CE."""

    MAP_WIDTH = 100
    MAP_HEIGHT = 100

    offset = 0

    # === HEADER (236 bytes) ===
    version = read_uint32_be(data, offset)
    offset += 4

    name = data[offset:offset+16].split(b'\x00')[0].decode('latin-1', errors='ignore').strip()
    if not name:
        name = Path(filename).stem
    offset += 16

    entering_tile = read_uint32_be(data, offset)
    entering_elev = read_uint32_be(data, offset + 4)
    entering_rot = read_uint32_be(data, offset + 8)
    offset += 12

    local_vars = read_uint32_be(data, offset)
    offset += 4

    script_idx = read_int32_be(data, offset)
    offset += 4

    flags = read_uint32_be(data, offset)
    offset += 4

    darkness = read_uint32_be(data, offset)
    global_vars = read_uint32_be(data, offset + 4)
    map_id = read_uint32_be(data, offset + 8)
    timestamp = read_uint32_be(data, offset + 12)
    offset += 16

    # Reserved (176 bytes)
    offset += 176

    # Global vars
    offset += global_vars * 4

    # Local vars
    offset += local_vars * 4

    if verbose:
        print(f"Header: version={version}, name={name}")
        print(f"Offset após header: {offset}")

    # === TILES ===
    tiles_by_elevation = [[], [], []]  # Uma lista para cada elevação
    elev_flags = [2, 4, 8]

    for elevation in range(3):
        if (flags & elev_flags[elevation]) != 0:
            continue

        for i in range(MAP_WIDTH * MAP_HEIGHT):
            if offset + 4 > len(data):
                break

            tile_value = read_uint32_be(data, offset)
            offset += 4

            floor_id = tile_value & 0xFFFF
            roof_id = (tile_value >> 16) & 0xFFFF

            x = i % MAP_WIDTH
            y = i // MAP_WIDTH

            if floor_id != 0 or roof_id != 0:
                tiles_by_elevation[elevation].append({
                    "floor_id": floor_id,
                    "roof_id": roof_id,
                    "x": x,
                    "y": y,
                    "elevation": elevation
                })

    if verbose:
        print(f"Offset após tiles: {offset}")

    # === SCRIPTS ===
    # 5 tipos de scripts
    for script_type in range(5):
        if offset + 4 > len(data):
            break

        count = read_uint32_be(data, offset)
        offset += 4

        if verbose:
            print(f"Scripts tipo {script_type}: {count}")

        if count > 0 and count < 1000:
            # Cada script tem 16 bytes base
            # Mas há padding/alinhamento complexo
            # Vamos usar o tamanho descoberto: 20 bytes por script
            offset += count * 20

    if verbose:
        print(f"Offset após scripts: {offset}")
        print(f"Bytes restantes: {len(data) - offset}\n")

    # === OBJETOS ===
    # Formato descoberto: não há contador total, apenas contadores por elevação
    # Pular possível header/padding (32 bytes)
    offset += 32

    objects = []

    if verbose:
        print(f"Início da seção de objetos: offset {offset}\n")

    # Ler objetos para cada elevação
    for elevation in range(3):
        if offset + 4 > len(data):
            break

        obj_count = read_uint32_be(data, offset)
        offset += 4

        if verbose:
            print(f"Elevação {elevation}: {obj_count} objetos")

        if obj_count > 0 and obj_count < 10000:
            for i in range(obj_count):
                if offset + 84 > len(data):
                    if verbose:
                        print(f"  Fim dos dados em objeto {i}")
                    break

                obj, new_offset = read_object_from_save(data, offset, len(objects), verbose)

                if obj and obj.pid != 0 and obj.pid != 0xFFFFFFFF:
                    obj.elevation = elevation
                    objects.append(obj)

                if new_offset <= offset:
                    if verbose:
                        print(f"  Offset não avançou, parando")
                    break

                offset = new_offset

    if verbose:
        print(f"\nTotal objetos lidos: {len(objects)}")
        print(f"Offset final: {offset}")
        print(f"Bytes restantes: {len(data) - offset}")

    return {
        "version": version,
        "name": name,
        "width": MAP_WIDTH,
        "height": MAP_HEIGHT,
        "num_levels": 3,
        "tiles": tiles_by_elevation,
        "objects": [asdict(obj) for obj in objects],
        "scripts": [f"script_{script_idx}.int"] if script_idx > 0 else [],
        "entering_tile": entering_tile,
        "entering_elevation": entering_elev,
        "entering_rotation": entering_rot,
        "script_index": script_idx,
        "flags": flags,
        "darkness": darkness,
        "global_variables_count": global_vars,
        "local_variables_count": local_vars
    }

