module ApplicationHelper
  # OGP：リンクを LINE・メール・SNS で送った時に出る「絵と説明の札」（お店の看板）
  #   運営事務局からの課題 #17、Issue #103。外に見せるページはトップだけなので、静的 OGP（どのページも同じ看板）
  OGP_TITLE = "MOGA ― 数値化ブルーノート".freeze
  OGP_DESCRIPTION = "人生の8つの大窓と64の小窓（曼荼羅64）に目標を並べ、" \
                    "予定と記録を％と青の濃淡で育てる記録アプリです。".freeze
  OGP_IMAGE_PATH = "/ogp.png".freeze

  # 看板の meta タグ一式。絵と住所は、今開いているサイトの住所（request.base_url）から作る
  #   （独自ドメインに移っても、書き直さずにそのまま使える）
  def ogp_meta_tags
    tags = ogp_properties.map { |property, content| tag.meta(property: property, content: content) }
    safe_join([ tag.meta(name: "description", content: OGP_DESCRIPTION), *tags,
                tag.meta(name: "twitter:card", content: "summary_large_image") ], "\n    ")
  end

  # og: で始まる看板の項目（名前 => 中身）
  def ogp_properties
    {
      "og:type" => "website",
      "og:site_name" => "MOGA",
      "og:title" => OGP_TITLE,
      "og:description" => OGP_DESCRIPTION,
      "og:url" => "#{request.base_url}#{request.path}",
      "og:image" => "#{request.base_url}#{OGP_IMAGE_PATH}",
      "og:image:width" => "1200",
      "og:image:height" => "630",
      "og:image:alt" => "MOGA 数値化ブルーノートと曼荼羅64の図柄",
      "og:locale" => "ja_JP"
    }
  end
end
