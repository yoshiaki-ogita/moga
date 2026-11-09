require "rails_helper"

RSpec.describe Window, type: :model do
  let(:phase) { create(:user).phases.find_by(code: "A") }

  it "番号・題名・数え方があれば作れる" do
    window = phase.windows.build(number: 1, title: "労働基準法", measure: :achievement_rate)
    expect(window).to be_valid
  end

  it "数え方を選ばなければ課題型になる" do
    expect(phase.windows.build(number: 1, title: "労働基準法")).to be_plan_count
  end

  it "題名は必須で、30文字まで" do
    expect(phase.windows.build(number: 1, title: "")).not_to be_valid
    expect(phase.windows.build(number: 1, title: "あ" * 31)).not_to be_valid
  end

  it "番号は 1〜8 だけ" do
    expect(phase.windows.build(number: 0, title: "x")).not_to be_valid
    expect(phase.windows.build(number: 9, title: "x")).not_to be_valid
  end

  it "同じ大窓に同じ番号は2つ作れない" do
    phase.windows.create!(number: 1, title: "労働基準法")
    expect(phase.windows.build(number: 1, title: "労災保険法")).not_to be_valid
  end

  it "ない数え方は選べない" do
    expect(phase.windows.build(number: 1, title: "x", measure: "unknown")).not_to be_valid
  end
end
