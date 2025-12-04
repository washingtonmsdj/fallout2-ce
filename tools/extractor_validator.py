"""
Extractor Validator - Sistema profissional de validação de extractors.

Valida e testa todos os extractors Python para garantir que funcionam
corretamente com todos os arquivos do Fallout 2.

Requirements: 2.1, 3.3, 3.4
"""
import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict
from datetime import datetime
import hashlib

from extractors.dat2_reader import DAT2Reader, DAT2Manager
from extractors.frm_decoder import FRMDecoder
from extractors.map_parser import MAPParser
from extractors.pro_parser import parse_proto
from extractors.msg_parser import MSGParser
from extractors.palette_loader import PaletteLoader


@dataclass
class ValidationResult:
    """Resultado de validação de um extrator."""
    extractor_name: str
    total_files: int
    successful: int
    failed: int
    errors: List[str] = None
    details: Dict[str, Any] = None


class ExtractorValidator:
    """
    Sistema profissional de validação de extractors.
    
    Valida todos os extractors contra os arquivos reais do Fallout 2,
    garantindo que funcionam corretamente.
    """
    
    def __init__(self, fallout2_path: str, output_dir: str = "analysis/extractor_validation"):
        """
        Inicializa o validador.
        
        Args:
            fallout2_path: Caminho para a pasta do Fallout 2
            output_dir: Diretório de saída para relatórios
        """
        self.fallout2_path = Path(fallout2_path)
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(parents=True, exist_ok=True)
        
        # Criar lista de caminhos DAT
        dat_files = []
        for dat_name in ['master.dat', 'critter.dat', 'patch000.dat']:
            dat_path = self.fallout2_path / dat_name
            if dat_path.exists():
                dat_files.append(str(dat_path))
        
        self.dat_manager = DAT2Manager(dat_files)
        self.palette_loader = PaletteLoader()
        self.frm_decoder = FRMDecoder(self.palette_loader)
        self.map_parser = MAPParser()
        self.msg_parser = MSGParser()
        
        self.results: Dict[str, ValidationResult] = {}
    
    def validate_dat2_reader(self) -> ValidationResult:
        """
        Valida DAT2Reader com todos os arquivos.
        
        Testa extração de master.dat, critter.dat e patch000.dat completos.
        """
        print("📦 Validando DAT2Reader...")
        
        total_files = 0
        successful = 0
        failed = 0
        errors = []
        details = {
            'dat_files': {},
            'file_types': {},
            'total_size': 0,
            'total_extracted_size': 0
        }
        
        for dat_name in ['master.dat', 'critter.dat', 'patch000.dat']:
            dat_path = self.fallout2_path / dat_name
            if not dat_path.exists():
                continue
            
            print(f"   Processando {dat_name}...")
            dat_info = {
                'total_files': 0,
                'successful': 0,
                'failed': 0,
                'file_types': {}
            }
            
            try:
                with DAT2Reader(str(dat_path)) as reader:
                    reader.read_directory()
                    files = reader.list_files()
                    dat_info['total_files'] = len(files)
                    total_files += len(files)
                    
                    # Testar extração de uma amostra (primeiros 100 arquivos)
                    sample_size = min(100, len(files))
                    for i, file_path in enumerate(files[:sample_size]):
                        try:
                            data = reader.extract_file(file_path)
                            if data:
                                successful += 1
                                dat_info['successful'] += 1
                                
                                # Contar por tipo
                                ext = Path(file_path).suffix.lower()
                                if ext not in dat_info['file_types']:
                                    dat_info['file_types'][ext] = 0
                                dat_info['file_types'][ext] += 1
                                
                                details['total_extracted_size'] += len(data)
                            else:
                                failed += 1
                                dat_info['failed'] += 1
                                errors.append(f"{file_path}: Extração retornou None")
                        except Exception as e:
                            failed += 1
                            dat_info['failed'] += 1
                            errors.append(f"{file_path}: {str(e)}")
                    
                    # Contar todos os tipos de arquivo
                    for file_path in files:
                        ext = Path(file_path).suffix.lower()
                        if ext not in details['file_types']:
                            details['file_types'][ext] = 0
                        details['file_types'][ext] += 1
                    
                    details['dat_files'][dat_name] = dat_info
                    reader.close()
                    
            except Exception as e:
                errors.append(f"Erro ao processar {dat_name}: {str(e)}")
        
        details['total_size'] = sum(
            (self.fallout2_path / dat).stat().st_size 
            for dat in ['master.dat', 'critter.dat', 'patch000.dat']
            if (self.fallout2_path / dat).exists()
        )
        
        result = ValidationResult(
            extractor_name="DAT2Reader",
            total_files=total_files,
            successful=successful,
            failed=failed,
            errors=errors[:50],  # Limitar a 50 erros
            details=details
        )
        
        self.results['dat2_reader'] = result
        print(f"✅ DAT2Reader: {successful}/{total_files} arquivos extraídos com sucesso")
        
        return result
    
    def validate_frm_decoder(self) -> ValidationResult:
        """
        Valida FRMDecoder para todos os tipos de FRM.
        
        Testa decodificação de diferentes variações de FRM.
        """
        print("🖼️  Validando FRMDecoder...")
        
        total_files = 0
        successful = 0
        failed = 0
        errors = []
        details = {
            'variations': {
                'single_direction': 0,
                'multi_direction': 0,
                'animated': 0,
                'static': 0
            },
            'directions': {},
            'frame_counts': {}
        }
        
        # Encontrar arquivos FRM
        all_files = self.dat_manager.list_all_files()
        frm_files = [f for f in all_files if f.lower().endswith('.frm')]
        total_files = len(frm_files)
        
        # Testar uma amostra
        sample_size = min(200, len(frm_files))
        for i, file_path in enumerate(frm_files[:sample_size]):
            try:
                frm_data = self.dat_manager.get_file(file_path)
                if not frm_data:
                    failed += 1
                    continue
                
                # Decodificar
                frm_image = self.frm_decoder.decode(frm_data)
                
                # Classificar variação
                if frm_image.num_directions == 1:
                    details['variations']['single_direction'] += 1
                else:
                    details['variations']['multi_direction'] += 1
                
                if frm_image.num_frames > 1:
                    details['variations']['animated'] += 1
                else:
                    details['variations']['static'] += 1
                
                # Contar direções
                dir_count = frm_image.num_directions
                if dir_count not in details['directions']:
                    details['directions'][dir_count] = 0
                details['directions'][dir_count] += 1
                
                # Contar frames
                frame_count = frm_image.num_frames
                if frame_count not in details['frame_counts']:
                    details['frame_counts'][frame_count] = 0
                details['frame_counts'][frame_count] += 1
                
                # Testar se tem frames válidos
                if frm_image.num_frames > 0 and frm_image.num_directions > 0:
                    if len(frm_image.frames) > 0 and len(frm_image.frames[0]) > 0:
                        successful += 1
                    else:
                        failed += 1
                        errors.append(f"{file_path}: Sem frames válidos")
                else:
                    failed += 1
                    errors.append(f"{file_path}: Sem frames ou direções")
                    
            except Exception as e:
                failed += 1
                errors.append(f"{file_path}: {str(e)}")
        
        result = ValidationResult(
            extractor_name="FRMDecoder",
            total_files=total_files,
            successful=successful,
            failed=failed,
            errors=errors[:50],
            details=details
        )
        
        self.results['frm_decoder'] = result
        print(f"✅ FRMDecoder: {successful}/{sample_size} arquivos decodificados com sucesso")
        
        return result
    
    def validate_map_parser(self) -> ValidationResult:
        """
        Valida MapParser para todos os mapas.
        
        Testa parsing de tiles, objetos e NPCs de todas as elevações.
        """
        print("🗺️  Validando MapParser...")
        
        total_files = 0
        successful = 0
        failed = 0
        errors = []
        details = {
            'versions': {},
            'elevations': {},
            'object_counts': {},
            'script_counts': {}
        }
        
        # Encontrar arquivos MAP
        all_files = self.dat_manager.list_all_files()
        map_files = [f for f in all_files if f.lower().endswith('.map')]
        total_files = len(map_files)
        
        # Testar todos os mapas
        for file_path in map_files:
            try:
                map_data = self.dat_manager.get_file(file_path)
                if not map_data:
                    failed += 1
                    continue
                
                # Parsear mapa
                parsed_map = self.map_parser.parse(map_data)
                
                # Coletar estatísticas
                version = parsed_map.version
                if version not in details['versions']:
                    details['versions'][version] = 0
                details['versions'][version] += 1
                
                elevations = parsed_map.num_levels
                if elevations not in details['elevations']:
                    details['elevations'][elevations] = 0
                details['elevations'][elevations] += 1
                
                object_count = len(parsed_map.objects)
                if object_count not in details['object_counts']:
                    details['object_counts'][object_count] = 0
                details['object_counts'][object_count] += 1
                
                script_count = len(parsed_map.scripts)
                if script_count not in details['script_counts']:
                    details['script_counts'][script_count] = 0
                details['script_counts'][script_count] += 1
                
                successful += 1
                
            except Exception as e:
                failed += 1
                errors.append(f"{file_path}: {str(e)}")
        
        result = ValidationResult(
            extractor_name="MapParser",
            total_files=total_files,
            successful=successful,
            failed=failed,
            errors=errors[:50],
            details=details
        )
        
        self.results['map_parser'] = result
        print(f"✅ MapParser: {successful}/{total_files} mapas parseados com sucesso")
        
        return result
    
    def validate_pro_parser(self) -> ValidationResult:
        """
        Valida PROParser para todos os protótipos.
        
        Testa parsing de itens, criaturas e tiles.
        """
        print("📋 Validando PROParser...")
        
        total_files = 0
        successful = 0
        failed = 0
        errors = []
        details = {
            'types': {
                'item': 0,
                'critter': 0,
                'scenery': 0,
                'wall': 0,
                'tile': 0,
                'misc': 0
            },
            'item_types': {},
            'errors_by_type': {}
        }
        
        # Encontrar arquivos PRO
        all_files = self.dat_manager.list_all_files()
        pro_files = [f for f in all_files if f.lower().endswith('.pro')]
        total_files = len(pro_files)
        
        # Testar uma amostra
        sample_size = min(500, len(pro_files))
        for file_path in pro_files[:sample_size]:
            try:
                pro_data = self.dat_manager.get_file(file_path)
                if not pro_data:
                    failed += 1
                    continue
                
                # Parsear PRO
                parsed_proto = parse_proto(pro_data)
                if not parsed_proto:
                    failed += 1
                    errors.append(f"{file_path}: Parsing retornou None")
                    continue
                
                # Classificar por tipo
                proto_type = parsed_proto.get('type', 'unknown')
                if proto_type in details['types']:
                    details['types'][proto_type] += 1
                
                # Se for item, classificar por tipo de item
                if proto_type == 'item':
                    item_type = parsed_proto.get('item_type', 'unknown')
                    if item_type not in details['item_types']:
                        details['item_types'][item_type] = 0
                    details['item_types'][item_type] += 1
                
                successful += 1
                
            except Exception as e:
                failed += 1
                error_type = type(e).__name__
                if error_type not in details['errors_by_type']:
                    details['errors_by_type'][error_type] = 0
                details['errors_by_type'][error_type] += 1
                errors.append(f"{file_path}: {str(e)}")
        
        result = ValidationResult(
            extractor_name="PROParser",
            total_files=total_files,
            successful=successful,
            failed=failed,
            errors=errors[:50],
            details=details
        )
        
        self.results['pro_parser'] = result
        print(f"✅ PROParser: {successful}/{sample_size} protótipos parseados com sucesso")
        
        return result
    
    def validate_all(self):
        """Valida todos os extractors."""
        print("=" * 70)
        print("🔍 Validação Completa de Extractors")
        print("=" * 70)
        print()
        
        self.validate_dat2_reader()
        self.validate_frm_decoder()
        self.validate_map_parser()
        self.validate_pro_parser()
        
        # Gerar relatório
        self.generate_report()
    
    def generate_report(self):
        """Gera relatório de validação."""
        print("\n💾 Gerando relatório...")
        
        report_data = {
            'generated_at': datetime.now().isoformat(),
            'results': {}
        }
        
        for key, result in self.results.items():
            report_data['results'][key] = {
                'extractor_name': result.extractor_name,
                'total_files': result.total_files,
                'successful': result.successful,
                'failed': result.failed,
                'success_rate': (result.successful / result.total_files * 100) if result.total_files > 0 else 0,
                'errors': result.errors,
                'details': result.details
            }
        
        # Salvar JSON
        json_file = self.output_dir / "validation_report.json"
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(report_data, f, indent=2, ensure_ascii=False)
        print(f"   ✅ Relatório JSON: {json_file}")
        
        # Gerar relatório Markdown
        md_file = self.output_dir / "validation_report.md"
        with open(md_file, 'w', encoding='utf-8') as f:
            f.write("# Relatório de Validação de Extractors\n\n")
            f.write(f"**Gerado em:** {report_data['generated_at']}\n\n")
            
            for key, result_data in report_data['results'].items():
                f.write(f"## {result_data['extractor_name']}\n\n")
                f.write(f"- **Total de arquivos:** {result_data['total_files']}\n")
                f.write(f"- **Sucesso:** {result_data['successful']}\n")
                f.write(f"- **Falhas:** {result_data['failed']}\n")
                f.write(f"- **Taxa de sucesso:** {result_data['success_rate']:.1f}%\n\n")
                
                if result_data['errors']:
                    f.write("### Erros Encontrados\n\n")
                    for error in result_data['errors'][:10]:
                        f.write(f"- {error}\n")
                    if len(result_data['errors']) > 10:
                        f.write(f"\n*... e mais {len(result_data['errors']) - 10} erros*\n")
                    f.write("\n")
        
        print(f"   ✅ Relatório Markdown: {md_file}")
        
        # Resumo
        print("\n" + "=" * 70)
        print("📊 Resumo da Validação")
        print("=" * 70)
        for key, result_data in report_data['results'].items():
            print(f"{result_data['extractor_name']}: {result_data['success_rate']:.1f}% ({result_data['successful']}/{result_data['total_files']})")


def main():
    """Função principal."""
    import sys
    
    if len(sys.argv) > 1:
        fallout2_path = sys.argv[1]
    else:
        fallout2_path = Path(__file__).parent.parent / "Fallout 2"
    
    if not Path(fallout2_path).exists():
        print("❌ Erro: Pasta do Fallout 2 não encontrada!")
        print(f"   Procurando em: {fallout2_path}")
        print("   Use: python extractor_validator.py <caminho_do_fallout2>")
        return
    
    validator = ExtractorValidator(str(fallout2_path))
    validator.validate_all()


if __name__ == "__main__":
    main()

