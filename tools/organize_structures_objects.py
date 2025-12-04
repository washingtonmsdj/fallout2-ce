#!/usr/bin/env python3
"""
Organizador de Estruturas, Tiles e Objetos para Jogo AAA
=========================================================
Organiza tiles (casas, paredes, pisos) e objetos (móveis, itens)
com nomes legíveis para facilitar substituição.
"""

import json
import shutil
from pathlib import Path
from datetime import datetime

# Mapeamento de prefixos de tiles do Fallout 2
TILE_PREFIXES = {
    # Pisos (Floor)
    'adb': 'adobe_building',      # Construções de adobe
    'aft': 'afterlife',           # Tiles especiais
    'arfl': 'arroyo_floor',       # Pisos de Arroyo
    'arrf': 'arroyo_roof',        # Telhados de Arroyo
    'brkfl': 'brick_floor',       # Piso de tijolos
    'cavfl': 'cave_floor',        # Piso de caverna
    'ctyfl': 'city_floor',        # Piso urbano
    'desfl': 'desert_floor',      # Piso deserto
    'drtfl': 'dirt_floor',        # Piso de terra
    'grsfl': 'grass_floor',       # Piso de grama
    'mtlfl': 'metal_floor',       # Piso metálico
    'sndfl': 'sand_floor',        # Piso de areia
    'vltfl': 'vault_floor',       # Piso de vault
    'wdfl': 'wood_floor',         # Piso de madeira
    
    # Paredes (Walls)
    'brkwl': 'brick_wall',        # Parede de tijolos
    'cavwl': 'cave_wall',         # Parede de caverna
    'ctywl': 'city_wall',         # Parede urbana
    'mtwl': 'metal_wall',         # Parede metálica
    'vltwl': 'vault_wall',        # Parede de vault
    'wdwl': 'wood_wall',          # Parede de madeira
    
    # Telhados (Roofs)
    'brkrf': 'brick_roof',
    'cavrf': 'cave_roof',
    'ctyrf': 'city_roof',
    'mtrf': 'metal_roof',
    'vltrf': 'vault_roof',
    'wdrf': 'wood_roof',
}

