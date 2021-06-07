module EffectiveRegions
  class Engine < ::Rails::Engine
    engine_name 'effective_regions'

    config.autoload_paths += Dir["#{config.root}/app/models/concerns"]

    # Include Helpers to base application
    initializer 'effective_regions.action_controller' do |app|
      ActiveSupport.on_load :action_controller_base do
        helper EffectiveRegionsHelper

        ActionController::Base.send(:include, ::EffectiveRegionsControllerHelper)
      end
    end

    # Include acts_as_addressable concern and allow any ActiveRecord object to call it
    initializer 'effective_regions.active_record' do |app|
      ActiveSupport.on_load :active_record do
        ActiveRecord::Base.extend(ActsAsRegionable::Base)
      end
    end

    # Set up our default configuration options.
    initializer "effective_regions.defaults", :before => :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_regions.rb")
    end

    initializer "effective_regions.append_precompiled_assets" do |app|
      app.config.assets.precompile += ['effective_regions_manifest.js', 'ck_assets.js', 'ck_assets.css', 'drop_cap.css']
    end

  end
end
