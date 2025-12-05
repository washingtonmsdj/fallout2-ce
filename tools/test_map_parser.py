#!/usr/bin/env python3
"""
Script de teste para o parser de mapas corrigido.
Testa o parsing de um mapa específico para verificar se funciona.
"""

import sys
import os
from pathlib import Path

# Adicionar diretório de extractors ao path
sys.path.insert(0, str(Path(__file__).parent))

from extractors.dat2_reader import DAT2Reader
from extractors.map_parser import parse_map_definitivo
import json

def test_map_parsing():
    """Testa o parsing de um mapa específico."""

    fallout2_path = Path("C:/Users/Casa/Documents/Novo github/fallout2-ce/Fallout 2")
    output_path = Path("C:/Users/Casa/Documents/Novo github/fallout2-ce/godot_project/assets")

    print("Testando parser de mapas corrigido...")

    # Abrir master.dat
    dat_path = fallout2_path / "master.dat"
    if not dat_path.exists():
        print(f"ERRO: {dat_path} não encontrado")
        return

    print(f"Abrindo {dat_path}...")
    dat = DAT2Reader(str(dat_path))
    file_count = dat.open()

    print(f"Encontrados {file_count} arquivos no DAT")

    # Procurar pelo mapa ARVILLAG.MAP
    map_name = "maps/arvillag.map"
    print(f"Procurando por {map_name}...")

    map_data = dat.get(map_name)
    if not map_data:
        print(f"ERRO: Mapa {map_name} não encontrado no DAT")
        return

    print(f"Mapa encontrado! Tamanho: {len(map_data)} bytes")

    # Parsear o mapa
    print("Parseando mapa...")
    try:
        parsed = parse_map_definitivo(map_data, map_name, verbose=True)

        print("
Resultado do parsing:")
        print(f"- Nome: {parsed['name']}")
        print(f"- Versão: {parsed['version']}")
        print(f"- Dimensões: {parsed['width']}x{parsed['height']}")
        print(f"- Tiles: {len(parsed['tiles'])}")
        print(f"- Objetos: {len(parsed['objects'])}")

        # Salvar resultado
        output_file = output_path / "data/maps/arvillag_test.json"
        output_file.parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(parsed, f, indent=2, ensure_ascii=False)

        print(f"Resultado salvo em: {output_file}")

        # Verificar se há tiles e objetos
        if len(parsed['tiles']) > 0:
            print("✅ Tiles encontrados!")
            print(f"   Primeiros 5 tiles: {parsed['tiles'][:5]}")
        else:
            print("❌ Nenhum tile encontrado")

        if len(parsed['objects']) > 0:
            print("✅ Objetos encontrados!")
            print(f"   Primeiros 3 objetos: {parsed['objects'][:3]}")
        else:
            print("❌ Nenhum objeto encontrado")

    except Exception as e:
        print(f"ERRO durante parsing: {e}")
        import traceback
        traceback.print_exc()

    dat.close()

if __name__ == "__main__":
    test_map_parsing()