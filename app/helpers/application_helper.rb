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

    "border-slate-200 bg-white"
  end
end
