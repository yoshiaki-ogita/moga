# 「お試しで見る」（SPF からのぞく人のための玄関）。登録なしで、見本の曼荼羅64を見て回れる
#   見本の利用者は見るだけ。書き込みは ApplicationController#block_demo_writes で止める
class DemoSessionsController < ApplicationController
  # 機械で何千回も押される嫌がらせに備え、ログインと同じく同じ相手（IP アドレス）からは3分間に10回まで
  rate_limit to: SessionsController::LOGIN_LIMIT, within: SessionsController::LOGIN_WITHIN, only: :create,
             store: SessionsController::RATE_LIMIT_STORE, name: "demo",
             with: -> { redirect_to root_path, alert: "お試しの回数が多すぎます。しばらく待ってから、もう一度お試しください" }

  def create
    log_in(DemoAccount.prepare!)
    redirect_to home_path, notice: "お試し中です（見るだけ）。気に入ったら、ログアウトして自分で登録してください"
  end
end
