#!/usr/bin/env python3
"""
Conversor .FRM com debug detalhado
"""

import struct
import sys
from pathlib import Path
from PIL import Image

BASE_DIR = Path(__file__).parent.parent
EXTRACTED_DIR = BASE_DIR / "web_server" / "assets" / "extracted"
CRITTERS_DIR = EXTRACTED_DIR / "critter" / "art" / "critters"
IMAGES_DIR = EXTRACTED_DIR / "images" / "critters"
IMAGES_DIR.mkdir(parents=True, exist_ok=True)

def padding_for_size(size):
    return (4 - size % 4) % 4

# Testar com um arquivo específico
test_file = CRITTERS_DIR / "HMWARRAK.FRM"
if not test_file.exists():
    print(f"Arquivo não encontrado: {test_file}")
    sys.exit(1)

print(f"Analisando: {test_file.name}")
print(f"Tamanho do arquivo: {test_file.stat().st_size} bytes\n")

with open(test_file, 'rb') as f:
    # Ler header
    field_0 = struct.unpack('<I', f.read(4))[0]
    fps = struct.unpack('<h', f.read(2))[0]
    action_frame = struct.unpack('<h', f.read(2))[0]
    frame_count = struct.unpack('<h', f.read(2))[0]
    
    x_offsets = [struct.unpack('<h', f.read(2))[0] for _ in range(6)]
    y_offsets = [struct.unpack('<h', f.read(2))[0] for _ in range(6)]
    data_offsets = [struct.unpack('<I', f.read(4))[0] for _ in range(6)]
    data_size = struct.unpack('<I', f.read(4))[0]
    
    header_pos = f.tell()
    
    print(f"Header lido:")
    print(f"  field_0: {field_0}")
    print(f"  fps: {fps}, action_frame: {action_frame}, frame_count: {frame_count}")
    print(f"  data_offsets: {data_offsets}")
    print(f"  data_size: {data_size}")
    print(f"  Posição após header: {header_pos} bytes\n")
    
    # Tentar ler primeiro frame da primeira direção
    if data_offsets[0] > 0:
        # Offset é relativo ao início dos dados (após header)
        # Mas preciso entender se há padding do header
        header_size = 62
        header_padding = padding_for_size(header_size)
        
        print(f"Calculando offset:")
        print(f"  header_size: {header_size}")
        print(f"  header_padding: {header_padding}")
        print(f"  data_offsets[0]: {data_offsets[0]}")
        
        # Tentar diferentes cálculos
        for attempt in range(3):
            if attempt == 0:
                offset = header_size + data_offsets[0]
                print(f"\nTentativa 1: header_size + data_offsets[0] = {offset}")
            elif attempt == 1:
                offset = header_size + header_padding + data_offsets[0]
                print(f"\nTentativa 2: header_size + padding + data_offsets[0] = {offset}")
            else:
                offset = data_offsets[0]
                print(f"\nTentativa 3: data_offsets[0] direto = {offset}")
            
            if offset < test_file.stat().st_size:
                f.seek(offset)
                try:
                    width = struct.unpack('<h', f.read(2))[0]
                    height = struct.unpack('<h', f.read(2))[0]
                    size = struct.unpack('<I', f.read(4))[0]
                    x = struct.unpack('<h', f.read(2))[0]
                    y = struct.unpack('<h', f.read(2))[0]
                    
                    print(f"  Lido: width={width}, height={height}, size={size}, x={x}, y={y}")
                    if width > 0 and height > 0 and size > 0 and size < 1000000:
                        print(f"  SUCESSO! Frame válido encontrado!")
                        break
                    else:
                        print(f"  Valores inválidos")
                except:
                    print(f"  Erro ao ler")
            else:
                print(f"  Offset maior que arquivo")

