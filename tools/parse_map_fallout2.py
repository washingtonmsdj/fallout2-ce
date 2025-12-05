#!/usr/bin/env python3
"""
Parser de mapas do Fallout 2 baseado na especificação real.

Formato do arquivo MAP:
1. Header (60 bytes)
2. Reserved (176 bytes)  
3. Global vars (global_vars * 4 bytes)
4. Local vars (local_vars * 4 bytes)
5. Tiles (10000 * 4 bytes por elevação presente)
6. Scripts (5 seções)
7. Objetos (por elevação)
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
    inventory: List = None


def read_script(data: bytes, offset: int, script_type: int) -> Tuple[dict, int]:
    """Lê um script do mapa.
    
    Estrutura de script no Fallout 2 (baseada em análise):
    Cada script tem tamanho fixo de 16 bytes:
    - 4 bytes: PID (tipo << 24 | index)
    - 4 bytes: tile (-1 se não posicionado)
    - 4 bytes: script_id + flags
    - 4 bytes: extra data
    
    A cada 16 scripts, há 4 bytes de checksum.
    """
    script = {}
    
    pid = struct.unpack('>I', data[offset:offset+4])[0]
    script['pid'] = pid
    offset += 4
    
    tile = struct.unpack('>i', data[offset:offset+4])[0]
    script['tile'] = tile
    offset += 4
    
    # Script ID
    script_id = struct.unpack('>i', data[offset:offset+4])[0]
    script['script_id'] = script_id
    offset += 4
    
    # Extra
    extra = struct.unpack('>I', data[offset:offset+4])[0]
    script['extra'] = extra
    offset += 4
    
    return script, offset


def read_object(data: bytes, offset: int) -> Tuple[Optional[MapObject], int]:
    """Lê um objeto do mapa.
    
    Estrutura de objeto no Fallout 2:
    - 4 bytes: ID interno
    - 4 bytes: tile position (-1 se não no mapa)
    - 4 bytes: x screen offset
    - 4 bytes: y screen offset
    - 4 bytes: sx
    - 4 bytes: sy
    - 4 bytes: frame number
    - 4 bytes: orientation
    - 4 bytes: FRM ID (tipo << 24 | id)
    - 4 bytes: flags
    - 4 bytes: elevation
    - 4 bytes: PID (tipo << 24 | id)
    - 4 bytes: cid
    - 4 bytes: light distance
    - 4 bytes: light intensity
    - 4 bytes: outline
    - 4 bytes: script id
    - 4 bytes: owner
    - 4 bytes: script index
    - 4 bytes: inventory count
    - 4 bytes: inventory max
    - 4 bytes: unknown
    Total base: 84 bytes
    + inventory items (cada item tem 8 bytes: count + pid)
    """
    
    if offset + 84 > len(data):
        return None, offset
    
    try:
        # ID interno
        obj_id = struct.unpack('>I', data[offset:offset+4])[0]
        
        # Tile position
        tile = struct.unpack('>i', data[offset+4:offset+8])[0]
        
        # Screen offsets (pular)
        # offset 8-24
        
        # Frame number
        frame = struct.unpack('>I', data[offset+24:offset+28])[0]
        
        # Orientation
        orientation = struct.unpack('>I', data[offset+28:offset+32])[0]
        
        # FRM ID
        frm_id = struct.unpack('>I', data[offset+32:offset+36])[0]
        
        # Flags
        flags = struct.unpack('>I', data[offset+36:offset+40])[0]
        
        # Elevation
        elevation = struct.unpack('>I', data[offset+40:offset+44])[0]
        
        # PID
        pid = struct.unpack('>I', data[offset+44:offset+48])[0]
        
        # Script ID (offset 64)
        script_id = struct.unpack('>i', data[offset+64:offset+68])[0]
        
        # Inventory count (offset 76)
        inv_count = struct.unpack('>I', data[offset+76:offset+80])[0]
        
        # Calcular posição
        if tile >= 0 and tile < 40000:
            x = tile % 100
            y = tile // 100
        else:
            x = 0
            y = 0
        
        # Tipo de objeto baseado no PID
        obj_type_id = (pid >> 24) & 0xFF
        type_names = {0: "item", 1: "critter", 2: "scenery", 3: "wall", 4: "tile", 5: "misc"}
        obj_type = type_names.get(obj_type_id, "misc")
        
        # Tamanho total do objeto
        obj_size = 84
        
        # Ler inventário se houver
        inventory = []
        if inv_count > 0 and inv_count < 100:
            for i in range(inv_count):
                if offset + obj_size + 8 <= len(data):
                    item_count = struct.unpack('>I', data[offset+obj_size:offset+obj_size+4])[0]
                    item_pid = struct.unpack('>I', data[offset+obj_size+4:offset+obj_size+8])[0]
                    inventory.append({"count": item_count, "pid": item_pid})
                    obj_size += 8
        
        obj = MapObject(
            pid=pid,
            x=x,
            y=y,
            elevation=elevation & 0x3,
            orientation=orientation & 0x7,
            script_id=script_id,
            object_type=obj_type,
            frm_id=frm_id,
            flags=flags,
            inventory=inventory if inventory else None
        )
        
        return obj, offset + obj_size
        
    except Exception as e:
        print(f"Erro ao ler objeto em offset {offset}: {e}")
        return None, offset + 84


def parse_map(data: bytes, filename: str, verbose: bool = False) -> dict:
    """Parseia um arquivo MAP do Fallout 2."""
    
    MAP_WIDTH = 100
    MAP_HEIGHT = 100
    TILES_PER_LEVEL = MAP_WIDTH * MAP_HEIGHT
    
    offset = 0
    
    # === HEADER (60 bytes) ===
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
    map_id = struct.unpack('>I', data[offset+8:offset+12])[0]
    timestamp = struct.unpack('>I', data[offset+12:offset+16])[0]
    offset += 16
    
    if verbose:
        print(f"Header: version={version}, name={name}, flags={flags:08X}")
        print(f"  entering: tile={entering_tile}, elev={entering_elev}")
        print(f"  vars: local={local_vars}, global={global_vars}")
    
    # === RESERVED (176 bytes) ===
    offset += 176
    
    # === GLOBAL VARS ===
    offset += global_vars * 4
    
    # === LOCAL VARS ===
    offset += local_vars * 4
    
    if verbose:
        print(f"Offset após vars: {offset}")
    
    # === TILES ===
    tiles = []
    elev_flags = [2, 4, 8]  # Flag 2=elev0 ausente, 4=elev1 ausente, 8=elev2 ausente
    
    for elevation in range(3):
        if (flags & elev_flags[elevation]) != 0:
            continue  # Elevação não presente
        
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
        print(f"Offset após tiles: {offset}, tiles lidos: {len(tiles)}")
    
    # === SCRIPTS (5 seções) ===
    scripts = []
    script_type_names = ["Spatial", "Timed", "Item", "Critter", "Scenery"]
    
    for script_type in range(5):
        if offset + 4 > len(data):
            break
        
        count = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        if verbose:
            print(f"Scripts tipo {script_type} ({script_type_names[script_type]}): {count}")
        
        # Validar count - se for muito grande, provavelmente é erro de parsing
        if count > 1000:
            if verbose:
                print(f"  AVISO: count muito grande ({count}), pulando seção")
            continue
        
        if count > 0:
            for i in range(count):
                if offset + 16 > len(data):
                    break
                script, offset = read_script(data, offset, script_type)
                scripts.append(script)
                
                # Cada 16 scripts, há um checksum de 4 bytes
                if (i + 1) % 16 == 0:
                    offset += 4
    
    if verbose:
        print(f"Offset após scripts: {offset}")
        print(f"Bytes restantes: {len(data) - offset}")
    
    # === OBJETOS (por elevação) ===
    objects = []
    
    for elevation in range(3):
        if (flags & elev_flags[elevation]) != 0:
            continue  # Elevação não presente
        
        if offset + 4 > len(data):
            break
        
        obj_count = struct.unpack('>I', data[offset:offset+4])[0]
        offset += 4
        
        if verbose:
            print(f"Objetos elevação {elevation}: {obj_count}")
        
        if obj_count > 0 and obj_count < 10000:
            for i in range(obj_count):
                if offset + 84 > len(data):
                    break
                
                obj, offset = read_object(data, offset)
                if obj:
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
        map_data = parse_map(data, "artemple.map", verbose=True)
        
        print("\n=== RESULTADO ===")
        print(f"Tiles: {map_data['stats']['total_tiles']}")
        print(f"Objetos: {map_data['stats']['total_objects']}")
        
        if map_data['objects']:
            print("\nPrimeiros 10 objetos:")
            for obj in map_data['objects'][:10]:
                print(f"  {obj['object_type']}: ({obj['x']}, {obj['y']}) PID={obj['pid']:08X}")
        
        # Salvar JSON
        output_path = project_root / "godot_project" / "assets" / "data" / "maps" / "artemple.json"
        with open(output_path, 'w') as f:
            json.dump(map_data, f, indent=2)
        print(f"\nSalvo em: {output_path}")
    
    # Testar com outro mapa que tenha mais objetos
    print("\n" + "=" * 60)
    print("ARVILLAG.MAP (Arroyo Village)")
    print("=" * 60)
    
    data = dat.get("maps/arvillag.map")
    if data:
        map_data = parse_map(data, "arvillag.map", verbose=True)
        
        print("\n=== RESULTADO ===")
        print(f"Tiles: {map_data['stats']['total_tiles']}")
        print(f"Objetos: {map_data['stats']['total_objects']}")
        
        if map_data['objects']:
            print("\nPrimeiros 10 objetos:")
            for obj in map_data['objects'][:10]:
                print(f"  {obj['object_type']}: ({obj['x']}, {obj['y']}) PID={obj['pid']:08X}")
    
    dat.close()


if __name__ == "__main__":
    main()
