// ============================================
// GAME EMULATOR - Emulador Completo do Fallout 2
// Carrega TODOS os assets e funciona como o jogo original
// ============================================

class Fallout2Emulator {
    constructor(app) {
        this.app = app;
        this.mapParser = new MapParser();
        this.frmLoader = new FRMLoader();
        this.assetsManager = new AssetsManager();
        
        // Estado do jogo
        this.currentMap = null;
        this.currentMapData = null;
        this.objects = [];
        this.npcs = [];
        this.items = [];
        this.scenery = [];
        this.tiles = [];
        
        // Containers
        this.mapContainer = null;
        this.objectsContainer = null;
        this.npcsContainer = null;
        this.playerContainer = null;
        
        // Cache
        this.spriteCache = new Map();
        this.mapCache = new Map();
        
        // Inicializar
        this.init();
    }
    
    async init() {
        console.log('🎮 Inicializando Emulador Fallout 2...');
        
        // Carregar assets
        await this.assetsManager.loadAllAssets();
        
        console.log('✅ Assets carregados');
    }
    
    // Carregar mapa completo (como o jogo original)
    async loadMap(mapName) {
        console.log(`🗺️ Carregando mapa: ${mapName}`);
        
        try {
            // Carregar mapa
            const mapData = await this.mapParser.loadMap(mapName);
            
            if (!mapData) {
                throw new Error(`Mapa ${mapName} não encontrado`);
            }
            
            this.currentMap = mapName;
            this.currentMapData = mapData;
            
            // Extrair dados
            this.tiles = mapData.tiles || [];
            this.objects = mapData.objects || [];
            this.npcs = mapData.npcs || [];
            this.items = mapData.items || [];
            this.scenery = mapData.scenery || [];
            
            console.log(`✅ Mapa carregado: ${mapData.name}`);
            console.log(`   - Tiles: ${this.tiles[0]?.length || 0}`);
            console.log(`   - Objetos: ${this.objects.length}`);
            console.log(`   - NPCs: ${this.npcs.length}`);
            console.log(`   - Items: ${this.items.length}`);
            console.log(`   - Scenery: ${this.scenery.length}`);
            
            return mapData;
        } catch (error) {
            console.error(`❌ Erro ao carregar mapa ${mapName}:`, error);
            throw error;
        }
    }
    
    // Renderizar mapa completo (como o jogo original)
    async renderMap(container) {
        if (!this.currentMapData) {
            throw new Error('Nenhum mapa carregado');
        }
        
        console.log('🎨 Renderizando mapa completo...');
        
        // Limpar containers
        container.removeChildren();
        
        // Criar containers por camada
        this.mapContainer = new PIXI.Container();
        this.objectsContainer = new PIXI.Container();
        this.npcsContainer = new PIXI.Container();
        this.playerContainer = new PIXI.Container();
        
        container.addChild(this.mapContainer);
        container.addChild(this.objectsContainer);
        container.addChild(this.npcsContainer);
        container.addChild(this.playerContainer);
        
        // CAMADA 1: Tiles (chão)
        await this.renderTiles();
        
        // CAMADA 2: Scenery (objetos de cenário)
        await this.renderScenery();
        
        // CAMADA 3: Items (itens no chão)
        await this.renderItems();
        
        // CAMADA 4: NPCs
        await this.renderNPCs();
        
        // CAMADA 5: Player
        await this.renderPlayer();
        
        console.log('✅ Mapa renderizado completamente');
    }
    
