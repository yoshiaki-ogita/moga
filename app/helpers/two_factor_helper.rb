# 二段階認証の設定画面で使う手伝い（守り2 ②）
module TwoFactorHelper
  # スマホのカメラで読む QR コード（画像ファイルを作らず、画面に直接描く）
  def otp_qr_svg(uri)
    svg = RQRCode::QRCode.new(uri).as_svg(
      module_size: 5, standalone: true, use_path: true, viewbox: true,
      svg_attributes: { class: "two-factor__qr-svg", role: "img", "aria-label": "スマホのアプリで読む QR コード" }
    )
    # rqrcode が作る図形の文字だけなので、そのまま画面に出してよい（利用者の入力は混ざらない）
    svg.html_safe
  end

  # 手で入れる時の種を、4文字ずつ区切って読みやすくする
  def otp_secret_for_reading(secret)
    secret.to_s.scan(/.{1,4}/).join(" ")
  end
end
