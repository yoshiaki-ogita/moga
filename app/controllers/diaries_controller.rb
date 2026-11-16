class DiariesController < ApplicationController
  before_action :require_login
  # 日付で、自分のその日の轍を探す（まだなければ新しく用意する）
  before_action :set_diary, only: %i[show update]

  # わたしの轍の一覧（新しい日が上）
  def index
    @diaries = current_user.diaries.order(diary_on: :desc)
  end

  # 1日の轍（その日がまだ無くても開ける。保存して初めて表に残る）
  def show
    prepare_form
  end

  # 1日の轍を保存する（初めてなら作り、2回目からは保存し直す）
  def update
    if @diary.update(diary_params)
      redirect_to diary_path(@diary.diary_on), notice: "#{@diary.date_label}の轍を保存しました"
    else
      prepare_form
      render :show, status: :unprocessable_content
    end
  end

  private

  def set_diary
    date = Date.iso8601(params[:date])
    @diary = Diary.for(current_user, date)
  rescue Date::Error
    raise ActiveRecord::RecordNotFound
  end

  # 入力画面の準備：空の行を足し、小窓の選び方（大窓ごとのまとまり）を用意する
  def prepare_form
    @diary.build_blank_plans
    @window_choices = current_user.window_choices
  end

  def diary_params
    params.require(:diary).permit(:word, :must_do, *review_fields,
                                  diary_plans_attributes: %i[id starts_at ends_at window_id memo _destroy])
  end

  # ④の評価で受け取る欄（mind_grade, mind_comment, ...）
  def review_fields
    Diary::REVIEW_ITEMS.keys.flat_map { |item| [ :"#{item}_grade", :"#{item}_comment" ] }
  end
end
