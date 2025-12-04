// ============================================
// MEU PRIMEIRO JOGO - Exemplo Completo
// Criado no Cursor - SEM engine necessária!
// ============================================

// Configuração do Canvas
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

// Estado do Jogo
const game = {
    running: true,
    paused: false,
    score: 0,
    level: 1,
    keys: {},
    
    // Player
    player: {
        x: 100,
        y: 300,
        width: 50,
        height: 50,
        speed: 5,
        color: '#4a9eff',
        health: 100
    },
    
    // Inimigos
    enemies: [],
    enemySpawnTimer: 0,
    enemySpawnRate: 120, // frames
    
    // Projéteis
    bullets: [],
    
    // Partículas
    particles: []
};

// ============================================
// INPUT
// ============================================

document.addEventListener('keydown', (e) => {
    const key = e.key.toLowerCase();
    game.keys[key] = true;
    
    // Pausar com ESC
    if (key === 'escape') {
        game.paused = !game.paused;
    }
    
    // Atirar com Espaço
    if (key === ' ' && !game.paused) {
        shoot();
    }
});

document.addEventListener('keyup', (e) => {
    game.keys[e.key.toLowerCase()] = false;
});

// ============================================
// FUNÇÕES DO JOGO
// ============================================

function shoot() {
    game.bullets.push({
        x: game.player.x + game.player.width,
        y: game.player.y + game.player.height / 2,
        width: 10,
        height: 5,
        speed: 10,
        color: '#ffd700'
    });
}

function spawnEnemy() {
    game.enemies.push({
        x: canvas.width,
        y: Math.random() * (canvas.height - 50),
        width: 40,
        height: 40,
        speed: 2 + game.level * 0.5,
        color: '#ff4444',
        health: 1
    });
}

function createParticle(x, y, color) {
    for (let i = 0; i < 5; i++) {
        game.particles.push({
            x: x,
            y: y,
            vx: (Math.random() - 0.5) * 4,
            vy: (Math.random() - 0.5) * 4,
            life: 30,
            maxLife: 30,
            color: color,
            size: Math.random() * 3 + 2
        });
    }
}

// ============================================
// UPDATE (Lógica do Jogo)
// ============================================

function update() {
    if (game.paused) return;
    
    const p = game.player;
    
    // Movimento do Player
    if (game.keys['w'] || game.keys['arrowup']) {
        p.y = Math.max(0, p.y - p.speed);
    }
    if (game.keys['s'] || game.keys['arrowdown']) {
        p.y = Math.min(canvas.height - p.height, p.y + p.speed);
    }
    if (game.keys['a'] || game.keys['arrowleft']) {
        p.x = Math.max(0, p.x - p.speed);
    }
    if (game.keys['d'] || game.keys['arrowright']) {
        p.x = Math.min(canvas.width - p.width, p.x + p.speed);
    }
    
    // Spawn de Inimigos
    game.enemySpawnTimer++;
    if (game.enemySpawnTimer >= game.enemySpawnRate) {
        spawnEnemy();
        game.enemySpawnTimer = 0;
        // Aumentar dificuldade
        game.enemySpawnRate = Math.max(60, game.enemySpawnRate - 2);
    }
    
    // Atualizar Projéteis
    game.bullets = game.bullets.filter(bullet => {
        bullet.x += bullet.speed;
        
        // Colisão com inimigos
        for (let i = game.enemies.length - 1; i >= 0; i--) {
            const enemy = game.enemies[i];
            if (bullet.x < enemy.x + enemy.width &&
                bullet.x + bullet.width > enemy.x &&
                bullet.y < enemy.y + enemy.height &&
                bullet.y + bullet.height > enemy.y) {
                
                // Hit!
                createParticle(enemy.x + enemy.width/2, enemy.y + enemy.height/2, enemy.color);
                game.enemies.splice(i, 1);
                game.score += 10;
                
                // Aumentar nível a cada 100 pontos
                game.level = Math.floor(game.score / 100) + 1;
                
                return false; // Remover projétil
            }
        }
        
        return bullet.x < canvas.width; // Remover se sair da tela
    });
    
    // Atualizar Inimigos
    game.enemies = game.enemies.filter(enemy => {
        enemy.x -= enemy.speed;
        
        // Colisão com player
        if (enemy.x < p.x + p.width &&
            enemy.x + enemy.width > p.x &&
            enemy.y < p.y + p.height &&
            enemy.y + enemy.height > p.y) {
            
            // Dano no player
            game.player.health -= 10;
            createParticle(p.x + p.width/2, p.y + p.height/2, p.color);
            
            if (game.player.health <= 0) {
                game.running = false;
            }
            
            return false; // Remover inimigo
        }
        
        return enemy.x > -enemy.width; // Remover se sair da tela
    });
    
    // Atualizar Partículas
    game.particles = game.particles.filter(particle => {
        particle.x += particle.vx;
        particle.y += particle.vy;
        particle.life--;
        return particle.life > 0;
    });
}

