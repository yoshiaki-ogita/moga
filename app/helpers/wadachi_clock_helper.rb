# 轍の⑦「今日の24時間」の円グラフ（SVG）を描く
#   真上が0時、右回り。外の輪＝予定（はっきりした青）、内の輪＝実際（同じ青を白でにじませた淡い色）
#   色は大窓ごとの青の濃淡（Aが一番濃く、Hが一番淡い）。参考：永田ゆかり『データ視覚化のデザイン』
#   このヘルパーは絵（SVG のタグ）を組み立てる仕事だけ。点・扇形・色・合計の計算は
#   WadachiClockGeometry（app/services）に任せる（運営事務局からの課題 #6、Issue #101）
module WadachiClockHelper
  PHASE_BLUES = {
    "A" => "#0d3c61", "B" => "#12507f", "C" => "#1565c0", "D" => "#1e88e5",
    "E" => "#42a5f5", "F" => "#64b5f6", "G" => "#90caf9", "H" => "#bbdefb"
  }.freeze
  DARK_PHASES = %w[A B C D].freeze # この大窓の上の字は白
  CENTER = WadachiClockGeometry::CENTER
  PLAN_RING = [ 130, 170 ].freeze   # 外の輪（予定）の内側・外側の半径
  ACTUAL_RING = [ 94, 122 ].freeze  # 内の輪（実際）
  ACTUAL_TINT = 0.45                # 実際の色を白へにじませる割合

  def wadachi_clock(diary)
    plans = diary.diary_plans.select(&:persisted?)
    confirmed = plans.any?(&:checked?)
    parts = [ clock_background, clock_rings(confirmed), clock_plan_arcs(plans), clock_actual_arcs(plans),
              clock_ticks, *plans.map { |plan| clock_label(plan) }, clock_center(plans, confirmed) ]
    tag.svg(safe_join(parts), viewBox: "-20 -5 460 430", class: "wadachi-clock__svg", role: "img",
                              aria: { label: "今日の24時間の円グラフ" })
  end

  # 「7時間」「6.5時間」のような合計（計算は WadachiClockGeometry）
  def clock_hours(ranges)
    WadachiClockGeometry.hours_label(ranges)
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

  # 外の輪：予定（はっきりした青）
  def clock_plan_arcs(plans)
    safe_join(plans.map do |plan|
      clock_arc(plan.starts_at, plan.ends_at, PLAN_RING, PHASE_BLUES[plan.phase_code], "#ffffff", 2)
    end)
  end

  # 内の輪：実際（同じ青を白でにじませた淡い色）
  def clock_actual_arcs(plans)
    safe_join(plans.select(&:actual?).map do |plan|
      color = PHASE_BLUES[plan.phase_code]
      clock_arc(*plan.actual_range, ACTUAL_RING, WadachiClockGeometry.tint(color, ACTUAL_TINT), color, 1.2)
    end)
  end

  def clock_arc(starts_at, ends_at, (inner, outer), fill, stroke, width)
    d = WadachiClockGeometry.arc_path(starts_at, ends_at, inner, outer)
    tag.path(d: d, fill: fill, stroke: stroke, "stroke-width": width, "stroke-linejoin": "round")
  end

  # 24時間の目盛り（6時間ごとに長く太く）と、0・6・12・18時の字
  def clock_ticks
    safe_join(clock_tick_lines + clock_tick_labels)
  end

  def clock_tick_lines
    (0..23).map do |h|
      long = (h % 6).zero?
      x1, y1 = WadachiClockGeometry.point(h, 174)
      x2, y2 = WadachiClockGeometry.point(h, long ? 186 : 180)
      tag.line(x1: x1, y1: y1, x2: x2, y2: y2, stroke: "#90a4ae", "stroke-width": long ? 2 : 1)
    end
  end

  def clock_tick_labels
    [ 0, 6, 12, 18 ].map do |h|
      x, y = WadachiClockGeometry.point(h, 200)
      tag.text("#{h}時", x: x, y: y + 5, "text-anchor": "middle", "font-size": 14, fill: "#546e7a")
    end
  end

  # 輪の上に小窓の記号（H3 など）を直接書く（色の見本表を見比べなくて済む）
  def clock_label(plan)
    x, y = WadachiClockGeometry.point(WadachiClockGeometry.mid_hour(plan.starts_at, plan.ends_at), 150)
    color = DARK_PHASES.include?(plan.phase_code) ? "#ffffff" : "#0d3c61"
    tag.text(plan.window_code, x: x, y: y + 5, "text-anchor": "middle", "font-size": 14, "font-weight": "bold",
             fill: color)
  end

  # 真ん中：予定と、できた時間。確かめた日は、できた時間を一言でほめる（#123）
  def clock_center(plans, confirmed)
    done = plans.filter_map(&:actual_range)
    lines = [ clock_center_note("外の輪＝予定", -24), clock_center_note("内の輪＝できた", -4),
              clock_center_total(plans, done, confirmed) ]
    lines << clock_cheer(done) if confirmed
    safe_join(lines)
  end

  def clock_center_note(text, dy)
    tag.text(text, x: CENTER, y: CENTER + dy, "text-anchor": "middle", "font-size": 13, fill: "#78909c")
  end

  def clock_center_total(plans, done, confirmed)
    plan_text = "予定 #{clock_hours(plans.map { |p| [ p.starts_at, p.ends_at ] })}"
    done_text = confirmed ? "できた #{clock_hours(done)}" : "実際は夜に"
    tag.text("#{plan_text} / #{done_text}", x: CENTER, y: CENTER + 22, "text-anchor": "middle",
                                            "font-size": 16, "font-weight": "bold", fill: "#0d3c61")
  end

  def clock_cheer(done)
    text = done.any? ? "よく進みました！" : "明日に回して、また一歩！"
    tag.text(text, x: CENTER, y: CENTER + 46, "text-anchor": "middle", "font-size": 14, "font-weight": "bold",
                   fill: "#1565c0")
  end
end
