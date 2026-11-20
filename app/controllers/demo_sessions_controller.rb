# 「お試しで見る」（SPF からのぞく人のための玄関）。登録なしで、見本の曼荼羅64を見て回れる
#   見本の利用者は見るだけ。書き込みは ApplicationController#block_demo_writes で止める
class DemoSessionsController < ApplicationController
  def create
    log_in(DemoAccount.prepare!)
    redirect_to home_path, notice: "お試し中です（見るだけ）。気に入ったら、ログアウトして自分で登録してください"
  end
end
