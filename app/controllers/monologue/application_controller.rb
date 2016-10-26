# frozen_string_literal: true
class Monologue::ApplicationController < ApplicationController
  include Monologue::ControllerHelpers::User

  force_ssl if Monologue::Config.force_ssl

  layout :custom_site_layout

  # only for front controllers
  before_action :load_site,
                :force_locale, if: proc { |controller| controller.public? }
  before_action :recent_posts, if: proc { |controller|
    controller.public? && Monologue::Config.sidebar.try(:include?, 'latest_posts')
  }
  before_action :all_tags, if: proc { |controller|
    controller.public? && (Monologue::Config.sidebar.try(:include?, 'tag_cloud') ||
                           Monologue::Config.sidebar.try(:include?, 'categories'))
  }
  before_action :archive_posts, if: proc { |controller|
    controller.public? && Monologue::Config.sidebar.try(:include?, 'archive')

  }
  before_action :bestoff, if: proc { |controller|
    controller.public? && Monologue::Config.sidebar.try(:include?, 'bestoff')
  }

  def public?
    !self.class.name.to_s.start_with?('Monologue::Admin::')
  end

  def force_locale
    I18n.locale = @site.locale
  end

  def load_site
    @site = Monologue::Site.find_by(domain: request.domain)
  end

  def posts_for_site
    Monologue::Post.for_domain(request.domain)
  end

  def tags_for_site
    Monologue::Tag.for_domain(request.domain)
  end

  def recent_posts
    @recent_posts = posts_for_site.published.limit(3)
  end

  def all_tags
    @tags = tags_for_site.where(:posts_count.gt => 0)
                          .order([:posts_count, :desc])
                          .entries

    # could use minmax here but it's only supported with ruby > 1.9'
    @tags_frequency_min = @tags.map(&:posts_count).min
    @tags_frequency_max = @tags.map(&:posts_count).max
  end

  def not_found
    # fallback to the default 404.html page from main_app.
    file = Rails.root.join('public', '404.html')
    if file.exist?
      render file: file.cleanpath.to_s.gsub(/#{file.extname}$/, ''),
             layout: false, status: 404, formats: [:html]
    else
      render action: '404', status: 404, formats: [:html]
    end
  end

  def bestoff
    @bestoff = posts_for_site.published.bestoff
  end

  def archive_posts
    @archive_posts = {}
    @first_post_year = DateTime.now.year

    # limit to 100 for safety reasons
    posts = posts_for_site.published.limit(100)
    unless posts.empty?
      @archive_posts = posts.group_by do |post|
        post.published_at.beginning_of_month.strftime('%Y %-m')
      end
      @first_post_year = posts.last.published_at.year
    end
  end

  def custom_site_layout
    @site.layout ? @site.layout : 'monologue/application'
  end
end
