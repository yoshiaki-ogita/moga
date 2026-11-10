require "rails_helper"

RSpec.describe Plan, type: :model do
  let(:window) { create(:user).phases.find_by(code: "B").windows.create!(number: 1, title: "地震・津波・火山") }

  it "題名があれば作れて、最初は「まだ」" do
    plan = window.plans.create!(title: "第1章 地震を読む")
    expect(plan).not_to be_done
    expect(Plan.undone).to include(plan)
  end

  it "題名は必須で、50文字まで" do
    expect(window.plans.build(title: "")).not_to be_valid
    expect(window.plans.build(title: "あ" * 51)).not_to be_valid
  end

  it "done_at が入っていれば「済み」" do
    plan = window.plans.create!(title: "第1章", done_at: Time.current)
    expect(plan).to be_done
    expect(Plan.done).to include(plan)
  end

  it "小窓を消すと、中の課題も一緒に消える（#18 の決裁）" do
    window.plans.create!(title: "第1章")
    expect { window.destroy }.to change(Plan, :count).by(-1)
  end
end
