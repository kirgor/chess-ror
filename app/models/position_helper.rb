module PositionHelper
  def calc_row(position)
    position / 8
  end

  def calc_column(position)
    position % 8
  end

  def calc_position(row, column)
    row * 8 + column
  end
end