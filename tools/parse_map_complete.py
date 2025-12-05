#!/usr/bin/env python3
"""Parser completo de mapas do Fallout 2 baseado na documentação oficial."""

import struct
import zlib
import json
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import List, Optional, Tuple


class DAT2Reader:
    def __init__(self, path):
        self.path = Path(path)
        self.files = {}
        self.fh = None
        
    def open(self):
        self.fh = open(self.path, 'rb')
        self.fh.seek(-8, 2)
        tree_size = struct.unpack('<I', self.fh.read(4))[0]
        data_size = struct.unpack('<I', self.fh.read(4))[0]
        self.fh.seek(data_size - tree_size - 8)
        count = struct.unpack('<I', self.fh.read(4))[0]
        for _ in range(count):
            nlen = struct.unpack('<I', self.fh.read(4))[0]
            name = self.fh.read(nlen).decode('ascii', errors='ignore').rstrip('\x00')
            comp = struct.unpack('<B', self.fh.read(1))[0]
            rsize = struct.unpack('<I', self.fh.read(4))[0]
            psize = struct.unpack('<I', self.fh.read(4))[0]
            off = struct.unpack('<I', self.fh.read(4))[0]
            self.files[name.lower().replace('\\', '/')] = (comp, rsize, psize, off)
        return len(self.files)
    
    def close(self):
        if self.fh:
            self.fh.close()
    
    def get(self, name):
        name = name.lower().replace('\\', '/')
        if name not in self.files:
            return None
        comp, rsize, psize, off = self.files[name]
        self.fh.seek(off)
        data = self.fh.read(psize)
        if comp:
            try:
                data = zlib.decompress(data)
            except:
                pass
        return data


@dataclass
class MapObject:
    pid: int
    x: int
    y: int
    elevation: int
    orientation: int
    script_id: int
    object_type: str
    frm_id: int = 0
    flags: int = 0


def read_object(data: bytes, offset: int) -> Tuple[Optional[MapObject], int]:
    """Lê um objeto do mapa.
    
    Estrutura de objeto (baseada em fontes do Fallout):
    - 4 bytes: unknown/id
    - 4 bytes: tile position
    - 4 bytes: x offset (screen)
    - 4 bytes: y offset (screen)
    - 4 bytes: sx, sy (screen coords)
    - 4 bytes: frame_num
    - 4 bytes: orientation
    - 4 bytes: FRM ID
    - 4 bytes: flags
    - 4 bytes: elevation
    - 4 bytes: inventory count
    - ... mais campos
    
    Total: ~84 bytes por objeto base
    """
    if offset + 84 > len(data):
        return None, offset
    
    try:
        # Ler campos principais
        obj_id = struct.unpack('>I', data[offset:offset+4])[0]
        tile = struct.unpack('>i', data[offset+4:offset+8])[0]
        x_off = struct.unpack('>i', data[offset+8:offset+12])[0]
        y_off = struct.unpack('>i', data[offset+12:offset+16])[0]
        sx = struct.unpack('>i', data[offset+16:offset+20])[0]
        sy = struct.unpack('>i', data[offset+20:offset+24])[0]
        frame_num = struct.unpack('>I', data[offset+24:offset+28])[0]
        orientation = struct.unpack('>I', data[offset+28:offset+32])[0]
        frm_id = struct.unpack('>I', data[offset+32:offset+36])[0]
        flags = struct.unpack('>I', data[offset+36:offset+40])[0]
        elevation = struct.unpack('>I', data[offset+40:offset+44])[0]
        
        # PID está em outro lugar - vamos procurar
        pid = struct.unpack('>I', data[offset+44:offset+48])[0]
        
        # Calcular posição
        if tile >= 0:
            x = tile % 100
            y = tile // 100
        else:
            x = 0
            y = 0
        
        # Tipo de objeto baseado no FRM ID
        frm_type = (frm_id >> 24) & 0xF
        type_names = {0: "item", 1: "critter", 2: "scenery", 3: "wall", 4: "tile", 5: "misc"}
        obj_type = type_names.get(frm_type, "misc")
        
        # Script ID
        script_id = struct.unpack('>i', data[offset+48:offset+52])[0]
        
        # Inventory count
        inv_count = struct.unpack('>I', data[offset+52:offset+56])[0]
        
        # Tamanho base + inventário
        obj_size = 84 + inv_count * 8
        
        obj = MapObject(
            pid=pid,
            x=x,
            y=y,
            elevation=elevation & 0x3,
            orientation=orientation & 0x7,
            script_id=script_id,
            object_type=obj_type,
            frm_id=frm_id,
            flags=flags
        )
        
        return obj, offset + obj_size
        
    except Exception as e:
        return None, offset + 84


