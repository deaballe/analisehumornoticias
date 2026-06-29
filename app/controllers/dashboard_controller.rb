class DashboardController < ApplicationController
  def index
    @briefing = DailyBriefing.current
    @latest_slot = latest_slot
    @snapshots = snapshots_for(@latest_slot)
    @trend_data = trend_data
    @updated_at = updated_at_label
  end

  private

  def latest_slot
    return nil unless @briefing

    { date: @briefing.briefing_date, slot: @briefing.slot }
  end

  def snapshots_for(latest_slot)
    return DailySnapshot.none unless latest_slot

    DailySnapshot.includes(:keyword)
                 .where(snapshot_date: latest_slot[:date], slot: latest_slot[:slot])
                 .order("keywords.term")
                 .joins(:keyword)
  end

  def trend_data
    start_date = 6.days.ago.to_date
    DailySnapshot.includes(:keyword)
                 .where(snapshot_date: start_date..Time.zone.today)
                 .order(:snapshot_date)
                 .group_by { |snapshot| snapshot.keyword.term }
                 .transform_values do |rows|
      rows.map { |row| [ row.snapshot_date, row.pct_negative.to_f ] }
    end
  end

  def updated_at_label
    return "Sem dados" unless @briefing

    slot_label = @briefing.slot == "manha" ? "07:00" : "18:00"
    "#{@briefing.briefing_date.strftime('%d/%m/%Y')} #{slot_label}"
  end
end
