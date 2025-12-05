#!/usr/bin/env python3
"""
Sistema Completo de Extração com Tracking de Arquivos Processados

Este script extrai TODO o conteúdo do Fallout 2 e, à medida que processa cada arquivo,
move os arquivos originais para uma pasta "processed" para marcar como processados.

Funcionalidades:
- Extrai todos os arquivos dos DATs (master.dat, critter.dat, patch000.dat)
- Processa cada arquivo conforme seu tipo (FRM, MAP, PRO, MSG, ACM, etc)
- Move arquivos processados para pasta separada
- Mantém log de progresso
- Permite retomar de onde parou
- Gera relatório completo

Uso:
    python extract_complete_with_tracking.py --fallout2-path "Fallout 2" --output-path "godot_project/assets"
"""

import os
import sys
import json
import shutil
import hashlib
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Set, Optional
from dataclasses import dataclass, asdict
import argparse

# Adicionar diretório de extractors ao path
sys.path.insert(0, str(Path(__file__).parent))

from extractors.dat2_reader import DAT2Reader, DAT2Manager
from extractors.frm_decoder import FRMDecoder
from extractors.map_parser import MAPParser
from extractors.pro_parser import parse_proto
from extractors.msg_parser import MSGParser
from extractors.acm_decoder import ACMDecoder
from extractors.palette_loader import PaletteLoader
from extractors.asset_organizer import AssetOrganizer
from extractors.tile_extractor import TileExtractor


@dataclass
class ProcessedFile:
    """Informações sobre um arquivo processado."""
    original_path: str
    processed_path: str
    file_type: str
    status: str  # 'success', 'failed', 'skipped'
    timestamp: str
    error_message: Optional[str] = None


@dataclass
class ExtractionProgress:
    """Progresso da extração."""
    total_files: int
    processed_files: int
    successful_files: int
    failed_files: int
    skipped_files: int
    processed_file_list: List[ProcessedFile]
    start_time: str
    last_update: str