    // Renderizar tiles (chão)
    async renderTiles() {
        if (!this.tiles || this.tiles.length === 0) {
            console.warn('Nenhum tile para renderizar');
            return;
        }
        
        const elevation = 0; // Elevação atual
        const elevationTiles = this.tiles[elevation] || [];
        
        if (elevationTiles.length === 0) {
            console.warn('Nenhum tile na elevação 0');
            return;
        }
        
        const SQUARE_GRID_WIDTH = 100;
        const SQUARE_GRID_HEIGHT = 100;
        
        // Renderizar tiles visíveis
        const centerX = 50;
        const centerY = 50;
        const viewRange = 40; // Aumentar range para ver mais
        
        console.log(`Renderizando tiles: range ${viewRange}, total tiles: ${elevationTiles.length}`);
        
        let tilesRendered = 0;
        for (let y = Math.max(0, centerY - viewRange); y < Math.min(SQUARE_GRID_HEIGHT, centerY + viewRange); y++) {
            for (let x = Math.max(0, centerX - viewRange); x < Math.min(SQUARE_GRID_WIDTH, centerX + viewRange); x++) {
                const squareTile = y * SQUARE_GRID_WIDTH + x;
                
                if (squareTile >= 0 && squareTile < elevationTiles.length) {
                    const tileData = elevationTiles[squareTile];
                    
                    if (tileData) {
                        await this.renderTile(squareTile, tileData);
                        tilesRendered++;
                    }
                }
            }
        }
        
        console.log(`✅ ${tilesRendered} tiles renderizados`);
    }
    
    // Renderizar tile individual
    async renderTile(squareTile, tileData) {
        // Converter squareTile para coordenadas de tela
        const screenPos = this.squareTileToScreenXY(squareTile);
        
        // Tentar carregar sprite real
        const floorFID = tileData.floor;
        const frmId = floorFID & 0xFFF;
        
        // Se FID é 0 ou inválido, usar tile padrão
        if (frmId === 0 || frmId > 1000) {
            // Usar gráfico padrão
            const tile = new PIXI.Graphics();
            tile.beginFill(0x3a5a3a);
            tile.drawPolygon([0, -12, 24, 0, 0, 12, -24, 0]);
            tile.endFill();
            tile.x = screenPos.x;
            tile.y = screenPos.y;
            this.mapContainer.addChild(tile);
            return;
        }
        
        try {
            // Tentar diferentes nomes de tiles
            const tileNames = [
                `grid${String(frmId).padStart(3, '0')}.FRM`,
                `GRID${String(frmId).padStart(3, '0')}.FRM`,
                `grid${frmId}.FRM`
            ];
            
            let textures = null;
            for (const spriteName of tileNames) {
                const spritePath = `/assets/organized/sprites/tiles/${spriteName}`;
                
                // Verificar cache
                if (this.spriteCache.has(spritePath)) {
                    textures = this.spriteCache.get(spritePath);
                    break;
                }
                
                try {
                    textures = await this.frmLoader.loadFRM(spritePath);
                    this.spriteCache.set(spritePath, textures);
                    break;
                } catch (error) {
                    // Tentar próximo nome
                    continue;
                }
            }
            
            if (textures && textures.length > 0) {
                const sprite = new PIXI.Sprite(textures[0]);
                sprite.x = screenPos.x;
                sprite.y = screenPos.y;
                sprite.anchor.set(0.5);
                this.mapContainer.addChild(sprite);
                return;
            }
        } catch (error) {
            // Fallback para gráfico
        }
        
        // Fallback: gráfico colorido baseado no FID
        const tile = new PIXI.Graphics();
        const color = this.getTileColorFromFID(frmId);
        tile.beginFill(color);
        tile.drawPolygon([0, -12, 24, 0, 0, 12, -24, 0]);
        tile.endFill();
        tile.x = screenPos.x;
        tile.y = screenPos.y;
        this.mapContainer.addChild(tile);
    }
    
    // Obter cor do tile baseado no FID
    getTileColorFromFID(frmId) {
        // Cores baseadas em FIDs comuns
        if (frmId === 1) return 0x3a5a3a; // Grama
        if (frmId >= 2 && frmId <= 10) return 0x4a6a4a; // Grama variada
        if (frmId >= 11 && frmId <= 20) return 0x5a4a3a; // Terra
        if (frmId >= 21 && frmId <= 30) return 0x4a4a4a; // Pedra
        if (frmId >= 31 && frmId <= 40) return 0x2a4a6a; // Água
        return 0x3a5a3a; // Padrão: grama
    }
    
