class Piece
  include PositionHelper

  attr_accessor :color, :position, :moved
  attr_reader :board

  def initialize(board, color, position)
    @board = board
    @color = color
    @position = position
    @moved = false
  end

  def row
    calc_row(@position)
  end

  def column
    calc_column(@position)
  end

  def moves
    result = []

    directions.each do |d|
      r, c = row + d[0], column + d[1]
      while r >= 0 && r < 8 && c >= 0 && c < 8
        p = calc_position(r, c)
        piece = @board.piece(p)
        unless piece.nil?
          result << p if piece.color != @color
          break
        end
        result << p

        break unless long_move?
        r, c = r + d[0], c + d[1]
      end
    end

    result
  end

  def long_move?
    true
  end
end