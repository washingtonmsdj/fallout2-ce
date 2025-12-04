#!/usr/bin/env python3
"""
Organizador de Assets para Substituição - Jogo AAA
===================================================
Este script reorganiza os assets extraídos do Fallout 2 em uma estrutura
profissional que facilita a substituição por assets originais.

Estrutura de saída:
  assets/
    characters/
      player/
        idle/, walk/, run/, attack/, death/
        _manifest.json
      npcs/
        {npc_name}/
          idle/, walk/, ...
          _manifest.json
    creatures/
      {creature_type}/
        {creature_name}/
          ...
    tiles/
      {environment}/
        floor/, walls/, objects/
    ui/
      menus/, hud/, icons/
    audio/
      music/, sfx/, voice/
"""

import json
import shutil
from pathlib import Path
from datetime import datetime

# Mapeamento de códigos Fallout 2 para nomes legíveis
CRITTER_NAMES = {
    # Humanos Masculinos
    'hmjmps': 'human_male_jumpsuit',
    'hmlthr': 'human_male_leather',
    'hmmetl': 'human_male_metal_armor',
    'hmcmbt': 'human_male_combat_armor',
    'hmmaxx': 'human_male_advanced_armor',
    'hmwarr': 'human_male_tribal',
    'hmbmet': 'human_male_brotherhood',
    'hmbjmp': 'human_male_vault_suit',
    
    # Humanos Femininos
    'hflthr': 'human_female_leather',
    'hfmetl': 'human_female_metal_armor',
    'hfcmbt': 'human_female_combat_armor',
    'hfmaxx': 'human_female_advanced_armor',
    'hfprim': 'human_female_tribal',
    'hfjmps': 'human_female_jumpsuit',
    
    # Power Armor
    'hapowr': 'human_power_armor',
    'hapowa': 'human_power_armor_advanced',
    'hanpwr': 'human_power_armor_enclave',
    'harobe': 'human_robe',
    
    # Mutantes
    'mamtnt': 'super_mutant',
    'mamtn2': 'super_mutant_armored',
    'mamurt': 'super_mutant_master',
    
    # Criaturas
    'maclaw': 'deathclaw',
    'maclw2': 'deathclaw_mother',
    'magcko': 'gecko',
    'magko2': 'gecko_fire',
    'mascrp': 'radscorpion',
    'mascp2': 'radscorpion_giant',
    'mamrat': 'mole_rat',
    'masrat': 'rat',
    'maddog': 'wild_dog',
    'mabrah': 'brahmin',
    'mabrom': 'brahmin_mutant',
    
    # Robôs
    'marobo': 'robot_robobrain',
    'marobt': 'robot_turret',
    'mahand': 'robot_mr_handy',
    'macybr': 'robot_cyborg',
    'magunn': 'robot_sentry',
    'magun2': 'robot_sentry_heavy',
    
    # Aliens e Especiais
    'malien': 'alien',
    'maboss': 'boss_master',
    'mabos2': 'boss_frank_horrigan',
    'maplnt': 'plant_spore',
    'mafloat': 'floater',
    'macent': 'centaur',
    'mafey': 'wanamingo',
    'madegg': 'deathclaw_egg',
    'madeth': 'death_animation',
}

# Tipos de animação do Fallout 2
ANIMATION_TYPES = {
    'aa': 'idle',
    'ab': 'walk',
    'ao': 'run',
    'at': 'attack_punch',
    'ak': 'attack_kick',
    'an': 'attack_swing',
    'aj': 'attack_thrust',
    'ag': 'attack_throw',
    'al': 'attack_fire_single',
    'am': 'attack_fire_burst',
    'ae': 'dodge',
    'ba': 'death_normal',
    'bb': 'death_critical',
    'bc': 'death_burn',
    'bd': 'death_explode',
    'be': 'death_melt',
    'bf': 'death_knockout',
    'as': 'stand_up',
    'ch': 'hit_front',
    'ci': 'hit_back',
}

