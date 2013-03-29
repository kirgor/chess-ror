class Pawn < Piece
  def directions
    dr = color ? 1 : -1
    result = []

    if @board.piece(@position + dr * 8).nil?
      result << [dr, 0]
      result << [2*dr, 0] if !moved && @board.piece(@position + dr * 16).nil?
    end

    piece = @board.piece(calc_position(row+dr, column-1))
    result << [dr, -1] if !piece.nil? && piece.color != @color

    piece = @board.piece(calc_position(row+dr, column+1))
    result << [dr, 1] if !piece.nil? && piece.color != @color

    lh = @board.history.last
    unless lh.nil?
      if lh[:from_piece].instance_of?(Pawn) &&
          (lh[:from] - lh[:to]).abs == 16 && lh[:from_piece].row == row
        result << [dr, -1] if lh[:from_piece].column == column-1
        result << [dr, 1] if lh[:from_piece].column == column+1
      end
    end

    result
  end

  def long_move?
    false
  end
end