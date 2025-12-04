// ============================================
// MAP RENDERER - Fallout 2 Isometric System
// Implementação CORRETA baseada no código original
// ============================================

class FalloutMapRenderer {
    constructor(app) {
        this.app = app;
        this.HEX_GRID_WIDTH = 200;
        this.HEX_GRID_HEIGHT = 200;
        this.SQUARE_GRID_WIDTH = 100;
        this.SQUARE_GRID_HEIGHT = 100;
        
        // Centro do grid (tile central visível)
        this.centerTile = { x: 100, y: 100 }; // HEX grid center
        this.centerSquare = { x: 50, y: 50 }; // SQUARE grid center
        
        // Offset da tela (centro da viewport)
        this.offset = { 
            x: 0, // Será calculado
            y: 0  // Será calculado
        };
        
        this.elevation = 0;
        this.mapLoader = null;
        this.squareOffset = { x: 0, y: 0 }; // Será calculado
        this.assetsManager = null;
    }
    
    // Inicializar assets manager
    async initAssets() {
        if (typeof AssetsManager !== 'undefined') {
            this.assetsManager = new AssetsManager();
            await this.assetsManager.loadAllAssets();
        }
    }
    
    // Obter tipo de tile baseado no FID
    getTileTypeFromFID(fid) {
        // FIDs comuns de tiles do Fallout 2
        const frmId = fid & 0xFFF;
        
        // Tiles de grama geralmente são 1-10
        if (frmId >= 1 && frmId <= 10) return 'grass';
        // Tiles de terra/dirt geralmente são 11-20
        if (frmId >= 11 && frmId <= 20) return 'dirt';
        // Tiles de pedra/stone geralmente são 21-30
        if (frmId >= 21 && frmId <= 30) return 'stone';
        // Tiles de água geralmente são 31-40
        if (frmId >= 31 && frmId <= 40) return 'water';
        // Tiles de areia geralmente são 41-50
        if (frmId >= 41 && frmId <= 50) return 'sand';
        
        return 'grass'; // Padrão
    }
    
    // Converter tile HEXAGONAL para coordenadas de tela
    // Baseado EXATAMENTE em: tileToScreenXY (tile.cc:675)
    tileToScreenXY(tile) {
        const v3 = this.HEX_GRID_WIDTH - 1 - (tile % this.HEX_GRID_WIDTH);
        const v4 = Math.floor(tile / this.HEX_GRID_WIDTH);
        
        let screenX = this.offset.x;
        let screenY = this.offset.y;
        
        const v5 = Math.floor((v3 - this.centerTile.x) / -2);
        screenX += 48 * Math.floor((v3 - this.centerTile.x) / 2);
        screenY += 12 * v5;
        
        if (v3 & 1) {
            if (v3 <= this.centerTile.x) {
                screenX -= 16;
                screenY += 12;
            } else {
                screenX += 32;
            }
        }
        
        const v6 = v4 - this.centerTile.y;
        screenX += 16 * v6;
        screenY += 12 * v6;
        
        return { x: screenX, y: screenY };
    }
    
    // Converter tile QUADRADO (square) para coordenadas de tela
    // Baseado EXATAMENTE em: squareTileToScreenXY (tile.cc:1097)
    squareTileToScreenXY(squareTile) {
        const v5 = this.SQUARE_GRID_WIDTH - 1 - (squareTile % this.SQUARE_GRID_WIDTH);
        const v6 = Math.floor(squareTile / this.SQUARE_GRID_WIDTH);
        
        // Usar squareOffset (não tileOffset)
        let screenX = this.squareOffset ? this.squareOffset.x : this.offset.x - 16;
        let screenY = this.squareOffset ? this.squareOffset.y : this.offset.y - 2;
        
        const v8 = v5 - this.centerSquare.x;
        screenX += 48 * v8;
        screenY -= 12 * v8;
        
        const v9 = v6 - this.centerSquare.y;
        screenX += 32 * v9;
        screenY += 24 * v9;
        
        return { x: screenX, y: screenY };
    }
    
    // Converter coordenadas de tela para tile (baseado em tileFromScreenXY)
    screenXYToTile(screenX, screenY) {
        // Implementação simplificada - precisa da fórmula completa
        const hexGridWidth = 200;
        const hexGridHeight = 200;
        
        // Ajustar para coordenadas relativas ao centro
        const relX = screenX - this.offset.x;
        const relY = screenY - this.offset.y;
        
        // Fórmula inversa (simplificada)
        const tileX = Math.floor(relX / 48) + Math.floor(relY / 24);
        const tileY = Math.floor(relY / 12) - Math.floor(relX / 32);
        
        return { x: tileX, y: tileY };
    }
    
