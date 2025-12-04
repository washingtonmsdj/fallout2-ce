"""
Módulo para extração completa de animações de criaturas do Fallout 2.

Este módulo implementa o AnimationExtractor que extrai TODAS as animações
de criaturas (idle, walk, run, attack, death, hit) em todas as 6 direções,
organizando em pastas por tipo de animação.

Referências:
- Requirements 1.1: Decodificar todos os frames em todas as direções
- Requirements 1.3: Organizar em pastas separadas por tipo de animação
"""
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple, Set
from dataclasses import dataclass, asdict, field
from PIL import Image

from .dat2_reader import DAT2Manager
from .frm_decoder import FRMDecoder, FRMImage, Frame
from .palette_loader import PaletteLoader


@dataclass
class AnimationFrame:
    """Dados de um frame individual de animação."""
    frame_index: int
    direction: int
    direction_name: str
    width: int
    height: int
    offset_x: int
    offset_y: int
    output_path: str


@dataclass
class AnimationData:
    """Dados completos de uma animação."""
    animation_type: str
    animation_code: str  # aa, ab, at, etc.
    fps: int
    frame_count: int
    directions: int
    frames: List[AnimationFrame] = field(default_factory=list)


@dataclass
class CritterData:
    """Dados completos de uma criatura com todas as animações."""
    critter_id: str
    critter_type: str  # human, animal, mutant, robot, creature
    animations: Dict[str, AnimationData] = field(default_factory=dict)
    total_frames: int = 0
    available_directions: List[str] = field(default_factory=list)


