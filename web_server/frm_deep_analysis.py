#!/usr/bin/env python3
"""
Análise profunda de um arquivo .FRM específico
Para encontrar onde estão os dados dos frames
"""

import struct
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
EXTRACTED_DIR = BASE_DIR / "web_server" / "assets" / "extracted"
CRITTERS_DIR = EXTRACTED_DIR / "critter" / "art" / "critters"

test_file = CRITTERS_DIR / "HMWARRAK.FRM"

def read_int16_be(f):
    high = struct.unpack('B', f.read(1))[0]
    low = struct.unpack('B', f.read(1))[0]
    value = (high << 8) | low
    if value > 32767:
        value -= 65536
    return value

def read_int32_be(f):
    bytes_data = f.read(4)
    value = struct.unpack('>I', bytes_data)[0]
    if value > 2147483647:
        value -= 4294967296
    return value

print("=" * 60)
print("ANALISE PROFUNDA - HMWARRAK.FRM")
print("=" * 60)

with open(test_file, 'rb') as f:
    file_size = test_file.stat().st_size
    print(f"\nTamanho do arquivo: {file_size} bytes")
    
    # Ler header
    field_0 = read_int32_be(f)
    fps = read_int16_be(f)
    action_frame = read_int16_be(f)
    frame_count = read_int16_be(f)
    
    x_offsets = [read_int16_be(f) for _ in range(6)]
    y_offsets = [read_int16_be(f) for _ in range(6)]
    data_offsets = [read_int32_be(f) for _ in range(6)]
    data_size = read_int32_be(f)
    
    header_pos = f.tell()
    
    print(f"\nHeader lido:")
    print(f"  field_0: {field_0}")
    print(f"  fps: {fps}, action_frame: {action_frame}, frame_count: {frame_count}")
    print(f"  data_offsets: {data_offsets}")
    print(f"  data_size: {data_size}")
    print(f"  Posição após header: {header_pos} bytes")
    
    # Verificar offsets
    print(f"\nVerificando offsets:")
    header_size = 62
    header_padding = (4 - header_size % 4) % 4
    
    for direction in range(6):
        if data_offsets[direction] == 0:
            print(f"  Direção {direction}: offset = 0 (sem dados)")
            continue
        
        # Tentar diferentes cálculos de offset
        for attempt in range(5):
            if attempt == 0:
                offset = header_size + data_offsets[direction]
                desc = "header_size + data_offsets"
            elif attempt == 1:
                offset = header_size + header_padding + data_offsets[direction]
                desc = "header_size + padding + data_offsets"
            elif attempt == 2:
                offset = data_offsets[direction]
                desc = "data_offsets direto"
            elif attempt == 3:
                offset = header_pos + data_offsets[direction]
                desc = "header_pos + data_offsets"
            else:
                offset = header_pos + header_padding + data_offsets[direction]
                desc = "header_pos + padding + data_offsets"
            
            if 0 <= offset < file_size:
                f.seek(offset)
                try:
                    width = read_int16_be(f)
                    height = read_int16_be(f)
                    size = read_int32_be(f)
                    
                    print(f"  Direção {direction}, tentativa '{desc}': offset={offset}")
                    print(f"    Lido: width={width}, height={height}, size={size}")
                    
                    if width > 0 and height > 0 and 0 < size < 1000000:
                        print(f"    ✅ VALORES VÁLIDOS! Este é o offset correto!")
                        
                        # Ler mais para confirmar
                        x = read_int16_be(f)
                        y = read_int16_be(f)
                        print(f"    x_offset={x}, y_offset={y}")
                        
                        # Verificar se há dados suficientes
                        if offset + 12 + size <= file_size:
                            print(f"    ✅ Dados suficientes no arquivo!")
                            break
                except:
                    pass

