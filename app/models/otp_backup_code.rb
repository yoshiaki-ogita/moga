# 二段階認証の「予備の鍵」（守り2 ②）
#   スマホを失くした時に、6桁の代わりに1回だけ使える鍵。1人に16個。
#   たとえ：合鍵をそのまま金庫に入れず、合鍵の「指紋」だけを控えておく。
#           控え（code_digest）が盗まれても、そこから合鍵は作れない。
class OtpBackupCode < ApplicationRecord
  belongs_to :user

  scope :unused, -> { where(used_at: nil) }

  # 鍵から指紋を作る。全角・大文字・空白・ハイフンの違いは同じ鍵とみなす
  def self.digest(code)
    normalized = code.to_s.unicode_normalize(:nfkc).downcase.gsub(/[\s-]/, "")
    OpenSSL::HMAC.hexdigest("SHA256", digest_key, normalized)
  end

  # 指紋づくりの秘密は、MOGA の秘密の親鍵（secret_key_base）から、この用途専用に作る
  def self.digest_key
    @digest_key ||= Rails.application.key_generator.generate_key("otp_backup_codes", 32)
  end
end
