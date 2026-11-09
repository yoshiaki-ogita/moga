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

RSpec.describe "記録の一覧（#25）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:window) { user.phases.find_by(code: "A").windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate) }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "記録がない時は、書いてみましょうと出る" do
    get window_path(window)
    expect(response.body).to include("これまでの記録（0）", "記録はまだありません")
  end

  it "記録した日・やった数・できた数・題名が、新しい日付を上にして並ぶ" do
    window.entries.create!(recorded_on: Date.new(2026, 11, 9), attempted_count: 10, achieved_count: 7, title: "古い記録")
    window.entries.create!(recorded_on: Date.new(2026, 11, 10), attempted_count: 20, achieved_count: 16, title: "新しい記録")
    get window_path(window)
    expect(response.body).to include("これまでの記録（2）", "2026年11月10日", "新しい記録")
    expect(response.body.index("新しい記録")).to be < response.body.index("古い記録")
  end
end

RSpec.describe "記録の編集（#26）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:window) { user.phases.find_by(code: "A").windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate) }
  let!(:entry) { window.entries.create!(recorded_on: Date.new(2026, 11, 10), attempted_count: 20, achieved_count: 16, title: "労基法 第1回") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "一覧に「直す」があり、直す画面に今の値が入っている" do
    get window_path(window)
    expect(response.body).to include(edit_entry_path(entry))
    get edit_entry_path(entry)
    expect(response.body).to include("記録を直す", "労基法 第1回", "保存する")
  end

  it "直すと保存し直され、小窓の画面に戻る" do
    patch entry_path(entry), params: { entry: { achieved_count: 18 } }
    expect(response).to redirect_to(window_path(window))
    expect(entry.reload.achieved_count).to eq(18)
  end

  it "できた数がやった数より多いと保存せず、エラーを出す" do
    patch entry_path(entry), params: { entry: { achieved_count: 21 } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(entry.reload.achieved_count).to eq(16)
  end

  it "他人の記録は直せない" do
    other_entry = create(:user).phases.find_by(code: "A").windows.create!(number: 1, title: "他人の窓", measure: :achievement_rate)
                               .entries.create!(recorded_on: Date.current, attempted_count: 1, achieved_count: 1)
    get edit_entry_path(other_entry)
    expect(response).to have_http_status(:not_found)
    patch entry_path(other_entry), params: { entry: { achieved_count: 0 } }
    expect(response).to have_http_status(:not_found)
    expect(other_entry.reload.achieved_count).to eq(1)
  end
end
