require "rails_helper"

RSpec.describe "小窓の作成（#14）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "A") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "作成画面が開ける" do
    get new_phase_window_path(phase)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("小窓を作る")
  end

  it "小窓を作ると、大窓の画面に出る" do
    post phase_windows_path(phase), params: { window: { number: 1, title: "労働基準法", measure: "achievement_rate" } }
    expect(response).to redirect_to(phase_path(phase))
    expect(phase.windows.first).to have_attributes(number: 1, title: "労働基準法", measure: "achievement_rate")

    get phase_path(phase)
    expect(response.body).to include("労働基準法")
  end

  it "題名が空なら保存せず、エラーを出す" do
    post phase_windows_path(phase), params: { window: { number: 1, title: "", measure: "plan_count" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("小窓の題名を入力してください")
  end

  it "1つの大窓に9つ目は作れない" do
    Window::NUMBERS.each { |n| phase.windows.create!(number: n, title: "窓#{n}") }
    get new_phase_window_path(phase)
    expect(response).to redirect_to(phase_path(phase))
    expect {
      post phase_windows_path(phase), params: { window: { number: 1, title: "9つ目" } }
    }.not_to change(Window, :count)
  end

  it "他人の大窓には小窓を作れない" do
    other_phase = create(:user).phases.find_by(code: "A")
    post phase_windows_path(other_phase), params: { window: { number: 1, title: "乗っ取り" } }
    expect(response).to have_http_status(:not_found)
    expect(other_phase.windows).to be_empty
  end
end
