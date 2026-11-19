require "rails_helper"

# 月ごとの成績表の「計算の係」のテスト（#130）
RSpec.describe MonthlyScoreTable do
  let(:phase) { create(:user).phases.find_by(code: "A") }
  let(:window) { phase.windows.create!(number: 1, title: "労働基準法", measure: :achievement_rate, target_count: 1148) }
  let(:today) { Date.new(2026, 11, 19) }

  def record(date, attempted, achieved)
    window.entries.create!(recorded_on: Date.parse(date), attempted_count: attempted, achieved_count: achieved)
  end

  def rows
    described_class.new(window.reload, today: today).rows
  end

  it "記録が無ければ、行は無い" do
    expect(rows).to eq([])
  end

  it "同じ月の記録は1行にまとめる（9月：200問中160 と 100問中80 → 300問中240、80%）" do
    record("2026-09-10", 200, 160)
    record("2026-09-30", 100, 80)
    september = rows.first
    expect([ september.month, september.attempted, september.achieved, september.accuracy_percent ])
      .to eq([ Date.new(2026, 9, 1), 300, 240, 80 ])
  end

  it "最初の記録の月から今月まで並び、累計を足していく（記録の無い月は 0）" do
    record("2026-09-30", 300, 240)
    record("2026-11-11", 10, 8)
    expect(rows.map { |r| [ r.month.month, r.attempted, r.cumulative ] })
      .to eq([ [ 9, 300, 300 ], [ 10, 0, 300 ], [ 11, 10, 310 ] ])
  end

  it "記録の無い月の正解率は nil（表では「―」）" do
    record("2026-09-30", 300, 240)
    expect(rows.second.accuracy_percent).to be_nil
  end

  it "累計 ÷ 全体の数 の％（300 ÷ 1148 → 26%）" do
    record("2026-09-30", 300, 240)
    expect(rows.first.cumulative_percent).to eq(26)
  end

  it "全体の数が無い小窓は、累計の％を出さない" do
    window.update!(target_count: nil)
    record("2026-09-30", 300, 240)
    expect(rows.first.cumulative_percent).to be_nil
  end

  it "累計の％は 100% で止まる" do
    record("2026-09-30", 1500, 1200)
    expect(rows.first.cumulative_percent).to eq(100)
  end

  it "年をまたいでも1か月ずつ並ぶ（2026年12月 → 2027年1月）" do
    record("2026-12-31", 10, 8)
    expect(described_class.new(window.reload, today: Date.new(2027, 1, 5)).rows.map(&:month))
      .to eq([ Date.new(2026, 12, 1), Date.new(2027, 1, 1) ])
  end
end
