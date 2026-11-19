require "rails_helper"

# 看板（OGP）：リンクを送った時に出る「絵と説明の札」（課題 #17、Issue #103）
RSpec.describe "OGP", type: :request do
  def meta(property)
    response.body[/<meta property="#{Regexp.escape(property)}" content="([^"]*)"/, 1]
  end

  it "トップページの頭に、題名・説明・絵の住所が出る" do
    get root_path
    expect(meta("og:title")).to eq("MOGA ― 数値化ブルーノート")
    expect(meta("og:description")).to include("曼荼羅64", "記録アプリです")
    expect(meta("og:image")).to eq("http://www.example.com/ogp.png")
    expect(meta("og:url")).to eq("http://www.example.com/")
    expect(response.body).to include('<meta name="twitter:card" content="summary_large_image">')
    expect(response.body).to include('<meta name="description" content="人生の8つの大窓')
  end

  it "ログインの画面でも同じ看板が出る（住所はそのページ）" do
    get login_path
    expect(meta("og:title")).to eq("MOGA ― 数値化ブルーノート")
    expect(meta("og:url")).to eq("http://www.example.com#{login_path}")
  end

  it "看板の絵 public/ogp.png は、横1200・縦630の PNG" do
    png = Rails.public_path.join("ogp.png").binread
    expect(png[0, 8]).to eq("\x89PNG\r\n\x1a\n".b)
    width, height = png[16, 8].unpack("NN")
    expect([ width, height ]).to eq([ 1200, 630 ])
  end
end
