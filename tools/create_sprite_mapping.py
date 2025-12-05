#!/usr/bin/env python3
"""
Cria mapeamento de sprites renomeados para o sistema de carregamento de mapas.
Analisa os sprites existentes e gera arquivo JSON de mapeamento.
"""

import json
from pathlib import Path
from collections import defaultdict

def scan_sprites():
    """Escaneia todos os sprites disponíveis."""
    sprites_dir = Path("godot_project/assets/sprites")
    
    sprite_map = {
        "tiles": {},
        "critters": {},
        "items": {},
        "characters": {},
        "ui": {}
    }
    
    # Escanear cada pasta
    for category in sprite_map.keys():
        category_path = sprites_dir / category
        if not category_path.exists():
            continue
        
        for sprite_file in category_path.glob("*.png"):
            # Nome sem extensão
            name = sprite_file.stem
            # Caminho relativo
            rel_path = f"{category}/{sprite_file.name}"
            sprite_map[category][name] = rel_path
    
    return sprite_map


def create_tile_mapping():
    """Cria mapeamento específico para tiles (já existe tile_mapping.json)."""
    tile_mapping_path = Path("godot_project/assets/data/tile_mapping.json")
    
    if tile_mapping_path.exists():
        with open(tile_mapping_path) as f:
            return json.load(f)
    
    return {}


def create_object_sprite_mapping():
    """
    Cria mapeamento de objetos baseado nos sprites disponíveis.
    Como não temos relação direta PID → nome de arquivo,
    vamos criar um sistema de busca por padrão.
    """
    
    sprites_dir = Path("godot_project/assets/sprites")
    
    # Mapear todos os sprites disponíveis por categoria
    mapping = {
        "critters": [],
        "items": [],
        "scenery": [],
        "walls": [],
        "misc": []
    }
    
    # Critters
    critters_dir = sprites_dir / "critters"
    if critters_dir.exists():
        for sprite in critters_dir.glob("*.png"):
            mapping["critters"].append({
                "filename": sprite.name,
                "name": sprite.stem,
                "path": f"critters/{sprite.name}"
            })
    
    # Characters (também podem ser critters)
    characters_dir = sprites_dir / "characters"
    if characters_dir.exists():
        for sprite in characters_dir.glob("*.png"):
            mapping["critters"].append({
                "filename": sprite.name,
                "name": sprite.stem,
                "path": f"characters/{sprite.name}"
            })
    
    # Items
    items_dir = sprites_dir / "items"
    if items_dir.exists():
        for sprite in items_dir.glob("*.png"):
            mapping["items"].append({
                "filename": sprite.name,
                "name": sprite.stem,
                "path": f"items/{sprite.name}"
            })
    
    return mapping


def main():
    print("=" * 70)
    print("CRIANDO MAPEAMENTO DE SPRITES")
    print("=" * 70)
    
    # Escanear sprites
    print("\n1. Escaneando sprites disponíveis...")
    sprite_map = scan_sprites()
    
    for category, sprites in sprite_map.items():
        print(f"   {category}: {len(sprites)} sprites")
    
    # Criar mapeamento de objetos
    print("\n2. Criando mapeamento de objetos...")
    object_mapping = create_object_sprite_mapping()
    
    for obj_type, sprites in object_mapping.items():
        print(f"   {obj_type}: {len(sprites)} sprites")
    
    # Salvar mapeamento
    output_path = Path("godot_project/assets/data/sprite_catalog.json")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    catalog = {
        "version": "1.0",
        "generated": "2025-12-05",
        "description": "Catálogo de sprites disponíveis para objetos do mapa",
        "sprites_by_category": sprite_map,
        "objects": object_mapping
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(catalog, f, indent=2, ensure_ascii=False)
    
    print(f"\n3. Catálogo salvo em: {output_path}")
    
    # Estatísticas
    total_sprites = sum(len(sprites) for sprites in sprite_map.values())
    total_objects = sum(len(sprites) for sprites in object_mapping.values())
    
    print("\n" + "=" * 70)
    print("RESUMO")
    print("=" * 70)
    print(f"Total de sprites catalogados: {total_sprites}")
    print(f"Total de objetos mapeados: {total_objects}")
    print(f"  - Critters: {len(object_mapping['critters'])}")
    print(f"  - Items: {len(object_mapping['items'])}")
    print("=" * 70)
    
    return True


if __name__ == '__main__':
    import sys
    success = main()
    sys.exit(0 if success else 1)
