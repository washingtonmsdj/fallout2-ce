// ============================================
// MAP LOADER - Carrega mapas .MAP do Fallout 2
// Baseado no código real do jogo
// ============================================

class FalloutMapLoader {
    constructor() {
        this.HEX_GRID_WIDTH = 200;
        this.HEX_GRID_HEIGHT = 200;
        this.SQUARE_GRID_WIDTH = 100;
        this.SQUARE_GRID_HEIGHT = 100;
    }
    
    // Converter tile hexagonal para coordenadas de tela
    // Baseado em: tileToScreenXY (tile.cc:675)
    tileToScreenXY(tile, centerTile, offset) {
        const v3 = this.HEX_GRID_WIDTH - 1 - (tile % this.HEX_GRID_WIDTH);
        const v4 = Math.floor(tile / this.HEX_GRID_WIDTH);
        
        let screenX = offset.x;
        let screenY = offset.y;
        
        const v5 = Math.floor((v3 - centerTile.x) / -2);
        screenX += 48 * Math.floor((v3 - centerTile.x) / 2);
        screenY += 12 * v5;
        
        if (v3 & 1) {
            if (v3 <= centerTile.x) {
                screenX -= 16;
                screenY += 12;
            } else {
                screenX += 32;
            }
        }
        
        const v6 = v4 - centerTile.y;
        screenX += 16 * v6;
        screenY += 12 * v6;
        
        return { x: screenX, y: screenY };
    }
    
    // Converter tile quadrado para coordenadas de tela
    // Baseado em: squareTileToScreenXY (tile.cc:1128)
    squareTileToScreenXY(squareTile, centerSquare, offset) {
        const v5 = this.SQUARE_GRID_WIDTH - 1 - (squareTile % this.SQUARE_GRID_WIDTH);
        const v6 = Math.floor(squareTile / this.SQUARE_GRID_WIDTH);
        
        const v7 = centerSquare.x;
        let screenX = offset.x;
        let screenY = offset.y;
        
        const v8 = v5 - v7;
        screenX += 48 * v8;
        screenY -= 12 * v8;
        
        const v9 = v6 - centerSquare.y;
        screenX += 32 * v9;
        screenY = 24 * v9 + screenY;
        screenY = screenY - 96;
        
        return { x: screenX, y: screenY };
    }
    
    // Carregar mapa .MAP (simplificado por enquanto)
    async loadMapFile(mapPath) {
        try {
            // Por enquanto, retornar dados mockados
            // Depois implementar parser real de .MAP
            return {
                header: {
                    name: 'Arroyo',
                    version: 20,
                    enteringTile: 20000,
                    enteringElevation: 0,
                    enteringRotation: 0
                },
                tiles: this.generateDefaultTiles(),
                objects: [],
                npcs: []
            };
        } catch (error) {
            console.error('Erro ao carregar mapa:', error);
            return null;
        }
    }
    
    // Gerar tiles padrão (temporário até carregar .MAP real)
    generateDefaultTiles() {
        const tiles = [];
        for (let y = 0; y < this.SQUARE_GRID_HEIGHT; y++) {
            for (let x = 0; x < this.SQUARE_GRID_WIDTH; x++) {
                const squareTile = y * this.SQUARE_GRID_WIDTH + x;
                // Tile padrão (grama)
                tiles[squareTile] = {
                    floor: 1, // FID do tile de chão
                    roof: 0,  // Sem telhado
                    type: 'grass'
                };
            }
        }
        return tiles;
    }
}

window.FalloutMapLoader = FalloutMapLoader;

