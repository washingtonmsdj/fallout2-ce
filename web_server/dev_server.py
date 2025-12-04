#!/usr/bin/env python3
"""
Servidor de Desenvolvimento com Hot Reload
Atualiza automaticamente quando arquivos mudam
"""

import http.server
import socketserver
import json
import os
import sys
from pathlib import Path
from urllib.parse import urlparse, parse_qs
import mimetypes
import threading
import time
try:
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler
    WATCHDOG_AVAILABLE = True
except ImportError:
    WATCHDOG_AVAILABLE = False
    print("⚠️  watchdog não instalado - hot reload desabilitado")
    print("   Instale com: pip install watchdog")

# Configuração
PORT = 8000
BASE_DIR = Path(__file__).parent.parent
FALLOUT_DIR = BASE_DIR / "Fallout 2"
WEB_DIR = Path(__file__).parent
ASSETS_DIR = WEB_DIR / "assets"
EXTRACTED_DIR = ASSETS_DIR / "extracted"

# Criar diretórios necessários
ASSETS_DIR.mkdir(exist_ok=True)
EXTRACTED_DIR.mkdir(exist_ok=True)

class FileChangeHandler(FileSystemEventHandler):
    """Monitora mudanças em arquivos"""
    
    def __init__(self):
        self.changed_files = []
        self.lock = threading.Lock()
    
    def on_modified(self, event):
        if not event.is_directory:
            with self.lock:
                self.changed_files.append(event.src_path)
            print(f"📝 Arquivo modificado: {event.src_path}")

# Importar handler do servidor principal
sys.path.insert(0, str(WEB_DIR))
from server import FalloutAssetHandler

class DevServer:
    """Servidor de desenvolvimento com hot reload"""
    
    def __init__(self, port=8000):
        self.port = port
        self.handler = FalloutAssetHandler
        self.httpd = None
        self.observer = None
        self.file_handler = FileChangeHandler()
    
    def start_file_watcher(self):
        """Inicia monitoramento de arquivos"""
        if not WATCHDOG_AVAILABLE:
            return
        
        event_handler = FileChangeHandler()
        observer = Observer()
        
        # Monitorar diretório web_server
        observer.schedule(event_handler, str(WEB_DIR), recursive=True)
        observer.start()
        
        self.observer = observer
        print("👀 Monitoramento de arquivos ativado")
    
    def start(self):
        """Inicia o servidor"""
        socketserver.TCPServer.allow_reuse_address = True
        
        try:
            self.httpd = socketserver.TCPServer(("", self.port), self.handler)
            print("=" * 70)
            print("🚀 SERVIDOR DE DESENVOLVIMENTO - Fallout 2 Web")
            print("=" * 70)
            print(f"\n✅ Servidor rodando em: http://localhost:{self.port}")
            print(f"📁 Diretório: {WEB_DIR}")
            print(f"\n📋 Páginas disponíveis:")
            print(f"   🎮 Jogo: http://localhost:{self.port}/fallout_game_web.html")
            print(f"   🎨 Editor: http://localhost:{self.port}/fallout_web_editor.html")
            print(f"   📊 Dashboard: http://localhost:{self.port}/dashboard.html")
            print(f"   🖼️  Galeria: http://localhost:{self.port}/sprite_gallery.html")
            print(f"\n💡 Dica: Arquivos são recarregados automaticamente!")
            print(f"   Pressione Ctrl+C para parar\n")
            print("=" * 70)
            
            # Iniciar monitoramento
            self.start_file_watcher()
            
            # Servir
            self.httpd.serve_forever()
            
        except KeyboardInterrupt:
            print("\n\n🛑 Parando servidor...")
            if self.observer:
                self.observer.stop()
            if self.httpd:
                self.httpd.shutdown()
            print("✅ Servidor parado")
        except OSError as e:
            if e.errno == 98 or e.errno == 48:  # Address already in use
                print(f"\n❌ Erro: Porta {self.port} já está em uso!")
                print(f"   Tente parar o servidor anterior ou use outra porta")
            else:
                print(f"\n❌ Erro: {e}")

if __name__ == "__main__":
    server = DevServer(PORT)
    server.start()

