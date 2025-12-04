#!/usr/bin/env python3
"""
Extrator Completo de Animações de Personagens do Fallout 2

Este script extrai TODAS as animações de personagens (critters) do Fallout 2,
organizando em uma estrutura de pastas profissional para uso no Godot.

Estrutura de saída:
godot_project/assets/characters/
├── player/
│   ├── animations/
│   │   ├── idle/
│   │   │   ├── idle_ne.png (spritesheet)
│   │   │   ├── idle_e.png
│   │   │   └── ...
│   │   ├── walk/
│   │   ├── run/
│   │   ├── attack_unarmed/
│   │   └── death/
│   └── player.tres (SpriteFrames resource)
├── npcs/
│   ├── tribal_male/
│   └── ...
└── creatures/
    ├── radscorpion/
    └── ...

Códigos de animação do Fallout 2:
- aa = idle/standing
- ab = walk
- at = run  
- an = attack (unarmed)
- ao = attack (unarmed 2)
- ak = attack (melee)
- al = attack (melee 2)
- ag = attack (ranged single)
- ah = attack (ranged burst)
- aj = attack (throw)
- ba = knockdown (front)
- bb = knockdown (back)
- as = dodge
- ao = hit (front)
- ap = hit (back)
- ch-cj = death animations
"""

import struct
import zlib
import json
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, field
from PIL import Image


# Mapeamento de códigos de animação para nomes legíveis
ANIMATION_CODES = {
    'aa': 'idle',
    'ab': 'walk',
    'at': 'run',
    'an': 'attack_unarmed',
    'ao': 'attack_unarmed_2',
    'ak': 'attack_melee',
    'al': 'attack_melee_2',
    'ag': 'attack_ranged',
    'ah': 'attack_burst',
    'aj': 'attack_throw',
    'as': 'dodge',
    'ae': 'stand_up',
    'ba': 'knockdown_front',
    'bb': 'knockdown_back',
    'ch': 'death_1',
    'ci': 'death_2',
    'cj': 'death_3',
    'ck': 'death_4',
    'cl': 'death_5',
}

# Animações essenciais para o player
PLAYER_ANIMATIONS = ['aa', 'ab', 'at', 'an', 'ak', 'ag', 'ch']

# Nomes das direções
DIRECTION_NAMES = ['ne', 'e', 'se', 'sw', 'w', 'nw']

# Critters importantes para extrair
IMPORTANT_CRITTERS = {
    # Player (Vault Dweller)
    'hmjmps': {'name': 'player_male_jumpsuit', 'category': 'player', 'is_player': True},
    'hfjmps': {'name': 'player_female_jumpsuit', 'category': 'player', 'is_player': True},
    'hmlthr': {'name': 'player_male_leather', 'category': 'player', 'is_player': True},
    'hflthr': {'name': 'player_female_leather', 'category': 'player', 'is_player': True},
    'hmmetl': {'name': 'player_male_metal', 'category': 'player', 'is_player': True},
    'hfmetl': {'name': 'player_female_metal', 'category': 'player', 'is_player': True},
    'hmcmbt': {'name': 'player_male_combat', 'category': 'player', 'is_player': True},
    'hfcmbt': {'name': 'player_female_combat', 'category': 'player', 'is_player': True},
    
    # NPCs Humanos
    'hmwarr': {'name': 'tribal_warrior', 'category': 'npcs'},
    'hfprim': {'name': 'tribal_female', 'category': 'npcs'},
    'hapowr': {'name': 'power_armor', 'category': 'npcs'},
    'hanpwr': {'name': 'advanced_power_armor', 'category': 'npcs'},
    'harobe': {'name': 'robed_figure', 'category': 'npcs'},
    
    # Criaturas
    'mascrp': {'name': 'radscorpion', 'category': 'creatures'},
    'masrat': {'name': 'rat', 'category': 'creatures'},
    'magcko': {'name': 'gecko', 'category': 'creatures'},
    'maddog': {'name': 'dog', 'category': 'creatures'},
    'mabrah': {'name': 'brahmin', 'category': 'creatures'},
    'madeth': {'name': 'deathclaw', 'category': 'creatures'},
    'mamurt': {'name': 'super_mutant', 'category': 'creatures'},
    'marobo': {'name': 'robot', 'category': 'creatures'},
}


