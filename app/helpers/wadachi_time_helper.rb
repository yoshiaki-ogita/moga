# 轍の①行動予定の「始まり」「終わり」を、一覧から1回で選べるようにする（#122）
#   数字を打たずに済むよう、4:00〜23:45 を15分刻みで並べる（作者の決定 2026-11-20）
module WadachiTimeHelper
  FIRST_HOUR = 4
  STEP_MINUTES = 15

  # select に渡す [見出し, 値] の一覧。例：["5:30", "05:30"]
  #   すでに保存した時刻が一覧に無い時（例：3:10）は、その時刻も足して消えないようにする
  def wadachi_time_options(selected = nil)
    times = (FIRST_HOUR * 60).step((24 * 60) - STEP_MINUTES, STEP_MINUTES).map { |m|
 format("%02d:%02d", m / 60, m % 60) }
    value = wadachi_time_value(selected)
    times = (times + [ value ]).sort if value && !times.include?(value)
    times.map { |t| [ t.delete_prefix("0"), t ] }
  end

  # 保存した時刻を "05:30" の形に。空なら nil
  def wadachi_time_value(time)
    time&.strftime("%H:%M")
  end
end
