# 🚀 Como Iniciar o Servidor

## ⚠️ PROBLEMA: "Conexão Recusada"

Se você está vendo "A conexão com localhost foi recusada", significa que o servidor não está rodando.

## ✅ SOLUÇÃO RÁPIDA

### Opção 1: Usar o arquivo .bat (Windows)
```bash
# Clique duas vezes em:
web_server/start.bat
```

### Opção 2: Comando Manual
```bash
cd web_server
python server.py
```

### Opção 3: Usar npm
```bash
npm run dev
```

## 🔍 VERIFICAR SE ESTÁ RODANDO

Após iniciar, você deve ver:
```
✅ Servidor rodando em: http://localhost:8000
```

## 🌐 ACESSAR

Depois que o servidor iniciar, abra no navegador:
- http://localhost:8000/
- http://localhost:8000/fallout_game_web.html

## 🛑 PARAR O SERVIDOR

Pressione `Ctrl+C` no terminal onde o servidor está rodando.

## ❌ PROBLEMAS COMUNS

### 1. Porta 8000 já em uso
**Erro:** "Address already in use"

**Solução:**
- Feche outros programas usando a porta 8000
- Ou mude a porta no `server.py` (linha 17: `PORT = 8000`)

### 2. Python não encontrado
**Erro:** "python não é reconhecido"

**Solução:**
- Instale Python 3
- Ou use `python3` ao invés de `python`

### 3. Módulos faltando
**Erro:** "ModuleNotFoundError"

**Solução:**
```bash
pip install watchdog
```

## ✅ TESTE RÁPIDO

1. Abra terminal
2. Execute: `cd web_server && python server.py`
3. Veja a mensagem: "Servidor rodando em: http://localhost:8000"
4. Abra o navegador em: http://localhost:8000/

**Pronto!** 🎮