@dataclass
class AnimationFrame:
    """Um frame de animação."""
    width: int
    height: int
    offset_x: int
    offset_y: int
    image: Image.Image


@dataclass  
class AnimationDirection:
    """Uma direção de animação com todos os frames."""
    direction_index: int
    direction_name: str
    frames: List[AnimationFrame] = field(default_factory=list)
    
    @property
    def frame_count(self) -> int:
        return len(self.frames)
    
    @property
    def max_width(self) -> int:
        return max((f.width for f in self.frames), default=0)
    
    @property
    def max_height(self) -> int:
        return max((f.height for f in self.frames), default=0)


@dataclass
class Animation:
    """Uma animação completa com todas as direções."""
    code: str
    name: str
    fps: int
    directions: Dict[int, AnimationDirection] = field(default_factory=dict)
    
    @property
    def direction_count(self) -> int:
        return len(self.directions)
    
    @property
    def frame_count(self) -> int:
        if not self.directions:
            return 0
        return max(d.frame_count for d in self.directions.values())


@dataclass
class CharacterAnimations:
    """Todas as animações de um personagem."""
    base_name: str
    display_name: str
    category: str
    animations: Dict[str, Animation] = field(default_factory=dict)


class DAT2Reader:
    """Leitor de arquivos DAT2 do Fallout 2."""
    
    def __init__(self, path: Path):
        self.path = path
        self.files: Dict[str, Tuple[int, int, int, int]] = {}
        self.fh = None
        
    def open(self) -> int:
        """Abre o arquivo DAT e lê o índice."""
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
        """Fecha o arquivo."""
        if self.fh:
            self.fh.close()
            self.fh = None
    
    def get(self, name: str) -> Optional[bytes]:
        """Lê um arquivo do DAT."""
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
    
    def list_files(self, pattern: str = '') -> List[str]:
        """Lista arquivos que contêm o padrão."""
        return [f for f in self.files.keys() if pattern.lower() in f]


