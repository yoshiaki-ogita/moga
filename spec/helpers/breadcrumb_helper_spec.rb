require "rails_helper"

RSpec.describe BreadcrumbHelper, type: :helper do
  it "配列はリンク、最後の文字は今いる画面として出す" do
    html = helper.breadcrumb([ "Home", "/home" ], [ "A 社労士", "/phases/1" ], "窓1 労働基準法")
    expect(html).to include('aria-label="現在地"', "現在地：")
    expect(html).to include('<a class="breadcrumb__link" href="/home">Home</a> ＞ <a class="breadcrumb__link" href="/phases/1">A 社労士</a> ＞ <span aria-current="page">窓1 労働基準法</span>')
  end

  it "リンクにはすべて押しやすくする目印 breadcrumb__link が付き、今いる画面には付かない（#108）" do
    html = helper.breadcrumb([ "Home", "/home" ], [ "A 社労士", "/phases/1" ], "窓1 労働基準法")
    expect(html.scan("<a ").size).to eq 2
    expect(html.scan('class="breadcrumb__link"').size).to eq 2
    expect(html).not_to include('<span class="breadcrumb__link"')
  end
end
