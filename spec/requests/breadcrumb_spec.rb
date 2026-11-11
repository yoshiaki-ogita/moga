require "rails_helper"

# 現在地（#31）：どの画面でも現在地が分かり、上の階層へ戻れる
RSpec.describe "現在地（パンくず #31）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "A") }
  let(:window) { phase.windows.create!(number: 1, title: "労働基準法", measure: :plan_count) }
  let(:plan) { window.plans.create!(title: "第1章") }
  let(:entry) do
    phase.windows.create!(number: 2, title: "過去問", measure: :achievement_rate)
         .entries.create!(recorded_on: Date.current, attempted_count: 1, achieved_count: 1)
  end

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "Home は「現在地：Home」" do
    get home_path
    expect(response.body).to include("現在地：", '<span aria-current="page">Home</span>')
  end

  it "大窓・小窓・直す画面のどれにも、Home へ戻るリンクと現在地がある" do
    {
      phase_path(phase) => "A 局面A",
      edit_phase_path(phase) => "名前を直す",
      new_phase_window_path(phase) => "小窓を作る",
      window_path(window) => "窓1 労働基準法",
      edit_window_path(window) => "直す",
      edit_plan_path(plan) => "課題を直す",
      edit_entry_path(entry) => "記録を直す"
    }.each do |path, current|
      get path
      expect(response.body).to include(%(<a href="#{home_path}">Home</a>), %(<span aria-current="page">#{current}</span>))
    end
  end

  it "小窓の下の画面からは、大窓と小窓へも戻れる" do
    get edit_plan_path(plan)
    expect(response.body).to include(%(href="#{phase_path(phase)}"), %(href="#{window_path(window)}"))
  end
end
