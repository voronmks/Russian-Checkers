// checkers.swift
import Foundation

let SIZE = 8
let EMPTY = 0, WHITE = 1, BLACK = 2, WHITE_KING = 3, BLACK_KING = 4

class Checkers {
    var board = [[Int]](repeating: [Int](repeating: EMPTY, count: SIZE), count: SIZE)
    var turn = WHITE

    init() {
        initBoard()
    }

    func initBoard() {
        for r in 0..<3 {
            for c in 0..<SIZE {
                if (r + c) % 2 == 1 {
                    board[r][c] = BLACK
                }
            }
        }
        for r in 5..<8 {
            for c in 0..<SIZE {
                if (r + c) % 2 == 1 {
                    board[r][c] = WHITE
                }
            }
        }
    }

    func isWhite(_ p: Int) -> Bool { p == WHITE || p == WHITE_KING }
    func isBlack(_ p: Int) -> Bool { p == BLACK || p == BLACK_KING }
    func isKing(_ p: Int) -> Bool { p == WHITE_KING || p == BLACK_KING }
    func opponent(_ p: Int) -> Int { isWhite(p) ? BLACK : WHITE }

    func inBounds(_ r: Int, _ c: Int) -> Bool {
        return r >= 0 && r < SIZE && c >= 0 && c < SIZE
    }

    func getPiece(_ r: Int, _ c: Int) -> Int {
        return inBounds(r, c) ? board[r][c] : EMPTY
    }

    func isEnemy(_ r: Int, _ c: Int, _ piece: Int) -> Bool {
        let p = getPiece(r, c)
        if p == EMPTY { return false }
        if isWhite(piece) && isBlack(p) { return true }
        if isBlack(piece) && isWhite(p) { return true }
        return false
    }

    func canCapture(_ r: Int, _ c: Int, _ dr: Int, _ dc: Int) -> Bool {
        let nr = r + dr, nc = c + dc
        if !inBounds(nr, nc) { return false }
        if getPiece(nr, nc) == EMPTY { return false }
        if !isEnemy(nr, nc, board[r][c]) { return false }
        let lr = r + 2*dr, lc = c + 2*dc
        if !inBounds(lr, lc) { return false }
        if getPiece(lr, lc) != EMPTY { return false }
        return true
    }

    func captureMovesFrom(_ r: Int, _ c: Int) -> [(Int, Int)] {
        let piece = board[r][c]
        var dirs = [(-1,-1), (-1,1), (1,-1), (1,1)]
        if !isKing(piece) {
            if isWhite(piece) { dirs = [(-1,-1), (-1,1)] }
            else { dirs = [(1,-1), (1,1)] }
        }
        var moves = [(Int, Int)]()
        for (dr, dc) in dirs {
            if canCapture(r, c, dr, dc) {
                moves.append((r + 2*dr, c + 2*dc))
            }
        }
        return moves
    }

    func simpleMovesFrom(_ r: Int, _ c: Int) -> [(Int, Int)] {
        let piece = board[r][c]
        var dirs = [(-1,-1), (-1,1), (1,-1), (1,1)]
        if !isKing(piece) {
            if isWhite(piece) { dirs = [(-1,-1), (-1,1)] }
            else { dirs = [(1,-1), (1,1)] }
        }
        var moves = [(Int, Int)]()
        for (dr, dc) in dirs {
            let nr = r + dr, nc = c + dc
            if inBounds(nr, nc) && getPiece(nr, nc) == EMPTY {
                moves.append((nr, nc))
            }
        }
        return moves
    }

    func hasCaptures(_ color: Int) -> Bool {
        for r in 0..<SIZE {
            for c in 0..<SIZE {
                let p = board[r][c]
                if p == EMPTY { continue }
                if color == WHITE && !isWhite(p) { continue }
                if color == BLACK && !isBlack(p) { continue }
                if !captureMovesFrom(r, c).isEmpty { return true }
            }
        }
        return false
    }

    func legalMovesFrom(_ r: Int, _ c: Int) -> [(Int, Int)] {
        let piece = board[r][c]
        if piece == EMPTY { return [] }
        if isWhite(piece) && turn != WHITE { return [] }
        if isBlack(piece) && turn != BLACK { return [] }
        if hasCaptures(turn) {
            return captureMovesFrom(r, c)
        }
        return simpleMovesFrom(r, c)
    }

