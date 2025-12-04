"""
Módulo para geração de arquivos SpriteFrames (.tres) do Godot 4.x.

Este módulo converte animações extraídas para o formato nativo do Godot,
incluindo mapeamento de 6 direções para 8 direções.

Referências:
- Requirements 2.2: Criar arquivo SpriteFrames (.tres) com timing correto
- Requirements 2.3: Mapear 6 direções para 8 direções
"""
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass

from .animation_extractor import AnimationData, AnimationFrame, CritterData
from .spritesheet_generator import SpritesheetMetadata, SpritesheetCollection


@dataclass
class SpriteFramesConfig:
    """Configuração para geração de SpriteFrames."""
    critter_id: str
    animation_name: str
    fps: float
    loop: bool
    frames: List[str]  # Caminhos relativos dos frames


class SpriteFramesGenerator:
    """
    Gerador de arquivos SpriteFrames (.tres) do Godot 4.x.
    
    Converte animações extraídas para o formato nativo do Godot,
    mapeando 6 direções isométricas para 8 direções.
    """
    
    # Mapeamento de 6 direções Fallout para 8 direções Godot
    # Fallout: NE(0), E(1), SE(2), SW(3), W(4), NW(5)
    # Godot: N, NE, E, SE, S, SW, W, NW
    DIRECTION_6_TO_8 = {
        'ne': 'ne',
        'e': 'e',
        'se': 'se',
        'sw': 'sw',
        'w': 'w',
        'nw': 'nw',
        # Direções interpoladas/duplicadas
        'n': 'ne',   # N usa NE
        's': 'se',   # S usa SE
    }
    
    # Ordem das 8 direções no Godot
    GODOT_DIRECTIONS = ['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw']
    
    # Direções originais do Fallout 2
    FALLOUT_DIRECTIONS = ['ne', 'e', 'se', 'sw', 'w', 'nw']
    
    def __init__(self, output_dir: str, assets_base_path: str = "res://assets/critters"):
        """
        Inicializa o gerador de SpriteFrames.
        
        Args:
            output_dir: Diretório de saída para arquivos .tres
            assets_base_path: Caminho base dos assets no Godot (res://)
        """
        self.output_dir = Path(output_dir)
        self.assets_base_path = assets_base_path
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def _generate_tres_header(self) -> str:
        """Gera o header do arquivo .tres."""
        return '[gd_resource type="SpriteFrames" format=3]\n\n'
    
    def _generate_animation_entry(
        self,
        name: str,
        fps: float,
        loop: bool,
        frames: List[str]
    ) -> str:
        """
        Gera uma entrada de animação para o arquivo .tres.
        
        Args:
            name: Nome da animação
            fps: Frames por segundo
            loop: Se a animação deve repetir
            frames: Lista de caminhos de recursos
            
        Returns:
            String formatada para o arquivo .tres
        """
        frames_array = []
        for frame_path in frames:
            frames_array.append(f'{{"duration": 1.0, "texture": ExtResource("{frame_path}")}}')
        
        frames_str = ', '.join(frames_array)
        
        return f'''{{
"frames": [{frames_str}],
"loop": {str(loop).lower()},
"name": &"{name}",
"speed": {fps}
}}'''
    
    def _get_direction_suffix(self, direction: str) -> str:
        """Obtém o sufixo de direção para nomes de animação."""
        return f"_{direction}"
    
    def map_6_to_8_directions(self, frames_6dir: Dict[str, List[str]]) -> Dict[str, List[str]]:
        """
        Mapeia 6 direções para 8 direções.
        
        Args:
            frames_6dir: Dicionário de direção -> lista de frames (6 direções)
            
        Returns:
            Dicionário com 8 direções (N e S duplicados de NE e SE)
        """
        frames_8dir = {}
        
        for godot_dir in self.GODOT_DIRECTIONS:
            source_dir = self.DIRECTION_6_TO_8.get(godot_dir, godot_dir)
            
            if source_dir in frames_6dir:
                frames_8dir[godot_dir] = frames_6dir[source_dir].copy()
            elif godot_dir in frames_6dir:
                frames_8dir[godot_dir] = frames_6dir[godot_dir].copy()
        
        return frames_8dir
    
    def generate_spriteframes_tres(
        self,
        critter_id: str,
        animations: Dict[str, AnimationData],
        frames_base_dir: str
    ) -> str:
        """
        Gera conteúdo do arquivo .tres para uma criatura.
        
        Args:
            critter_id: ID da criatura
            animations: Dicionário de animações
            frames_base_dir: Diretório base dos frames
            
        Returns:
            Conteúdo do arquivo .tres
        """
        # Coletar todos os recursos externos
        ext_resources = {}
        resource_id = 1
        
        # Coletar animações
        animation_entries = []
        
        for anim_type, anim_data in animations.items():
            # Agrupar frames por direção
            frames_by_dir: Dict[str, List[Tuple[int, str]]] = {}
            
            for frame in anim_data.frames:
                dir_name = frame.direction_name
                if dir_name not in frames_by_dir:
                    frames_by_dir[dir_name] = []
                
                # Construir caminho do recurso
                frame_path = f"{self.assets_base_path}/{critter_id}/{anim_type}/{Path(frame.output_path).name}"
                frames_by_dir[dir_name].append((frame.frame_index, frame_path))
            
            # Ordenar frames por índice
            for dir_name in frames_by_dir:
                frames_by_dir[dir_name].sort(key=lambda x: x[0])
            
            # Converter para apenas caminhos
            frames_paths_by_dir = {
                dir_name: [path for _, path in frames]
                for dir_name, frames in frames_by_dir.items()
            }
            
            # Mapear para 8 direções
            frames_8dir = self.map_6_to_8_directions(frames_paths_by_dir)
            
            # Gerar entrada para cada direção
            fps = anim_data.fps if anim_data.fps > 0 else 10.0
            loop = anim_type in ['idle', 'walk', 'run']  # Animações que repetem
            
            for direction, frame_paths in frames_8dir.items():
                if not frame_paths:
                    continue
                
                # Registrar recursos externos
                for path in frame_paths:
                    if path not in ext_resources:
                        ext_resources[path] = resource_id
                        resource_id += 1
                
                # Nome da animação: {tipo}_{direção}
                anim_name = f"{anim_type}{self._get_direction_suffix(direction)}"
                
                animation_entries.append({
                    'name': anim_name,
                    'fps': fps,
                    'loop': loop,
                    'frames': frame_paths
                })
        
        # Gerar arquivo .tres
        return self._build_tres_content(ext_resources, animation_entries)
    
    def _build_tres_content(
        self,
        ext_resources: Dict[str, int],
        animations: List[Dict]
    ) -> str:
        """
        Constrói o conteúdo completo do arquivo .tres.
        
        Args:
            ext_resources: Mapeamento de caminho -> ID de recurso
            animations: Lista de configurações de animação
            
        Returns:
            Conteúdo do arquivo .tres
        """
        lines = []
        
        # Header com contagem de recursos
        load_steps = len(ext_resources) + 1
        lines.append(f'[gd_resource type="SpriteFrames" load_steps={load_steps} format=3]')
        lines.append('')
        
        # Recursos externos (texturas)
        for path, res_id in sorted(ext_resources.items(), key=lambda x: x[1]):
            lines.append(f'[ext_resource type="Texture2D" path="{path}" id="{res_id}"]')
        
        lines.append('')
        lines.append('[resource]')
        
        # Animações
        anim_array = []
        for anim in animations:
            frames_refs = []
            for frame_path in anim['frames']:
                res_id = ext_resources.get(frame_path, 1)
                frames_refs.append(f'{{"duration": 1.0, "texture": ExtResource("{res_id}")}}')
            
            frames_str = ', '.join(frames_refs)
            loop_str = 'true' if anim['loop'] else 'false'
            
            anim_array.append(f'''{{
"frames": [{frames_str}],
"loop": {loop_str},
"name": &"{anim['name']}",
"speed": {anim['fps']}
}}''')
        
        animations_str = ', '.join(anim_array)
        lines.append(f'animations = [{animations_str}]')
        
        return '\n'.join(lines)

    
    def generate_for_critter(
        self,
        critter_data: CritterData,
        frames_base_dir: str
    ) -> str:
        """
        Gera arquivo .tres para uma criatura.
        
        Args:
            critter_data: Dados da criatura
            frames_base_dir: Diretório base dos frames
            
        Returns:
            Caminho do arquivo .tres gerado
        """
        tres_content = self.generate_spriteframes_tres(
            critter_data.critter_id,
            critter_data.animations,
            frames_base_dir
        )
        
        # Salvar arquivo
        output_path = self.output_dir / f"{critter_data.critter_id}.tres"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(tres_content)
        
        return str(output_path)
    
    def generate_for_all_critters(
        self,
        critters: Dict[str, CritterData],
        frames_base_dir: str
    ) -> Dict[str, str]:
        """
        Gera arquivos .tres para todas as criaturas.
        
        Args:
            critters: Dicionário de criaturas
            frames_base_dir: Diretório base dos frames
            
        Returns:
            Dicionário mapeando critter_id para caminho do .tres
        """
        results = {}
        
        for critter_id, critter_data in critters.items():
            print(f"Gerando SpriteFrames para {critter_id}...")
            
            try:
                tres_path = self.generate_for_critter(critter_data, frames_base_dir)
                results[critter_id] = tres_path
            except Exception as e:
                print(f"Erro ao gerar SpriteFrames para {critter_id}: {e}")
        
        print(f"Gerados {len(results)} arquivos SpriteFrames")
        return results
    
    def generate_simple_tres(
        self,
        critter_id: str,
        animation_type: str,
        frame_paths: List[str],
        fps: float = 10.0,
        loop: bool = True
    ) -> str:
        """
        Gera um arquivo .tres simples para uma única animação.
        
        Args:
            critter_id: ID da criatura
            animation_type: Tipo de animação
            frame_paths: Lista de caminhos dos frames
            fps: Frames por segundo
            loop: Se deve repetir
            
        Returns:
            Conteúdo do arquivo .tres
        """
        ext_resources = {}
        for i, path in enumerate(frame_paths, 1):
            ext_resources[path] = i
        
        animations = [{
            'name': animation_type,
            'fps': fps,
            'loop': loop,
            'frames': frame_paths
        }]
        
        return self._build_tres_content(ext_resources, animations)


def generate_godot_spriteframes(
    critters: Dict[str, CritterData],
    frames_base_dir: str,
    output_dir: str,
    assets_base_path: str = "res://assets/critters"
) -> Dict[str, str]:
    """
    Função de conveniência para gerar SpriteFrames para todas as criaturas.
    
    Args:
        critters: Dicionário de criaturas
        frames_base_dir: Diretório base dos frames
        output_dir: Diretório de saída
        assets_base_path: Caminho base no Godot
        
    Returns:
        Dicionário de caminhos gerados
    """
    generator = SpriteFramesGenerator(output_dir, assets_base_path)
    return generator.generate_for_all_critters(critters, frames_base_dir)
