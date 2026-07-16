// Checkers.cs
using System;
using System.Collections.Generic;
using System.Linq;

class Checkers
{
    const int SIZE = 8;
    const int EMPTY = 0;
    const int WHITE = 1;
    const int BLACK = 2;
    const int WHITE_KING = 3;
    const int BLACK_KING = 4;

    int[,] board = new int[SIZE, SIZE];
    int turn = WHITE;
    Random rand = new Random();

    public Checkers()
    {
        InitBoard();
    }

    void InitBoard()
    {
        for (int r = 0; r < 3; r++)
            for (int c = 0; c < SIZE; c++)
                if ((r + c) % 2 == 1) board[r, c] = BLACK;
        for (int r = 5; r < 8; r++)
            for (int c = 0; c < SIZE; c++)
                if ((r + c) % 2 == 1) board[r, c] = WHITE;
    }

    bool IsWhite(int p) => p == WHITE || p == WHITE_KING;
    bool IsBlack(int p) => p == BLACK || p == BLACK_KING;
    bool IsKing(int p) => p == WHITE_KING || p == BLACK_KING;
    int Opponent(int p) => IsWhite(p) ? BLACK : WHITE;

    bool InBounds(int r, int c) => r >= 0 && r < SIZE && c >= 0 && c < SIZE;
    int GetPiece(int r, int c) => InBounds(r, c) ? board[r, c] : EMPTY;

    bool IsEnemy(int r, int c, int piece)
    {
        int p = GetPiece(r, c);
        if (p == EMPTY) return false;
        if (IsWhite(piece) && IsBlack(p)) return true;
        if (IsBlack(piece) && IsWhite(p)) return true;
        return false;
    }

    bool CanCapture(int r, int c, int dr, int dc)
    {
        int nr = r + dr, nc = c + dc;
        if (!InBounds(nr, nc)) return false;
        if (GetPiece(nr, nc) == EMPTY) return false;
        if (!IsEnemy(nr, nc, board[r, c])) return false;
        int lr = r + 2*dr, lc = c + 2*dc;
        if (!InBounds(lr, lc)) return false;
        if (GetPiece(lr, lc) != EMPTY) return false;
        return true;
    }

    List<(int, int)> CaptureMovesFrom(int r, int c)
    {
        int piece = board[r, c];
        var dirs = new[] { (-1,-1), (-1,1), (1,-1), (1,1) };
        if (!IsKing(piece))
        {
            if (IsWhite(piece)) dirs = new[] { (-1,-1), (-1,1) };
            else dirs = new[] { (1,-1), (1,1) };
        }
        var moves = new List<(int, int)>();
        foreach (var (dr, dc) in dirs)
            if (CanCapture(r, c, dr, dc))
                moves.Add((r + 2*dr, c + 2*dc));
        return moves;
    }

    List<(int, int)> SimpleMovesFrom(int r, int c)
    {
        int piece = board[r, c];
        var dirs = new[] { (-1,-1), (-1,1), (1,-1), (1,1) };
        if (!IsKing(piece))
        {
            if (IsWhite(piece)) dirs = new[] { (-1,-1), (-1,1) };
            else dirs = new[] { (1,-1), (1,1) };
        }
        var moves = new List<(int, int)>();
        foreach (var (dr, dc) in dirs)
        {
            int nr = r + dr, nc = c + dc;
            if (InBounds(nr, nc) && GetPiece(nr, nc) == EMPTY)
                moves.Add((nr, nc));
        }
        return moves;
    }

    bool HasCaptures(int color)
    {
        for (int r = 0; r < SIZE; r++)
            for (int c = 0; c < SIZE; c++)
            {
                int p = board[r, c];
                if (p == EMPTY) continue;
                if (color == WHITE && !IsWhite(p)) continue;
                if (color == BLACK && !IsBlack(p)) continue;
                if (CaptureMovesFrom(r, c).Count > 0) return true;
            }
        return false;
    }

    List<(int, int)> LegalMovesFrom(int r, int c)
    {
        int piece = board[r, c];
        if (piece == EMPTY) return new List<(int, int)>();
        if (IsWhite(piece) && turn != WHITE) return new List<(int, int)>();
        if (IsBlack(piece) && turn != BLACK) return new List<(int, int)>();
        if (HasCaptures(turn))
            return CaptureMovesFrom(r, c);
        return SimpleMovesFrom(r, c);
    }

    bool ApplyMove(int fr, int fc, int tr, int tc)
    {
        int piece = board[fr, fc];
        if (piece == EMPTY) return false;
        int dr = tr - fr, dc = tc - fc;
        if (Math.Abs(dr) == 2 && Math.Abs(dc) == 2)
        {
            int cr = fr + dr/2, cc = fc + dc/2;
            if (GetPiece(cr, cc) == EMPTY) return false;
            board[cr, cc] = EMPTY;
        }
        board[tr, tc] = piece;
        board[fr, fc] = EMPTY;
        if (!IsKing(piece))
        {
            if (IsWhite(piece) && tr == 0) board[tr, tc] = WHITE_KING;
            else if (IsBlack(piece) && tr == SIZE-1) board[tr, tc] = BLACK_KING;
        }
        turn = Opponent(piece);
        return true;
    }

