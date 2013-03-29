class Rook < Piece
  def directions
    [[-1, 0], [1, 0], [0, -1], [0, 1]]
  end
end