class FRMAnimationDecoder:
    """Decodificador de animações FRM - versão corrigida."""
    
    def __init__(self, palette: List[Tuple[int, int, int]]):
        self.palette = palette
    
    def _read_int16_be(self, data: bytes, offset: int) -> int:
        """Lê int16 big-endian com sinal."""
        value = struct.unpack('>H', data[offset:offset+2])[0]
        if value > 32767:
            value -= 65536
        return value
    
    def _read_int32_be(self, data: bytes, offset: int) -> int:
        """Lê int32 big-endian."""
        return struct.unpack('>I', data[offset:offset+4])[0]
    
    def decode(self, data: bytes) -> Optional[Animation]:
        """Decodifica um arquivo FRM em uma Animation."""
        if len(data) < 62:
            return None
        
        # Header (big-endian)
        version = self._read_int32_be(data, 0)
        fps = self._read_int16_be(data, 4)
        action_frame = self._read_int16_be(data, 6)
        frame_count = self._read_int16_be(data, 8)
        
        if fps <= 0:
            fps = 10  # Default FPS
        
        # Offsets por direção
        x_offsets = [self._read_int16_be(data, 10 + i * 2) for i in range(6)]
        y_offsets = [self._read_int16_be(data, 22 + i * 2) for i in range(6)]
        data_offsets = [self._read_int32_be(data, 34 + i * 4) for i in range(6)]
        
        animation = Animation(code='', name='', fps=fps)
        
        # Base offset: header (62 bytes) - SEM padding extra
        # O formato FRM original não usa padding após o header
        base_offset = 62
        
        for direction in range(6):
            # Verificar se direção existe
            if direction > 0 and data_offsets[direction] == data_offsets[direction - 1]:
                continue
            
            # Offset real = base + offset da direção
            offset = base_offset + data_offsets[direction]
            if offset >= len(data):
                continue
            
            anim_dir = AnimationDirection(
                direction_index=direction,
                direction_name=DIRECTION_NAMES[direction]
            )
            
            # Ler todos os frames desta direção
            for frame_idx in range(frame_count):
                if offset + 12 > len(data):
                    break
                
                w = self._read_int16_be(data, offset)
                h = self._read_int16_be(data, offset + 2)
                size = self._read_int32_be(data, offset + 4)
                off_x = self._read_int16_be(data, offset + 8)
                off_y = self._read_int16_be(data, offset + 10)
                
                if w <= 0 or h <= 0 or size <= 0:
                    break
                
                if size > 10000000:  # Sanity check
                    break
                
                pixels_offset = offset + 12
                if pixels_offset + size > len(data):
                    break
                
                # Decodificar pixels (otimizado)
                pixels = data[pixels_offset:pixels_offset + size]
                
                # Criar array de cores RGBA
                rgba_data = bytearray(w * h * 4)
                for i, p in enumerate(pixels):
                    if i >= w * h:
                        break
                    idx = i * 4
                    if p == 0:
                        rgba_data[idx:idx+4] = (0, 0, 0, 0)
                    else:
                        r, g, b = self.palette[p]
                        rgba_data[idx:idx+4] = (r, g, b, 255)
                
                img = Image.frombytes('RGBA', (w, h), bytes(rgba_data))
                
                frame = AnimationFrame(
                    width=w,
                    height=h,
                    offset_x=off_x,
                    offset_y=off_y,
                    image=img
                )
                anim_dir.frames.append(frame)
                
                # Avançar para próximo frame (SEM padding - formato FRM não usa padding)
                offset = pixels_offset + size
            
            if anim_dir.frames:
                animation.directions[direction] = anim_dir
        
        return animation if animation.directions else None


