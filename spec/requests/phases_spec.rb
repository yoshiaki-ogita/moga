require "rails_helper"

RSpec.describe "大窓の名前の編集（#13）", type: :request do
  let(:user) { create(:user, name: "荻田", email: "ogita@example.com", password: "password123") }
  let(:phase) { user.phases.find_by(code: "A") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "編集画面が開ける" do
    get edit_phase_path(phase)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("大窓 A の名前")
  end

  it "名前を変えると、Home の表示も変わる" do
    patch phase_path(phase), params: { phase: { name: "社労士受験合格" } }
    expect(response).to redirect_to(phase_path(phase))
    expect(phase.reload.name).to eq("社労士受験合格")

    get home_path
    expect(response.body).to include("社労士受験合格")
    expect(response.body).not_to include("局面A")
  end

  it "記号（A〜H）は変えられない" do
    patch phase_path(phase), params: { phase: { name: "社労士", code: "B" } }
    expect(phase.reload.code).to eq("A")
  end

  it "名前が空なら保存せず、エラーを出す" do
    patch phase_path(phase), params: { phase: { name: "" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("大窓の名前を入力してください")
    expect(phase.reload.name).to eq("局面A")
  end

  it "他人の大窓は編集できない" do
    other_phase = create(:user).phases.find_by(code: "A")
    get edit_phase_path(other_phase)
    expect(response).to have_http_status(:not_found)

    patch phase_path(other_phase), params: { phase: { name: "乗っ取り" } }
    expect(response).to have_http_status(:not_found)
    expect(other_phase.reload.name).to eq("局面A")
  end

  it "ログインしていなければ編集できない" do
    delete logout_path
    get edit_phase_path(phase)
    expect(response).to redirect_to(root_path)
  end
end
