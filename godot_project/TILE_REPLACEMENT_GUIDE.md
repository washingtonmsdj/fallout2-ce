# Guia de Substituição de Tiles

## Estrutura de Pastas

```
tiles_organized/
├── desert/           # Ambiente desértico
│   ├── floor/       # Pisos
│   ├── wall/        # Paredes
│   └── roof/        # Telhados
├── city/            # Ambiente urbano
├── cave/            # Cavernas
├── vault/           # Vaults (bunkers)
├── interior/        # Interiores
├── arroyo/          # Tribal
└── wasteland/       # Wasteland
```

## Dimensões dos Tiles

| Tipo | Dimensões | Descrição |
|------|-----------|-----------|
| Floor | 80x36 px | Piso isométrico |
| Wall | 80x80 px | Parede (pode variar) |
| Roof | 80x36 px | Telhado isométrico |
| Building | Variável | Estruturas completas |

## Como Substituir

1. **Identifique o ambiente** que você quer modificar
2. **Mantenha as dimensões** isométricas (80x36 para pisos)
3. **Use PNG com transparência** onde necessário
4. **Substitua os arquivos** mantendo os mesmos nomes

## Dicas para Jogo AAA

- Crie tilesets consistentes por ambiente
- Use variações (tile_001, tile_002) para evitar repetição
- Considere tiles de transição entre ambientes
- Adicione detalhes como rachaduras, sujeira, etc.

## Ambientes Disponíveis


### Desert
- **building**: 36 tiles

### Wasteland
- **misc**: 15 tiles

### Misc
- **floor**: 10 tiles

### Arroyo
- **roof**: 39 tiles
