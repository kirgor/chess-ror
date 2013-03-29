require 'thread'

class Board
  include PositionHelper

  @@instances = Hash.new

  def self.instance(id)
    @@instances[id]
  end

  attr_reader :id, :white_player, :black_player, :moves, :player, :history, :check_state, :win_state

  def initialize(id, white_player, black_player)
    @@instances[id] = self

    @id = id
    @white_player = white_player
    @black_player = black_player

    @pieces = 64.times.collect { nil }

    @pieces[0] = Rook.new(self, true, 0)
    @pieces[1] = Knight.new(self, true, 1)
    @pieces[2] = Bishop.new(self, true, 2)
    @pieces[3] = Queen.new(self, true, 3)
    @pieces[4] = King.new(self, true, 4)
    @pieces[5] = Bishop.new(self, true, 5)
    @pieces[6] = Knight.new(self, true, 6)
    @pieces[7] = Rook.new(self, true, 7)
    (8..15).each do |i|
      @pieces[i] = Pawn.new(self, true, i)
    end

    @pieces[56] = Rook.new(self, false, 56)
    @pieces[57] = Knight.new(self, false, 57)
    @pieces[58] = Bishop.new(self, false, 58)
    @pieces[59] = Queen.new(self, false, 59)
    @pieces[60] = King.new(self, false, 60)
    @pieces[61] = Bishop.new(self, false, 61)
    @pieces[62] = Knight.new(self, false, 62)
    @pieces[63] = Rook.new(self, false, 63)
    (48..55).each do |i|
      @pieces[i] = Pawn.new(self, false, i)
    end

    @white_pieces = (0..15).collect { |i| @pieces[i] }
    @black_pieces = (48..63).collect { |i| @pieces[i] }

    @white_king = @pieces[4]
    @black_king = @pieces[60]

    @player = true
    @history = []
    @moves = calc_moves

    @subscribers_mutex = Mutex.new
    @subscribers = []
  end

  def piece(position)
    unless @temp_move.nil?
      if @temp_move.include?(position)
        @temp_move[position]
      else
        @pieces[position]
      end
    else
      @pieces[position]
    end
  end

  def move!(from, to, piece=nil)
    if @moves.include?([from, to])
      moving_piece = @pieces[from]
      attacked_piece = @pieces[to]

      # Castling
      if moving_piece.instance_of?(King) && (calc_column(to) - calc_column(from)).abs == 2
        rook = @pieces[0] if to == 2
        rook = @pieces[7] if to == 6
        rook = @pieces[56] if to == 58
        rook = @pieces[63] if to == 62
        @pieces[rook.position] = nil
        rook.position = (to + from) / 2
        @pieces[rook.position] = rook
      end

      # En passant
      if attacked_piece.nil? && moving_piece.instance_of?(Pawn) &&
          (calc_column(to) - calc_column(from)).abs == 1
        attacked_piece = @history.last[:from_piece]
        @pieces[attacked_piece.position] = nil
      end

      # Promoting
      if moving_piece.instance_of?(Pawn) && calc_row(to) == (@player ? 7 : 0)
        new_piece = nil
        new_piece = Queen.new(self, @player, to) if piece == 'queen'
        new_piece = Knight.new(self, @player, to) if piece == 'knight'
        new_piece = Rook.new(self, @player, to) if piece == 'rook'
        new_piece = Bishop.new(self, @player, to) if piece == 'bishop'
        return false if new_piece.nil?

        moving_pieces = moving_piece.color ? @white_pieces : @black_pieces
        moving_pieces.delete(moving_piece)
        moving_pieces << new_piece
        moving_piece = new_piece
      end


      unless attacked_piece.nil?
        attacked_pieces = attacked_piece.color ? @white_pieces : @black_pieces
        attacked_pieces.delete(attacked_piece)
      end

      @pieces[from] = nil
      @pieces[to] = moving_piece
      moving_piece.position = to
      moving_piece.moved = true

      @player = !@player
      @history << {
          :from => from,
          :to => to,
          :from_piece => moving_piece,
          :to_piece => attacked_piece
      }
      @moves = calc_moves

      if check?
        @check_state = moves.empty? ? :checkmate : :check
      else
        @check_state = moves.empty? ? :stalemate : nil
      end

      if @check_state == :checkmate
        @win_state = @player ? :black : :white
      elsif @check_state == :stalemate
        @win_state = :draw
      end

      @subscribers_mutex.synchronize {
        @subscribers.each { |s| s.run }
        @subscribers = []
      }

      true
    else
      false
    end
  end

  def undo!
    last_move = @history.last
    @pieces[last_move[:from]] = last_move[:from_piece]
    @pieces[last_move[:to]] = last_move[:to_piece]
    last_move[:from_piece].position = last_move[:from]
    @player = !@player
  end

  def check?
    king = @player ? @white_king : @black_king
    enemy_pieces = @player ? @black_pieces : @white_pieces
    enemy_pieces.any? do |ep|
      ep.moves.any? { |m| m == king.position }
    end
  end

  def possible_check?(from, to)
    @temp_move = {
        from => nil,
        to => @pieces[from]
    }

    moving_piece = @pieces[from]
    attacked_piece = @pieces[to]

    king = @player ? @white_king : @black_king
    enemy_pieces = @player ? @black_pieces : @white_pieces
    king_positions = moving_piece == king ? [to] : [king.position]

    # En passant
    if attacked_piece.nil? && moving_piece.instance_of?(Pawn) &&
        (calc_column(to) - calc_column(from)).abs == 1
      attacked_piece = @history.last[:from_piece]
      @temp_move[attacked_piece.position] = nil
    end

    # Castling
    if moving_piece.instance_of?(King) && (calc_column(to) - calc_column(from)).abs == 2
      rook = @pieces[0] if to == 2
      rook = @pieces[7] if to == 6
      rook = @pieces[56] if to == 58
      rook = @pieces[63] if to == 62
      @temp_move[rook.position] = nil
      @temp_move[(to + from) / 2] = rook
      king_positions << king.position << (to + from) / 2
    end

    result = enemy_pieces.any? do |ep|
      ep == attacked_piece ? false : ep.moves.any? { |m| king_positions.include?(m) }
    end

    @temp_move = nil

    result
  end

  def calc_moves
    pieces = @player ? @white_pieces : @black_pieces
    result = []
    pieces.each do |p|
      p.moves.each do |m|
        result << [p.position, m] unless possible_check?(p.position, m)
      end
    end

    result
  end

  def subscribe
    @subscribers_mutex.synchronize {
      @subscribers << Thread.current
    }
    Thread.stop
  end
end