    // Renderizar scenery (objetos de cenário)
    async renderScenery() {
        console.log(`Renderizando ${this.scenery.length} objetos de cenário...`);
        for (const obj of this.scenery) {
            await this.renderObject(obj, this.objectsContainer);
        }
        console.log(`✅ ${this.scenery.length} objetos de cenário renderizados`);
    }
    
    // Renderizar items
    async renderItems() {
        console.log(`Renderizando ${this.items.length} itens...`);
        for (const item of this.items) {
            await this.renderObject(item, this.objectsContainer);
        }
        console.log(`✅ ${this.items.length} itens renderizados`);
    }
    
    // Renderizar NPCs
    async renderNPCs() {
        console.log(`Renderizando ${this.npcs.length} NPCs...`);
        for (const npc of this.npcs) {
            await this.renderNPC(npc);
        }
        console.log(`✅ ${this.npcs.length} NPCs renderizados`);
    }
    
    // Renderizar objeto genérico
    async renderObject(obj, container) {
        const screenPos = this.tileToScreenXY(obj.tile);
        
        // Tentar carregar sprite real baseado no FID
        try {
            const sprite = await this.loadObjectSprite(obj.fid);
            if (sprite) {
                sprite.x = screenPos.x;
                sprite.y = screenPos.y - 20;
                container.addChild(sprite);
                return;
            }
        } catch (error) {
            console.debug(`Sprite não encontrado para objeto FID ${obj.fid.toString(16)}`);
        }
        
        // Fallback: gráfico
        const graphic = new PIXI.Graphics();
        graphic.beginFill(0x666666);
        graphic.drawCircle(0, 0, 8);
        graphic.endFill();
        graphic.x = screenPos.x;
        graphic.y = screenPos.y - 20;
        container.addChild(graphic);
    }
    
    // Renderizar NPC
    async renderNPC(npc) {
        const screenPos = this.tileToScreenXY(npc.tile);
        
        // Tentar carregar sprite real
        try {
            const sprite = await this.loadCritterSprite(npc.fid);
            if (sprite) {
                sprite.x = screenPos.x;
                sprite.y = screenPos.y - 15;
                this.npcsContainer.addChild(sprite);
                
                // Adicionar nome se disponível
                if (npc.name) {
                    const label = new PIXI.Text(npc.name, {
                        fontFamily: 'Arial',
                        fontSize: 10,
                        fill: 0xffffff
                    });
                    label.anchor.set(0.5);
                    label.y = 20;
                    sprite.addChild(label);
                }
                return;
            }
        } catch (error) {
            console.debug(`Sprite não encontrado para NPC FID ${npc.fid.toString(16)}`);
        }
        
        // Fallback: gráfico
        const graphic = new PIXI.Graphics();
        graphic.beginFill(0xff6b6b);
        graphic.drawCircle(0, 0, 10);
        graphic.endFill();
        graphic.x = screenPos.x;
        graphic.y = screenPos.y - 15;
        this.npcsContainer.addChild(graphic);
    }
    
    // Renderizar player
    async renderPlayer() {
        const enteringTile = this.currentMapData.enteringTile || 20000;
        const screenPos = this.tileToScreenXY(enteringTile);
        
        // Tentar carregar sprite do player
        try {
            const playerFID = 0x01000001; // FID padrão do player
            const sprite = await this.loadCritterSprite(playerFID);
            if (sprite) {
                sprite.x = screenPos.x;
                sprite.y = screenPos.y - 15;
                this.playerContainer.addChild(sprite);
                return;
            }
        } catch (error) {
            console.debug('Sprite do player não encontrado');
        }
        
        // Fallback: gráfico
        const player = new PIXI.Graphics();
        player.beginFill(0x4a9eff);
        player.drawCircle(0, 0, 12);
        player.endFill();
        player.lineStyle(2, 0xffffff);
        player.drawCircle(0, 0, 12);
        player.x = screenPos.x;
        player.y = screenPos.y - 15;
        this.playerContainer.addChild(player);
    }
    
