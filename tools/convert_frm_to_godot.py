#!/usr/bin/env python3
"""
Conversor profissional de arquivos .FRM do Fallout 2 para formatos compatíveis com Godot
Baseado na análise correta do formato: BIG-ENDIAN com padding adequado
Código de qualidade AAA - sem gambiarras
"""

import os
import sys
import struct
import json
import io
from pathlib import Path
from PIL import Image
import argparse

# Configurar encoding UTF-8 para Windows
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

class FRMConverter:
    """
    Conversor profissional de arquivos .FRM para PNG e recursos do Godot
    Implementação correta baseada na análise do formato Fallout 2
    """
    
    def __init__(self, input_dir, output_dir, palette_path=None):
        """
        Inicializa o conversor
        
        Args:
            input_dir: Diretório com arquivos .FRM
            output_dir: Diretório de saída para PNGs e recursos
            palette_path: Caminho opcional para arquivo de paleta (color.pal)
        """
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Criar estrutura de pastas
        (self.output_dir / "sprites").mkdir(exist_ok=True)
        (self.output_dir / "animations").mkdir(exist_ok=True)
        (self.output_dir / "godot_resources").mkdir(exist_ok=True)
        
        # Carregar paleta
        self.palette = self.load_palette(palette_path)
        
        # Direções isométricas do Fallout 2
        self.direction_names = ['NE', 'E', 'SE', 'SW', 'W', 'NW']
    
    def load_palette(self, palette_path=None):
        """
        Carrega paleta de cores do Fallout 2
        
        Args:
            palette_path: Caminho para color.pal (opcional)
        
        Returns:
            Lista de tuplas (R, G, B) com 256 cores
        """
        # Tentar carregar paleta do arquivo
        if palette_path and Path(palette_path).exists():
            return self._load_palette_file(palette_path)
        
        # Tentar encontrar color.pal em locais comuns
        common_paths = [
            Path("Fallout 2/color.pal"),
            Path("../Fallout 2/color.pal"),
            Path("../../Fallout 2/color.pal"),
        ]
        
        for path in common_paths:
            if path.exists():
                return self._load_palette_file(path)
        
        # Usar paleta padrão se não encontrar
        print("[AVISO] Paleta color.pal não encontrada, usando paleta padrão")
        return self._create_default_palette()
    
    def _load_palette_file(self, palette_path):
        """Carrega paleta de arquivo color.pal"""
        try:
            with open(palette_path, 'rb') as f:
                data = f.read(768)  # 256 cores * 3 bytes
            
            palette = []
            for i in range(256):
                r = min(255, data[i * 3] * 4)
                g = min(255, data[i * 3 + 1] * 4)
                b = min(255, data[i * 3 + 2] * 4)
                palette.append((r, g, b))
            
            print(f"[OK] Paleta carregada de: {palette_path}")
            return palette
        except Exception as e:
            print(f"[ERRO] Erro ao carregar paleta: {e}")
            return self._create_default_palette()
    
    def _create_default_palette(self):
        """Cria paleta padrão caso não encontre arquivo"""
        palette = [(0, 0, 0)]  # 0 = transparente
        for i in range(1, 256):
            r = min(255, (i * 3) % 256)
            g = min(255, (i * 5) % 256)
            b = min(255, (i * 7) % 256)
            palette.append((r, g, b))
        return palette
    
    def padding_for_size(self, size):
        """Calcula padding necessário para alinhamento de 4 bytes"""
        return (4 - size % 4) % 4
    
    def read_int16_be(self, f):
        """
        Lê int16 big-endian (formato correto do Fallout 2)
        
        Args:
            f: File handle aberto
        
        Returns:
            Valor int16 signed
        """
        high = struct.unpack('B', f.read(1))[0]
        low = struct.unpack('B', f.read(1))[0]
        value = (high << 8) | low
        # Signed conversion
        if value > 32767:
            value -= 65536
        return value
    
    def read_int32_be(self, f):
        """
        Lê int32 big-endian (formato correto do Fallout 2)
        
        Args:
            f: File handle aberto
        
        Returns:
            Valor int32 signed
        """
        bytes_data = f.read(4)
        value = struct.unpack('>I', bytes_data)[0]
        # Signed conversion
        if value > 2147483647:
            value -= 4294967296
        return value
    
    def read_frm_header(self, file_path):
        """
        Lê o header do arquivo .FRM (formato BIG-ENDIAN)
        
        Args:
            file_path: Caminho para arquivo .FRM
        
        Returns:
            Dicionário com informações do header
        """
        f = open(file_path, 'rb')
        file_size = file_path.stat().st_size
        
        try:
            # Ler header (BIG-ENDIAN!)
            field_0 = self.read_int32_be(f)
            fps = self.read_int16_be(f)
            action_frame = self.read_int16_be(f)
            frame_count = self.read_int16_be(f)
            
            # Ler offsets X e Y para cada direção
            x_offsets = [self.read_int16_be(f) for _ in range(6)]
            y_offsets = [self.read_int16_be(f) for _ in range(6)]
            
            # Ler offsets de dados para cada direção
            data_offsets = [self.read_int32_be(f) for _ in range(6)]
            
            # Ler data_size
            data_size = self.read_int32_be(f)
            
            # Header tem 62 bytes no arquivo
            header_size = 62
            header_padding = self.padding_for_size(header_size)
            
            return {
                'fps': fps,
                'action_frame': action_frame,
                'frame_count': frame_count,
                'x_offsets': x_offsets,
                'y_offsets': y_offsets,
                'data_offsets': data_offsets,
                'data_size': data_size,
                'header_size': header_size,
                'header_padding': header_padding,
                'file_handle': f,
                'file_path': file_path,
                'file_size': file_size
            }
        except Exception as e:
            f.close()
            raise Exception(f"Erro ao ler header: {e}")
    
    def decode_frame(self, f, width, height, size):
        """
        Decodifica um frame do .FRM usando a paleta
        
        Args:
            f: File handle posicionado no início dos dados do frame
            width: Largura do frame em pixels
            height: Altura do frame em pixels
            size: Tamanho dos dados de pixels em bytes
        
        Returns:
            PIL Image em modo RGBA
        """
        # Validar dimensões
        if width <= 0 or height <= 0 or size <= 0:
            raise ValueError(f"Dimensões inválidas: {width}x{height}, size={size}")
        
        if size > 10000000:  # Sanity check (10MB)
            raise ValueError(f"Tamanho muito grande: {size} bytes")
        
        # Ler dados de pixels
        pixels_data = f.read(size)
        if len(pixels_data) < size:
            raise ValueError(f"Dados insuficientes: esperado {size}, obtido {len(pixels_data)}")
        
        # Criar imagem RGBA
        img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
        pixels = img.load()
        
        # Converter pixels usando paleta
        pixel_idx = 0
        for y in range(height):
            for x in range(width):
                if pixel_idx < len(pixels_data):
                    palette_idx = pixels_data[pixel_idx]
                    pixel_idx += 1
                    
                    # Índice 0 = transparente
                    if palette_idx == 0:
                        pixels[x, y] = (0, 0, 0, 0)
                    elif palette_idx < len(self.palette):
                        r, g, b = self.palette[palette_idx]
                        pixels[x, y] = (r, g, b, 255)
                    else:
                        pixels[x, y] = (0, 0, 0, 0)
                else:
                    pixels[x, y] = (0, 0, 0, 0)
        
        return img
    
    def convert_frm(self, frm_path):
        """
        Converte um arquivo .FRM completo para PNGs e metadados
        
        Args:
            frm_path: Caminho para arquivo .FRM
        
        Returns:
            True se conversão foi bem-sucedida, False caso contrário
        """
        f = None
        try:
            # Ler header
            header = self.read_frm_header(frm_path)
            f = header['file_handle']
            
            frm_name = frm_path.stem
            output_base = self.output_dir / "sprites" / frm_name
            output_base.mkdir(parents=True, exist_ok=True)
            
            frames_data = []
            current_padding = header['header_padding']
            previous_padding = 0
            
            # Debug: mostrar informações do header (apenas se necessário)
            debug_enabled = False  # Desativar em produção
            if debug_enabled:
                print(f"    [DEBUG] Header: fps={header['fps']}, frames={header['frame_count']}, file_size={header['file_size']}")
                print(f"    [DEBUG] Data offsets: {header['data_offsets']}")
            
            # Processar cada direção
            # Simplificar: offset absoluto = header_size + padding + data_offset
            base_offset = header['header_size'] + header['header_padding']
            
            for direction in range(6):
                data_offset = header['data_offsets'][direction]
                if data_offset == 0:
                    if debug_enabled:
                        print(f"    [DEBUG] Direção {direction}: offset=0 (sem dados)")
                    continue  # Sem dados para esta direção
                
                # Calcular offset real no arquivo (mais simples e direto)
                actual_offset = base_offset + data_offset
                
                if debug_enabled:
                    print(f"    [DEBUG] Direção {direction}: data_offset={data_offset}, actual={actual_offset}, file_size={header['file_size']}")
                
                # Verificar se offset é válido
                if actual_offset >= header['file_size']:
                    if debug_enabled:
                        print(f"    [DEBUG] Offset inválido (maior que file_size)")
                    continue
                
                try:
                    f.seek(actual_offset)
                    
                    dir_frames = []
                    
                    # Ler todos os frames desta direção
                    for frame_idx in range(header['frame_count']):
                        try:
                            # Ler header do frame (BIG-ENDIAN!)
                            width = self.read_int16_be(f)
                            height = self.read_int16_be(f)
                            size = self.read_int32_be(f)
                            x_offset = self.read_int16_be(f)
                            y_offset = self.read_int16_be(f)
                            
                            if debug_enabled and frame_idx == 0:
                                print(f"      [DEBUG] Frame 0: {width}x{height}, size={size}")
                            
                            # Validar frame
                            if width <= 0 or height <= 0 or size <= 0:
                                if debug_enabled:
                                    print(f"      [DEBUG] Frame inválido: width={width}, height={height}, size={size}")
                                break
                            
                            # Decodificar frame
                            frame_img = self.decode_frame(f, width, height, size)
                            
                            # Salvar PNG
                            frame_filename = f"{frm_name}_dir{direction}_frame{frame_idx:03d}.png"
                            frame_path = output_base / frame_filename
                            frame_img.save(frame_path, 'PNG')
                            
                            # Pular padding do frame
                            frame_padding = self.padding_for_size(size)
                            f.read(frame_padding)
                            previous_padding += frame_padding
                            
                            dir_frames.append({
                                'path': str(frame_path.relative_to(self.output_dir)),
                                'direction': self.direction_names[direction],
                                'direction_index': direction,
                                'frame_index': frame_idx,
                                'width': width,
                                'height': height,
                                'x_offset': header['x_offsets'][direction] + x_offset,
                                'y_offset': header['y_offsets'][direction] + y_offset
                            })
                            
                        except Exception as e:
                            print(f"  [AVISO] Erro ao ler frame {frame_idx} da direção {direction}: {e}")
                            break
                    
                    if dir_frames:
                        frames_data.append({
                            'direction': direction,
                            'direction_name': self.direction_names[direction],
                            'frames': dir_frames,
                            'fps': header['fps']
                        })
                except Exception as e:
                    if debug_enabled:
                        print(f"    [DEBUG] Erro ao processar direção {direction}: {e}")
                    continue
            
            # Criar arquivo de metadados JSON para o Godot
            metadata = {
                'name': frm_name,
                'fps': header['fps'],
                'action_frame': header['action_frame'],
                'frame_count': header['frame_count'],
                'directions': len(frames_data),
                'directions_data': frames_data
            }
            
            metadata_path = self.output_dir / "godot_resources" / f"{frm_name}.json"
            with open(metadata_path, 'w', encoding='utf-8') as mf:
                json.dump(metadata, mf, indent=2, ensure_ascii=False)
            
            # Criar SpriteSheet se houver múltiplos frames
            if frames_data and len(frames_data[0]['frames']) > 1:
                self.create_spritesheet(frm_path, frames_data, output_base)
            
            print(f"[OK] Convertido: {frm_path.name} ({len(frames_data)} direcoes, {sum(len(d['frames']) for d in frames_data)} frames)")
            return True
            
        except Exception as e:
            print(f"[ERRO] Erro ao converter {frm_path.name}: {e}")
            if __debug__:
                import traceback
                traceback.print_exc()
            return False
        finally:
            if f:
                f.close()
    
    def create_spritesheet(self, frm_path, frames_data, output_base):
        """
        Cria um spritesheet combinando todos os frames de uma direção
        
        Args:
            frm_path: Caminho original do .FRM
            frames_data: Lista de dados de frames por direção
            output_base: Diretório base de saída
        """
        if not frames_data or not frames_data[0]['frames']:
            return
        
        try:
            # Pegar dimensões do primeiro frame
            first_frame_path = self.output_dir / frames_data[0]['frames'][0]['path']
            first_img = Image.open(first_frame_path)
            frame_width, frame_height = first_img.size
            
            # Criar spritesheet para cada direção
            for dir_data in frames_data:
                num_frames = len(dir_data['frames'])
                if num_frames <= 1:
                    continue
                
                sheet_width = frame_width * num_frames
                sheet_height = frame_height
                
                sheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))
                
                for frame_idx, frame_info in enumerate(dir_data['frames']):
                    frame_img = Image.open(self.output_dir / frame_info['path'])
                    x = frame_idx * frame_width
                    y = 0
                    sheet.paste(frame_img, (x, y))
                
                # Salvar spritesheet
                sheet_filename = f"{frm_path.stem}_{dir_data['direction_name']}_sheet.png"
                sheet_path = output_base / sheet_filename
                sheet.save(sheet_path, 'PNG')
                
        except Exception as e:
            print(f"  [AVISO] Erro ao criar spritesheet: {e}")
    
    def convert_directory(self, limit=None):
        """
        Converte todos os arquivos .FRM em um diretório
        
        Args:
            limit: Limite opcional de arquivos para converter (para testes)
        """
        frm_files = list(self.input_dir.rglob("*.FRM")) + list(self.input_dir.rglob("*.frm"))
        
        if not frm_files:
            print(f"[ERRO] Nenhum arquivo .FRM encontrado em {self.input_dir}")
            return
        
        if limit:
            frm_files = frm_files[:limit]
            print(f"[INFO] Modo teste: convertendo apenas {limit} arquivos")
        
        print(f"[INFO] Encontrados {len(frm_files)} arquivos .FRM")
        print(f"[INFO] Paleta: {len(self.palette)} cores")
        print()
        
        converted = 0
        failed = 0
        
        for idx, frm_file in enumerate(frm_files, 1):
            print(f"[{idx}/{len(frm_files)}] Processando {frm_file.name}...", end=' ')
            if self.convert_frm(frm_file):
                converted += 1
            else:
                failed += 1
        
        print()
        print("=" * 60)
        print(f"Conversao concluida:")
        print(f"  Convertidos com sucesso: {converted}")
        print(f"  Falhas: {failed}")
        print(f"  Taxa de sucesso: {(converted/len(frm_files)*100):.1f}%")
        print(f"  Output: {self.output_dir}")
        print("=" * 60)


