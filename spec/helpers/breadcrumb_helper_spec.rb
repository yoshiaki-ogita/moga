require "rails_helper"

RSpec.describe BreadcrumbHelper, type: :helper do
  it "配列はリンク、最後の文字は今いる画面として出す" do
    html = helper.breadcrumb([ "Home", "/home" ], [ "A 社労士", "/phases/1" ], "窓1 労働基準法")
    expect(html).to include('aria-label="現在地"', "現在地：")
    expect(html).to include('<a href="/home">Home</a> ＞ <a href="/phases/1">A 社労士</a> ＞ <span aria-current="page">窓1 労働基準法</span>')
  end
end
