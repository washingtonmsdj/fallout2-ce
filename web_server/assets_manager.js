// ============================================
// ASSETS MANAGER - Gerenciador profissional de assets
// Sistema completo para carregar todos os assets do jogo
// ============================================

class AssetsManager {
    constructor() {
        this.frmLoader = new FRMLoader();
        this.mapParser = new MapParser();
        this.textureCache = new Map();
        this.mapCache = new Map();
        this.loadingProgress = 0;
    }
    
    // Carregar todos os assets necessários
    async loadAllAssets() {
        const assets = {
            tiles: [],
            critters: [],
            items: [],
            walls: [],
            scenery: [],
            interface: []
        };
        
        // Carregar tiles básicos
        assets.tiles = await this.loadTiles();
        
        // Carregar critters (NPCs)
        assets.critters = await this.loadCritters();
        
        // Carregar items
        assets.items = await this.loadItems();
        
        // Carregar walls
        assets.walls = await this.loadWalls();
        
        // Carregar scenery
        assets.scenery = await this.loadScenery();
        
        // Carregar interface
        assets.interface = await this.loadInterface();
        
        return assets;
    }
    
    // Carregar tiles
    async loadTiles() {
        const tiles = [];
        const tileFiles = [
            'grid000.FRM',
            'grid001.FRM',
            'grid002.FRM'
        ];
        
        for (const file of tileFiles) {
            try {
                const path = `/assets/organized/sprites/tiles/${file}`;
                const textures = await this.frmLoader.loadFRM(path);
                tiles.push({
                    name: file,
                    textures: textures
                });
            } catch (error) {
                console.warn(`Tile não encontrado: ${file}`);
            }
        }
        
        return tiles;
    }
    
    // Carregar critters (NPCs)
    async loadCritters() {
        const critters = [];
        
        // Lista de critters comuns do Fallout 2
        const critterFiles = [
            'hmwarrda.frm', // Vault Dweller (player)
            'hmwarrdb.frm',
            'hmwarrdc.frm',
            'hmwarrdd.frm',
            'hmwarrde.frm',
            'hmwarrdf.frm',
            'hmwarrdg.frm',
            'hmwarrdh.frm',
        ];
        
        for (const file of critterFiles) {
            try {
                const path = `/assets/organized/sprites/critters/${file}`;
                const textures = await this.frmLoader.loadFRM(path);
                critters.push({
                    name: file,
                    textures: textures
                });
            } catch (error) {
                // Ignorar se não encontrado
                console.debug(`Critter não encontrado: ${file}`);
            }
        }
        
        return critters;
    }
    
    // Carregar items
    async loadItems() {
        const items = [];
        // TODO: Carregar lista de items
        return items;
    }
    
    // Carregar walls
    async loadWalls() {
        const walls = [];
        // Carregar algumas walls básicas
        const wallFiles = [
            'YLF1000.FRM',
            'YLF1001.FRM',
            'YBK1000.FRM'
        ];
        
        for (const file of wallFiles) {
            try {
                const path = `/assets/organized/sprites/walls/${file}`;
                const textures = await this.frmLoader.loadFRM(path);
                walls.push({
                    name: file,
                    textures: textures
                });
            } catch (error) {
                console.warn(`Wall não encontrada: ${file}`);
            }
        }
        
        return walls;
    }
    
    // Carregar scenery
    async loadScenery() {
        const scenery = [];
        
        // Carregar alguns sprites de scenery comuns
        const sceneryFiles = [
            'tree01.frm',
            'rock01.frm',
            'bush01.frm'
        ];
        
        for (const file of sceneryFiles) {
            try {
                const path = `/assets/organized/sprites/scenery/${file}`;
                const textures = await this.frmLoader.loadFRM(path);
                scenery.push({
                    name: file,
                    textures: textures
                });
            } catch (error) {
                // Ignorar se não encontrado
                console.debug(`Scenery não encontrado: ${file}`);
            }
        }
        
        return scenery;
    }
    
    // Carregar interface
    async loadInterface() {
        const interface = [];
        // TODO: Carregar interface
        return interface;
    }
    
    // Carregar mapa específico
    async loadMap(mapName) {
        if (this.mapCache.has(mapName)) {
            return this.mapCache.get(mapName);
        }
        
        const map = await this.mapParser.loadMap(mapName);
        this.mapCache.set(mapName, map);
        return map;
    }
    
    // Obter texture de sprite
    getTexture(spriteName, direction = 0, frame = 0) {
        const key = `${spriteName}_${direction}_${frame}`;
        if (this.textureCache.has(key)) {
            return this.textureCache.get(key);
        }
        
        // Tentar carregar
        return null;
    }
}

// Exportar
window.AssetsManager = AssetsManager;

