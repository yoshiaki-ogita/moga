require "rails_helper"

RSpec.describe "大窓の「なぜ」のメモ（#145）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "B") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "大窓の真ん中の球体から、メモを書く画面へ行ける" do
    get phase_path(phase)
    expect(response.body).to include(%(href="#{edit_phase_path(phase)}"), "なぜ？")
  end

  it "メモを書く画面に、問いかけと空欄がある" do
    get edit_phase_path(phase)
    expect(response.body).to include("なぜ　あなたはそこへ向かおうとしているのか？", "phase[memo]")
  end

  it "メモを保存すると、大窓の画面に出る（何度でも書き直せる）" do
    patch phase_path(phase), params: { phase: { name: "地域防災", memo: "家族と地域を守りたいから" } }
    expect(phase.reload.memo).to eq "家族と地域を守りたいから"

    patch phase_path(phase), params: { phase: { memo: "防災士として役に立ちたいから" } }
    get phase_path(phase)
    expect(response.body).to include("防災士として役に立ちたいから")
    expect(response.body).not_to include("家族と地域を守りたいから")
  end

  it "メモが空なら、大窓の画面にメモの枠は出ない" do
    get phase_path(phase)
    expect(response.body).not_to include("phase-memo")
  end

  it "1000文字を超えるメモは保存できない" do
    patch phase_path(phase), params: { phase: { memo: "あ" * 1001 } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(phase.reload.memo).to be_nil
  end
end
