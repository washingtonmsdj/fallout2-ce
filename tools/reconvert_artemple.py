#!/usr/bin/env python3
"""Reconverte o mapa artemple com o parser corrigido."""

import struct
import zlib
import json
from pathlib import Path
from dataclasses import dataclass, asdict
from typing import List, Optional


@dataclass
class TileInfo:
    floor_id: int
    roof_id: int
    x: int
    y: int
    elevation: int


class DAT2:
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


def parse_map(data: bytes, filename: str) -> dict:
    """Parseia um arquivo MAP."""
    MAP_WIDTH = 100
    MAP_HEIGHT = 100
    TILES_PER_LEVEL = MAP_WIDTH * MAP_HEIGHT
    
    offset = 0
    
    # Header
    version = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    # Nome
    name_bytes = data[offset:offset+16]
    name = name_bytes.split(b'\x00')[0].decode('latin-1', errors='ignore').strip()
    if not name:
        name = Path(filename).stem
    offset += 16
    
    # Entering
    entering_tile = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    entering_elevation = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    entering_rotation = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    # Local vars
    local_vars = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    # Script index
    script_index = struct.unpack('>i', data[offset:offset+4])[0]
    offset += 4
    
    # Flags
    flags = struct.unpack('>I', data[offset:offset+4])[0]
    offset += 4
    
    # Skip darkness, global_vars, map_id, timestamp
    offset += 16
    
    # Skip reserved (176 bytes)
    offset += 176
    
    # Skip global vars data
    global_vars = struct.unpack('>I', data[offset-176-16+8:offset-176-16+12])[0]
    offset += global_vars * 4
    
    # Skip local vars data
    offset += local_vars * 4
    
    # Ler tiles - respeitar flags de elevação
    elev_flags = [2, 4, 8]
    tiles = []
    
    for elevation in range(3):
        if (flags & elev_flags[elevation]) != 0:
            continue
        
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
                tiles.append(TileInfo(
                    floor_id=floor_id,
                    roof_id=roof_id,
                    x=x,
                    y=y,
                    elevation=elevation
                ))
    
    return {
        "name": name,
        "filename": filename,
        "version": version,
        "width": MAP_WIDTH,
        "height": MAP_HEIGHT,
        "num_levels": 3,
        "entering": {
            "tile": entering_tile,
            "elevation": entering_elevation,
            "rotation": entering_rotation,
            "x": entering_tile % MAP_WIDTH,
            "y": (entering_tile // MAP_WIDTH) % MAP_HEIGHT
        },
        "script": f"script_{script_index}.int" if script_index > 0 else "",
        "flags": flags,
        "tiles": [asdict(t) for t in tiles],
        "objects": [],
        "stats": {
            "total_tiles": len(tiles),
            "total_objects": 0,
            "critters": 0,
            "items": 0,
            "scenery": 0
        }
    }


def main():
    print("Reconvertendo artemple.map...")
    
    dat = DAT2("Fallout 2/master.dat")
    dat.open()
    
    data = dat.get("maps/artemple.map")
    if not data:
        print("Mapa não encontrado!")
        return
    
    map_data = parse_map(data, "maps/artemple.map")
    
    print(f"Tiles: {len(map_data['tiles'])}")
    print(f"Flags: {map_data['flags']} (bin: {bin(map_data['flags'])})")
    print(f"Entering: {map_data['entering']}")
    
    # Verificar floor_ids
    floor_ids = set(t['floor_id'] & 0xFFF for t in map_data['tiles'])
    print(f"Floor IDs únicos: {len(floor_ids)}")
    print(f"Exemplos: {sorted(floor_ids)[:20]}")
    
    # Salvar
    output_path = Path("godot_project/assets/data/maps/artemple.json")
    with open(output_path, 'w') as f:
        json.dump(map_data, f, indent=2)
    
    print(f"Salvo em: {output_path}")
    
    dat.close()


if __name__ == "__main__":
    main()