# Mapeamento de objetos do Fallout 2
OBJECT_NAMES = {
    # Móveis
    'desk': 'furniture_desk',
    'dresr': 'furniture_dresser',
    'bkshlf': 'furniture_bookshelf',
    'abkshlf': 'furniture_bookshelf_alt',
    'locker': 'container_locker',
    'footlkr': 'container_footlocker',
    'chest': 'container_chest',
    'safe': 'container_safe',
    'lgsafe': 'container_safe_large',
    'fridge': 'furniture_fridge',
    'bokcas': 'furniture_bookcase',
    'walllkr': 'furniture_wall_locker',
    'wshelv': 'furniture_wall_shelf',
    'tbltop': 'furniture_table',
    'sttable': 'furniture_steel_table',
    'medtbl': 'furniture_medical_table',
    'pooltbl': 'furniture_pool_table',
    
    # Containers
    'bag': 'container_bag',
    'backpack': 'container_backpack',
    'bpack': 'container_backpack',
    'box': 'container_box',
    'bigbox': 'container_box_large',
    'smalbox': 'container_box_small',
    'ibox': 'container_industrial_box',
    'crate': 'container_crate',
    'poorbox': 'container_poor_box',
    'cartrunk': 'container_car_trunk',
    'wepnbox': 'container_weapon_box',
    'boxweap': 'container_weapon_box',
    'ammobox': 'container_ammo_box',
    
    # Armas
    'pistol': 'weapon_pistol',
    'rifle': 'weapon_rifle',
    'minigun': 'weapon_minigun',
    'uzi': 'weapon_uzi',
    'flamethr': 'weapon_flamethrower',
    'rlaunch': 'weapon_rocket_launcher',
    'knife': 'weapon_knife',
    'club': 'weapon_club',
    'sledge': 'weapon_sledgehammer',
    'spear': 'weapon_spear',
    
    # Armaduras
    'ltharmor': 'armor_leather',
    'mtlarmor': 'armor_metal',
    'cmbtflx': 'armor_combat',
    'pwrarmor': 'armor_power',
    'parmor': 'armor_power',
    'robe': 'armor_robe',
    
    # Itens consumíveis
    'beer': 'consumable_beer',
    'stimpak': 'consumable_stimpak',
    'radaway': 'consumable_radaway',
    
    # Itens diversos
    'ammo': 'item_ammo',
    'shell': 'item_shell',
    'rshell': 'item_shell_rocket',
    'battery': 'item_battery',
    'chip': 'item_chip',
    'book': 'item_book',
    'bib': 'item_bible',
    'dynamite': 'item_dynamite',
    'gernade': 'item_grenade',
    'flare': 'item_flare',
    'rope': 'item_rope',
    'rock': 'item_rock',
    'shovel': 'item_shovel',
    'geiger': 'item_geiger_counter',
    'motion': 'item_motion_sensor',
    'motor': 'item_motor',
    'pump': 'item_pump',
    'tanks': 'item_tanks',
    'plstic': 'item_plastic_explosive',
    'suprtool': 'item_super_tool',
    'sttools': 'item_steel_tools',
    'docbag': 'item_doctor_bag',
    'firewood': 'item_firewood',
    'plank': 'item_plank',
    'geck': 'item_geck',
    
    # Decoração
    'flower': 'decor_flower',
    'brocflwr': 'decor_broc_flower',
    'arvase': 'decor_vase',
    'trophy': 'decor_trophy',
    'elvis': 'decor_elvis',
    'elecpic': 'decor_electric_picture',
    'stonhead': 'decor_stone_head',
    'grave': 'decor_grave',
    'arbones': 'decor_bones',
    'body': 'decor_body',
    'v13bones': 'decor_vault13_bones',
    
    # Veículos
    'vertibrd': 'vehicle_vertibird',
    'ccart': 'vehicle_cart',
    
    # Máquinas
    'minemach': 'machine_mining',
    'gunturet': 'machine_turret',
    'gunautoc': 'machine_auto_cannon',
    
    # Criaturas (itens)
    'alien': 'creature_alien_corpse',
    'dclaw': 'creature_deathclaw_corpse',
    'scorptal': 'creature_scorpion_tail',
    'radslimb': 'creature_radscorpion_limb',
    'geckfire': 'creature_gecko_fire',
    
    # Robôs
    'robtrock': 'robot_robobrain_corpse',
    'robtroc': 'robot_robobrain_corpse',
    'rbtmelee': 'robot_melee',
    'thand': 'robot_hand',
    
    # Especiais
    'boss': 'special_boss',
    'trekguy': 'special_star_trek',
    'xander': 'special_xander_root',
    'iceche': 'special_ice_chest',
    'jar': 'special_jar',
    'jcontain': 'special_container',
    'bcasefl': 'special_briefcase',
    'dskglow': 'special_desk_glow',
    'dskmilt': 'special_desk_military',
    'gizdead': 'special_gizmo_dead',
    'donotuse': 'special_do_not_use',
    'reserved': 'special_reserved',
    'maxflr': 'special_max_floor',
}

# Categorias de ambiente para tiles
TILE_ENVIRONMENTS = {
    'desert': ['des', 'sand', 'dirt', 'adb', 'adobe'],
    'city': ['cty', 'city', 'urban', 'brk', 'brick'],
    'cave': ['cav', 'cave', 'rock', 'mine'],
    'vault': ['vlt', 'vault', 'metal', 'mtl'],
    'interior': ['wood', 'wd', 'carpet', 'tile', 'floor'],
    'arroyo': ['arr', 'arroyo', 'tribal'],
    'wasteland': ['waste', 'ruin', 'debris', 'aft'],
}

