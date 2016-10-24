# frozen_string_literal: true
class Monologue::Admin::TagsController < Monologue::Admin::BaseController
  respond_to :html
  before_action :load_tag, only: [:edit, :update]

  def index
    @tags = Monologue::Tag.all
  end

  def edit
  end

  def update
    if @tag.update(tag_params)
      redirect_to edit_admin_tag_path(@tag)
    else
      render :edit
    end
  end

  private

  def load_tag
    @tag = Monologue::Tag.find(params[:id])
  end


  def tag_params
    params.require(:tag)
          .permit(*%i(icon
                      bestoff))
  end
end
