class WindowsController < ApplicationController
  before_action :require_login
  # 自分の大窓だけを探す（他人の大窓には小窓を作れない＝404）
  before_action :set_phase, only: %i[new create]

  # 小窓を作る画面（#14）
  def new
    if @phase.free_window_numbers.empty?
      redirect_to phase_path(@phase), alert: "小窓は1つの大窓に8つまでです"
      return
    end
    # 大窓の画面の空いたマスから来たときは、その番号を最初から選んでおく
    number = params[:number].to_i
    number = @phase.free_window_numbers.first unless @phase.free_window_numbers.include?(number)
    @window = @phase.windows.build(number: number)
  end

  # 小窓を保存する（#14）
  def create
    @window = @phase.windows.build(window_params)
    if @window.save
      redirect_to phase_path(@phase), notice: "小窓「#{@window.title}」を作りました"
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_phase
    @phase = current_user.phases.find(params[:phase_id])
  end

  def window_params
    params.require(:window).permit(:number, :title, :measure)
  end
end
