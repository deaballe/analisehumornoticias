namespace :pipeline do
  desc "Audit source collection and keyword matching (no DeepSeek calls)"
  task audit: :environment do
    keywords = Keyword.order(:term).to_a
    collected = 0
    matched_items = []

    puts "Auditoria do pipeline — #{Time.zone.now.strftime('%d/%m/%Y %H:%M')}"
    puts "=" * 60

    Source.order(:slug).each do |source|
      items = ScraperRegistry.for(source).call(source)
      source_matches = 0

      items.each do |item|
        article = Article.new(title: item[:title], content_snippet: item[:content_snippet])
        matched = KeywordMatcher.call(article, keywords)
        next if matched.empty?

        source_matches += 1
        matched_items << { source: source.slug, title: item[:title], keywords: matched.map(&:term) }
      end

      collected += items.size
      puts format("%-18s %3d coletadas | %3d com keyword", source.slug, items.size, source_matches)
    end

    by_keyword = matched_items.flat_map { |item| item[:keywords] }.tally.sort_by { |_, count| -count }

    puts
    puts "Total coletado: #{collected}"
    puts "Com keyword:    #{matched_items.size} (#{percentage(matched_items.size, collected)}%)"
    puts
    puts "Por keyword:"
    if by_keyword.any?
      by_keyword.each { |term, count| puts format("  %3d  %s", count, term) }
    else
      puts "  (nenhuma)"
    end

    puts
    puts "Exemplos:"
    matched_items.first(10).each do |item|
      puts "  [#{item[:source]}] #{item[:keywords].join(', ')}"
      puts "    #{item[:title].truncate(100)}"
    end
  end
end

def percentage(part, total)
  return "0.0" if total.zero?

  format("%.1f", part * 100.0 / total)
end
