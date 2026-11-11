class EntriesController < ApplicationController
  before_action :require_login
  # 自分の小窓だけを探す（他人の小窓には記録を書けない＝404）
  before_action :set_window, only: %i[create]
  # 自分の記録だけを探す（他人の記録は直せない＝404）
  before_action :set_entry, only: %i[edit update destroy]

  # 記録を書く（#24）。入力欄は小窓の詳細画面にある
  def create
    @entry = @window.entries.build(entry_params)
    if @entry.save
      redirect_to window_path(@window), notice: "#{@entry.date_label}の記録を書きました"
    else
      @phase = @window.phase
      render "windows/show", status: :unprocessable_content
    end
  end

  # 記録を直す画面（#26）
  def edit
  end

  # 記録を保存し直す（#26）
  def update
    if @entry.update(entry_params)
      redirect_to window_path(@window), notice: "#{@entry.date_label}の記録を直しました"
    else
      render :edit, status: :unprocessable_content
    end
  end

  # 記録を消す（#27）
  def destroy
    @entry.destroy!
    redirect_to window_path(@window), notice: "#{@entry.date_label}の記録を消しました", status: :see_other
  end

  private

  def set_window
    @window = current_user.windows.find(params[:window_id])
  end

  def set_entry
    @entry = current_user.entries.find(params[:id])
    @window = @entry.window
    @phase = @window.phase
  end

  def entry_params
    params.require(:entry).permit(:recorded_on, :attempted_count, :achieved_count, :title, :body)
  end
end