    // Renderizar tile de chão (SQUARE grid)
    // Baseado em: tileRenderFloor (tile.cc:1598)
    async renderFloorTile(container, squareTile, tileData) {
        const screenPos = this.squareTileToScreenXY(squareTile);
        
        // Tentar carregar sprite real se disponível
        if (this.assetsManager && tileData && tileData.floorFID) {
            try {
                // Construir FID (Frame ID) - formato: OBJ_TYPE_TILE | (frmId & 0xFFF)
                const frmId = tileData.floorFID & 0xFFF;
                const spriteName = `tile_${frmId}`;
                
                // Tentar carregar sprite
                const textures = await this.assetsManager.frmLoader.loadFRM(
                    `/assets/organized/sprites/tiles/grid${String(frmId).padStart(3, '0')}.FRM`
                );
                
                if (textures && textures.length > 0) {
                    const sprite = new PIXI.Sprite(textures[0]);
                    sprite.x = screenPos.x;
                    sprite.y = screenPos.y;
                    sprite.anchor.set(0.5);
                    container.addChild(sprite);
                    return sprite;
                }
            } catch (error) {
                // Fallback para gráfico se sprite não carregar
                console.debug(`Tile sprite não encontrado, usando gráfico: ${error.message}`);
            }
        }
        
        // Fallback: Criar tile isométrico gráfico
        const tile = new PIXI.Graphics();
        
        // Cores baseadas no tipo de tile
        let color = 0x3a5a3a; // Grama padrão
        if (tileData && tileData.type) {
            switch(tileData.type) {
                case 'grass': color = 0x3a5a3a; break;
                case 'dirt': color = 0x5a4a3a; break;
                case 'stone': color = 0x4a4a4a; break;
                case 'water': color = 0x2a4a6a; break;
                case 'sand': color = 0x8a7a5a; break;
                default: color = 0x3a5a3a;
            }
        }
        
        // Desenhar losango isométrico (48 pixels de largura, 24 de altura)
        tile.beginFill(color);
        tile.moveTo(0, -12);      // Topo
        tile.lineTo(24, 0);       // Direita
        tile.lineTo(0, 12);       // Baixo
        tile.lineTo(-24, 0);      // Esquerda
        tile.lineTo(0, -12);      // Fechar
        tile.endFill();
        
        // Borda muito sutil
        tile.lineStyle(1, 0x2a4a2a, 0.3);
        tile.moveTo(0, -12);
        tile.lineTo(24, 0);
        tile.lineTo(0, 12);
        tile.lineTo(-24, 0);
        tile.lineTo(0, -12);
        
        tile.x = screenPos.x;
        tile.y = screenPos.y;
        
        container.addChild(tile);
        
        return tile;
    }
    
