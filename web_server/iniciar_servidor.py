#!/usr/bin/env python3
"""
Script simples para iniciar o servidor web
Garante que funcione corretamente
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path

# Configuração
PORT = 8000
WEB_DIR = Path(__file__).parent

# Mudar para o diretório web
os.chdir(WEB_DIR)

# Handler com CORS para Chrome
class CORSRequestHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
        super().end_headers()
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

Handler = CORSRequestHandler

# Criar servidor
try:
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        print("=" * 70)
        print("🚀 SERVIDOR WEB - Fallout 2")
        print("=" * 70)
        print(f"\n✅ Servidor rodando em: http://localhost:{PORT}")
        print(f"📁 Diretório: {WEB_DIR}")
        print(f"\n🌐 URLs Disponíveis:")
        print(f"   🏠 Início: http://localhost:{PORT}/")
        print(f"   🎮 Jogo: http://localhost:{PORT}/fallout_game_web.html")
        print(f"   🎨 Editor: http://localhost:{PORT}/fallout_web_editor.html")
        print(f"   📊 Dashboard: http://localhost:{PORT}/dashboard.html")
        print(f"\n⏹️  Pressione Ctrl+C para parar")
        print("=" * 70)
        print()
        
        httpd.serve_forever()
        
except OSError as e:
    if e.errno == 98 or e.errno == 48:  # Address already in use
        print(f"\n❌ ERRO: Porta {PORT} já está em uso!")
        print(f"   Feche outros programas ou mude a porta.")
        print(f"\n💡 Solução: Edite este arquivo e mude PORT = {PORT} para outra porta")
        sys.exit(1)
    else:
        print(f"\n❌ ERRO: {e}")
        sys.exit(1)
        
except KeyboardInterrupt:
    print("\n\n🛑 Servidor parado pelo usuário")
    sys.exit(0)

