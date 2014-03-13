EffectiveRegions::Engine.routes.draw do

  scope :module => 'effective' do
    scope '/effective_regions' do
      get 'snippets' => 'regions#snippets', :as => :snippets
    end

    scope '/edit' do  # Changing this, means change editorUrlRegEx in mercury.min.js
      get '(*requested_uri)' => 'regions#edit', :as => :edit_effective_regions
      put '(*requested_uri)' => 'regions#update', :as => :effective_regions
    end
  end
end
