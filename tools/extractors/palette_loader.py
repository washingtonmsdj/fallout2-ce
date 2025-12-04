"""
Módulo para carregamento de paletas de cores do Fallout 2.

Este módulo implementa o PaletteLoader que lê arquivos .pal (paleta de 256 cores)
usados pelo Fallout 2 para renderizar sprites FRM.
"""
from pathlib import Path
from typing import List, Tuple, Optional


class PaletteLoader:
    """
    Carregador de paletas de cores do Fallout 2.
    
    Os arquivos .pal contêm 256 cores em formato RGB, cada cor usando 6 bits
    por canal (valores de 0-63), totalizando 768 bytes (256 × 3).
    """
    
    def __init__(self, pal_path: Optional[str] = None):
        """
        Inicializa o carregador de paleta.
        
        Args:
            pal_path: Caminho para o arquivo .pal. Se None, usa paleta padrão.
        """
        self.palette: List[Tuple[int, int, int]] = []
        self.pal_path = Path(pal_path) if pal_path else None
        
        if pal_path:
            self.load(pal_path)
        else:
            self._load_default()
            
    def load(self, pal_path: str) -> List[Tuple[int, int, int]]:
        """
        Carrega uma paleta de cores de um arquivo .pal.
        
        Args:
            pal_path: Caminho para o arquivo .pal
            
        Returns:
            Lista de tuplas RGB (256 cores)
            
        Raises:
            FileNotFoundError: Se o arquivo não existir
            ValueError: Se o arquivo tiver tamanho incorreto
        """
        pal_file = Path(pal_path)
        if not pal_file.exists():
            raise FileNotFoundError(f"Arquivo de paleta não encontrado: {pal_path}")
        
        with open(pal_file, 'rb') as f:
            palette_data = f.read(768)  # 256 cores × 3 bytes (RGB)
            
        if len(palette_data) < 768:
            raise ValueError(f"Arquivo de paleta muito pequeno: {len(palette_data)} bytes (esperado 768)")
        
        # Converter paleta: cada cor usa 6 bits (0-63), converter para 8 bits (0-255)
        self.palette = []
        for i in range(256):
            r = palette_data[i * 3]
            g = palette_data[i * 3 + 1]
            b = palette_data[i * 3 + 2]
            
            # Validar valores (devem estar entre 0-63)
            if r > 63 or g > 63 or b > 63:
                # Se valores inválidos, usar preto
                r, g, b = 0, 0, 0
            
            # Converter de 6 bits para 8 bits (multiplicar por 4)
            r = r * 4
            g = g * 4
            b = b * 4
            
            # Garantir que está no range 0-255
            r = min(255, max(0, r))
            g = min(255, max(0, g))
            b = min(255, max(0, b))
            
            self.palette.append((r, g, b))
        
        self.pal_path = pal_file
        return self.palette
        
    def _load_default(self):
        """Carrega uma paleta padrão básica (fallback)."""
        # Paleta padrão simplificada (16 cores básicas repetidas)
        basic_colors = [
            (0, 0, 0),       # 0: Preto (transparente)
            (0, 0, 42),      # 1: Azul escuro
            (0, 42, 0),      # 2: Verde escuro
            (0, 42, 42),     # 3: Ciano escuro
            (42, 0, 0),      # 4: Vermelho escuro
            (42, 0, 42),     # 5: Magenta escuro
            (42, 21, 0),     # 6: Marrom
            (42, 42, 42),    # 7: Cinza escuro
            (21, 21, 21),    # 8: Cinza médio
            (21, 21, 63),    # 9: Azul médio
            (21, 63, 21),    # 10: Verde médio
            (21, 63, 63),    # 11: Ciano médio
            (63, 21, 21),    # 12: Vermelho médio
            (63, 21, 63),    # 13: Magenta médio
            (63, 63, 21),    # 14: Amarelo médio
            (63, 63, 63),    # 15: Cinza claro
        ]
        
        # Converter para 8 bits e preencher até 256 cores
        self.palette = []
        for i in range(256):
            if i < len(basic_colors):
                r, g, b = basic_colors[i]
                # Converter de 6 bits para 8 bits
                self.palette.append((r * 4, g * 4, b * 4))
            else:
                # Preencher com gradientes
                idx = i % len(basic_colors)
                r, g, b = basic_colors[idx]
                intensity = (i // len(basic_colors)) % 4
                r = min(255, r * 4 + intensity * 16)
                g = min(255, g * 4 + intensity * 16)
                b = min(255, b * 4 + intensity * 16)
                self.palette.append((r, g, b))
                
    def get_color(self, index: int) -> Tuple[int, int, int]:
        """
        Obtém uma cor da paleta pelo índice.
        
        Args:
            index: Índice da cor (0-255)
            
        Returns:
            Tupla RGB (r, g, b) com valores de 0-255
        """
        if not self.palette:
            self._load_default()
            
        if index < 0 or index >= len(self.palette):
            # Retornar preto se índice inválido
            return (0, 0, 0)
            
        return self.palette[index]
        
    def get_palette(self) -> List[Tuple[int, int, int]]:
        """
        Retorna a paleta completa.
        
        Returns:
            Lista de 256 tuplas RGB
        """
        if not self.palette:
            self._load_default()
            
        return self.palette.copy()

