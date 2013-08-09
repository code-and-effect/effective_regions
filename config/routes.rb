EffectiveRegions::Engine.routes.draw do

  scope :module => 'effective' do
    scope '/edit' do  # Changing this, means change editorUrlRegEx in mercury.min.js
      get '(*requested_uri)' => 'regions#edit', :as => :mercury_editor
      put '(*requested_uri)' => 'regions#update', :as => :mercury_editor_save
    end
  end
end
