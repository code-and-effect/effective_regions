Rails.application.routes.draw do
  mount EffectiveRegions::Engine => '/', :as => 'effective_regions'
end

EffectiveRegions::Engine.routes.draw do
  scope :module => 'effective' do
    scope '/effective' do
      get 'snippets' => 'regions#snippets', :as => :snippets # Index of all Snippets
      get 'snippet/:id' => 'regions#snippet', :as => :snippet # Get a Snippet based on passed values

      get 'templates' => 'regions#templates', :as => :templates # Index of all Templates
    end

    scope '/edit' do  # Changing this, means changing the effective_ckeditor routes
      get '(*requested_uri)' => 'regions#edit', :as => :edit_effective_regions
      get '(*requested_uri)' => 'regions#edit', :as => :edit
      put '(*requested_uri)' => 'regions#update', :as => :effective_regions
    end
  end
end
