class ActionDispatch::Routing::Mapper

  def comfy_route_cms_admin(options = {})
    options[:path] ||= 'admin'

    scope :module => :comfy, :as => :comfy do
      scope :module => :admin do
        namespace :cms, :as => :admin_cms, :path => options[:path], :except => :show do
          get '/', :to => 'base#jump'
          resources :sites do
            resources :pages do
              get :form_blocks,    :on => :member
              get :toggle_branch,  :on => :member
              get :page_variant,   :on => :member
              put :reorder,        :on => :collection
              resources :revisions, :only => [:index, :show, :revert, :edit, :update] do
                patch :revert, :on => :member
                get :page_variant, :on => :member
                get :compare, :on => :collection
              end
              # get 'revisions/:id/compare/:second_revision_id', :controller => :revisions, :action => :compare, :as => :compare_revisions
            end
            resources :files do
              put :reorder, :on => :collection
            end
            resources :layouts do
              put :reorder, :on => :collection
              resources :revisions, :only => [:index, :show, :revert] do
                patch :revert, :on => :member
              end
            end
            resources :snippets do
              put :reorder, :on => :collection
              resources :revisions, :only => [:index, :show, :revert] do
                patch :revert, :on => :member
              end
            end
            resources :categories
            resources :variants
          end
        end
      end
    end
  end
end
