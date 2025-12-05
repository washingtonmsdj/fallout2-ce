#!/usr/bin/env python3
"""
Script para corrigir especificamente o mapa ARTEMPLE.MAP
"""

import sys
from pathlib import Path

# Adicionar diretório de extractors ao path
sys.path.insert(0, str(Path(__file__).parent))

from extractors.dat2_reader import DAT2Reader
import json

def fix_artemple_map():
    """Corrige especificamente o mapa ARTEMPLE."""

    fallout2_path = Path("C:/Users/Casa/Documents/Novo github/fallout2-ce/Fallout 2")
    output_path = Path("C:/Users/Casa/Documents/Novo github/fallout2-ce/godot_project/assets")

    print("Corrigindo mapa ARTEMPLE...")

    # Abrir master.dat
    dat_path = fallout2_path / "master.dat"
    if not dat_path.exists():
        print(f"ERRO: {dat_path} não encontrado")
        return False

    dat = DAT2Reader(str(dat_path))
    file_count = dat.open()
    print(f"DAT aberto com {file_count} arquivos")

    # Ler mapa ARTEMPLE
    map_name = "maps/artemple.map"
    map_data = dat.get(map_name)

    if not map_data:
        print(f"ERRO: Mapa {map_name} não encontrado")
        dat.close()
        return False

    print(f"Mapa encontrado! {len(map_data)} bytes")

    # Usar o parser corrigido (importar aqui para evitar problemas)
    try:
        from extractors.map_parser import parse_map_definitivo

        # Parsear
        parsed = parse_map_definitivo(map_data, "artemple.map", verbose=True)

        print("
Parsing concluído:")
        print(f"- Nome: {parsed['name']}")
        print(f"- Tiles: {len(parsed['tiles'])}")
        print(f"- Objetos: {len(parsed['objects'])}")

        # Salvar
        output_file = output_path / "maps/Maps/ARTEMPLE.json"
        output_file.parent.mkdir(parents=True, exist_ok=True)

        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(parsed, f, indent=2, ensure_ascii=False)

        print(f"Arquivo salvo em: {output_file}")

        if len(parsed['tiles']) > 0:
            print("✅ Tiles encontrados!")
        else:
            print("❌ Nenhum tile encontrado")

        if len(parsed['objects']) > 0:
            print("✅ Objetos encontrados!")
        else:
            print("❌ Nenhum objeto encontrado")

        dat.close()
        return True

    except Exception as e:
        print(f"ERRO: {e}")
        import traceback
        traceback.print_exc()
        dat.close()
        return False

if __name__ == "__main__":
    # Executar diretamente
    fix_artemple_map()