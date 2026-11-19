require "rails_helper"

RSpec.describe "使い方の画面（#115）", type: :request do
  it "ログインしていなくても読め、5つの手順が並ぶ" do
    get guide_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("MOGA の使い方", "大窓に名前をつける", "小窓を作る", "数え方を選ぶ",
                                     "記録を足す", "わたしの轍", "課題型", "達成率型", "TOPへ戻る")
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

    it "使い方の画面に、Home への現在地と戻り道が出る" do
      get guide_path
      expect(response.body).to include("現在地", "Homeへ戻る")
    end
  end
end
