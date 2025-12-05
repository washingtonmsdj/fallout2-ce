#!/usr/bin/env python3
"""Verifica mapeamento de tiles do artemple."""

import json
from pathlib import Path

def main():
    # Carregar dados
    with open("godot_project/assets/data/maps/artemple.json") as f:
        map_data = json.load(f)
    
    with open("godot_project/assets/data/tile_mapping.json") as f:
        tile_mapping = json.load(f)
    
    # Verificar tiles do nível 1
    tiles = [t for t in map_data['tiles'] if t['elevation'] == 1]
    
    # Extrair IDs únicos (12 bits inferiores)
    ids = set()
    for t in tiles:
        tile_index = t['floor_id'] & 0xFFF
        if tile_index > 1:
            ids.add(tile_index)
    
    print(f"IDs de tiles usados (nível 1): {len(ids)} únicos")
    print(f"Primeiros 20: {sorted(ids)[:20]}")
    
    print("\nMapeamento para esses IDs:")
    found = 0
    not_found = 0
    for i in sorted(ids)[:20]:
        tile_name = tile_mapping.get(str(i), "NAO ENCONTRADO")
        if tile_name != "NAO ENCONTRADO":
            found += 1
            # Verificar se arquivo existe
            tile_path = Path(f"godot_project/assets/sprites/tiles/{tile_name}.png")
            exists = "OK" if tile_path.exists() else "FALTA"
            print(f"  {i}: {tile_name} [{exists}]")
        else:
            not_found += 1
            print(f"  {i}: NAO ENCONTRADO")
    
    print(f"\nTotal: {found} encontrados, {not_found} não encontrados")

if __name__ == "__main__":
    main()
