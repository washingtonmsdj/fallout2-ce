# 📁 Estrutura Profissional do Projeto

## 🎯 Estrutura Atual vs Ideal

### ❌ Problema Atual
```
fallout2-ce/
├── web_server/          ← Fora da estrutura do jogo
│   ├── assets/         ← Assets aqui
│   └── ...
├── src/                ← Código C++ do jogo
└── Fallout 2/          ← Assets originais
```

### ✅ Estrutura Ideal (Padrão AAA)
```
fallout2-ce/
├── src/                    # Código-fonte C++
├── build/                  # Builds compilados
│
├── game/                   # JOGO PRINCIPAL (C++)
│   ├── data/              # Assets do jogo original
│   │   ├── master.dat
│   │   ├── critter.dat
│   │   └── ...
│   └── fallout2-ce.exe
│
├── web/                   # VERSÃO WEB
│   ├── server/            # Servidor Python
│   │   ├── server.py
│   │   └── ...
│   ├── assets/            # Assets organizados para web
│   │   ├── sprites/
│   │   ├── maps/
│   │   └── ...
│   ├── js/                # JavaScript
│   │   ├── core/
│   │   ├── game/
│   │   └── utils/
│   └── index.html
│
└── tools/                 # Ferramentas
    ├── extractors/
    └── converters/
```

## 🔄 Reorganização Proposta

1. **Mover `web_server/` → `web/`**
2. **Separar assets do jogo C++ dos assets web**
3. **Criar estrutura clara e profissional**

## 📝 Vantagens

- ✅ Separação clara entre jogo C++ e web
- ✅ Assets organizados por plataforma
- ✅ Estrutura profissional (padrão AAA)
- ✅ Fácil manutenção
- ✅ Preparado para produção

