class GamesController < ApplicationController
  before_action :set_game, only: %i[ show edit update destroy ]

  # GET /games or /games.json
  def index
    @games = Game.all
  end

  # GET /games/1 or /games/1.json
  def show
  end

  # GET /games/new
  def new
    @game = Game.new(
      log: 'A'*9 + 'B'*2 + 'C'*2 + 'D'*4 + 'E'*12 +
      'F'*2 + 'G'*3 + 'H'*2 + 'I'*9 + 'J'*1 +
      'K'*1 + 'L'*4 + 'M'*2 + 'N'*6 + 'O'*8 +
      'P'*2 + 'Q'*1 + 'R'*6 + 'S'*4 + 'T'*6 +
      'U'*4 + 'V'*2 + 'W'*2 + 'X'*1 + 'Y'*2 +
      'Z'*1
    )
  end

  # GET /games/1/edit
  def edit
  end

  # POST /games or /games.json
  def create
    @game = Game.new(game_params)

    respond_to do |format|
      if @game.save
        format.html { redirect_to @game, notice: "Game was successfully created." }
        format.json { render :show, status: :created, location: @game }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /games/1 or /games/1.json
  def update
    respond_to do |format|
      if @game.update(game_params)
        format.html { redirect_to @game, notice: "Game was successfully updated." }
        format.json { render :show, status: :ok, location: @game }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @game.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /games/1 or /games/1.json
  def destroy
    @game.destroy!

    respond_to do |format|
      format.html { redirect_to games_path, status: :see_other, notice: "Game was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_game
      @game = Game.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def game_params
      params.require(:game).permit(:log)
    end
end