def parse_map_v2(data: bytes, filename: str) -> dict:
    """Parser alternativo baseado em análise binária."""
    
    MAP_WIDTH = 100
    MAP_HEIGHT = 100
    
    offset = 0
    
    # Header
    version = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    # Nome
    name = data[offset:offset+16].split(b'\x00')[0].decode('latin-1', errors='ignore').strip()
    if not name:
        name = Path(filename).stem
    offset += 16
    
    # Entering
    entering_tile = struct.unpack('>I', data[offset:offset+4])[0]
    entering_elev = struct.unpack('>I', data[offset+4:offset+8])[0]
    entering_rot = struct.unpack('>I', data[offset+8:offset+12])[0]
    offset += 12
    
    # Local vars
    local_vars = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    # Script index
    script_idx = struct.unpack('>i', data[offset:offset+4])[0]
    offset += 4
    
    # Flags
    flags = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    # Darkness, global_vars, map_id, timestamp
    darkness = struct.unpack('>I', data[offset:offset+4])[0]
    global_vars = struct.unpack('>I', data[offset+4:offset+8])[0]
    map_id = struct.unpack('>I', data[offset+8:offset+12])[0]
    timestamp = struct.unpack('>I', data[offset+12:offset+16])[0]
    offset += 16
    
    # Reserved (176 bytes)
    offset += 176
    
    # Global vars data
    offset += global_vars * 4
    
    # Local vars data
    offset += local_vars * 4
    
    # Tiles
    tiles = []
    elev_flags = [2, 4, 8]
    
    for elevation in range(3):
        if (flags & elev_flags[elevation]) != 0:
            continue
        
        for i in range(MAP_WIDTH * MAP_HEIGHT):
            if offset + 4 > len(data):
                break
            
            tile_value = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            floor_id = tile_value & 0xFFFF
            roof_id = (tile_value >> 16) & 0xFFFF
            
            x = i % MAP_WIDTH
            y = i // MAP_WIDTH
            
            if floor_id != 0 or roof_id != 0:
                tiles.append({
                    "floor_id": floor_id,
                    "roof_id": roof_id,
                    "x": x,
                    "y": y,
                    "elevation": elevation
                })
    
    print(f"Offset após tiles: {offset}")
    
    # Scripts - 5 tipos
    # Cada tipo tem: count (4 bytes) + scripts
    script_counts = []
    for script_type in range(5):
        if offset + 4 > len(data):
            break
        
        count = struct.unpack('>I', data[offset:offset+4])[0]
        script_counts.append(count)
        offset += 4
        
        # Pular dados dos scripts
        # Cada script tem ~16 bytes mínimo
        if count > 0 and count < 1000:
            # Estrutura de script varia por tipo
            # Tipo 0 (Spatial): 16 bytes
            # Tipo 1 (Timed): 20 bytes
            # Tipo 2 (Item): 16 bytes
            # Tipo 3 (Critter): 16 bytes
            # Tipo 4 (Scenery): 16 bytes
            script_sizes = [16, 20, 16, 16, 16]
            offset += count * script_sizes[script_type]
    
    print(f"Script counts: {script_counts}")
    print(f"Offset após scripts: {offset}")
    
    # Objetos
    objects = []
    
    if offset + 4 <= len(data):
        total_objects = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        print(f"Total objects header: {total_objects}")
        
        if total_objects > 0 and total_objects < 10000:
            # Ler objetos
            for i in range(total_objects):
                obj, offset = read_object(data, offset)
                if obj:
                    objects.append(asdict(obj))
                else:
                    break
    
    print(f"Objetos lidos: {len(objects)}")
    
    return {
        "name": name,
        "filename": filename,
        "version": version,
        "width": MAP_WIDTH,
        "height": MAP_HEIGHT,
        "num_levels": 3,
        "entering": {
            "tile": entering_tile,
            "elevation": entering_elev,
            "rotation": entering_rot,
            "x": entering_tile % MAP_WIDTH,
            "y": entering_tile // MAP_WIDTH
        },
        "script": f"script_{script_idx}.int" if script_idx > 0 else "",
        "flags": flags,
        "tiles": tiles,
        "objects": objects,
        "stats": {
            "total_tiles": len(tiles),
            "total_objects": len(objects),
            "critters": len([o for o in objects if o.get("object_type") == "critter"]),
            "items": len([o for o in objects if o.get("object_type") == "item"]),
            "scenery": len([o for o in objects if o.get("object_type") == "scenery"]),
            "walls": len([o for o in objects if o.get("object_type") == "wall"])
        }
    }


def main():
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    
    dat = DAT2Reader(dat_path)
    dat.open()
    
    data = dat.get("maps/artemple.map")
    if not data:
        print("Mapa não encontrado!")
        return
    
    print(f"Tamanho: {len(data)} bytes")
    print("=" * 60)
    
    map_data = parse_map_v2(data, "artemple.map")
    
    print("\n=== RESULTADO ===")
    print(f"Nome: {map_data['name']}")
    print(f"Tiles: {map_data['stats']['total_tiles']}")
    print(f"Objetos: {map_data['stats']['total_objects']}")
    print(f"  - Critters: {map_data['stats']['critters']}")
    print(f"  - Items: {map_data['stats']['items']}")
    print(f"  - Scenery: {map_data['stats']['scenery']}")
    print(f"  - Walls: {map_data['stats']['walls']}")
    
    if map_data['objects']:
        print("\nPrimeiros 10 objetos:")
        for obj in map_data['objects'][:10]:
            print(f"  {obj['object_type']}: ({obj['x']}, {obj['y']}) PID={obj['pid']:08X}")
    
    dat.close()


if __name__ == "__main__":
    main()
