class Monologue::Tag
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  has_many :taggings, class_name: 'Monologue::Tagging'
  has_and_belongs_to_many :posts, class_name: 'Monologue::Post'

  belongs_to :site, class_name: 'Monologue::Site'

  field :name, type: String
  field :name_downcase, type: String
  field :posts_count, type: Integer, default: 0
  field :bestoff, type: Boolean, default: false

  validates :name, uniqueness: true, presence: true

  scope :for_domain, lambda { |domain|
    where(site: Monologue::Site.where(domain: domain).first)
  }

  index(name_downcase: 1)
  index(name: 1, site: 1)
  index(site: 1)

  has_mongoid_attached_file :icon, {
    storage: :s3,
    path: '/tag/:id/:style-:basename.:extension',
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

    :styles => { # grid system aliases
      :max_300 => ['300>',    :jpg],  # col-sm-4
      :max_227 => ['227>',   :jpg],   # col-sm-3
      :max_150 => ['150>', :jpg],     # col-sm-2
      :max_32  => ['32>',    :jpg],   # thumb
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
  validates_attachment_content_type :icon, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]


  before_save do
    self.name_downcase = name.to_s.downcase
    update_posts_count
  end

  def update_posts_count
    self.posts_count = posts_with_tag.size
  end

  def frequency
    posts_count
  end

  def posts_with_tag
    posts.published
  end

end
