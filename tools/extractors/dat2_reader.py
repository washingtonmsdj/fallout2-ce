"""
Módulo para leitura e extração de arquivos DAT2 do Fallout 2.

Este módulo implementa o DAT2Reader que lê o índice de arquivos e extrai
conteúdo dos containers DAT2 (master.dat, critter.dat, patch000.dat).
"""
import struct
import zlib
from pathlib import Path
from typing import List, Optional, Dict
from dataclasses import dataclass


@dataclass
class FileInfo:
    """Informações sobre um arquivo dentro do DAT2."""
    name: str
    path: str
    size: int
    compressed_size: int
    is_compressed: bool
    offset: int


class DAT2Reader:
    """
    Leitor de arquivos DAT2 do Fallout 2.
    
    O formato DAT2 consiste em:
    - Dados dos arquivos (no início)
    - Tabela de entradas (no final)
    - Footer com tamanhos (últimos 8 bytes)
    """
    
    def __init__(self, dat_path: str):
        """
        Inicializa o leitor DAT2.
        
        Args:
            dat_path: Caminho para o arquivo DAT2
        """
        self.dat_path = Path(dat_path)
        self.stream = None
        self.entries: List[FileInfo] = []
        self.data_offset = 0
        
    def __enter__(self):
        """Context manager entry."""
        self.open()
        return self
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.close()
        return False
        
    def open(self):
        """
        Abre o arquivo DAT2 para leitura.
        
        Raises:
            FileNotFoundError: Se o arquivo não existir
        """
        if not self.dat_path.exists():
            raise FileNotFoundError(f"Arquivo DAT2 não encontrado: {self.dat_path}")
        
        self.stream = open(self.dat_path, 'rb')
        return True
        
    def close(self):
        """Fecha o arquivo DAT2."""
        if self.stream:
            self.stream.close()
            self.stream = None
            
    def _read_header(self) -> tuple[int, int]:
        """
        Lê o header do DAT2 (footer no final do arquivo).
        
        Returns:
            Tupla (entries_data_size, dbase_data_size)
        """
        if not self.stream:
            raise RuntimeError("Arquivo não aberto")
            
        # Ir para o final do arquivo para ler o footer
        self.stream.seek(0, 2)  # SEEK_END
        file_size = self.stream.tell()
        
        # Ler footer: entriesDataSize (4 bytes) + dbaseDataSize (4 bytes)
        self.stream.seek(file_size - 8, 0)
        entries_data_size = struct.unpack('<I', self.stream.read(4))[0]
        dbase_data_size = struct.unpack('<I', self.stream.read(4))[0]
        
        return entries_data_size, dbase_data_size
        
    def _read_directory(self, entries_data_size: int, dbase_data_size: int):
        """
        Lê o diretório de arquivos do DAT2.
        
        Args:
            entries_data_size: Tamanho da tabela de entradas
            dbase_data_size: Tamanho dos dados
        """
        if not self.stream:
            raise RuntimeError("Arquivo não aberto")
            
        # Ir para o final do arquivo para calcular posições
        self.stream.seek(0, 2)  # SEEK_END
        file_size = self.stream.tell()
        
        # Ir para o início da tabela de entradas
        entries_table_start = file_size - entries_data_size - 8
        self.stream.seek(entries_table_start, 0)
        
        # Ler número de entradas
        entries_length = struct.unpack('<I', self.stream.read(4))[0]
        
        # Ler cada entrada
        self.entries = []
        for i in range(entries_length):
            # Ler tamanho do caminho
            path_length = struct.unpack('<I', self.stream.read(4))[0]
            
            # Ler caminho
            path_bytes = self.stream.read(path_length)
            path = path_bytes.decode('latin-1', errors='ignore')
            
            # Ler flags e tamanhos
            compressed = struct.unpack('B', self.stream.read(1))[0]
            uncompressed_size = struct.unpack('<I', self.stream.read(4))[0]
            data_size = struct.unpack('<I', self.stream.read(4))[0]
            data_offset = struct.unpack('<I', self.stream.read(4))[0]
            
            # Extrair nome do arquivo do caminho
            name = Path(path).name
            
            entry = FileInfo(
                name=name,
                path=path,
                size=uncompressed_size,
                compressed_size=data_size,
                is_compressed=(compressed == 1),
                offset=data_offset
            )
            self.entries.append(entry)
        
        # Calcular offset dos dados
        self.data_offset = file_size - dbase_data_size
        
    def list_files(self) -> List[str]:
        """
        Lista todos os arquivos no DAT2.
        
        Returns:
            Lista de caminhos de arquivos (paths internos)
        """
        if not self.stream:
            self.open()
            
        if not self.entries:
            entries_data_size, dbase_data_size = self._read_header()
            self._read_directory(entries_data_size, dbase_data_size)
            
        return [entry.path for entry in self.entries]
        
    def get_file_info(self, internal_path: str) -> Optional[FileInfo]:
        """
        Obtém informações sobre um arquivo específico.
        
        Args:
            internal_path: Caminho interno do arquivo no DAT2
            
        Returns:
            FileInfo se encontrado, None caso contrário
        """
        if not self.entries:
            self.list_files()
            
        for entry in self.entries:
            if entry.path == internal_path:
                return entry
        return None
        
    def extract_file(self, internal_path: str) -> bytes:
        """
        Extrai e descomprime um arquivo do DAT2.
        
        Args:
            internal_path: Caminho interno do arquivo no DAT2
            
        Returns:
            Dados do arquivo (descomprimidos se necessário)
            
        Raises:
            FileNotFoundError: Se o arquivo não for encontrado no DAT2
            zlib.error: Se a descompressão falhar
        """
        if not self.stream:
            raise RuntimeError("Arquivo não aberto")
            
        entry = self.get_file_info(internal_path)
        if not entry:
            raise FileNotFoundError(f"Arquivo não encontrado no DAT2: {internal_path}")
        
        # Ir para a posição dos dados
        actual_offset = self.data_offset + entry.offset
        self.stream.seek(actual_offset, 0)
        
        # Ler dados
        data = self.stream.read(entry.compressed_size)
        
        # Descomprimir se necessário
        if entry.is_compressed:
            try:
                data = zlib.decompress(data)
            except zlib.error as e:
                raise zlib.error(f"Erro ao descomprimir {internal_path}: {e}")
        
        return data
        
    def extract_all(self, output_dir: str) -> Dict[str, str]:
        """
        Extrai todos os arquivos do DAT2 para um diretório.
        
        Args:
            output_dir: Diretório de destino
            
        Returns:
            Dicionário mapeando caminhos internos para caminhos de saída
        """
        output_path = Path(output_dir)
        output_path.mkdir(parents=True, exist_ok=True)
        
        extracted = {}
        
        for entry in self.entries:
            try:
                data = self.extract_file(entry.path)
                
                # Construir caminho de saída
                output_file = output_path / entry.path.replace('\\', '/')
                output_file.parent.mkdir(parents=True, exist_ok=True)
                
                # Salvar arquivo
                with open(output_file, 'wb') as f:
                    f.write(data)
                    
                extracted[entry.path] = str(output_file)
                
            except Exception as e:
                # Log erro mas continua com outros arquivos
                print(f"Erro ao extrair {entry.path}: {e}")
                
        return extracted


