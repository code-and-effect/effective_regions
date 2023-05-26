module Effective
  class RegionsController < ApplicationController
    respond_to :html, :json
    layout false

    skip_before_action :verify_authenticity_token, only: :update
    before_action(:authenticate_user!) if defined?(Devise)

    skip_log_page_views(quiet: true, only: [:snippet]) if defined?(EffectiveLogging)

    def edit
      EffectiveResources.authorize!(self, :edit, Effective::Region.new)

      cookies['effective_regions_editting'] = {:value => params[:exit].presence || request.referrer, :path => '/'}

      # TODO: turn this into a cookie or something better.
      uri = URI.parse(Rack::Utils.unescape(request.url.sub('/edit', '')))
      uri.query = [uri.query, "edit=true"].compact.join('&')

      redirect_to uri.to_s
    end

    def update
      refresh_page = false
      response = {}
      success = false

      Effective::Region.transaction do
        (request.fullpath.slice!(0..4) rescue nil) if request.fullpath.to_s.starts_with?('/edit') # This is so the before_save_method can reference the real current page

        region_params.each do |key, vals| # article_section_2_title => {:content => '<p></p>'}
          to_save = nil  # Which object, the regionable, or the region (if global) to save

          regionable, title = find_regionable(key)

          if regionable
            EffectiveResources.authorized?(self, :update, regionable) # can I update the regionable object?

            region = regionable.regions.find { |region| region.title == title }
            region ||= regionable.regions.build(title: title)

            to_save = regionable
          else
            region = Effective::Region.global.where(title: title).first_or_initialize
            EffectiveResources.authorized?(self, :update, region) # can I update the global region?

            to_save = region
          end

          region.content = cleanup(vals[:content])

          region.snippets = HashWithIndifferentAccess.new()
          (vals[:snippets] || []).each { |snippet, vals| region.snippets[snippet] = HashWithIndifferentAccess.new(vals.to_h) }

          # Last chance for a developer to make some changes here
          refresh_page = true if (run_before_save_method(region, regionable) rescue nil) == :refresh

          to_save.save!
        end

        # Hand off the appropriate params to EffectivePages gem
        if defined?(EffectivePages) && params[:effective_menus].present?
          Effective::Menu.update_from_effective_regions!(menu_params)
        end

        response[:refresh] = true if refresh_page

        success = true
      end

      if success
        render(json: response.to_json(), status: 200)
      else
        render(text: 'error', status: :unprocessable_entity)
      end

    end

    def snippet # This is a GET.  CKEDITOR passes us data, we need to render the non-editable content
      EffectiveResources.authorize!(self, :edit, Effective::Region.new)

      klass = "Effective::Snippets::#{region_params[:name].try(:classify)}".safe_constantize

      if klass.present?
        @snippet = klass.new(region_params[:data])
        render :partial => @snippet.to_partial_path, :object => @snippet, :locals => {:snippet => @snippet, :snippet_preview => true}
      else
        render :text => "Missing class Effective::Snippets::#{region_params[:name].try(:classify)}"
      end
    end

    protected

    def find_regionable(key)
      regionable = nil
      title = nil

      if(class_name, id, title = key.scan(/(\w+)_(\d+)_(\w+)/).flatten).present?
        # The problem here is that class_name could have a namespace prepended to it
        klass = class_name.classify.safe_constantize

        if klass == nil && (pieces = class_name.split('_')).length > 1
          pieces.each_with_index do |piece, index|
            potential_namespace = pieces[0..index].join('_')
            potential_classname = (pieces.last(pieces.length-index-1).join('_') rescue '')

            klass = "#{potential_namespace.classify}::#{potential_classname.classify}".safe_constantize
            break if klass
          end
        end

        regionable = (klass.find(id) rescue nil)
      end

      return regionable, (title || key)
    end

    def cleanup(str)
      (str || '').tap do |str|
        str.chomp!('<p>&nbsp;</p>') # Remove any trailing empty <p>'s
        str.gsub!("\n", '')
        str.strip!
      end
    end

    def region_params
      begin
        params.require(:effective_regions).permit!
      rescue => e
        params[:effective_regions]
      end
    end

    private

    def run_before_save_method(region, regionable)
      return nil if region == nil

      if EffectiveRegions.before_save_method.respond_to?(:call)
        view_context.instance_exec(region, (regionable || :global), &EffectiveRegions.before_save_method)
      elsif EffectiveRegions.before_save_method.kind_of?(Symbol)
        self.instance_exec(self, region, (regionable || :global), &EffectiveRegions.before_save_method)
      end

    end

    def menu_params
      begin
        params.require(:effective_menus).permit!
      rescue => e
        params[:effective_menus]
      end
    end

  end
end
