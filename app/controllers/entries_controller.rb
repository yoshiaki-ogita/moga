class EntriesController < ApplicationController
  before_action :require_login
  # 自分の小窓だけを探す（他人の小窓には記録を書けない＝404）
  before_action :set_window, only: %i[create]

  # 記録を書く（#24）。入力欄は小窓の詳細画面にある
  def create
    @entry = @window.entries.build(entry_params)
    if @entry.save
      redirect_to window_path(@window), notice: "#{@entry.recorded_on.strftime('%-m月%-d日')}の記録を書きました"
    else
      @phase = @window.phase
      render "windows/show", status: :unprocessable_content
    end
  end

  private

  def set_window
    @window = current_user.windows.find(params[:window_id])
  end

  def entry_params
    params.require(:entry).permit(:recorded_on, :attempted_count, :achieved_count, :title, :body)
  end
end
