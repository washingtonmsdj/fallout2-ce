"""
Módulo para extração de elementos de interface do Fallout 2.

Este módulo implementa o UIExtractor que extrai elementos de UI de
art/intrface/, mantendo nomenclatura descritiva e incluindo ícones.
"""
from pathlib import Path
from typing import List, Dict, Optional
from dataclasses import dataclass, asdict
import json

from .dat2_reader import DAT2Manager
from .frm_decoder import FRMDecoder
from .palette_loader import PaletteLoader


@dataclass
class UIElementMetadata:
    """Metadados de um elemento de UI."""
    name: str
    ui_type: str  # menu, button, icon, background, etc.
    width: int
    height: int
    output_path: str
    description: str = ""


class UIExtractor:
    """
    Extrator de elementos de interface do Fallout 2.
    
    Extrai elementos de art/intrface/, mantendo nomenclatura descritiva
    e incluindo ícones de inventário e slots.
    """
    
    # Mapeamento de nomes de arquivos para tipos de UI
    UI_TYPE_MAPPINGS = {
        'menu': ['menu', 'mainmenu', 'title'],
        'button': ['button', 'btn'],
        'icon': ['icon', 'ico'],
        'background': ['bg', 'background', 'back'],
        'panel': ['panel', 'window', 'frame'],
        'inventory': ['inventory', 'inv', 'item'],
        'slot': ['slot', 'empty'],
        'cursor': ['cursor', 'mouse'],
        'dialog': ['dialog', 'talk']
    }
    
    # Mapeamento de nomes para descrições descritivas
    UI_NAME_MAPPINGS = {
        'mainmenu': 'mainmenu_bg',
        'button': 'button_normal',
        'button_pressed': 'button_pressed',
        'button_hover': 'button_hover',
        'inventory': 'inventory_bg',
        'item_slot': 'item_slot',
        'item_slot_empty': 'item_slot_empty'
    }
    
    def __init__(self, dat_manager: DAT2Manager, palette: PaletteLoader, output_dir: str):
        """
        Inicializa o extrator de UI.
        
        Args:
            dat_manager: Gerenciador DAT2 para acessar arquivos
            palette: Carregador de paleta
            output_dir: Diretório de saída para elementos de UI
        """
        self.dat_manager = dat_manager
        self.palette = palette
        self.output_dir = Path(output_dir)
        self.decoder = FRMDecoder(palette)
        
        # Criar estrutura de diretórios
        self.output_dir.mkdir(parents=True, exist_ok=True)
        for ui_type in ['menu', 'button', 'icon', 'background', 'inventory', 'other']:
            (self.output_dir / ui_type).mkdir(parents=True, exist_ok=True)
    
    def _identify_ui_type(self, filename: str) -> str:
        """
        Identifica o tipo de elemento de UI pelo nome do arquivo.
        
        Args:
            filename: Nome do arquivo
            
        Returns:
            Tipo de UI
        """
        filename_lower = filename.lower()
        
        for ui_type, keywords in self.UI_TYPE_MAPPINGS.items():
            for keyword in keywords:
                if keyword in filename_lower:
                    return ui_type
        
        return 'other'
    
    def _get_descriptive_name(self, filename: str, ui_type: str) -> str:
        """
        Gera um nome descritivo para o elemento de UI.
        
        Args:
            filename: Nome original do arquivo
            ui_type: Tipo de UI identificado
            
        Returns:
            Nome descritivo
        """
        filename_lower = filename.lower()
        
        # Verificar mapeamentos diretos
        for key, value in self.UI_NAME_MAPPINGS.items():
            if key in filename_lower:
                return value
        
        # Gerar nome baseado no tipo e nome original
        base_name = Path(filename).stem.lower()
        
        # Remover extensões comuns
        base_name = base_name.replace('.frm', '').replace('_', '')
        
        # Adicionar sufixo baseado no tipo
        if ui_type == 'button':
            if 'press' in filename_lower or 'down' in filename_lower:
                return f"button_pressed"
            elif 'hover' in filename_lower or 'over' in filename_lower:
                return f"button_hover"
            else:
                return f"button_normal"
        elif ui_type == 'background':
            return f"{base_name}_bg"
        elif ui_type == 'icon':
            return f"icon_{base_name}"
        else:
            return base_name
    
    def extract_ui_element(self, frm_path: str) -> Optional[UIElementMetadata]:
        """
        Extrai um elemento de UI individual.
        
        Args:
            frm_path: Caminho interno do arquivo FRM no DAT2
            
        Returns:
            UIElementMetadata se extraído com sucesso, None caso contrário
        """
        try:
            # Obter dados do FRM
            frm_data = self.dat_manager.get_file(frm_path)
            if not frm_data:
                return None
            
            # Decodificar FRM
            frm_image = self.decoder.decode(frm_data)
            
            # Identificar tipo e nome
            filename = Path(frm_path).name
            ui_type = self._identify_ui_type(filename)
            descriptive_name = self._get_descriptive_name(filename, ui_type)
            
            # Obter dimensões do primeiro frame da primeira direção
            if not frm_image.frames or not frm_image.frames[0]:
                return None
            
            first_frame = frm_image.frames[0][0]
            width = first_frame.width
            height = first_frame.height
            
            # Criar diretório de saída
            type_dir = self.output_dir / ui_type
            type_dir.mkdir(parents=True, exist_ok=True)
            
            # Exportar elemento (usar primeiro frame da primeira direção)
            output_filename = f"{descriptive_name}.png"
            output_path = type_dir / output_filename
            
            self.decoder.to_png(frm_image, str(output_path), direction=0, frame=0)
            
            return UIElementMetadata(
                name=descriptive_name,
                ui_type=ui_type,
                width=width,
                height=height,
                output_path=str(output_path.relative_to(self.output_dir)),
                description=f"Elemento de UI: {descriptive_name}"
            )
            
        except Exception as e:
            print(f"Erro ao extrair elemento de UI {frm_path}: {e}")
            return None
    
    def extract_all_ui(self) -> Dict[str, List[UIElementMetadata]]:
        """
        Extrai todos os elementos de UI de art/intrface/.
        
        Returns:
            Dicionário organizado por tipo de UI
        """
        # Listar todos os arquivos FRM relacionados a interface
        all_files = self.dat_manager.list_all_files()
        ui_files = [f for f in all_files 
                   if f.lower().endswith('.frm') and 
                   'intrface' in f.lower()]
        
        print(f"Encontrados {len(ui_files)} arquivos FRM de interface")
        
        # Extrair elementos
        results: Dict[str, List[UIElementMetadata]] = {}
        
        for ui_path in ui_files:
            metadata = self.extract_ui_element(ui_path)
            if metadata:
                if metadata.ui_type not in results:
                    results[metadata.ui_type] = []
                results[metadata.ui_type].append(metadata)
        
        return results
    
    def save_metadata(self, ui_elements: Dict[str, List[UIElementMetadata]], output_file: str):
        """
        Salva metadados de todos os elementos de UI em JSON.
        
        Args:
            ui_elements: Dicionário de elementos por tipo
            output_file: Caminho do arquivo JSON de saída
        """
        # Converter para formato serializável
        output_data = {}
        for ui_type, metadata_list in ui_elements.items():
            output_data[ui_type] = [asdict(m) for m in metadata_list]
        
        output_path = Path(output_file)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        
        print(f"Metadados de UI salvos em: {output_path}")

