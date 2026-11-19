require "rails_helper"

# 全体の数（#128）。例：過去問700問のうち 120問 回答、96問 正解
RSpec.describe "小窓の全体の数（#128）", type: :model do
  let(:phase) { create(:user).phases.find_by(code: "A") }
  let(:window) { phase.windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate, target_count: 700) }

  it "全体の数は空欄でもよい" do
    expect(phase.windows.build(number: 1, title: "x", measure: :achievement_rate)).to be_valid
  end

  it "全体の数は 1 以上の整数だけ" do
    expect(phase.windows.build(number: 1, title: "x", target_count: 0)).not_to be_valid
    expect(phase.windows.build(number: 1, title: "x", target_count: -5)).not_to be_valid
    expect(phase.windows.build(number: 1, title: "x", target_count: 1.5)).not_to be_valid
  end

  it "全体の数がある達成率型は、回答済み ÷ 全体の数（120 ÷ 700 → 17%）" do
    window.entries.create!(recorded_on: Date.current, attempted_count: 100, achieved_count: 80)
    window.entries.create!(recorded_on: Date.current, attempted_count: 20, achieved_count: 16)
    expect(window.progress_fraction).to eq([ 120, 700 ])
    expect(window.progress_percent).to eq(17)
  end

  it "正解率は 正解 ÷ 回答済み（96 ÷ 120 → 80%）" do
    window.entries.create!(recorded_on: Date.current, attempted_count: 120, achieved_count: 96)
    expect(window.accuracy_fraction).to eq([ 96, 120 ])
    expect(window.accuracy_percent).to eq(80)
  end

  it "まだ1問も解いていなければ、どちらも 0%" do
    expect(window.progress_percent).to eq(0)
    expect(window.accuracy_percent).to eq(0)
  end

  it "全体の数より多く解いても 100% で止まる（2周目など）" do
    window.entries.create!(recorded_on: Date.current, attempted_count: 800, achieved_count: 700)
    expect(window.progress_percent).to eq(100)
  end

  it "全体の数が空欄の達成率型は、今までどおり できた ÷ やった" do
    window.update!(target_count: nil)
    window.entries.create!(recorded_on: Date.current, attempted_count: 20, achieved_count: 16)
    expect(window.progress_fraction).to eq([ 16, 20 ])
    expect(window.uses_target?).to be(false)
  end

  it "課題型は全体の数が入っていても、今までどおり 済み ÷ 課題" do
    plan_window = phase.windows.create!(number: 2, title: "課題型", measure: :plan_count, target_count: 700)
    plan_window.plans.create!(title: "第1章", done_at: Time.current)
    plan_window.plans.create!(title: "第2章")
    expect(plan_window.progress_fraction).to eq([ 1, 2 ])
  end
end
