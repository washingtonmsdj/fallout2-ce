"""
Módulo para organização de assets na estrutura do projeto Godot.

Este módulo implementa o AssetOrganizer que organiza assets extraídos
na estrutura correta do Godot e gera um manifesto completo.
"""
import json
from pathlib import Path
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict
from datetime import datetime
import logging


@dataclass
class ManifestEntry:
    """Entrada no manifesto de assets."""
    original_path: str
    output_path: str
    asset_type: str
    dimensions: Optional[Dict[str, int]] = None
    metadata: Optional[Dict] = None


class AssetOrganizer:
    """
    Organizador de assets para estrutura do projeto Godot.
    
    Organiza assets extraídos na estrutura:
    - sprites/{categoria}/{subcategoria}/{arquivo}.png
    - audio/{tipo}/{arquivo}.ogg
    - data/{tipo}/{arquivo}.json
    """
    
    def __init__(self, godot_project_path: str):
        """
        Inicializa o organizador de assets.
        
        Args:
            godot_project_path: Caminho do projeto Godot
        """
        self.godot_path = Path(godot_project_path)
        self.assets_dir = self.godot_path / 'assets'
        self.manifest: List[ManifestEntry] = []
        
        # Criar estrutura de diretórios
        self._create_directory_structure()
        
        # Configurar logging de erros
        self.log_file = self.assets_dir / 'extraction_errors.log'
        self.logger = self._setup_logger()
    
    def _create_directory_structure(self):
        """Cria a estrutura de diretórios do projeto Godot."""
        directories = [
            'sprites/critters',
            'sprites/tiles',
            'sprites/ui',
            'audio/music',
            'audio/sfx',
            'audio/voice',
            'data/maps',
            'data/messages',
            'data/scripts'
        ]
        
        for directory in directories:
            (self.assets_dir / directory).mkdir(parents=True, exist_ok=True)
    
    def _setup_logger(self) -> logging.Logger:
        """Configura logger para erros de extração."""
        logger = logging.getLogger('asset_extraction')
        logger.setLevel(logging.ERROR)
        
        # Handler para arquivo
        file_handler = logging.FileHandler(self.log_file)
        file_handler.setLevel(logging.ERROR)
        
        # Formato
        formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s'
        )
        file_handler.setFormatter(formatter)
        
        logger.addHandler(file_handler)
        
        return logger
    
    def log_error(self, file_path: str, error_type: str, message: str):
        """
        Registra um erro de extração.
        
        Args:
            file_path: Caminho do arquivo que causou erro
            error_type: Tipo do erro
            message: Mensagem de erro
        """
        self.logger.error(
            f"File: {file_path} | Type: {error_type} | Message: {message}"
        )
    
    def organize_sprite(self, source: str, category: str, name: str, 
                      dimensions: Optional[Dict[str, int]] = None) -> str:
        """
        Organiza um sprite na estrutura do Godot.
        
        Args:
            source: Caminho do arquivo fonte
            category: Categoria do sprite (critters, tiles, ui)
            name: Nome do arquivo
            dimensions: Dimensões opcionais (width, height)
            
        Returns:
            Caminho de destino organizado
        """
        output_path = self.assets_dir / 'sprites' / category / name
        
        # Copiar arquivo se necessário
        source_path = Path(source)
        if source_path.exists() and source_path != output_path:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            import shutil
            shutil.copy2(source_path, output_path)
        
        # Adicionar ao manifesto
        entry = ManifestEntry(
            original_path=source,
            output_path=str(output_path.relative_to(self.godot_path)),
            asset_type='sprite',
            dimensions=dimensions
        )
        self.manifest.append(entry)
        
        return str(output_path)
    
    def organize_audio(self, source: str, audio_type: str, name: str) -> str:
        """
        Organiza um arquivo de áudio na estrutura do Godot.
        
        Args:
            source: Caminho do arquivo fonte
            audio_type: Tipo de áudio (music, sfx, voice)
            name: Nome do arquivo
            
        Returns:
            Caminho de destino organizado
        """
        output_path = self.assets_dir / 'audio' / audio_type / name
        
        # Copiar arquivo se necessário
        source_path = Path(source)
        if source_path.exists() and source_path != output_path:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            import shutil
            shutil.copy2(source_path, output_path)
        
        # Adicionar ao manifesto
        entry = ManifestEntry(
            original_path=source,
            output_path=str(output_path.relative_to(self.godot_path)),
            asset_type='audio',
            metadata={'audio_type': audio_type}
        )
        self.manifest.append(entry)
        
        return str(output_path)
    
    def organize_data(self, source: str, data_type: str, name: str,
                     metadata: Optional[Dict] = None) -> str:
        """
        Organiza um arquivo de dados na estrutura do Godot.
        
        Args:
            source: Caminho do arquivo fonte
            data_type: Tipo de dados (maps, messages, scripts)
            name: Nome do arquivo
            metadata: Metadados opcionais
            
        Returns:
            Caminho de destino organizado
        """
        output_path = self.assets_dir / 'data' / data_type / name
        
        # Copiar arquivo se necessário
        source_path = Path(source)
        if source_path.exists() and source_path != output_path:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            import shutil
            shutil.copy2(source_path, output_path)
        
        # Adicionar ao manifesto
        entry = ManifestEntry(
            original_path=source,
            output_path=str(output_path.relative_to(self.godot_path)),
            asset_type='data',
            metadata=metadata
        )
        self.manifest.append(entry)
        
        return str(output_path)
    
    def generate_manifest(self) -> Dict:
        """
        Gera o manifesto completo de assets extraídos.
        
        Returns:
            Dicionário com o manifesto completo
        """
        manifest_dict = {
            'version': '1.0',
            'generated_at': datetime.now().isoformat(),
            'total_assets': len(self.manifest),
            'assets': [asdict(entry) for entry in self.manifest],
            'statistics': self._calculate_statistics()
        }
        
        return manifest_dict
    
    def _calculate_statistics(self) -> Dict:
        """Calcula estatísticas do manifesto."""
        stats = {
            'by_type': {},
            'by_category': {}
        }
        
        for entry in self.manifest:
            # Por tipo
            asset_type = entry.asset_type
            stats['by_type'][asset_type] = stats['by_type'].get(asset_type, 0) + 1
            
            # Por categoria (para sprites)
            if asset_type == 'sprite':
                category = Path(entry.output_path).parent.name
                if 'by_category' not in stats:
                    stats['by_category'] = {}
                stats['by_category'][category] = stats['by_category'].get(category, 0) + 1
        
        return stats
    
    def save_manifest(self, output_file: Optional[str] = None):
        """
        Salva o manifesto em arquivo JSON.
        
        Args:
            output_file: Caminho do arquivo de saída (None = padrão)
        """
        if output_file is None:
            output_file = str(self.assets_dir / 'manifest.json')
        
        manifest_dict = self.generate_manifest()
        
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(manifest_dict, f, indent=2, ensure_ascii=False)
        
        print(f"Manifesto salvo em: {output_path}")
        print(f"Total de assets: {manifest_dict['total_assets']}")

