#!/usr/bin/env python3
"""
Extrai sprites do menu principal do Fallout 2
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
    def __init__(self, dat_path):
        self.dat_path = Path(dat_path)
        self.files = {}
        self.file_handle = None
        
    def open(self):
        self.file_handle = open(self.dat_path, 'rb')
        f = self.file_handle
        f.seek(-8, 2)
        tree_size = struct.unpack('<I', f.read(4))[0]
        data_size = struct.unpack('<I', f.read(4))[0]
        f.seek(data_size - tree_size - 8)
        file_count = struct.unpack('<I', f.read(4))[0]
        
        for _ in range(file_count):
            name_len = struct.unpack('<I', f.read(4))[0]
            name = f.read(name_len).decode('ascii', errors='ignore').rstrip('\x00')
            compressed = struct.unpack('<B', f.read(1))[0]
            real_size = struct.unpack('<I', f.read(4))[0]
            packed_size = struct.unpack('<I', f.read(4))[0]
            offset = struct.unpack('<I', f.read(4))[0]
            self.files[name.lower().replace('\\', '/')] = {
                'compressed': compressed, 'real_size': real_size,
                'packed_size': packed_size, 'offset': offset
            }
        return len(self.files)
    
    def close(self):
        if self.file_handle:
            self.file_handle.close()
    
    def extract(self, filename):
        filename = filename.lower().replace('\\', '/')
        if filename not in self.files:
            return None
        info = self.files[filename]
        self.file_handle.seek(info['offset'])
        data = self.file_handle.read(info['packed_size'])
        if info['compressed']:
            try:
                data = zlib.decompress(data)
            except:
                pass
        return data
    
    def list_files(self, ext=None, contains=None):
        files = list(self.files.keys())
        if ext:
            files = [f for f in files if f.endswith(ext.lower())]
        if contains:
            files = [f for f in files if contains.lower() in f]
        return sorted(files)


def load_palette(extractor):
    data = extractor.extract('color.pal')
    if not data:
        return [(i, i, i) for i in range(256)]
    palette = []
    for i in range(256):
        r = min(255, data[i * 3] * 4)
        g = min(255, data[i * 3 + 1] * 4)
        b = min(255, data[i * 3 + 2] * 4)
        palette.append((r, g, b))
    return palette


def decode_frm(data, palette):
    """Decodifica FRM e retorna imagem do primeiro frame"""
    if len(data) < 62:
        return None
    
    # Header BIG-ENDIAN
    frame_count = struct.unpack('>H', data[8:10])[0]
    data_offsets = [struct.unpack('>I', data[34+i*4:38+i*4])[0] for i in range(6)]
    
    # Primeiro frame
    offset = 62 + data_offsets[0]
    if offset + 12 > len(data):
        return None
    
    width = struct.unpack('>H', data[offset:offset+2])[0]
    height = struct.unpack('>H', data[offset+2:offset+4])[0]
    size = struct.unpack('>I', data[offset+4:offset+8])[0]
    
    if width <= 0 or height <= 0:
        return None
    
    offset += 12
    if offset + size > len(data):
        return None
    
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
                else:
                    r, g, b = palette[pal_idx]
                    pixels[x, y] = (r, g, b, 255)
    
    return img


def main():
    print("Extraindo sprites do menu principal...")
    
    extractor = DAT2Extractor("Fallout 2/master.dat")
    extractor.open()
    
    palette = load_palette(extractor)
    print(f"Paleta carregada")
    
    output_dir = Path("godot_project/assets/sprites/ui")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Sprites do menu
    menu_files = [
        ('art/intrface/mainmenu.frm', 'mainmenu.png'),
        ('art/intrface/menuup.frm', 'menuup.png'),
        ('art/intrface/menudown.frm', 'menudown.png'),
        ('art/intrface/intrface.frm', 'intrface.png'),
    ]
    
    for frm_path, out_name in menu_files:
        print(f"  Extraindo {frm_path}...")
        data = extractor.extract(frm_path)
        if data:
            img = decode_frm(data, palette)
            if img:
                img.save(output_dir / out_name, 'PNG')
                print(f"    -> {out_name} ({img.width}x{img.height})")
            else:
                print(f"    ERRO: Falha ao decodificar")
        else:
            print(f"    ERRO: Arquivo nao encontrado")
    
    # Listar arquivos de menu encontrados
    print("\nArquivos de interface disponiveis:")
    menu_frms = extractor.list_files('.frm', 'intrface/menu')
    for f in menu_frms[:20]:
        print(f"  {f}")
    
    extractor.close()
    print("\nConcluido!")


if __name__ == "__main__":
    main()
