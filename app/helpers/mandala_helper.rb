module MandalaHelper
  # この％より濃いマスは、字を白にして読みやすくする
  DARK_FROM = 60

  # 曼荼羅のマスの class（#30）。濃さそのものは CSS の --pct で決める
  def mandala_cell_class(percent)
    classes = [ "mandala__cell", "mandala__cell--shaded" ]
    classes << "mandala__cell--dark" if percent >= DARK_FROM
    classes.join(" ")
  end
end
