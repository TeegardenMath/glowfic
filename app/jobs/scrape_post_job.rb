class ScrapePostJob < ApplicationJob
  queue_as :low

  def perform(url, board_id, section_id, status, threaded, importer_id)
    Resque.logger.debug "Starting scrape for #{url}"
    scraper = PostScraper.new(url, board_id, section_id, status, threaded)
    scraped_post = scraper.scrape!
    Notification.notify_user(User.find_by(id: importer_id), :import_success, post: scraped_post)
  end

  def self.notify_exception(exception, url, board_id, section_id, status, threaded, importer_id)
    Resque.logger.warn "Failed to import #{url}: #{exception.message}"
    importer = User.find_by(id: importer_id)
    if importer
      post = exception.is_a?(AlreadyImportedError) ? Post.find_by(id: exception.post_id) : nil
      Notification.notify_user(importer, :import_fail, error: exception.message, post: post)
    end
    super
  end

  def self.view_post(post_id)
    host = ENV['DOMAIN_NAME'] || 'localhost:3000'
    url = Rails.application.routes.url_helpers.post_url(post_id, host: host, protocol: 'https')
    "<a href='#{url}'>View it here</a>."
  end
end
