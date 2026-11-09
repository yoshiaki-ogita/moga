require "rails_helper"

# #8 テストヘルパーの導入：FactoryBot が使える状態になっているかを確かめる
RSpec.describe "FactoryBot の設定" do
  it "spec の中で create・build を FactoryBot. なしで呼べる" do
    expect(self).to respond_to(:create)
    expect(self).to respond_to(:build)
  end

  it "factories の定義がすべて正しく作れる（lint）" do
    expect { FactoryBot.lint }.not_to raise_error
  end
end
