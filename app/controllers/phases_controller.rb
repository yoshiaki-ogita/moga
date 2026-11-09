class PhasesController < ApplicationController
  before_action :require_login
  # 自分の大窓だけを探す（他人の大窓の番号を打っても見つからない＝404）
  before_action :set_phase

  def show
  end

  # 大窓の名前を直す画面（#13）
  def edit
  end

  # 大窓の名前を保存する（#13）
  def update
    if @phase.update(phase_params)
      redirect_to phase_path(@phase), notice: "大窓の名前を「#{@phase.name}」にしました"
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_phase
    @phase = current_user.phases.find(params[:id])
  end

  # 直してよいのは名前だけ（記号 A〜H は変えられない）
  def phase_params
    params.require(:phase).permit(:name)
  end
end
