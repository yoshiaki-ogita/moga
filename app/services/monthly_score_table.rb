# 月ごとの成績表（#130）の「計算の係」
#   達成率型の小窓の記録を月ごとにまとめ、1か月を1行にして返す。表を描くのはビューの仕事
#   表（データベース）は増やさず、記録した日・やった数・できた数から、見るたびに計算する
#   たとえ：毎日の家計簿から、月ごとの集計表を作る係
class MonthlyScoreTable
  # 1か月ぶんの行
  #   month      ：その月の1日（例：2026年9月1日）
  #   attempted  ：その月に解いた数（やった数の合計）
  #   achieved   ：その月の正解（できた数の合計）
  #   cumulative ：その月までの累計の回答済み
  Row = Struct.new(:month, :attempted, :achieved, :cumulative, :target_count, keyword_init: true) do
    # その月の正解率 ○%（解いた数が0なら nil＝表では「―」）
    def accuracy_percent
      return nil if attempted.zero?

      (achieved * 100.0 / attempted).round
    end

    # 累計の回答済み ÷ 全体の数 ○%（全体の数が無ければ nil）。100% で止める
    def cumulative_percent
      return nil if target_count.blank?

      [ (cumulative * 100.0 / target_count).round, 100 ].min
    end
  end

  def initialize(window, today: Date.current)
    @window = window
    @today = today
  end

  # 最初の記録の月から、今月（記録が先の月にあればその月）まで、1か月ずつの行を古い順に返す
  # 記録が無ければ空の配列
  def rows
    entries = @window.entries.select(&:persisted?)
    return [] if entries.empty?

    by_month = entries.group_by { |entry| entry.recorded_on.beginning_of_month }
    cumulative = 0
    months(by_month.keys).map do |month|
      row = build_row(month, by_month.fetch(month, []), cumulative)
      cumulative = row.cumulative
      row
    end
  end

  private

  # 1か月ぶんの記録から1行を作る。累計は前の月までの累計に、その月の解いた数を足す
  def build_row(month, monthly, cumulative_before)
    attempted = monthly.sum(&:attempted_count)
    Row.new(month: month, attempted: attempted, achieved: monthly.sum(&:achieved_count),
            cumulative: cumulative_before + attempted, target_count: @window.target_count)
  end

  # 最初の月から最後の月まで、記録の無い月も含めて1か月ずつ並べる
  def months(recorded_months)
    first = recorded_months.min
    last = [ recorded_months.max, @today.beginning_of_month ].max
    list = []
    month = first
    while month <= last
      list << month
      month = month.next_month
    end
    list
  end
end
