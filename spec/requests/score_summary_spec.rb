require "rails_helper"

RSpec.describe "科目ごとのまとめ表（#132）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:phase) { user.phases.find_by(code: "A") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "大窓の画面に、科目ごとの行と合計を出す" do
    window = phase.windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate, target_count: 1148)
    window.entries.create!(recorded_on: Date.current, attempted_count: 10, achieved_count: 8)
    phase.windows.create!(number: 2, title: "労災保険法", measure: :achievement_rate, target_count: 700)
    get phase_path(phase)
    expect(response.body).to include("科目ごとのまとめ表", "窓1 労働基準法", "窓2 労災保険法", "合計", "1848", "80%")
  end

  it "達成率型の小窓が無ければ、まとめ表は出さない" do
    phase.windows.create!(number: 1, title: "課題型", measure: :plan_count)
    get phase_path(phase)
    expect(response.body).not_to include("科目ごとのまとめ表")
  end
end
