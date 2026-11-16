# わたしの轍（1日に1つ）。真ん中の丸（本人）から開く
#   ① 行動予定（diary_plans）② 今日の一言（word）③ 今日必ずやること（must_do）
#   ①〜③は前の日の夜に書く
class Diary < ApplicationRecord
  # 1日の画面に出しておく、空の行動予定の行の数（JavaScript を使わずに「行を足す」代わり）
  BLANK_PLAN_ROWS = 3

  belongs_to :user
  # 轍を消すと、中の行動予定も一緒に消える。時刻の早い順に並べる
  has_many :diary_plans, -> { order(:starts_at) }, dependent: :destroy, inverse_of: :diary
  # 時刻も小窓も空の行は、保存しない（空の行を残して保存してもよい）
  accepts_nested_attributes_for :diary_plans, allow_destroy: true,
                                              reject_if: ->(attrs) { attrs.values_at("starts_at", "ends_at", "window_id", "memo").all?(&:blank?) }

  validates :diary_on, presence: true, uniqueness: { scope: :user_id }
  validates :word, length: { maximum: 50 }
  validates :must_do, length: { maximum: 1000 }

  # その日の轍を探す。まだなければ、保存前の新しい轍を用意する
  def self.for(user, date)
    user.diaries.find_or_initialize_by(diary_on: date)
  end

  # 「11月17日（火）」のような日付
  def date_label
    "#{diary_on.strftime('%-m月%-d日')}（#{%w[日 月 火 水 木 金 土][diary_on.wday]}）"
  end

  # 入力画面用に、空の行動予定の行を足しておく
  def build_blank_plans
    BLANK_PLAN_ROWS.times { diary_plans.build }
  end
end
