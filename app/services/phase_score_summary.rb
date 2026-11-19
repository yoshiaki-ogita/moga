# 科目ごとのまとめ表（#132）の「計算の係」
#   大窓の中の達成率型の小窓を1行ずつ並べ、最後に合計を出す。表を描くのはビューの仕事
#   表（データベース）は増やさず、小窓の記録から見るたびに計算する
#   たとえ：科目ごとの成績表を1枚にまとめて、いちばん下に合計を書く係
class PhaseScoreSummary
  # 1行ぶん（小窓1つ、または合計）
  #   target_count ：全体の数（無ければ nil）
  #   attempted    ：回答済み（やった数の合計）
  #   achieved     ：正解（できた数の合計）
  #   counted      ：進み具合の分子（全体の数がある小窓の回答済み）
  Row = Struct.new(:window, :target_count, :attempted, :achieved, :counted, keyword_init: true) do
    # 正解率 ○%（回答済みが0なら nil＝表では「―」）
    def accuracy_percent
      return nil if attempted.zero?

      (achieved * 100.0 / attempted).round
    end

    # 進み具合 ○%（全体の数が無ければ nil）。100% で止める
    def progress_percent
      return nil if target_count.blank?

      [ (counted * 100.0 / target_count).round, 100 ].min
    end
  end

  # windows：大窓の小窓（記録を読み込み済みのもの。Phase#windows_by_number の値）
  def initialize(windows)
    @windows = windows.select(&:achievement_rate?).sort_by(&:number)
  end

  # 小窓ごとの行（番号の順）
  def rows
    @rows ||= @windows.map do |window|
      attempted = window.attempted_total
      Row.new(window: window, target_count: window.target_count, attempted: attempted,
              achieved: window.achieved_total, counted: window.target_count ? attempted : 0)
    end
  end

  # 合計の行。全体の数と進み具合は、全体の数がある小窓だけで数える（どれにも無ければ nil）
  def total
    targets = rows.filter_map(&:target_count)
    Row.new(window: nil, target_count: targets.empty? ? nil : targets.sum,
            attempted: rows.sum(&:attempted), achieved: rows.sum(&:achieved), counted: rows.sum(&:counted))
  end

  def any?
    rows.any?
  end
end