# Categorias de objetos
OBJECT_CATEGORIES = {
    'furniture': ['desk', 'dresr', 'bkshlf', 'bokcas', 'shelf', 'table', 'fridge', 'pool'],
    'containers': ['locker', 'chest', 'safe', 'bag', 'box', 'crate', 'trunk'],
    'weapons': ['pistol', 'rifle', 'gun', 'knife', 'club', 'sledge', 'spear', 'flame', 'launch'],
    'armor': ['armor', 'robe', 'cmbt', 'pwr'],
    'consumables': ['beer', 'stim', 'rad'],
    'items': ['ammo', 'shell', 'battery', 'chip', 'book', 'dynamite', 'grenade', 'flare', 'rope'],
    'decor': ['flower', 'vase', 'trophy', 'elvis', 'grave', 'bones', 'body'],
    'machines': ['machine', 'turret', 'cannon'],
    'vehicles': ['verti', 'cart', 'car'],
}


class StructureOrganizer:
    def __init__(self, source_path: str, output_path: str):
        self.source = Path(source_path)
        self.output = Path(output_path)
        self.manifest = {
            'version': '1.0',
            'created': datetime.now().isoformat(),
            'tiles': {},
            'objects': {},
            'stats': {'total': 0, 'organized': 0}
        }
    
    def organize_all(self):
        """Organiza todos os tiles e objetos."""
        print("=" * 60)
        print("ORGANIZADOR DE ESTRUTURAS E OBJETOS")
        print("=" * 60)
        
        self._organize_tiles()
        self._organize_objects()
        self._generate_tile_guide()
        self._generate_object_guide()
        self._save_manifest()
        
        print("\n" + "=" * 60)
        print("ORGANIZAÇÃO CONCLUÍDA!")
        print(f"Total: {self.manifest['stats']['total']}")
        print(f"Organizados: {self.manifest['stats']['organized']}")
        print("=" * 60)
    
    def _organize_tiles(self):
        """Organiza tiles por ambiente e tipo."""
        print("\n[1/2] Organizando tiles (pisos, paredes, telhados)...")
        
        tiles_source = self.source / 'assets' / 'sprites' / 'tiles'
        if not tiles_source.exists():
            print("  Pasta de tiles não encontrada!")
            return
        
        tiles_out = self.output / 'assets' / 'tiles_organized'
        
        count = 0
        for tile_file in tiles_source.glob('*.png'):
            if tile_file.name.endswith('.import'):
                continue
            
            self.manifest['stats']['total'] += 1
            
            name = tile_file.stem.lower()
            
            # Determinar ambiente
            environment = self._get_tile_environment(name)
            
            # Determinar tipo (floor, wall, roof)
            tile_type = self._get_tile_type(name)
            
            # Obter nome legível
            readable_name = self._get_tile_readable_name(name)
            
            # Criar estrutura
            dest_dir = tiles_out / environment / tile_type
            dest_dir.mkdir(parents=True, exist_ok=True)
            
            # Copiar com nome legível
            dest_file = dest_dir / f"{readable_name}.png"
            shutil.copy2(tile_file, dest_file)
            count += 1
            self.manifest['stats']['organized'] += 1
            
            # Registrar
            if environment not in self.manifest['tiles']:
                self.manifest['tiles'][environment] = {}
            if tile_type not in self.manifest['tiles'][environment]:
                self.manifest['tiles'][environment][tile_type] = []
            self.manifest['tiles'][environment][tile_type].append(readable_name)
        
        print(f"  Tiles organizados: {count}")
        
        # Gerar manifesto por ambiente
        for env in self.manifest['tiles']:
            env_dir = tiles_out / env
            manifest_data = {
                'environment': env,
                'types': self.manifest['tiles'][env],
                'replacement_guide': {
                    'floor_size': '80x36 pixels (isometric)',
                    'wall_size': '80x80 pixels',
                    'roof_size': '80x36 pixels',
                    'format': 'PNG with transparency'
                }
            }
            with open(env_dir / '_manifest.json', 'w') as f:
                json.dump(manifest_data, f, indent=2)
    
    def _organize_objects(self):
        """Organiza objetos por categoria."""
        print("\n[2/2] Organizando objetos (móveis, itens, containers)...")
        
        items_source = self.source / 'assets' / 'sprites' / 'items'
        if not items_source.exists():
            print("  Pasta de items não encontrada!")
            return
        
        objects_out = self.output / 'assets' / 'objects_organized'
        
        # Processar JSONs de recursos
        json_dir = items_source / 'godot_resources'
        if json_dir.exists():
            count = 0
            for json_file in json_dir.glob('*.json'):
                if '_1.json' in json_file.name:
                    continue  # Pular duplicatas
                
                self.manifest['stats']['total'] += 1
                
                name = json_file.stem.lower()
                
                # Determinar categoria
                category = self._get_object_category(name)
                
                # Obter nome legível
                readable_name = self._get_object_readable_name(name)
                
                # Criar estrutura
                dest_dir = objects_out / category
                dest_dir.mkdir(parents=True, exist_ok=True)
                
                # Copiar JSON
                dest_json = dest_dir / f"{readable_name}.json"
                shutil.copy2(json_file, dest_json)
                
                # Copiar sprites associados se existirem
                sprite_dir = items_source / 'sprites' / json_file.stem.upper()
                if sprite_dir.exists():
                    sprite_dest = dest_dir / readable_name
                    sprite_dest.mkdir(exist_ok=True)
                    for sprite in sprite_dir.glob('*.png'):
                        shutil.copy2(sprite, sprite_dest / sprite.name)
                
                count += 1
                self.manifest['stats']['organized'] += 1
                
                # Registrar
                if category not in self.manifest['objects']:
                    self.manifest['objects'][category] = []
                self.manifest['objects'][category].append(readable_name)
            
            print(f"  Objetos organizados: {count}")
        
        # Gerar manifesto por categoria
        for cat in self.manifest['objects']:
            cat_dir = objects_out / cat
            if cat_dir.exists():
                manifest_data = {
                    'category': cat,
                    'objects': self.manifest['objects'][cat],
                    'replacement_guide': {
                        'format': 'PNG with transparency',
                        'json_format': 'Godot resource format'
                    }
                }
                with open(cat_dir / '_manifest.json', 'w') as f:
                    json.dump(manifest_data, f, indent=2)
    
    def _get_tile_environment(self, name: str) -> str:
        """Determina o ambiente do tile."""
        for env, keywords in TILE_ENVIRONMENTS.items():
            if any(kw in name for kw in keywords):
                return env
        return 'misc'
    
    def _get_tile_type(self, name: str) -> str:
        """Determina o tipo do tile (floor, wall, roof)."""
        if 'fl' in name or 'floor' in name:
            return 'floor'
        elif 'wl' in name or 'wall' in name:
            return 'wall'
        elif 'rf' in name or 'roof' in name:
            return 'roof'
        elif 'db' in name:  # adobe building
            return 'building'
        return 'misc'
    
    def _get_tile_readable_name(self, name: str) -> str:
        """Converte nome de tile para legível."""
        # Tentar match de prefixo
        for prefix, readable in TILE_PREFIXES.items():
            if name.startswith(prefix):
                # Extrair número
                num = name[len(prefix):]
                return f"{readable}_{num}"
        return name
    
    def _get_object_category(self, name: str) -> str:
        """Determina categoria do objeto."""
        for cat, keywords in OBJECT_CATEGORIES.items():
            if any(kw in name for kw in keywords):
                return cat
        return 'misc'
    
    def _get_object_readable_name(self, name: str) -> str:
        """Converte nome de objeto para legível."""
        # Tentar match
        for code, readable in OBJECT_NAMES.items():
            if name.startswith(code) or code in name:
                # Extrair número se houver
                import re
                match = re.search(r'(\d+)$', name)
                if match:
                    return f"{readable}_{match.group(1)}"
                return readable
        return name
    
    def _generate_tile_guide(self):
        """Gera guia de substituição de tiles."""
        guide_path = self.output / 'TILE_REPLACEMENT_GUIDE.md'
        
        guide = """# Guia de Substituição de Tiles

## Estrutura de Pastas

```
tiles_organized/
├── desert/           # Ambiente desértico
│   ├── floor/       # Pisos
│   ├── wall/        # Paredes
│   └── roof/        # Telhados
├── city/            # Ambiente urbano
├── cave/            # Cavernas
├── vault/           # Vaults (bunkers)
├── interior/        # Interiores
├── arroyo/          # Tribal
└── wasteland/       # Wasteland
```

## Dimensões dos Tiles

| Tipo | Dimensões | Descrição |
|------|-----------|-----------|
| Floor | 80x36 px | Piso isométrico |
| Wall | 80x80 px | Parede (pode variar) |
| Roof | 80x36 px | Telhado isométrico |
| Building | Variável | Estruturas completas |

## Como Substituir

1. **Identifique o ambiente** que você quer modificar
2. **Mantenha as dimensões** isométricas (80x36 para pisos)
3. **Use PNG com transparência** onde necessário
4. **Substitua os arquivos** mantendo os mesmos nomes

## Dicas para Jogo AAA

- Crie tilesets consistentes por ambiente
- Use variações (tile_001, tile_002) para evitar repetição
- Considere tiles de transição entre ambientes
- Adicione detalhes como rachaduras, sujeira, etc.

## Ambientes Disponíveis

"""
        
        for env, types in self.manifest['tiles'].items():
            guide += f"\n### {env.title()}\n"
            for tile_type, tiles in types.items():
                guide += f"- **{tile_type}**: {len(tiles)} tiles\n"
        
        with open(guide_path, 'w', encoding='utf-8') as f:
            f.write(guide)
        
        print(f"  Guia de tiles gerado: {guide_path}")
    
    def _generate_object_guide(self):
        """Gera guia de substituição de objetos."""
        guide_path = self.output / 'OBJECT_REPLACEMENT_GUIDE.md'
        
        guide = """# Guia de Substituição de Objetos

## Estrutura de Pastas

```
objects_organized/
├── furniture/       # Móveis (mesas, cadeiras, estantes)
├── containers/      # Containers (baús, armários, cofres)
├── weapons/         # Armas
├── armor/           # Armaduras
├── consumables/     # Consumíveis
├── items/           # Itens diversos
├── decor/           # Decoração
├── machines/        # Máquinas
└── vehicles/        # Veículos
```

## Como Substituir

1. **Localize a categoria** do objeto
2. **Verifique o _manifest.json** da categoria
3. **Substitua o PNG** mantendo dimensões similares
4. **Atualize o JSON** se necessário (propriedades do objeto)

## Categorias de Objetos

"""
        
        for cat, objects in self.manifest['objects'].items():
            guide += f"\n### {cat.title()} ({len(objects)} objetos)\n"
            for obj in objects[:10]:  # Mostrar primeiros 10
                guide += f"- {obj}\n"
            if len(objects) > 10:
                guide += f"- ... e mais {len(objects) - 10}\n"
        
        guide += """
## Dicas para Jogo AAA

- Mantenha consistência visual entre objetos
- Adicione variações de estado (novo, usado, quebrado)
- Considere animações para objetos interativos
- Use iluminação consistente nos sprites
"""
        
        with open(guide_path, 'w', encoding='utf-8') as f:
            f.write(guide)
        
        print(f"  Guia de objetos gerado: {guide_path}")
    
    def _save_manifest(self):
        """Salva manifesto."""
        manifest_path = self.output / 'assets' / 'structures_manifest.json'
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(manifest_path, 'w', encoding='utf-8') as f:
            json.dump(self.manifest, f, indent=2, ensure_ascii=False)
        
        print(f"  Manifesto salvo: {manifest_path}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Organiza tiles e objetos')
    parser.add_argument('--source', default='godot_project', help='Pasta fonte')
    parser.add_argument('--output', default='godot_project', help='Pasta saída')
    
    args = parser.parse_args()
    
    organizer = StructureOrganizer(args.source, args.output)
    organizer.organize_all()


if __name__ == '__main__':
    main()
