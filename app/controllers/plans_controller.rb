class PlansController < ApplicationController
  before_action :require_login
  # 自分の小窓だけを探す（他人の小窓には課題を足せない＝404）
  before_action :set_window, only: %i[create]

  # 課題を足す（#19）。入力欄は小窓の詳細画面にある
  def create
    @plan = @window.plans.build(plan_params)
    if @plan.save
      redirect_to window_path(@window), notice: "課題「#{@plan.title}」を足しました"
    else
      @phase = @window.phase
      render "windows/show", status: :unprocessable_content
    end
  end

  private

  def set_window
    @window = current_user.windows.find(params[:window_id])
  end

  def plan_params
    params.require(:plan).permit(:title)
  end
end
