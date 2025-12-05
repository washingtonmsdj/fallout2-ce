#!/usr/bin/env python3
"""
Parser FINAL de mapas do Fallout 2 - baseado no código fonte real.

Estrutura de objeto (72 bytes base):
- id (4)
- tile (4)
- x (4)
- y (4)
- sx (4)
- sy (4)
- frame (4)
- rotation (4)
- fid (4)
- flags (4)
- elevation (4)
- pid (4)
- cid (4)
- lightDistance (4)
- lightIntensity (4)
- field_74 (4)
- sid (4)
- scriptIndex (4)

Depois: objectDataRead (inventário + dados específicos do tipo)
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


# Tipos de objeto baseados no PID
OBJ_TYPE_ITEM = 0
OBJ_TYPE_CRITTER = 1
OBJ_TYPE_SCENERY = 2
OBJ_TYPE_WALL = 3
OBJ_TYPE_TILE = 4
OBJ_TYPE_MISC = 5

TYPE_NAMES = {
    OBJ_TYPE_ITEM: "item",
    OBJ_TYPE_CRITTER: "critter",
    OBJ_TYPE_SCENERY: "scenery",
    OBJ_TYPE_WALL: "wall",
    OBJ_TYPE_TILE: "tile",
    OBJ_TYPE_MISC: "misc"
}


def read_object(data: bytes, offset: int) -> Tuple[Optional[MapObject], int]:
    """Lê um objeto do mapa usando a estrutura real do Fallout 2."""
    
    if offset + 72 > len(data):
        return None, offset
    
    try:
        # Campos base (72 bytes)
        obj_id = struct.unpack('>I', data[offset+0:offset+4])[0]
        tile = struct.unpack('>i', data[offset+4:offset+8])[0]
        x_off = struct.unpack('>i', data[offset+8:offset+12])[0]
        y_off = struct.unpack('>i', data[offset+12:offset+16])[0]
        sx = struct.unpack('>i', data[offset+16:offset+20])[0]
        sy = struct.unpack('>i', data[offset+20:offset+24])[0]
        frame = struct.unpack('>I', data[offset+24:offset+28])[0]
        rotation = struct.unpack('>I', data[offset+28:offset+32])[0]
        fid = struct.unpack('>I', data[offset+32:offset+36])[0]
        flags = struct.unpack('>I', data[offset+36:offset+40])[0]
        elevation = struct.unpack('>I', data[offset+40:offset+44])[0]
        pid = struct.unpack('>I', data[offset+44:offset+48])[0]
        cid = struct.unpack('>I', data[offset+48:offset+52])[0]
        light_dist = struct.unpack('>I', data[offset+52:offset+56])[0]
        light_int = struct.unpack('>I', data[offset+56:offset+60])[0]
        field_74 = struct.unpack('>I', data[offset+60:offset+64])[0]
        sid = struct.unpack('>i', data[offset+64:offset+68])[0]
        script_idx = struct.unpack('>I', data[offset+68:offset+72])[0]
        
        offset += 72
        
        # Tipo de objeto
        obj_type_id = (pid >> 24) & 0xFF
        obj_type = TYPE_NAMES.get(obj_type_id, "misc")
        
        # objectDataRead - inventário + dados específicos
        # Inventário (12 bytes)
        if offset + 12 > len(data):
            return None, offset
        
        inv_length = struct.unpack('>I', data[offset:offset+4])[0]
        inv_capacity = struct.unpack('>I', data[offset+4:offset+8])[0]
        inv_ptr = struct.unpack('>I', data[offset+8:offset+12])[0]  # ignorado
        offset += 12
        
        # Dados específicos do tipo
        if obj_type_id == OBJ_TYPE_CRITTER:
            # Critter: field_0 (4) + combat data (muitos bytes) + hp (4) + radiation (4) + poison (4)
            # Combat data tem ~32 bytes
            if offset + 4 + 32 + 12 <= len(data):
                offset += 4 + 32 + 12  # Simplificado
        else:
            # Outros tipos: flags (4) + dados específicos
            if offset + 4 <= len(data):
                offset += 4
            
            # Dados específicos por subtipo (simplificado)
            if obj_type_id == OBJ_TYPE_ITEM:
                # Pode ter 0, 4 ou 8 bytes extras dependendo do tipo de item
                pass
            elif obj_type_id == OBJ_TYPE_SCENERY:
                # Pode ter 0, 4 ou 8 bytes extras dependendo do tipo de scenery
                pass
            elif obj_type_id == OBJ_TYPE_MISC:
                # Exit grids têm 16 bytes extras
                pass
        
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
        
        return obj, offset
        
    except Exception as e:
        return None, offset + 72


def parse_map_final(data: bytes, filename: str, verbose: bool = False) -> dict:
    """Parser final baseado no código fonte do Fallout 2 CE."""
    
    MAP_WIDTH = 100
    MAP_HEIGHT = 100
    TILES_PER_LEVEL = MAP_WIDTH * MAP_HEIGHT
    
    offset = 0
    
    # === HEADER ===
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
    
    darkness = struct.unpack('>I', data[offset:offset+4])[0]
    global_vars = struct.unpack('>I', data[offset+4:offset+8])[0]
    offset += 16
    
    # Reserved
    offset += 176
    
    # Vars
    offset += global_vars * 4
    offset += local_vars * 4
    
    if verbose:
        print(f"Header: version={version}, name={name}, flags={flags:08X}")
        print(f"Offset após header+vars: {offset}")
    
    # === TILES ===
    tiles = []
    elev_flags = [2, 4, 8]
    elevations_present = []
    
    for elevation in range(3):
        if (flags & elev_flags[elevation]) != 0:
            continue
        elevations_present.append(elevation)
        
        for i in range(TILES_PER_LEVEL):
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
    
    if verbose:
        print(f"Offset após tiles: {offset}")
        print(f"Elevações presentes: {elevations_present}")
    
    # === SCRIPTS ===
    for script_type in range(5):
        if offset + 4 > len(data):
            break
        
        count = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        if verbose:
            print(f"Scripts tipo {script_type}: {count}")
        
        if count > 0 and count < 1000:
            scripts_read = 0
            while scripts_read < count:
                batch = min(16, count - scripts_read)
                offset += batch * 16
                scripts_read += batch
                
                if scripts_read < count or batch == 16:
                    offset += 4
    
    if verbose:
        print(f"Offset após scripts: {offset}")
        print(f"Bytes restantes: {len(data) - offset}")
    
    # === OBJETOS ===
    # Primeiro vem o total de objetos
    objects = []
    
    if offset + 4 <= len(data):
        total_objects = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        if verbose:
            print(f"Total objetos (header): {total_objects}")
        
        # Para TODAS as 3 elevações (não apenas as presentes nos tiles)
        for elevation in range(3):
            if offset + 4 > len(data):
                break
            
            obj_count = struct.unpack('>I', data[offset:offset+4])[0]
            offset += 4
            
            if verbose:
                print(f"Objetos elevação {elevation}: {obj_count}")
            
            if obj_count > 0 and obj_count < 10000:
                for i in range(obj_count):
                    if offset + 72 > len(data):
                        break
                    
                    obj, offset = read_object(data, offset)
                    if obj and obj.pid != 0:
                        obj.elevation = elevation
                        objects.append(obj)
    
    if verbose:
        print(f"Total objetos lidos: {len(objects)}")
        print(f"Offset final: {offset}")
    
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
    
    # Testar com artemple
    print("=" * 60)
    print("ARTEMPLE.MAP")
    print("=" * 60)
    
    data = dat.get("maps/artemple.map")
    if data:
        map_data = parse_map_final(data, "artemple.map", verbose=True)
        
        print("\n=== RESULTADO ===")
        print(f"Tiles: {map_data['stats']['total_tiles']}")
        print(f"Objetos: {map_data['stats']['total_objects']}")
        print(f"  - Critters: {map_data['stats']['critters']}")
        print(f"  - Items: {map_data['stats']['items']}")
        print(f"  - Scenery: {map_data['stats']['scenery']}")
        print(f"  - Walls: {map_data['stats']['walls']}")
        
        if map_data['objects']:
            print("\nPrimeiros 20 objetos:")
            for obj in map_data['objects'][:20]:
                print(f"  {obj['object_type']:8s}: ({obj['x']:2d}, {obj['y']:2d}) PID={obj['pid']:08X} FRM={obj['frm_id']:08X}")
        
        # Salvar
        output_path = project_root / "godot_project" / "assets" / "data" / "maps" / "artemple.json"
        with open(output_path, 'w') as f:
            json.dump(map_data, f, indent=2)
        print(f"\nSalvo em: {output_path}")
    
    dat.close()


if __name__ == "__main__":
    main()
