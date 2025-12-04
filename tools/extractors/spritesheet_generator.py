"""
Módulo para geração de spritesheets a partir de animações extraídas.

Este módulo combina frames individuais em spritesheets únicos por animação/direção
e gera metadados JSON com timing e dimensões.

Referências:
- Requirements 1.2: Exportar como spritesheet com metadados
"""
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict
from PIL import Image

from .animation_extractor import AnimationData, AnimationFrame, CritterData
from .frm_decoder import FRMDecoder


@dataclass
class SpritesheetMetadata:
    """Metadados de um spritesheet."""
    critter_id: str
    animation_type: str
    direction: str
    frame_count: int
    frame_width: int
    frame_height: int
    sheet_width: int
    sheet_height: int
    fps: int
    frame_duration_ms: float
    frames: List[Dict]  # Lista de {x, y, width, height, offset_x, offset_y}
    output_path: str


@dataclass
class SpritesheetCollection:
    """Coleção de spritesheets para uma criatura."""
    critter_id: str
    critter_type: str
    spritesheets: Dict[str, SpritesheetMetadata]  # key: "{animation}_{direction}"
    total_sheets: int


class SpritesheetGenerator:
    """
    Gerador de spritesheets a partir de frames de animação.
    
    Combina frames individuais em spritesheets horizontais ou em grid,
    gerando metadados JSON para uso em engines de jogos.
    """
    
    DIRECTION_NAMES = ['ne', 'e', 'se', 'sw', 'w', 'nw']
    
    def __init__(self, output_dir: str):
        """
        Inicializa o gerador de spritesheets.
        
        Args:
            output_dir: Diretório base de saída
        """
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def generate_spritesheet_from_frames(
        self,
        frame_paths: List[str],
        output_path: str,
        layout: str = 'horizontal'
    ) -> Tuple[int, int, List[Dict]]:
        """
        Gera um spritesheet a partir de uma lista de caminhos de frames.
        
        Args:
            frame_paths: Lista de caminhos para arquivos PNG de frames
            output_path: Caminho de saída do spritesheet
            layout: 'horizontal' ou 'grid'
            
        Returns:
            Tupla (sheet_width, sheet_height, frame_rects)
        """
        if not frame_paths:
            raise ValueError("Lista de frames vazia")
        
        # Carregar todos os frames
        frames: List[Image.Image] = []
        for path in frame_paths:
            img = Image.open(path)
            frames.append(img)
        
        # Calcular dimensões
        max_width = max(f.width for f in frames)
        max_height = max(f.height for f in frames)
        num_frames = len(frames)
        
        if layout == 'horizontal':
            sheet_width = max_width * num_frames
            sheet_height = max_height
            cols = num_frames
            rows = 1
        else:  # grid
            # Calcular grid quadrado aproximado
            import math
            cols = math.ceil(math.sqrt(num_frames))
            rows = math.ceil(num_frames / cols)
            sheet_width = max_width * cols
            sheet_height = max_height * rows
        
        # Criar spritesheet
        spritesheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))
        
        # Posicionar frames e coletar retângulos
        frame_rects = []
        for idx, frame in enumerate(frames):
            if layout == 'horizontal':
                x = idx * max_width
                y = 0
            else:
                col = idx % cols
                row = idx // cols
                x = col * max_width
                y = row * max_height
            
            # Centralizar frame no slot
            x_offset = (max_width - frame.width) // 2
            y_offset = (max_height - frame.height) // 2
            
            spritesheet.paste(frame, (x + x_offset, y + y_offset))
            
            frame_rects.append({
                'x': x,
                'y': y,
                'width': max_width,
                'height': max_height,
                'actual_width': frame.width,
                'actual_height': frame.height,
                'x_offset': x_offset,
                'y_offset': y_offset
            })
        
        # Fechar imagens
        for frame in frames:
            frame.close()
        
        # Salvar spritesheet
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        spritesheet.save(output_file, 'PNG')
        spritesheet.close()
        
        return sheet_width, sheet_height, frame_rects
    
    def generate_animation_spritesheet(
        self,
        animation_data: AnimationData,
        critter_id: str,
        frames_base_dir: str,
        direction: Optional[str] = None
    ) -> List[SpritesheetMetadata]:
        """
        Gera spritesheets para uma animação.
        
        Args:
            animation_data: Dados da animação
            critter_id: ID da criatura
            frames_base_dir: Diretório base onde estão os frames
            direction: Direção específica (None = todas)
            
        Returns:
            Lista de metadados dos spritesheets gerados
        """
        results = []
        
        # Agrupar frames por direção
        frames_by_direction: Dict[str, List[AnimationFrame]] = {}
        for frame in animation_data.frames:
            dir_name = frame.direction_name
            if direction and dir_name != direction:
                continue
            if dir_name not in frames_by_direction:
                frames_by_direction[dir_name] = []
            frames_by_direction[dir_name].append(frame)
        
        # Ordenar frames por índice
        for dir_name in frames_by_direction:
            frames_by_direction[dir_name].sort(key=lambda f: f.frame_index)
        
        # Gerar spritesheet para cada direção
        for dir_name, frames in frames_by_direction.items():
            if not frames:
                continue
            
            # Caminhos dos frames
            frame_paths = [
                str(Path(frames_base_dir) / f.output_path)
                for f in frames
            ]
            
            # Verificar se todos os arquivos existem
            existing_paths = [p for p in frame_paths if Path(p).exists()]
            if not existing_paths:
                continue
            
            # Nome do spritesheet
            sheet_name = f"{critter_id}_{animation_data.animation_type}_{dir_name}_sheet.png"
            sheet_path = self.output_dir / critter_id / sheet_name
            
            # Gerar spritesheet
            sheet_width, sheet_height, frame_rects = self.generate_spritesheet_from_frames(
                existing_paths,
                str(sheet_path),
                layout='horizontal'
            )
            
            # Calcular duração do frame
            fps = animation_data.fps if animation_data.fps > 0 else 10
            frame_duration_ms = 1000.0 / fps
            
            # Criar metadados
            metadata = SpritesheetMetadata(
                critter_id=critter_id,
                animation_type=animation_data.animation_type,
                direction=dir_name,
                frame_count=len(frames),
                frame_width=frame_rects[0]['width'] if frame_rects else 0,
                frame_height=frame_rects[0]['height'] if frame_rects else 0,
                sheet_width=sheet_width,
                sheet_height=sheet_height,
                fps=fps,
                frame_duration_ms=frame_duration_ms,
                frames=frame_rects,
                output_path=str(sheet_path.relative_to(self.output_dir))
            )
            results.append(metadata)
        
        return results

    
    def generate_critter_spritesheets(
        self,
        critter_data: CritterData,
        frames_base_dir: str
    ) -> SpritesheetCollection:
        """
        Gera todos os spritesheets para uma criatura.
        
        Args:
            critter_data: Dados da criatura com animações
            frames_base_dir: Diretório base onde estão os frames
            
        Returns:
            Coleção de spritesheets
        """
        spritesheets: Dict[str, SpritesheetMetadata] = {}
        
        for anim_type, anim_data in critter_data.animations.items():
            sheet_list = self.generate_animation_spritesheet(
                anim_data,
                critter_data.critter_id,
                frames_base_dir
            )
            
            for sheet in sheet_list:
                key = f"{anim_type}_{sheet.direction}"
                spritesheets[key] = sheet
        
        return SpritesheetCollection(
            critter_id=critter_data.critter_id,
            critter_type=critter_data.critter_type,
            spritesheets=spritesheets,
            total_sheets=len(spritesheets)
        )
    
    def save_spritesheet_metadata(
        self,
        collection: SpritesheetCollection,
        output_file: str
    ):
        """
        Salva metadados de spritesheets em JSON.
        
        Args:
            collection: Coleção de spritesheets
            output_file: Caminho do arquivo JSON
        """
        data = {
            'critter_id': collection.critter_id,
            'critter_type': collection.critter_type,
            'total_sheets': collection.total_sheets,
            'spritesheets': {
                key: asdict(sheet)
                for key, sheet in collection.spritesheets.items()
            }
        }
        
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
    
    def generate_all_spritesheets(
        self,
        critters: Dict[str, CritterData],
        frames_base_dir: str
    ) -> Dict[str, SpritesheetCollection]:
        """
        Gera spritesheets para todas as criaturas.
        
        Args:
            critters: Dicionário de criaturas
            frames_base_dir: Diretório base dos frames
            
        Returns:
            Dicionário de coleções de spritesheets
        """
        results: Dict[str, SpritesheetCollection] = {}
        
        for critter_id, critter_data in critters.items():
            print(f"Gerando spritesheets para {critter_id}...")
            
            collection = self.generate_critter_spritesheets(
                critter_data,
                frames_base_dir
            )
            
            if collection.total_sheets > 0:
                results[critter_id] = collection
                
                # Salvar metadados individuais
                metadata_path = self.output_dir / critter_id / 'spritesheet_metadata.json'
                self.save_spritesheet_metadata(collection, str(metadata_path))
        
        # Salvar manifesto global
        self._save_global_manifest(results)
        
        return results
    
    def _save_global_manifest(self, collections: Dict[str, SpritesheetCollection]):
        """Salva manifesto global de todos os spritesheets."""
        manifest = {
            'total_critters': len(collections),
            'total_spritesheets': sum(c.total_sheets for c in collections.values()),
            'critters': {}
        }
        
        for critter_id, collection in collections.items():
            manifest['critters'][critter_id] = {
                'critter_type': collection.critter_type,
                'total_sheets': collection.total_sheets,
                'animations': list(set(
                    sheet.animation_type 
                    for sheet in collection.spritesheets.values()
                )),
                'directions': list(set(
                    sheet.direction 
                    for sheet in collection.spritesheets.values()
                ))
            }
        
        manifest_path = self.output_dir / 'spritesheet_manifest.json'
        with open(manifest_path, 'w', encoding='utf-8') as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)
        
        print(f"Manifesto global salvo em: {manifest_path}")