    // Carregar sprite de objeto baseado em FID
    async loadObjectSprite(fid) {
        const objType = (fid >> 24) & 0xFF;
        const frmId = fid & 0xFFFFFF;
        
        // Determinar caminho baseado no tipo
        let spritePath = null;
        
        if (objType === 3) { // OBJ_TYPE_SCENERY
            spritePath = `/assets/organized/sprites/scenery/scenery_${frmId}.FRM`;
        } else if (objType === 2) { // OBJ_TYPE_ITEM
            spritePath = `/assets/organized/sprites/items/item_${frmId}.FRM`;
        }
        
        if (spritePath && !this.spriteCache.has(spritePath)) {
            try {
                const textures = await this.frmLoader.loadFRM(spritePath);
                this.spriteCache.set(spritePath, textures);
            } catch (error) {
                return null;
            }
        }
        
        const textures = this.spriteCache.get(spritePath);
        if (textures && textures.length > 0) {
            return new PIXI.Sprite(textures[0]);
        }
        
        return null;
    }
    
    // Carregar sprite de critter baseado em FID
    async loadCritterSprite(fid) {
        const frmId = fid & 0xFFFFFF;
        
        // Tentar diferentes nomes de critters
        const critterNames = [
            `hmwarrda.frm`, // Player comum
            `critter_${frmId}.frm`,
            `npc_${frmId}.frm`
        ];
        
        for (const name of critterNames) {
            const spritePath = `/assets/organized/sprites/critters/${name}`;
            
            if (!this.spriteCache.has(spritePath)) {
                try {
                    const textures = await this.frmLoader.loadFRM(spritePath);
                    this.spriteCache.set(spritePath, textures);
                } catch (error) {
                    continue;
                }
            }
            
            const textures = this.spriteCache.get(spritePath);
            if (textures && textures.length > 0) {
                return new PIXI.Sprite(textures[0]);
            }
        }
        
        return null;
    }
    
    // Converter squareTile para coordenadas de tela
    squareTileToScreenXY(squareTile) {
        const SQUARE_GRID_WIDTH = 100;
        const v5 = SQUARE_GRID_WIDTH - 1 - (squareTile % SQUARE_GRID_WIDTH);
        const v6 = Math.floor(squareTile / SQUARE_GRID_WIDTH);
        
        const centerSquare = { x: 50, y: 50 };
        const offset = {
            x: Math.floor((this.app.screen.width - 32) / 2) - 16,
            y: Math.floor((this.app.screen.height - 16) / 2) - 2
        };
        
        let screenX = offset.x;
        let screenY = offset.y;
        
        const v8 = v5 - centerSquare.x;
        screenX += 48 * v8;
        screenY -= 12 * v8;
        
        const v9 = v6 - centerSquare.y;
        screenX += 32 * v9;
        screenY += 24 * v9;
        
        return { x: screenX, y: screenY };
    }
    
    // Converter tile para coordenadas de tela
    tileToScreenXY(tile) {
        const HEX_GRID_WIDTH = 200;
        const v3 = HEX_GRID_WIDTH - 1 - (tile % HEX_GRID_WIDTH);
        const v4 = Math.floor(tile / HEX_GRID_WIDTH);
        
        const centerTile = { x: 100, y: 100 };
        const offset = {
            x: Math.floor((this.app.screen.width - 32) / 2),
            y: Math.floor((this.app.screen.height - 16) / 2)
        };
        
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
}

// Exportar
window.Fallout2Emulator = Fallout2Emulator;

