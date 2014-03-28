EffectiveRegions::Engine.routes.draw do

  scope :module => 'effective' do
    scope '/effective_regions' do
      get 'snippets' => 'regions#snippets', :as => :snippets # Index of all Snippets
      get 'snippet' => 'regions#snippet', :as => :snippet # Get a Snippet based on passed values
    end

    scope '/edit' do  # Changing this, means changing the effective_ckeditor routes
      get '(*requested_uri)' => 'regions#edit', :as => :edit_effective_regions
      put '(*requested_uri)' => 'regions#update', :as => :effective_regions
    end
  end
end
