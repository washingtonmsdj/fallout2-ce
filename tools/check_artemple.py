#!/usr/bin/env python3
"""Verifica os dados do mapa artemple."""

import json
from pathlib import Path

def main():
    json_path = Path("godot_project/assets/data/maps/artemple.json")
    
    with open(json_path) as f:
        data = json.load(f)
    
    tiles = data['tiles']
    
    print("Estatísticas do mapa artemple:")
    print(f"  Total de tiles: {len(tiles)}")
    print(f"  Entering: {data['entering']}")
    
    for elevation in [0, 1, 2]:
        level_tiles = [t for t in tiles if t['elevation'] == elevation]
        floor_ids = set(t['floor_id'] for t in level_tiles)
        roof_ids = set(t['roof_id'] for t in level_tiles)
        
        print(f"\n  Nível {elevation}:")
        print(f"    Tiles: {len(level_tiles)}")
        print(f"    Floor IDs únicos: {len(floor_ids)} - {sorted(floor_ids)[:20]}")
        print(f"    Roof IDs únicos: {len(roof_ids)} - {sorted(roof_ids)[:20]}")
    
    # Verificar objetos
    objects = data.get('objects', [])
    print(f"\n  Objetos: {len(objects)}")
    if objects:
        obj_types = {}
        for obj in objects:
            t = obj.get('object_type', 'unknown')
            obj_types[t] = obj_types.get(t, 0) + 1
        print(f"    Por tipo: {obj_types}")

if __name__ == "__main__":
    main()
