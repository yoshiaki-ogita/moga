require "rails_helper"

RSpec.describe WadachiClockHelper, type: :helper do
  let(:user) { create(:user) }
  let(:window) { user.phases.find_by(code: "D").windows.create!(number: 1, title: "長距離ウォーキング") }
  let(:diary) { user.diaries.create!(diary_on: Date.new(2026, 11, 17)) }

  it "予定だけの日は、内の輪が点線で「実際は夜に」と出る" do
    diary.diary_plans.create!(starts_at: "07:30", ends_at: "10:00", window: window)
    svg = helper.wadachi_clock(diary.reload)
    expect(svg).to include("<svg", "D1", "予定 2.5時間 / 実際は夜に", 'stroke-dasharray="4 4"', 'fill="#1e88e5"')
  end

  it "実際を確かめると、内の輪に淡い色が入り、合計が出る" do
    diary.diary_plans.create!(starts_at: "07:30", ends_at: "10:00", window: window, actual_starts_at: "08:00", actual_ends_at: "09:00")
    svg = helper.wadachi_clock(diary.reload)
    expect(svg).to include("予定 2.5時間 / 実際 1時間", 'fill="#83bef1"')
    expect(svg).not_to include("stroke-dasharray")
  end

  it "合計は「7時間」「6.5時間」の形" do
    t = ->(s) { Time.zone.parse("2000-01-01 #{s}") }
    expect(helper.clock_hours([ [ t["05:00"], t["06:30"] ] ])).to eq("1.5時間")
    expect(helper.clock_hours([ [ t["05:00"], t["12:00"] ] ])).to eq("7時間")
  end
end
