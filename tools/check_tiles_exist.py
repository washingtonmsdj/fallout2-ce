#!/usr/bin/env python3
"""Verifica quais tiles do mapeamento existem como arquivos."""

import json
from pathlib import Path

def main():
    m = json.load(open('godot_project/assets/data/tile_mapping.json'))
    tiles_dir = Path('godot_project/assets/sprites/tiles')
    
    missing = []
    found = 0
    
    for k, v in m.items():
        p = tiles_dir / f'{v}.png'
        if p.exists():
            found += 1
        else:
            missing.append((k, v))
    
    print(f'Total no mapeamento: {len(m)}')
    print(f'Encontrados: {found}')
    print(f'Faltando: {len(missing)}')
    print(f'\nPrimeiros 20 faltando:')
    for k, v in missing[:20]:
        print(f'  {k}: {v}')

if __name__ == "__main__":
    main()
