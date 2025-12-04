// ============================================
// FRM LOADER - Carrega sprites .FRM reais do Fallout 2
// Sistema profissional para carregar assets reais
// ============================================

class FRMLoader {
    constructor() {
        this.cache = new Map();
        this.basePath = '/assets/organized/sprites/';
    }
    
    // Carregar sprite FRM e converter para PIXI.Texture
    async loadFRM(frmPath) {
        // Verificar cache
        if (this.cache.has(frmPath)) {
            return this.cache.get(frmPath);
        }
        
        try {
            // Carregar arquivo FRM
            const response = await fetch(frmPath);
            if (!response.ok) {
                throw new Error(`Failed to load FRM: ${frmPath}`);
            }
            
            const arrayBuffer = await response.arrayBuffer();
            const data = new Uint8Array(arrayBuffer);
            
            // Parse FRM
            const frmData = this.parseFRM(data);
            
            // Converter para PIXI.Texture
            const textures = this.convertToPIXITextures(frmData);
            
            // Cache
            this.cache.set(frmPath, textures);
            
            return textures;
        } catch (error) {
            console.error(`Erro ao carregar FRM ${frmPath}:`, error);
            // Retornar sprite placeholder
            return this.createPlaceholderSprite();
        }
    }
    
    // Parse formato FRM (baseado em FORMATO_FRM.md)
    parseFRM(data) {
        const view = new DataView(data.buffer);
        let offset = 0;
        
        // Header FRM (80 bytes total)
        const field_0 = view.getUint32(offset, true); offset += 4;
        const framesPerSecond = view.getUint16(offset, true); offset += 2;
        const actionFrame = view.getUint16(offset, true); offset += 2;
        const frameCount = view.getUint16(offset, true); offset += 2;
        
        // X offsets (12 bytes - 6 direções)
        const xOffsets = [];
        for (let i = 0; i < 6; i++) {
            xOffsets.push(view.getInt16(offset, true));
            offset += 2;
        }
        
        // Y offsets (12 bytes - 6 direções)
        const yOffsets = [];
        for (let i = 0; i < 6; i++) {
            yOffsets.push(view.getInt16(offset, true));
            offset += 2;
        }
        
        // Data offsets (24 bytes - 6 direções)
        const dataOffsets = [];
        for (let i = 0; i < 6; i++) {
            dataOffsets.push(view.getUint32(offset, true));
            offset += 4;
        }
        
        // Padding (24 bytes)
        offset += 24;
        
        // Data size (4 bytes)
        const dataSize = view.getUint32(offset, true);
        
        // Parse frames de cada direção
        const frames = [];
        for (let dir = 0; dir < 6; dir++) {
            if (dataOffsets[dir] === 0) continue; // Direção não tem dados
            
            const directionFrames = [];
            let frameOffset = dataOffsets[dir];
            
            for (let frame = 0; frame < frameCount; frame++) {
                const frameData = this.parseFrame(data, frameOffset);
                frameData.direction = dir;
                frameData.frame = frame;
                frameData.xOffset = xOffsets[dir];
                frameData.yOffset = yOffsets[dir];
                
                directionFrames.push(frameData);
                frames.push(frameData);
                
                // Próximo frame: header (12 bytes) + dados
                frameOffset += 12 + frameData.size;
            }
        }
        
        return {
            field_0,
            framesPerSecond,
            actionFrame,
            frameCount,
            xOffsets,
            yOffsets,
            dataOffsets,
            dataSize,
            frames
        };
    }
    
    // Parse frame individual (baseado em FORMATO_FRM.md - ArtFrame)
    parseFrame(data, offset) {
        const view = new DataView(data.buffer);
        
        // Frame header (12 bytes)
        const width = view.getUint16(offset, true); offset += 2;
        const height = view.getUint16(offset, true); offset += 2;
        const size = view.getUint32(offset, true); offset += 4;
        const x = view.getInt16(offset, true); offset += 2;
        const y = view.getInt16(offset, true); offset += 2;
        
        // Dados de pixel começam após o header
        const pixelDataOffset = offset;
        const pixelData = new Uint8Array(data, pixelDataOffset, size);
        
        return {
            width,
            height,
            size,
            x, // Hotspot X
            y, // Hotspot Y
            pixelData,
            offset: pixelDataOffset
        };
    }
    
    // Converter frame para PIXI.Texture
    convertToPIXITextures(frmData) {
        const textures = [];
        
        for (const frame of frmData.frames) {
            // Descomprimir RLE
            const pixels = this.decompressRLE(frame.pixelData, frame.width, frame.height);
            
            // Criar canvas
            const canvas = document.createElement('canvas');
            canvas.width = frame.width;
            canvas.height = frame.height;
            const ctx = canvas.getContext('2d');
            const imageData = ctx.createImageData(frame.width, frame.height);
            
            // Converter para RGBA usando palette do Fallout 2
            // Por enquanto, usar cores simples
            for (let i = 0; i < pixels.length; i++) {
                const paletteIndex = pixels[i];
                const rgba = this.getPaletteColor(paletteIndex);
                
                imageData.data[i * 4] = rgba.r;
                imageData.data[i * 4 + 1] = rgba.g;
                imageData.data[i * 4 + 2] = rgba.b;
                imageData.data[i * 4 + 3] = paletteIndex === 0 ? 0 : 255; // Transparente se índice 0
            }
            
            ctx.putImageData(imageData, 0, 0);
            
            // Criar PIXI.Texture
            const texture = PIXI.Texture.from(canvas);
            textures.push(texture);
        }
        
        return textures;
    }
    
    // Descomprimir RLE (Run-Length Encoding)
    decompressRLE(data, width, height) {
        const pixels = new Uint8Array(width * height);
        let pixelIndex = 0;
        let dataIndex = 0;
        
        while (pixelIndex < pixels.length && dataIndex < data.length) {
            const byte = data[dataIndex++];
            
            if (byte === 0) {
                // Transparente
                pixels[pixelIndex++] = 0;
            } else if (byte < 0x80) {
                // Literal
                pixels[pixelIndex++] = byte;
            } else {
                // RLE: repetir próximo byte (byte - 0x80) vezes
                const count = byte - 0x80;
                const value = data[dataIndex++];
                for (let i = 0; i < count && pixelIndex < pixels.length; i++) {
                    pixels[pixelIndex++] = value;
                }
            }
        }
        
        return pixels;
    }
    
    // Obter cor da palette (simplificado - usar palette real depois)
    getPaletteColor(index) {
        // Palette básica do Fallout 2 (primeiras cores)
        const basicPalette = [
            {r: 0, g: 0, b: 0},       // 0 - Transparente
            {r: 255, g: 255, b: 255}, // 1 - Branco
            {r: 128, g: 128, b: 128}, // 2 - Cinza
            {r: 255, g: 0, b: 0},     // 3 - Vermelho
            {r: 0, g: 255, b: 0},     // 4 - Verde
            {r: 0, g: 0, b: 255},     // 5 - Azul
        ];
        
        if (index < basicPalette.length) {
            return basicPalette[index];
        }
        
        // Cor padrão
        return {r: 128, g: 128, b: 128};
    }
    
    // Criar sprite placeholder
    createPlaceholderSprite() {
        const graphics = new PIXI.Graphics();
        graphics.beginFill(0x666666);
        graphics.drawRect(0, 0, 32, 32);
        graphics.endFill();
        
        const texture = PIXI.RenderTexture.create({width: 32, height: 32});
        return [texture];
    }
}

// Exportar
window.FRMLoader = FRMLoader;