# Categorias de criaturas
CREATURE_CATEGORIES = {
    'human': ['hm', 'hf', 'ha', 'hn'],
    'mutant': ['ma'],
    'robot': ['ro', 'cy', 'gu', 'ha'],
    'animal': ['do', 'ra', 'br', 'gc'],
    'monster': ['cl', 'sc', 'fl', 'ce', 'fe', 'pl'],
}


class AssetOrganizer:
    def __init__(self, source_path: str, output_path: str):
        self.source = Path(source_path)
        self.output = Path(output_path)
        self.manifest = {
            'version': '1.0',
            'created': datetime.now().isoformat(),
            'characters': {},
            'creatures': {},
            'tiles': {},
            'ui': {},
            'audio': {},
            'stats': {
                'total_files': 0,
                'organized_files': 0,
                'categories': {}
            }
        }
    
    def organize_all(self):
        """Organiza todos os assets."""
        print("=" * 60)
        print("ORGANIZADOR DE ASSETS PARA JOGO AAA")
        print("=" * 60)
        
        self._organize_characters()
        self._organize_tiles()
        self._organize_ui()
        self._organize_audio()
        self._generate_replacement_guide()
        self._generate_summary()
        self._save_manifest()
        
        print("\n" + "=" * 60)
        print("ORGANIZAÇÃO CONCLUÍDA!")
        print(f"Total de arquivos: {self.manifest['stats']['total_files']}")
        print(f"Arquivos organizados: {self.manifest['stats']['organized_files']}")
        print("=" * 60)
    
    def _organize_characters(self):
        """Organiza sprites de personagens e criaturas."""
        print("\n[1/4] Organizando personagens e criaturas...")
        
        critters_path = self.source / 'assets' / 'sprites' / 'critters'
        if not critters_path.exists():
            print("  Pasta de critters não encontrada!")
            return
        
        # Criar estrutura de saída
        chars_out = self.output / 'assets' / 'characters'
        creatures_out = self.output / 'assets' / 'creatures'
        
        # Processar cada arquivo
        for png_file in critters_path.glob('*.png'):
            if png_file.name.endswith('.import'):
                continue
            
            self.manifest['stats']['total_files'] += 1
            
            # Decodificar nome
            base_name = png_file.stem.lower()
            
            # Identificar tipo de criatura e animação
            critter_code = base_name[:6] if len(base_name) >= 6 else base_name
            anim_code = base_name[6:8] if len(base_name) >= 8 else 'aa'
            
            # Obter nome legível
            readable_name = self._get_readable_name(critter_code)
            anim_name = ANIMATION_TYPES.get(anim_code, 'unknown')
            
            # Determinar categoria
            category = self._get_category(critter_code)
            
            # Criar estrutura de pastas
            if category == 'human':
                dest_base = chars_out / 'npcs' / readable_name
            else:
                dest_base = creatures_out / category / readable_name
            
            dest_dir = dest_base / anim_name
            dest_dir.mkdir(parents=True, exist_ok=True)
            
            # Copiar arquivo
            dest_file = dest_dir / f"{anim_name}_frame_0.png"
            shutil.copy2(png_file, dest_file)
            self.manifest['stats']['organized_files'] += 1
            
            # Registrar no manifesto
            self._register_character(readable_name, category, anim_name, str(dest_file))
        
        # Gerar manifestos individuais por personagem
        self._generate_character_manifests(chars_out)
        self._generate_character_manifests(creatures_out)
        
        print(f"  Personagens organizados: {len(self.manifest['characters'])}")
        print(f"  Criaturas organizadas: {len(self.manifest['creatures'])}")
    
    def _get_readable_name(self, code: str) -> str:
        """Converte código para nome legível."""
        # Tentar match exato primeiro
        for key, name in CRITTER_NAMES.items():
            if code.startswith(key):
                return name
        
        # Fallback: usar código com prefixo descritivo
        if code.startswith('hm'):
            return f"human_male_{code[2:]}"
        elif code.startswith('hf'):
            return f"human_female_{code[2:]}"
        elif code.startswith('ma'):
            return f"creature_{code[2:]}"
        
        return f"unknown_{code}"
    
    def _get_category(self, code: str) -> str:
        """Determina categoria da criatura."""
        prefix = code[:2].lower()
        
        if prefix in ['hm', 'hf', 'ha', 'hn']:
            return 'human'
        elif prefix == 'ma':
            # Verificar subcategoria de monstros
            if any(code.startswith(f'ma{x}') for x in ['claw', 'scrp', 'rat', 'dog', 'bra']):
                return 'animal'
            elif any(code.startswith(f'ma{x}') for x in ['robo', 'hand', 'gunn', 'cybr']):
                return 'robot'
            elif any(code.startswith(f'ma{x}') for x in ['mtnt', 'murt']):
                return 'mutant'
            else:
                return 'monster'
        
        return 'other'
    
    def _register_character(self, name: str, category: str, animation: str, path: str):
        """Registra personagem no manifesto."""
        target = self.manifest['characters'] if category == 'human' else self.manifest['creatures']
        
        if name not in target:
            target[name] = {
                'category': category,
                'animations': {},
                'replacement_ready': True
            }
        
        if animation not in target[name]['animations']:
            target[name]['animations'][animation] = []
        
        target[name]['animations'][animation].append(path)
    
    def _generate_character_manifests(self, base_path: Path):
        """Gera arquivo _manifest.json para cada personagem."""
        if not base_path.exists():
            return
        
        for char_dir in base_path.rglob('*'):
            if char_dir.is_dir() and not char_dir.name.startswith('_'):
                # Verificar se tem animações
                anims = [d.name for d in char_dir.iterdir() if d.is_dir()]
                if anims:
                    manifest = {
                        'name': char_dir.name,
                        'animations': anims,
                        'directions': 6,
                        'replacement_guide': {
                            'sprite_size': '80x80 recommended',
                            'format': 'PNG with transparency',
                            'naming': '{animation}_frame_{n}.png',
                            'directions': ['ne', 'e', 'se', 'sw', 'w', 'nw']
                        }
                    }
                    
                    manifest_path = char_dir / '_manifest.json'
                    with open(manifest_path, 'w', encoding='utf-8') as f:
                        json.dump(manifest, f, indent=2, ensure_ascii=False)
    
    def _organize_tiles(self):
        """Organiza tiles de mapa."""
        print("\n[2/4] Organizando tiles...")
        
        tiles_path = self.source / 'assets' / 'sprites' / 'tiles'
        if not tiles_path.exists():
            print("  Pasta de tiles não encontrada!")
            return
        
        tiles_out = self.output / 'assets' / 'tiles'
        
        # Categorias de ambiente
        environments = {
            'desert': ['des', 'sand', 'dirt'],
            'city': ['city', 'urban', 'street', 'road'],
            'cave': ['cave', 'rock', 'mine'],
            'vault': ['vault', 'metal', 'floor'],
            'interior': ['wood', 'carpet', 'tile'],
            'wasteland': ['waste', 'ruin', 'debris']
        }
        
        count = 0
        for tile_file in tiles_path.rglob('*.png'):
            if tile_file.name.endswith('.import'):
                continue
            
            self.manifest['stats']['total_files'] += 1
            
            # Determinar ambiente
            env = 'misc'
            name_lower = tile_file.stem.lower()
            for env_name, keywords in environments.items():
                if any(kw in name_lower for kw in keywords):
                    env = env_name
                    break
            
            # Copiar para estrutura organizada
            dest_dir = tiles_out / env
            dest_dir.mkdir(parents=True, exist_ok=True)
            
            shutil.copy2(tile_file, dest_dir / tile_file.name)
            count += 1
            self.manifest['stats']['organized_files'] += 1
        
        print(f"  Tiles organizados: {count}")
    
    def _organize_ui(self):
        """Organiza elementos de UI."""
        print("\n[3/4] Organizando UI...")
        
        ui_path = self.source / 'assets' / 'sprites' / 'ui'
        if not ui_path.exists():
            print("  Pasta de UI não encontrada!")
            return
        
        ui_out = self.output / 'assets' / 'ui'
        
        count = 0
        for ui_file in ui_path.rglob('*.png'):
            if ui_file.name.endswith('.import'):
                continue
            
            self.manifest['stats']['total_files'] += 1
            
            # Categorizar UI
            name_lower = ui_file.stem.lower()
            if any(x in name_lower for x in ['menu', 'main', 'title']):
                category = 'menus'
            elif any(x in name_lower for x in ['btn', 'button']):
                category = 'buttons'
            elif any(x in name_lower for x in ['icon', 'item']):
                category = 'icons'
            elif any(x in name_lower for x in ['hud', 'bar', 'panel']):
                category = 'hud'
            else:
                category = 'misc'
            
            dest_dir = ui_out / category
            dest_dir.mkdir(parents=True, exist_ok=True)
            
            shutil.copy2(ui_file, dest_dir / ui_file.name)
            count += 1
            self.manifest['stats']['organized_files'] += 1
        
        print(f"  Elementos de UI organizados: {count}")
    
    def _organize_audio(self):
        """Organiza arquivos de áudio."""
        print("\n[4/4] Organizando áudio...")
        
        audio_path = self.source / 'assets' / 'audio'
        if not audio_path.exists():
            print("  Pasta de áudio não encontrada!")
            return
        
        audio_out = self.output / 'assets' / 'audio'
        
        count = 0
        for audio_file in audio_path.rglob('*'):
            if audio_file.is_file() and audio_file.suffix in ['.ogg', '.wav', '.mp3']:
                self.manifest['stats']['total_files'] += 1
                
                # Manter estrutura existente
                rel_path = audio_file.relative_to(audio_path)
                dest_file = audio_out / rel_path
                dest_file.parent.mkdir(parents=True, exist_ok=True)
                
                shutil.copy2(audio_file, dest_file)
                count += 1
                self.manifest['stats']['organized_files'] += 1
        
        print(f"  Arquivos de áudio organizados: {count}")
    
    def _generate_replacement_guide(self):
        """Gera guia de substituição de assets."""
        guide_path = self.output / 'ASSET_REPLACEMENT_GUIDE.md'
        
        guide = """# Guia de Substituição de Assets

## Visão Geral

Este guia explica como substituir os assets placeholder pelos seus próprios assets originais.

## Estrutura de Pastas

```
assets/
├── characters/           # Personagens jogáveis e NPCs
│   ├── player/          # Personagem principal
│   └── npcs/            # NPCs do jogo
│       └── {npc_name}/  # Cada NPC em sua pasta
│           ├── idle/    # Animação parada
│           ├── walk/    # Animação andando
│           ├── run/     # Animação correndo
│           ├── attack/  # Animações de ataque
│           └── _manifest.json
├── creatures/           # Criaturas e inimigos
│   ├── animal/
│   ├── monster/
│   ├── mutant/
│   └── robot/
├── tiles/               # Tiles de mapa
│   ├── desert/
│   ├── city/
│   ├── cave/
│   └── interior/
├── ui/                  # Interface do usuário
│   ├── menus/
│   ├── hud/
│   ├── buttons/
│   └── icons/
└── audio/               # Áudio
    ├── music/
    ├── sfx/
    └── voice/
```

## Como Substituir Personagens

### 1. Localize a pasta do personagem
Cada personagem tem sua própria pasta em `characters/npcs/` ou `creatures/`.

### 2. Verifique o _manifest.json
O arquivo `_manifest.json` contém:
- Lista de animações necessárias
- Número de direções (geralmente 6)
- Tamanho recomendado dos sprites
- Formato de nomenclatura

### 3. Crie seus sprites
- **Tamanho recomendado**: 80x80 pixels (pode variar)
- **Formato**: PNG com transparência
- **Direções**: NE, E, SE, SW, W, NW (6 direções isométricas)
- **Nomenclatura**: `{animacao}_frame_{n}.png`

### 4. Substitua os arquivos
Simplesmente substitua os PNGs existentes pelos seus.

## Animações Necessárias

| Animação | Descrição | Frames típicos |
|----------|-----------|----------------|
| idle | Parado | 1-4 |
| walk | Andando | 6-8 |
| run | Correndo | 6-8 |
| attack_punch | Soco | 4-6 |
| attack_kick | Chute | 4-6 |
| attack_fire | Atirando | 3-5 |
| death_normal | Morte normal | 6-10 |
| hit_front | Recebendo dano | 2-3 |

## Como Substituir Tiles

1. Localize a categoria em `tiles/`
2. Mantenha as dimensões isométricas: **80x36 pixels** para tiles de chão
3. Use PNG com transparência onde necessário
4. Mantenha o mesmo nome de arquivo ou atualize as referências

## Como Substituir UI

1. Localize o elemento em `ui/`
2. Mantenha as mesmas dimensões ou ajuste o código
3. Use PNG com transparência
4. Teste no jogo após substituição

## Dicas para Jogo AAA

1. **Consistência visual**: Mantenha um estilo artístico consistente
2. **Resolução**: Considere suportar múltiplas resoluções (1x, 2x, 4x)
3. **Animações fluidas**: Use mais frames para animações mais suaves
4. **Efeitos**: Adicione partículas e efeitos visuais
5. **Som**: Substitua todos os sons por áudio original de alta qualidade

## Checklist de Substituição

- [ ] Personagem principal (player)
- [ ] NPCs principais
- [ ] Inimigos comuns
- [ ] Bosses
- [ ] Tiles de ambiente
- [ ] Interface do usuário
- [ ] Ícones de itens
- [ ] Música de fundo
- [ ] Efeitos sonoros
- [ ] Vozes/Diálogos

"""
        
        with open(guide_path, 'w', encoding='utf-8') as f:
            f.write(guide)
        
        print(f"\n  Guia de substituição gerado: {guide_path}")
    
    def _generate_summary(self):
        """Gera sumário dos assets."""
        summary_path = self.output / 'ASSETS_SUMMARY.md'
        
        summary = f"""# Sumário de Assets

Gerado em: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

## Estatísticas

- **Total de arquivos**: {self.manifest['stats']['total_files']}
- **Arquivos organizados**: {self.manifest['stats']['organized_files']}

## Personagens ({len(self.manifest['characters'])})

| Nome | Categoria | Animações |
|------|-----------|-----------|
"""
        
        for name, data in sorted(self.manifest['characters'].items()):
            anims = ', '.join(data['animations'].keys())
            summary += f"| {name} | {data['category']} | {anims} |\n"
        
        summary += f"""
## Criaturas ({len(self.manifest['creatures'])})

| Nome | Categoria | Animações |
|------|-----------|-----------|
"""
        
        for name, data in sorted(self.manifest['creatures'].items()):
            anims = ', '.join(data['animations'].keys())
            summary += f"| {name} | {data['category']} | {anims} |\n"
        
        summary += """
## Próximos Passos

1. Revise os assets extraídos
2. Identifique quais personagens/criaturas você precisa
3. Delete os que não vai usar
4. Substitua os restantes pelos seus assets originais
5. Teste no jogo

## Arquivos Importantes

- `ASSET_REPLACEMENT_GUIDE.md` - Guia detalhado de substituição
- `assets/manifest.json` - Manifesto completo de todos os assets
"""
        
        with open(summary_path, 'w', encoding='utf-8') as f:
            f.write(summary)
        
        print(f"  Sumário gerado: {summary_path}")
    
    def _save_manifest(self):
        """Salva manifesto principal."""
        manifest_path = self.output / 'assets' / 'manifest.json'
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(manifest_path, 'w', encoding='utf-8') as f:
            json.dump(self.manifest, f, indent=2, ensure_ascii=False)
        
        print(f"  Manifesto salvo: {manifest_path}")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(description='Organiza assets para substituição em jogo AAA')
    parser.add_argument('--source', default='godot_project', help='Pasta fonte dos assets')
    parser.add_argument('--output', default='godot_project', help='Pasta de saída')
    
    args = parser.parse_args()
    
    organizer = AssetOrganizer(args.source, args.output)
    organizer.organize_all()


if __name__ == '__main__':
    main()
