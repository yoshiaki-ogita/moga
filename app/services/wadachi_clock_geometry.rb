# わたしの轍の時計（今日の24時間の円グラフ）の「計算の係」
#   絵（SVG のタグ）は描かず、数字と道筋の文字だけを返す。絵を描くのは WadachiClockHelper の仕事
#   （運営事務局からの課題 #6 ロジックの分離、Issue #101）
#   たとえ：盛り付け係（ヘルパー）から、計量と火加減（計算）を任された専門の係
module WadachiClockGeometry
  module_function

  CENTER = 210 # 円の真ん中（SVG の座標）

  # 時刻 → 0時からの分（日本の時刻の「時・分」で数える）
  def minutes_of(time)
    (time.hour * 60) + time.min
  end

  # 時刻 → 0時からの時間（7時30分 → 7.5）
  def hours_of(time)
    minutes_of(time) / 60.0
  end

  # 時間（7.5 など）→ 円の上の点 [x, y]。真上が0時、右回り
  def point(hour, radius)
    angle = (hour / 24.0 * 2 * Math::PI) - (Math::PI / 2)
    [ (CENTER + (radius * Math.cos(angle))).round(1), (CENTER + (radius * Math.sin(angle))).round(1) ]
  end

  # 始まりから終わりまでの扇形（輪の一部）の道筋。SVG の path の d に入れる文字
  #   外の弧を右回りに進み、内の弧を左回りに戻って閉じる
  def arc_path(starts_at, ends_at, inner, outer)
    s = hours_of(starts_at)
    e = hours_of(ends_at)
    large = e - s > 12 ? 1 : 0
    x1, y1 = point(s, outer)
    x2, y2 = point(e, outer)
    x3, y3 = point(e, inner)
    x4, y4 = point(s, inner)
    "M#{x1},#{y1} A#{outer},#{outer} 0 #{large} 1 #{x2},#{y2} " \
      "L#{x3},#{y3} A#{inner},#{inner} 0 #{large} 0 #{x4},#{y4} Z"
  end

  # 始まりと終わりのちょうど真ん中の時間（小窓の記号を書く場所）
  def mid_hour(starts_at, ends_at)
    (hours_of(starts_at) + hours_of(ends_at)) / 2
  end

  # [[始まり, 終わり], ...] の合計を「7時間」「6.5時間」の形で
  def hours_label(ranges)
    hours = ranges.sum { |s, e| hours_of(e) - hours_of(s) }
    "#{hours.round(1).to_s.delete_suffix('.0')}時間"
  end

  # 色（#0d3c61 など）を白へ混ぜて淡くする（にじんだ色）。ratio は 0〜1
  def tint(hex, ratio)
    rgb = hex.delete("#").scan(/../).map { |c| c.to_i(16) }
    "#" + rgb.map { |v| format("%02x", (v + ((255 - v) * ratio)).round) }.join
  end
end
