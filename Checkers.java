// Checkers.java
import java.util.*;

public class Checkers {
    static final int SIZE = 8;
    static final int EMPTY = 0;
    static final int WHITE = 1;
    static final int BLACK = 2;
    static final int WHITE_KING = 3;
    static final int BLACK_KING = 4;

    int[][] board = new int[SIZE][SIZE];
    int turn = WHITE;
    Random rand = new Random();

    public Checkers() {
        initBoard();
    }

    void initBoard() {
        for (int r = 0; r < 3; r++)
            for (int c = 0; c < SIZE; c++)
                if ((r + c) % 2 == 1) board[r][c] = BLACK;
        for (int r = 5; r < 8; r++)
            for (int c = 0; c < SIZE; c++)
                if ((r + c) % 2 == 1) board[r][c] = WHITE;
    }

    boolean isWhite(int p) { return p == WHITE || p == WHITE_KING; }
    boolean isBlack(int p) { return p == BLACK || p == BLACK_KING; }
    boolean isKing(int p) { return p == WHITE_KING || p == BLACK_KING; }
    int opponent(int p) { return isWhite(p) ? BLACK : WHITE; }

    boolean inBounds(int r, int c) { return r >= 0 && r < SIZE && c >= 0 && c < SIZE; }
    int getPiece(int r, int c) { return inBounds(r, c) ? board[r][c] : EMPTY; }

    boolean isEnemy(int r, int c, int piece) {
        int p = getPiece(r, c);
        if (p == EMPTY) return false;
        if (isWhite(piece) && isBlack(p)) return true;
        if (isBlack(piece) && isWhite(p)) return true;
        return false;
    }

    boolean canCapture(int r, int c, int dr, int dc) {
        int nr = r + dr, nc = c + dc;
        if (!inBounds(nr, nc)) return false;
        if (getPiece(nr, nc) == EMPTY) return false;
        if (!isEnemy(nr, nc, board[r][c])) return false;
        int lr = r + 2*dr, lc = c + 2*dc;
        if (!inBounds(lr, lc)) return false;
        if (getPiece(lr, lc) != EMPTY) return false;
        return true;
    }

    List<int[]> captureMovesFrom(int r, int c) {
        int piece = board[r][c];
        int[][] dirs = {{-1,-1},{-1,1},{1,-1},{1,1}};
        if (!isKing(piece)) {
            if (isWhite(piece)) dirs = new int[][]{{-1,-1},{-1,1}};
            else dirs = new int[][]{{1,-1},{1,1}};
        }
        List<int[]> moves = new ArrayList<>();
        for (int[] d : dirs) {
            if (canCapture(r, c, d[0], d[1]))
                moves.add(new int[]{r + 2*d[0], c + 2*d[1]});
        }
        return moves;
    }

    List<int[]> simpleMovesFrom(int r, int c) {
        int piece = board[r][c];
        int[][] dirs = {{-1,-1},{-1,1},{1,-1},{1,1}};
        if (!isKing(piece)) {
            if (isWhite(piece)) dirs = new int[][]{{-1,-1},{-1,1}};
            else dirs = new int[][]{{1,-1},{1,1}};
        }
        List<int[]> moves = new ArrayList<>();
        for (int[] d : dirs) {
            int nr = r + d[0], nc = c + d[1];
            if (inBounds(nr, nc) && getPiece(nr, nc) == EMPTY)
                moves.add(new int[]{nr, nc});
        }
        return moves;
    }

    boolean hasCaptures(int color) {
        for (int r = 0; r < SIZE; r++)
            for (int c = 0; c < SIZE; c++) {
                int p = board[r][c];
                if (p == EMPTY) continue;
                if (color == WHITE && !isWhite(p)) continue;
                if (color == BLACK && !isBlack(p)) continue;
                if (!captureMovesFrom(r, c).isEmpty()) return true;
            }
        return false;
    }

    List<int[]> legalMovesFrom(int r, int c) {
        int piece = board[r][c];
        if (piece == EMPTY) return new ArrayList<>();
        if (isWhite(piece) && turn != WHITE) return new ArrayList<>();
        if (isBlack(piece) && turn != BLACK) return new ArrayList<>();
        if (hasCaptures(turn))
            return captureMovesFrom(r, c);
        return simpleMovesFrom(r, c);
    }

    boolean applyMove(int fr, int fc, int tr, int tc) {
        int piece = board[fr][fc];
        if (piece == EMPTY) return false;
        int dr = tr - fr, dc = tc - fc;
        if (Math.abs(dr) == 2 && Math.abs(dc) == 2) {
            int cr = fr + dr/2, cc = fc + dc/2;
            if (getPiece(cr, cc) == EMPTY) return false;
            board[cr][cc] = EMPTY;
        }
        board[tr][tc] = piece;
        board[fr][fc] = EMPTY;
        if (!isKing(piece)) {
            if (isWhite(piece) && tr == 0) board[tr][tc] = WHITE_KING;
            else if (isBlack(piece) && tr == SIZE-1) board[tr][tc] = BLACK_KING;
        }
        turn = opponent(piece);
        return true;
    }

