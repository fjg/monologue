# encoding: UTF-8
# frozen_string_literal: true
require 'spec_helper'

describe 'tags' do
  before(:each) do
    @site1 = Factory(:site)
  end

  describe 'Viewing the list of posts with tags' do
    before(:each) do
      @post_in_bestoff = Factory(:post_in_bestoff, title: 'post X', site: @site1)
      @post_not_in_bestoff = Factory(:post, title: 'post Y', site: @site1)
    end

    it 'should display the tags for the posts as a link' do
      visit "http://www.#{@site1.domain}/monologue"
      within '.widget-bestoff' do
        page.should have_content(@post_in_bestoff.title)
        page.should_not have_content(@post_not_in_bestoff.title)
      end
    end
  end
end
