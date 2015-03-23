class Comfy::Admin::Cms::RevisionsController < Comfy::Admin::Cms::BaseController

  before_action :load_record
  before_action :load_revision, :except => [:index, :compare]
  before_action :authorize

  def index
    redirect_to :action => :show, :id => @record.revisions.first.try(:id) || 0
  end

  def show
    case @record
    when Comfy::Cms::Page
      @current_content    = @record.blocks.inject({}){|c, b| c[b.identifier] = b.content; c }
      @versioned_content  = @record.blocks.inject({}){|c, b| c[b.identifier] = @revision.data['blocks_attributes'].detect{|r| r[:identifier] == b.identifier}.try(:[], :content); c }
    else
      @current_content    = @record.revision_fields.inject({}){|c, f| c[f] = @record.send(f); c }
      @versioned_content  = @record.revision_fields.inject({}){|c, f| c[f] = @revision.data[f]; c }
    end
  end

  def compare
    @revision = @record.revisions.find(params[:revision_id])
    @second_revision = @record.revisions.find(params[:second_revision_id])
    case @record
    when Comfy::Cms::Page
      @current_content = @record.blocks.inject({}){|c, b| c[b.identifier] = @second_revision.data['blocks_attributes'].detect{|r| r[:identifier] == b.identifier}.try(:[], :content); c }
      @versioned_content = @record.blocks.inject({}){|c, b| c[b.identifier] = @revision.data['blocks_attributes'].detect{|r| r[:identifier] == b.identifier}.try(:[], :content); c }
    else
      # You should not be here.
      raise ComfortableMexicanSofa::NotImplementedError
    end
    render :show
  end

  def edit
    case @record
    when Comfy::Cms::Page
      check_for_layouts
      load_from_revision
      render 'comfy/admin/cms/pages/edit'
    else
      # You should not be here.
      raise ComfortableMexicanSofa::NotImplementedError
    end
  end

  def update
    case @record
    when Comfy::Cms::Page
      load_cms_page
      preview_cms_page
      return if params[:preview]

      # when saving, create a new revision
      @page.prepare_inverse_revision
      @page.create_revision if @page.revision_data
      @page.update_column(:newest_draft_timestamp, @page.revisions.first.created_at)
      if params[:publish]
        begin
          if params[:scheduled_revision_datetime] > Time.now
            @page.update_columns(scheduled_revision_datetime: params[:scheduled_revision_datetime], scheduled_revision_id: @page.revisions.first.id)
          else
            @page.last_published_revision_id = @page.revisions.first.id
            @page.is_published = true
            @page.is_withdrawn = false
            @page.revision_data = nil
            @page.skip_create_revision = true
            @page.save!
          end
          flash[:success] = I18n.t('comfy.admin.cms.pages.updated')
          redirect_to :controller => :pages, :action => :edit, :id => @page
        rescue ActiveRecord::RecordInvalid
          flash.now[:danger] = I18n.t('comfy.admin.cms.pages.update_failure')
          render :action => :edit
        end
      elsif params[:withdraw]
        begin
          @page.is_published = false
          @page.is_withdrawn = true
          @page.revision_data = nil
          @page.skip_create_revision = true
          @page.last_published_revision_id = nil
          @page.save!
          flash[:success] = I18n.t('comfy.admin.cms.pages.updated')
          redirect_to :controller => :pages, :action => :edit, :id => @page
        rescue ActiveRecord::RecordInvalid
          flash.now[:danger] = I18n.t('comfy.admin.cms.pages.update_failure')
          render :action => :edit
        end
      else
        if params[:save_as_draft]
          @page.is_published = false
          @page.is_withdrawn = false
        end
        begin
          flash[:success] = I18n.t('comfy.admin.cms.pages.updated')
          redirect_to :action => :edit, :page_id => @page, :id => @page.revisions.first
        rescue ActiveRecord::RecordInvalid
          flash.now[:danger] = I18n.t('comfy.admin.cms.pages.update_failure')
          render :action => :edit
        end
      end
    else
      raise ComfortableMexicanSofa::NotImplementedError
    end
  end

  def revert
    @record.restore_from_revision(@revision)
    flash[:success] = I18n.t('comfy.admin.cms.revisions.reverted')
    redirect_to_record
  end

  def form_blocks
    @page = @site.pages.find_by_id(params[:page_id]) || @site.pages.new
    @page.layout = @site.layouts.find_by_id(params[:layout_id])
  end

  def publish
    # xxx
  end

