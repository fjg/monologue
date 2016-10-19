# frozen_string_literal: true
class Monologue::PostsController < Monologue::ApplicationController
  def index
    @page = params[:page].nil? ? 1 : params[:page]
    @posts = posts_for_site.page(@page)
                           .includes(:user, :tags)
                           .published
  end

  def show
    if monologue_current_user
      @post = posts_for_site.default.where(url: params[:post_url]).first
    else
      @post = posts_for_site.published.where(url: params[:post_url]).first
    end
    not_found if @post.nil?
  end

  def feed
    @posts = posts_for_site.published.limit(25)
    if params[:tags].present?
      tags = params[:tags].split(',')
      tag_ids = Monologue::Tag.where(:name_downcase.in => tags).pluck(:id)
      @posts = @posts.where(:tag_ids.in => tag_ids)
    end
    render 'feed', layout: false
  end
end
