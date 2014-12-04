module Effective
  class RegionsController < ApplicationController
    respond_to :html, :json
    layout false

    before_filter :authenticate_user! if defined?(Devise)
    skip_log_page_views :quiet => true, :only => [:snippet, :snippets, :templates] if defined?(EffectiveLogging)

    skip_before_filter :verify_authenticity_token, :only => [:update]

    def edit
      EffectiveRegions.authorized?(self, :edit, Effective::Region.new())

      cookies['effective_regions_editting'] = {:value => request.referrer, :path => '/'}

      # TODO: turn this into a cookie or something better.
      redirect_to request.url.gsub('/edit', '') + '?edit=true'
    end

    def update
      javascript_should_refresh_page = ''

      Effective::Region.transaction do
        (request.fullpath.slice!(0..4) rescue nil) if request.fullpath.to_s.starts_with?('/edit') # This is so the before_save_method can reference the real current page

        region_params.each do |key, vals| # article_section_2_title => {:content => '<p></p>'}
          to_save = nil  # Which object, the regionable, or the region (if global) to save

          regionable, title = find_regionable(key)

          if regionable
            EffectiveRegions.authorized?(self, :update, regionable) # can I update the regionable object?

            region = regionable.regions.find { |region| region.title == title }
            region ||= regionable.regions.build(:title => title)

            to_save = regionable
          else
            region = Effective::Region.global.where(:title => title).first_or_initialize
            EffectiveRegions.authorized?(self, :update, region) # can I update the global region?

            to_save = region
          end

          region.content = cleanup(vals[:content])

          region.snippets = HashWithIndifferentAccess.new()
          (vals[:snippets] || []).each { |snippet, vals| region.snippets[snippet] = vals }

          # Last chance for a developer to make some changes here
          if (run_before_save_method(region, regionable) rescue nil) == :refresh
            javascript_should_refresh_page = 'refresh'
          end

          to_save.save!
        end

        render :text => javascript_should_refresh_page, :status => 200
        return
      end

      render :text => 'error', :status => :unprocessable_entity
    end

    def snippets
      EffectiveRegions.authorized?(self, :edit, Effective::Region.new())

      retval = {}
      EffectiveRegions.snippets.each do |snippet|
        retval[snippet.class_name] = {
          :dialog_url => snippet.snippet_dialog_url,
          :label => snippet.snippet_label,
          :description => snippet.snippet_description,
          :inline => snippet.snippet_inline,
          :editables => snippet.snippet_editables,
          :tag => snippet.snippet_tag.to_s
          #:template => ActionView::Base.new(ActionController::Base.view_paths, {}, ActionController::Base.new).render(:partial => snippet.to_partial_path, :object => snippet, :locals => {:snippet => snippet})
        }
      end

      render :json => retval
    end

    def snippet # This is a GET.  CKEDITOR passes us data, we need to render the non-editable content
      klass = "Effective::Snippets::#{region_params[:name].try(:classify)}".safe_constantize

      if klass.present?
        @snippet = klass.new(region_params[:data])
        render :partial => @snippet.to_partial_path, :object => @snippet, :locals => {:snippet => @snippet, :snippet_preview => true}
      else
        render :text => "Missing class Effective::Snippets::#{region_params[:name].try(:classify)}"
      end
    end

    def templates
      EffectiveRegions.authorized?(self, :edit, Effective::Region.new())

      retval = EffectiveRegions.templates.map do |template|
        {
          :title => template.title,
          :description => template.description,
          :image => template.image || "#{template.class_name}.png",
          :html => render_to_string(:partial => template.to_partial_path, :object => template, :locals => {:template => template})
        }
      end

      render :json => retval
    end

    protected

    def find_regionable(key)
      regionable = nil
      title = nil

      if(class_name, id, title = key.scan(/(\w+)_(\d+)_(\w+)/).flatten).present?
        regionable = (class_name.classify.safe_constantize).find(id) rescue nil
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

  end
end

