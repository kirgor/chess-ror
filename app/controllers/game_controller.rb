class GameController < ApplicationController
  def index
    params[:player] = params[:player] == 'true'
  end

  def join
    redirect_to :action => :index, :id => params[:id], :player => params.include?(:player)
  end

  def new
    #if params.include?(:white_player) && params.include?(:black_player)
    Board.new(params[:id], params[:white_player], params[:black_player])
    #end
    redirect_to :action => :index, :id => params[:id], :player => params.include?(:player)
  end

  def move
    if params.include?(:from) && params.include?(:to) && params.include?(:player)
      board = Board.instance(params[:id])
      unless board.nil?
        status = board.move!(params[:from].to_i, params[:to].to_i, params[:piece]) ? 200 : 400
        render :text => status, :status => status
      else
        render :text => 404, :status => 404
      end
    else
      render :text => 400, :status => 400
    end
  end

  def current_move
    board = Board.instance(params[:id])
    unless board.nil?
      render :json => board.history.length
    else
      render :text => 404, :status => 404
    end
  end

  def subscribe
    board = Board.instance(params[:id])
    unless board.nil?
      board.subscribe
      render :text => 200, :status => 200
    else
      render :text => 404, :status => 404
    end
  end

  def board
    board = Board.instance(params[:id])
    unless board.nil?
      render :json => {
          :whitePlayer => board.white_player,
          :blackPlayer => board.black_player,
          :pieces => 64.times.collect { |i|
            piece = board.piece(i)
            piece.nil? ? nil : {:type => piece.class.name.downcase, :color => piece.color}
          },
          :moves => board.moves,
          :move => board.history.length,
          :player => board.player,
          :checkState => board.check_state,
          :winState => board.win_state
      }
    else
      render :text => 404, :status => 404
    end
  end
end