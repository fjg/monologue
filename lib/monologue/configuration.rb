# frozen_string_literal: true
module Monologue
  class Configuration
    include ConfigurationExtensions

    attr_accessor :disqus_shortname,
                  :show_rss_icon,

                  :twitter_username,
                  :twitter_locale,

                  :facebook_like_locale,
                  :facebook_url,

                  # used in the open graph protocol to display an image
                  # when a post is liked
                  :facebook_logo,
                  :facebook_app_id,

                  :google_plus_account_url,
                  :google_plusone_locale,

                  :use_pinterest, # display pinterest?

                  :linkedin_url,

                  :github_username,

                  :force_ssl,
                  :admin_force_ssl,
                  :posts_per_page,
                  :admin_posts_per_page,
                  :google_analytics_id,
                  :gauge_analytics_site_id,
                  :sidebar,
                  :preview_size

    def initialize
      @preview_size = 1000
    end
  end

  def self.config
    yield(Rails.application.config.monologue)
  end
end
