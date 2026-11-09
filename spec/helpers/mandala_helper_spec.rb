require "rails_helper"

RSpec.describe MandalaHelper, type: :helper do
  it "60% 未満は字が青のまま、60% 以上は白い字の class が付く" do
    expect(helper.mandala_cell_class(59)).not_to include("mandala__cell--dark")
    expect(helper.mandala_cell_class(60)).to include("mandala__cell--dark")
  end
end
