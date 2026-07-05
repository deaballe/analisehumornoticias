class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  def default_url_options
    options = super
    relative_root = Rails.application.config.relative_url_root.to_s
    return options if relative_root.empty?

    options.merge(script_name: relative_root)
  end
end
