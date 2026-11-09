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

RSpec.describe "大窓の画面に小窓が並ぶ（#15）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "A") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "中心に大窓の名前、まわりに小窓の題名が並ぶ" do
    phase.update!(name: "社労士受験合格")
    phase.windows.create!(number: 1, title: "労働基準法")
    phase.windows.create!(number: 2, title: "労災保険法")
    get phase_path(phase)
    expect(response.body).to include("社労士受験合格", "労働基準法", "労災保険法")
  end

  it "まだ小窓がない番号には「＋ 小窓を作る」が出て、その番号で作成画面に進む" do
    phase.windows.create!(number: 1, title: "労働基準法")
    get phase_path(phase)
    expect(response.body.scan("＋ 小窓を作る").size).to eq(7)
    expect(response.body).to include(new_phase_window_path(phase, number: 2))
  end

  it "その大窓の小窓だけが並ぶ（ほかの大窓の小窓は出ない）" do
    phase.windows.create!(number: 1, title: "労働基準法")
    user.phases.find_by(code: "B").windows.create!(number: 1, title: "地震・津波")
    get phase_path(phase)
    expect(response.body).to include("労働基準法")
    expect(response.body).not_to include("地震・津波")
  end
end
