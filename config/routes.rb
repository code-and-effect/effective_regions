Rails.application.routes.draw do
  mount EffectiveRegions::Engine => '/', :as => 'effective_regions'
end

EffectiveRegions::Engine.routes.draw do
  scope :module => 'effective' do
    scope '/effective' do
      get 'snippet/:id' => 'regions#snippet', :as => :snippet # Get a Snippet based on passed values
      
      resources :ck_assets, only: [:index, :update] # Ckeditor IFrame
    end

    scope '/edit' do  # Changing this, means changing the effective_ckeditor routes
      get '(*requested_uri)' => 'regions#edit', :as => :edit_effective_regions
      get '(*requested_uri)' => 'regions#edit', :as => :edit
      put '(*requested_uri)' => 'regions#update', :as => :effective_regions
    end
  end
end
