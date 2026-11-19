require "rails_helper"

RSpec.describe "使い方の画面（#115）", type: :request do
  it "ログインしていなくても読め、呼びかけの言葉と5つの手順が並ぶ" do
    get guide_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("MOGA の使い方", "真ん中の◯は、あなた自身です。",
                                     "あなた自身で、今の自分を8つに描いてみる", "大きな夢を、今日できる大きさに",
                                     "数え方は、あなたが決める", "数字は、うそをつかない", "朝・昼・晩、自分と向き合う",
                                     "わたしの轍", "TOPへ戻る")
  end

  it "結びと MOGA からのメッセージがある（歌詞は載せない）" do
    get guide_path
    expect(response.body).to include("あなたのそばに、また春よ、来い！", "MOGA から、あなたへ。",
                                     "松任谷由実さんの『春よ、来い』を口ずさみながら")
  end

  it "いちばん上に64の窓の図がある（押すと大きく見られる）" do
    get guide_path
    expect(response.body).to include("曼荼羅アート64の図", "guide_mandala64", 'target="_blank"')
  end

  it "TOP から使い方の画面へ行ける" do
    get root_path
    expect(response.body).to include(%(href="#{guide_path}"))
  end

  context "ログインしている時" do
    let(:user) { create(:user, password: "password123") }

    before do
      post login_path, params: { email: user.email, password: "password123" }
    end

    it "Home に「使い方を見る」の入口がある" do
      get home_path
      expect(response.body).to include("使い方を見る", %(href="#{guide_path}"))
    end

    it "小窓がまだ1つも無い時は、Home に「最初の一歩」が出る" do
      get home_path
      expect(response.body).to include("最初の一歩", "この大窓の名前を直す", "くわしくは「使い方」へ")
    end

    it "小窓を1つ作ったら、Home の「最初の一歩」は消える" do
      user.phases.find_by(code: "A").windows.create!(number: 1, title: "労働基準法")
      get home_path
      expect(response.body).not_to include("最初の一歩")
    end

    it "使い方の画面に、Home への現在地と戻り道が出る" do
      get guide_path
      expect(response.body).to include("現在地", "Homeへ戻る")
    end
  end
end
