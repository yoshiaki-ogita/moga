class WindowsController < ApplicationController
  before_action :require_login
  # 自分の大窓だけを探す（他人の大窓には小窓を作れない＝404）
  before_action :set_phase, only: %i[new create]
  # 自分の小窓だけを探す（他人の小窓は開けない＝404）
  before_action :set_window, only: %i[show edit update destroy]

  # 小窓の詳細（#16）
  def show
  end

  # 小窓の題名・数え方を直す画面（#17）
  def edit
  end

  # 小窓を保存し直す（#17）。数え方を変えたら、％は新しい数え方で計算し直される（11/7 決裁）
  def update
    if @window.update(window_params)
      redirect_to window_path(@window), notice: "小窓「#{@window.title}」を直しました"
    else
      render :edit, status: :unprocessable_content
    end
  end

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

  # 小窓を消す（#18）。中の課題・記録も一緒に消える（11/7 決裁。課題・記録の表は #19・#24 で足す）
  def destroy
    @window.destroy!
    redirect_to phase_path(@phase), notice: "小窓「#{@window.title}」を消しました", status: :see_other
  end

  private

  def set_phase
    @phase = current_user.phases.find(params[:phase_id])
  end

  def set_window
    @window = current_user.windows.find(params[:id])
    @phase = @window.phase
  end

  def window_params
    params.require(:window).permit(:number, :title, :measure)
  end
end