    // Renderizar mapa completo
    // Baseado em: tileRenderFloorsInRect (tile.cc:1438)
    renderMap(container, mapData) {
        // Limpar container
        container.removeChildren();
        
        // Fundo preto
        const bg = new PIXI.Graphics();
        bg.beginFill(0x000000);
        bg.drawRect(0, 0, this.app.screen.width, this.app.screen.height);
        bg.endFill();
        container.addChild(bg);
        
        // Configurar offset (centro da tela)
        // Baseado EXATAMENTE em: _tile_offx e _tile_offy (tile.cc:581-583)
        // _tile_offx = (gTileWindowWidth - 32) / 2
        // _tile_offy = (gTileWindowHeight - 16) / 2
        // Se screen width > 640: _tile_offx -= 32
        this.offset = {
            x: Math.floor((this.app.screen.width - 32) / 2),
            y: Math.floor((this.app.screen.height - 16) / 2)
        };
        
        // Ajustar se tela maior que 640 (original)
        if (this.app.screen.width > 640) {
            this.offset.x -= 32;
        }
        
        // Square offset (baseado em tile.cc:592-598)
        // _square_offx = _tile_offx - 16
        // _square_offy = _tile_offy - 2
        // Se _tile_y & 1: _square_offy -= 12, _square_offx -= 16
        this.squareOffset = {
            x: this.offset.x - 16,
            y: this.offset.y - 2
        };
        
        // Ajuste se tile_y for ímpar
        if (this.centerTile.y & 1) {
            this.squareOffset.y -= 12;
            this.squareOffset.x -= 16;
        }
        
        // Calcular área visível (baseado em squareTileScreenToCoord)
        const viewWidth = this.app.screen.width;
        const viewHeight = this.app.screen.height;
        
        // Calcular range de tiles visíveis
        const minSquareX = Math.max(0, this.centerSquare.x - 30);
        const maxSquareX = Math.min(this.SQUARE_GRID_WIDTH - 1, this.centerSquare.x + 30);
        const minSquareY = Math.max(0, this.centerSquare.y - 30);
        const maxSquareY = Math.min(this.SQUARE_GRID_HEIGHT - 1, this.centerSquare.y + 30);
        
        // CAMADA 1: Renderizar FLOORS (chão)
        // Baseado em: tileRenderFloorsInRect
        const tilePromises = [];
        
        for (let y = minSquareY; y <= maxSquareY; y++) {
            for (let x = minSquareX; x <= maxSquareX; x++) {
                const squareTile = y * this.SQUARE_GRID_WIDTH + x;
                
                // Obter dados do tile do mapa real se disponível
                let tileData = { type: 'grass' };
                
                if (mapData && mapData.tiles && mapData.tiles[this.elevation]) {
                    const tileInfo = mapData.tiles[this.elevation][squareTile];
                    if (tileInfo) {
                        tileData = {
                            floorFID: tileInfo.floor,
                            roofFID: tileInfo.roof,
                            type: this.getTileTypeFromFID(tileInfo.floor)
                        };
                    }
                } else {
                    // Fallback: determinar tipo de tile
                    const distX = Math.abs(x - this.centerSquare.x);
                    const distY = Math.abs(y - this.centerSquare.y);
                    const dist = Math.sqrt(distX ** 2 + distY ** 2);
                    
                    if (dist < 8) {
                        tileData.type = 'dirt';
                    } else if (dist > 12 && dist < 18) {
                        tileData.type = 'stone';
                    } else if ((x + y) % 3 === 0) {
                        tileData.type = 'sand';
                    }
                }
                
                tilePromises.push(this.renderFloorTile(container, squareTile, tileData));
            }
        }
        
        // Aguardar todos os tiles carregarem (não bloqueia, mas organiza)
        Promise.all(tilePromises).catch(err => {
            console.warn('Alguns tiles não carregaram:', err);
        });
        
        // CAMADA 2: Objetos (pré-roof)
        this.renderObjects(container, mapData).catch(err => {
            console.warn('Erro ao renderizar objetos:', err);
        });
        
        // CAMADA 3: Roofs (telhados) - por enquanto vazio
        
        // CAMADA 4: NPCs (antes do player)
        this.renderNPCs(container, mapData).catch(err => {
            console.warn('Erro ao renderizar NPCs:', err);
        });
        
        // CAMADA 5: Player (sempre por último, apenas UMA vez)
        // Remover qualquer player existente primeiro
        const existingPlayers = container.children.filter(child => 
            child.userData && child.userData.isPlayer === true
        );
        existingPlayers.forEach(p => container.removeChild(p));
        
        // Renderizar player (apenas um)
        this.renderPlayer(container);
    }
    
    // Renderizar objetos do mapa
    // Baseado em: _obj_render_pre_roof e _obj_render_post_roof
    renderObjects(container, mapData) {
        if (!mapData || !mapData.objects) {
            // Objetos padrão se não houver dados
            const defaultObjects = [
                { tile: 20100, type: 'tree' },   // tile = y * HEX_GRID_WIDTH + x
                { tile: 20200, type: 'rock' },
                { tile: 20050, type: 'tree' },
                { tile: 20300, type: 'building' },
            ];
            
            defaultObjects.forEach(obj => {
                const screenPos = this.tileToScreenXY(obj.tile);
                const sprite = this.createObjectSprite(obj);
                
                sprite.x = screenPos.x;
                sprite.y = screenPos.y - 20;
                container.addChild(sprite);
            });
            return;
        }
        
        mapData.objects.forEach(obj => {
            const tile = obj.tileX * this.HEX_GRID_WIDTH + obj.tileY;
            const screenPos = this.tileToScreenXY(tile);
            const sprite = this.createObjectSprite(obj);
            
            sprite.x = screenPos.x;
            sprite.y = screenPos.y - 20;
            container.addChild(sprite);
        });
    }
    
