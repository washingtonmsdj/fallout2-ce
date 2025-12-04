// ============================================
// GAME ENGINE - Fallout 2 Web Edition
// Sistema completo de jogo
// ============================================

class FalloutGameEngine {
    constructor(app) {
        this.app = app;
        this.currentMap = null;
        this.player = null;
        this.npcs = [];
        this.objects = [];
        this.quests = [];
        this.gameState = 'menu'; // menu, playing, paused, dialog
        this.maps = []; // Inicializar array de mapas
        
        // Inicializar
        this.init();
    }
    
    init() {
        // Criar player
        this.player = {
            x: 0,
            y: 0,
            tileX: 0,
            tileY: 0,
            hp: 100,
            maxHp: 100,
            ap: 10,
            maxAp: 10,
            level: 1,
            name: "Vault Dweller",
            sprite: null
        };
        
        // Carregar dados (async não bloqueia)
        this.loadQuests();
        this.loadMaps().catch(err => {
            console.warn('Erro ao carregar mapas:', err);
        });
    }
    
    async loadMaps() {
        try {
            const response = await fetch('/assets/web/maps/index.json');
            if (response.ok) {
                const data = await response.json();
                this.maps = data.maps || [];
            } else {
                // Fallback: mapas padrão se arquivo não existir
                console.warn('Arquivo de mapas não encontrado, usando mapas padrão');
                this.maps = [
                    { name: 'Arroyo', file: 'arroyo.json', desc: 'Vila inicial' },
                    { name: 'Klamath', file: 'klamath.json', desc: 'Cidade de Klamath' },
                    { name: 'Den', file: 'den.json', desc: 'A Den' },
                    { name: 'Modoc', file: 'modoc.json', desc: 'Modoc' },
                    { name: 'Vault City', file: 'vaultcity.json', desc: 'Vault City' }
                ];
            }
        } catch (error) {
            console.warn('Erro ao carregar mapas, usando fallback:', error);
            // Fallback: mapas padrão
            this.maps = [
                { name: 'Arroyo', file: 'arroyo.json', desc: 'Vila inicial' },
                { name: 'Klamath', file: 'klamath.json', desc: 'Cidade de Klamath' },
                { name: 'Den', file: 'den.json', desc: 'A Den' },
                { name: 'Modoc', file: 'modoc.json', desc: 'Modoc' },
                { name: 'Vault City', file: 'vaultcity.json', desc: 'Vault City' }
            ];
        }
    }
    
    loadQuests() {
        this.quests = [
            {
                id: 1,
                title: 'Encontrar o G.E.C.K.',
                description: 'Você precisa encontrar o G.E.C.K. para salvar sua vila de Arroyo.',
                status: 'active',
                location: 'Arroyo',
                objectives: [
                    { text: 'Falar com o Elder', completed: false },
                    { text: 'Encontrar pistas sobre o G.E.C.K.', completed: false },
                    { text: 'Localizar o G.E.C.K.', completed: false }
                ]
            },
            {
                id: 2,
                title: 'Explorar o Mundo',
                description: 'Explore o mundo pós-apocalíptico e descubra novos locais.',
                status: 'active',
                location: 'Worldmap',
                objectives: [
                    { text: 'Visitar Klamath', completed: false },
                    { text: 'Visitar Den', completed: false },
                    { text: 'Visitar Modoc', completed: false }
                ]
            },
            {
                id: 3,
                title: 'Ajudar Klamath',
                description: 'Ajude os habitantes de Klamath com seus problemas.',
                status: 'available',
                location: 'Klamath',
                objectives: [
                    { text: 'Falar com o prefeito', completed: false },
                    { text: 'Resolver problemas da cidade', completed: false }
                ]
            }
        ];
    }
    
    startNewGame() {
        this.gameState = 'playing';
        this.loadMap(this.maps[0] || { name: 'Arroyo', desc: 'Vila inicial' });
        // Player é renderizado pelo mapRenderer, não precisa criar aqui
    }
    
