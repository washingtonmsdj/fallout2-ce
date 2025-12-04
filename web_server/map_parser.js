// ============================================
// MAP PARSER - Carrega mapas .MAP reais do Fallout 2
// Sistema profissional para carregar mapas reais
// ============================================

class MapParser {
    constructor() {
        this.basePath = '/assets/organized/maps/';
    }
    
    // Carregar mapa .MAP
    async loadMap(mapName) {
        try {
            const mapPath = `${this.basePath}${mapName}.map`;
            const response = await fetch(mapPath);
            
            if (!response.ok) {
                // Tentar com maiúsculas
                const mapPathUpper = `${this.basePath}${mapName.toUpperCase()}.MAP`;
                const responseUpper = await fetch(mapPathUpper);
                if (!responseUpper.ok) {
                    throw new Error(`Mapa não encontrado: ${mapName}`);
                }
                return await this.parseMap(await responseUpper.arrayBuffer());
            }
            
            return await this.parseMap(await response.arrayBuffer());
        } catch (error) {
            console.error(`Erro ao carregar mapa ${mapName}:`, error);
            return this.createDefaultMap();
        }
    }
    
    // Parse formato .MAP
    async parseMap(arrayBuffer) {
        const view = new DataView(arrayBuffer);
        let offset = 0;
        
        // Header (64 bytes)
        const version = view.getUint32(offset, true); offset += 4;
        
        // Nome do mapa (16 bytes)
        const nameBytes = new Uint8Array(arrayBuffer, offset, 16);
        const name = this.readString(nameBytes);
        offset += 16;
        
        // Tile de entrada
        const enteringTile = view.getUint32(offset, true); offset += 4;
        const enteringElevation = view.getUint32(offset, true); offset += 4;
        const enteringRotation = view.getUint32(offset, true); offset += 4;
        
        // Variáveis locais
        const localVarsCount = view.getUint32(offset, true); offset += 4;
        const scriptIndex = view.getUint32(offset, true); offset += 4;
        const flags = view.getUint32(offset, true); offset += 4;
        const darkness = view.getUint32(offset, true); offset += 4;
        const globalVarsCount = view.getUint32(offset, true); offset += 4;
        const mapIndex = view.getUint32(offset, true); offset += 4;
        const lastVisitTime = view.getUint32(offset, true); offset += 4;
        
        // Pular campos extras (44 bytes)
        offset += 44;
        
        // Ler variáveis globais
        const globalVars = [];
        for (let i = 0; i < globalVarsCount; i++) {
            globalVars.push(view.getUint32(offset, true));
            offset += 4;
        }
        
        // Ler variáveis locais
        const localVars = [];
        for (let i = 0; i < localVarsCount; i++) {
            localVars.push(view.getUint32(offset, true));
            offset += 4;
        }
        
        // Ler tiles (SQUARE_GRID_SIZE = 10000 tiles por elevação)
        const SQUARE_GRID_SIZE = 100 * 100;
        const ELEVATION_COUNT = 3;
        const tiles = [];
        
        for (let elev = 0; elev < ELEVATION_COUNT; elev++) {
            const elevationTiles = [];
            for (let i = 0; i < SQUARE_GRID_SIZE; i++) {
                const floorFID = view.getUint32(offset, true); offset += 4;
                const roofFID = view.getUint32(offset, true); offset += 4;
                elevationTiles.push({
                    floor: floorFID,
                    roof: roofFID
                });
            }
            tiles.push(elevationTiles);
        }
        
        // Ler objetos do mapa
        // Baseado EXATAMENTE em: objectLoadAllInternal (object.cc:474)
        const objects = [];
        
        // Ler contagem total de objetos
        if (offset + 4 >= arrayBuffer.byteLength) {
            console.warn('Fim do arquivo antes de ler objetos');
        } else {
            const totalObjectCount = view.getUint32(offset, true);
            offset += 4;
            
            // Ler objetos por elevação (3 elevações)
            // Baseado em: for (int elevation = 0; elevation < ELEVATION_COUNT; elevation++)
            for (let elev = 0; elev < 3 && offset < arrayBuffer.byteLength; elev++) {
                if (offset + 4 >= arrayBuffer.byteLength) break;
                
                const objectsAtElevation = view.getUint32(offset, true);
                offset += 4;
                
                // Ler objetos desta elevação
                // Baseado em: objectRead (object.cc:412)
                for (let i = 0; i < objectsAtElevation && offset + 60 < arrayBuffer.byteLength; i++) {
                    try {
                        const obj = {
                            // objectRead estrutura completa (76 bytes + objectData)
                            id: view.getUint32(offset, true), offset += 4,
                            tile: view.getUint32(offset, true), offset += 4,
                            x: view.getInt32(offset, true), offset += 4,
                            y: view.getInt32(offset, true), offset += 4,
                            sx: view.getInt32(offset, true), offset += 4,
                            sy: view.getInt32(offset, true), offset += 4,
                            frame: view.getUint32(offset, true), offset += 4,
                            rotation: view.getUint32(offset, true), offset += 4,
                            fid: view.getUint32(offset, true), offset += 4,
                            flags: view.getUint32(offset, true), offset += 4,
                            elevation: elev, // Usar elevação atual
                            pid: view.getUint32(offset, true), offset += 4,
                            cid: view.getUint32(offset, true), offset += 4,
                            lightDistance: view.getUint32(offset, true), offset += 4,
                            lightIntensity: view.getUint32(offset, true), offset += 4,
                            field_74: view.getUint32(offset, true), offset += 4,
                            sid: view.getUint32(offset, true), offset += 4,
                            scriptIndex: view.getUint32(offset, true), offset += 4,
                        };
                        
                        // Calcular tileX e tileY
                        obj.tileX = obj.tile % 200;
                        obj.tileY = Math.floor(obj.tile / 200);
                        
                        // Determinar tipo baseado no FID
                        const objType = (obj.fid >> 24) & 0xFF;
                        if (objType === 1) { // OBJ_TYPE_CRITTER
                            obj.type = 'critter';
                            obj.isNPC = true;
                        } else if (objType === 2) { // OBJ_TYPE_ITEM
                            obj.type = 'item';
                        } else if (objType === 3) { // OBJ_TYPE_SCENERY
                            obj.type = 'scenery';
                        } else {
                            obj.type = 'unknown';
                        }
                        
                        objects.push(obj);
                        
                        // Pular objectData (tamanho variável baseado no tipo)
                        // objectDataRead lê dados baseados no tipo do objeto
                        // Por enquanto, pular (será implementado depois)
                        // A estrutura objectData varia muito baseado no tipo
                        
                    } catch (error) {
                        console.warn(`Erro ao ler objeto ${i} na elevação ${elev}:`, error);
                        // Continuar tentando ler outros objetos
                        // Não quebrar completamente se um objeto falhar
                        if (offset + 60 >= arrayBuffer.byteLength) {
                            break; // Fim do arquivo
                        }
                    }
                }
            }
        }
        
        console.log(`✅ ${objects.length} objetos carregados do mapa`);
        
        // Separar NPCs dos objetos
        const npcs = objects.filter(obj => obj.isNPC);
        const items = objects.filter(obj => obj.type === 'item');
        const scenery = objects.filter(obj => obj.type === 'scenery');
        
        return {
            version,
            name,
            enteringTile,
            enteringElevation,
            enteringRotation,
            localVars,
            globalVars,
            scriptIndex,
            flags,
            darkness,
            mapIndex,
            tiles,
            objects: objects, // Todos os objetos
            npcs: npcs, // Apenas NPCs
            items: items, // Apenas itens
            scenery: scenery // Apenas cenário
        };
    }
    
    // Ler string null-terminated
    readString(bytes) {
        let str = '';
        for (let i = 0; i < bytes.length; i++) {
            if (bytes[i] === 0) break;
            str += String.fromCharCode(bytes[i]);
        }
        return str;
    }
    
    // Criar mapa padrão
    createDefaultMap() {
        return {
            name: 'Arroyo',
            version: 20,
            enteringTile: 20000,
            enteringElevation: 0,
            enteringRotation: 0,
            localVars: [],
            globalVars: [],
            scriptIndex: 0,
            flags: 0,
            darkness: 0,
            mapIndex: 0,
            tiles: [],
            objects: [],
            npcs: []
        };
    }
}

// Exportar
window.MapParser = MapParser;