class CharacterAnimationExtractor:
    """Extrator principal de animações de personagens."""
    
    def __init__(self, fallout2_path: Path, output_path: Path):
        self.fallout2_path = fallout2_path
        self.output_path = output_path
        self.critter_dat: Optional[DAT2Reader] = None
        self.master_dat: Optional[DAT2Reader] = None
        self.palette: List[Tuple[int, int, int]] = []
        self.decoder: Optional[FRMAnimationDecoder] = None
        
    def initialize(self) -> bool:
        """Inicializa os leitores de DAT e carrega a paleta."""
        critter_path = self.fallout2_path / "critter.dat"
        master_path = self.fallout2_path / "master.dat"
        
        if not critter_path.exists():
            print(f"ERRO: critter.dat não encontrado em {critter_path}")
            return False
        
        if not master_path.exists():
            print(f"ERRO: master.dat não encontrado em {master_path}")
            return False
        
        # Abrir DATs
        self.critter_dat = DAT2Reader(critter_path)
        self.critter_dat.open()
        print(f"critter.dat: {len(self.critter_dat.files)} arquivos")
        
        self.master_dat = DAT2Reader(master_path)
        self.master_dat.open()
        print(f"master.dat: {len(self.master_dat.files)} arquivos")
        
        # Carregar paleta
        self._load_palette()
        
        # Criar decoder
        self.decoder = FRMAnimationDecoder(self.palette)
        
        return True
    
    def _load_palette(self):
        """Carrega a paleta de cores."""
        pal_data = self.master_dat.get('color.pal')
        if pal_data:
            self.palette = [
                (min(255, pal_data[i*3] * 4),
                 min(255, pal_data[i*3+1] * 4),
                 min(255, pal_data[i*3+2] * 4))
                for i in range(256)
            ]
        else:
            # Paleta grayscale fallback
            self.palette = [(i, i, i) for i in range(256)]
        print(f"Paleta carregada: {len(self.palette)} cores")
    
    def cleanup(self):
        """Fecha os arquivos DAT."""
        if self.critter_dat:
            self.critter_dat.close()
        if self.master_dat:
            self.master_dat.close()

    def extract_character(self, base_name: str, info: dict) -> Optional[CharacterAnimations]:
        """Extrai todas as animações de um personagem."""
        display_name = info.get('name', base_name)
        category = info.get('category', 'npcs')
        animations_to_extract = PLAYER_ANIMATIONS if info.get('is_player') else ['aa', 'ab', 'at', 'ch']
        
        character = CharacterAnimations(
            base_name=base_name,
            display_name=display_name,
            category=category
        )
        
        print(f"\nExtraindo: {display_name} ({base_name})")
        
        for anim_code in animations_to_extract:
            anim_name = ANIMATION_CODES.get(anim_code, anim_code)
            frm_path = f"art/critters/{base_name}{anim_code}.frm"
            frm_data = self.critter_dat.get(frm_path)
            
            if not frm_data:
                print(f"    {anim_name}: arquivo nao encontrado")
                continue
            
            try:
                animation = self.decoder.decode(frm_data)
                if animation:
                    animation.code = anim_code
                    animation.name = anim_name
                    character.animations[anim_code] = animation
                    print(f"  {anim_name}: {animation.direction_count} direcoes, {animation.frame_count} frames")
                else:
                    print(f"    {anim_name}: decode retornou None (size={len(frm_data)})")
            except Exception as e:
                print(f"    {anim_name}: erro no decode: {e}")
        
        return character if character.animations else None
    
    def save_character_animations(self, character: CharacterAnimations):
        """Salva as animações de um personagem como PNGs e gera SpriteFrames .tres"""
        char_dir = self.output_path / character.category / character.display_name
        anim_dir = char_dir / "animations"
        anim_dir.mkdir(parents=True, exist_ok=True)
        
        # Metadados para gerar SpriteFrames
        metadata = {
            'character': character.display_name,
            'animations': {}
        }
        
        # Salvar cada animação
        for anim_code, animation in character.animations.items():
            anim_subdir = anim_dir / animation.name
            anim_subdir.mkdir(exist_ok=True)
            
            for dir_idx, anim_direction in animation.directions.items():
                if not anim_direction.frames:
                    continue
                
                # Usar tamanho fixo para todos os frames (maior frame)
                frame_w = anim_direction.max_width
                frame_h = anim_direction.max_height
                num_frames = len(anim_direction.frames)
                sheet_w = frame_w * num_frames
                
                spritesheet = Image.new('RGBA', (sheet_w, frame_h), (0, 0, 0, 0))
                
                for i, frame in enumerate(anim_direction.frames):
                    # Centralizar frame no slot
                    x_offset = i * frame_w + (frame_w - frame.width) // 2
                    y_offset = (frame_h - frame.height) // 2
                    spritesheet.paste(frame.image, (x_offset, y_offset))
                
                # Salvar spritesheet
                dir_name = DIRECTION_NAMES[dir_idx]
                sheet_path = anim_subdir / f"{animation.name}_{dir_name}.png"
                spritesheet.save(sheet_path)
                
                # Guardar metadados
                anim_key = f"{animation.name}_{dir_name}"
                metadata['animations'][anim_key] = {
                    'path': str(sheet_path.relative_to(char_dir)),
                    'frame_width': frame_w,
                    'frame_height': frame_h,
                    'num_frames': num_frames,
                    'fps': animation.fps,
                    'loop': animation.name in ['idle', 'walk', 'run']
                }
        
        # Salvar metadados JSON
        meta_path = char_dir / "animations_meta.json"
        with open(meta_path, 'w') as f:
            json.dump(metadata, f, indent=2)
        
        # Gerar arquivo .tres (SpriteFrames)
        self._generate_sprite_frames_from_metadata(character, char_dir, metadata)
        
        print(f"  Salvo em: {char_dir}")
    
    def _generate_sprite_frames_from_metadata(self, character: CharacterAnimations, char_dir: Path, metadata: dict):
        """Gera arquivo .tres do Godot com SpriteFrames usando metadados"""
        tres_path = char_dir / f"{character.display_name}.tres"
        
        animations = metadata['animations']
        if not animations:
            return
        
        # Calcular número de sub-resources necessários
        total_atlas = sum(anim['num_frames'] for anim in animations.values())
        load_steps = len(animations) + total_atlas + 1
        
        with open(tres_path, 'w') as f:
            f.write(f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]\n\n')
            
            # External resources (texturas)
            godot_base = f"res://assets/characters/{character.category}/{character.display_name}"
            for idx, (anim_name, anim_data) in enumerate(animations.items(), 1):
                path = f"{godot_base}/{anim_data['path'].replace(chr(92), '/')}"
                f.write(f'[ext_resource type="Texture2D" path="{path}" id="{idx}"]\n')
            
            # Sub-resources (AtlasTextures)
            f.write('\n')
            atlas_id = 1
            atlas_map = {}  # {anim_name: [(atlas_id, frame_idx), ...]}
            
            for idx, (anim_name, anim_data) in enumerate(animations.items(), 1):
                atlas_map[anim_name] = []
                for frame_idx in range(anim_data['num_frames']):
                    x = frame_idx * anim_data['frame_width']
                    f.write(f'[sub_resource type="AtlasTexture" id="AtlasTexture_{atlas_id}"]\n')
                    f.write(f'atlas = ExtResource("{idx}")\n')
                    f.write(f'region = Rect2({x}, 0, {anim_data["frame_width"]}, {anim_data["frame_height"]})\n\n')
                    atlas_map[anim_name].append(atlas_id)
                    atlas_id += 1
            
            # Resource principal
            f.write('[resource]\n')
            f.write('animations = [')
            
            first = True
            for anim_name, anim_data in animations.items():
                if not first:
                    f.write(', ')
                first = False
                
                f.write('{\n')
                f.write(f'"loop": {"true" if anim_data["loop"] else "false"},\n')
                f.write(f'"name": &"{anim_name}",\n')
                f.write(f'"speed": {float(anim_data["fps"])},\n')
                f.write('"frames": [')
                
                for i, aid in enumerate(atlas_map[anim_name]):
                    if i > 0:
                        f.write(', ')
                    f.write('{\n')
                    f.write('"duration": 1.0,\n')
                    f.write(f'"texture": SubResource("AtlasTexture_{aid}")\n')
                    f.write('}')
                
                f.write(']\n')
                f.write('}')
            
            f.write(']\n')
        
        print(f"    SpriteFrames: {tres_path.name}")
    
    def extract_all(self, critters: dict = None):
        """Extrai todos os personagens especificados."""
        if critters is None:
            critters = IMPORTANT_CRITTERS
        
        extracted = 0
        for base_name, info in critters.items():
            character = self.extract_character(base_name, info)
            if character:
                self.save_character_animations(character)
                extracted += 1
        
        print(f"\n=== Extração completa: {extracted} personagens ===")
        return extracted


def main():
    """Função principal."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Extrai animações de personagens do Fallout 2')
    parser.add_argument('--fallout2', '-f', type=str, default='Fallout 2',
                        help='Caminho para pasta do Fallout 2')
    parser.add_argument('--output', '-o', type=str, default='godot_project/assets/characters',
                        help='Pasta de saída')
    parser.add_argument('--player-only', '-p', action='store_true',
                        help='Extrair apenas animações do player')
    
    args = parser.parse_args()
    
    fallout2_path = Path(args.fallout2)
    output_path = Path(args.output)
    
    extractor = CharacterAnimationExtractor(fallout2_path, output_path)
    
    if not extractor.initialize():
        print("Falha ao inicializar extrator")
        return 1
    
    try:
        if args.player_only:
            # Extrair apenas player
            player_critters = {k: v for k, v in IMPORTANT_CRITTERS.items() if v.get('is_player')}
            extractor.extract_all(player_critters)
        else:
            extractor.extract_all()
    finally:
        extractor.cleanup()
    
    return 0


if __name__ == '__main__':
    exit(main())