    async loadMap(mapData) {
        this.currentMap = mapData;
        
        // Limpar stage
        this.app.stage.removeChildren();
        
        // Criar container do mapa
        this.mapContainer = new PIXI.Container();
        this.app.stage.addChild(this.mapContainer);
        
        // Usar EMULADOR COMPLETO se disponível
        if (typeof Fallout2Emulator !== 'undefined') {
            if (!this.emulator) {
                this.emulator = new Fallout2Emulator(this.app);
            }
            
            // Obter nome do mapa
            let mapName = 'ARROYO';
            if (mapData.file) {
                mapName = mapData.file.replace('.json', '').replace('.map', '').toUpperCase();
            } else if (mapData.name) {
                mapName = mapData.name.toUpperCase();
            }
            
            // Carregar mapa completo
            try {
                await this.emulator.loadMap(mapName);
                await this.emulator.renderMap(this.mapContainer);
                console.log('✅ Mapa carregado e renderizado completamente');
            } catch (error) {
                console.error('Erro ao carregar mapa no emulador:', error);
                // Fallback para renderizador antigo
                if (typeof FalloutMapRenderer !== 'undefined') {
                    if (!this.mapRenderer) {
                        this.mapRenderer = new FalloutMapRenderer(this.app);
                        await this.mapRenderer.initAssets();
                    }
                    this.mapRenderer.renderMap(this.mapContainer, mapData);
                }
            }
        } else if (typeof FalloutMapRenderer !== 'undefined') {
            // Fallback para renderizador
            if (!this.mapRenderer) {
                this.mapRenderer = new FalloutMapRenderer(this.app);
                await this.mapRenderer.initAssets();
            }
            
            let realMapData = mapData.mapData || mapData;
            
            if (!realMapData.tiles && typeof MapParser !== 'undefined') {
                try {
                    const mapParser = new MapParser();
                    const mapName = mapData.file ? mapData.file.replace('.json', '').replace('.map', '') : 'ARROYO';
                    realMapData = await mapParser.loadMap(mapName);
                } catch (error) {
                    console.warn('Erro ao carregar mapa real:', error);
                }
            }
            
            this.mapRenderer.renderMap(this.mapContainer, realMapData);
        } else {
            console.warn('Nenhum renderizador disponível, usando fallback');
            this.renderMap();
            this.createPlayer();
        }
    }
    
    renderMap() {
        // Fundo com gradiente
        const bg = new PIXI.Graphics();
        bg.beginFill(0x0d1117);
        bg.drawRect(0, 0, this.app.screen.width, this.app.screen.height);
        bg.endFill();
        this.mapContainer.addChild(bg);
        
        // Camada de tiles (chão)
        this.renderTiles();
        
        // Grid isométrico (simulado)
        this.drawIsometricGrid();
        
        // Objetos do mapa
        this.renderObjects();
        
        // NPCs
        this.renderNPCs();
        
        // Título do mapa
        const title = new PIXI.Text(this.currentMap.name, {
            fontFamily: 'Arial',
            fontSize: 32,
            fill: 0x4a9eff,
            fontWeight: 'bold',
            stroke: 0x000000,
            strokeThickness: 4
        });
        title.x = this.app.screen.width / 2 - title.width / 2;
        title.y = 30;
        this.mapContainer.addChild(title);
    }
    
    renderTiles() {
        // Renderizar tiles do chão
        const tileSize = 50;
        const offsetX = this.app.screen.width / 2;
        const offsetY = 150;
        
        // Criar alguns tiles visíveis
        for (let i = -8; i < 8; i++) {
            for (let j = -8; j < 8; j++) {
                // Coordenadas isométricas
                const isoX = (i - j) * (tileSize / 2);
                const isoY = (i + j) * (tileSize / 4);
                
                const x = offsetX + isoX;
                const y = offsetY + isoY;
                
                // Criar tile
                const tile = new PIXI.Graphics();
                
                // Cor baseada na posição (efeito de variação)
                const color = (i + j) % 2 === 0 ? 0x1a1a2e : 0x161b22;
                tile.beginFill(color);
                
                // Desenhar losango (tile isométrico)
                tile.moveTo(x, y - tileSize / 2);
                tile.lineTo(x + tileSize / 2, y);
                tile.lineTo(x, y + tileSize / 2);
                tile.lineTo(x - tileSize / 2, y);
                tile.lineTo(x, y - tileSize / 2);
                tile.endFill();
                
                // Borda sutil
                tile.lineStyle(1, 0x30363d, 0.3);
                tile.moveTo(x, y - tileSize / 2);
                tile.lineTo(x + tileSize / 2, y);
                tile.lineTo(x, y + tileSize / 2);
                tile.lineTo(x - tileSize / 2, y);
                tile.lineTo(x, y - tileSize / 2);
                
                this.mapContainer.addChild(tile);
            }
        }
    }
    
    renderObjects() {
        // Adicionar alguns objetos ao mapa
        const objects = [
            { x: 300, y: 200, type: 'tree', color: 0x2d5016 },
            { x: 500, y: 250, type: 'rock', color: 0x4a4a4a },
            { x: 200, y: 300, type: 'tree', color: 0x2d5016 },
            { x: 600, y: 180, type: 'building', color: 0x6b4423 },
            { x: 150, y: 150, type: 'rock', color: 0x4a4a4a },
            { x: 700, y: 350, type: 'tree', color: 0x2d5016 },
        ];
        
        objects.forEach(obj => {
            const sprite = new PIXI.Graphics();
            
            if (obj.type === 'tree') {
                // Árvore
                sprite.beginFill(obj.color);
                sprite.drawCircle(0, 0, 15);
                sprite.endFill();
                sprite.beginFill(0x1a5c1a);
                sprite.drawCircle(0, -5, 12);
                sprite.endFill();
            } else if (obj.type === 'rock') {
                // Pedra
                sprite.beginFill(obj.color);
                sprite.drawCircle(0, 0, 10);
                sprite.endFill();
            } else if (obj.type === 'building') {
                // Construção
                sprite.beginFill(obj.color);
                sprite.drawRect(-15, -20, 30, 25);
                sprite.endFill();
                sprite.lineStyle(2, 0x8b4513);
                sprite.drawRect(-15, -20, 30, 25);
            }
            
            sprite.x = obj.x;
            sprite.y = obj.y;
            this.mapContainer.addChild(sprite);
        });
    }
    
