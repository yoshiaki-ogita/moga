# ログインしたままの期限（#114）
# 最後に MOGA を開いてから2週間たつと、自動的にログアウトする（共用の端末で開いたままにならないように）
# 鍵の名前は Rails の決まりのまま（変えると全員が一度ログアウトになるため）
Rails.application.config.session_store :cookie_store, expire_after: 2.weeks
