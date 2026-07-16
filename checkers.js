// checkers.js
const readline = require('readline');
const { stdin, stdout } = process;

const SIZE = 8;
const EMPTY = 0, WHITE = 1, BLACK = 2, WHITE_KING = 3, BLACK_KING = 4;

class Checkers {
    constructor() {
        this.board = Array.from({length: SIZE}, () => Array(SIZE).fill(EMPTY));
        this.turn = WHITE;
        this.initBoard();
    }

    initBoard() {
        for (let r = 0; r < 3; r++) {
            for (let c = 0; c < SIZE; c++) {
                if ((r + c) % 2 === 1) this.board[r][c] = BLACK;
            }
        }
        for (let r = 5; r < 8; r++) {
            for (let c = 0; c < SIZE; c++) {
                if ((r + c) % 2 === 1) this.board[r][c] = WHITE;
            }
        }
    }

    isWhite(p) { return p === WHITE || p === WHITE_KING; }
    isBlack(p) { return p === BLACK || p === BLACK_KING; }
    isKing(p) { return p === WHITE_KING || p === BLACK_KING; }
    opponent(p) { return this.isWhite(p) ? BLACK : WHITE; }

    inBounds(r, c) { return r >= 0 && r < SIZE && c >= 0 && c < SIZE; }

    getPiece(r, c) { return this.inBounds(r, c) ? this.board[r][c] : EMPTY; }

    isEnemy(r, c, piece) {
        const p = this.getPiece(r, c);
        if (p === EMPTY) return false;
        if (this.isWhite(piece) && this.isBlack(p)) return true;
        if (this.isBlack(piece) && this.isWhite(p)) return true;
        return false;
    }

    canCapture(r, c, dr, dc) {
        const nr = r + dr, nc = c + dc;
        if (!this.inBounds(nr, nc)) return false;
        if (this.getPiece(nr, nc) === EMPTY) return false;
        if (!this.isEnemy(nr, nc, this.board[r][c])) return false;
        const lr = r + 2*dr, lc = c + 2*dc;
        if (!this.inBounds(lr, lc)) return false;
        if (this.getPiece(lr, lc) !== EMPTY) return false;
        return true;
    }

    captureMovesFrom(r, c) {
        const piece = this.board[r][c];
        let dirs = [[-1,-1], [-1,1], [1,-1], [1,1]];
        if (!this.isKing(piece)) {
            if (this.isWhite(piece)) dirs = [[-1,-1], [-1,1]];
            else dirs = [[1,-1], [1,1]];
        }
        const moves = [];
        for (const d of dirs) {
            if (this.canCapture(r, c, d[0], d[1])) {
                moves.push([r + 2*d[0], c + 2*d[1]]);
            }
        }
        return moves;
    }

    simpleMovesFrom(r, c) {
        const piece = this.board[r][c];
        let dirs = [[-1,-1], [-1,1], [1,-1], [1,1]];
        if (!this.isKing(piece)) {
            if (this.isWhite(piece)) dirs = [[-1,-1], [-1,1]];
            else dirs = [[1,-1], [1,1]];
        }
        const moves = [];
        for (const d of dirs) {
            const nr = r + d[0], nc = c + d[1];
            if (this.inBounds(nr, nc) && this.getPiece(nr, nc) === EMPTY) {
                moves.push([nr, nc]);
            }
        }
        return moves;
    }

    hasCaptures(color) {
        for (let r = 0; r < SIZE; r++) {
            for (let c = 0; c < SIZE; c++) {
                const p = this.board[r][c];
                if (p === EMPTY) continue;
                if (color === WHITE && !this.isWhite(p)) continue;
                if (color === BLACK && !this.isBlack(p)) continue;
                if (this.captureMovesFrom(r, c).length > 0) return true;
            }
        }
        return false;
    }

    legalMovesFrom(r, c) {
        const piece = this.board[r][c];
        if (piece === EMPTY) return [];
        if (this.isWhite(piece) && this.turn !== WHITE) return [];
        if (this.isBlack(piece) && this.turn !== BLACK) return [];
        if (this.hasCaptures(this.turn)) {
            return this.captureMovesFrom(r, c);
        }
        return this.simpleMovesFrom(r, c);
    }

    applyMove(fr, fc, tr, tc) {
        const piece = this.board[fr][fc];
        if (piece === EMPTY) return false;
        const dr = tr - fr, dc = tc - fc;
        if (Math.abs(dr) === 2 && Math.abs(dc) === 2) {
            const cr = fr + dr/2, cc = fc + dc/2;
            if (this.getPiece(cr, cc) === EMPTY) return false;
            this.board[cr][cc] = EMPTY;
        }
        this.board[tr][tc] = piece;
        this.board[fr][fc] = EMPTY;
        if (!this.isKing(piece)) {
            if (this.isWhite(piece) && tr === 0) this.board[tr][tc] = WHITE_KING;
            else if (this.isBlack(piece) && tr === SIZE-1) this.board[tr][tc] = BLACK_KING;
        }
        this.turn = this.opponent(piece);
        return true;
    }

