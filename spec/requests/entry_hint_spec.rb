require "rails_helper"

RSpec.describe "記録の欄の説明（#116）", type: :request do
  let(:user) { create(:user, password: "password123") }
  let(:window) { user.phases.find_by(code: "A").windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate) }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  it "達成率型の小窓の記録の欄の上に、何を数えるかの説明と例が出る" do
    get window_path(window)
    expect(response.body).to include("やった数とできた数は、小窓ごとに自分で決めます。",
                                     "やった数＝解いた問題の数、できた数＝正解した数",
                                     "やった数＝歩こうとした日数、できた数＝歩けた日数")
  end

  it "記録を直す画面にも、同じ説明が出る" do
    entry = window.entries.create!(recorded_on: Date.current, attempted_count: 10, achieved_count: 8)
    get edit_entry_path(entry)
    expect(response.body).to include("やった数とできた数は、小窓ごとに自分で決めます。")
  end
end
