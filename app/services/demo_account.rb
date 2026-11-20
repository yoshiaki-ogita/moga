# 「お試しで見る」の見本の利用者と、見本の曼荼羅64を用意する（SPF からのぞく人のための玄関）
#   - 見本の利用者はアプリに1人だけ。最初に「お試しで見る」が押された時に作る（本番でコマンドを打たずに済む）
#   - 中身は架空の見本。作者の本当の記録には触れない
#   - 見本の利用者は見るだけ（書き込みは ApplicationController で止める）
class DemoAccount
  EMAIL = "demo@moga.example".freeze # .example は見本用に決められた名前で、実在しない
  NAME = "お試しの方".freeze

  # 大窓（コード → 名前と8つの小窓）。窓6＝核、窓8＝シナプス
  PHASES = {
    "A" => [ "資格に挑戦する", %w[基礎の教科書を読む 過去問を解く 苦手な単元の復習 模擬試験 法改正を調べる 合格の核となる重点科目 勉強仲間と教え合う 学んだことを仕事に生かす] ],
    "B" => [ "地域と防災", %w[地震と火山に備える 風水害と土砂災害を知る ハザードマップを読む 高齢の方を緊急時に守る わが家の備え 住民どうしの地区防災 ふるさとのまちづくり 防災の情報をデジタルでつなぐ] ],
    "C" => [ "お金と暮らし", %w[年金と収入の把握 家計簿をつける 我が家のバランスシート 100歳までの資産の見通し 資産の運用を学ぶ 暮らしを支えるお金の芯 社会に役立つ投資を知る 資産と暮らしをまとめて点検] ],
    "D" => [ "健康と運動", %w[ウォーキング 献立と栄養 スロージョギング 庭づくり 花と芝の手入れ 運動で脳を鍛える 畑と野菜づくり 健診の数値を記録する] ],
    "E" => [ "音楽と文芸", %w[ピアノをゆっくり弾く 好きな洋楽を訳す リズムを学ぶ 俳句を詠む 随筆を書く 感性を研ぎ澄ます 昭和史を読む ブログで書いたものを公開] ],
    "F" => [ "自分史と未来", %w[自分史の年表 昔のノートを読み直す 毎日の現在地を記録 20年後の自分を描く 暮らしの経営を学ぶ 明日の自分は今日と違う 退職時の課題の進み具合 自分の物差しを作る] ],
    "G" => [ "美術と手仕事", %w[作品の手入れと展示 道具と場所を整える 水彩でふるさとを描く 木版画を彫る 木彫りに挑む つくる悦びを育てる 編み物 作品集をデジタルで遺す] ],
    "H" => [ "ITとAIを学ぶ", %w[プログラミングの卒業 自分のアプリを作る 継続して学ぶ 情報セキュリティ AIと協働する 8つの大窓の数字を読む パソコンの基礎力 学びを発信する] ]
  }.freeze

  # 課題型の小窓の「課題の数」と「済みの数」の見本（窓ごとに青の濃さが変わるように）
  PLAN_TOTALS = [ 4, 5, 3, 4, 5, 4, 3, 5 ].freeze
  DONE_PATTERN = {
    "A" => [ 3, 4, 1, 2, 0, 3, 1, 2 ], "B" => [ 2, 3, 1, 1, 4, 2, 0, 1 ],
    "C" => [ 4, 2, 1, 1, 0, 2, 0, 1 ], "D" => [ 3, 4, 2, 1, 3, 4, 1, 3 ],
    "E" => [ 1, 0, 1, 2, 1, 1, 0, 1 ], "F" => [ 2, 1, 3, 1, 0, 2, 1, 1 ],
    "G" => [ 1, 1, 2, 0, 0, 1, 0, 0 ], "H" => [ 4, 4, 2, 2, 3, 3, 3, 2 ]
  }.freeze

  # 今日の轍の見本：始まり、終わり、小窓、ひと言、実際は？（◎kept／○shifted／△missed／まだ nil）
  DIARY_PLANS = [
    [ "05:00", "06:30", "H3", "Railsの復習", "kept" ], [ "07:00", "08:30", "D1", "川沿いを歩く", "shifted" ],
    [ "09:00", "11:00", "A2", "過去問を20問", "kept" ], [ "14:00", "15:00", "G3", "畑の景色を描く", "missed" ],
    [ "19:00", "20:00", "E5", "随筆を1本", nil ]
  ].freeze

  def self.user
    User.find_by(email: EMAIL)
  end

  # 見本の利用者を返す。まだ無ければ作り、今日の轍の見本も用意する
  def self.prepare!
    demo = user || create_user!
    ensure_today_diary(demo)
    demo
  rescue ActiveRecord::RecordNotUnique
    # 2人が同時に初めて押した時は、先に作られた方を使う
    user.tap { |found| ensure_today_diary(found) }
  end

  def self.create_user!
    User.transaction do
      demo = User.create!(name: NAME, email: EMAIL, password: SecureRandom.base58(32), demo_account: true)
      demo.phases.each { |phase| fill_phase(phase) }
      demo
    end
  end

  def self.fill_phase(phase)
    name, titles = PHASES.fetch(phase.code)
    phase.update!(name: name, memo: (phase.code == "B" ? "家族と地域を、災害から守れる人になりたいから" : nil))
    titles.each_with_index do |title, i|
      window = phase.windows.create!(number: i + 1, title: title, measure: :plan_count)
      add_plans(window, PLAN_TOTALS[i], DONE_PATTERN.fetch(phase.code)[i])
    end
  end

  # 課題を total 個作り、はじめの done 個を「済み」にする
  def self.add_plans(window, total, done)
    total.times do |n|
      window.plans.create!(title: "#{window.title}（その#{n + 1}）", done_at: (n < done ? 1.day.ago : nil))
    end
  end

  # 今日の「わたしの轍」に、行動予定の見本を入れる（日が変わっても見られるように、押された日に作る）
  def self.ensure_today_diary(demo)
    diary = Diary.for(demo, Date.current)
    return if diary.persisted?

    diary.assign_attributes(word: "一歩ずつ、今日も前へ。", must_do: "ウォーキング／過去問を20問")
    add_diary_plans(diary, demo.windows.includes(:phase).index_by { |w| "#{w.phase.code}#{w.number}" })
    diary.save!
  end
  def self.add_diary_plans(diary, windows)
    DIARY_PLANS.each do |starts, ends, code, memo, outcome|
      diary.diary_plans.build(starts_at: starts, ends_at: ends, window: windows.fetch(code), memo: memo,
                              outcome: outcome)
    end
  end

  private_class_method :create_user!, :fill_phase, :add_plans, :ensure_today_diary, :add_diary_plans
end