    winner() {
        let w = 0, b = 0;
        for (let r = 0; r < SIZE; r++) {
            for (let c = 0; c < SIZE; c++) {
                const p = this.board[r][c];
                if (this.isWhite(p)) w++;
                else if (this.isBlack(p)) b++;
            }
        }
        if (w === 0) return BLACK;
        if (b === 0) return WHITE;
        return EMPTY;
    }

    display() {
        console.clear();
        console.log('  a b c d e f g h');
        for (let r = 0; r < SIZE; r++) {
            process.stdout.write(`${r+1} `);
            for (let c = 0; c < SIZE; c++) {
                const p = this.board[r][c];
                let ch;
                switch(p) {
                    case EMPTY: ch = '.'; break;
                    case WHITE: ch = 'w'; break;
                    case BLACK: ch = 'b'; break;
                    case WHITE_KING: ch = 'W'; break;
                    case BLACK_KING: ch = 'B'; break;
                }
                process.stdout.write(ch + ' ');
            }
            console.log(`${r+1}`);
        }
        console.log('  a b c d e f g h');
        console.log(`Turn: ${this.turn === WHITE ? 'White' : 'Black'}`);
    }
}

function parseMove(str) {
    const parts = str.split('-');
    if (parts.length !== 2) return null;
    const from = parts[0].trim(), to = parts[1].trim();
    if (from.length !== 2 || to.length !== 2) return null;
    const fc = from.charCodeAt(0) - 97;
    const fr = parseInt(from[1]) - 1;
    const tc = to.charCodeAt(0) - 97;
    const tr = parseInt(to[1]) - 1;
    if (fr < 0 || fr >= SIZE || fc < 0 || fc >= SIZE || tr < 0 || tr >= SIZE || tc < 0 || tc >= SIZE) return null;
    return {fr, fc, tr, tc};
}

const rl = readline.createInterface({ input: stdin, output: stdout });

function ask(question) {
    return new Promise(resolve => rl.question(question, resolve));
}

async function playerMove(game) {
    while (true) {
        game.display();
        const color = game.turn === WHITE ? 'White' : 'Black';
        const input = await ask(`${color}, enter move (e.g., a3-b4) or 'q' to quit: `);
        if (input === 'q') return false;
        if (input === 'u') { console.log('Undo not implemented.'); continue; }
        const parsed = parseMove(input);
        if (!parsed) { console.log('Invalid format.'); continue; }
        const {fr, fc, tr, tc} = parsed;
        const piece = game.board[fr][fc];
        if (piece === EMPTY) { console.log('No piece there.'); continue; }
        if ((game.isWhite(piece) && game.turn !== WHITE) || (game.isBlack(piece) && game.turn !== BLACK)) {
            console.log('Not your turn.');
            continue;
        }
        const legal = game.legalMovesFrom(fr, fc);
        if (!legal.some(m => m[0] === tr && m[1] === tc)) {
            console.log('Illegal move.');
            continue;
        }
        if (!game.applyMove(fr, fc, tr, tc)) {
            console.log('Move failed.');
            continue;
        }
        const w = game.winner();
        if (w !== EMPTY) {
            game.display();
            console.log(w === WHITE ? 'White wins!' : 'Black wins!');
            return false;
        }
        return true;
    }
}

function aiMove(game) {
    let moves = [];
    for (let r = 0; r < SIZE; r++) {
        for (let c = 0; c < SIZE; c++) {
            const p = game.board[r][c];
            if (p === EMPTY) continue;
            if ((game.isWhite(p) && game.turn !== WHITE) || (game.isBlack(p) && game.turn !== BLACK)) continue;
            const legal = game.legalMovesFrom(r, c);
            for (const m of legal) {
                moves.push([r, c, m[0], m[1]]);
            }
        }
    }
    if (moves.length === 0) { console.log('AI has no moves.'); return false; }
    const move = moves[Math.floor(Math.random() * moves.length)];
    const [fr, fc, tr, tc] = move;
    game.applyMove(fr, fc, tr, tc);
    const w = game.winner();
    if (w !== EMPTY) {
        game.display();
        console.log(w === WHITE ? 'White wins!' : 'Black wins!');
        return false;
    }
    return true;
}

async function main() {
    const game = new Checkers();
    console.log('Russian Checkers');
    console.log('Controls: enter moves as "a3-b4". "q" to quit.');
    while (true) {
        if (game.turn === WHITE) {
            if (!await playerMove(game)) break;
        } else {
            if (!await aiMove(game)) break;
        }
    }
    rl.close();
}

main().catch(console.error);
