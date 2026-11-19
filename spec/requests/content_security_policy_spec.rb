require "rails_helper"

RSpec.describe "CSP（#111）", type: :request do
  def csp
    response.headers["Content-Security-Policy"]
  end

  it "画面に CSP の札が付き、スクリプトは MOGA 自身と合言葉付きだけ" do
    get root_path
    expect(csp).to include("default-src 'self'", "object-src 'none'", "frame-ancestors 'none'")
    expect(csp).to match(/script-src 'self' 'nonce-[^']+'/)
  end

  it "importmap のスクリプトのタグに、札と同じ合言葉が付いている（Turbo・Stimulus が動く）" do
    get root_path
    nonce = csp[/'nonce-([^']+)'/, 1]
    expect(response.body).to include(%(nonce="#{nonce}"))
    expect(response.body).to include('<script type="importmap"')
  end

  it "円グラフ・曼荼羅の濃淡（style=\"--pct\"）のために、style はタグの中の物も許す" do
    get root_path
    expect(csp).to include("style-src 'self' 'unsafe-inline'")
  end

  it "合言葉は画面を出すたびに変わる" do
    get root_path
    first = csp[/'nonce-([^']+)'/, 1]
    get root_path
    expect(csp[/'nonce-([^']+)'/, 1]).not_to eq(first)
  end
end
