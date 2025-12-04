#!/usr/bin/env python3
"""
Servidor Web para Visualização de Sprites do Fallout 2
Dashboard completo e robusto para análise de assets
"""

import http.server
import socketserver
import json
import os
import sys
from pathlib import Path
from urllib.parse import urlparse, parse_qs
import mimetypes

# Configuração
PORT = 8000
BASE_DIR = Path(__file__).parent.parent
FALLOUT_DIR = BASE_DIR / "Fallout 2"
WEB_DIR = BASE_DIR / "web_server"
ASSETS_DIR = WEB_DIR / "assets"
EXTRACTED_DIR = ASSETS_DIR / "extracted"

# Criar diretórios necessários
ASSETS_DIR.mkdir(exist_ok=True)
EXTRACTED_DIR.mkdir(exist_ok=True)

class FalloutAssetHandler(http.server.SimpleHTTPRequestHandler):
    """Handler customizado para servir assets e API"""
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_DIR), **kwargs)
    
    def end_headers(self):
        """Adiciona headers CORS e segurança para Chrome"""
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('X-Frame-Options', 'SAMEORIGIN')
        super().end_headers()
    
    def do_OPTIONS(self):
        """Handle OPTIONS requests (CORS preflight)"""
        self.send_response(200)
        self.end_headers()
    
    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        
        # Ignorar silenciosamente requisições de favicon.ico se não existir
        if path == '/favicon.ico':
            favicon_path = Path(self.directory) / 'favicon.ico'
            if favicon_path.exists() and favicon_path.is_file():
                super().do_GET()
            else:
                # Retornar 204 No Content ao invés de 404
                self.send_response(204)
                self.end_headers()
            return
        
        # API endpoints
        if path.startswith('/api/'):
            self.handle_api(path, parsed_path)
            return
        
        # Servir arquivos estáticos
        # Normalizar caminho
        if path == '/' or path == '':
            path = '/index.html'
        elif not path.startswith('/'):
            path = '/' + path
        
        # Remover barra inicial para construir caminho
        file_path = Path(self.directory) / path.lstrip('/')
        
        # Verificar se arquivo existe
        if file_path.exists() and file_path.is_file():
            # Determinar Content-Type
            content_type = 'text/html; charset=utf-8'
            if path.endswith('.js'):
                content_type = 'application/javascript; charset=utf-8'
            elif path.endswith('.css'):
                content_type = 'text/css; charset=utf-8'
            elif path.endswith('.json'):
                content_type = 'application/json; charset=utf-8'
            elif path.endswith('.png'):
                content_type = 'image/png'
            elif path.endswith('.jpg') or path.endswith('.jpeg'):
                content_type = 'image/jpeg'
            elif path.endswith('.gif'):
                content_type = 'image/gif'
            elif path.endswith('.woff') or path.endswith('.woff2'):
                content_type = 'font/woff2'
            elif path.endswith('.ttf'):
                content_type = 'font/ttf'
            
            # Servir arquivo
            self.send_response(200)
            self.send_header('Content-Type', content_type)
            self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
            self.send_header('Pragma', 'no-cache')
            self.send_header('Expires', '0')
            self.end_headers()  # end_headers já adiciona CORS
            
            try:
                with open(file_path, 'rb') as f:
                    self.wfile.write(f.read())
            except Exception as e:
                print(f"Erro ao ler arquivo {file_path}: {e}")
                self.send_error(500, f"Erro ao ler arquivo: {e}")
        else:
            # Tentar servir com SimpleHTTPRequestHandler padrão
            try:
                super().do_GET()
            except Exception as e:
                self.send_error(404, f"Arquivo não encontrado: {path}")
    
    def handle_api(self, path, parsed):
        """Handle API requests"""
        query = parse_qs(parsed.query)
        
        if path == '/api/stats':
            self.send_json_response(self.get_stats())
        elif path == '/api/files':
            self.send_json_response(self.get_files(query))
        elif path == '/api/sprites':
            self.send_json_response(self.get_sprites(query))
        elif path == '/api/critters':
            self.send_json_response(self.get_critters())
        elif path == '/api/sprites/images':
            self.send_json_response(self.get_sprite_images())
        else:
            self.send_error(404, "API endpoint not found")
    
    def get_stats(self):
        """Retorna estatísticas dos assets"""
        stats = {
            "dat_files": {},
            "total_size": 0,
            "sprite_count": 0,
            "extracted_count": 0
        }
        
        # Analisar arquivos .DAT
        dat_files = ['master.dat', 'critter.dat', 'patch000.dat', 'f2_res.dat']
        for dat_file in dat_files:
            dat_path = FALLOUT_DIR / dat_file
            if dat_path.exists():
                size = dat_path.stat().st_size
                stats["dat_files"][dat_file] = {
                    "size": size,
                    "size_mb": round(size / (1024 * 1024), 2),
                    "exists": True
                }
                stats["total_size"] += size
        
        # Contar sprites extraídos
        if EXTRACTED_DIR.exists():
            frm_files = list(EXTRACTED_DIR.rglob("*.FRM")) + list(EXTRACTED_DIR.rglob("*.frm"))
            stats["extracted_count"] = len(frm_files)
        
        # Contar sprites conhecidos (da lista)
        critters_lst = FALLOUT_DIR / "data" / "art" / "critters" / "critters.lst"
        if not critters_lst.exists():
            # Tentar dentro do .DAT ou usar estimativa
            stats["sprite_count"] = "N/A (dentro do .DAT)"
        else:
            with open(critters_lst, 'r') as f:
                lines = [l.strip() for l in f if l.strip()]
                stats["sprite_count"] = len(lines)
        
        return stats
    
    def get_files(self, query):
        """Lista arquivos disponíveis"""
        file_type = query.get('type', ['all'])[0]
        files = []
        
        # Arquivos .DAT
        if file_type in ['all', 'dat']:
            for dat_file in ['master.dat', 'critter.dat', 'patch000.dat', 'f2_res.dat']:
                dat_path = FALLOUT_DIR / dat_file
                if dat_path.exists():
                    files.append({
                        "name": dat_file,
                        "type": "dat",
                        "size": dat_path.stat().st_size,
                        "size_mb": round(dat_path.stat().st_size / (1024 * 1024), 2),
                        "path": str(dat_path.relative_to(BASE_DIR))
                    })
        
        # Sprites extraídos
        if file_type in ['all', 'frm']:
            if EXTRACTED_DIR.exists():
                for frm_file in EXTRACTED_DIR.rglob("*.FRM"):
                    files.append({
                        "name": frm_file.name,
                        "type": "frm",
                        "size": frm_file.stat().st_size,
                        "path": str(frm_file.relative_to(BASE_DIR)),
                        "category": frm_file.parent.name
                    })
                for frm_file in EXTRACTED_DIR.rglob("*.frm"):
                    files.append({
                        "name": frm_file.name,
                        "type": "frm",
                        "size": frm_file.stat().st_size,
                        "path": str(frm_file.relative_to(BASE_DIR)),
                        "category": frm_file.parent.name
                    })
        
        return {"files": files, "count": len(files)}
    
    def get_sprites(self, query):
        """Lista sprites disponíveis"""
        sprites = []
        
        # Sprites conhecidos (baseado em nomes comuns)
        known_sprites = [
            {"name": "hmwarr", "type": "critter", "desc": "Homem Tribal"},
            {"name": "hfprim", "type": "critter", "desc": "Mulher Tribal"},
            {"name": "hmjmps", "type": "critter", "desc": "Homem Jumpsuit"},
            {"name": "hfjmps", "type": "critter", "desc": "Mulher Jumpsuit"},
        ]
        
        for sprite in known_sprites:
            sprites.append({
                **sprite,
                "animations": ["stand", "walk", "run", "attack"],
                "weapons": ["none", "knife", "pistol", "rifle"],
                "directions": 6,
                "location": f"critter.dat ou master.dat"
            })
        
        return {"sprites": sprites, "count": len(sprites)}
    
    def get_critters(self):
        """Lista critters/NPCs conhecidos"""
        critters = []
        
        # Critters conhecidos do jogo
        known_critters = [
            {"id": 1, "name": "hmwarr", "desc": "Homem Tribal", "gender": "male"},
            {"id": 2, "name": "hfprim", "desc": "Mulher Tribal", "gender": "female"},
            {"id": 3, "name": "hmjmps", "desc": "Homem Jumpsuit", "gender": "male"},
            {"id": 4, "name": "hfjmps", "desc": "Mulher Jumpsuit", "gender": "female"},
        ]
        
        return {"critters": known_critters, "count": len(known_critters)}
    
    def get_sprite_images(self):
        """Lista sprites convertidos para PNG"""
        images_index = EXTRACTED_DIR / "images" / "sprites_index.json"
        
        if not images_index.exists():
            return {"sprites": [], "count": 0, "message": "Nenhuma imagem convertida ainda"}
        
        try:
            import json
            with open(images_index, 'r', encoding='utf-8') as f:
                data = json.load(f)
            return {"sprites": data, "count": len(data)}
        except Exception as e:
            return {"sprites": [], "count": 0, "error": str(e)}
    
    def send_json_response(self, data):
        """Envia resposta JSON"""
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(json.dumps(data, indent=2).encode('utf-8'))
    
    def log_message(self, format, *args):
        """Custom log format"""
        print(f"[{self.address_string()}] {format % args}")

def main():
    """Inicia o servidor"""
    os.chdir(WEB_DIR)
    
    handler = FalloutAssetHandler
    
    with socketserver.TCPServer(("", PORT), handler) as httpd:
        print("=" * 60)
        print(f"🚀 Servidor Web Fallout 2 Asset Viewer")
        print("=" * 60)
        print(f"📡 Servidor rodando em: http://localhost:{PORT}")
        print(f"📁 Diretório base: {BASE_DIR}")
        print(f"📦 Assets: {FALLOUT_DIR}")
        print("=" * 60)
        print("\n✨ Dashboard disponível em:")
        print(f"   http://localhost:{PORT}/dashboard.html")
        print("\n📊 API disponível em:")
        print(f"   http://localhost:{PORT}/api/stats")
        print(f"   http://localhost:{PORT}/api/files")
        print(f"   http://localhost:{PORT}/api/sprites")
        print("\n⏹️  Pressione Ctrl+C para parar o servidor")
        print("=" * 60)
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\n\n🛑 Servidor parado pelo usuário")
            sys.exit(0)

if __name__ == "__main__":
    main()

