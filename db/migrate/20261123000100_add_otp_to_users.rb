# 二段の鍵（守り2、2026-11-23）
#   otp_secret       … スマホのアプリと MOGA だけが持つ「6桁の数字を出す種」
#   otp_enabled_at   … 二段の鍵を使い始めた日時（空なら、これまでどおりパスワードだけでログイン）
#   otp_last_used_at … 最後に通った6桁の時刻（同じ6桁の使い回しを止めるため）
class AddOtpToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :otp_secret, :string
    add_column :users, :otp_enabled_at, :datetime
    add_column :users, :otp_last_used_at, :datetime
  end
end
