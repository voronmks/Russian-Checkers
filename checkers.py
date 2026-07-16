# checkers.py
import os
import copy
import random
import sys

SIZE = 8
EMPTY = 0
WHITE = 1
BLACK = 2
WHITE_KING = 3
BLACK_KING = 4

class Checkers:
    def __init__(self):
        self.board = [[EMPTY]*SIZE for _ in range(SIZE)]
        self.turn = WHITE
        self.selected = None
        self.valid_moves = []
        self.must_capture = False
        self.move_history = []
        self._init_board()
        self._find_all_captures()

    def _init_board(self):
        for row in range(3):
            for col in range(SIZE):
                if (row + col) % 2 == 1:
                    self.board[row][col] = BLACK
        for row in range(5, 8):
            for col in range(SIZE):
                if (row + col) % 2 == 1:
                    self.board[row][col] = WHITE

    def _is_king(self, piece):
        return piece in (WHITE_KING, BLACK_KING)

    def _is_white(self, piece):
        return piece in (WHITE, WHITE_KING)

    def _is_black(self, piece):
        return piece in (BLACK, BLACK_KING)

    def _opponent(self, piece):
        if self._is_white(piece):
            return BLACK
        return WHITE

    def _in_bounds(self, r, c):
        return 0 <= r < SIZE and 0 <= c < SIZE

    def _get_piece(self, r, c):
        return self.board[r][c] if self._in_bounds(r, c) else EMPTY

    def _is_enemy(self, r, c, piece):
        p = self._get_piece(r, c)
        if p == EMPTY:
            return False
        if self._is_white(piece):
            return self._is_black(p)
        else:
            return self._is_white(p)

    def _can_capture(self, r, c, dr, dc):
        nr, nc = r + dr, c + dc
        if not self._in_bounds(nr, nc):
            return False
        if self._get_piece(nr, nc) == EMPTY:
            return False
        if not self._is_enemy(nr, nc, self.board[r][c]):
            return False
        land_r, land_c = r + 2*dr, c + 2*dc
        if not self._in_bounds(land_r, land_c):
            return False
        if self._get_piece(land_r, land_c) != EMPTY:
            return False
        return True

    def _capture_moves_from(self, r, c, visited=None):
        if visited is None:
            visited = set()
        piece = self.board[r][c]
        dirs = [(-1,-1), (-1,1), (1,-1), (1,1)]
        if self._is_king(piece):
            # kings can move in all diagonal directions
            dirs = [(-1,-1), (-1,1), (1,-1), (1,1)]
        moves = []
        for dr, dc in dirs:
            if self._can_capture(r, c, dr, dc):
                land_r, land_c = r + 2*dr, c + 2*dc
                # Check that this position hasn't been visited in this chain
                if (land_r, land_c) in visited:
                    continue
                # Perform capture on a copy to check further captures
                new_board = [row[:] for row in self.board]
                captured = new_board[r+dr][c+dc]
                new_board[land_r][land_c] = piece
                new_board[r][c] = EMPTY
                new_board[r+dr][c+dc] = EMPTY
                # Check if the captured piece was a king
                # Not needed for move validation but for multi-jump we'll handle in move execution
                # Append the move sequence
                # For simplicity, we'll just record the move and continue recursively
                # We'll store the sequence in a list
                # We'll implement the recursive search in the move function, not here.
                moves.append((land_r, land_c))
        return moves

    def _find_all_captures_for_color(self, color):
        captures = []
        for r in range(SIZE):
            for c in range(SIZE):
                p = self.board[r][c]
                if p == EMPTY:
                    continue
                if self._is_white(p) and color != WHITE:
                    continue
                if self._is_black(p) and color != BLACK:
                    continue
                # Check capture moves
                dirs = [(-1,-1), (-1,1), (1,-1), (1,1)]
                if self._is_king(p):
                    # King can capture in all diagonal directions
                    pass
                for dr, dc in dirs:
                    if self._can_capture(r, c, dr, dc):
                        captures.append((r, c))
                        break
        return captures

    def _find_all_moves_for_piece(self, r, c):
        piece = self.board[r][c]
        moves = []
        # Check captures first
        dirs = [(-1,-1), (-1,1), (1,-1), (1,1)]
        if self._is_king(piece):
            # kings can move both directions
            pass
        # Simple moves (non-capture)
        for dr, dc in dirs:
            nr, nc = r + dr, c + dc
            if self._in_bounds(nr, nc) and self._get_piece(nr, nc) == EMPTY:
                # Check if move direction is forward for non-kings
                if not self._is_king(piece):
                    if self._is_white(piece) and dr != -1:
                        continue
                    if self._is_black(piece) and dr != 1:
                        continue
                moves.append((nr, nc))
        return moves

    def _has_captures(self, color):
        captures = self._find_all_captures_for_color(color)
        return len(captures) > 0

    def _get_legal_moves(self, r, c):
        piece = self.board[r][c]
        if piece == EMPTY:
            return []
        if self._is_white(piece) and self.turn != WHITE:
            return []
        if self._is_black(piece) and self.turn != BLACK:
            return []
        # If there are mandatory captures, only capture moves are allowed
        if self._has_captures(self.turn):
            # Only return capture moves for this piece
            return self._capture_moves_from(r, c)
        else:
            return self._find_all_moves_for_piece(r, c)

    def _is_winner(self):
        # Check if any player has no pieces left
        white_pieces = 0
        black_pieces = 0
        for r in range(SIZE):
            for c in range(SIZE):
                p = self.board[r][c]
                if self._is_white(p):
                    white_pieces += 1
                elif self._is_black(p):
                    black_pieces += 1
        if white_pieces == 0:
            return BLACK
        if black_pieces == 0:
            return WHITE
        return None

    def apply_move(self, from_r, from_c, to_r, to_c):
        piece = self.board[from_r][from_c]
        if piece == EMPTY:
            return False
        # Check if it's a capture
        dr = to_r - from_r
        dc = to_c - from_c
        if abs(dr) == 2 and abs(dc) == 2:
            # Capture move
            captured_r = from_r + dr//2
            captured_c = from_c + dc//2
            if self._get_piece(captured_r, captured_c) == EMPTY:
                return False
            # Remove captured piece
            self.board[captured_r][captured_c] = EMPTY
        # Move the piece
        self.board[to_r][to_c] = piece
        self.board[from_r][from_c] = EMPTY
        # Check promotion
        if not self._is_king(piece):
            if self._is_white(piece) and to_r == 0:
                self.board[to_r][to_c] = WHITE_KING
            elif self._is_black(piece) and to_r == SIZE-1:
                self.board[to_r][to_c] = BLACK_KING
        # Switch turn
        self.turn = self._opponent(piece)  # Actually opponent color
        # For simplicity, we'll just switch the turn color
        if self.turn == WHITE:
            self.turn = BLACK
        else:
            self.turn = WHITE
        return True

    def undo_move(self):
        # Not fully implemented for demo
        pass

    def display(self):
        os.system('cls' if os.name == 'nt' else 'clear')
        print("  a b c d e f g h")
        for r in range(SIZE):
            print(f"{r+1} ", end='')
            for c in range(SIZE):
                p = self.board[r][c]
                if p == EMPTY:
                    ch = '.'
                elif p == WHITE:
                    ch = 'w'
                elif p == BLACK:
                    ch = 'b'
                elif p == WHITE_KING:
                    ch = 'W'
                elif p == BLACK_KING:
                    ch = 'B'
                print(ch, end=' ')
            print(f"{r+1}")
        print("  a b c d e f g h")
        print(f"Turn: {'White' if self.turn == WHITE else 'Black'}")

    def parse_move(self, move_str):
        # Expect format like 'a3-b4'
        try:
            parts = move_str.split('-')
            if len(parts) != 2:
                return None
            from_sq = parts[0].strip()
            to_sq = parts[1].strip()
            from_col = ord(from_sq[0]) - ord('a')
            from_row = int(from_sq[1]) - 1
            to_col = ord(to_sq[0]) - ord('a')
            to_row = int(to_sq[1]) - 1
            if not (0 <= from_row < SIZE and 0 <= from_col < SIZE and
                    0 <= to_row < SIZE and 0 <= to_col < SIZE):
                return None
            return (from_row, from_col, to_row, to_col)
        except:
            return None

    def player_move(self):
        while True:
            self.display()
            move_str = input(f"{'White' if self.turn == WHITE else 'Black'}, enter move (e.g., a3-b4) or 'q' to quit: ").strip()
            if move_str.lower() == 'q':
                return False
            if move_str.lower() == 'u':
                # Undo not implemented in demo
                print("Undo not available.")
                continue
            parsed = self.parse_move(move_str)
            if parsed is None:
                print("Invalid format. Use e.g., a3-b4")
                continue
            fr, fc, tr, tc = parsed
            piece = self.board[fr][fc]
            if piece == EMPTY:
                print("No piece at source.")
                continue
            if self._is_white(piece) and self.turn != WHITE:
                print("It's not your turn.")
                continue
            if self._is_black(piece) and self.turn != BLACK:
                print("It's not your turn.")
                continue
            legal = self._get_legal_moves(fr, fc)
            if (tr, tc) not in legal:
                print("Illegal move.")
                continue
            # Apply move
            if not self.apply_move(fr, fc, tr, tc):
                print("Move failed.")
                continue
            # Check win
            winner = self._is_winner()
            if winner:
                self.display()
                print(f"{'White' if winner == WHITE else 'Black'} wins!")
                return False
            # If the capturing piece can continue capturing, the player must continue (multi-jump)
            # We'll handle this by checking if the piece that moved has more captures and if so, force the player to move again.
            # In our simple version, we'll just let the turn switch and the next player can move.
            # For simplicity, we'll skip multi-jump forcing for now.
            return True

    def ai_move(self):
        # Simple AI: find all legal moves and pick a random one
        moves = []
        for r in range(SIZE):
            for c in range(SIZE):
                p = self.board[r][c]
                if p == EMPTY:
                    continue
                if self._is_white(p) and self.turn != WHITE:
                    continue
                if self._is_black(p) and self.turn != BLACK:
                    continue
                legal = self._get_legal_moves(r, c)
                for tr, tc in legal:
                    moves.append((r, c, tr, tc))
        if not moves:
            print("No moves available.")
            return False
        # Random move
        move = random.choice(moves)
        fr, fc, tr, tc = move
        self.apply_move(fr, fc, tr, tc)
        winner = self._is_winner()
        if winner:
            self.display()
            print(f"{'White' if winner == WHITE else 'Black'} wins!")
            return False
        return True

def main():
    game = Checkers()
    print("Russian Checkers")
    print("Controls: enter moves as 'a3-b4'. 'q' to quit.")
    while True:
        if game.turn == WHITE:
            if not game.player_move():
                break
        else:
            if not game.ai_move():
                break
        # Check if game ended
        winner = game._is_winner()
        if winner:
            game.display()
            print(f"{'White' if winner == WHITE else 'Black'} wins!")
            break

if __name__ == "__main__":
    main()
