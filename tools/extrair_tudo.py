#!/usr/bin/env python3
"""
Script Simplificado para Extração Completa

Este é um wrapper simples que facilita a execução da extração completa.

Uso:
    python extrair_tudo.py
    python extrair_tudo.py --fallout2-path "Fallout 2" --output-path "godot_project/assets"
"""

import sys
from pathlib import Path

# Adicionar diretório atual ao path
sys.path.insert(0, str(Path(__file__).parent))

# Importar e executar o script principal
if __name__ == '__main__':
    # Se não foram passados argumentos, usar valores padrão
    if len(sys.argv) == 1:
        # Tentar encontrar pasta do Fallout 2
        current_dir = Path(__file__).parent.parent
        fallout2_path = current_dir / "Fallout 2"
        output_path = current_dir / "godot_project" / "assets"
        
        if not fallout2_path.exists():
            print("❌ Erro: Pasta 'Fallout 2' não encontrada!")
            print(f"   Procurando em: {fallout2_path}")
            print("\nUso:")
            print("  python extrair_tudo.py")
            print("  python extrair_tudo.py --fallout2-path 'Fallout 2' --output-path 'godot_project/assets'")
            sys.exit(1)
        
        # Usar valores padrão
        sys.argv = [
            sys.argv[0],
            '--fallout2-path', str(fallout2_path),
            '--output-path', str(output_path)
        ]
    
    # Importar e executar
    from extract_complete_with_tracking import main
    sys.exit(main())

