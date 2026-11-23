# 二段の鍵（守り2、2026-11-23）
#
# 一言で言うと：パスワード（1本目の鍵）に加えて、スマホのアプリが30秒ごとに出す6桁の数字（2本目の鍵）を確かめる。
# たとえ：玄関の鍵に、30秒ごとに番号が変わるダイヤル錠をもう1つ付ける。
#         番号の出し方の「種」（otp_secret）は、MOGA と本人のスマホだけが持っている。
#         パスワードを盗まれても、スマホが無ければ中に入れない。
#
# 使うかどうかは、利用者が選ぶ（作者の決定）。使わない人は、これまでどおりパスワードだけでログインできる。
# お試しの見本の利用者は、二段の鍵を使えない（みんなで使う見本の部屋のため）。
module TwoFactor
  extend ActiveSupport::Concern

  ISSUER = "MOGA".freeze
  # スマホの時計が少し遅れていても、ひとつ前の数字（30秒前まで）は受け付ける
  DRIFT_BEHIND = 30

  def otp_enabled?
    otp_enabled_at.present?
  end

  # 設定を始める：新しい種を作って覚える。
  # この時点では、まだ二段の鍵は効かない（enable_otp! で6桁を1回合わせて、初めて効く）
  def prepare_otp!
    return false if demo_user? || otp_enabled?

    update!(otp_secret: ROTP::Base32.random)
  end

  # スマホのアプリに種を渡すための文字列（次の PR で、これを QR コードにして画面に出す）
  def otp_provisioning_uri
    return if otp_secret.blank?

    totp.provisioning_uri(email)
  end

  # 6桁を1回合わせたら、二段の鍵を使い始める（スマホに正しく種が入ったことの確かめを兼ねる）
  def enable_otp!(code)
    return false if demo_user? || otp_enabled?
    return false unless verify_otp(code)

    update!(otp_enabled_at: Time.current)
  end

  # やめる時は、パスワードと6桁の両方が要る（他人が勝手に外せないように）
  def disable_otp!(password:, code:)
    return false unless otp_enabled?
    return false unless authenticate(password)
    return false unless verify_otp(code)

    update!(otp_secret: nil, otp_enabled_at: nil, otp_last_used_at: nil)
  end

  # 6桁が合っているか。合っていれば、その時刻を覚えて同じ6桁の使い回しを止める
  #   全角の数字（１２３４５６）や、間の空白・ハイフンも受け付ける
  def verify_otp(code)
    return false if otp_secret.blank?

    digits = code.to_s.unicode_normalize(:nfkc).gsub(/[\s-]/, "")
    return false unless digits.match?(/\A\d{6}\z/)

    matched_at = totp.verify(digits, drift_behind: DRIFT_BEHIND, after: otp_last_used_at&.to_i)
    return false unless matched_at

    update_column(:otp_last_used_at, Time.zone.at(matched_at))
    true
  end

  def demo_user?
    email == DemoAccount::EMAIL
  end

  private

  def totp
    ROTP::TOTP.new(otp_secret, issuer: ISSUER)
  end
end
