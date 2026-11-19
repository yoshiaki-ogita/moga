require "rails_helper"

RSpec.describe "小窓の全体の数（#128）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "A") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "作成画面に「全体の数」の欄がある" do
    get new_phase_window_path(phase)
    expect(response.body).to include("全体の数", 'name="window[target_count]"')
  end

  it "全体の数を入れて小窓を作れる" do
    post phase_windows_path(phase),
         params: { window: { number: 1, title: "労働基準法", measure: "achievement_rate", target_count: 700 } }
    expect(phase.windows.first.target_count).to eq(700)
  end

  it "全体の数に 0 を入れると保存せず、エラーを出す" do
    post phase_windows_path(phase),
         params: { window: { number: 1, title: "労働基準法", measure: "achievement_rate", target_count: 0 } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("全体の数は0より大きい値にしてください")
  end

  it "小窓の画面に、回答済みと正解を並べて出す" do
    window = phase.windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate, target_count: 700)
    window.entries.create!(recorded_on: Date.current, attempted_count: 120, achieved_count: 96)
    get window_path(window)
    expect(response.body).to include("回答済み 120 ／ 700問（到達率 17%）", "正解 96 ／ 120問（正解率 80%）")
  end

  it "全体の数が空欄の小窓には、その2行を出さない" do
    window = phase.windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate)
    get window_path(window)
    expect(response.body).not_to include("回答済み")
  end
end