    int Winner()
    {
        int white = 0, black = 0;
        for (int r = 0; r < SIZE; r++)
            for (int c = 0; c < SIZE; c++)
            {
                int p = board[r, c];
                if (IsWhite(p)) white++;
                else if (IsBlack(p)) black++;
            }
        if (white == 0) return BLACK;
        if (black == 0) return WHITE;
        return EMPTY;
    }

    void Display()
    {
        Console.Clear();
        Console.WriteLine("  a b c d e f g h");
        for (int r = 0; r < SIZE; r++)
        {
            Console.Write($"{r+1} ");
            for (int c = 0; c < SIZE; c++)
            {
                int p = board[r, c];
                char ch;
                switch (p)
                {
                    case EMPTY: ch = '.'; break;
                    case WHITE: ch = 'w'; break;
                    case BLACK: ch = 'b'; break;
                    case WHITE_KING: ch = 'W'; break;
                    case BLACK_KING: ch = 'B'; break;
                    default: ch = '?'; break;
                }
                Console.Write($"{ch} ");
            }
            Console.WriteLine($"{r+1}");
        }
        Console.WriteLine("  a b c d e f g h");
        Console.WriteLine($"Turn: {(turn == WHITE ? "White" : "Black")}");
    }

    bool PlayerMove()
    {
        while (true)
        {
            Display();
            string color = turn == WHITE ? "White" : "Black";
            Console.Write($"{color}, enter move (e.g., a3-b4) or 'q' to quit: ");
            string input = Console.ReadLine().Trim();
            if (input == "q") return false;
            if (input == "u") { Console.WriteLine("Undo not implemented."); continue; }
            var parsed = ParseMove(input);
            if (parsed == null) { Console.WriteLine("Invalid format."); continue; }
            var (fr, fc, tr, tc) = parsed.Value;
            int piece = board[fr, fc];
            if (piece == EMPTY) { Console.WriteLine("No piece there."); continue; }
            if ((IsWhite(piece) && turn != WHITE) || (IsBlack(piece) && turn != BLACK))
            { Console.WriteLine("Not your turn."); continue; }
            var legal = LegalMovesFrom(fr, fc);
            if (!legal.Any(m => m.Item1 == tr && m.Item2 == tc))
            { Console.WriteLine("Illegal move."); continue; }
            if (!ApplyMove(fr, fc, tr, tc))
            { Console.WriteLine("Move failed."); continue; }
            int w = Winner();
            if (w != EMPTY)
            {
                Display();
                Console.WriteLine(w == WHITE ? "White wins!" : "Black wins!");
                return false;
            }
            return true;
        }
    }

    (int fr, int fc, int tr, int tc)? ParseMove(string str)
    {
        var parts = str.Split('-');
        if (parts.Length != 2) return null;
        string from = parts[0].Trim(), to = parts[1].Trim();
        if (from.Length != 2 || to.Length != 2) return null;
        int fc = from[0] - 'a';
        int fr = int.Parse(from[1].ToString()) - 1;
        int tc = to[0] - 'a';
        int tr = int.Parse(to[1].ToString()) - 1;
        if (fr < 0 || fr >= SIZE || fc < 0 || fc >= SIZE || tr < 0 || tr >= SIZE || tc < 0 || tc >= SIZE)
            return null;
        return (fr, fc, tr, tc);
    }

    bool AIMove()
    {
        var moves = new List<(int fr, int fc, int tr, int tc)>();
        for (int r = 0; r < SIZE; r++)
            for (int c = 0; c < SIZE; c++)
            {
                int p = board[r, c];
                if (p == EMPTY) continue;
                if ((IsWhite(p) && turn != WHITE) || (IsBlack(p) && turn != BLACK)) continue;
                var legal = LegalMovesFrom(r, c);
                foreach (var (tr, tc) in legal)
                    moves.Add((r, c, tr, tc));
            }
        if (moves.Count == 0) { Console.WriteLine("AI has no moves."); return false; }
        var move = moves[rand.Next(moves.Count)];
        ApplyMove(move.fr, move.fc, move.tr, move.tc);
        int w = Winner();
        if (w != EMPTY)
        {
            Display();
            Console.WriteLine(w == WHITE ? "White wins!" : "Black wins!");
            return false;
        }
        return true;
    }

    static void Main()
    {
        var game = new Checkers();
        Console.WriteLine("Russian Checkers");
        Console.WriteLine("Controls: enter moves as 'a3-b4'. 'q' to quit.");
        while (true)
        {
            if (game.turn == WHITE)
            {
                if (!game.PlayerMove()) break;
            }
            else
            {
                if (!game.AIMove()) break;
            }
        }
    }
}
