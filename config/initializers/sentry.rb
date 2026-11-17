# エラー監視（#92）。本番で起きたエラーを Sentry に知らせる
#   たとえ：家の火災報知器。火（エラー）が出たら、住人（開発者）にすぐ知らせてくれる
#   ・SENTRY_DSN（知らせる先の住所）は Render の環境変数に置く。コードには書かない
#   ・SENTRY_DSN が無い所（開発・テスト・自分のMac）では何も送らない
if ENV["SENTRY_DSN"].present?
  Sentry.init do |config|
    config.dsn = ENV["SENTRY_DSN"]
    # 本番だけで動かす
    config.enabled_environments = %w[production]
    # エラーの前に何が起きていたか（どの画面を開いたか等）の足あとも一緒に送る
    config.breadcrumbs_logger = %i[active_support_logger http_logger]
    # 個人情報（メールアドレス・IPアドレス・Cookie・入力した中身）は送らない
    config.send_default_pii = false
    # 速さの計測（パフォーマンス監視）は使わない。エラーだけを知らせる
    config.traces_sample_rate = 0.0
  end
end

# 火災報知器の「試しの知らせ」（一時的なもの。届いたのを確かめたら次の PR で消す）
#   本番の MOGA が立ち上がった時に1回だけ、Sentry へ「試しです」と知らせる
if ENV["SENTRY_DSN"].present?
  Rails.application.config.after_initialize do
    Sentry.capture_message("MOGA の火災報知器の試し：本番の MOGA が立ち上がりました")
  end
end
