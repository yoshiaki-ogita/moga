require "rails_helper"

RSpec.describe "記録の作成（#24）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:window) { user.phases.find_by(code: "A").windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate) }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "達成率型の小窓に、記録の入力欄があり、記録した日に今日が入っている" do
    get window_path(window)
    expect(response.body).to include("記録する", Date.current.iso8601)
  end

  it "記録を書くと、その小窓の記録になる" do
    post window_entries_path(window), params: { entry: { recorded_on: "2026-11-10", attempted_count: 20, achieved_count: 16, title: "労基法 第1回" } }
    expect(response).to redirect_to(window_path(window))
    entry = window.entries.last
    expect([ entry.attempted_count, entry.achieved_count, entry.title ]).to eq([ 20, 16, "労基法 第1回" ])
  end

  it "できた数がやった数より多いと保存せず、エラーを出す" do
    post window_entries_path(window), params: { entry: { recorded_on: "2026-11-10", attempted_count: 5, achieved_count: 6 } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("できた数はやった数以下にしてください")
  end

  it "他人の小窓には記録を書けない" do
    other_window = create(:user).phases.find_by(code: "A").windows.create!(number: 1, title: "他人の窓", measure: :achievement_rate)
    post window_entries_path(other_window), params: { entry: { recorded_on: "2026-11-10", attempted_count: 1, achieved_count: 1 } }
    expect(response).to have_http_status(:not_found)
    expect(other_window.entries).to be_empty
  end
end
