"""
Módulo para extração de tiles de mapa do Fallout 2.

Este módulo implementa o TileExtractor que extrai tiles de chão (floor)
e teto (roof) do master.dat, organizando por categoria e preservando
dimensões isométricas.
"""
from pathlib import Path
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict
import json

from .dat2_reader import DAT2Manager
from .frm_decoder import FRMDecoder
from .palette_loader import PaletteLoader


@dataclass
class TileMetadata:
    """Metadados de um tile."""
    name: str
    category: str
    tile_type: str  # floor ou roof
    width: int
    height: int
    output_path: str


class TileExtractor:
    """
    Extrator de tiles de mapa do Fallout 2.
    
    Extrai tiles de chão (floor) e teto (roof), organizando por categoria
    (desert, city, cave, vault, etc.) e preservando dimensões isométricas.
    """
    
    # Categorias de tiles baseadas em caminhos
    TILE_CATEGORIES = {
        'desert': ['desert', 'wasteland', 'outdoor'],
        'city': ['city', 'urban', 'town'],
        'cave': ['cave', 'underground', 'tunnel'],
        'vault': ['vault', 'vault_'],
        'building': ['building', 'house', 'interior'],
        'sewer': ['sewer', 'drain'],
        'encampment': ['encamp', 'camp']
    }
    
    # Dimensões padrão de tiles isométricos
    FLOOR_TILE_SIZE = (80, 36)  # width, height
    ROOF_TILE_SIZE = (80, 36)   # Geralmente similar
    
    def __init__(self, dat_manager: DAT2Manager, palette: PaletteLoader, output_dir: str):
        """
        Inicializa o extrator de tiles.
        
        Args:
            dat_manager: Gerenciador DAT2 para acessar arquivos
            palette: Carregador de paleta
            output_dir: Diretório de saída para tiles
        """
        self.dat_manager = dat_manager
        self.palette = palette
        self.output_dir = Path(output_dir)
        self.decoder = FRMDecoder(palette)
        
        # Criar estrutura de diretórios
        self.output_dir.mkdir(parents=True, exist_ok=True)
        for category in ['floor', 'roof', 'unknown']:
            (self.output_dir / category).mkdir(parents=True, exist_ok=True)
    
    def _identify_tile_category(self, path: str) -> str:
        """
        Identifica a categoria do tile pelo caminho.
        
        Args:
            path: Caminho do arquivo
            
        Returns:
            Categoria do tile
        """
        path_lower = path.lower()
        
        for category, keywords in self.TILE_CATEGORIES.items():
            for keyword in keywords:
                if keyword in path_lower:
                    return category
        
        return 'unknown'
    
    def _identify_tile_type(self, path: str) -> str:
        """
        Identifica o tipo do tile (floor ou roof).
        
        Args:
            path: Caminho do arquivo
            
        Returns:
            'floor' ou 'roof'
        """
        path_lower = path.lower()
        
        if 'roof' in path_lower or 'ceil' in path_lower:
            return 'roof'
        else:
            return 'floor'
    
    def extract_tile(self, frm_path: str) -> Optional[TileMetadata]:
        """
        Extrai um tile individual.
        
        Args:
            frm_path: Caminho interno do arquivo FRM no DAT2
            
        Returns:
            TileMetadata se extraído com sucesso, None caso contrário
        """
        try:
            # Obter dados do FRM
            frm_data = self.dat_manager.get_file(frm_path)
            if not frm_data:
                return None
            
            # Decodificar FRM
            frm_image = self.decoder.decode(frm_data)
            
            # Identificar tipo e categoria
            tile_type = self._identify_tile_type(frm_path)
            category = self._identify_tile_category(frm_path)
            tile_name = Path(frm_path).stem
            
            # Obter dimensões do primeiro frame da primeira direção
            if not frm_image.frames or not frm_image.frames[0]:
                return None
            
            first_frame = frm_image.frames[0][0]
            width = first_frame.width
            height = first_frame.height
            
            # Criar diretório de saída
            type_dir = self.output_dir / tile_type
            category_dir = type_dir / category
            category_dir.mkdir(parents=True, exist_ok=True)
            
            # Exportar tile (usar primeiro frame da primeira direção)
            output_filename = f"{tile_name}.png"
            output_path = category_dir / output_filename
            
            self.decoder.to_png(frm_image, str(output_path), direction=0, frame=0)
            
            return TileMetadata(
                name=tile_name,
                category=category,
                tile_type=tile_type,
                width=width,
                height=height,
                output_path=str(output_path.relative_to(self.output_dir))
            )
            
        except Exception as e:
            print(f"Erro ao extrair tile {frm_path}: {e}")
            return None
    
    def extract_all_tiles(self) -> Dict[str, List[TileMetadata]]:
        """
        Extrai todos os tiles do master.dat.
        
        Returns:
            Dicionário organizado por tipo (floor/roof) e categoria
        """
        # Listar todos os arquivos FRM relacionados a tiles
        all_files = self.dat_manager.list_all_files()
        tile_files = [f for f in all_files 
                     if f.lower().endswith('.frm') and 
                     ('tile' in f.lower() or 'floor' in f.lower() or 
                      'roof' in f.lower() or 'art/tiles' in f.lower())]
        
        print(f"Encontrados {len(tile_files)} arquivos FRM de tiles")
        
        # Extrair tiles
        results: Dict[str, List[TileMetadata]] = {
            'floor': [],
            'roof': []
        }
        
        for tile_path in tile_files:
            metadata = self.extract_tile(tile_path)
            if metadata:
                results[metadata.tile_type].append(metadata)
        
        return results
    
    def save_metadata(self, tiles: Dict[str, List[TileMetadata]], output_file: str):
        """
        Salva metadados de todos os tiles em JSON.
        
        Args:
            tiles: Dicionário de tiles por tipo
            output_file: Caminho do arquivo JSON de saída
        """
        # Converter para formato serializável
        output_data = {}
        for tile_type, metadata_list in tiles.items():
            output_data[tile_type] = [asdict(m) for m in metadata_list]
        
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        print(f"Metadados de tiles salvos em: {output_path}")

