require "rails_helper"

RSpec.describe "二段階認証の注意点", type: :request do
  let(:notice_words) do
    [ "＜MOGAを二段階認証で管理する場合の注意点＞", "二段階認証とは", "始める前に", "重要事項", "お断り",
     "予備の鍵16個は、必ず紙に控えてください。", "アプリ製作者にも元に戻せません。",
     "電話やメールで聞かれたら、それは詐欺です。", "ご自身の判断と責任でお願いします。" ]
  end

  it "注意点だけの画面は、ログインしていなくても読める" do
    get two_factor_notice_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(*notice_words, "TOPへ戻る")
  end

  it "使い方の画面から、注意点の画面へ行ける" do
    get guide_path
    expect(response.body).to include(two_factor_notice_path)
  end

  context "ログインしている時" do
    let(:user) { create(:user) }

    before { post login_path, params: { email: user.email, password: "password123" } }

    it "二段階認証を使う前の画面では、「二段階認証を使う」ボタンより上に注意点が出る" do
      get two_factor_path
      expect(response.body).to include(*notice_words)
      expect(response.body.index("重要事項")).to be < response.body.index("二段階認証を使う</a>")
    end

    it "二段階認証を使っている時は、注意点の画面へのリンクが出る" do
      user.update!(otp_secret: ROTP::Base32.random, otp_enabled_at: Time.current)
      get two_factor_path
      expect(response.body).to include("二段階認証の注意点を読む", two_factor_notice_path)
    end
  end
end
