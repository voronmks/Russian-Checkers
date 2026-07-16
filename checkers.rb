# checkers.rb
class Checkers
  SIZE = 8
  EMPTY = 0; WHITE = 1; BLACK = 2; WHITE_KING = 3; BLACK_KING = 4

  attr_reader :board, :turn

  def initialize
    @board = Array.new(SIZE) { Array.new(SIZE, EMPTY) }
    @turn = WHITE
    init_board
  end

  def init_board
    (0...3).each do |r|
      (0...SIZE).each do |c|
        @board[r][c] = BLACK if (r + c).odd?
      end
    end
    (5...8).each do |r|
      (0...SIZE).each do |c|
        @board[r][c] = WHITE if (r + c).odd?
      end
    end
  end

  def is_white(p) = [WHITE, WHITE_KING].include?(p)
  def is_black(p) = [BLACK, BLACK_KING].include?(p)
  def is_king(p) = [WHITE_KING, BLACK_KING].include?(p)
  def opponent(p) = is_white(p) ? BLACK : WHITE

  def in_bounds(r, c) = r >= 0 && r < SIZE && c >= 0 && c < SIZE
  def get_piece(r, c) = in_bounds(r, c) ? @board[r][c] : EMPTY

  def is_enemy(r, c, piece)
    p = get_piece(r, c)
    return false if p == EMPTY
    return true if is_white(piece) && is_black(p)
    return true if is_black(piece) && is_white(p)
    false
  end

  def can_capture(r, c, dr, dc)
    nr, nc = r + dr, c + dc
    return false unless in_bounds(nr, nc)
    return false if get_piece(nr, nc) == EMPTY
    return false unless is_enemy(nr, nc, @board[r][c])
    lr, lc = r + 2*dr, c + 2*dc
    return false unless in_bounds(lr, lc)
    return false if get_piece(lr, lc) != EMPTY
    true
  end

  def capture_moves_from(r, c)
    piece = @board[r][c]
    dirs = [[-1,-1], [-1,1], [1,-1], [1,1]]
    if !is_king(piece)
      if is_white(piece)
        dirs = [[-1,-1], [-1,1]]
      else
        dirs = [[1,-1], [1,1]]
      end
    end
    moves = []
    dirs.each do |dr, dc|
      if can_capture(r, c, dr, dc)
        moves << [r + 2*dr, c + 2*dc]
      end
    end
    moves
  end

  def simple_moves_from(r, c)
    piece = @board[r][c]
    dirs = [[-1,-1], [-1,1], [1,-1], [1,1]]
    if !is_king(piece)
      if is_white(piece)
        dirs = [[-1,-1], [-1,1]]
      else
        dirs = [[1,-1], [1,1]]
      end
    end
    moves = []
    dirs.each do |dr, dc|
      nr, nc = r + dr, c + dc
      if in_bounds(nr, nc) && get_piece(nr, nc) == EMPTY
        moves << [nr, nc]
      end
    end
    moves
  end

  def has_captures(color)
    (0...SIZE).each do |r|
      (0...SIZE).each do |c|
        p = @board[r][c]
        next if p == EMPTY
        next if color == WHITE && !is_white(p)
        next if color == BLACK && !is_black(p)
        return true if capture_moves_from(r, c).any?
      end
    end
    false
  end

  def legal_moves_from(r, c)
    piece = @board[r][c]
    return [] if piece == EMPTY
    return [] if is_white(piece) && @turn != WHITE
    return [] if is_black(piece) && @turn != BLACK
    if has_captures(@turn)
      capture_moves_from(r, c)
    else
      simple_moves_from(r, c)
    end
  end

  def apply_move(fr, fc, tr, tc)
    piece = @board[fr][fc]
    return false if piece == EMPTY
    dr, dc = tr - fr, tc - fc
    if dr.abs == 2 && dc.abs == 2
      cr, cc = fr + dr/2, fc + dc/2
      return false if get_piece(cr, cc) == EMPTY
      @board[cr][cc] = EMPTY
    end
    @board[tr][tc] = piece
    @board[fr][fc] = EMPTY
    if !is_king(piece)
      if is_white(piece) && tr == 0
        @board[tr][tc] = WHITE_KING
      elsif is_black(piece) && tr == SIZE-1
        @board[tr][tc] = BLACK_KING
      end
    end
    @turn = opponent(piece)
    true
  end

  def winner
    white = black = 0
    (0...SIZE).each do |r|
      (0...SIZE).each do |c|
        p = @board[r][c]
        white += 1 if is_white(p)
        black += 1 if is_black(p)
      end
    end
    return BLACK if white == 0
    return WHITE if black == 0
    EMPTY
  end

  def display
    system('clear') || system('cls')
    puts "  a b c d e f g h"
    (0...SIZE).each do |r|
      print "#{r+1} "
      (0...SIZE).each do |c|
        p = @board[r][c]
        ch = case p
             when EMPTY then '.'
             when WHITE then 'w'
             when BLACK then 'b'
             when WHITE_KING then 'W'
             when BLACK_KING then 'B'
             end
        print "#{ch} "
      end
      puts r+1
    end
    puts "  a b c d e f g h"
    puts "Turn: #{@turn == WHITE ? 'White' : 'Black'}"
  end

  def parse_move(str)
    parts = str.split('-')
    return nil if parts.length != 2
    from, to = parts[0].strip, parts[1].strip
    return nil if from.length != 2 || to.length != 2
    fc = from[0].ord - 'a'.ord
    fr = from[1].to_i - 1
    tc = to[0].ord - 'a'.ord
    tr = to[1].to_i - 1
    return nil if [fr, fc, tr, tc].any? { |v| v < 0 || v >= SIZE }
    [fr, fc, tr, tc]
  end

  def player_move
    loop do
      display
      color = @turn == WHITE ? 'White' : 'Black'
      print "#{color}, enter move (e.g., a3-b4) or 'q' to quit: "
      input = gets.chomp.strip
      return false if input == 'q'
      if input == 'u'
        puts "Undo not implemented."
        next
      end
      parsed = parse_move(input)
      unless parsed
        puts "Invalid format."
        next
      end
      fr, fc, tr, tc = parsed
      piece = @board[fr][fc]
      if piece == EMPTY
        puts "No piece there."
        next
      end
      if (is_white(piece) && @turn != WHITE) || (is_black(piece) && @turn != BLACK)
        puts "Not your turn."
        next
      end
      legal = legal_moves_from(fr, fc)
      unless legal.include?([tr, tc])
        puts "Illegal move."
        next
      end
      unless apply_move(fr, fc, tr, tc)
        puts "Move failed."
        next
      end
      w = winner
      if w != EMPTY
        display
        puts w == WHITE ? "White wins!" : "Black wins!"
        return false
      end
      return true
    end
  end

  def ai_move
    moves = []
    (0...SIZE).each do |r|
      (0...SIZE).each do |c|
        p = @board[r][c]
        next if p == EMPTY
        next if is_white(p) && @turn != WHITE
        next if is_black(p) && @turn != BLACK
        legal = legal_moves_from(r, c)
        legal.each { |tr, tc| moves << [r, c, tr, tc] }
      end
    end
    if moves.empty?
      puts "AI has no moves."
      return false
    end
    move = moves.sample
    apply_move(move[0], move[1], move[2], move[3])
    w = winner
    if w != EMPTY
      display
      puts w == WHITE ? "White wins!" : "Black wins!"
      return false
    end
    true
  end
end

game = Checkers.new
puts "Russian Checkers"
puts "Controls: enter moves as 'a3-b4'. 'q' to quit."
loop do
  if game.turn == Checkers::WHITE
    break unless game.player_move
  else
    break unless game.ai_move
  end
end
