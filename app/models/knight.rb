class Knight < Piece
  def directions
    [[-1, -2], [-2, -1], [-1, 2], [-2, 1], [1, -2], [2, -1], [1, 2], [2, 1]]
  end

  def long_move?
    false
  end
end