class DAT2Manager:
    """
    Gerenciador de múltiplos arquivos DAT2 com resolução de prioridade.
    
    A ordem de prioridade é: patch000.dat > critter.dat > master.dat
    Isso significa que se um arquivo existe em múltiplos DAT2, o arquivo
    do DAT2 com maior prioridade será usado.
    """
    
    # Ordem de prioridade (maior índice = maior prioridade)
    PRIORITY_ORDER = {
        'patch000.dat': 2,
        'critter.dat': 1,
        'master.dat': 0,
    }
    
    def __init__(self, dat_paths: List[str]):
        """
        Inicializa o gerenciador com uma lista de caminhos DAT2.
        
        Args:
            dat_paths: Lista de caminhos para arquivos DAT2
        """
        self.readers: List[tuple[DAT2Reader, int]] = []
        
        # Criar leitores e ordenar por prioridade
        for dat_path in dat_paths:
            dat_file = Path(dat_path).name.lower()
            priority = self.PRIORITY_ORDER.get(dat_file, -1)
            
            if priority >= 0:
                reader = DAT2Reader(dat_path)
                reader.open()
                self.readers.append((reader, priority))
        
        # Ordenar por prioridade (maior primeiro)
        self.readers.sort(key=lambda x: x[1], reverse=True)
        
    def __enter__(self):
        """Context manager entry."""
        return self
        
    def __exit__(self, exc_type, exc_val, exc_tb):
        """Context manager exit."""
        self.close()
        return False
        
    def close(self):
        """Fecha todos os leitores DAT2."""
        for reader, _ in self.readers:
            reader.close()
        self.readers.clear()
        
    def get_file(self, internal_path: str) -> Optional[bytes]:
        """
        Obtém um arquivo do DAT2 com maior prioridade.
        
        Args:
            internal_path: Caminho interno do arquivo
            
        Returns:
            Dados do arquivo se encontrado, None caso contrário
        """
        # Procurar em ordem de prioridade (maior primeiro)
        for reader, _ in self.readers:
            try:
                if internal_path in reader.list_files():
                    return reader.extract_file(internal_path)
            except Exception:
                # Continuar procurando em outros DAT2
                continue
        return None
        
    def list_all_files(self) -> List[str]:
        """
        Lista todos os arquivos únicos de todos os DAT2.
        
        Se um arquivo existe em múltiplos DAT2, apenas o caminho é retornado
        (o arquivo do DAT2 com maior prioridade será usado quando extraído).
        
        Returns:
            Lista de caminhos únicos de arquivos
        """
        seen = set()
        all_files = []
        
        # Coletar arquivos em ordem de prioridade
        for reader, _ in self.readers:
            files = reader.list_files()
            for file_path in files:
                if file_path not in seen:
                    seen.add(file_path)
                    all_files.append(file_path)
                    
        return all_files
        
    def get_file_info(self, internal_path: str) -> Optional[FileInfo]:
        """
        Obtém informações sobre um arquivo do DAT2 com maior prioridade.
        
        Args:
            internal_path: Caminho interno do arquivo
            
        Returns:
            FileInfo se encontrado, None caso contrário
        """
        for reader, _ in self.readers:
            info = reader.get_file_info(internal_path)
            if info:
                return info
        return None

