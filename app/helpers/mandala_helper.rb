module MandalaHelper
  # この％より濃いマスは、字を白にして読みやすくする
  DARK_FROM = 60

  # 小窓の配列の決まり（#117、2026-11-15 作者の決定）。
  # どの大窓でも、窓6＝テーマの核、窓8＝1〜7を結ぶ糸（シナプス）
  WINDOW_ROLES = { 6 => "核", 8 => "シナプス" }.freeze
  WINDOW_ROLE_RULE = "窓6＝このテーマの核　窓8＝シナプス（1〜7を結ぶ糸）".freeze

  # マスに小さく添える役割の言葉。役割のない窓は nil
  def window_role(number)
    WINDOW_ROLES[number]
  end

  # 曼荼羅のマスの class（#30）。濃さそのものは CSS の --pct で決める
  def mandala_cell_class(percent)
    classes = [ "mandala__cell", "mandala__cell--shaded" ]
    classes << "mandala__cell--dark" if percent >= DARK_FROM
    classes.join(" ")
  end
end