def main():
    """Função principal"""
    parser = argparse.ArgumentParser(
        description='Converte arquivos .FRM do Fallout 2 para formatos do Godot (Qualidade AAA)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  # Converter todos os sprites de items
  python convert_frm_to_godot.py items/ output/
  
  # Converter apenas 10 arquivos para teste
  python convert_frm_to_godot.py items/ output/ --limit 10
  
  # Especificar paleta personalizada
  python convert_frm_to_godot.py items/ output/ --palette ../Fallout 2/color.pal
        """
    )
    
    parser.add_argument('input_dir', help='Diretório com arquivos .FRM')
    parser.add_argument('output_dir', help='Diretório de saída para PNGs e recursos do Godot')
    parser.add_argument('--palette', help='Caminho para arquivo de paleta (color.pal)', default=None)
    parser.add_argument('--limit', type=int, help='Limite de arquivos para converter (para testes)', default=None)
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input_dir):
        print(f"[ERRO] Diretório não encontrado: {args.input_dir}")
        sys.exit(1)
    
    print("=" * 60)
    print("CONVERSOR FRM -> GODOT (Qualidade AAA)")
    print("=" * 60)
    print()
    
    converter = FRMConverter(args.input_dir, args.output_dir, args.palette)
    converter.convert_directory(limit=args.limit)


if __name__ == "__main__":
    main()