    int winner() {
        int white = 0, black = 0;
        for (int r = 0; r < SIZE; r++)
            for (int c = 0; c < SIZE; c++) {
                int p = board[r][c];
                if (isWhite(p)) white++;
                else if (isBlack(p)) black++;
            }
        if (white == 0) return BLACK;
        if (black == 0) return WHITE;
        return EMPTY;
    }

    void display() {
        System.out.print("\033[H\033[2J");
        System.out.println("  a b c d e f g h");
        for (int r = 0; r < SIZE; r++) {
            System.out.print((r+1) + " ");
            for (int c = 0; c < SIZE; c++) {
                int p = board[r][c];
                char ch;
                switch (p) {
                    case EMPTY: ch = '.'; break;
                    case WHITE: ch = 'w'; break;
                    case BLACK: ch = 'b'; break;
                    case WHITE_KING: ch = 'W'; break;
                    case BLACK_KING: ch = 'B'; break;
                    default: ch = '?'; break;
                }
                System.out.print(ch + " ");
            }
            System.out.println((r+1));
        }
        System.out.println("  a b c d e f g h");
        System.out.println("Turn: " + (turn == WHITE ? "White" : "Black"));
    }

    int[] parseMove(String str) {
        String[] parts = str.split("-");
        if (parts.length != 2) return null;
        String from = parts[0].trim(), to = parts[1].trim();
        if (from.length() != 2 || to.length() != 2) return null;
        int fc = from.charAt(0) - 'a';
        int fr = from.charAt(1) - '1';
        int tc = to.charAt(0) - 'a';
        int tr = to.charAt(1) - '1';
        if (fr < 0 || fr >= SIZE || fc < 0 || fc >= SIZE || tr < 0 || tr >= SIZE || tc < 0 || tc >= SIZE)
            return null;
        return new int[]{fr, fc, tr, tc};
    }

    boolean playerMove(Scanner scanner) {
        while (true) {
            display();
            String color = turn == WHITE ? "White" : "Black";
            System.out.print(color + ", enter move (e.g., a3-b4) or 'q' to quit: ");
            String input = scanner.nextLine().trim();
            if (input.equals("q")) return false;
            if (input.equals("u")) { System.out.println("Undo not implemented."); continue; }
            int[] parsed = parseMove(input);
            if (parsed == null) { System.out.println("Invalid format."); continue; }
            int fr = parsed[0], fc = parsed[1], tr = parsed[2], tc = parsed[3];
            int piece = board[fr][fc];
            if (piece == EMPTY) { System.out.println("No piece there."); continue; }
            if ((isWhite(piece) && turn != WHITE) || (isBlack(piece) && turn != BLACK)) {
                System.out.println("Not your turn.");
                continue;
            }
            List<int[]> legal = legalMovesFrom(fr, fc);
            boolean ok = false;
            for (int[] m : legal) if (m[0] == tr && m[1] == tc) { ok = true; break; }
            if (!ok) { System.out.println("Illegal move."); continue; }
            if (!applyMove(fr, fc, tr, tc)) { System.out.println("Move failed."); continue; }
            int w = winner();
            if (w != EMPTY) {
                display();
                System.out.println(w == WHITE ? "White wins!" : "Black wins!");
                return false;
            }
            return true;
        }
    }

    boolean aiMove() {
        List<int[]> moves = new ArrayList<>();
        for (int r = 0; r < SIZE; r++)
            for (int c = 0; c < SIZE; c++) {
                int p = board[r][c];
                if (p == EMPTY) continue;
                if ((isWhite(p) && turn != WHITE) || (isBlack(p) && turn != BLACK)) continue;
                List<int[]> legal = legalMovesFrom(r, c);
                for (int[] m : legal) moves.add(new int[]{r, c, m[0], m[1]});
            }
        if (moves.isEmpty()) { System.out.println("AI has no moves."); return false; }
        int[] move = moves.get(rand.nextInt(moves.size()));
        applyMove(move[0], move[1], move[2], move[3]);
        int w = winner();
        if (w != EMPTY) {
            display();
            System.out.println(w == WHITE ? "White wins!" : "Black wins!");
            return false;
        }
        return true;
    }

    public static void main(String[] args) {
        Checkers game = new Checkers();
        Scanner scanner = new Scanner(System.in);
        System.out.println("Russian Checkers");
        System.out.println("Controls: enter moves as 'a3-b4'. 'q' to quit.");
        while (true) {
            if (game.turn == WHITE) {
                if (!game.playerMove(scanner)) break;
            } else {
                if (!game.aiMove()) break;
            }
        }
        scanner.close();
    }
}
