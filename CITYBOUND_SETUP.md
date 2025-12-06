# Rodando Citybound no Localhost

## Problema Encontrado

O Citybound no repositório requer uma versão **muito antiga** do Rust nightly (2020-03-10), que é difícil de compilar em máquinas modernas.

## Solução: Usar Build Pronto

A forma mais rápida é baixar o executável pronto:

### Passo 1: Baixar o Build
1. Acesse: http://aeplay.org/citybound-livebuilds
2. Procure pelo arquivo mais recente para Windows (`.exe`)
3. Baixe o arquivo

### Passo 2: Executar
1. Descompacte o arquivo (se necessário)
2. Execute o `.exe`
3. Abra seu navegador em `http://localhost:1234` (ou a porta que aparecer)

## Alternativa: Compilar do Código

Se quiser compilar do código, você precisará:

1. Instalar a versão correta do Rust:
```powershell
rustup override set nightly-2020-03-10
```

2. Instalar dependências do Visual Studio Build Tools

3. Executar:
```powershell
npm install
npm run ensure-tooling
npm run watch-browser  # Terminal 1
npm start              # Terminal 2
```

**Aviso:** Isso pode levar 1-2 horas dependendo da sua internet e máquina.

## Próximos Passos

Depois de rodar o Citybound, você pode:
- Explorar a interface web
- Desenhar estradas
- Criar zonas
- Observar a simulação de tráfego e economia

Isso vai te dar insights para seu projeto Fallout 2 em Godot!
