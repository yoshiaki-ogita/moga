class PhasesController < ApplicationController
  before_action :require_login
  # 自分の大窓だけを探す（他人の大窓の番号を打っても見つからない＝404）
  before_action :set_phase

  # 小窓を 3×3 のマスに並べる順番（真ん中が大窓。窓1 から時計回り。Home と同じ並べ方）
  #   1 2 3
  #   8 ◯ 4
  #   7 6 5
  WINDOW_ORDER = [ 1, 2, 3, 8, :phase, 4, 7, 6, 5 ].freeze

  # 大窓の画面：中心に大窓の名前、まわりに小窓（#15）
  def show
    # 小窓・課題・記録をまとめて読み込む（進捗率を数える時に、1マスずつ問い合わせない）
    Window.preload_for_progress(@phase.windows.to_a)
    @windows = @phase.windows.index_by(&:number)
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