    // Criar sprite de objeto
    createObjectSprite(obj) {
        const sprite = new PIXI.Graphics();
        
        switch(obj.type) {
            case 'tree':
                // Árvore
                sprite.beginFill(0x2d5016);
                sprite.drawCircle(0, 0, 8);
                sprite.endFill();
                sprite.beginFill(0x1a5c1a);
                sprite.drawCircle(0, -8, 10);
                sprite.endFill();
                break;
                
            case 'rock':
                // Pedra
                sprite.beginFill(0x4a4a4a);
                sprite.drawCircle(0, 0, 6);
                sprite.endFill();
                break;
                
            case 'building':
                // Construção
                sprite.beginFill(0x6b4423);
                sprite.drawRect(-12, -15, 24, 20);
                sprite.endFill();
                sprite.lineStyle(2, 0x8b4513);
                sprite.drawRect(-12, -15, 24, 20);
                break;
                
            default:
                sprite.beginFill(0x666666);
                sprite.drawCircle(0, 0, 5);
                sprite.endFill();
        }
        
        return sprite;
    }
    
    // Renderizar NPCs
    renderNPCs(container, mapData) {
        if (!mapData || !mapData.npcs) {
            // NPCs padrão se não houver dados
            const defaultNPCs = [
                { tile: 20150, name: 'Elder', type: 'elder' },
                { tile: 20080, name: 'Villager', type: 'villager' },
                { tile: 20250, name: 'Guard', type: 'guard' },
            ];
            
            defaultNPCs.forEach(npc => {
                const screenPos = this.tileToScreenXY(npc.tile);
                const sprite = this.createNPCSprite(npc);
                
                sprite.x = screenPos.x;
                sprite.y = screenPos.y - 15;
                container.addChild(sprite);
            });
            return;
        }
        
        mapData.npcs.forEach(npc => {
            const tile = npc.tileX * this.HEX_GRID_WIDTH + npc.tileY;
            const screenPos = this.tileToScreenXY(tile);
            const sprite = this.createNPCSprite(npc);
            
            sprite.x = screenPos.x;
            sprite.y = screenPos.y - 15;
            container.addChild(sprite);
        });
    }
    
    // Criar sprite de NPC
    createNPCSprite(npc) {
        const sprite = new PIXI.Graphics();
        
        // Cor baseada no tipo
        let color = 0xff6b6b;
        if (npc.type === 'villager') color = 0x4ecdc4;
        if (npc.type === 'guard') color = 0xffd93d;
        
        sprite.beginFill(color);
        sprite.drawCircle(0, 0, 10);
        sprite.endFill();
        sprite.lineStyle(2, 0xffffff);
        sprite.drawCircle(0, 0, 10);
        
        // Label
        if (npc.name) {
            const label = new PIXI.Text(npc.name, {
                fontFamily: 'Arial',
                fontSize: 10,
                fill: 0xffffff,
                stroke: 0x000000,
                strokeThickness: 2
            });
            label.anchor.set(0.5);
            label.y = 15;
            sprite.addChild(label);
        }
        
        return sprite;
    }
    
    // Renderizar player
    // Player está sempre no centerTile
    renderPlayer(container) {
        // Verificar se player já existe
        const existingPlayer = container.children.find(child => 
            child.userData && child.userData.isPlayer === true
        );
        
        if (existingPlayer) {
            return existingPlayer; // Já existe, não criar novamente
        }
        
        // Tile do player (centro do grid)
        const playerTile = this.centerTile.y * this.HEX_GRID_WIDTH + this.centerTile.x;
        const screenPos = this.tileToScreenXY(playerTile);
        
        const player = new PIXI.Graphics();
        player.beginFill(0x4a9eff);
        player.drawCircle(0, 0, 12);
        player.endFill();
        player.lineStyle(2, 0xffffff);
        player.drawCircle(0, 0, 12);
        
        player.x = screenPos.x;
        player.y = screenPos.y - 15;
        
        // Marcar como player para evitar duplicação
        player.userData = { isPlayer: true };
        
        // Label
        const label = new PIXI.Text('Vault Dweller', {
            fontFamily: 'Arial',
            fontSize: 11,
            fill: 0xffffff,
            stroke: 0x000000,
            strokeThickness: 2
        });
        label.anchor.set(0.5);
        label.y = 18;
        player.addChild(label);
        
        container.addChild(player);
        
        return player;
    }
}

// Exportar
window.FalloutMapRenderer = FalloutMapRenderer;

