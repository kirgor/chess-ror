class King < Queen
  def directions
    result = super
    if !@moved
      if color
        if @board.piece(3).nil? &&
            @board.piece(2).nil? &&
            @board.piece(1).nil? &&
            @board.piece(0).instance_of?(Rook) &&
            !@board.piece(0).moved
          result << [0, -2]
        end
        if @board.piece(5).nil? &&
            @board.piece(6).nil? &&
            @board.piece(7).instance_of?(Rook) &&
            !@board.piece(7).moved
          result << [0, 2]
        end
      else
        if @board.piece(59).nil? &&
            @board.piece(58).nil? &&
            @board.piece(57).nil? &&
            @board.piece(56).instance_of?(Rook) &&
            !@board.piece(56).moved
          result << [0, -2]
        end
        if @board.piece(61).nil? &&
            @board.piece(62).nil? &&
            @board.piece(63).instance_of?(Rook) &&
            !@board.piece(63).moved
          result << [0, 2]
        end
      end
    end

    result
  end

  def long_move?
    false
  end
end