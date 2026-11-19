# ログインしたままの期限（#114）
# 最後に MOGA を開いてから2週間たつと、自動的にログアウトする（共用の端末で開いたままにならないように）
# 鍵の名前は、これまでの Rails の決まり（_moga_session）のまま。変えると全員が一度ログアウトになるため
# （名前を書かないと _session_id に変わってしまうので、はっきり書いておく）
Rails.application.config.session_store :cookie_store, key: "_moga_session", expire_after: 2.weeks