    func applyMove(_ fr: Int, _ fc: Int, _ tr: Int, _ tc: Int) -> Bool {
        let piece = board[fr][fc]
        if piece == EMPTY { return false }
        let dr = tr - fr, dc = tc - fc
        if abs(dr) == 2 && abs(dc) == 2 {
            let cr = fr + dr/2, cc = fc + dc/2
            if getPiece(cr, cc) == EMPTY { return false }
            board[cr][cc] = EMPTY
        }
        board[tr][tc] = piece
        board[fr][fc] = EMPTY
        if !isKing(piece) {
            if isWhite(piece) && tr == 0 {
                board[tr][tc] = WHITE_KING
            } else if isBlack(piece) && tr == SIZE-1 {
                board[tr][tc] = BLACK_KING
            }
        }
        turn = opponent(piece)
        return true
    }

    func winner() -> Int {
        var white = 0, black = 0
        for r in 0..<SIZE {
            for c in 0..<SIZE {
                let p = board[r][c]
                if isWhite(p) { white += 1 }
                else if isBlack(p) { black += 1 }
            }
        }
        if white == 0 { return BLACK }
        if black == 0 { return WHITE }
        return EMPTY
    }

    func display() {
        print("\u{001B}[2J", terminator: "")
        print("  a b c d e f g h")
        for r in 0..<SIZE {
            print("\(r+1) ", terminator: "")
            for c in 0..<SIZE {
                let p = board[r][c]
                let ch: Character
                switch p {
                case EMPTY: ch = "."
                case WHITE: ch = "w"
                case BLACK: ch = "b"
                case WHITE_KING: ch = "W"
                case BLACK_KING: ch = "B"
                default: ch = "?"
                }
                print("\(ch) ", terminator: "")
            }
            print("\(r+1)")
        }
        print("  a b c d e f g h")
        print("Turn: \(turn == WHITE ? "White" : "Black")")
    }

    func parseMove(_ str: String) -> (Int, Int, Int, Int)? {
        let parts = str.split(separator: "-")
        if parts.count != 2 { return nil }
        let from = String(parts[0]), to = String(parts[1])
        if from.count != 2 || to.count != 2 { return nil }
        let fc = Int(from.unicodeScalars.first!.value) - 97
        let fr = Int(String(from.last!))! - 1
        let tc = Int(to.unicodeScalars.first!.value) - 97
        let tr = Int(String(to.last!))! - 1
        if fr < 0 || fr >= SIZE || fc < 0 || fc >= SIZE || tr < 0 || tr >= SIZE || tc < 0 || tc >= SIZE {
            return nil
        }
        return (fr, fc, tr, tc)
    }

    func playerMove() -> Bool {
        while true {
            display()
            let color = turn == WHITE ? "White" : "Black"
            print("\(color), enter move (e.g., a3-b4) or 'q' to quit: ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else { continue }
            if input == "q" { return false }
            if input == "u" { print("Undo not implemented."); continue }
            guard let (fr, fc, tr, tc) = parseMove(input) else {
                print("Invalid format.")
                continue
            }
            let piece = board[fr][fc]
            if piece == EMPTY { print("No piece there."); continue }
            if (isWhite(piece) && turn != WHITE) || (isBlack(piece) && turn != BLACK) {
                print("Not your turn.")
                continue
            }
            let legal = legalMovesFrom(fr, fc)
            if !legal.contains(where: { $0.0 == tr && $0.1 == tc }) {
                print("Illegal move.")
                continue
            }
            if !applyMove(fr, fc, tr, tc) {
                print("Move failed.")
                continue
            }
            let w = winner()
            if w != EMPTY {
                display()
                print(w == WHITE ? "White wins!" : "Black wins!")
                return false
            }
            return true
        }
    }

    func aiMove() -> Bool {
        var moves = [(Int, Int, Int, Int)]()
        for r in 0..<SIZE {
            for c in 0..<SIZE {
                let p = board[r][c]
                if p == EMPTY { continue }
                if (isWhite(p) && turn != WHITE) || (isBlack(p) && turn != BLACK) { continue }
                let legal = legalMovesFrom(r, c)
                for (tr, tc) in legal {
                    moves.append((r, c, tr, tc))
                }
            }
        }
        if moves.isEmpty { print("AI has no moves."); return false }
        let move = moves.randomElement()!
        applyMove(move.0, move.1, move.2, move.3)
        let w = winner()
        if w != EMPTY {
            display()
            print(w == WHITE ? "White wins!" : "Black wins!")
            return false
        }
        return true
    }
}

let game = Checkers()
print("Russian Checkers")
print("Controls: enter moves as 'a3-b4'. 'q' to quit.")
while true {
    if game.turn == WHITE {
        if !game.playerMove() { break }
    } else {
        if !game.aiMove() { break }
    }
}
