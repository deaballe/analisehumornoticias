namespace :history do
  desc "Backfill DailySnapshot rows for the last N days (default 7). Usage: bin/rails history:backfill DAYS=7"
  task backfill: :environment do
    days = Integer(ENV.fetch("DAYS", HistoryBackfill::DEFAULT_DAYS))
    slot = ENV.fetch("SLOT", HistoryBackfill::DEFAULT_SLOT)
    fill_gaps = ENV.fetch("FILL_GAPS", "true") != "false"
    collect = ENV.fetch("COLLECT", "true") != "false"

    puts "History backfill days=#{days} slot=#{slot} collect=#{collect} fill_gaps=#{fill_gaps}"
    result = HistoryBackfill.call(days: days, slot: slot, collect: collect, analyze: true, fill_gaps: fill_gaps)
    puts "articles=#{result[:articles]} analyses=#{result[:analyses]} snapshots=#{result[:snapshots]}"
    result[:coverage_by_day].each do |date, count|
      puts "  #{date}: analyses=#{count}"
    end
  end
end
