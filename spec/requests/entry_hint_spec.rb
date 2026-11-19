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
                                     "達成率＝できた数 ÷ やった数",
                                     "例1：やった数＝解いた問題の数、できた数＝正解した数",
                                     "例2：やった数＝ボールを投げた回数、できた数＝かごに入った回数（10回投げて7回入ったら 70%）")
  end

  it "記録を直す画面にも、同じ説明が出る" do
    entry = window.entries.create!(recorded_on: Date.current, attempted_count: 10, achieved_count: 8)
    get edit_entry_path(entry)
    expect(response.body).to include("やった数とできた数は、小窓ごとに自分で決めます。")
  end

  it "全体の数がある小窓では、過去問の言葉（回答・正解・到達率）で説明し、ボールの例は出さない" do
    window.update!(target_count: 1148)
    get window_path(window)
    expect(response.body).to include("やった数＝回答した問題の数、できた数＝正解した問題の数",
                                     "正解率＝正解数 ÷ 回答数、到達率＝回答数 ÷ この科目の過去問数（「全体の数」に入れた 1148問）")
    expect(response.body).not_to include("ボールを投げた回数")
  end
end
