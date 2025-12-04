#!/usr/bin/env python3
"""
Analisador detalhado de arquivos .FRM
Para entender exatamente o formato
"""

import struct
from pathlib import Path

BASE_DIR = Path(__file__).parent.parent
EXTRACTED_DIR = BASE_DIR / "web_server" / "assets" / "extracted"
CRITTERS_DIR = EXTRACTED_DIR / "critter" / "art" / "critters"

# Analisar um arquivo específico
test_file = CRITTERS_DIR / "HMWARRAK.FRM"

if not test_file.exists():
    print(f"Arquivo não encontrado: {test_file}")
    exit(1)

print("=" * 60)
print("ANALISE DETALHADA DO ARQUIVO .FRM")
print("=" * 60)
print(f"\nArquivo: {test_file.name}")
print(f"Tamanho: {test_file.stat().st_size} bytes\n")

with open(test_file, 'rb') as f:
    data = f.read()
    
    # Mostrar primeiros 200 bytes em hex
    print("Primeiros 200 bytes (hex):")
    for i in range(0, min(200, len(data)), 16):
        hex_str = ' '.join(f'{b:02x}' for b in data[i:i+16])
        ascii_str = ''.join(chr(b) if 32 <= b < 127 else '.' for b in data[i:i+16])
        print(f"{i:04x}: {hex_str:<48} {ascii_str}")
    
    print("\n" + "=" * 60)
    print("TENTANDO DIFERENTES INTERPRETACOES DO HEADER")
    print("=" * 60)
    
    # Tentar little-endian
    f.seek(0)
    print("\n1. LITTLE-ENDIAN:")
    try:
        field_0_le = struct.unpack('<I', f.read(4))[0]
        fps_le = struct.unpack('<h', f.read(2))[0]
        action_le = struct.unpack('<h', f.read(2))[0]
        count_le = struct.unpack('<h', f.read(2))[0]
        print(f"  field_0: {field_0_le}")
        print(f"  fps: {fps_le}")
        print(f"  action_frame: {action_le}")
        print(f"  frame_count: {count_le}")
    except:
        print("  Erro")
    
    # Tentar big-endian (como fileReadInt16 faz)
    f.seek(0)
    print("\n2. BIG-ENDIAN (como fileReadInt16):")
    try:
        # fileReadInt16: high << 8 | low
        high = struct.unpack('B', f.read(1))[0]
        low = struct.unpack('B', f.read(1))[0]
        field_0_be_16 = (high << 8) | low
        high = struct.unpack('B', f.read(1))[0]
        low = struct.unpack('B', f.read(1))[0]
        field_0_be = (field_0_be_16 << 16) | ((high << 8) | low)
        
        # fps (big-endian 16-bit)
        high = struct.unpack('B', f.read(1))[0]
        low = struct.unpack('B', f.read(1))[0]
        fps_be = (high << 8) | low
        if fps_be > 32767:
            fps_be -= 65536
        
        # action_frame
        high = struct.unpack('B', f.read(1))[0]
        low = struct.unpack('B', f.read(1))[0]
        action_be = (high << 8) | low
        if action_be > 32767:
            action_be -= 65536
        
        # frame_count
        high = struct.unpack('B', f.read(1))[0]
        low = struct.unpack('B', f.read(1))[0]
        count_be = (high << 8) | low
        if count_be > 32767:
            count_be -= 65536
        
        print(f"  field_0: {field_0_be}")
        print(f"  fps: {fps_be}")
        print(f"  action_frame: {action_be}")
        print(f"  frame_count: {count_be}")
        
        if 0 < count_be < 100 and 0 < fps_be < 100:
            print("  ✅ VALORES PARECEM VÁLIDOS!")
    except Exception as e:
        print(f"  Erro: {e}")
    
    # Tentar big-endian usando struct
    f.seek(0)
    print("\n3. BIG-ENDIAN (struct '>I', '>h'):")
    try:
        field_0_be2 = struct.unpack('>I', f.read(4))[0]
        fps_be2 = struct.unpack('>h', f.read(2))[0]
        action_be2 = struct.unpack('>h', f.read(2))[0]
        count_be2 = struct.unpack('>h', f.read(2))[0]
        print(f"  field_0: {field_0_be2}")
        print(f"  fps: {fps_be2}")
        print(f"  action_frame: {action_be2}")
        print(f"  frame_count: {count_be2}")
        
        if 0 < count_be2 < 100 and 0 < fps_be2 < 100:
            print("  ✅ VALORES PARECEM VÁLIDOS!")
    except Exception as e:
        print(f"  Erro: {e}")