class CompleteExtractor:
    """
    Extrator completo com tracking de arquivos processados.
    
    Extrai todos os arquivos dos DATs, processa cada um conforme seu tipo,
    e move arquivos processados para pasta separada.
    """
    
    def __init__(self, fallout2_path: str, output_path: str, processed_path: Optional[str] = None):
        """
        Inicializa o extrator completo.
        
        Args:
            fallout2_path: Caminho para instalação do Fallout 2
            output_path: Caminho de saída para assets extraídos
            processed_path: Caminho para mover arquivos processados (padrão: fallout2_path/processed)
        """
        self.fallout2_path = Path(fallout2_path)
        self.output_path = Path(output_path)
        self.processed_path = Path(processed_path) if processed_path else self.fallout2_path / "processed"
        
        # Criar diretórios necessários
        self.output_path.mkdir(parents=True, exist_ok=True)
        self.processed_path.mkdir(parents=True, exist_ok=True)
        
        # Arquivo de progresso
        self.progress_file = self.output_path / "extraction_progress.json"
        self.progress: ExtractionProgress = self._load_progress()
        
        # Inicializar componentes
        self._init_components()
        
        # Tipos de arquivo e seus processadores
        self.file_processors = {
            '.frm': self._process_frm,
            '.map': self._process_map,
            '.pro': self._process_pro,
            '.msg': self._process_msg,
            '.acm': self._process_acm,
            '.pal': self._process_palette,
            '.txt': self._process_text,
            '.int': self._process_script,
            '.ssl': self._process_script,
        }
        
    def _init_components(self):
        """Inicializa componentes de extração."""
        # DAT2 Manager
        dat_files = []
        for dat_name in ['master.dat', 'critter.dat', 'patch000.dat']:
            dat_path = self.fallout2_path / dat_name
            if dat_path.exists():
                dat_files.append(str(dat_path))
        
        if not dat_files:
            raise FileNotFoundError("Nenhum arquivo DAT encontrado!")
        
        self.dat_manager = DAT2Manager(dat_files)
        
        # Palette Loader
        palette_path = self.fallout2_path / 'color.pal'
        if palette_path.exists():
            self.palette_loader = PaletteLoader(str(palette_path))
        else:
            # Tentar extrair palette dos DATs
            palette_data = self.dat_manager.get_file('color.pal')
            if palette_data:
                # Salvar temporariamente e carregar
                import tempfile
                with tempfile.NamedTemporaryFile(suffix='.pal', delete=False) as tmp:
                    tmp.write(palette_data)
                    tmp_path = tmp.name
                self.palette_loader = PaletteLoader(tmp_path)
            else:
                # Usar palette padrão
                self.palette_loader = PaletteLoader()
        
        # Asset Organizer
        self.organizer = AssetOrganizer(str(self.output_path))
        
        # Decoders
        self.frm_decoder = FRMDecoder(self.palette_loader)
        self.map_parser = MAPParser()
        self.msg_parser = MSGParser()
        self.acm_decoder = ACMDecoder()
        self.tile_extractor = TileExtractor(self.dat_manager, self.palette_loader, str(self.output_path))
        
    def _load_progress(self) -> ExtractionProgress:
        """Carrega progresso anterior ou cria novo."""
        if self.progress_file.exists():
            try:
                with open(self.progress_file, 'r', encoding='utf-8') as f:
                    data = json.load(f)
                    return ExtractionProgress(**data)
            except Exception as e:
                print(f"Erro ao carregar progresso: {e}. Criando novo progresso.")
        
        return ExtractionProgress(
            total_files=0,
            processed_files=0,
            successful_files=0,
            failed_files=0,
            skipped_files=0,
            processed_file_list=[],
            start_time=datetime.now().isoformat(),
            last_update=datetime.now().isoformat()
        )
    
    def _save_progress(self):
        """Salva progresso atual."""
        self.progress.last_update = datetime.now().isoformat()
        with open(self.progress_file, 'w', encoding='utf-8') as f:
            json.dump(asdict(self.progress), f, indent=2, ensure_ascii=False)
    
    def _is_processed(self, file_path: str) -> bool:
        """Verifica se arquivo já foi processado."""
        for pf in self.progress.processed_file_list:
            if pf.original_path == file_path:
                return True
        return False
    
    def _mark_as_processed(self, relative_path: str):
        """
        Marca arquivo como processado criando um arquivo marcador.
        
        Como arquivos dentro de DATs não podem ser movidos diretamente,
        criamos um arquivo marcador na pasta processed para indicar que
        o arquivo foi processado.
        
        Args:
            relative_path: Caminho relativo dentro do DAT
        """
        try:
            # Criar estrutura de diretórios na pasta processed
            processed_file_path = self.processed_path / relative_path
            processed_file_path.parent.mkdir(parents=True, exist_ok=True)
            
            # Criar arquivo marcador
            marker_file = processed_file_path.with_suffix(processed_file_path.suffix + '.processed')
            
            # Se já existe, não criar novamente
            if marker_file.exists():
                return
            
            # Criar marcador com informações
            marker_content = {
                'original_path': relative_path,
                'processed_date': datetime.now().isoformat(),
                'status': 'processed'
            }
            
            marker_file.write_text(json.dumps(marker_content, indent=2), encoding='utf-8')
        except Exception as e:
            print(f"  ⚠️  Erro ao marcar arquivo como processado: {e}")
    
    def extract_all(self) -> ExtractionProgress:
        """
        Extrai todos os arquivos dos DATs.
        
        Returns:
            Progresso final da extração
        """
        print("=" * 80)
        print("EXTRAÇÃO COMPLETA DO FALLOUT 2")
        print("=" * 80)
        print(f"Pasta do jogo: {self.fallout2_path}")
        print(f"Pasta de saída: {self.output_path}")
        print(f"Pasta de processados: {self.processed_path}")
        print()
        
        # Listar todos os arquivos dos DATs
        print("Listando arquivos dos DATs...")
        all_files = self.dat_manager.list_all_files()
        self.progress.total_files = len(all_files)
        print(f"Total de arquivos encontrados: {len(all_files)}")
        print()
        
            # Processar cada arquivo
        for idx, file_path in enumerate(all_files, 1):
            # Verificar se já foi processado
            if self._is_processed(file_path):
                if idx % 100 == 0:  # Mostrar progresso a cada 100 arquivos pulados
                    print(f"[{idx}/{len(all_files)}] ⏭️  Pulando arquivos já processados...")
                self.progress.skipped_files += 1
                continue
            
            # Mostrar progresso apenas a cada 10 arquivos ou em arquivos importantes
            show_progress = (idx % 10 == 0) or file_path.endswith(('.map', '.frm', '.pro'))
            if show_progress:
                print(f"[{idx}/{len(all_files)}] 🔄 Processando: {file_path}")
            
            # Processar arquivo
            try:
                success = self._process_file(file_path)
            except Exception as e:
                print(f"  ❌ Erro inesperado: {e}")
                success = False
            
            if success:
                # Marcar como processado
                processed_file = ProcessedFile(
                    original_path=file_path,
                    processed_path=str(self.processed_path / file_path),
                    file_type=Path(file_path).suffix.lower(),
                    status='success',
                    timestamp=datetime.now().isoformat()
                )
                self.progress.processed_file_list.append(processed_file)
                self.progress.successful_files += 1
                
                # Criar marcador de processado
                self._mark_as_processed(file_path)
                
                if show_progress:
                    print(f"  ✅ Sucesso!")
            else:
                processed_file = ProcessedFile(
                    original_path=file_path,
                    processed_path=str(self.processed_path / file_path),
                    file_type=Path(file_path).suffix.lower(),
                    status='failed',
                    timestamp=datetime.now().isoformat(),
                    error_message="Falha no processamento"
                )
                self.progress.processed_file_list.append(processed_file)
                self.progress.failed_files += 1
                if show_progress:
                    print(f"  ❌ Falha!")
            
            self.progress.processed_files += 1
            
            # Salvar progresso a cada 10 arquivos
            if idx % 10 == 0:
                self._save_progress()
                if idx % 100 == 0:
                    self._print_progress()
        
        # Salvar progresso final
        self._save_progress()
        
        # Gerar relatório final
        self._generate_final_report()
        
        return self.progress
    
    def _process_file(self, file_path: str) -> bool:
        """
        Processa um arquivo conforme seu tipo.
        
        Args:
            file_path: Caminho do arquivo dentro do DAT
            
        Returns:
            True se processado com sucesso, False caso contrário
        """
        file_ext = Path(file_path).suffix.lower()
        
        # Obter dados do arquivo
        try:
            file_data = self.dat_manager.get_file(file_path)
            if not file_data:
                print(f"  ⚠️  Arquivo não encontrado no DAT")
                return False
        except Exception as e:
            print(f"  ⚠️  Erro ao ler arquivo: {e}")
            # Tentar salvar como arquivo bruto mesmo assim
            return self._save_raw_file(file_path, file_data if 'file_data' in locals() else None)
        
        # Processar conforme tipo
        processor = self.file_processors.get(file_ext, self._process_generic)
        
        try:
            success = processor(file_path, file_data)
            if success:
                return True
            else:
                # Se falhou, tentar salvar como arquivo bruto
                print(f"  ⚠️  Processamento falhou, salvando como arquivo bruto...")
                return self._save_raw_file(file_path, file_data)
        except Exception as e:
            print(f"  ⚠️  Erro ao processar: {e}")
            # Tentar salvar como arquivo bruto como fallback
            try:
                return self._save_raw_file(file_path, file_data)
            except:
                return False
    
    def _process_frm(self, file_path: str, file_data: bytes) -> bool:
        """Processa arquivo FRM (sprite)."""
        try:
            # Verificar tamanho mínimo
            if len(file_data) < 62:
                print(f"  ⚠️  Arquivo FRM muito pequeno ({len(file_data)} bytes)")
                return False
            
            # Decodificar FRM
            frm_image = self.frm_decoder.decode(file_data)
            if not frm_image or not frm_image.frames:
                print(f"  ⚠️  Nenhum frame encontrado no FRM")
                return False
            
            # Salvar frames como PNG
            output_dir = self.output_path / "sprites" / Path(file_path).stem
            output_dir.mkdir(parents=True, exist_ok=True)
            
            frame_count = 0
            for direction_idx, direction_frames in enumerate(frm_image.frames):
                if not direction_frames:
                    continue
                    
                for frame_idx, frame_data in enumerate(direction_frames):
                    try:
                        # Criar imagem PIL
                        img = Image.new('RGBA', (frame_data.width, frame_data.height), (0, 0, 0, 0))
                        pixels = img.load()
                        
                        # Converter pixels usando paleta
                        pixel_data = frame_data.pixels
                        pixel_idx = 0
                        for y in range(frame_data.height):
                            for x in range(frame_data.width):
                                if pixel_idx < len(pixel_data):
                                    palette_idx = pixel_data[pixel_idx]
                                    pixel_idx += 1
                                    
                                    # Índice 0 = transparente
                                    if palette_idx == 0:
                                        pixels[x, y] = (0, 0, 0, 0)
                                    else:
                                        r, g, b = self.palette_loader.get_color(palette_idx)
                                        pixels[x, y] = (r, g, b, 255)
                                else:
                                    pixels[x, y] = (0, 0, 0, 0)
                        
                        # Salvar frame
                        output_file = output_dir / f"dir_{direction_idx:02d}_frame_{frame_idx:03d}.png"
                        img.save(str(output_file), 'PNG')
                        frame_count += 1
                    except Exception as e:
                        if frame_count == 0:  # Só mostrar erro no primeiro frame
                            print(f"  ⚠️  Erro ao salvar frame {direction_idx}/{frame_idx}: {e}")
                        continue
            
            if frame_count == 0:
                print(f"  ⚠️  Nenhum frame foi salvo")
                return False
            
            # Organizar asset
            try:
                self.organizer.add_asset('sprite', str(output_dir), {
                    'source': file_path,
                    'frames': frame_count,
                    'directions': len(frm_image.frames)
                })
            except:
                pass  # Não crítico se organizador falhar
            
            return True
        except ValueError as e:
            print(f"  ⚠️  Erro de validação FRM: {e}")
            return False
        except Exception as e:
            print(f"  ⚠️  Erro ao processar FRM: {e}")
            import traceback
            if len(str(e)) < 100:  # Só mostrar traceback para erros curtos
                traceback.print_exc()
            return False
    
    def _process_map(self, file_path: str, file_data: bytes) -> bool:
        """Processa arquivo MAP (mapa)."""
        try:
            # Verificar tamanho mínimo
            if len(file_data) < 100:
                print(f"  ⚠️  Arquivo MAP muito pequeno ({len(file_data)} bytes)")
                return False
            
            # Parsear mapa
            map_data = self.map_parser.parse(file_data)
            if not map_data:
                print(f"  ⚠️  Falha ao parsear MAP")
                return False
            
            # Salvar como JSON
            output_file = self.output_path / "maps" / Path(file_path).with_suffix('.json')
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Converter MapData para dict se necessário
            from dataclasses import asdict
            try:
                if hasattr(map_data, '__dataclass_fields__'):
                    map_dict = asdict(map_data)
                elif hasattr(map_data, '__dict__'):
                    map_dict = map_data.__dict__
                else:
                    map_dict = map_data
            except Exception as e:
                print(f"  ⚠️  Erro ao converter MapData: {e}")
                return False
            
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(map_dict, f, indent=2, ensure_ascii=False, default=str)
            
            # Organizar asset (não crítico se falhar)
            try:
                self.organizer.add_asset('map', str(output_file), {
                    'source': file_path
                })
            except:
                pass
            
            return True
        except Exception as e:
            print(f"  ⚠️  Erro ao processar MAP: {e}")
            return False
    
    def _process_pro(self, file_path: str, file_data: bytes) -> bool:
        """Processa arquivo PRO (protótipo)."""
        try:
            # Parsear protótipo
            proto_data = parse_proto(file_data)
            if not proto_data:
                return False
            
            # Salvar como JSON
            output_file = self.output_path / "prototypes" / Path(file_path).with_suffix('.json')
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(proto_data, f, indent=2, ensure_ascii=False)
            
            # Organizar asset
            self.organizer.add_asset('prototype', str(output_file), {
                'source': file_path
            })
            
            return True
        except Exception as e:
            print(f"  ⚠️  Erro ao processar PRO: {e}")
            return False
    
    def _process_msg(self, file_path: str, file_data: bytes) -> bool:
        """Processa arquivo MSG (mensagem/diálogo)."""
        try:
            # Parsear mensagem
            msg_data = self.msg_parser.parse(file_data)
            if not msg_data:
                return False
            
            # Salvar como JSON
            output_file = self.output_path / "texts" / Path(file_path).with_suffix('.json')
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(msg_data, f, indent=2, ensure_ascii=False)
            
            # Organizar asset
            self.organizer.add_asset('text', str(output_file), {
                'source': file_path
            })
            
            return True
        except Exception as e:
            print(f"  ⚠️  Erro ao processar MSG: {e}")
            return False
    
    def _process_acm(self, file_path: str, file_data: bytes) -> bool:
        """Processa arquivo ACM (áudio)."""
        try:
            # Preparar caminho de saída
            output_file = self.output_path / "audio" / Path(file_path).with_suffix('.wav')
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Decodificar ACM diretamente para WAV
            success = self.acm_decoder.decode_to_wav(file_data, str(output_file))
            if not success:
                # Se falhar, salvar ACM original como fallback
                output_file = self.output_path / "audio" / Path(file_path).name
                with open(output_file, 'wb') as f:
                    f.write(file_data)
                print(f"  ⚠️  Decodificação ACM falhou, salvando arquivo original")
            
            # Organizar asset
            self.organizer.add_asset('audio', str(output_file), {
                'source': file_path
            })
            
            return True
        except Exception as e:
            print(f"  ⚠️  Erro ao processar ACM: {e}")
            return False
    
    def _process_palette(self, file_path: str, file_data: bytes) -> bool:
        """Processa arquivo PAL (paleta de cores)."""
        try:
            # Salvar paleta
            output_file = self.output_path / "palettes" / Path(file_path).name
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_file, 'wb') as f:
                f.write(file_data)
            
            # Organizar asset
            self.organizer.add_asset('palette', str(output_file), {
                'source': file_path
            })
            
            return True
        except Exception as e:
            print(f"  ⚠️  Erro ao processar PAL: {e}")
            return False
    
    def _process_text(self, file_path: str, file_data: bytes) -> bool:
        """Processa arquivo de texto genérico."""
        try:
            # Salvar texto
            output_file = self.output_path / "texts" / Path(file_path).name
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Tentar decodificar como UTF-8, fallback para latin-1
            try:
                text = file_data.decode('utf-8')
            except:
                text = file_data.decode('latin-1', errors='ignore')
            
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(text)
            
            return True
        except Exception as e:
            print(f"  ⚠️  Erro ao processar texto: {e}")
            return False
    
    def _process_script(self, file_path: str, file_data: bytes) -> bool:
        """Processa arquivo de script (.INT, .SSL)."""
        try:
            # Salvar script
            output_file = self.output_path / "scripts" / Path(file_path).name
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_file, 'wb') as f:
                f.write(file_data)
            
            # Organizar asset
            self.organizer.add_asset('script', str(output_file), {
                'source': file_path
            })
            
            return True
        except Exception as e:
            print(f"  ⚠️  Erro ao processar script: {e}")
            return False
    
    def _process_generic(self, file_path: str, file_data: bytes) -> bool:
        """Processa arquivo genérico (salva como está)."""
        return self._save_raw_file(file_path, file_data)
    
    def _save_raw_file(self, file_path: str, file_data: Optional[bytes]) -> bool:
        """
        Salva arquivo bruto como fallback quando processamento falha.
        
        Args:
            file_path: Caminho do arquivo
            file_data: Dados do arquivo (pode ser None)
            
        Returns:
            True se salvo com sucesso
        """
        if file_data is None:
            return False
            
        try:
            # Salvar arquivo bruto na pasta misc/raw
            output_file = self.output_path / "misc" / "raw" / Path(file_path).name
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_file, 'wb') as f:
                f.write(file_data)
            
            return True
        except Exception as e:
            print(f"  ❌ Erro ao salvar arquivo bruto: {e}")
            return False
    
    def _print_progress(self):
        """Imprime progresso atual."""
        total = self.progress.total_files
        processed = self.progress.processed_files
        success = self.progress.successful_files
        failed = self.progress.failed_files
        skipped = self.progress.skipped_files
        
        if total > 0:
            percent = (processed / total) * 100
            print(f"\n📊 Progresso: {processed}/{total} ({percent:.1f}%) | ✅ {success} | ❌ {failed} | ⏭️  {skipped}\n")
    
    def _generate_final_report(self):
        """Gera relatório final da extração."""
        report_file = self.output_path / "extraction_report.json"
        
        report = {
            'extraction_date': datetime.now().isoformat(),
            'fallout2_path': str(self.fallout2_path),
            'output_path': str(self.output_path),
            'processed_path': str(self.processed_path),
            'statistics': {
                'total_files': self.progress.total_files,
                'processed_files': self.progress.processed_files,
                'successful_files': self.progress.successful_files,
                'failed_files': self.progress.failed_files,
                'skipped_files': self.progress.skipped_files,
                'success_rate': (self.progress.successful_files / self.progress.processed_files * 100) if self.progress.processed_files > 0 else 0
            },
            'file_types': self._count_file_types(),
            'errors': [asdict(pf) for pf in self.progress.processed_file_list if pf.status == 'failed']
        }
        
        with open(report_file, 'w', encoding='utf-8') as f:
            json.dump(report, f, indent=2, ensure_ascii=False)
        
        print("\n" + "=" * 80)
        print("RELATÓRIO FINAL")
        print("=" * 80)
        print(f"Total de arquivos: {report['statistics']['total_files']}")
        print(f"Processados: {report['statistics']['processed_files']}")
        print(f"Sucesso: {report['statistics']['successful_files']}")
        print(f"Falhas: {report['statistics']['failed_files']}")
        print(f"Pulados: {report['statistics']['skipped_files']}")
        print(f"Taxa de sucesso: {report['statistics']['success_rate']:.1f}%")
        print(f"\nRelatório salvo em: {report_file}")
        print("=" * 80)
    
    def _count_file_types(self) -> Dict[str, int]:
        """Conta arquivos por tipo."""
        types = {}
        for pf in self.progress.processed_file_list:
            file_type = pf.file_type or 'unknown'
            types[file_type] = types.get(file_type, 0) + 1
        return types


