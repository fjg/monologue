# encoding: UTF-8
# frozen_string_literal: true
FactoryGirl.define do
  factory :post, class: Monologue::Post do
    published true
    association :user
    association :site
    sequence(:title) { |i| "post title #{i}" }
    content 'this is some text with accents éàöûù and even html tags <br />'
    sequence(:url) { |i| "post/ulr#{i}" }
    sequence(:published_at) { |i| DateTime.new(2011, 1, 1, 12, 0, 17) + i.days }
  end

  factory :unpublished_post, class: Monologue::Post, parent: :post do |_post|
    published false
    title 'unpublished'
    url 'unpublished'
  end

  factory :post_with_tags, class: Monologue::Post, parent: :post do |post|
    post.after_create { |p| p.tag!(['Rails', 'a great tag', 'Тест']) }
  end

  factory :post_in_bestoff, class: Monologue::Post, parent: :post do |post|
    post.bestoff true
  end
end
