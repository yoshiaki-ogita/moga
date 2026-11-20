require "rails_helper"

RSpec.describe "お試しで見る（登録なし・見るだけ）", type: :request do
  it "TOP に「お試しで見る」のボタンがある" do
    get root_path
    expect(response.body).to include("お試しで見る（登録なし・見るだけ）", demo_session_path)
  end

  it "押すと、見本の利用者でログインし、見本の曼荼羅64と帯が出る" do
    post demo_session_path
    expect(response).to redirect_to(home_path)
    follow_redirect!
    expect(response.body).to include("お試し中（見るだけ）です。", "資格に挑戦する", "ITとAIを学ぶ")

    demo = DemoAccount.user
    expect(demo.windows.count).to eq 64
    expect(demo.phases.find_by(code: "B").memo).to be_present
  end

  it "今日の「わたしの轍」にも見本が入っている" do
    post demo_session_path
    get diary_path(Date.current)
    expect(response.body).to include("Railsの復習", "△ の予定は、明日にもう一度")
  end

  it "何度押しても、見本の利用者は1人だけ" do
    2.times { post demo_session_path }
    expect(User.where(email: DemoAccount::EMAIL).count).to eq 1
  end

  it "お試し中は書き込めない（大窓の名前を直そうとしても変わらない）" do
    post demo_session_path
    phase = DemoAccount.user.phases.find_by(code: "A")
    patch phase_path(phase), params: { phase: { name: "いたずら" } }
    expect(response).to have_http_status(:see_other)
    expect(phase.reload.name).to eq "資格に挑戦する"
    follow_redirect!
    expect(response.body).to include("お試し中は見るだけです。")
  end

  it "お試し中でもログアウトはできる" do
    post demo_session_path
    delete logout_path
    expect(response).to redirect_to(root_path)
    get home_path
    expect(response).to redirect_to(root_path)
  end

  it "見本用のアドレスは、ふつうの登録では使えない" do
    post users_path, params: { user: { name: "だれか", email: "demo@moga.example", password: "password123", password_confirmation: "password123" } }
    expect(User.where(email: "demo@moga.example")).to be_empty
  end

  it "ふつうの利用者には帯が出ず、書き込みもできる" do
    user = create(:user, password: "password123")
    post login_path, params: { email: user.email, password: "password123" }
    phase = user.phases.find_by(code: "A")
    patch phase_path(phase), params: { phase: { name: "社労士" } }
    expect(phase.reload.name).to eq "社労士"
    get home_path
    expect(response.body).not_to include("お試し中（見るだけ）です。")
  end
end
