# 小窓（窓 1〜8）。1つの大窓に最大8つ
class Window < ApplicationRecord
  NUMBERS = (1..8).to_a.freeze

  belongs_to :phase
  # 小窓を消すと、中の課題も一緒に消える（11/7 決裁）
  has_many :plans, -> { order(:created_at) }, dependent: :destroy
  # 小窓を消すと、中の記録も一緒に消える（新しい日付が上）
  has_many :entries, -> { order(recorded_on: :desc, created_at: :desc) }, dependent: :destroy

  # 数え方：課題型（課題の「済み ÷ 課題」）／達成率型（記録の「できた ÷ やった」）
  enum :measure, { plan_count: 0, achievement_rate: 1 }, validate: true

  validates :number, presence: true, inclusion: { in: NUMBERS }, uniqueness: { scope: :phase_id }
  validates :title, presence: true, length: { maximum: 30 }

  # 進捗率を数えるために、たくさんの小窓の中身をまとめて読み込む（#34 N+1対策）
  # 課題型の小窓には課題だけ、達成率型の小窓には記録だけを読み込む（使わない物は読まない）
  def self.preload_for_progress(windows)
    plan_windows, rate_windows = windows.partition(&:plan_count?)
    ActiveRecord::Associations::Preloader.new(records: plan_windows, associations: :plans).call
    ActiveRecord::Associations::Preloader.new(records: rate_windows, associations: :entries).call
  end

  # 進捗率（#28）。どの表にも保存せず、見るたびに計算する
  # 割り算の「上の数（分子）」と「下の数（分母）」を返す
  #   課題型   ：済んだ課題の数 ÷ 課題の数
  #   達成率型 ：できた数の合計 ÷ やった数の合計（11/7 決裁 例：16/20 と 10/10 → 26÷30）
  # 読み込み済みの課題・記録を Ruby で数えるので、includes と組み合わせても余計な問い合わせが出ない
  def progress_fraction
    if plan_count?
      [ plans.count(&:done?), plans.size ]
    else
      [ entries.sum(&:achieved_count), entries.sum(&:attempted_count) ]
    end
  end

  # 0.0〜1.0。課題・記録が0件（分母が0）の窓は 0（講師補足①：0%・白）
  def progress_rate
    numerator, denominator = progress_fraction
    return 0.0 if denominator.zero?

    numerator.to_f / denominator
  end

  # 画面に出す ○%（四捨五入した整数）
  def progress_percent
    (progress_rate * 100).round
  end
end
