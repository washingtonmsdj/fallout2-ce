"""
Módulo para extração de sprites de criaturas e NPCs do Fallout 2.

Este módulo implementa o CritterExtractor que varre o critter.dat,
organiza sprites por tipo e extrai todas as animações.
"""
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict

from .dat2_reader import DAT2Manager, DAT2Reader
from .frm_decoder import FRMDecoder, FRMImage
from .palette_loader import PaletteLoader


@dataclass
class CritterAnimation:
    """Metadados de uma animação de criatura."""
    name: str
    animation_type: str  # idle, walk, attack, death, etc.
    direction: str
    frame: int
    width: int
    height: int
    offset_x: int
    offset_y: int
    fps: int
    frame_count: int
    output_path: str


@dataclass
class CritterMetadata:
    """Metadados completos de uma criatura."""
    critter_name: str
    critter_type: str  # human, animal, mutant, robot
    animations: List[CritterAnimation]
    total_frames: int
    directions: List[str]


class CritterExtractor:
    """
    Extrator de sprites de criaturas e NPCs do Fallout 2.
    
    Organiza sprites por tipo (humans, animals, mutants, robots) e extrai
    todas as animações (idle, walk, attack, death, etc.) preservando
    metadados de offset para alinhamento correto.
    """
    
    # Padrões de nomenclatura para identificar tipos de criaturas
    CRITTER_PATTERNS = {
        'human': ['hm', 'hf', 'hmwarr', 'hfprim', 'hmjmps', 'hfjmps'],
        'animal': ['radscorp', 'gecko', 'brahmin', 'dog', 'rat'],
        'mutant': ['mutant', 'super', 'ghoul', 'centaur'],
        'robot': ['robot', 'turret', 'eyebot', 'protectron']
    }
    
    # Padrões de nomenclatura para tipos de animação
    # Nota: padrões mais específicos primeiro para evitar falsos positivos
    ANIMATION_PATTERNS = {
        'walk': ['walk', 'move'],
        'attack': ['attack', 'hit'],
        'death': ['death', 'die'],
        'knockdown': ['knock', 'down'],
        'reload': ['reload'],
        'shoot': ['shoot', 'fire'],
        'idle': ['idle', 'stand']
    }
    
    def __init__(self, dat_manager: DAT2Manager, palette: PaletteLoader, output_dir: str):
        """
        Inicializa o extrator de criaturas.
        
        Args:
            dat_manager: Gerenciador DAT2 para acessar arquivos
            palette: Carregador de paleta
            output_dir: Diretório de saída para sprites
        """
        self.dat_manager = dat_manager
        self.palette = palette
        self.output_dir = Path(output_dir)
        self.decoder = FRMDecoder(palette)
        
        # Criar estrutura de diretórios
        self.output_dir.mkdir(parents=True, exist_ok=True)
        for critter_type in ['humans', 'animals', 'mutants', 'robots', 'unknown']:
            (self.output_dir / critter_type).mkdir(parents=True, exist_ok=True)
    
    def _identify_critter_type(self, filename: str) -> str:
        """
        Identifica o tipo de criatura pelo nome do arquivo.
        
        Args:
            filename: Nome do arquivo FRM
            
        Returns:
            Tipo de criatura: 'human', 'animal', 'mutant', 'robot', ou 'unknown'
        """
        filename_lower = filename.lower()
        
        for critter_type, patterns in self.CRITTER_PATTERNS.items():
            for pattern in patterns:
                if pattern in filename_lower:
                    return critter_type
        
        return 'unknown'
    
    def _identify_animation_type(self, filename: str) -> str:
        """
        Identifica o tipo de animação pelo nome do arquivo.
        
        Args:
            filename: Nome do arquivo FRM
            
        Returns:
            Tipo de animação: 'idle', 'walk', 'attack', etc.
        """
        filename_lower = filename.lower()
        
        for anim_type, patterns in self.ANIMATION_PATTERNS.items():
            for pattern in patterns:
                if pattern in filename_lower:
                    return anim_type
        
        # Se não encontrar, tentar inferir pela última letra
        if filename_lower.endswith('a.frm'):
            return 'idle'
        elif filename_lower.endswith('d.frm'):
            return 'walk'
        elif filename_lower.endswith('c.frm'):
            return 'attack'
        elif filename_lower.endswith('e.frm'):
            return 'death'
        
        return 'unknown'
    
    def _extract_critter_name(self, path: str) -> str:
        """
        Extrai o nome base da criatura do caminho.
        
        Args:
            path: Caminho do arquivo (ex: art/critters/hmwarrda.frm)
            
        Returns:
            Nome base (ex: hmwarr)
        """
        filename = Path(path).stem.lower()
        
        # Remover sufixos de animação
        for anim_type, patterns in self.ANIMATION_PATTERNS.items():
            for pattern in patterns:
                if filename.endswith(pattern):
                    filename = filename[:-len(pattern)]
                    break
        
        return filename
    
    def extract_critter_sprite(self, frm_path: str) -> Optional[CritterMetadata]:
        """
        Extrai um sprite de criatura completo.
        
        Args:
            frm_path: Caminho interno do arquivo FRM no DAT2
            
        Returns:
            CritterMetadata com todas as animações, ou None se falhar
        """
        try:
            # Obter dados do FRM
            frm_data = self.dat_manager.get_file(frm_path)
            if not frm_data:
                return None
            
            # Decodificar FRM
            frm_image = self.decoder.decode(frm_data)
            
            # Identificar tipo e nome
            critter_name = self._extract_critter_name(frm_path)
            critter_type = self._identify_critter_type(Path(frm_path).stem)
            animation_type = self._identify_animation_type(Path(frm_path).stem)
            
            # Criar diretório de saída
            type_dir = self.output_dir / critter_type
            critter_dir = type_dir / critter_name
            critter_dir.mkdir(parents=True, exist_ok=True)
            
            # Extrair todas as direções e frames
            animations = []
            base_name = f"{critter_name}_{animation_type}"
            
            for direction in range(6):
                if direction >= len(frm_image.frames) or not frm_image.frames[direction]:
                    continue
                
                direction_name = FRMDecoder.DIRECTION_NAMES[direction]
                
                for frame_idx, frame_data in enumerate(frm_image.frames[direction]):
                    # Exportar frame individual
                    frame_filename = f"{base_name}_{direction_name}_frame{frame_idx:03d}.png"
                    frame_path = critter_dir / frame_filename
                    
                    self.decoder.to_png(frm_image, str(frame_path), direction, frame_idx)
                    
                    # Criar metadados
                    animation = CritterAnimation(
                        name=critter_name,
                        animation_type=animation_type,
                        direction=direction_name,
                        frame=frame_idx,
                        width=frame_data.width,
                        height=frame_data.height,
                        offset_x=frame_data.offset_x,
                        offset_y=frame_data.offset_y,
                        fps=frm_image.fps,
                        frame_count=frm_image.num_frames,
                        output_path=str(frame_path.relative_to(self.output_dir))
                    )
                    animations.append(animation)
            
            # Calcular totais
            total_frames = sum(len(frames) for frames in frm_image.frames if frames)
            directions = [FRMDecoder.DIRECTION_NAMES[i] 
                         for i in range(6) 
                         if i < len(frm_image.frames) and frm_image.frames[i]]
            
            return CritterMetadata(
                critter_name=critter_name,
                critter_type=critter_type,
                animations=animations,
                total_frames=total_frames,
                directions=directions
            )
            
        except Exception as e:
            print(f"Erro ao extrair {frm_path}: {e}")
            return None
    
    def extract_all_critters(self) -> Dict[str, List[CritterMetadata]]:
        """
        Extrai todos os sprites de criaturas do critter.dat.
        
        Returns:
            Dicionário organizado por tipo de criatura
        """
        # Listar todos os arquivos FRM no critter.dat
        all_files = self.dat_manager.list_all_files()
        critter_files = [f for f in all_files 
                        if f.lower().endswith('.frm') and 'critter' in f.lower()]
        
        print(f"Encontrados {len(critter_files)} arquivos FRM de criaturas")
        
        # Organizar por criatura (agrupar animações do mesmo critter)
        critters_by_name: Dict[str, List[str]] = {}
        for frm_path in critter_files:
            critter_name = self._extract_critter_name(frm_path)
            if critter_name not in critters_by_name:
                critters_by_name[critter_name] = []
            critters_by_name[critter_name].append(frm_path)
        
        # Extrair cada criatura
        results: Dict[str, List[CritterMetadata]] = {
            'humans': [],
            'animals': [],
            'mutants': [],
            'robots': [],
            'unknown': []
        }
        
        for critter_name, frm_paths in critters_by_name.items():
            print(f"Extraindo {critter_name} ({len(frm_paths)} animações)...")
            
            for frm_path in frm_paths:
                metadata = self.extract_critter_sprite(frm_path)
                if metadata:
                    results[metadata.critter_type].append(metadata)
        
        return results
    
    def save_metadata(self, critters: Dict[str, List[CritterMetadata]], output_file: str):
        """
        Salva metadados de todas as criaturas em JSON.
        
        Args:
            critters: Dicionário de criaturas por tipo
            output_file: Caminho do arquivo JSON de saída
        """
        # Converter para formato serializável
        output_data = {}
        for critter_type, metadata_list in critters.items():
            output_data[critter_type] = [asdict(m) for m in metadata_list]
        
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        print(f"Metadados salvos em: {output_path}")

