class Monologue::Tag
  include Mongoid::Document
  include Mongoid::Timestamps

  has_many :taggings, class_name: 'Monologue::Tagging'
  has_and_belongs_to_many :posts, class_name: 'Monologue::Post'

  belongs_to :site, class_name: 'Monologue::Site'

  field :name, type: String
  field :name_downcase, type: String
  field :posts_count, type: Integer, default: 0

  validates :name, uniqueness: true, presence: true

  scope :for_domain, lambda { |domain|
    where(site: Monologue::Site.where(domain: domain).first)
  }

  index(name_downcase: 1)
  index(name: 1, site: 1)
  index(site: 1)

  before_save do
    self.name_downcase = name.to_s.downcase
    update_posts_count
  end

  def update_posts_count
    self.posts_count = posts_with_tag.size
  end

  def posts_with_tag
    posts.published
  end

end
