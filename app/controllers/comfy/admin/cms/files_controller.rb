class Comfy::Admin::Cms::FilesController < Comfy::Admin::Cms::BaseController
  include ActionView::Helpers::NumberHelper

  before_action :build_file,  :only => [:new, :create]
  before_action :load_file,   :only => [:edit, :update, :destroy]
  before_action :authorize

  def index
    case params[:source]
    when 'redactor'
      files_scope  = @site.files.limit(100).order('created_at DESC')
      files_scope = files_scope.where('comfy_cms_files.label LIKE ? OR comfy_cms_files.description LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%") if params[:source] == 'filter'
      file_hashes = case params[:type]
      when 'image'
        files_scope.images.collect do |image|
          { :thumb => image.file.url(:cms_thumb),
            :image => image.file.url,
            :title => image.label }
        end
      else
        files_scope.collect do |file|
          { :title  => file.label,
            :name   => file.file_file_name,
            :link   => file.file.url,
            :size   => number_to_human_size(file.file_file_size) }
        end
      end
      render :json => file_hashes
    else
      files_scope = @site.files.not_page_file
        .includes(:categories)
        .for_category(params[:category])
        .order('comfy_cms_files.position')
      files_scope = files_scope.where('comfy_cms_files.label LIKE ? OR comfy_cms_files.description LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%") if params[:source] == 'filter'
      @files = comfy_paginate(files_scope, 50)
    end
  end

  def new
    render
  end

  def create
    @file.save!

    case params[:source]
    when 'plupload'
      render :text => render_to_string(:partial => 'file', :object => @file)
    else
      flash[:success] = I18n.t('comfy.admin.cms.files.created')
      redirect_to :action => :edit, :id => @file
    end

  rescue ActiveRecord::RecordInvalid
    case params[:source]
    when 'plupload'
      render :text => @file.errors.full_messages.to_sentence, :status => :unprocessable_entity
    else
      flash.now[:danger] = I18n.t('comfy.admin.cms.files.creation_failure')
      render :action => :new
    end
  end

  def update
    if @file.update(file_params)
      flash[:success] = I18n.t('comfy.admin.cms.files.updated')
      if params.has_key?(:page_id) && params.has_key?(:revision_id)
        redirect_to edit_comfy_admin_cms_site_page_revision_path(params[:site_id].to_i, params[:page_id].to_i, params[:revision_id].to_i)
      else
        redirect_to :action => :index
      end
    else
      flash.now[:danger] = I18n.t('comfy.admin.cms.files.update_failure')
      render :action => :edit
    end
  end

  def destroy
    @file.destroy
    respond_to do |format|
      format.js
      format.html do
        flash[:success] = I18n.t('comfy.admin.cms.files.deleted')
        if params.has_key?(:page_id) && params.has_key?(:revision_id)
          redirect_to edit_comfy_admin_cms_site_page_revision_path(params[:site_id].to_i, params[:page_id].to_i, params[:revision_id].to_i)
        else
          redirect_to :action => :index
        end
      end
    end
  end

  def reorder
    (params[:comfy_cms_file] || []).each_with_index do |id, index|
      if (cms_file = ::Comfy::Cms::File.find_by_id(id))
        cms_file.update_column(:position, index)
      end
    end
    render :nothing => true
  end

protected

  def build_file
    @file = @site.files.new(file_params)
  end

  def load_file
    @file = @site.files.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = I18n.t('comfy.admin.cms.files.not_found')
    redirect_to :action => :index
  end

  def file_params
    unless (file = params[:file]).is_a?(Hash)
      params[:file] = { }
      params[:file][:file] = file
    end
    params.fetch(:file, {}).permit!
  end
end
