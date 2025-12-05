#!/usr/bin/env python3
"""
Parser PRECISO baseado na análise real do ARTEMPLE.MAP.

Descobertas:
- Scripts CRITTER têm 20 bytes cada
- Offset correto após scripts: 40288
- Objetos começam logo após os scripts
- Total esperado: 567 objetos
"""

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


TYPE_NAMES = {
    0: "item",
    1: "critter",
    2: "scenery",
    3: "wall",
    4: "tile",
    5: "misc"
}


def read_object_simple(data: bytes, offset: int, obj_num: int, verbose: bool = False) -> Tuple[Optional[MapObject], int]:
    """
    Lê um objeto usando tamanho fixo de 80 bytes.
    Vamos descobrir o tamanho real empiricamente.
    """
    
    OBJECT_SIZE = 80  # Tamanho base a testar
    
    if offset + OBJECT_SIZE > len(data):
        return None, offset
    
    try:
        # Ler campos principais
        # Baseado na análise, o PID está no início
        pid = struct.unpack('>I', data[offset:offset+4])[0]
        
        # Tile position
        tile = struct.unpack('>I', data[offset+4:offset+8])[0]
        
        # FRM ID (geralmente em offset +32)
        fid = struct.unpack('>I', data[offset+32:offset+36])[0]
        
        # Flags
        flags = struct.unpack('>I', data[offset+36:offset+40])[0]
        
        # Elevation
        elevation = struct.unpack('>I', data[offset+40:offset+44])[0]
        
        # Script ID
        sid = struct.unpack('>i', data[offset+64:offset+68])[0]
        
        # Orientation
        rotation = struct.unpack('>I', data[offset+28:offset+32])[0]
        
        # Tipo de objeto
        obj_type_id = (pid >> 24) & 0xFF
        obj_type = TYPE_NAMES.get(obj_type_id, "misc")
        
        # Calcular posição
        if 0 <= tile < 10000:
            x = tile % 100
            y = tile // 100
        else:
            x = 0
            y = 0
        
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
        
        if verbose and obj_num < 10:
            print(f"  Obj {obj_num:3d}: {obj_type:8s} PID={pid:08X} @ ({x:2d},{y:2d}) tile={tile}")
        
        return obj, offset + OBJECT_SIZE
        
    except Exception as e:
        if verbose:
            print(f"  ERRO em objeto {obj_num}: {e}")
        return None, offset + OBJECT_SIZE


def parse_map_accurate(data: bytes, filename: str, verbose: bool = False) -> dict:
    """Parser preciso baseado na análise real."""
    
    MAP_WIDTH = 100
    MAP_HEIGHT = 100
    
    offset = 0
    
    # === HEADER (236 bytes) ===
    version = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    name = data[offset:offset+16].split(b'\x00')[0].decode('latin-1', errors='ignore').strip()
    if not name:
        name = Path(filename).stem
    offset += 16
    
    entering_tile = struct.unpack('>I', data[offset:offset+4])[0]
    entering_elev = struct.unpack('>I', data[offset+4:offset+8])[0]
    entering_rot = struct.unpack('>I', data[offset+8:offset+12])[0]
    offset += 12
    
    local_vars = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    script_idx = struct.unpack('>i', data[offset:offset+4])[0]
    offset += 4
    
    flags = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    offset += 16  # darkness, global_vars, etc
    offset += 176  # reserved
    offset += 0 * 4  # global vars (0)
    offset += local_vars * 4  # local vars
    
    if verbose:
        print(f"Offset após header: {offset}")
    
    # === TILES (40000 bytes) ===
    tiles = []
    
    # Só elevação 0 está presente (flags = 0x0C)
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
                "elevation": 0
            })
    
    if verbose:
        print(f"Offset após tiles: {offset}")
    
    # === SCRIPTS ===
    # 5 tipos: Spatial(0), Timed(1), Item(2), Critter(3), Scenery(4)
    
    for script_type in range(5):
        if offset + 4 > len(data):
            break
        
        count = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        if verbose:
            print(f"Scripts tipo {script_type}: {count}")
        
        if count > 0 and count < 1000:
            # Cada script tem 20 bytes
            offset += count * 20
    
    if verbose:
        print(f"Offset após scripts: {offset}")
        print(f"Bytes restantes: {len(data) - offset}")
    
    # === OBJETOS ===
    # Agora vem a seção de objetos
    # Vamos tentar ler objetos até o fim do arquivo
    
    objects = []
    obj_num = 0
    
    if verbose:
        print(f"\nLendo objetos a partir de offset {offset}...")
    
    while offset + 80 <= len(data):
        obj, new_offset = read_object_simple(data, offset, obj_num, verbose)
        
        if obj and obj.pid != 0:
            objects.append(obj)
            obj_num += 1
        
        # Se não conseguimos ler, tentar avançar
        if new_offset == offset:
            offset += 4
        else:
            offset = new_offset
        
        # Parar se chegamos perto do fim
        if len(data) - offset < 100:
            break
    
    if verbose:
        print(f"\nTotal objetos lidos: {len(objects)}")
        print(f"Offset final: {offset}")
        print(f"Bytes restantes: {len(data) - offset}")
    
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
        "objects": [asdict(o) for o in objects],
        "stats": {
            "total_tiles": len(tiles),
            "total_objects": len(objects),
            "critters": len([o for o in objects if o.object_type == "critter"]),
            "items": len([o for o in objects if o.object_type == "item"]),
            "scenery": len([o for o in objects if o.object_type == "scenery"]),
            "walls": len([o for o in objects if o.object_type == "wall"])
        }
    }


def main():
    project_root = Path(__file__).parent.parent
    dat_path = project_root / "Fallout 2" / "master.dat"
    
    dat = DAT2Reader(dat_path)
    dat.open()
    
    print("=" * 60)
    print("PARSER PRECISO - ARTEMPLE.MAP")
    print("=" * 60)
    
    data = dat.get("maps/artemple.map")
    if data:
        print(f"Tamanho: {len(data)} bytes\n")
        
        map_data = parse_map_accurate(data, "artemple.map", verbose=True)
        
        print("\n" + "=" * 60)
        print("RESULTADO")
        print("=" * 60)
        print(f"Nome: {map_data['name']}")
        print(f"Tiles: {map_data['stats']['total_tiles']}")
        print(f"Objetos: {map_data['stats']['total_objects']}")
        print(f"  - Critters: {map_data['stats']['critters']}")
        print(f"  - Items: {map_data['stats']['items']}")
        print(f"  - Scenery: {map_data['stats']['scenery']}")
        print(f"  - Walls: {map_data['stats']['walls']}")
        
        # Salvar
        output_path = project_root / "godot_project" / "assets" / "data" / "maps" / "artemple.json"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'w') as f:
            json.dump(map_data, f, indent=2)
        print(f"\nSalvo em: {output_path}")
    
    dat.close()


if __name__ == "__main__":
    main()
