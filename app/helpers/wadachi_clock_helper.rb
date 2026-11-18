# 轍の⑦「今日の24時間」の円グラフ（SVG）を描く
#   真上が0時、右回り。外の輪＝予定（はっきりした青）、内の輪＝実際（同じ青を白でにじませた淡い色）
#   色は大窓ごとの青の濃淡（Aが一番濃く、Hが一番淡い）。参考：永田ゆかり『データ視覚化のデザイン』
module WadachiClockHelper
  PHASE_BLUES = {
    "A" => "#0d3c61", "B" => "#12507f", "C" => "#1565c0", "D" => "#1e88e5",
    "E" => "#42a5f5", "F" => "#64b5f6", "G" => "#90caf9", "H" => "#bbdefb"
  }.freeze
  DARK_PHASES = %w[A B C D].freeze # この大窓の上の字は白
  CENTER = 210
  PLAN_RING = [ 130, 170 ].freeze   # 外の輪（予定）の内側・外側の半径
  ACTUAL_RING = [ 94, 122 ].freeze  # 内の輪（実際）
  ACTUAL_TINT = 0.45                # 実際の色を白へにじませる割合

  def wadachi_clock(diary)
    plans = diary.diary_plans.select(&:persisted?)
    confirmed = plans.any?(&:actual?)
    parts = [ clock_background, clock_rings(confirmed) ]
    plans.each do |plan|
      parts << clock_arc(plan.starts_at, plan.ends_at, PLAN_RING, PHASE_BLUES[plan.phase_code], "#ffffff", 2)
    end
    plans.select(&:actual?).each do |plan|
      color = PHASE_BLUES[plan.phase_code]
      parts << clock_arc(*plan.actual_range, ACTUAL_RING, tint(color, ACTUAL_TINT), color, 1.2)
    end
    parts << clock_ticks
    plans.each { |plan| parts << clock_label(plan) }
    parts << clock_center(plans, confirmed)
    tag.svg(safe_join(parts), viewBox: "-20 -5 460 430", class: "wadachi-clock__svg", role: "img",
                              aria: { label: "今日の24時間の円グラフ" })
  end

  # 「7時間」「6.5時間」のような合計
  def clock_hours(ranges)
    hours = ranges.sum { |s, e| (minutes_of(e) - minutes_of(s)) / 60.0 }
    "#{hours.round(1).to_s.delete_suffix('.0')}時間"
  end

  private

  def clock_background
    safe_join([
      tag.defs(safe_join([
        tag.radialGradient(safe_join([ tag.stop(offset: "0", "stop-color": "#ffffff"),
                                       tag.stop(offset: "1", "stop-color": "#d9e2ea") ]),
                           id: "wadachi-clock-bg", cx: "50%", cy: "42%", r: "62%"),
        tag.filter(tag.feDropShadow(dx: 0, dy: 4, stdDeviation: 6, "flood-color": "#0d3c61", "flood-opacity": 0.18),
                   id: "wadachi-clock-shadow", x: "-20%", y: "-20%", width: "140%", height: "140%")
      ])),
      tag.circle(cx: CENTER, cy: CENTER, r: 180, fill: "url(#wadachi-clock-bg)", filter: "url(#wadachi-clock-shadow)")
    ])
  end

  # 輪の下地（淡い灰色）と細い枠線。実際がまだの日は内の輪を点線にする
  def clock_rings(confirmed)
    dash = confirmed ? nil : "4 4"
    safe_join([
      tag.circle(cx: CENTER, cy: CENTER, r: 150, fill: "none", stroke: "#e9eef2", "stroke-width": 40),
      *PLAN_RING.map { |r|
        tag.circle(cx: CENTER, cy: CENTER, r: r, fill: "none", stroke: "#b0bec5", "stroke-width": 1)
      },
      tag.circle(cx: CENTER, cy: CENTER, r: 108, fill: "none", stroke: "#f4f6f8", "stroke-width": 28),
      *ACTUAL_RING.map { |r|
        tag.circle(cx: CENTER, cy: CENTER, r: r, fill: "none", stroke: "#cfd8dc", "stroke-width": 1,
                   "stroke-dasharray": dash)
      }
    ])
  end

  def clock_arc(starts_at, ends_at, (inner, outer), fill, stroke, width)
    s = minutes_of(starts_at) / 60.0
    e = minutes_of(ends_at) / 60.0
    large = e - s > 12 ? 1 : 0
    x1, y1 = point(s, outer)
    x2, y2 = point(e, outer)
    x3, y3 = point(e, inner)
    x4, y4 = point(s, inner)
    d = "M#{x1},#{y1} A#{outer},#{outer} 0 #{large} 1 #{x2},#{y2} " \
        "L#{x3},#{y3} A#{inner},#{inner} 0 #{large} 0 #{x4},#{y4} Z"
    tag.path(d: d, fill: fill, stroke: stroke, "stroke-width": width, "stroke-linejoin": "round")
  end

  def clock_ticks
    lines = (0..23).map do |h|
      x1, y1 = point(h, 174)
      x2, y2 = point(h, (h % 6).zero? ? 186 : 180)
      tag.line(x1: x1, y1: y1, x2: x2, y2: y2, stroke: "#90a4ae", "stroke-width": (h % 6).zero? ? 2 : 1)
    end
    labels = [ 0, 6, 12, 18 ].map do |h|
      x, y = point(h, 200)
      tag.text("#{h}時", x: x, y: y + 5, "text-anchor": "middle", "font-size": 14, fill: "#546e7a")
    end
    safe_join(lines + labels)
  end

  # 輪の上に小窓の記号（H3 など）を直接書く（色の見本表を見比べなくて済む）
  def clock_label(plan)
    mid = (minutes_of(plan.starts_at) + minutes_of(plan.ends_at)) / 120.0
    x, y = point(mid, 150)
    color = DARK_PHASES.include?(plan.phase_code) ? "#ffffff" : "#0d3c61"
    tag.text(plan.window_code, x: x, y: y + 5, "text-anchor": "middle", "font-size": 14, "font-weight": "bold",
             fill: color)
  end

  def clock_center(plans, confirmed)
    plan_text = "予定 #{clock_hours(plans.map { |p| [ p.starts_at, p.ends_at ] })}"
    actual_text = confirmed ? "実際 #{clock_hours(plans.filter_map(&:actual_range))}" : "実際は夜に"
    safe_join([
      tag.text("外の輪＝予定", x: CENTER, y: CENTER - 16, "text-anchor": "middle", "font-size": 13, fill: "#78909c"),
      tag.text("内の輪＝実際", x: CENTER, y: CENTER + 4, "text-anchor": "middle", "font-size": 13, fill: "#78909c"),
      tag.text("#{plan_text} / #{actual_text}", x: CENTER, y: CENTER + 30, "text-anchor": "middle",
                                                "font-size": 16, "font-weight": "bold", fill: "#0d3c61")
    ])
  end

  # 時刻 → 円の上の点（真上が0時、右回り）
  def point(hour, radius)
    angle = (hour / 24.0 * 2 * Math::PI) - (Math::PI / 2)
    [ (CENTER + (radius * Math.cos(angle))).round(1), (CENTER + (radius * Math.sin(angle))).round(1) ]
  end

  def minutes_of(time)
    (time.hour * 60) + time.min
  end

  # 色を白へ混ぜて淡くする（にじんだ色）
  def tint(hex, ratio)
    rgb = hex.delete("#").scan(/../).map { |c| c.to_i(16) }
    "#" + rgb.map { |v| format("%02x", (v + ((255 - v) * ratio)).round) }.join
  end
end