class AnimationExtractor:
    """
    Extrator completo de animações de criaturas do Fallout 2.
    
    Suporta todos os tipos de animação:
    - idle (aa): Parado
    - walk (ab): Andando
    - run (at): Correndo
    - attack_unarmed (an): Ataque desarmado
    - attack_melee (ao): Ataque corpo-a-corpo
    - attack_ranged (ap): Ataque à distância
    - death (ba-bm): Várias animações de morte
    - hit (ao): Recebendo dano
    - dodge (aq): Esquivando
    - standup (ch, cj): Levantando
    - knockdown (ra, rb): Caindo
    """
    
    # Mapeamento de códigos de animação para tipos
    # Baseado na documentação do formato FRM do Fallout 2
    ANIMATION_CODES = {
        'aa': 'idle',
        'ab': 'walk',
        'at': 'run',
        'an': 'attack_unarmed',
        'ao': 'attack_melee',
        'ap': 'attack_ranged',
        'aq': 'dodge',
        'as': 'damage',
        # Death animations (ba-bm)
        'ba': 'death_normal',
        'bb': 'death_critical',
        'bc': 'death_burn',
        'bd': 'death_explode',
        'be': 'death_melt',
        'bf': 'death_laser',
        'bg': 'death_plasma',
        'bh': 'death_electric',
        'bi': 'death_emp',
        'bj': 'death_explode_big',
        'bk': 'death_fire',
        'bl': 'death_knockout',
        'bm': 'death_blood',
        # Knockdown/standup
        'ch': 'standup_front',
        'cj': 'standup_back',
        'ra': 'knockdown_front',
        'rb': 'knockdown_back',
    }
    
    # Tipos de animação principais para extração
    PRIMARY_ANIMATIONS = ['aa', 'ab', 'at', 'an', 'ao', 'ap', 'ba', 'as']
    
    # Padrões para identificar tipos de criaturas
    CRITTER_TYPE_PATTERNS = {
        'human': ['hm', 'hf', 'nm', 'nf'],  # Human male/female, NPC male/female
        'animal': ['rat', 'dog', 'brahmin', 'gecko', 'radscorp', 'mantis', 'pig', 'mole'],
        'mutant': ['mutant', 'super', 'ghoul', 'centaur', 'floater', 'deathclaw'],
        'robot': ['robot', 'turret', 'eyebot', 'protectron', 'robobrain', 'sentry'],
        'creature': ['alien', 'wanamingo', 'plant', 'spore'],
    }
    
    # Nomes das 6 direções isométricas
    DIRECTION_NAMES = ['ne', 'e', 'se', 'sw', 'w', 'nw']
    
    def __init__(self, dat_manager: DAT2Manager, palette: PaletteLoader, output_dir: str):
        """
        Inicializa o extrator de animações.
        
        Args:
            dat_manager: Gerenciador DAT2 para acessar arquivos
            palette: Carregador de paleta de cores
            output_dir: Diretório base de saída
        """
        self.dat_manager = dat_manager
        self.palette = palette
        self.output_dir = Path(output_dir)
        self.decoder = FRMDecoder(palette)
        
        # Criar estrutura de diretórios
        self.output_dir.mkdir(parents=True, exist_ok=True)
    
    def _identify_critter_type(self, critter_id: str) -> str:
        """
        Identifica o tipo de criatura pelo ID.
        
        Args:
            critter_id: ID da criatura (ex: hmwarr, radscorp)
            
        Returns:
            Tipo: 'human', 'animal', 'mutant', 'robot', 'creature', ou 'unknown'
        """
        critter_lower = critter_id.lower()
        
        for critter_type, patterns in self.CRITTER_TYPE_PATTERNS.items():
            for pattern in patterns:
                if critter_lower.startswith(pattern) or pattern in critter_lower:
                    return critter_type
        
        return 'unknown'
    
    def _extract_critter_id(self, frm_path: str) -> str:
        """
        Extrai o ID da criatura do caminho do arquivo FRM.
        
        Args:
            frm_path: Caminho do arquivo (ex: art/critters/hmwarraa.frm)
            
        Returns:
            ID da criatura (ex: hmwarr)
        """
        filename = Path(frm_path).stem.lower()
        
        # Remover código de animação (últimos 2 caracteres)
        if len(filename) >= 2:
            return filename[:-2]
        return filename
    
    def _extract_animation_code(self, frm_path: str) -> str:
        """
        Extrai o código de animação do caminho do arquivo FRM.
        
        Args:
            frm_path: Caminho do arquivo (ex: art/critters/hmwarraa.frm)
            
        Returns:
            Código de animação (ex: aa, ab, ba)
        """
        filename = Path(frm_path).stem.lower()
        
        if len(filename) >= 2:
            return filename[-2:]
        return 'aa'
    
    def _get_animation_type(self, animation_code: str) -> str:
        """
        Obtém o tipo de animação pelo código.
        
        Args:
            animation_code: Código de 2 letras (ex: aa, ab)
            
        Returns:
            Tipo de animação (ex: idle, walk)
        """
        return self.ANIMATION_CODES.get(animation_code, f'unknown_{animation_code}')

    
    def extract_animation(self, frm_path: str, critter_id: str, 
                          animation_code: str) -> Optional[AnimationData]:
        """
        Extrai uma animação específica de um arquivo FRM.
        
        Args:
            frm_path: Caminho interno do arquivo FRM no DAT2
            critter_id: ID da criatura
            animation_code: Código da animação (aa, ab, etc.)
            
        Returns:
            AnimationData com todos os frames, ou None se falhar
        """
        try:
            # Obter dados do FRM
            frm_data = self.dat_manager.get_file(frm_path)
            if not frm_data:
                return None
            
            # Decodificar FRM
            frm_image = self.decoder.decode(frm_data)
            
            animation_type = self._get_animation_type(animation_code)
            
            # Criar diretório de saída: critters/{critter_id}/{animation_type}/
            critter_dir = self.output_dir / critter_id / animation_type
            critter_dir.mkdir(parents=True, exist_ok=True)
            
            # Extrair todos os frames de todas as direções
            frames: List[AnimationFrame] = []
            directions_found = 0
            
            for direction in range(6):
                if direction >= len(frm_image.frames) or not frm_image.frames[direction]:
                    continue
                
                directions_found += 1
                direction_name = self.DIRECTION_NAMES[direction]
                
                for frame_idx, frame_data in enumerate(frm_image.frames[direction]):
                    # Nome do arquivo: {critter_id}_{animation_type}_{direction}_frame{N}.png
                    frame_filename = f"{critter_id}_{animation_type}_{direction_name}_frame{frame_idx:03d}.png"
                    frame_path = critter_dir / frame_filename
                    
                    # Exportar frame como PNG
                    self.decoder.to_png(frm_image, str(frame_path), direction, frame_idx)
                    
                    # Criar metadados do frame
                    frame_info = AnimationFrame(
                        frame_index=frame_idx,
                        direction=direction,
                        direction_name=direction_name,
                        width=frame_data.width,
                        height=frame_data.height,
                        offset_x=frame_data.offset_x,
                        offset_y=frame_data.offset_y,
                        output_path=str(frame_path.relative_to(self.output_dir))
                    )
                    frames.append(frame_info)
            
            return AnimationData(
                animation_type=animation_type,
                animation_code=animation_code,
                fps=frm_image.fps,
                frame_count=frm_image.num_frames,
                directions=directions_found,
                frames=frames
            )
            
        except Exception as e:
            print(f"Erro ao extrair animação {frm_path}: {e}")
            return None
    
    def extract_critter(self, critter_id: str, frm_paths: List[str]) -> Optional[CritterData]:
        """
        Extrai todas as animações de uma criatura.
        
        Args:
            critter_id: ID da criatura
            frm_paths: Lista de caminhos FRM para esta criatura
            
        Returns:
            CritterData com todas as animações, ou None se falhar
        """
        critter_type = self._identify_critter_type(critter_id)
        
        animations: Dict[str, AnimationData] = {}
        total_frames = 0
        all_directions: Set[str] = set()
        
        for frm_path in frm_paths:
            animation_code = self._extract_animation_code(frm_path)
            
            animation_data = self.extract_animation(frm_path, critter_id, animation_code)
            if animation_data:
                animations[animation_data.animation_type] = animation_data
                total_frames += len(animation_data.frames)
                
                # Coletar direções disponíveis
                for frame in animation_data.frames:
                    all_directions.add(frame.direction_name)
        
        if not animations:
            return None
        
        return CritterData(
            critter_id=critter_id,
            critter_type=critter_type,
            animations=animations,
            total_frames=total_frames,
            available_directions=sorted(list(all_directions))
        )
    
    def list_critter_files(self) -> Dict[str, List[str]]:
        """
        Lista todos os arquivos FRM de criaturas agrupados por ID.
        
        Returns:
            Dicionário mapeando critter_id para lista de caminhos FRM
        """
        all_files = self.dat_manager.list_all_files()
        
        # Filtrar apenas arquivos FRM de criaturas
        critter_files = [f for f in all_files 
                        if f.lower().endswith('.frm') and 
                        ('critter' in f.lower() or 'art/critters' in f.lower())]
        
        # Agrupar por critter_id
        critters: Dict[str, List[str]] = {}
        for frm_path in critter_files:
            critter_id = self._extract_critter_id(frm_path)
            if critter_id not in critters:
                critters[critter_id] = []
            critters[critter_id].append(frm_path)
        
        return critters
    
    def extract_all_critters(self, limit: Optional[int] = None, 
                             animation_filter: Optional[List[str]] = None) -> Dict[str, CritterData]:
        """
        Extrai todas as criaturas do DAT2.
        
        Args:
            limit: Limite de criaturas a extrair (None = todas)
            animation_filter: Lista de códigos de animação a extrair (None = todas)
            
        Returns:
            Dicionário mapeando critter_id para CritterData
        """
        critter_files = self.list_critter_files()
        
        print(f"Encontradas {len(critter_files)} criaturas únicas")
        
        results: Dict[str, CritterData] = {}
        count = 0
        
        for critter_id, frm_paths in critter_files.items():
            if limit and count >= limit:
                break
            
            # Filtrar animações se especificado
            if animation_filter:
                frm_paths = [p for p in frm_paths 
                            if self._extract_animation_code(p) in animation_filter]
            
            if not frm_paths:
                continue
            
            print(f"Extraindo {critter_id} ({len(frm_paths)} animações)...")
            
            critter_data = self.extract_critter(critter_id, frm_paths)
            if critter_data:
                results[critter_id] = critter_data
                count += 1
        
        print(f"Extraídas {len(results)} criaturas")
        return results
    
    def save_manifest(self, critters: Dict[str, CritterData], output_file: str):
        """
        Salva manifesto JSON com todas as criaturas extraídas.
        
        Args:
            critters: Dicionário de criaturas
            output_file: Caminho do arquivo de saída
        """
        # Converter para formato serializável
        manifest = {
            'critters': {},
            'summary': {
                'total_critters': len(critters),
                'total_animations': 0,
                'total_frames': 0,
                'by_type': {}
            }
        }
        
        for critter_id, critter_data in critters.items():
            # Converter animações
            animations_dict = {}
            for anim_type, anim_data in critter_data.animations.items():
                animations_dict[anim_type] = {
                    'animation_code': anim_data.animation_code,
                    'fps': anim_data.fps,
                    'frame_count': anim_data.frame_count,
                    'directions': anim_data.directions,
                    'frames': [asdict(f) for f in anim_data.frames]
                }
            
            manifest['critters'][critter_id] = {
                'critter_id': critter_data.critter_id,
                'critter_type': critter_data.critter_type,
                'animations': animations_dict,
                'total_frames': critter_data.total_frames,
                'available_directions': critter_data.available_directions
            }
            
            # Atualizar sumário
            manifest['summary']['total_animations'] += len(critter_data.animations)
            manifest['summary']['total_frames'] += critter_data.total_frames
            
            critter_type = critter_data.critter_type
            if critter_type not in manifest['summary']['by_type']:
                manifest['summary']['by_type'][critter_type] = 0
            manifest['summary']['by_type'][critter_type] += 1
        
        # Salvar JSON
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(manifest, f, indent=2, ensure_ascii=False)
        
        print(f"Manifesto salvo em: {output_path}")


