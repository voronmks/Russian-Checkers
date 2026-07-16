// checkers.go
package main

import (
	"bufio"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"
)

const SIZE = 8
const (
	EMPTY = iota
	WHITE
	BLACK
	WHITE_KING
	BLACK_KING
)

type Checkers struct {
	board      [SIZE][SIZE]int
	turn       int
	moveHistory []string
}

func NewCheckers() *Checkers {
	c := &Checkers{turn: WHITE}
	c.initBoard()
	return c
}

func (c *Checkers) initBoard() {
	for r := 0; r < 3; r++ {
		for col := 0; col < SIZE; col++ {
			if (r+col)%2 == 1 {
				c.board[r][col] = BLACK
			}
		}
	}
	for r := 5; r < 8; r++ {
		for col := 0; col < SIZE; col++ {
			if (r+col)%2 == 1 {
				c.board[r][col] = WHITE
			}
		}
	}
}

func (c *Checkers) isWhite(p int) bool { return p == WHITE || p == WHITE_KING }
func (c *Checkers) isBlack(p int) bool { return p == BLACK || p == BLACK_KING }
func (c *Checkers) isKing(p int) bool  { return p == WHITE_KING || p == BLACK_KING }
func (c *Checkers) opponent(p int) int {
	if c.isWhite(p) {
		return BLACK
	}
	return WHITE
}

func (c *Checkers) inBounds(r, c int) bool {
	return r >= 0 && r < SIZE && c >= 0 && c < SIZE
}

func (c *Checkers) getPiece(r, c int) int {
	if c.inBounds(r, c) {
		return c.board[r][c]
	}
	return EMPTY
}

func (c *Checkers) isEnemy(r, c int, piece int) bool {
	p := c.getPiece(r, c)
	if p == EMPTY {
		return false
	}
	if c.isWhite(piece) && c.isBlack(p) {
		return true
	}
	if c.isBlack(piece) && c.isWhite(p) {
		return true
	}
	return false
}

func (c *Checkers) canCapture(r, c, dr, dc int) bool {
	nr, nc := r+dr, c+dc
	if !c.inBounds(nr, nc) {
		return false
	}
	if c.getPiece(nr, nc) == EMPTY {
		return false
	}
	if !c.isEnemy(nr, nc, c.board[r][c]) {
		return false
	}
	lr, lc := r+2*dr, c+2*dc
	if !c.inBounds(lr, lc) {
		return false
	}
	if c.getPiece(lr, lc) != EMPTY {
		return false
	}
	return true
}

func (c *Checkers) captureMovesFrom(r, c int) [][2]int {
	var moves [][2]int
	piece := c.board[r][c]
	dirs := [][2]int{{-1, -1}, {-1, 1}, {1, -1}, {1, 1}}
	// For kings, all directions; for others, only forward
	if !c.isKing(piece) {
		if c.isWhite(piece) {
			// white moves up (row decreases)
			dirs = [][2]int{{-1, -1}, {-1, 1}}
		} else {
			// black moves down (row increases)
			dirs = [][2]int{{1, -1}, {1, 1}}
		}
	}
	for _, d := range dirs {
		dr, dc := d[0], d[1]
		if c.canCapture(r, c, dr, dc) {
			lr, lc := r+2*dr, c+2*dc
			moves = append(moves, [2]int{lr, lc})
		}
	}
	return moves
}

func (c *Checkers) simpleMovesFrom(r, c int) [][2]int {
	var moves [][2]int
	piece := c.board[r][c]
	dirs := [][2]int{{-1, -1}, {-1, 1}, {1, -1}, {1, 1}}
	if !c.isKing(piece) {
		if c.isWhite(piece) {
			dirs = [][2]int{{-1, -1}, {-1, 1}}
		} else {
			dirs = [][2]int{{1, -1}, {1, 1}}
		}
	}
	for _, d := range dirs {
		nr, nc := r+d[0], c+d[1]
		if c.inBounds(nr, nc) && c.getPiece(nr, nc) == EMPTY {
			moves = append(moves, [2]int{nr, nc})
		}
	}
	return moves
}

func (c *Checkers) hasCaptures(color int) bool {
	for r := 0; r < SIZE; r++ {
		for c := 0; c < SIZE; c++ {
			p := c.board[r][c]
			if p == EMPTY {
				continue
			}
			if color == WHITE && !c.isWhite(p) {
				continue
			}
			if color == BLACK && !c.isBlack(p) {
				continue
			}
			if len(c.captureMovesFrom(r, c)) > 0 {
				return true
			}
		}
	}
	return false
}

func (c *Checkers) legalMovesFrom(r, c int) [][2]int {
	piece := c.board[r][c]
	if piece == EMPTY {
		return nil
	}
	if c.isWhite(piece) && c.turn != WHITE {
		return nil
	}
	if c.isBlack(piece) && c.turn != BLACK {
		return nil
	}
	if c.hasCaptures(c.turn) {
		return c.captureMovesFrom(r, c)
	}
	return c.simpleMovesFrom(r, c)
}

func (c *Checkers) applyMove(fr, fc, tr, tc int) bool {
	piece := c.board[fr][fc]
	if piece == EMPTY {
		return false
	}
	dr, dc := tr-fr, tc-fc
	if abs(dr) == 2 && abs(dc) == 2 {
		cr, cc := fr+dr/2, fc+dc/2
		if c.getPiece(cr, cc) == EMPTY {
			return false
		}
		c.board[cr][cc] = EMPTY
	}
	c.board[tr][tc] = piece
	c.board[fr][fc] = EMPTY
	// Promotion
	if !c.isKing(piece) {
		if c.isWhite(piece) && tr == 0 {
			c.board[tr][tc] = WHITE_KING
		} else if c.isBlack(piece) && tr == SIZE-1 {
			c.board[tr][tc] = BLACK_KING
		}
	}
	// Switch turn
	if c.turn == WHITE {
		c.turn = BLACK
	} else {
		c.turn = WHITE
	}
	return true
}