def main():
    """Função principal."""
    parser = argparse.ArgumentParser(
        description='Extrai TODO o conteúdo do Fallout 2 com tracking de arquivos processados',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Exemplos:
  # Extração completa
  python extract_complete_with_tracking.py --fallout2-path "Fallout 2" --output-path "godot_project/assets"
  
  # Especificar pasta de processados
  python extract_complete_with_tracking.py --fallout2-path "Fallout 2" --output-path "godot_project/assets" --processed-path "Fallout 2/processed"
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
        help='Caminho de saída para assets extraídos'
    )
    
    parser.add_argument(
        '--processed-path',
        type=str,
        default=None,
        help='Caminho para mover arquivos processados (padrão: fallout2_path/processed)'
    )
    
    parser.add_argument(
        '--resume',
        action='store_true',
        help='Retomar extração de onde parou'
    )
    
    args = parser.parse_args()
    
    # Validar caminhos
    fallout2_path = Path(args.fallout2_path)
    if not fallout2_path.exists():
        print(f"❌ Erro: Caminho do Fallout 2 não encontrado: {fallout2_path}")
        return 1
    
    output_path = Path(args.output_path)
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Verificar arquivos DAT
    required_dats = ['master.dat', 'critter.dat']
    missing_dats = []
    for dat_name in required_dats:
        if not (fallout2_path / dat_name).exists():
            missing_dats.append(dat_name)
    
    if missing_dats:
        print(f"⚠️  Aviso: Arquivos DAT não encontrados: {', '.join(missing_dats)}")
        print("A extração pode ser incompleta.")
    
    # Criar extrator
    try:
        extractor = CompleteExtractor(
            str(fallout2_path),
            str(output_path),
            args.processed_path
        )
        
        # Executar extração
        progress = extractor.extract_all()

        # Extrair tiles específicos
        print("\n" + "=" * 80)
        print("EXTRAÇÃO DE TILES")
        print("=" * 80)
        try:
            tiles_extracted = extractor.tile_extractor.extract_all_tiles()
            print(f"✅ {tiles_extracted} tiles extraídos")
        except Exception as e:
            print(f"❌ Erro na extração de tiles: {e}")

        return 0
        
    except KeyboardInterrupt:
        print("\n\n⚠️  Extração cancelada pelo usuário.")
        print("Progresso salvo. Execute novamente para retomar.")
        return 1
    except Exception as e:
        print(f"\n❌ Erro fatal durante extração: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())

