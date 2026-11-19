# CSP（コンテンツ セキュリティ ポリシー）：画面で動いてよい物の出どころを、ブラウザに伝える（#111）
#   今の守り（自動エスケープ）に、もう一枚の守りを重ねる。
#   たとえ：建物の入口に「出入りできるのは MOGA の社員証を持つ人だけ」と張り紙をしておく。
#   万一だれかが画面に悪い <script> を紛れ込ませても、社員証（nonce）が無いのでブラウザが動かさない。
#
#   script-src：MOGA 自身のファイルと、その画面ごとの合言葉（nonce）付きのタグだけ
#               importmap・Turbo・Stimulus のタグには、Rails が合言葉を自動で付ける
#   style-src ：MOGA 自身のファイルと、タグの中の style="..."（円グラフ・曼荼羅の濃淡の --pct で使う）
#   img/font  ：MOGA 自身と data: だけ
#   object-src：使わない（none）
#   frame-ancestors：ほかのサイトの枠の中に MOGA を表示させない（none）
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.script_src  :self
    policy.style_src   :self, :unsafe_inline
    policy.img_src     :self, :data
    policy.font_src    :self, :data
    policy.connect_src :self
    policy.object_src  :none
    policy.base_uri    :self
    policy.form_action :self
    policy.frame_ancestors :none
  end

  # 画面を出すたびに新しい合言葉（nonce）を作り、script-src にだけ使う
  #   style-src に合言葉を付けると 'unsafe-inline' が効かなくなり、円グラフの style="--pct" が止まるため付けない
  config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src]
end