protected

  def load_record
    @record = if params[:layout_id]
      ::Comfy::Cms::Layout.find(params[:layout_id])
    elsif params[:page_id]
      ::Comfy::Cms::Page.find(params[:page_id])
    elsif params[:snippet_id]
      ::Comfy::Cms::Snippet.find(params[:snippet_id])
    end
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = I18n.t('comfy.admin.cms.revisions.record_not_found')
    redirect_to comfy_admin_cms_path
  end

  def load_revision
    @revision = @record.revisions.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = I18n.t('comfy.admin.cms.revisions.not_found')
    redirect_to_record
  end

  def redirect_to_record
    redirect_to case @record
      when ::Comfy::Cms::Layout  then edit_comfy_admin_cms_site_layout_path(@site, @record)
      when ::Comfy::Cms::Page    then edit_comfy_admin_cms_site_page_path(@site, @record)
      when ::Comfy::Cms::Snippet then edit_comfy_admin_cms_site_snippet_path(@site, @record)
    end
  end

  def index_for_redactor
    tree_walker = ->(page, list, offset) do
      return unless page.present?
      label = "#{'. . ' * offset}#{page.label}"
      list << {:name => label, :url => page.url(:relative)}
      page.children.each do |child_page|
        tree_walker.(child_page, list, offset + 1)
      end
      list
    end

    page_select_options = [{
      :name => I18n.t('comfy.admin.cms.pages.form.choose_link'),
      :url  => false
    }] + tree_walker.(@site.pages.root, [ ], 0)

    render :json => page_select_options
  end

  def site_has_no_pages?
    @site.pages.count == 0
  end

  def pages_grouped_by_parent
    @site.pages.includes(:categories).group_by(&:parent_id)
  end

  def check_for_layouts
    if @site.layouts.count == 0
      flash[:danger] = I18n.t('comfy.admin.cms.pages.layout_not_found')
      redirect_to new_comfy_admin_cms_site_layout_path(@site)
    end
  end

  def build_cms_page
    @page = @site.pages.new(page_params)
    @page.parent ||= (@site.pages.find_by_id(params[:parent_id]) || @site.pages.root)
    @page.layout ||= (@page.parent && @page.parent.layout || @site.layouts.first)
  end

  def load_cms_page
    @page = @site.pages.find(params[:page_id])
    @page.attributes = page_params
    @page.layout ||= (@page.parent && @page.parent.layout || @site.layouts.first)
    @page
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = I18n.t('comfy.admin.cms.pages.not_found')
    redirect_to :action => :index
  end

  def load_from_revision
    @page = @site.pages.find(params[:page_id])
    @page.attributes = page_params
    @page.layout ||= (@page.parent && @page.parent.layout || @site.layouts.first)
    revision = @page.revisions.find(params[:id])
    revision.data.map { |k,v| @page.send("#{k}=", v) }
    # page = @page.blocks.inject({}){|c, b| c[b.identifier] = revision.data['blocks_attributes'].detect{|r| r[:identifier] == b.identifier}.try(:[], :content); c }
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = I18n.t('comfy.admin.cms.pages.not_found')
    redirect_to :action => :index
  end

  def preview_cms_page
    if params[:preview]
      layout = @page.layout.app_layout.blank? ? false : @page.layout.app_layout
      @cms_site   = @page.site
      @cms_layout = @page.layout
      @cms_page   = @page

      # Chrome chokes on content with iframes. Issue #434
      response.headers['X-XSS-Protection'] = '0'

      render :inline => @page.render, :layout => layout, :content_type => 'text/html'
    end
  end

  def page_params
    params.fetch(:page, {}).permit!
  end

end