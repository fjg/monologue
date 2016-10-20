# frozen_string_literal: true
class Monologue::Admin::PostsController < Monologue::Admin::BaseController
  respond_to :html
  before_action :load_sites, only: [:new, :create, :edit, :update]
  before_action :load_post, only: [:edit, :update]

  def index
    @page = params[:page].nil? ? 1 : params[:page]
    @posts = Monologue::Post.listing_page(@page).includes(:user, :site)
  end

  def new
    @post = Monologue::Post.new
  end

  ## Preview a post without saving.
  def preview
    # mockup our models for preview.
    @post = Monologue::Post.new post_params
    @post.user_id = monologue_current_user.id
    @post.published_at = Time.zone.now
    # render it exactly as it would display when live.
    load_data_for_preview
    render '/monologue/posts/show',
           layout: Monologue::Config.layout || '/layouts/monologue/application'
  end

  def create
    @post = Monologue::Post.new post_params
    @post.user_id = monologue_current_user.id
    if @post.save
      prepare_flash_and_redirect_to_edit
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      prepare_flash_and_redirect_to_edit
    else
      render :edit
    end
  end

  def destroy
    post = Monologue::Post.find(params[:id])
    if post.destroy
      redirect_to admin_posts_path,
                  notice:  I18n.t('monologue.admin.posts.delete.removed')
    else
      redirect_to admin_posts_path,
                  alert: I18n.t('monologue.admin.posts.delete.failed')
    end
  end

  private

  def load_post
    @post = Monologue::Post.find(params[:id])
  end

  def load_sites
    @sites = Monologue::Site.all.only('id', 'domain')
  end

  # call before_action for layouts/sidebar...
  def load_data_for_preview
    @site = @post.site
    force_locale
    recent_posts
    all_tags
    archive_posts
  end

  def prepare_flash_and_redirect_to_edit
    if @post.published_in_future? && ActionController::Base.perform_caching
      flash[:warning] = I18n.t("monologue.admin.posts.#{params[:action]}.saved_with_future_date_and_cache")
    else
      flash[:notice] =  I18n.t("monologue.admin.posts.#{params[:action]}.saved")
    end
    redirect_to edit_admin_post_path(@post)
  end

  def post_params
    params.require(:post)
          .permit(*%i(site_id published tag_list title content cover url published_at))
  end
end
