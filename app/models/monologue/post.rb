class Monologue::Post
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  ROOT_PATH = Monologue::Engine.routes.url_helpers.root_path

  has_many :taggings, class_name: 'Monologue::Tagging'
  has_and_belongs_to_many :tags,
                          dependent: :destroy,
                          class_name: 'Monologue::Tag',
                          order: [:created_at, :asc]
  before_validation :generate_url
  belongs_to :user, class_name: 'Monologue::User', inverse_of: 'posts'
  belongs_to :site, class_name: 'Monologue::Site'

  field :title, type: String
  field :content, type: String
  field :url, type: String

  field :published_at, type: Time
  field :published, type: Boolean, default: false
  field :bestoff, type: Boolean, default: false

  scope :default, lambda {
    order([[:published_at, :desc], [:created_at, :desc], [:updated_at, :desc]])
  }
  scope :for_domain, lambda { |domain|
    where(site: Monologue::Site.where(domain: domain).first)
  }
  scope :bestoff, lambda { where(bestoff: true) }
  scope :published, lambda {
    default.where(:published_at.lte => DateTime.now, published: true)
           .order([[:published_at, :desc]])
  }

  validates :user_id, presence: true
  validates :site_id, presence: true
  validates :title, :content, :url, :published_at, presence: true
  validates :url, uniqueness: true
  validate :url_do_not_start_with_slash

  index({ published_at: 1, published: 1 })
  index({ published_at: 1, published: 1, url: 1 })

  has_mongoid_attached_file :cover, {
    storage: :s3,
    path: '/blog/:id/:',
    url: ':s3_alias_url',
    s3_credentials: {
      access_key_id:     Monologue::Config.s3_access_key_id,
      secret_access_key: Monologue::Config.s3_secret_access_key,
    },
    bucket:              Monologue::Config.s3_bucket,
    s3_host_name:        Monologue::Config.s3_end_point,
    s3_host_alias:       Monologue::Config.s3_host_alias,
    s3_region:           Monologue::Config.s3_region,
    s3_protocol:         '',

    :styles => {
      :large => ['600>', :jpg], # post index desktop
      :medium    => ['450>',   :jpg], # post index mobile
      :small   => ['300>',    :jpg],
      :sidebar   => ['150>',    :jpg], # sidebar widgets
    },

    # https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/Expiration.html#ExpirationDownloadDist
    # Cache-Control apply to browser / s3
    # Regarding CF:
    # Minimum TTL < max-age < maximum TTL, CF caches objects for the value
    #  of the max-age directive.
    # max-age < minimum TTL, CF caches objects for the value
    #  of the CF minimum TTL.
    # max-age > maximum TTL, CF caches objects for the value
    #  of the CF maximum TTL.
    s3_headers:          { 'Cache-Control' => "max-age=#{1.year.to_i}" },
  }
  validates_attachment_content_type :cover, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]

  def tag_list=(tags_attr)
    tag!(tags_attr.split(','))
  end

  def tag_list
    tags.pluck(:name).join(', ') if tags
  end

  def tag!(tags_attr)
    self.tags = tags_attr.map(&:strip).reject(&:blank?).map do |tag|
      tag = Monologue::Tag.where(name: tag, site: site.id).first_or_create
      tag.update_posts_count
      tag.save
      tag
    end
  end

  def full_url
    "#{ROOT_PATH}#{url}"
  end

  def published_in_future?
    published && published_at > DateTime.now
  end

  def self.page(p)
    paged_results(p, Monologue::Config.posts_per_page || 10, false)
  end

  def self.listing_page(p)
    paged_results(p, Monologue::Config.admin_posts_per_page || 50, true)
  end

  def self.total_pages
    @number_of_pages
  end

  def self.set_total_pages(per_page)
    @number_of_pages = count / per_page + (count % per_page == 0 ? 0 : 1)
  end

  def self.paged_results(p, per_page, admin)
    set_total_pages(per_page)
    p = (p.nil? ? 0 : p.to_i - 1)
    offset = p * per_page
    if admin
      default.limit(per_page).offset(offset)
    else
      limit(per_page).offset(offset)
    end
  end

  private

  def generate_url
    return unless url.blank?
    year = if published_at.class == ActiveSupport::TimeWithZone
             published_at.year
           else
             DateTime.now.year
           end
    self.url = "#{year}/#{title.parameterize}"
  end

  def url_do_not_start_with_slash
    errors.add(
      :url,
      I18n.t(
        'mongoid.errors.models.monologue/post.attributes.url.start_with_slash'
      )
    ) if url.start_with?('/')
  end
end
