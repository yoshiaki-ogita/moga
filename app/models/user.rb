class User < ApplicationRecord
  # パスワードは bcrypt でハッシュ化して password_digest に保存する
  has_secure_password

  # 大窓（局面）A〜H。利用者を消すと大窓も一緒に消える
  has_many :phases, dependent: :destroy
  has_many :windows, through: :phases
  has_many :plans, through: :windows
  has_many :entries, through: :windows

  # 登録と同時に大窓 A〜H を8つ作る（11/7 決裁）
  after_create :ensure_default_phases

  # メールアドレスは小文字にそろえて保存する（大文字・小文字ちがいの二重登録を防ぐ）
  before_save { self.email = email.downcase }

  validates :name, presence: true, length: { maximum: 50 }
  validates :email, presence: true,
                    length: { maximum: 255 },
                    format: { with: URI::MailTo::EMAIL_REGEXP },
                    uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 8 }, allow_nil: true

  # 足りない大窓だけを「局面A」〜「局面H」の仮の名前で作る（何度呼んでも8つより増えない）
  def ensure_default_phases
    existing = phases.pluck(:code)
    (Phase::CODES - existing).each do |code|
      phases.create!(code: code, name: "局面#{code}")
    end
  end
end
