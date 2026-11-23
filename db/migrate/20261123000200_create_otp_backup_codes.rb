# 二段の鍵の「予備の鍵」16個（守り2 ②、2026-11-23）
#   スマホを失くした時に、6桁の代わりに1回だけ使える。
#   鍵そのものは保存しない。鍵から作った「指紋」（code_digest）だけを保存する
class CreateOtpBackupCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_backup_codes do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :code_digest, null: false
      t.datetime :used_at
      t.timestamps
    end
    # 同じ人に同じ鍵が2つできないように（user_id で探す時の索引も兼ねる）
    add_index :otp_backup_codes, [ :user_id, :code_digest ], unique: true
  end
end
