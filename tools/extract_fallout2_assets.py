#!/usr/bin/env python3
"""
Extrator de Assets do Fallout 2
Extrai sprites do master.dat e converte para PNG
"""

import os
import sys
import struct
import zlib
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("ERRO: Pillow nao instalado. Execute: pip install Pillow")
    sys.exit(1)

class DAT2Extractor:
    """Extrai arquivos do formato DAT2 do Fallout 2"""
    
    def __init__(self, dat_path):
        self.dat_path = Path(dat_path)
        self.files = {}
        self.file_handle = None
        
    def open(self):
        """Abre o arquivo DAT e le o indice"""
        if not self.dat_path.exists():
            raise FileNotFoundError(f"Arquivo nao encontrado: {self.dat_path}")
        
        self.file_handle = open(self.dat_path, 'rb')
        f = self.file_handle
        
        # Ler footer (ultimos 8 bytes)
        f.seek(-8, 2)
        tree_size = struct.unpack('<I', f.read(4))[0]
        data_size = struct.unpack('<I', f.read(4))[0]
        
        # Posicionar no inicio da arvore de arquivos
        f.seek(data_size - tree_size - 8)
        
        # Ler numero de arquivos
        file_count = struct.unpack('<I', f.read(4))[0]
        print(f"  Arquivos no DAT: {file_count}")
        
        # Ler cada entrada
        for _ in range(file_count):
            name_len = struct.unpack('<I', f.read(4))[0]
            name = f.read(name_len).decode('ascii', errors='ignore').rstrip('\x00')
            compressed = struct.unpack('<B', f.read(1))[0]
            real_size = struct.unpack('<I', f.read(4))[0]
            packed_size = struct.unpack('<I', f.read(4))[0]
            offset = struct.unpack('<I', f.read(4))[0]
            
            self.files[name.lower().replace('\\', '/')] = {
                'name': name,
                'compressed': compressed,
                'real_size': real_size,
                'packed_size': packed_size,
                'offset': offset
            }
        
        return len(self.files)
    
    def close(self):
        if self.file_handle:
            self.file_handle.close()
            self.file_handle = None
    
    def extract(self, filename):
        """Extrai um arquivo do DAT"""
        filename = filename.lower().replace('\\', '/')
        if filename not in self.files:
            return None
        
        info = self.files[filename]
        self.file_handle.seek(info['offset'])
        data = self.file_handle.read(info['packed_size'])
        
        if info['compressed']:
            try:
                data = zlib.decompress(data)
            except zlib.error:
                pass
        
        return data
    
    def list_files(self, extension=None, contains=None):
        """Lista arquivos no DAT"""
        files = list(self.files.keys())
        if extension:
            files = [f for f in files if f.endswith(extension.lower())]
        if contains:
            files = [f for f in files if contains.lower() in f.lower()]
        return sorted(files)


class FRMDecoder:
    """Decodifica arquivos FRM do Fallout 2"""
    
    def __init__(self, palette):
        self.palette = palette
    
    def decode(self, data):
        """Decodifica FRM e retorna lista de frames"""
        if len(data) < 62:
            return []
        
        # Header (BIG-ENDIAN)
        version = struct.unpack('>I', data[0:4])[0]
        fps = struct.unpack('>H', data[4:6])[0]
        action_frame = struct.unpack('>H', data[6:8])[0]
        frame_count = struct.unpack('>H', data[8:10])[0]
        
        # Offsets para cada direcao
        x_shifts = [struct.unpack('>h', data[10+i*2:12+i*2])[0] for i in range(6)]
        y_shifts = [struct.unpack('>h', data[22+i*2:24+i*2])[0] for i in range(6)]
        data_offsets = [struct.unpack('>I', data[34+i*4:38+i*4])[0] for i in range(6)]
        
        frames = []
        base_offset = 62
        
        for direction in range(6):
            offset = base_offset + data_offsets[direction]
            
            for frame_idx in range(frame_count):
                if offset + 12 > len(data):
                    break
                
                # Frame header
                width = struct.unpack('>H', data[offset:offset+2])[0]
                height = struct.unpack('>H', data[offset+2:offset+4])[0]
                size = struct.unpack('>I', data[offset+4:offset+8])[0]
                frame_x = struct.unpack('>h', data[offset+8:offset+10])[0]
                frame_y = struct.unpack('>h', data[offset+10:offset+12])[0]
                
                if width <= 0 or height <= 0 or size <= 0:
                    break
                
                offset += 12
                
                if offset + size > len(data):
                    break
                
                # Decodificar pixels
                pixel_data = data[offset:offset+size]
                img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
                pixels = img.load()
                
                for y in range(height):
                    for x in range(width):
                        idx = y * width + x
                        if idx < len(pixel_data):
                            pal_idx = pixel_data[idx]
                            if pal_idx == 0:
                                pixels[x, y] = (0, 0, 0, 0)
                            elif pal_idx < len(self.palette):
                                r, g, b = self.palette[pal_idx]
                                pixels[x, y] = (r, g, b, 255)
                
                frames.append({
                    'image': img,
                    'direction': direction,
                    'frame': frame_idx,
                    'width': width,
                    'height': height,
                    'x_offset': x_shifts[direction] + frame_x,
                    'y_offset': y_shifts[direction] + frame_y
                })
                
                offset += size
                offset += (4 - size % 4) % 4  # Padding
            
            # Se primeira direcao nao tem dados, as outras tambem nao
            if direction == 0 and not frames:
                break
        
        return frames