    renderNPCs() {
        // Adicionar alguns NPCs
        const npcs = [
            { x: 400, y: 250, name: 'Elder', color: 0xff6b6b },
            { x: 250, y: 200, name: 'Villager', color: 0x4ecdc4 },
            { x: 550, y: 300, name: 'Guard', color: 0xffd93d },
        ];
        
        npcs.forEach(npc => {
            const sprite = new PIXI.Graphics();
            sprite.beginFill(npc.color);
            sprite.drawCircle(0, 0, 12);
            sprite.endFill();
            sprite.lineStyle(2, 0xffffff);
            sprite.drawCircle(0, 0, 12);
            
            sprite.x = npc.x;
            sprite.y = npc.y;
            
            // Label
            const label = new PIXI.Text(npc.name, {
                fontFamily: 'Arial',
                fontSize: 10,
                fill: 0xffffff,
                stroke: 0x000000,
                strokeThickness: 2
            });
            label.anchor.set(0.5);
            label.y = 18;
            sprite.addChild(label);
            
            this.mapContainer.addChild(sprite);
            this.npcs.push({ sprite, ...npc });
        });
    }
    
    drawIsometricGrid() {
        // Grid agora é apenas visual, tiles são renderizados em renderTiles()
        const grid = new PIXI.Graphics();
        grid.lineStyle(1, 0x30363d, 0.2);
        
        const tileSize = 50;
        const offsetX = this.app.screen.width / 2;
        const offsetY = 150;
        
        // Apenas bordas dos tiles
        for (let i = -8; i < 8; i++) {
            for (let j = -8; j < 8; j++) {
                const isoX = (i - j) * (tileSize / 2);
                const isoY = (i + j) * (tileSize / 4);
                const x = offsetX + isoX;
                const y = offsetY + isoY;
                
                grid.moveTo(x, y - tileSize / 2);
                grid.lineTo(x + tileSize / 2, y);
                grid.lineTo(x, y + tileSize / 2);
                grid.lineTo(x - tileSize / 2, y);
                grid.lineTo(x, y - tileSize / 2);
            }
        }
        
        this.mapContainer.addChild(grid);
    }
    
    createPlayer() {
        // Se mapRenderer está ativo, não criar player aqui (já é renderizado pelo mapRenderer)
        if (this.mapRenderer) {
            return;
        }
        
        // Fallback apenas se mapRenderer não estiver disponível
        if (this.player.sprite && this.mapContainer) {
            try {
                this.mapContainer.removeChild(this.player.sprite);
            } catch(e) {
                // Ignorar se não existir
            }
        }
        
        // Criar sprite do player
        const player = new PIXI.Graphics();
        player.beginFill(0x4a9eff);
        player.drawCircle(0, 0, 15);
        player.endFill();
        
        // Borda
        player.lineStyle(2, 0xffffff);
        player.drawCircle(0, 0, 15);
        
        // Marcar como player
        player.userData = { isPlayer: true };
        
        // Posicionar no centro
        player.x = this.app.screen.width / 2;
        player.y = this.app.screen.height / 2;
        
        this.player.sprite = player;
        if (this.mapContainer) {
            this.mapContainer.addChild(player);
        }
        
        // Adicionar label
        const label = new PIXI.Text(this.player.name, {
            fontFamily: 'Arial',
            fontSize: 12,
            fill: 0xffffff,
            stroke: 0x000000,
            strokeThickness: 2
        });
        label.anchor.set(0.5);
        label.y = 25;
        player.addChild(label);
    }
    
    updatePlayerPosition(x, y) {
        if (this.player.sprite) {
            this.player.sprite.x = x;
            this.player.sprite.y = y;
            this.player.x = x;
            this.player.y = y;
        }
    }
    
    getQuest(id) {
        return this.quests.find(q => q.id === id);
    }
    
    updateQuest(id, updates) {
        const quest = this.getQuest(id);
        if (quest) {
            Object.assign(quest, updates);
        }
    }
    
    completeQuestObjective(questId, objectiveIndex) {
        const quest = this.getQuest(questId);
        if (quest && quest.objectives[objectiveIndex]) {
            quest.objectives[objectiveIndex].completed = true;
        }
    }
}

// Exportar para uso global
window.FalloutGameEngine = FalloutGameEngine;

