#!/usr/bin/env python3
"""
Script CLI principal para extração de assets do Fallout 2.

Este script é o ponto de entrada para extrair todos os assets do Fallout 2
e convertê-los para formatos compatíveis com Godot Engine.
"""
import argparse
import sys
from pathlib import Path

# Adicionar diretório de extractors ao path
sys.path.insert(0, str(Path(__file__).parent))

from extractors.extraction_pipeline import ExtractionPipeline


def main():
    """Função principal do script CLI."""
    parser = argparse.ArgumentParser(
        description='Extrai assets do Fallout 2 para Godot Engine',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  # Extrair todos os assets
  python extract_all.py --fallout2-path "C:/Games/Fallout 2" --output-path "./godot_project"
  
  # Extrair apenas sprites
  python extract_all.py --fallout2-path "C:/Games/Fallout 2" --output-path "./godot_project" --types sprites
  
  # Extrair sprites e áudio
  python extract_all.py --fallout2-path "C:/Games/Fallout 2" --output-path "./godot_project" --types sprites audio
        """
    )
    
    parser.add_argument(
        '--fallout2-path',
        type=str,
        required=True,
        help='Caminho para instalação do Fallout 2'
    )
    
    parser.add_argument(
        '--output-path',
        type=str,
        required=True,
        help='Caminho do projeto Godot de destino'
    )
    
    parser.add_argument(
        '--types',
        nargs='+',
        choices=['sprites', 'audio', 'maps', 'texts', 'all'],
        default=['all'],
        help='Tipos de assets a extrair (padrão: all)'
    )
    
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Mostrar informações detalhadas durante extração'
    )
    
    args = parser.parse_args()
    
    # Validar caminhos
    fallout2_path = Path(args.fallout2_path)
    if not fallout2_path.exists():
        print(f"Erro: Caminho do Fallout 2 não encontrado: {fallout2_path}")
        return 1
    
    output_path = Path(args.output_path)
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Verificar arquivos DAT necessários
    required_dats = ['master.dat', 'critter.dat']
    missing_dats = []
    for dat_name in required_dats:
        if not (fallout2_path / dat_name).exists():
            missing_dats.append(dat_name)
    
    if missing_dats:
        print(f"Aviso: Arquivos DAT não encontrados: {', '.join(missing_dats)}")
        print("A extração pode ser incompleta.")
    
    # Criar pipeline
    try:
        pipeline = ExtractionPipeline(str(fallout2_path), str(output_path))
        
        # Executar extração baseada nos tipos solicitados
        if 'all' in args.types:
            report = pipeline.extract_all()
        else:
            # Extrair tipos específicos
            report = None
            if 'sprites' in args.types:
                print("\n[1] Extraindo sprites...")
                pipeline.extract_sprites()
            
            if 'audio' in args.types:
                print("\n[2] Extraindo áudio...")
                pipeline.extract_audio()
            
            if 'maps' in args.types:
                print("\n[3] Extraindo mapas...")
                pipeline.extract_maps()
            
            if 'texts' in args.types:
                print("\n[4] Extraindo textos...")
                pipeline.extract_texts()
            
            # Gerar manifesto
            print("\n[Final] Gerando manifesto...")
            pipeline.organizer.save_manifest()
            
            report = pipeline.organizer.generate_manifest()
        
        # Mostrar relatório
        print("\n" + "=" * 60)
        print("Extração Concluída!")
        print("=" * 60)
        
        if isinstance(report, dict):
            print(f"Total de assets: {report.get('total_assets', 0)}")
            print(f"Manifesto: {output_path / 'assets' / 'manifest.json'}")
        else:
            print(f"Arquivos processados: {report.extracted_files}")
            print(f"Arquivos com erro: {report.failed_files}")
            print(f"Duração: {report.duration_seconds:.2f} segundos")
            print(f"Manifesto: {report.manifest_path}")
        
        if args.verbose and hasattr(report, 'errors') and report.errors:
            print(f"\nErros encontrados: {len(report.errors)}")
            for error in report.errors[:10]:  # Mostrar primeiros 10
                print(f"  - {error.file_path}: {error.message}")
        
        pipeline.close()
        return 0
        
    except KeyboardInterrupt:
        print("\n\nExtração cancelada pelo usuário.")
        return 1
    except Exception as e:
        print(f"\nErro fatal durante extração: {e}")
        if args.verbose:
            import traceback
            traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())

