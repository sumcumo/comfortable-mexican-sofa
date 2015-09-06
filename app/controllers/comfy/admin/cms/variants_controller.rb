class Comfy::Admin::Cms::VariantsController < Comfy::Admin::Cms::BaseController

  before_action :build_variant, :only => [:new, :create]
  before_action :load_variant,  :only => [:edit, :update, :destroy]
  before_action :authorize

  def index
    #return redirect_to :action => :new if @site.variants.count == 0
    @variants = @site.variants.order(hierarchy: 'ASC')
  end

  def new
    render
  end

  def edit
    @variant.attributes = variant_params
  end

  def create
    @variant.save!
    flash[:success] = I18n.t('comfy.admin.cms.variants.created')
    redirect_to :action => :edit, :id => @variant
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = I18n.t('comfy.admin.cms.variants.creation_failure')
    render :action => :new
  end

  def update
    @variant.update_attributes!(variant_params)
    flash[:success] = I18n.t('comfy.admin.cms.variants.updated')
    redirect_to :action => :edit, :id => @variant
  rescue ActiveRecord::RecordInvalid
    flash.now[:danger] = I18n.t('comfy.admin.cms.variants.update_failure')
    render :action => :edit
  end

  def destroy
    @variant.destroy
    flash[:success] = I18n.t('comfy.admin.cms.variants.deleted')
    redirect_to :action => :index
  end

  protected

  def build_variant
    @variant = @site.variants.new(variant_params)
  end

  def load_variant
    @variant = @site.variants.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:danger] = I18n.t('comfy.admin.cms.variants.not_found')
    redirect_to :action => :index
  end

  def variant_params
    params.fetch(:variant, {}).permit!
  end


end
