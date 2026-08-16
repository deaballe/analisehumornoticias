module ApplicationHelper
  def sentiment_badge(label, sentiment)
    colors = {
      "positive" => "bg-emerald-100 text-emerald-800",
      "neutral" => "bg-amber-100 text-amber-800",
      "negative" => "bg-rose-100 text-rose-800"
    }

    content_tag(:span, "#{label}: #{sentiment_label(sentiment)}",
                class: "inline-flex rounded-full px-2 py-1 text-xs font-medium #{colors.fetch(sentiment, colors['neutral'])}")
  end

  def humor_badge(score)
    value = score.to_f.round
    tone =
      if value <= 30
        "bg-emerald-100 text-emerald-900 ring-1 ring-emerald-200"
      elsif value >= 70
        "bg-rose-100 text-rose-900 ring-1 ring-rose-200"
      else
        "bg-amber-100 text-amber-900 ring-1 ring-amber-200"
      end

    content_tag(:span, "Humor #{value}/100",
                class: "inline-flex rounded-full px-2.5 py-1 text-xs font-semibold #{tone}")
  end

  def relevance_badge(score)
    content_tag(:span, "Relevância #{score.to_i}",
                class: "inline-flex rounded-full bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-700 ring-1 ring-slate-200")
  end

  def sentiment_label(sentiment)
    {
      "positive" => "Positivo",
      "neutral" => "Neutro",
      "negative" => "Negativo"
    }.fetch(sentiment, sentiment)
  end

  def snapshot_status_class(snapshot)
    return "border-slate-200 bg-slate-50" if snapshot.article_count.zero?
    return "border-rose-500 bg-rose-50 ring-2 ring-rose-200" if snapshot.is_critical?

    if snapshot.pct_negative.to_f >= 40
      "border-rose-300 bg-rose-50"
    elsif snapshot.pct_positive.to_f >= 40
      "border-emerald-300 bg-emerald-50"
    else
      "border-amber-300 bg-amber-50"
    end
  end

  def briefing_item_humor(item)
    return item["humor_score"].to_f if item["humor_score"].present?

    article_id = item["article_id"]
    return 50.0 if article_id.blank?

    analysis = ArticleAnalysis.where(article_id: article_id).order(relevance_score: :desc).first
    analysis ? HumorScore.call(analysis) : 50.0
  end

  def briefing_item_attention(item)
    return item["attention_score"].to_f if item["attention_score"].present?

    article_id = item["article_id"]
    return 0.0 if article_id.blank?

    analysis = ArticleAnalysis.where(article_id: article_id).order(relevance_score: :desc).first
    analysis ? AttentionScore.call(analysis) : 0.0
  end

  def briefing_item_tone_class(item)
    humor = briefing_item_humor(item)

    if humor <= 30
      "border-emerald-300 bg-emerald-50"
    elsif humor >= 70
      "border-rose-300 bg-rose-50"
    else
      "border-amber-300 bg-amber-50"
    end
  end

  def display_keyword_term(term)
    acronyms = %w[RS SPGG SUPLAN SUAD SUGEP SPE CELIC STI BM PC ALERS PPP PPA]
    small_words = %w[de do da dos das e]

    term.to_s.split(/(\s+)/).map.with_index do |part, index|
      next part if part.match?(/\A\s+\z/)

      upper = part.upcase
      next upper if acronyms.include?(upper)

      lower = part.downcase
      next lower if index.positive? && small_words.include?(lower)

      part.capitalize
    end.join
  end
end