def extract_all_animations(dat_paths: List[str], palette_path: str, 
                           output_dir: str, limit: Optional[int] = None) -> Dict[str, CritterData]:
    """
    Função de conveniência para extrair todas as animações.
    
    Args:
        dat_paths: Lista de caminhos para arquivos DAT2
        palette_path: Caminho para arquivo de paleta
        output_dir: Diretório de saída
        limit: Limite de criaturas (None = todas)
        
    Returns:
        Dicionário de criaturas extraídas
    """
    palette = PaletteLoader(palette_path)
    
    with DAT2Manager(dat_paths) as dat_manager:
        extractor = AnimationExtractor(dat_manager, palette, output_dir)
        critters = extractor.extract_all_critters(limit=limit)
        
        # Salvar manifesto
        manifest_path = Path(output_dir) / 'critter_manifest.json'
        extractor.save_manifest(critters, str(manifest_path))
        
        return critters



class TransparencyValidator:
    """
    Validador de transparência para PNGs extraídos.
    
    Garante que pixels com índice de paleta 0 são convertidos para
    alpha 0 (totalmente transparente) nos PNGs gerados.
    
    Referências:
    - Requirements 2.1: Gerar arquivos PNG com transparência correta
    """
    
    @staticmethod
    def validate_png_transparency(png_path: str, original_pixels: bytes = None) -> Dict:
        """
        Valida a transparência de um arquivo PNG.
        
        Args:
            png_path: Caminho do arquivo PNG
            original_pixels: Bytes originais do FRM (opcional, para validação completa)
            
        Returns:
            Dicionário com resultados da validação
        """
        from PIL import Image
        
        result = {
            'valid': True,
            'path': png_path,
            'has_transparency': False,
            'transparent_pixels': 0,
            'opaque_pixels': 0,
            'errors': []
        }
        
        try:
            img = Image.open(png_path)
            
            # Verificar modo RGBA
            if img.mode != 'RGBA':
                result['valid'] = False
                result['errors'].append(f"Modo incorreto: {img.mode} (esperado RGBA)")
                img.close()
                return result
            
            # Contar pixels transparentes e opacos
            pixels = img.load()
            width, height = img.size
            
            for y in range(height):
                for x in range(width):
                    pixel = pixels[x, y]
                    alpha = pixel[3]
                    
                    if alpha == 0:
                        result['transparent_pixels'] += 1
                        result['has_transparency'] = True
                    elif alpha == 255:
                        result['opaque_pixels'] += 1
                    else:
                        # Alpha parcial não deveria existir em sprites FRM
                        result['errors'].append(
                            f"Alpha parcial ({alpha}) em ({x}, {y})"
                        )
            
            # Se temos pixels originais, validar correspondência
            if original_pixels:
                pixel_idx = 0
                for y in range(height):
                    for x in range(width):
                        if pixel_idx < len(original_pixels):
                            palette_idx = original_pixels[pixel_idx]
                            pixel = pixels[x, y]
                            alpha = pixel[3]
                            
                            # Índice 0 deve ser transparente
                            if palette_idx == 0 and alpha != 0:
                                result['valid'] = False
                                result['errors'].append(
                                    f"Pixel ({x}, {y}): índice 0 deveria ser transparente"
                                )
                            # Índices não-zero devem ser opacos
                            elif palette_idx != 0 and alpha != 255:
                                result['valid'] = False
                                result['errors'].append(
                                    f"Pixel ({x}, {y}): índice {palette_idx} deveria ser opaco"
                                )
                            
                            pixel_idx += 1
            
            img.close()
            
        except Exception as e:
            result['valid'] = False
            result['errors'].append(f"Erro ao abrir PNG: {e}")
        
        return result
    
    @staticmethod
    def validate_all_pngs(directory: str) -> Dict:
        """
        Valida todos os PNGs em um diretório.
        
        Args:
            directory: Caminho do diretório
            
        Returns:
            Dicionário com resultados agregados
        """
        from pathlib import Path
        
        results = {
            'total_files': 0,
            'valid_files': 0,
            'invalid_files': 0,
            'files_with_transparency': 0,
            'errors': []
        }
        
        dir_path = Path(directory)
        png_files = list(dir_path.rglob('*.png'))
        results['total_files'] = len(png_files)
        
        for png_path in png_files:
            validation = TransparencyValidator.validate_png_transparency(str(png_path))
            
            if validation['valid']:
                results['valid_files'] += 1
            else:
                results['invalid_files'] += 1
                results['errors'].extend(validation['errors'])
            
            if validation['has_transparency']:
                results['files_with_transparency'] += 1
        
        return results
