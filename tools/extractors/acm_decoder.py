"""
Módulo para decodificação de áudio ACM do Fallout 2.

Este módulo implementa o ACMDecoder que converte arquivos ACM para formatos
compatíveis com Godot (OGG ou WAV).
"""
import subprocess
import struct
from pathlib import Path
from typing import Optional, Tuple
import tempfile
import os


class ACMDecoder:
    """
    Decodificador de arquivos ACM do Fallout 2.
    
    O formato ACM é um formato de áudio comprimido proprietário. Este decodificador
    tenta usar ferramentas externas (como acm2wav ou ffmpeg) para converter para
    formatos padrão.
    """
    
    def __init__(self, use_ffmpeg: bool = True, ffmpeg_path: Optional[str] = None):
        """
        Inicializa o decodificador ACM.
        
        Args:
            use_ffmpeg: Se True, tenta usar ffmpeg para conversão
            ffmpeg_path: Caminho para o executável ffmpeg (None = auto-detect)
        """
        self.use_ffmpeg = use_ffmpeg
        self.ffmpeg_path = ffmpeg_path or self._find_ffmpeg()
    
    def _find_ffmpeg(self) -> Optional[str]:
        """
        Tenta encontrar o executável ffmpeg no sistema.
        
        Returns:
            Caminho para ffmpeg ou None se não encontrado
        """
        # Verificar variável de ambiente
        if 'FFMPEG_PATH' in os.environ:
            path = Path(os.environ['FFMPEG_PATH'])
            if path.exists():
                return str(path)
        
        # Tentar encontrar no PATH
        try:
            result = subprocess.run(['ffmpeg', '-version'], 
                                  capture_output=True, 
                                  timeout=5)
            if result.returncode == 0:
                return 'ffmpeg'
        except (FileNotFoundError, subprocess.TimeoutExpired):
            pass
        
        return None
    
    def _detect_audio_type(self, path: str) -> str:
        """
        Detecta o tipo de áudio pelo caminho original.
        
        Args:
            path: Caminho do arquivo
            
        Returns:
            Tipo: 'music', 'sfx', ou 'voice'
        """
        path_lower = path.lower()
        
        if 'music' in path_lower or 'sound/music' in path_lower:
            return 'music'
        elif 'voice' in path_lower or 'sound/voice' in path_lower:
            return 'voice'
        else:
            return 'sfx'
    
    def decode_to_wav(self, acm_data: bytes, output_path: str) -> bool:
        """
        Decodifica dados ACM para WAV.
        
        Args:
            acm_data: Dados binários do arquivo ACM
            output_path: Caminho de saída do arquivo WAV
            
        Returns:
            True se bem-sucedido, False caso contrário
        """
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Criar arquivo temporário ACM
        with tempfile.NamedTemporaryFile(suffix='.acm', delete=False) as temp_acm:
            temp_acm.write(acm_data)
            temp_acm_path = temp_acm.name
        
        try:
            # Tentar usar ffmpeg se disponível
            if self.use_ffmpeg and self.ffmpeg_path:
                return self._convert_with_ffmpeg(temp_acm_path, output_path)
            
            # Fallback: copiar como WAV (não ideal, mas permite continuar)
            # Em produção, seria necessário um decodificador ACM real
            print(f"Aviso: Conversão ACM não suportada sem ffmpeg. "
                  f"Copiando dados brutos para {output_path}")
            with open(output_path, 'wb') as f:
                f.write(acm_data)
            return False
            
        finally:
            # Limpar arquivo temporário
            try:
                os.unlink(temp_acm_path)
            except OSError:
                pass
    
    def _convert_with_ffmpeg(self, acm_path: str, wav_path: str) -> bool:
        """
        Converte ACM para WAV usando ffmpeg.
        
        Args:
            acm_path: Caminho do arquivo ACM
            wav_path: Caminho de saída WAV
            
        Returns:
            True se bem-sucedido
        """
        try:
            cmd = [
                self.ffmpeg_path,
                '-i', acm_path,
                '-y',  # Sobrescrever arquivo de saída
                wav_path
            ]
            
            result = subprocess.run(cmd, 
                                  capture_output=True, 
                                  timeout=30)
            
            if result.returncode == 0:
                return True
            else:
                print(f"Erro ao converter ACM: {result.stderr.decode('utf-8', errors='ignore')}")
                return False
                
        except subprocess.TimeoutExpired:
            print(f"Timeout ao converter ACM: {acm_path}")
            return False
        except Exception as e:
            print(f"Erro ao converter ACM: {e}")
            return False
    
    def convert_to_ogg(self, acm_data: bytes, output_path: str) -> bool:
        """
        Converte dados ACM para OGG.
        
        Args:
            acm_data: Dados binários do arquivo ACM
            output_path: Caminho de saída do arquivo OGG
            
        Returns:
            True se bem-sucedido, False caso contrário
        """
        output_file = Path(output_path)
        output_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Criar arquivo temporário ACM
        with tempfile.NamedTemporaryFile(suffix='.acm', delete=False) as temp_acm:
            temp_acm.write(acm_data)
            temp_acm_path = temp_acm.name
        
        try:
            # Converter ACM -> WAV -> OGG usando ffmpeg
            if self.use_ffmpeg and self.ffmpeg_path:
                with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as temp_wav:
                    temp_wav_path = temp_wav.name
                
                try:
                    # ACM -> WAV
                    if not self._convert_with_ffmpeg(temp_acm_path, temp_wav_path):
                        return False
                    
                    # WAV -> OGG
                    cmd = [
                        self.ffmpeg_path,
                        '-i', temp_wav_path,
                        '-c:a', 'libvorbis',  # Codec OGG Vorbis
                        '-y',
                        output_path
                    ]
                    
                    result = subprocess.run(cmd, 
                                          capture_output=True, 
                                          timeout=30)
                    
                    return result.returncode == 0
                    
                finally:
                    # Limpar WAV temporário
                    try:
                        os.unlink(temp_wav_path)
                    except OSError:
                        pass
            
            # Fallback: tentar converter diretamente
            if self.use_ffmpeg and self.ffmpeg_path:
                cmd = [
                    self.ffmpeg_path,
                    '-i', temp_acm_path,
                    '-c:a', 'libvorbis',
                    '-y',
                    output_path
                ]
                
                result = subprocess.run(cmd, 
                                      capture_output=True, 
                                      timeout=30)
                return result.returncode == 0
            
            return False
            
        finally:
            # Limpar arquivo temporário
            try:
                os.unlink(temp_acm_path)
            except OSError:
                pass
    
    def organize_audio(self, acm_path: str, output_dir: str, 
                      audio_type: Optional[str] = None) -> str:
        """
        Organiza arquivo de áudio na estrutura de saída.
        
        Args:
            acm_path: Caminho interno do arquivo ACM
            output_dir: Diretório base de saída
            audio_type: Tipo de áudio ('music', 'sfx', 'voice') ou None para auto-detect
        
        Returns:
            Caminho de saída organizado
        """
        if audio_type is None:
            audio_type = self._detect_audio_type(acm_path)
        
        output_path = Path(output_dir) / 'audio' / audio_type
        output_path.mkdir(parents=True, exist_ok=True)
        
        # Nome do arquivo de saída (mudar extensão para .ogg)
        filename = Path(acm_path).stem + '.ogg'
        return str(output_path / filename)