def load_palette(dat_extractor):
    """Carrega paleta de cores do DAT"""
    pal_data = dat_extractor.extract('color.pal')
    
    if not pal_data:
        print("  AVISO: color.pal nao encontrado, usando paleta padrao")
        return [(i, i, i) for i in range(256)]
    
    palette = []
    for i in range(256):
        r = min(255, pal_data[i * 3] * 4)
        g = min(255, pal_data[i * 3 + 1] * 4)
        b = min(255, pal_data[i * 3 + 2] * 4)
        palette.append((r, g, b))
    
    print("  Paleta carregada: 256 cores")
    return palette


def extract_interface_sprites(dat_extractor, palette, output_dir):
    """Extrai sprites da interface"""
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    decoder = FRMDecoder(palette)
    
    # Sprites importantes da interface
    interface_files = [
        'art/intrface/mainmenu.frm',    # Menu principal background
        'art/intrface/menuup.frm',       # Botao normal
        'art/intrface/menudown.frm',     # Botao pressionado
        'art/intrface/intrface.frm',     # Interface bar
        'art/intrface/iface.frm',        # Interface alternativa
    ]
    
    # Listar todos os FRMs de interface
    all_interface = dat_extractor.list_files('.frm', 'intrface')
    print(f"  Encontrados {len(all_interface)} arquivos de interface")
    
    extracted = 0
    for frm_path in all_interface[:50]:  # Limitar para teste
        frm_data = dat_extractor.extract(frm_path)
        if not frm_data:
            continue
        
        frames = decoder.decode(frm_data)
        if not frames:
            continue
        
        # Nome do arquivo
        name = Path(frm_path).stem.lower()
        
        # Salvar primeiro frame (ou todos se animado)
        for i, frame in enumerate(frames):
            if len(frames) == 1:
                out_path = output_dir / f"{name}.png"
            else:
                out_path = output_dir / f"{name}_d{frame['direction']}_f{frame['frame']}.png"
            
            frame['image'].save(out_path, 'PNG')
        
        extracted += 1
    
    return extracted


def main():
    print("=" * 60)
    print("EXTRATOR DE ASSETS DO FALLOUT 2")
    print("=" * 60)
    
    # Caminhos
    fallout_dir = Path("Fallout 2")
    output_dir = Path("godot_project/assets/sprites/ui")
    
    master_dat = fallout_dir / "master.dat"
    
    if not master_dat.exists():
        print(f"ERRO: {master_dat} nao encontrado!")
        return
    
    print(f"\nAbrindo {master_dat}...")
    extractor = DAT2Extractor(master_dat)
    
    try:
        file_count = extractor.open()
        print(f"  Total de arquivos: {file_count}")
        
        # Carregar paleta
        print("\nCarregando paleta...")
        palette = load_palette(extractor)
        
        # Extrair interface
        print("\nExtraindo sprites de interface...")
        count = extract_interface_sprites(extractor, palette, output_dir)
        print(f"  Extraidos: {count} sprites")
        
        print(f"\nSprites salvos em: {output_dir}")
        
    finally:
        extractor.close()
    
    print("\n" + "=" * 60)
    print("EXTRACAO CONCLUIDA!")
    print("=" * 60)


if __name__ == "__main__":
    main()
