#!/usr/bin/env python3
"""
Parser de mapas do Fallout 2 - Versão 3
Baseado na análise real dos bytes do arquivo.

Estrutura descoberta:
- Após os scripts, há uma seção de objetos por elevação
- Cada elevação tem: count (4 bytes) + objetos
- Objetos têm tamanho variável (base 84 bytes + inventário)
"""

import struct
import zlib
import json
from pathlib import Path
from dataclasses import dataclass, asdict, field
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


def read_object_v2(data: bytes, offset: int, elevation: int) -> Tuple[Optional[MapObject], int]:
    """Lê um objeto usando a estrutura real do Fallout 2.
    
    Baseado na análise do código fonte do Fallout 2 CE:
    
    Estrutura de Object (68 bytes base):
    0x00: id (4)
    0x04: tile (4) - posição no mapa
    0x08: x (4) - offset x na tela
    0x0C: y (4) - offset y na tela
    0x10: sx (4)
    0x14: sy (4)
    0x18: frame (4)
    0x1C: rotation (4)
    0x20: fid (4) - FRM ID
    0x24: flags (4)
    0x28: elevation (4)
    0x2C: pid (4) - Proto ID
    0x30: cid (4)
    0x34: lightDistance (4)
    0x38: lightIntensity (4)
    0x3C: outline (4)
    0x40: sid (4) - Script ID
    0x44: owner (4) - dono do objeto
    
    Total: 72 bytes
    
    Depois vem dados específicos do tipo:
    - Items: 12 bytes extras
    - Critters: muitos bytes extras
    - Scenery: 4 bytes extras
    - Walls: 4 bytes extras
    - Misc: 0 bytes extras
    
    E depois inventário se houver.
    """
    
    if offset + 72 > len(data):
        return None, offset
    
    try:
        # Ler campos base
        obj_id = struct.unpack('>I', data[offset+0x00:offset+0x04])[0]
        tile = struct.unpack('>i', data[offset+0x04:offset+0x08])[0]
        x_off = struct.unpack('>i', data[offset+0x08:offset+0x0C])[0]
        y_off = struct.unpack('>i', data[offset+0x0C:offset+0x10])[0]
        sx = struct.unpack('>i', data[offset+0x10:offset+0x14])[0]
        sy = struct.unpack('>i', data[offset+0x14:offset+0x18])[0]
        frame = struct.unpack('>I', data[offset+0x18:offset+0x1C])[0]
        rotation = struct.unpack('>I', data[offset+0x1C:offset+0x20])[0]
        fid = struct.unpack('>I', data[offset+0x20:offset+0x24])[0]
        flags = struct.unpack('>I', data[offset+0x24:offset+0x28])[0]
        elev = struct.unpack('>I', data[offset+0x28:offset+0x2C])[0]
        pid = struct.unpack('>I', data[offset+0x2C:offset+0x30])[0]
        cid = struct.unpack('>I', data[offset+0x30:offset+0x34])[0]
        light_dist = struct.unpack('>I', data[offset+0x34:offset+0x38])[0]
        light_int = struct.unpack('>I', data[offset+0x38:offset+0x3C])[0]
        outline = struct.unpack('>I', data[offset+0x3C:offset+0x40])[0]
        sid = struct.unpack('>i', data[offset+0x40:offset+0x44])[0]
        owner = struct.unpack('>I', data[offset+0x44:offset+0x48])[0]
        
        offset += 72  # Tamanho base
        
        # Tipo de objeto baseado no PID
        obj_type_id = (pid >> 24) & 0xFF
        type_names = {0: "item", 1: "critter", 2: "scenery", 3: "wall", 4: "tile", 5: "misc"}
        obj_type = type_names.get(obj_type_id, "misc")
        
        # Dados extras por tipo
        if obj_type == "item":
            # Items têm 12 bytes extras
            if offset + 12 <= len(data):
                offset += 12
        elif obj_type == "critter":
            # Critters têm muitos dados extras (~40 bytes)
            if offset + 40 <= len(data):
                offset += 40
        elif obj_type == "scenery":
            # Scenery tem 4 bytes extras
            if offset + 4 <= len(data):
                offset += 4
        elif obj_type == "wall":
            # Walls têm 4 bytes extras
            if offset + 4 <= len(data):
                offset += 4
        
        # Inventário
        if offset + 8 <= len(data):
            inv_count = struct.unpack('>I', data[offset:offset+4])[0]
            inv_max = struct.unpack('>I', data[offset+4:offset+8])[0]
            offset += 8
            
            # Cada item do inventário tem 8 bytes
            if inv_count > 0 and inv_count < 100:
                offset += inv_count * 8
        
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
            elevation=elevation,
            orientation=rotation & 0x7,
            script_id=sid,
            object_type=obj_type,
            frm_id=fid,
            flags=flags
        )
        
        return obj, offset
        
    except Exception as e:
        return None, offset + 72


def parse_map_v3(data: bytes, filename: str, verbose: bool = False) -> dict:
    """Parser versão 3 - mais robusto."""
    
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
    # 5 tipos de scripts
    for script_type in range(5):
        if offset + 4 > len(data):
            break
        
        count = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        if verbose:
            print(f"Scripts tipo {script_type}: {count}")
        
        if count > 0 and count < 1000:
            # Cada script tem 16 bytes
            # A cada 16 scripts, há 4 bytes de checksum
            scripts_read = 0
            while scripts_read < count:
                batch = min(16, count - scripts_read)
                offset += batch * 16
                scripts_read += batch
                
                # Checksum após cada batch de 16
                if scripts_read < count or batch == 16:
                    offset += 4
    
    if verbose:
        print(f"Offset após scripts: {offset}")
    
    # === OBJETOS ===
    objects = []
    
    for elevation in elevations_present:
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
                
                obj, offset = read_object_v2(data, offset, elevation)
                if obj and obj.pid != 0:
                    objects.append(obj)
    
    if verbose:
        print(f"Total objetos: {len(objects)}")
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
        map_data = parse_map_v3(data, "artemple.map", verbose=True)
        
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
