class NewsPipelineJob < ApplicationJob
  queue_as :default

  def perform(slot)
    NewsPipeline.new(slot: slot).run
  end
end
