class CleanupJob < ApplicationJob
  queue_as :default

  def perform
    count = DetectionEvent.where("detected_at < ?", 90.days.ago).delete_all
    Rails.logger.info "CleanupJob: deleted #{count} detection events older than 90 days"
  end
end
