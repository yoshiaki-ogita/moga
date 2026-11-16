# わたしの轍（1日に1つ）。真ん中の丸（本人）から開く
#   ① 行動予定（diary_plans）② 今日の一言（word）③ 今日必ずやること（must_do）
#   ①〜③は前の日の夜に書く
#   ④ 今日1日の自分の行動の評価（5つの項目に a〜e とコメント）は、その日の終わりに書く
#   ⑤ 今日もう一度やり直せるとしたら？（3つ以上を目指す）⑥ 自信を育てた出来事3つ も、その日の終わりに書く
class Diary < ApplicationRecord
  # ④の評価の項目（並び順のまま画面に出す。名前は本人の言葉 11/16）
  REVIEW_ITEMS = {
    mind: "心（メンタル）",
    skill: "技（スキル）",
    body: "体（健康）",
    life: "生活",
    overall: "今日は全体で？"
  }.freeze

  # a〜e の意味（本人の言葉 11/16）
  GRADES = {
    "a" => "良い！",
    "b" => "やや良い",
    "c" => "まぁまぁ",
    "d" => "明日こそ",
    "e" => "負けるな！！"
  }.freeze

  # 1日の画面に出しておく、空の行動予定の行の数（JavaScript を使わずに「行を足す」代わり）
  # ⑤ やり直せるなら：5行まで書ける。3つ以上を目指す（足りなくても保存はできる。励ましの言葉を出す）
  REDO_FIELDS = %i[redo_1 redo_2 redo_3 redo_4 redo_5].freeze
  REDO_GOAL = 3

  # ⑥ 自信を育てた出来事3つ（見出しは本人が選んだ文 11/17）
  CONFIDENCE_ITEMS = {
    joy: "今日嬉しかったことは？",
    growth: "成長したこと、上達したことは？（自己効力感）",
    thanks: "「ありがとう！」と言った、言われたことは？（自己肯定感）"
  }.freeze

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
  # 評価は a〜e のどれか（まだ付けていなければ空でよい）。コメントは50文字まで
  REVIEW_ITEMS.each_key do |item|
    validates :"#{item}_grade", inclusion: { in: GRADES.keys }, allow_blank: true
    validates :"#{item}_comment", length: { maximum: 50 }
  end

  # その日の轍を探す。まだなければ、保存前の新しい轍を用意する
  (REDO_FIELDS + CONFIDENCE_ITEMS.keys).each do |field|
    validates field, length: { maximum: 50 }
  end

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

  # ⑤に書いた数
  def redo_count
    REDO_FIELDS.count { |field| self[field].present? }
  end

  # ⑤の励まし（まだ1つも書いていない日は何も言わない＝前の日の夜の保存では出さない）
  def redo_cheer
    count = redo_count
    return if count.zero?
    return "⑤ #{REDO_GOAL}つ以上達成！" if count >= REDO_GOAL

    "⑤はあと#{REDO_GOAL - count}つ。もう一歩！"
  end
end
