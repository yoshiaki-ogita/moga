require "rails_helper"

RSpec.describe "Home（曼荼羅）", type: :request do
  let(:user) { create(:user, name: "荻田", email: "ogita@example.com", password: "password123") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "真ん中に本人の名前、まわりに大窓 A〜H が並ぶ" do
    get home_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("荻田")
    Phase::CODES.each { |code| expect(response.body).to include("局面#{code}") }
  end

  it "#12 より前に登録した人（大窓がない人）にも、Home を開くと大窓ができる" do
    user.phases.destroy_all
    get home_path
    expect(user.phases.count).to eq(8)
  end

  it "大窓を押すと、その大窓の画面へ進む" do
    phase = user.phases.find_by(code: "A")
    get phase_path(phase)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("A 局面A")
  end

  it "他人の大窓の画面は開けない" do
    other_phase = create(:user).phases.first
    get phase_path(other_phase)
    expect(response).to have_http_status(:not_found)
  end
end