// ============================================
// RENDER (Desenhar)
// ============================================

function draw() {
    // Limpar tela
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    // Desenhar grade de fundo
    ctx.strokeStyle = '#1a1a2e';
    ctx.lineWidth = 1;
    for (let x = 0; x < canvas.width; x += 50) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, canvas.height);
        ctx.stroke();
    }
    for (let y = 0; y < canvas.height; y += 50) {
        ctx.beginPath();
        ctx.moveTo(0, y);
        ctx.lineTo(canvas.width, y);
        ctx.stroke();
    }
    
    // Desenhar Player
    ctx.fillStyle = game.player.color;
    ctx.fillRect(game.player.x, game.player.y, game.player.width, game.player.height);
    
    // Desenhar Projéteis
    game.bullets.forEach(bullet => {
        ctx.fillStyle = bullet.color;
        ctx.fillRect(bullet.x, bullet.y, bullet.width, bullet.height);
    });
    
    // Desenhar Inimigos
    game.enemies.forEach(enemy => {
        ctx.fillStyle = enemy.color;
        ctx.fillRect(enemy.x, enemy.y, enemy.width, enemy.height);
    });
    
    // Desenhar Partículas
    game.particles.forEach(particle => {
        const alpha = particle.life / particle.maxLife;
        ctx.fillStyle = particle.color + Math.floor(alpha * 255).toString(16).padStart(2, '0');
        ctx.beginPath();
        ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2);
        ctx.fill();
    });
    
    // UI
    ctx.fillStyle = '#fff';
    ctx.font = '20px Arial';
    ctx.fillText(`Score: ${game.score}`, 10, 30);
    ctx.fillText(`Level: ${game.level}`, 10, 60);
    ctx.fillText(`Health: ${game.player.health}`, 10, 90);
    
    // Barra de vida
    const barWidth = 200;
    const barHeight = 20;
    ctx.fillStyle = '#333';
    ctx.fillRect(canvas.width - barWidth - 10, 10, barWidth, barHeight);
    ctx.fillStyle = game.player.health > 50 ? '#4a9eff' : '#ff4444';
    ctx.fillRect(canvas.width - barWidth - 10, 10, (game.player.health / 100) * barWidth, barHeight);
    ctx.strokeStyle = '#fff';
    ctx.lineWidth = 2;
    ctx.strokeRect(canvas.width - barWidth - 10, 10, barWidth, barHeight);
    
    // Pausa
    if (game.paused) {
        ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = '#fff';
        ctx.font = '48px Arial';
        ctx.textAlign = 'center';
        ctx.fillText('PAUSADO', canvas.width / 2, canvas.height / 2);
        ctx.textAlign = 'left';
    }
    
    // Game Over
    if (!game.running) {
        ctx.fillStyle = 'rgba(0, 0, 0, 0.8)';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = '#ff4444';
        ctx.font = '48px Arial';
        ctx.textAlign = 'center';
        ctx.fillText('GAME OVER', canvas.width / 2, canvas.height / 2 - 50);
        ctx.fillStyle = '#fff';
        ctx.font = '24px Arial';
        ctx.fillText(`Score Final: ${game.score}`, canvas.width / 2, canvas.height / 2 + 20);
        ctx.fillText('Recarregue a página para jogar novamente', canvas.width / 2, canvas.height / 2 + 60);
        ctx.textAlign = 'left';
    }
}

// ============================================
// GAME LOOP
// ============================================

function gameLoop() {
    if (game.running) {
        update();
    }
    draw();
    requestAnimationFrame(gameLoop);
}

// ============================================
// INICIAR JOGO
// ============================================

console.log('🎮 Jogo iniciado!');
gameLoop();

