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

  # Home の曼荼羅に並べる大窓（#35 Controller から移した）
  # 足りない大窓を用意し、大窓 → 小窓 → 課題・記録をまとめて読み込んで（#34 N+1対策）、記号 A〜H で引ける形で返す
  def mandala_phases
    ensure_default_phases
    ActiveRecord::Associations::Preloader.new(records: [ self ], associations: { phases: :windows }).call
    Window.preload_for_progress(phases.flat_map(&:windows))
    phases.index_by(&:code)
  end

  # 全体の進捗率（#28）＝大窓 A〜H の進捗率の平均
  def progress_rate
    return 0.0 if phases.empty?

    phases.sum(&:progress_rate) / phases.size
  end

  def progress_percent
    (progress_rate * 100).round
  end

  # 足りない大窓だけを「局面A」〜「局面H」の仮の名前で作る（何度呼んでも8つより増えない）
  def ensure_default_phases
    existing = phases.pluck(:code)
    (Phase::CODES - existing).each do |code|
      phases.create!(code: code, name: "局面#{code}")
    end
  end
end
