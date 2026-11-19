require "rails_helper"

# 科目ごとのまとめ表の「計算の係」のテスト（#132）
RSpec.describe PhaseScoreSummary do
  let(:phase) { create(:user).phases.find_by(code: "A") }

  def rate_window(number, title, target)
    phase.windows.create!(number: number, title: title, measure: :achievement_rate, target_count: target)
  end

  def record(window, attempted, achieved)
    window.entries.create!(recorded_on: Date.current, attempted_count: attempted, achieved_count: achieved)
  end

  def summary
    described_class.new(phase.reload.windows_by_number.values)
  end

  it "達成率型の小窓が無ければ、表は出さない（課題型は入れない）" do
    phase.windows.create!(number: 1, title: "課題型", measure: :plan_count)
    expect(summary.any?).to be(false)
  end

  it "小窓ごとに、全体の数・回答済み・正解・正解率・進み具合を出す（10問中8、全体1148 → 80%・1%）" do
    record(rate_window(1, "労働基準法", 1148), 10, 8)
    row = summary.rows.first
    expect([ row.target_count, row.attempted, row.achieved, row.accuracy_percent, row.progress_percent ])
      .to eq([ 1148, 10, 8, 80, 1 ])
  end

  it "番号の順に並ぶ" do
    rate_window(3, "雇用保険法", 700)
    rate_window(1, "労働基準法", 1148)
    expect(summary.rows.map { |r| r.window.number }).to eq([ 1, 3 ])
  end

  it "まだ解いていない小窓は、正解率が nil（「―」）で進み具合は 0%" do
    rate_window(2, "労災保険法", 700)
    row = summary.rows.first
    expect([ row.accuracy_percent, row.progress_percent ]).to eq([ nil, 0 ])
  end

  it "全体の数が空欄の小窓は、全体の数と進み具合が nil（「―」）" do
    record(rate_window(1, "労働基準法", nil), 10, 8)
    row = summary.rows.first
    expect([ row.target_count, row.progress_percent, row.accuracy_percent ]).to eq([ nil, nil, 80 ])
  end

  it "合計：全体の数の合計と回答済みの合計で進み具合を出す（(350+0) ÷ (1148+700) → 19%）" do
    record(rate_window(1, "労働基準法", 1148), 350, 280)
    rate_window(2, "労災保険法", 700)
    total = summary.total
    expect([ total.target_count, total.attempted, total.achieved, total.accuracy_percent, total.progress_percent ])
      .to eq([ 1848, 350, 280, 80, 19 ])
  end

  it "合計の進み具合は、全体の数がある小窓だけで数える（空欄の小窓の回答済みは入れない）" do
    record(rate_window(1, "労働基準法", 100), 50, 40)
    record(rate_window(2, "空欄", nil), 50, 25)
    total = summary.total
    expect([ total.attempted, total.progress_percent, total.accuracy_percent ]).to eq([ 100, 50, 65 ])
  end

  it "どの小窓にも全体の数が無ければ、合計の全体の数と進み具合も nil" do
    record(rate_window(1, "空欄", nil), 10, 8)
    expect([ summary.total.target_count, summary.total.progress_percent ]).to eq([ nil, nil ])
  end
end
