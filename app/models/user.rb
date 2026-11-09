class User < ApplicationRecord
  # パスワードは bcrypt でハッシュ化して password_digest に保存する
  has_secure_password

  # メールアドレスは小文字にそろえて保存する（大文字・小文字ちがいの二重登録を防ぐ）
  before_save { self.email = email.downcase }

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true,
                    length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, allow_nil: true
end