func abs(x int) int {
	if x < 0 {
		return -x
	}
	return x
}

func (c *Checkers) winner() int {
	white, black := 0, 0
	for r := 0; r < SIZE; r++ {
		for c := 0; c < SIZE; c++ {
			p := c.board[r][c]
			if c.isWhite(p) {
				white++
			} else if c.isBlack(p) {
				black++
			}
		}
	}
	if white == 0 {
		return BLACK
	}
	if black == 0 {
		return WHITE
	}
	return EMPTY
}

func (c *Checkers) display() {
	fmt.Print("\033[H\033[2J")
	fmt.Println("  a b c d e f g h")
	for r := 0; r < SIZE; r++ {
		fmt.Printf("%d ", r+1)
		for c := 0; c < SIZE; c++ {
			p := c.board[r][c]
			var ch string
			switch p {
			case EMPTY:
				ch = "."
			case WHITE:
				ch = "w"
			case BLACK:
				ch = "b"
			case WHITE_KING:
				ch = "W"
			case BLACK_KING:
				ch = "B"
			}
			fmt.Printf("%s ", ch)
		}
		fmt.Printf("%d\n", r+1)
	}
	fmt.Println("  a b c d e f g h")
	if c.turn == WHITE {
		fmt.Println("Turn: White")
	} else {
		fmt.Println("Turn: Black")
	}
}

func parseMove(moveStr string) (int, int, int, int, error) {
	parts := strings.Split(moveStr, "-")
	if len(parts) != 2 {
		return 0, 0, 0, 0, fmt.Errorf("invalid format")
	}
	from := parts[0]
	to := parts[1]
	if len(from) != 2 || len(to) != 2 {
		return 0, 0, 0, 0, fmt.Errorf("invalid square")
	}
	fc := int(from[0] - 'a')
	fr, _ := strconv.Atoi(string(from[1]))
	fr--
	tc := int(to[0] - 'a')
	tr, _ := strconv.Atoi(string(to[1]))
	tr--
	if fr < 0 || fr >= SIZE || fc < 0 || fc >= SIZE || tr < 0 || tr >= SIZE || tc < 0 || tc >= SIZE {
		return 0, 0, 0, 0, fmt.Errorf("out of bounds")
	}
	return fr, fc, tr, tc, nil
}

func (c *Checkers) playerMove() bool {
	reader := bufio.NewReader(os.Stdin)
	for {
		c.display()
		color := "White"
		if c.turn == BLACK {
			color = "Black"
		}
		fmt.Printf("%s, enter move (e.g., a3-b4) or 'q' to quit: ", color)
		input, _ := reader.ReadString('\n')
		input = strings.TrimSpace(input)
		if input == "q" {
			return false
		}
		if input == "u" {
			fmt.Println("Undo not implemented.")
			continue
		}
		fr, fc, tr, tc, err := parseMove(input)
		if err != nil {
			fmt.Println("Invalid format:", err)
			continue
		}
		piece := c.board[fr][fc]
		if piece == EMPTY {
			fmt.Println("No piece there.")
			continue
		}
		if c.isWhite(piece) && c.turn != WHITE {
			fmt.Println("Not your turn.")
			continue
		}
		if c.isBlack(piece) && c.turn != BLACK {
			fmt.Println("Not your turn.")
			continue
		}
		legal := c.legalMovesFrom(fr, fc)
		found := false
		for _, m := range legal {
			if m[0] == tr && m[1] == tc {
				found = true
				break
			}
		}
		if !found {
			fmt.Println("Illegal move.")
			continue
		}
		if !c.applyMove(fr, fc, tr, tc) {
			fmt.Println("Move failed.")
			continue
		}
		if w := c.winner(); w != EMPTY {
			c.display()
			if w == WHITE {
				fmt.Println("White wins!")
			} else {
				fmt.Println("Black wins!")
			}
			return false
		}
		return true
	}
}

func (c *Checkers) aiMove() bool {
	var moves [][4]int // fr, fc, tr, tc
	for r := 0; r < SIZE; r++ {
		for c := 0; c < SIZE; c++ {
			p := c.board[r][c]
			if p == EMPTY {
				continue
			}
			if c.isWhite(p) && c.turn != WHITE {
				continue
			}
			if c.isBlack(p) && c.turn != BLACK {
				continue
			}
			legal := c.legalMovesFrom(r, c)
			for _, m := range legal {
				moves = append(moves, [4]int{r, c, m[0], m[1]})
			}
		}
	}
	if len(moves) == 0 {
		fmt.Println("AI has no moves.")
		return false
	}
	// Random move
	move := moves[rand.Intn(len(moves))]
	fr, fc, tr, tc := move[0], move[1], move[2], move[3]
	c.applyMove(fr, fc, tr, tc)
	if w := c.winner(); w != EMPTY {
		c.display()
		if w == WHITE {
			fmt.Println("White wins!")
		} else {
			fmt.Println("Black wins!")
		}
		return false
	}
	return true
}

func main() {
	rand.Seed(time.Now().UnixNano())
	game := NewCheckers()
	fmt.Println("Russian Checkers")
	fmt.Println("Controls: enter moves as 'a3-b4'. 'q' to quit.")
	for {
		if game.turn == WHITE {
			if !game.playerMove() {
				break
			}
		} else {
			if !game.aiMove() {
				break
			}
		}
	}
}
