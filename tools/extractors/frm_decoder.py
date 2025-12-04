"""
Módulo para decodificação de sprites FRM do Fallout 2.

Este módulo implementa o FRMDecoder que lê arquivos .FRM e converte para PNG,
preservando transparência, múltiplas direções e animações.
"""
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict
from dataclasses import dataclass
from PIL import Image

from .palette_loader import PaletteLoader


@dataclass
class Frame:
    """Dados de um frame individual."""
    width: int
    height: int
    offset_x: int
    offset_y: int
    pixels: bytes


@dataclass
class FRMImage:
    """Dados completos de uma imagem FRM."""
    version: int
    fps: int
    action_frame: int
    num_frames: int
    num_directions: int
    x_offsets: List[int]
    y_offsets: List[int]
    frames: List[List[Frame]]  # [direction][frame]


class FRMDecoder:
    """
    Decodificador de arquivos FRM do Fallout 2.
    
    O formato FRM armazena sprites com até 6 direções isométricas e múltiplos
    frames de animação. Os pixels são indexados por paleta (0-255).
    """
    
    # Nomes das direções
    DIRECTION_NAMES = ['ne', 'e', 'se', 'sw', 'w', 'nw']
    DIRECTION_SUFFIXES = ['_ne', '_e', '_se', '_sw', '_w', '_nw']
    
    def __init__(self, palette: Optional[PaletteLoader] = None):
        """
        Inicializa o decodificador FRM.
        
        Args:
            palette: Carregador de paleta. Se None, cria um novo.
        """
        if palette is None:
            self.palette = PaletteLoader()
        else:
            self.palette = palette
            
    def _read_int16_be(self, data: bytes, offset: int) -> int:
        """Lê int16 big-endian."""
        high = data[offset]
        low = data[offset + 1]
        value = (high << 8) | low
        # Signed
        if value > 32767:
            value -= 65536
        return value
    
    def _read_int32_be(self, data: bytes, offset: int) -> int:
        """Lê int32 big-endian."""
        value = struct.unpack('>I', data[offset:offset+4])[0]
        # Signed
        if value > 2147483647:
            value -= 4294967296
        return value
    
    def _padding_for_size(self, size: int) -> int:
        """Calcula padding para alinhamento de 4 bytes."""
        return (4 - size % 4) % 4
    
    def decode(self, frm_data: bytes) -> FRMImage:
        """
        Decodifica dados FRM em uma estrutura FRMImage.
        
        Args:
            frm_data: Dados binários do arquivo FRM
            
        Returns:
            FRMImage com todos os frames e direções
            
        Raises:
            ValueError: Se os dados forem inválidos
        """
        if len(frm_data) < 62:
            raise ValueError("Dados FRM muito pequenos")
        
        # Ler header (big-endian)
        version = self._read_int32_be(frm_data, 0)
        fps = self._read_int16_be(frm_data, 4)
        action_frame = self._read_int16_be(frm_data, 6)
        frame_count = self._read_int16_be(frm_data, 8)
        
        # Ler offsets
        x_offsets = [self._read_int16_be(frm_data, 10 + i * 2) for i in range(6)]
        y_offsets = [self._read_int16_be(frm_data, 22 + i * 2) for i in range(6)]
        data_offsets = [self._read_int32_be(frm_data, 34 + i * 4) for i in range(6)]
        data_size = self._read_int32_be(frm_data, 58)
        
        # Calcular padding do header
        header_size = 62
        header_padding = self._padding_for_size(header_size)
        
        # Decodificar frames por direção
        frames_by_direction: List[List[Frame]] = [[] for _ in range(6)]
        num_directions = 0
        
        # Base offset: header + header_padding
        base_offset = header_size + header_padding
        
        for direction in range(6):
            # Verificar se a direção existe:
            # - Direção 0: sempre existe se há dados (offset 0 é válido)
            # - Outras direções: offset igual ao anterior significa que compartilha dados
            if direction == 0:
                # Direção 0 sempre existe se há dados
                if data_size == 0:
                    continue
            else:
                # Para outras direções, offset igual ao anterior significa não existe separadamente
                if data_offsets[direction] == data_offsets[direction - 1]:
                    continue
                
            num_directions += 1
            
            # Calcular offset real: base + offset da direção
            actual_offset = base_offset + data_offsets[direction]
            
            if actual_offset >= len(frm_data):
                continue
            
            # Ler frames desta direção
            offset = actual_offset
            previous_padding = 0
            
            for frame_idx in range(frame_count):
                if offset + 12 > len(frm_data):
                    break
                
                # Ler header do frame
                width = self._read_int16_be(frm_data, offset)
                height = self._read_int16_be(frm_data, offset + 2)
                size = self._read_int32_be(frm_data, offset + 4)
                x_offset = self._read_int16_be(frm_data, offset + 8)
                y_offset = self._read_int16_be(frm_data, offset + 10)
                
                if width <= 0 or height <= 0 or size <= 0:
                    break
                
                if size > 10000000:  # Sanity check
                    break
                
                # Ler pixels
                pixels_offset = offset + 12
                if pixels_offset + size > len(frm_data):
                    break
                
                pixels = frm_data[pixels_offset:pixels_offset + size]
                
                # Criar frame
                frame = Frame(
                    width=width,
                    height=height,
                    offset_x=x_offset,
                    offset_y=y_offset,
                    pixels=pixels
                )
                frames_by_direction[direction].append(frame)
                
                # Avançar para próximo frame
                frame_padding = self._padding_for_size(size)
                offset = pixels_offset + size + frame_padding
                previous_padding += frame_padding
        
        return FRMImage(
            version=version,
            fps=fps,
            action_frame=action_frame,
            num_frames=frame_count,
            num_directions=num_directions,
            x_offsets=x_offsets,
            y_offsets=y_offsets,
            frames=frames_by_direction
        )
    
    def to_png(self, frm_image: FRMImage, output_path: str, direction: int = 0, frame: int = 0) -> None:
        """
        Converte um frame específico de FRM para PNG.
        
        Args:
            frm_image: Imagem FRM decodificada
            output_path: Caminho de saída do PNG
            direction: Direção a exportar (0-5)
            frame: Frame a exportar (0-based)
        """
        if direction < 0 or direction >= 6:
            raise ValueError(f"Direção inválida: {direction}")
        
        if direction >= len(frm_image.frames) or not frm_image.frames[direction]:
            raise ValueError(f"Direção {direction} não disponível")
        
        if frame >= len(frm_image.frames[direction]):
            raise ValueError(f"Frame {frame} não disponível na direção {direction}")
        
        frame_data = frm_image.frames[direction][frame]
        
        # Criar imagem RGBA
        img = Image.new('RGBA', (frame_data.width, frame_data.height), (0, 0, 0, 0))
        pixels = img.load()
        
        # Preencher pixels
        pixel_idx = 0
        for y in range(frame_data.height):
            for x in range(frame_data.width):
                if pixel_idx < len(frame_data.pixels):
                    palette_idx = frame_data.pixels[pixel_idx]
                    pixel_idx += 1
                    
                    # Índice 0 = transparente
                    if palette_idx == 0:
                        pixels[x, y] = (0, 0, 0, 0)
                    else:
                        r, g, b = self.palette.get_color(palette_idx)
                        pixels[x, y] = (r, g, b, 255)
                else:
                    pixels[x, y] = (0, 0, 0, 0)
        
        # Salvar PNG
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        img.save(output_file, 'PNG')
    
    def to_spritesheet(self, frm_image: FRMImage, output_path: str, direction: int = 0) -> None:
        """
        Converte todos os frames de uma direção para um spritesheet PNG.
        
        Args:
            frm_image: Imagem FRM decodificada
            output_path: Caminho de saída do PNG
            direction: Direção a exportar (0-5)
        """
        if direction < 0 or direction >= 6 or direction >= len(frm_image.frames):
            raise ValueError(f"Direção inválida: {direction}")
        
        frames = frm_image.frames[direction]
        if not frames:
            raise ValueError(f"Nenhum frame disponível na direção {direction}")
        
        # Calcular dimensões do spritesheet
        max_width = max(f.width for f in frames)
        max_height = max(f.height for f in frames)
        num_frames = len(frames)
        
        # Criar spritesheet
        sheet_width = max_width * num_frames
        sheet_height = max_height
        spritesheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))
        
        # Desenhar cada frame
        for frame_idx, frame_data in enumerate(frames):
            # Criar imagem temporária para este frame
            frame_img = Image.new('RGBA', (frame_data.width, frame_data.height), (0, 0, 0, 0))
            frame_pixels = frame_img.load()
            
            pixel_idx = 0
            for y in range(frame_data.height):
                for x in range(frame_data.width):
                    if pixel_idx < len(frame_data.pixels):
                        palette_idx = frame_data.pixels[pixel_idx]
                        pixel_idx += 1
                        
                        if palette_idx == 0:
                            frame_pixels[x, y] = (0, 0, 0, 0)
                        else:
                            r, g, b = self.palette.get_color(palette_idx)
                            frame_pixels[x, y] = (r, g, b, 255)
            
            # Colar no spritesheet
            x_offset = frame_idx * max_width
            spritesheet.paste(frame_img, (x_offset, 0))
        
        # Salvar
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        spritesheet.save(output_file, 'PNG')
    
    def to_individual_frames(self, frm_image: FRMImage, output_dir: str, base_name: str) -> List[str]:
        """
        Exporta todos os frames como arquivos PNG individuais.
        
        Args:
            frm_image: Imagem FRM decodificada
            output_dir: Diretório de saída
            base_name: Nome base para os arquivos
            
        Returns:
            Lista de caminhos dos arquivos criados
        """
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        created_files = []
        
        for direction in range(6):
            if direction >= len(frm_image.frames) or not frm_image.frames[direction]:
                continue
            
            suffix = self.DIRECTION_SUFFIXES[direction]
            
            for frame_idx, frame_data in enumerate(frm_image.frames[direction]):
                frame_name = f"{base_name}{suffix}_frame{frame_idx:03d}.png"
                frame_path = output_path / frame_name
                
                self.to_png(frm_image, str(frame_path), direction, frame_idx)
                created_files.append(str(frame_path))
        
        return created_files
    
    def export_all_directions(self, frm_image: FRMImage, output_dir: str, base_name: str) -> List[str]:
        """
        Exporta todas as direções como arquivos PNG separados.
        
        Args:
            frm_image: Imagem FRM decodificada
            output_dir: Diretório de saída
            base_name: Nome base para os arquivos
            
        Returns:
            Lista de caminhos dos arquivos criados
        """
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        created_files = []
        
        for direction in range(6):
            if direction >= len(frm_image.frames) or not frm_image.frames[direction]:
                continue
            
            suffix = self.DIRECTION_SUFFIXES[direction]
            output_file = output_path / f"{base_name}{suffix}.png"
            
            # Exportar primeiro frame ou spritesheet se múltiplos frames
            if len(frm_image.frames[direction]) == 1:
                self.to_png(frm_image, str(output_file), direction, 0)
            else:
                self.to_spritesheet(frm_image, str(output_file), direction)
            
            created_files.append(str(output_file))
        
        return created_files

