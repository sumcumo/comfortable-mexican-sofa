class Comfy::Admin::Cms::PagesController < Comfy::Admin::Cms::BaseController

  before_action :check_for_layouts, :only => [:new, :edit]
  before_action :build_cms_page,    :only => [:new, :create]
  before_action :load_cms_page,     :only => [:edit, :update, :destroy]
  before_action :authorize
  before_action :preview_cms_page,  :only => [:create, :update]

  def index
    return redirect_to :action => :new if site_has_no_pages?
    return index_for_redactor if params[:source] == 'redactor'

    session[:cms_page_viewstate] = params

    if params[:q].present? || params[:category].present?
      pages_scope = @site.pages
        .includes(:categories)
        .for_category(params[:category])
        .order(label: :asc)

      pages_scope = pages_scope.where('comfy_cms_pages.label LIKE ? OR comfy_cms_pages.slug LIKE ? OR comfy_cms_pages.full_path LIKE ?', "%#{params[:q]}%", "%#{params[:q]}%", "%#{params[:q]}%") if params[:q].present?
      pages_ids   = pages_scope.pluck(:id)

      @pages_by_parent  = pages_scope.group_by(&:parent_id)
      @pages            = pages_scope.select{ |page| page.parent == nil || !pages_ids.include?(page.parent_id) }
    else
      @pages_by_parent = pages_grouped_by_parent
      @pages = [@site.pages.includes(:categories).root].compact
    end
  end

  def new
    render
  end

  def edit
    if @page.revisions.size == 0
      @page.prepare_inverse_revision!
      @page.create_revision
      @page.update_column(:last_published_revision_id, @page.revisions.first.id)
    end
    redirect_to edit_comfy_admin_cms_site_page_revision_path(@site, @page, @page.revisions.first)
  end

  def create
    @page.save!
    flash[:success] = I18n.t('comfy.admin.cms.pages.created')
    redirect_to :action => :edit, :id => @page
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = I18n.t('comfy.admin.cms.pages.creation_failure')
    render :action => :new
  end

  def destroy
    @page.destroy
    flash[:success] = I18n.t('comfy.admin.cms.pages.deleted')
    redirect_to :action => :index
  end

  def form_blocks
    @page = @site.pages.find_by_id(params[:id]) || @site.pages.new
    @page.layout = @site.layouts.find_by_id(params[:layout_id])
  end

  def toggle_branch
    @pages_by_parent = pages_grouped_by_parent
    @page = @site.pages.find(params[:id])
    s   = (session[:cms_page_tree] ||= [])
    id  = @page.id.to_s
    s.member?(id) ? s.delete(id) : s << id
    redirect_to :action => :index unless request.xhr?
    render :text => '' if request.xhr? && params[:silent] == 'true'
  rescue ActiveRecord::RecordNotFound
    # do nothing
  end

  def reorder
    (params[:comfy_cms_page] || []).each_with_index do |id, index|
      ::Comfy::Cms::Page.where(:id => id).update_all(:position => index)
    end
    render :nothing => true
  end

protected

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
    @page = @site.pages.find(params[:id] || params[:page_id])
    @page.attributes = page_params
    @page.layout ||= (@page.parent && @page.parent.layout || @site.layouts.first)
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = I18n.t('comfy.admin.cms.pages.not_found')
    redirect_to :action => :index
  end

  def load_from_revision
    @page = @site.pages.find(params[:page_id])
    @page.attributes = page_params
    @page.layout ||= (@page.parent && @page.parent.layout || @site.layouts.first)
    revision = @page.revisions.find(params[:revision_id])
    page = @page.blocks.inject({}){|c, b| c[b.identifier] = revision.data['blocks_attributes'].detect{|r| r[:identifier] == b.identifier}.try(:[], :content); c }
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
