module BreadcrumbHelper
  SEPARATOR = " ＞ ".freeze

  # 現在地（パンくず）を画面の上に出す（#31）
  #   breadcrumb(["Home", home_path], ["A 社労士", phase_path(phase)], "窓1 労働基準法")
  #   ・[名前, 行き先] はリンク（押すとその画面へ戻れる）
  #   ・最後の文字だけの物が「今いる画面」
  def breadcrumb(*items)
    links = items.map do |item|
      if item.is_a?(Array)
        link_to(item[0], item[1])
      else
        tag.span(item, aria: { current: "page" })
      end
    end
    tag.nav(class: "breadcrumb", aria: { label: "現在地" }) do
      safe_join([ tag.span("現在地：", class: "breadcrumb__label"), safe_join(links, SEPARATOR) ])
    end
  end
end
